import '../../models/user_model.dart';
import '../../core/constants/app_constants.dart';

class MockUsers {
  MockUsers._();

  static const UserModel officerRajesh = UserModel(
    id: AppConstants.officerDefaultId,
    name: AppConstants.officerDefaultName,
    email: AppConstants.officerDemoEmail,
    role: UserRole.municipalOfficer,
    department: 'Water Supply & Sewerage Board',
    phoneNumber: '+91 98211 22334',
    zone: 'Central Command & Citywide',
  );

  static const UserModel officerAnita = UserModel(
    id: 'USR-OFF-002',
    name: 'Anita Desai',
    email: 'anita.desai@demo.com',
    role: UserRole.municipalOfficer,
    department: 'Smart City Operations Control',
    phoneNumber: '+91 98211 88990',
    zone: 'East & South Districts',
  );

  static const UserModel workerRahul = UserModel(
    id: AppConstants.workerDefaultUserId,
    name: AppConstants.workerDefaultName,
    email: AppConstants.workerDemoEmail,
    role: UserRole.fieldWorker,
    department: 'Rapid Response Plumbing Unit',
    workerId: AppConstants.workerDefaultWorkerId,
    phoneNumber: '+91 98230 45671',
    zone: 'Sector 4, North Zone',
  );

  static const UserModel workerPriya = UserModel(
    id: 'USR-WRK-002',
    name: 'Priya Sharma',
    email: 'priya@demo.com',
    role: UserRole.fieldWorker,
    department: 'Pipeline Inspection Division',
    workerId: 'WRK-002',
    phoneNumber: '+91 98230 67890',
    zone: 'Tech Park Zone B',
  );

  static const UserModel workerAmit = UserModel(
    id: 'USR-WRK-003',
    name: 'Amit Deshmukh',
    email: 'amit@demo.com',
    role: UserRole.fieldWorker,
    department: 'Heavy Infrastructure Repair',
    workerId: 'WRK-003',
    phoneNumber: '+91 98230 11223',
    zone: 'Industrial Sector 5',
  );

  static const UserModel workerNeha = UserModel(
    id: 'USR-WRK-004',
    name: 'Neha Kulkarni',
    email: 'neha@demo.com',
    role: UserRole.fieldWorker,
    department: 'Emergency Maintenance Crew',
    workerId: 'WRK-004',
    phoneNumber: '+91 98230 99887',
    zone: 'Old Heritage City',
  );

  static List<UserModel> get allUsers => [
        officerRajesh,
        officerAnita,
        workerRahul,
        workerPriya,
        workerAmit,
        workerNeha,
      ];

  static final Map<String, String> userPasswords = {
    AppConstants.officerDemoEmail: AppConstants.officerDemoPassword,
    'anita.desai@demo.com': 'Officer@123',
    AppConstants.workerDemoEmail: AppConstants.workerDemoPassword,
    'priya@demo.com': 'Worker@123',
    'amit@demo.com': 'Worker@123',
    'neha@demo.com': 'Worker@123',
  };
}
