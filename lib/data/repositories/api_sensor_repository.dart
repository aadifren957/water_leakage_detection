import '../../models/sensor_reading_model.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/errors/exceptions.dart';
import 'sensor_repository.dart';

class ApiSensorRepository implements SensorRepository {
  final ApiClient _client;
  List<SensorReadingModel> _cache = [];

  ApiSensorRepository({ApiClient? client}) : _client = client ?? ApiClient();

  @override
  List<SensorReadingModel> getSensors() => List.unmodifiable(_cache);

  @override
  SensorReadingModel? getSensorByDeviceId(String deviceId) {
    try {
      return _cache.firstWhere((s) => s.deviceId == deviceId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<SensorReadingModel>> fetchSensors() async {
    try {
      final res = await _client.get('/sensors/readings');
      if (res is List) {
        _cache = res
            .map((item) => SensorReadingModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return _cache;
    } on ApiException catch (e) {
      throw AppException(e.message);
    } catch (e) {
      throw AppException('Failed to load sensors: $e');
    }
  }
}
