import 'package:flutter_test/flutter_test.dart';
import 'package:water_watch/data/repositories/mock_data_store.dart';
import 'package:water_watch/data/repositories/auth_repository.dart';
import 'package:water_watch/models/user_model.dart';
import 'package:water_watch/core/errors/exceptions.dart';
import 'package:water_watch/core/constants/app_constants.dart';

void main() {
  group('AuthRepository & Role-Based Access Tests', () {
    late MockDataStore store;
    late MockAuthRepository authRepo;

    setUp(() {
      store = MockDataStore();
      store.resetToDefaults();
      authRepo = MockAuthRepository(store: store);
    });

    test('Valid Officer Login returns Municipal Officer profile', () async {
      final user = await authRepo.login(
        email: AppConstants.officerDemoEmail,
        password: AppConstants.officerDemoPassword,
      );

      expect(user.id, equals(AppConstants.officerDefaultId));
      expect(user.name, equals(AppConstants.officerDefaultName));
      expect(user.role, equals(UserRole.municipalOfficer));
      expect(user.role.isOfficer, isTrue);
      expect(user.role.isWorker, isFalse);
    });

    test('Valid Field Worker Login maps to Rahul Patil (WRK-001)', () async {
      final user = await authRepo.login(
        email: AppConstants.workerDemoEmail,
        password: AppConstants.workerDemoPassword,
      );

      expect(user.id, equals(AppConstants.workerDefaultUserId));
      expect(user.name, equals(AppConstants.workerDefaultName));
      expect(user.workerId, equals(AppConstants.workerDefaultWorkerId));
      expect(user.role, equals(UserRole.fieldWorker));
      expect(user.role.isWorker, isTrue);
    });

    test('Invalid Credentials throw AuthException', () async {
      expect(
        () async => await authRepo.login(
          email: 'unknown@city.gov',
          password: 'Password@123',
        ),
        throwsA(isA<AuthException>()),
      );

      expect(
        () async => await authRepo.login(
          email: AppConstants.officerDemoEmail,
          password: 'WrongPassword!',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('Switch Demo Account seamlessly switches between Officer and Worker', () async {
      final worker = await authRepo.switchDemoAccount(UserRole.fieldWorker);
      expect(worker.role, equals(UserRole.fieldWorker));
      expect(authRepo.getCurrentUser()?.role, equals(UserRole.fieldWorker));

      final officer = await authRepo.switchDemoAccount(UserRole.municipalOfficer);
      expect(officer.role, equals(UserRole.municipalOfficer));
      expect(authRepo.getCurrentUser()?.role, equals(UserRole.municipalOfficer));
    });
  });
}
