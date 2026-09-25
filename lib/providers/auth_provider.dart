import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/api_auth_repository.dart';
import 'incident_provider.dart';
import 'worker_provider.dart';
import 'notification_provider.dart';
import 'sensor_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return ApiAuthRepository();
});

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated => user != null;
  bool get isOfficer => user?.role.isOfficer ?? false;
  bool get isWorker => user?.role.isWorker ?? false;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final Ref _ref;

  AuthNotifier(this._repository, this._ref)
      : super(AuthState(user: _repository.getCurrentUser()));

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.login(email: email, password: password);
      if (!mounted) return true;
      state = state.copyWith(user: user, isLoading: false);

      // Refresh all feature data providers upon successful authentication
      try {
        _ref.read(allIncidentsProvider.notifier).refresh();
        _ref.read(workersListProvider.notifier).refresh();
        _ref.read(sensorsListProvider.notifier).refresh();
        _ref.read(userNotificationsProvider.notifier).refresh();
      } catch (_) {}

      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _repository.logout();
    if (!mounted) return;
    state = const AuthState(user: null);
  }

  Future<void> switchDemoAccount(UserRole role) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.switchDemoAccount(role);
      if (!mounted) return;
      state = state.copyWith(user: user, isLoading: false);

      try {
        _ref.read(allIncidentsProvider.notifier).refresh();
        _ref.read(workersListProvider.notifier).refresh();
        _ref.read(sensorsListProvider.notifier).refresh();
        _ref.read(userNotificationsProvider.notifier).refresh();
      } catch (_) {}
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo, ref);
});
