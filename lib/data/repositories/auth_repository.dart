import '../../models/user_model.dart';
import '../../core/errors/exceptions.dart';
import '../mock_data/mock_users.dart';
import 'mock_data_store.dart';

abstract class AuthRepository {
  Future<UserModel> login({required String email, required String password});
  UserModel? getCurrentUser();
  Future<void> logout();
  Future<UserModel> switchDemoAccount(UserRole role);
}

class MockAuthRepository implements AuthRepository {
  final MockDataStore _store;

  MockAuthRepository({MockDataStore? store}) : _store = store ?? MockDataStore();

  @override
  Future<UserModel> login({required String email, required String password}) async {
    // Simulate brief network delay
    await Future.delayed(const Duration(milliseconds: 350));

    final normalizedEmail = email.trim().toLowerCase();
    final expectedPassword = MockUsers.userPasswords[normalizedEmail];

    if (expectedPassword == null) {
      throw AuthException('No account found with email "$email". Please use a demo account.');
    }

    if (expectedPassword != password) {
      throw AuthException('Incorrect password. Please verify credentials.');
    }

    final user = _store.users.firstWhere(
      (u) => u.email.toLowerCase() == normalizedEmail,
      orElse: () => throw AuthException('User profile data missing.'),
    );

    _store.currentUser = user;
    return user;
  }

  @override
  UserModel? getCurrentUser() {
    return _store.currentUser;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _store.currentUser = null;
  }

  @override
  Future<UserModel> switchDemoAccount(UserRole role) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final targetUser = role.isOfficer ? MockUsers.officerRajesh : MockUsers.workerRahul;
    _store.currentUser = targetUser;
    return targetUser;
  }
}
