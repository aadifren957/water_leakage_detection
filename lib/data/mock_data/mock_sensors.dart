import '../../models/sensor_reading_model.dart';

class MockSensors {
  MockSensors._();

  static List<SensorReadingModel> get initialSensors => [
        SensorReadingModel(
          deviceId: 'WLS-001',
          deviceName: 'ESP8266 Sensor Node #01 - Sector 4 Main Feeder',
          location: 'Sector 4 Main Distribution Line, Near Metro Pillar 142',
          flowRate: 8.50,
          totalVolume: 125.60,
          normalBaselineFlowRate: 3.20,
          isLeakageDetected: true,
          isPumpOn: false, // ESP8266 auto-stopped pump on high anomaly
          isOnline: true,
          lastUpdated: DateTime.now().subtract(const Duration(minutes: 2)),
          hourlyHistory: [
            const HourlyReading(timeLabel: '06:00', flowRate: 3.1, pressure: 2.5),
            const HourlyReading(timeLabel: '07:00', flowRate: 3.3, pressure: 2.5),
            const HourlyReading(timeLabel: '08:00', flowRate: 3.4, pressure: 2.4),
            const HourlyReading(timeLabel: '09:00', flowRate: 3.5, pressure: 2.4),
            const HourlyReading(timeLabel: '10:00', flowRate: 5.8, pressure: 2.1), // Spike starts
            const HourlyReading(timeLabel: '11:00', flowRate: 8.2, pressure: 1.6),
            const HourlyReading(timeLabel: '12:00', flowRate: 8.5, pressure: 1.5),
          ],
        ),
        SensorReadingModel(
          deviceId: 'WLS-002',
          deviceName: 'ESP8266 Sensor Node #02 - Tech Park Data Line',
          location: 'Cyber Gateway Avenue, Near Server Hub 3',
          flowRate: 12.40,
          totalVolume: 310.20,
          normalBaselineFlowRate: 4.00,
          isLeakageDetected: true,
          isPumpOn: false,
          isOnline: true,
          lastUpdated: DateTime.now().subtract(const Duration(minutes: 5)),
          hourlyHistory: [
            const HourlyReading(timeLabel: '06:00', flowRate: 3.9, pressure: 2.8),
            const HourlyReading(timeLabel: '07:00', flowRate: 4.1, pressure: 2.8),
            const HourlyReading(timeLabel: '08:00', flowRate: 4.2, pressure: 2.7),
            const HourlyReading(timeLabel: '09:00', flowRate: 7.5, pressure: 2.0),
            const HourlyReading(timeLabel: '10:00', flowRate: 11.0, pressure: 1.4),
            const HourlyReading(timeLabel: '11:00', flowRate: 12.1, pressure: 1.3),
            const HourlyReading(timeLabel: '12:00', flowRate: 12.4, pressure: 1.2),
          ],
        ),
        SensorReadingModel(
          deviceId: 'WLS-003',
          deviceName: 'ESP8266 Sensor Node #03 - Old Heritage Gateway',
          location: 'Old City Clock Tower Junction',
          flowRate: 6.20,
          totalVolume: 84.10,
          normalBaselineFlowRate: 2.80,
          isLeakageDetected: true,
          isPumpOn: false,
          isOnline: true,
          lastUpdated: DateTime.now().subtract(const Duration(minutes: 12)),
          hourlyHistory: [
            const HourlyReading(timeLabel: '06:00', flowRate: 2.7, pressure: 2.3),
            const HourlyReading(timeLabel: '07:00', flowRate: 2.8, pressure: 2.3),
            const HourlyReading(timeLabel: '08:00', flowRate: 2.9, pressure: 2.2),
            const HourlyReading(timeLabel: '09:00', flowRate: 4.1, pressure: 1.9),
            const HourlyReading(timeLabel: '10:00', flowRate: 5.8, pressure: 1.7),
            const HourlyReading(timeLabel: '11:00', flowRate: 6.0, pressure: 1.6),
            const HourlyReading(timeLabel: '12:00', flowRate: 6.2, pressure: 1.6),
          ],
        ),
        SensorReadingModel(
          deviceId: 'WLS-004',
          deviceName: 'ESP8266 Sensor Node #04 - Green Valley Trunk',
          location: 'Green Valley Residency, Block C Feeder',
          flowRate: 3.40,
          totalVolume: 2400.50,
          normalBaselineFlowRate: 3.50,
          isLeakageDetected: false,
          isPumpOn: true,
          isOnline: true,
          lastUpdated: DateTime.now().subtract(const Duration(minutes: 1)),
          hourlyHistory: [
            const HourlyReading(timeLabel: '06:00', flowRate: 3.2, pressure: 2.6),
            const HourlyReading(timeLabel: '07:00', flowRate: 3.5, pressure: 2.6),
            const HourlyReading(timeLabel: '08:00', flowRate: 3.6, pressure: 2.5),
            const HourlyReading(timeLabel: '09:00', flowRate: 3.4, pressure: 2.5),
            const HourlyReading(timeLabel: '10:00', flowRate: 3.3, pressure: 2.6),
            const HourlyReading(timeLabel: '11:00', flowRate: 3.4, pressure: 2.5),
            const HourlyReading(timeLabel: '12:00', flowRate: 3.4, pressure: 2.5),
          ],
        ),
      ];
}
