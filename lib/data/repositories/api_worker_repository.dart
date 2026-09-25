import '../../models/worker_model.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/errors/exceptions.dart';
import 'worker_repository.dart';

class ApiWorkerRepository implements WorkerRepository {
  final ApiClient _client;
  List<WorkerModel> _cache = [];

  ApiWorkerRepository({ApiClient? client}) : _client = client ?? ApiClient();

  @override
  List<WorkerModel> getWorkers() => List.unmodifiable(_cache);

  @override
  WorkerModel? getWorkerById(String id) {
    try {
      return _cache.firstWhere((w) => w.id == id || w.userId == id);
    } catch (_) {
      return null;
    }
  }

  @override
  WorkerModel? getWorkerByUserId(String userId) {
    try {
      return _cache.firstWhere((w) => w.userId == userId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<WorkerModel>> fetchWorkers() async {
    try {
      final res = await _client.get('/workers');
      if (res is List) {
        _cache = res
            .map((item) => WorkerModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return _cache;
    } on ApiException catch (e) {
      throw AppException(e.message);
    } catch (e) {
      throw AppException('Failed to load workers: $e');
    }
  }

  @override
  void incrementWorkerTaskCount(String workerId) {
    final index = _cache.indexWhere((w) => w.id == workerId || w.userId == workerId);
    if (index != -1) {
      final worker = _cache[index];
      final newCount = worker.activeTaskCount + 1;
      _cache[index] = worker.copyWith(
        activeTaskCount: newCount,
        isAvailable: newCount < worker.maxCapacity,
      );
    }
  }

  @override
  void decrementWorkerTaskCount(String workerId) {
    final index = _cache.indexWhere((w) => w.id == workerId || w.userId == workerId);
    if (index != -1) {
      final worker = _cache[index];
      final newCount = (worker.activeTaskCount - 1).clamp(0, 999);
      _cache[index] = worker.copyWith(
        activeTaskCount: newCount,
        isAvailable: newCount < worker.maxCapacity,
      );
    }
  }
}
