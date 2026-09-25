import '../../models/worker_model.dart';
import '../../core/constants/app_constants.dart';

class MockWorkers {
  MockWorkers._();

  static List<WorkerModel> get initialWorkers => [
        const WorkerModel(
          id: AppConstants.workerDefaultWorkerId,
          userId: AppConstants.workerDefaultUserId,
          name: AppConstants.workerDefaultName,
          email: AppConstants.workerDemoEmail,
          phone: '+91 98230 45671',
          zone: 'Sector 4, North Zone',
          isAvailable: true,
          activeTaskCount: 1, // Has 1 assigned incident in initial dataset (INC-2026-005)
          maxCapacity: AppConstants.maxWorkerTaskCapacity,
          skills: ['Pipe Fitting', 'Pressure Valve Calibration', 'Fast Joint Sealing'],
        ),
        const WorkerModel(
          id: 'WRK-002',
          userId: 'USR-WRK-002',
          name: 'Priya Sharma',
          email: 'priya@demo.com',
          phone: '+91 98230 67890',
          zone: 'Tech Park Zone B',
          isAvailable: true,
          activeTaskCount: 0,
          maxCapacity: AppConstants.maxWorkerTaskCapacity,
          skills: ['Acoustic Leak Detection', 'Ultrasonic Flow Sensor Calibration'],
        ),
        const WorkerModel(
          id: 'WRK-003',
          userId: 'USR-WRK-003',
          name: 'Amit Deshmukh',
          email: 'amit@demo.com',
          phone: '+91 98230 11223',
          zone: 'Industrial Sector 5',
          isAvailable: true,
          activeTaskCount: 1, // Has 1 assigned incident (INC-2026-006)
          maxCapacity: AppConstants.maxWorkerTaskCapacity,
          skills: ['Heavy Pipeline Welding', 'Excavation & Trenching', 'Main Gate Valves'],
        ),
        const WorkerModel(
          id: 'WRK-004',
          userId: 'USR-WRK-004',
          name: 'Neha Kulkarni',
          email: 'neha@demo.com',
          phone: '+91 98230 99887',
          zone: 'Old Heritage City',
          isAvailable: false, // Busy - max capacity reached
          activeTaskCount: 3,
          maxCapacity: AppConstants.maxWorkerTaskCapacity,
          skills: ['Heritage District Plumbing', 'Corrosion Remediation', 'Emergency Shuts'],
        ),
      ];
}
