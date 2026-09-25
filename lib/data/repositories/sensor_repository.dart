import '../../models/sensor_reading_model.dart';
import 'mock_data_store.dart';

abstract class SensorRepository {
  List<SensorReadingModel> getSensors();
  Future<List<SensorReadingModel>> fetchSensors();
  SensorReadingModel? getSensorByDeviceId(String deviceId);
}

class MockSensorRepository implements SensorRepository {
  final MockDataStore _store;

  MockSensorRepository({MockDataStore? store}) : _store = store ?? MockDataStore();

  @override
  List<SensorReadingModel> getSensors() {
    return List.unmodifiable(_store.sensors);
  }

  @override
  Future<List<SensorReadingModel>> fetchSensors() async {
    return List.unmodifiable(_store.sensors);
  }

  @override
  SensorReadingModel? getSensorByDeviceId(String deviceId) {
    try {
      return _store.sensors.firstWhere((s) => s.deviceId == deviceId);
    } catch (_) {
      return null;
    }
  }
}
