import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/worker_model.dart';
import '../data/repositories/worker_repository.dart';
import '../data/repositories/api_worker_repository.dart';

final workerRepositoryProvider = Provider<WorkerRepository>((ref) {
  return ApiWorkerRepository();
});

class WorkersNotifier extends StateNotifier<List<WorkerModel>> {
  final WorkerRepository _repository;

  WorkersNotifier(this._repository) : super(_repository.getWorkers()) {
    refresh();
  }

  Future<void> refresh() async {
    try {
      final workers = await _repository.fetchWorkers();
      if (!mounted) return;
      state = workers;
    } catch (_) {
      if (!mounted) return;
      state = _repository.getWorkers();
    }
  }
}

final workersListProvider = StateNotifierProvider<WorkersNotifier, List<WorkerModel>>((ref) {
  final repo = ref.watch(workerRepositoryProvider);
  return WorkersNotifier(repo);
});

final availableWorkersProvider = Provider<List<WorkerModel>>((ref) {
  final workers = ref.watch(workersListProvider);
  return workers.where((w) => w.canAcceptTasks).toList();
});
