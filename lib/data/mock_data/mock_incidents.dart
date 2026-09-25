import '../../models/incident_model.dart';
import '../../models/timeline_event_model.dart';
import '../../core/constants/app_constants.dart';

class MockIncidents {
  MockIncidents._();

  static List<IncidentModel> get initialIncidents {
    final now = DateTime.now();

    return [
      // 1. Identified - Sector 4
      IncidentModel(
        id: 'INC-2026-001',
        deviceId: 'WLS-001',
        location: 'Sector 4 Main Distribution Line, Near Metro Pillar 142',
        zone: 'North Zone - Sector 4',
        flowRate: 8.50,
        totalVolume: 125.60,
        isLeakageDetected: true,
        isPumpOn: false,
        status: IncidentStatus.identified,
        priority: IncidentPriority.high,
        detectedAt: now.subtract(const Duration(minutes: 25)),
        timeline: [
          TimelineEventModel(
            id: 'TLE-001-1',
            title: 'Leakage Detected',
            description:
                'ESP8266 IoT Node WLS-001 recorded abnormal flow rate of 8.50 L/min (exceeding baseline 3.20 L/min). Automatic pump shutdown executed.',
            timestamp: now.subtract(const Duration(minutes: 25)),
            actorName: 'ESP8266 Telemetry Engine',
            actorRole: 'IoT Sensor Node',
            type: TimelineEventType.detected,
          ),
        ],
      ),

      // 2. Identified - Tech Park
      IncidentModel(
        id: 'INC-2026-002',
        deviceId: 'WLS-002',
        location: 'Cyber Gateway Avenue, Near Server Hub 3',
        zone: 'Tech Park Zone B',
        flowRate: 12.40,
        totalVolume: 310.20,
        isLeakageDetected: true,
        isPumpOn: false,
        status: IncidentStatus.identified,
        priority: IncidentPriority.critical,
        detectedAt: now.subtract(const Duration(minutes: 10)),
        timeline: [
          TimelineEventModel(
            id: 'TLE-002-1',
            title: 'Critical Leakage Detected',
            description:
                'Massive flow anomaly of 12.40 L/min detected on high-priority fiber duct cooling conduit.',
            timestamp: now.subtract(const Duration(minutes: 10)),
            actorName: 'ESP8266 Telemetry Engine',
            actorRole: 'IoT Sensor Node',
            type: TimelineEventType.detected,
          ),
        ],
      ),

      // 3. Acknowledged - Old City
      IncidentModel(
        id: 'INC-2026-003',
        deviceId: 'WLS-003',
        location: 'Old City Clock Tower Junction, Heritage Lane 4',
        zone: 'Old Heritage City',
        flowRate: 6.20,
        totalVolume: 84.10,
        isLeakageDetected: true,
        isPumpOn: false,
        status: IncidentStatus.acknowledged,
        priority: IncidentPriority.medium,
        detectedAt: now.subtract(const Duration(hours: 1, minutes: 15)),
        acknowledgedAt: now.subtract(const Duration(minutes: 50)),
        acknowledgedBy: AppConstants.officerDefaultName,
        timeline: [
          TimelineEventModel(
            id: 'TLE-003-1',
            title: 'Leakage Detected',
            description:
                'Flow rate increase of 6.20 L/min reported in heritage masonry line.',
            timestamp: now.subtract(const Duration(hours: 1, minutes: 15)),
            actorName: 'ESP8266 Telemetry Engine',
            actorRole: 'IoT Sensor Node',
            type: TimelineEventType.detected,
          ),
          TimelineEventModel(
            id: 'TLE-003-2',
            title: 'Acknowledged by Municipal Officer',
            description:
                'Officer Rajesh Varma reviewed telemetry and confirmed field dispatch requirement.',
            timestamp: now.subtract(const Duration(minutes: 50)),
            actorName: AppConstants.officerDefaultName,
            actorRole: 'Municipal Officer',
            type: TimelineEventType.acknowledged,
          ),
        ],
      ),

      // 4. Acknowledged - Civil Lines
      IncidentModel(
        id: 'INC-2026-004',
        deviceId: 'WLS-006',
        location: 'Civil Lines Road, Outside General Hospital Gate 2',
        zone: 'Central Administrative Zone',
        flowRate: 4.80,
        totalVolume: 52.30,
        isLeakageDetected: true,
        isPumpOn: false,
        status: IncidentStatus.acknowledged,
        priority: IncidentPriority.low,
        detectedAt: now.subtract(const Duration(hours: 2, minutes: 30)),
        acknowledgedAt: now.subtract(const Duration(hours: 1, minutes: 45)),
        acknowledgedBy: 'Anita Desai',
        timeline: [
          TimelineEventModel(
            id: 'TLE-004-1',
            title: 'Leakage Detected',
            description: 'Flow rate deviation of 4.80 L/min recorded at hospital feeder line.',
            timestamp: now.subtract(const Duration(hours: 2, minutes: 30)),
            actorName: 'ESP8266 Telemetry Engine',
            actorRole: 'IoT Sensor Node',
            type: TimelineEventType.detected,
          ),
          TimelineEventModel(
            id: 'TLE-004-2',
            title: 'Acknowledged by Municipal Officer',
            description:
                'Officer Anita Desai acknowledged incident. Priority scheduled for maintenance crew.',
            timestamp: now.subtract(const Duration(hours: 1, minutes: 45)),
            actorName: 'Anita Desai',
            actorRole: 'Municipal Officer',
            type: TimelineEventType.acknowledged,
          ),
        ],
      ),

      // 5. Assigned - Green Valley (Assigned to Rahul Patil / worker@demo.com)
      IncidentModel(
        id: 'INC-2026-005',
        deviceId: 'WLS-004',
        location: 'Green Valley Residency, Block C Feeder Main',
        zone: 'Sector 4, North Zone',
        flowRate: 9.10,
        totalVolume: 198.40,
        isLeakageDetected: true,
        isPumpOn: false,
        status: IncidentStatus.assigned,
        priority: IncidentPriority.high,
        detectedAt: now.subtract(const Duration(hours: 3)),
        acknowledgedAt: now.subtract(const Duration(hours: 2, minutes: 40)),
        acknowledgedBy: AppConstants.officerDefaultName,
        assignedWorkerId: AppConstants.workerDefaultWorkerId,
        assignedWorkerUserId: AppConstants.workerDefaultUserId,
        assignedWorkerName: AppConstants.workerDefaultName,
        assignedAt: now.subtract(const Duration(hours: 2, minutes: 15)),
        timeline: [
          TimelineEventModel(
            id: 'TLE-005-1',
            title: 'Leakage Detected',
            description:
                'Flow surge to 9.10 L/min detected on residential sub-feeder line.',
            timestamp: now.subtract(const Duration(hours: 3)),
            actorName: 'ESP8266 Telemetry Engine',
            actorRole: 'IoT Sensor Node',
            type: TimelineEventType.detected,
          ),
          TimelineEventModel(
            id: 'TLE-005-2',
            title: 'Acknowledged by Municipal Officer',
            description:
                'Officer Rajesh Varma reviewed fault telemetry and prioritized repair.',
            timestamp: now.subtract(const Duration(hours: 2, minutes: 40)),
            actorName: AppConstants.officerDefaultName,
            actorRole: 'Municipal Officer',
            type: TimelineEventType.acknowledged,
          ),
          TimelineEventModel(
            id: 'TLE-005-3',
            title: 'Assigned to Rahul Patil',
            description:
                'Field worker Rahul Patil (WRK-001) assigned for on-site pipeline sealing.',
            timestamp: now.subtract(const Duration(hours: 2, minutes: 15)),
            actorName: AppConstants.officerDefaultName,
            actorRole: 'Municipal Officer',
            type: TimelineEventType.assigned,
          ),
        ],
      ),

      // 6. Assigned - Industrial Area (Assigned to Amit Deshmukh)
      IncidentModel(
        id: 'INC-2026-006',
        deviceId: 'WLS-005',
        location: 'Industrial Area Phase 2, Heavy Fabricators Sector',
        zone: 'Industrial Sector 5',
        flowRate: 15.80,
        totalVolume: 480.00,
        isLeakageDetected: true,
        isPumpOn: false,
        status: IncidentStatus.assigned,
        priority: IncidentPriority.critical,
        detectedAt: now.subtract(const Duration(hours: 4)),
        acknowledgedAt: now.subtract(const Duration(hours: 3, minutes: 30)),
        acknowledgedBy: AppConstants.officerDefaultName,
        assignedWorkerId: 'WRK-003',
        assignedWorkerUserId: 'USR-WRK-003',
        assignedWorkerName: 'Amit Deshmukh',
        assignedAt: now.subtract(const Duration(hours: 3)),
        timeline: [
          TimelineEventModel(
            id: 'TLE-006-1',
            title: 'Critical Leakage Detected',
            description:
                'High pressure pipeline anomaly 15.80 L/min triggered alarm in industrial sector.',
            timestamp: now.subtract(const Duration(hours: 4)),
            actorName: 'ESP8266 Telemetry Engine',
            actorRole: 'IoT Sensor Node',
            type: TimelineEventType.detected,
          ),
          TimelineEventModel(
            id: 'TLE-006-2',
            title: 'Acknowledged by Municipal Officer',
            description: 'Officer Rajesh Varma initiated emergency field dispatch.',
            timestamp: now.subtract(const Duration(hours: 3, minutes: 30)),
            actorName: AppConstants.officerDefaultName,
            actorRole: 'Municipal Officer',
            type: TimelineEventType.acknowledged,
          ),
          TimelineEventModel(
            id: 'TLE-006-3',
            title: 'Assigned to Amit Deshmukh',
            description:
                'Assigned to heavy infrastructure specialist Amit Deshmukh (WRK-003).',
            timestamp: now.subtract(const Duration(hours: 3)),
            actorName: AppConstants.officerDefaultName,
            actorRole: 'Municipal Officer',
            type: TimelineEventType.assigned,
          ),
        ],
      ),

      // 7. Resolved - Metro Station Plaza (Priya Sharma)
      IncidentModel(
        id: 'INC-2026-007',
        deviceId: 'WLS-007',
        location: 'Central Metro Station Plaza, Underground Concourse',
        zone: 'Tech Park Zone B',
        flowRate: 7.30,
        totalVolume: 165.20,
        isLeakageDetected: false, // Resolved
        isPumpOn: true,
        status: IncidentStatus.resolved,
        priority: IncidentPriority.high,
        detectedAt: now.subtract(const Duration(hours: 6)),
        acknowledgedAt: now.subtract(const Duration(hours: 5, minutes: 30)),
        acknowledgedBy: 'Anita Desai',
        assignedWorkerId: 'WRK-002',
        assignedWorkerUserId: 'USR-WRK-002',
        assignedWorkerName: 'Priya Sharma',
        assignedAt: now.subtract(const Duration(hours: 5)),
        resolvedAt: now.subtract(const Duration(hours: 3)),
        resolvedBy: 'Priya Sharma',
        repairNotes:
            'Replaced degraded 50mm rubber flange gasket and tightened retaining bolts. System repressurized with zero seepage.',
        timeline: [
          TimelineEventModel(
            id: 'TLE-007-1',
            title: 'Leakage Detected',
            description: 'Flow anomaly 7.30 L/min detected at underground concourse valve.',
            timestamp: now.subtract(const Duration(hours: 6)),
            actorName: 'ESP8266 Telemetry Engine',
            actorRole: 'IoT Sensor Node',
            type: TimelineEventType.detected,
          ),
          TimelineEventModel(
            id: 'TLE-007-2',
            title: 'Acknowledged by Municipal Officer',
            description: 'Officer Anita Desai acknowledged incident.',
            timestamp: now.subtract(const Duration(hours: 5, minutes: 30)),
            actorName: 'Anita Desai',
            actorRole: 'Municipal Officer',
            type: TimelineEventType.acknowledged,
          ),
          TimelineEventModel(
            id: 'TLE-007-3',
            title: 'Assigned to Priya Sharma',
            description: 'Assigned to Priya Sharma (WRK-002).',
            timestamp: now.subtract(const Duration(hours: 5)),
            actorName: 'Anita Desai',
            actorRole: 'Municipal Officer',
            type: TimelineEventType.assigned,
          ),
          TimelineEventModel(
            id: 'TLE-007-4',
            title: 'Marked Resolved',
            description:
                'Priya Sharma resolved the incident. Notes: Replaced degraded 50mm rubber flange gasket and tightened retaining bolts.',
            timestamp: now.subtract(const Duration(hours: 3)),
            actorName: 'Priya Sharma',
            actorRole: 'Field Worker',
            type: TimelineEventType.resolved,
          ),
        ],
      ),

      // 8. Resolved - Railway Colony (Rahul Patil)
      IncidentModel(
        id: 'INC-2026-008',
        deviceId: 'WLS-008',
        location: 'Railway Colony Main Water Header Junction',
        zone: 'Sector 4, North Zone',
        flowRate: 11.20,
        totalVolume: 512.00,
        isLeakageDetected: false,
        isPumpOn: true,
        status: IncidentStatus.resolved,
        priority: IncidentPriority.critical,
        detectedAt: now.subtract(const Duration(hours: 18)),
        acknowledgedAt: now.subtract(const Duration(hours: 17, minutes: 40)),
        acknowledgedBy: AppConstants.officerDefaultName,
        assignedWorkerId: AppConstants.workerDefaultWorkerId,
        assignedWorkerUserId: AppConstants.workerDefaultUserId,
        assignedWorkerName: AppConstants.workerDefaultName,
        assignedAt: now.subtract(const Duration(hours: 17, minutes: 15)),
        resolvedAt: now.subtract(const Duration(hours: 14)),
        resolvedBy: AppConstants.workerDefaultName,
        repairNotes:
            'Fitted emergency pipe repair clamp over 100mm ductile iron pipe fracture. Water flow normalized and line flushed.',
        timeline: [
          TimelineEventModel(
            id: 'TLE-008-1',
            title: 'Critical Leakage Detected',
            description: 'Major flow rate surge 11.20 L/min detected at railway junction line.',
            timestamp: now.subtract(const Duration(hours: 18)),
            actorName: 'ESP8266 Telemetry Engine',
            actorRole: 'IoT Sensor Node',
            type: TimelineEventType.detected,
          ),
          TimelineEventModel(
            id: 'TLE-008-2',
            title: 'Acknowledged by Municipal Officer',
            description: 'Officer Rajesh Varma logged high priority dispatch.',
            timestamp: now.subtract(const Duration(hours: 17, minutes: 40)),
            actorName: AppConstants.officerDefaultName,
            actorRole: 'Municipal Officer',
            type: TimelineEventType.acknowledged,
          ),
          TimelineEventModel(
            id: 'TLE-008-3',
            title: 'Assigned to Rahul Patil',
            description: 'Assigned to Rahul Patil (WRK-001).',
            timestamp: now.subtract(const Duration(hours: 17, minutes: 15)),
            actorName: AppConstants.officerDefaultName,
            actorRole: 'Municipal Officer',
            type: TimelineEventType.assigned,
          ),
          TimelineEventModel(
            id: 'TLE-008-4',
            title: 'Marked Resolved',
            description:
                'Rahul Patil completed repair: Fitted emergency pipe repair clamp over 100mm ductile iron pipe fracture.',
            timestamp: now.subtract(const Duration(hours: 14)),
            actorName: AppConstants.workerDefaultName,
            actorRole: 'Field Worker',
            type: TimelineEventType.resolved,
          ),
        ],
      ),
    ];
  }
}
