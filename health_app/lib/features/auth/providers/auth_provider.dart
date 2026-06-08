import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

// Providers
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(apiClientProvider));
});

// Auth State
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthInitial()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    final isAuth = await _authService.isAuthenticated();
    if (isAuth) {
      try {
        final profile = await _authService.getProfile();
        state = AuthAuthenticated(
          UserModel(
            id: profile.userId,
            email: '',
            isActive: true,
            fullName: profile.fullName,
          ),
        );
      } catch (_) {
        state = const AuthUnauthenticated();
      }
    } else {
      state = const AuthUnauthenticated();
    }
  }

  Future<bool> login(String email, String password) async {
    state = const AuthLoading();
    try {
      final tokenResponse =
          await _authService.login(email: email, password: password);
      state = AuthAuthenticated(tokenResponse.user);
      return true;
    } catch (e) {
      state = AuthError(_parseError(e));
      return false;
    }
  }

  Future<bool> register(
      String email, String password, String fullName) async {
    state = const AuthLoading();
    try {
      final tokenResponse = await _authService.register(
        email: email,
        password: password,
        fullName: fullName,
      );
      state = AuthAuthenticated(tokenResponse.user);
      return true;
    } catch (e) {
      state = AuthError(_parseError(e));
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthUnauthenticated();
  }

  String _parseError(dynamic e) {
    if (e.toString().contains('401')) return 'Invalid email or password.';
    if (e.toString().contains('422')) return 'Please check your input.';
    if (e.toString().contains('409')) return 'Email already registered.';
    if (e.toString().contains('SocketException') ||
        e.toString().contains('Connection')) {
      return 'Connection failed. Check your internet.';
    }
    return 'Something went wrong. Please try again.';
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});

// Profile state
class ProfileNotifier extends StateNotifier<AsyncValue<ProfileModel?>> {
  final AuthService _authService;

  ProfileNotifier(this._authService) : super(const AsyncValue.data(null));

  Future<void> loadProfile() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authService.getProfile());
  }

  Future<bool> saveProfile(ProfileModel profile) async {
    try {
      final saved = await _authService.setupProfile(profile);
      state = AsyncValue.data(saved);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateProfile(ProfileModel profile) async {
    try {
      final updated = await _authService.updateProfile(profile);
      state = AsyncValue.data(updated);
      return true;
    } catch (e) {
      return false;
    }
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<ProfileModel?>>((ref) {
  return ProfileNotifier(ref.watch(authServiceProvider));
});