import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:water_watch/providers/auth_provider.dart';
import 'package:water_watch/providers/incident_provider.dart';
import 'package:water_watch/providers/worker_provider.dart';
import 'package:water_watch/providers/notification_provider.dart';
import 'package:water_watch/providers/sensor_provider.dart';
import 'package:water_watch/providers/data_store_provider.dart';
import 'package:water_watch/data/repositories/mock_data_store.dart';
import 'package:water_watch/data/repositories/auth_repository.dart';
import 'package:water_watch/data/repositories/incident_repository.dart';
import 'package:water_watch/data/repositories/worker_repository.dart';
import 'package:water_watch/data/repositories/notification_repository.dart';
import 'package:water_watch/data/repositories/sensor_repository.dart';
import 'package:water_watch/models/user_model.dart';
import 'package:water_watch/models/incident_model.dart';

void main() {
  group('Cross-Dashboard State Synchronization & Riverpod Tests', () {
    test('Officer and Worker share synchronous in-memory state during workflow', () async {
      final store = MockDataStore()..resetToDefaults();
      final authRepo = MockAuthRepository(store: store);
      final workerRepo = MockWorkerRepository(store: store);
      final notifRepo = MockNotificationRepository(store: store);
      final incidentRepo = MockIncidentRepository(
        store: store,
        workerRepo: workerRepo,
        notificationRepo: notifRepo,
      );
      final sensorRepo = MockSensorRepository(store: store);

      final container = ProviderContainer(
        overrides: [
          dataStoreProvider.overrideWithValue(store),
          authRepositoryProvider.overrideWithValue(authRepo),
          workerRepositoryProvider.overrideWithValue(workerRepo),
          notificationRepositoryProvider.overrideWithValue(notifRepo),
          incidentRepositoryProvider.overrideWithValue(incidentRepo),
          sensorRepositoryProvider.overrideWithValue(sensorRepo),
        ],
      );

      // 1. Initial State as Officer
      final initialStats = container.read(incidentStatsProvider);
      expect(initialStats.identifiedCount, greaterThan(0));

      // 2. Officer acknowledges an identified incident (INC-2026-001)
      await container.read(allIncidentsProvider.notifier).acknowledge('INC-2026-001');

      final incAfterAck = container.read(allIncidentsProvider).firstWhere((i) => i.id == 'INC-2026-001');
      expect(incAfterAck.status, equals(IncidentStatus.acknowledged));

      // 3. Officer assigns INC-2026-001 to Rahul Patil (WRK-001)
      await container.read(allIncidentsProvider.notifier).assignWorker(
            incidentId: 'INC-2026-001',
            workerId: 'WRK-001',
          );

      // 4. Worker capacity should update
      await container.read(workersListProvider.notifier).refresh();
      final rahul = container.read(workersListProvider).firstWhere((w) => w.id == 'WRK-001');
      expect(rahul.activeTaskCount, equals(2)); // Started at 1, now 2

      // 5. Switch to Field Worker account (Rahul Patil)
      await container.read(authStateProvider.notifier).switchDemoAccount(UserRole.fieldWorker);

      final workerTasks = container.read(workerTasksProvider);
      final hasNewlyAssigned = workerTasks.any((t) => t.id == 'INC-2026-001');
      expect(hasNewlyAssigned, isTrue);

      // 6. Worker resolves the task
      await container.read(allIncidentsProvider.notifier).resolve(
            incidentId: 'INC-2026-001',
            repairNotes: 'Replaced cracked 25mm PVC pipe connector.',
          );

      // 7. Verify resolution reflected in stats
      final updatedStats = container.read(incidentStatsProvider);
      expect(updatedStats.resolvedTodayCount, equals(initialStats.resolvedTodayCount + 1));

      container.dispose();
    });
  });
}
