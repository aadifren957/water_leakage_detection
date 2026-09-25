import '../../models/incident_model.dart';
import '../../models/worker_model.dart';
import '../../models/sensor_reading_model.dart';
import '../../models/notification_model.dart';
import '../../models/user_model.dart';
import '../mock_data/mock_users.dart';
import '../mock_data/mock_workers.dart';
import '../mock_data/mock_sensors.dart';
import '../mock_data/mock_incidents.dart';
import '../mock_data/mock_notifications.dart';

/// Central singleton in-memory data store for the running session.
/// Ensures that Municipal Officers and Field Workers see synchronized state,
/// and allows a complete Reset Demo Data operation at any time.
class MockDataStore {
  static final MockDataStore _instance = MockDataStore._internal();
  factory MockDataStore() => _instance;

  MockDataStore._internal() {
    resetToDefaults();
  }

  late List<UserModel> users;
  late List<WorkerModel> workers;
  late List<SensorReadingModel> sensors;
  late List<IncidentModel> incidents;
  late List<NotificationModel> notifications;
  UserModel? currentUser;

  void resetToDefaults() {
    users = List.from(MockUsers.allUsers);
    workers = List.from(MockWorkers.initialWorkers);
    sensors = List.from(MockSensors.initialSensors);
    incidents = List.from(MockIncidents.initialIncidents);
    notifications = List.from(MockNotifications.initialNotifications);
    currentUser = MockUsers.officerRajesh;
  }
}
