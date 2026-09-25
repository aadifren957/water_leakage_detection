import '../../models/worker_model.dart';
import '../../core/errors/exceptions.dart';
import 'mock_data_store.dart';

abstract class WorkerRepository {
  List<WorkerModel> getWorkers();
  Future<List<WorkerModel>> fetchWorkers();
  WorkerModel? getWorkerById(String id);
  WorkerModel? getWorkerByUserId(String userId);
  void incrementWorkerTaskCount(String workerId);
  void decrementWorkerTaskCount(String workerId);
}

class MockWorkerRepository implements WorkerRepository {
  final MockDataStore _store;

  MockWorkerRepository({MockDataStore? store}) : _store = store ?? MockDataStore();

  @override
  List<WorkerModel> getWorkers() {
    return List.unmodifiable(_store.workers);
  }

  @override
  Future<List<WorkerModel>> fetchWorkers() async {
    return List.unmodifiable(_store.workers);
  }

  @override
  WorkerModel? getWorkerById(String id) {
    try {
      return _store.workers.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  WorkerModel? getWorkerByUserId(String userId) {
    try {
      return _store.workers.firstWhere((w) => w.userId == userId);
    } catch (_) {
      return null;
    }
  }

  @override
  void incrementWorkerTaskCount(String workerId) {
    final index = _store.workers.indexWhere((w) => w.id == workerId);
    if (index == -1) {
      throw AppException('Worker with ID "$workerId" not found.');
    }

    final worker = _store.workers[index];
    final newCount = worker.activeTaskCount + 1;
    final isNowAvailable = newCount < worker.maxCapacity;

    _store.workers[index] = worker.copyWith(
      activeTaskCount: newCount,
      isAvailable: isNowAvailable,
    );
  }

  @override
  void decrementWorkerTaskCount(String workerId) {
    final index = _store.workers.indexWhere((w) => w.id == workerId);
    if (index == -1) return;

    final worker = _store.workers[index];
    final newCount = (worker.activeTaskCount - 1).clamp(0, 999);
    final isNowAvailable = newCount < worker.maxCapacity;

    _store.workers[index] = worker.copyWith(
      activeTaskCount: newCount,
      isAvailable: isNowAvailable,
    );
  }
}
