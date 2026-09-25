import '../../models/user_model.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/errors/exceptions.dart';
import 'auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  final ApiClient _client;
  UserModel? _currentUser;

  ApiAuthRepository({ApiClient? client}) : _client = client ?? ApiClient();

  @override
  UserModel? getCurrentUser() => _currentUser;

  @override
  Future<UserModel> login({required String email, required String password}) async {
    try {
      final res = await _client.post(
        '/auth/login',
        body: {
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      );

      final token = res['token'] as String;
      await _client.setToken(token);

      final userJson = res['user'] as Map<String, dynamic>;
      final user = UserModel.fromJson(userJson);
      _currentUser = user;
      return user;
    } on ApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException('Login failed: ${e.toString()}');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _client.post('/auth/logout');
    } catch (_) {}
    await _client.setToken(null);
    _currentUser = null;
  }

  @override
  Future<UserModel> switchDemoAccount(UserRole role) async {
    final email = role.isOfficer ? 'officer@demo.com' : 'worker@demo.com';
    final password = role.isOfficer ? 'Officer@123' : 'Worker@123';
    return login(email: email, password: password);
  }
}
