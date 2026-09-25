import { prisma } from '../config/db';
import { IotReadingInput } from '../validators/sensor.validator';
import { IncidentStatus, NotificationType, Severity } from '@prisma/client';
import { NotificationService } from './notification.service';

export class SensorService {
  /**
   * Format SensorReading for Flutter SensorReadingModel
   */
  static formatSensorModel(device: any, latestReading: any, historyReadings: any[]) {
    const hourlyHistory = (historyReadings || []).map((r) => {
      const date = new Date(r.recordedAt);
      const hours = date.getHours().toString().padStart(2, '0');
      const mins = date.getMinutes().toString().padStart(2, '0');
      return {
        timeLabel: `${hours}:${mins}`,
        flowRate: r.flowRate,
        pressure: 2.4,
      };
    });

    return {
      deviceId: latestReading?.deviceId || device.deviceId,
      deviceName: latestReading?.deviceName || device.deviceName || 'ESP8266 Flow Node',
      location: latestReading?.location || device.location || 'Smart City Water Pipeline',
      flowRate: latestReading?.flowRate ?? 0.0,
      totalVolume: latestReading?.totalLiters ?? 0.0,
      normalBaselineFlowRate: latestReading?.normalBaselineFlowRate ?? 3.5,
      isLeakageDetected: latestReading?.leakageDetected ?? false,
      isPumpOn: latestReading?.pumpStatus ?? true,
      isOnline: latestReading?.isOnline ?? true,
      lastUpdated: latestReading?.recordedAt ? latestReading.recordedAt.toISOString() : new Date().toISOString(),
      hourlyHistory,
    };
  }

  /**
   * Ingest real telemetry from ESP8266 or IoT Gateways
   */
  static async ingestReading(input: IotReadingInput) {
    const pumpStatus = input.leakageDetected ? false : input.pumpStatus;

    // Create sensor reading record
    const reading = await prisma.sensorReading.create({
      data: {
        deviceId: input.deviceId,
        deviceName: input.deviceName,
        location: input.location,
        flowRate: input.flowRate,
        totalLiters: input.totalLiters,
        normalBaselineFlowRate: input.normalBaselineFlowRate,
        leakageDetected: input.leakageDetected,
        pumpStatus,
        isOnline: input.isOnline,
      },
    });

    // If leakage confirmed, check if an active incident already exists for this device
    if (input.leakageDetected) {
      const activeIncident = await prisma.incident.findFirst({
        where: {
          deviceId: input.deviceId,
          status: { in: [IncidentStatus.IDENTIFIED, IncidentStatus.ACKNOWLEDGED, IncidentStatus.ASSIGNED] },
        },
      });

      if (!activeIncident) {
        // Automatically create new incident
        const count = await prisma.incident.count();
        const incidentCode = `INC-${new Date().getFullYear()}-${(count + 1).toString().padStart(3, '0')}`;

        const newInc = await prisma.$transaction(async (tx) => {
          const inc = await tx.incident.create({
            data: {
              incidentCode,
              title: `Abnormal Flow Anomaly (${input.flowRate.toFixed(2)} L/min)`,
              description: `ESP8266 node ${input.deviceId} recorded flow anomaly above baseline (${input.normalBaselineFlowRate} L/min). Auto safety shutoff active.`,
              location: input.location,
              zone: 'Distribution Network',
              deviceId: input.deviceId,
              flowRate: input.flowRate,
              totalLiters: input.totalLiters,
              leakageDetected: true,
              pumpStatus: false,
              severity: input.flowRate > 10 ? Severity.CRITICAL : Severity.HIGH,
              status: IncidentStatus.IDENTIFIED,
            },
          });

          await tx.incidentHistory.create({
            data: {
              incidentId: inc.id,
              actorName: `ESP8266 Node (${input.deviceId})`,
              actorRole: 'IoT Sensor Node',
              action: 'DETECTED',
              newStatus: IncidentStatus.IDENTIFIED,
              note: 'Leakage Detected via Telemetry',
              metadata: {
                flowRate: input.flowRate,
                baseline: input.normalBaselineFlowRate,
                description: `Sensor anomaly detected at ${input.location} (${input.flowRate.toFixed(2)} L/min). Automatic safety shutoff active.`,
              },
            },
          });

          return inc;
        });

        // Notify officers
        await NotificationService.notifyAllOfficers({
          title: `New Leakage Alert: ${incidentCode}`,
          message: `Flow anomaly ${input.flowRate.toFixed(2)} L/min at ${input.location}. Automatic safety shutoff triggered.`,
          type: NotificationType.LEAK_DETECTED,
          incidentId: newInc.id,
        });
      }
    }

    return reading;
  }

  /**
   * Get all registered sensor devices and their latest status
   */
  static async getAllSensors() {
    // Distinct device IDs from SensorReading or defaults
    const deviceReadings = await prisma.sensorReading.findMany({
      distinct: ['deviceId'],
      orderBy: { recordedAt: 'desc' },
      take: 20,
    });

    const results = [];
    for (const r of deviceReadings) {
      const recentHistory = await prisma.sensorReading.findMany({
        where: { deviceId: r.deviceId },
        orderBy: { recordedAt: 'asc' },
        take: 12,
      });

      results.push(this.formatSensorModel({ deviceId: r.deviceId, deviceName: r.deviceName, location: r.location }, r, recentHistory));
    }

    return results;
  }

  /**
   * Get single sensor telemetry by deviceId
   */
  static async getSensorByDeviceId(deviceId: string) {
    const latest = await prisma.sensorReading.findFirst({
      where: { deviceId },
      orderBy: { recordedAt: 'desc' },
    });

    if (!latest) {
      return null;
    }

    const history = await prisma.sensorReading.findMany({
      where: { deviceId },
      orderBy: { recordedAt: 'asc' },
      take: 12,
    });

    return this.formatSensorModel({ deviceId: latest.deviceId, deviceName: latest.deviceName, location: latest.location }, latest, history);
  }
}
