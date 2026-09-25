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
      if (e.code == 'UNVERIFIED_EMAIL') {
        throw AuthException('UNVERIFIED_EMAIL:${e.message}');
      }
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException('Login failed: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    String? workerId,
    String? zone,
  }) async {
    try {
      final res = await _client.post(
        '/auth/register',
        body: {
          'fullName': fullName.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
          if (phoneNumber != null && phoneNumber.trim().isNotEmpty) 'phoneNumber': phoneNumber.trim(),
          if (workerId != null && workerId.trim().isNotEmpty) 'workerId': workerId.trim().toUpperCase(),
          if (zone != null && zone.trim().isNotEmpty) 'zone': zone.trim(),
        },
      );

      return res is Map<String, dynamic> ? res : {'email': email, 'requiresVerification': true};
    } on ApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException('Registration failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> verifyEmail({required String email, required String otp}) async {
    try {
      final res = await _client.post(
        '/auth/verify-email',
        body: {
          'email': email.trim().toLowerCase(),
          'otp': otp.trim(),
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
      throw AuthException('Verification failed: ${e.toString()}');
    }
  }

  @override
  Future<void> resendOtp(String email) async {
    try {
      await _client.post(
        '/auth/resend-otp',
        body: {'email': email.trim().toLowerCase()},
      );
    } on ApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException('Failed to resend code: ${e.toString()}');
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      await _client.post(
        '/auth/forgot-password',
        body: {'email': email.trim().toLowerCase()},
      );
    } on ApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException('Password recovery request failed: ${e.toString()}');
    }
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      await _client.post(
        '/auth/reset-password',
        body: {
          'email': email.trim().toLowerCase(),
          'otp': otp.trim(),
          'newPassword': newPassword,
        },
      );
    } on ApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException('Failed to reset password: ${e.toString()}');
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
