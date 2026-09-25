import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sensor_reading_model.dart';
import '../data/repositories/sensor_repository.dart';
import '../data/repositories/api_sensor_repository.dart';

final sensorRepositoryProvider = Provider<SensorRepository>((ref) {
  return ApiSensorRepository();
});

class SensorsNotifier extends StateNotifier<List<SensorReadingModel>> {
  final SensorRepository _repository;

  SensorsNotifier(this._repository) : super(_repository.getSensors()) {
    refresh();
  }

  Future<void> refresh() async {
    try {
      final sensors = await _repository.fetchSensors();
      if (!mounted) return;
      state = sensors;
    } catch (_) {
      if (!mounted) return;
      state = _repository.getSensors();
    }
  }
}

final sensorsListProvider = StateNotifierProvider<SensorsNotifier, List<SensorReadingModel>>((ref) {
  final repo = ref.watch(sensorRepositoryProvider);
  return SensorsNotifier(repo);
});

final selectedSensorIdProvider = StateProvider<String>((ref) => 'WLS-001');

final selectedSensorProvider = Provider<SensorReadingModel?>((ref) {
  final sensors = ref.watch(sensorsListProvider);
  final selectedId = ref.watch(selectedSensorIdProvider);

  try {
    return sensors.firstWhere((s) => s.deviceId == selectedId);
  } catch (_) {
    return sensors.isNotEmpty ? sensors.first : null;
  }
});
