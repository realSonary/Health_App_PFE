import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_constants.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiClient _client;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthService(this._client);

  Future<TokenResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    final tokenResponse =
        TokenResponse.fromJson(response.data as Map<String, dynamic>);
    await _persistToken(tokenResponse);
    return tokenResponse;
  }

  Future<TokenResponse> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _client.post(
      '/auth/register',
      data: {
        'email': email,
        'password': password,
        'full_name': fullName,
      },
    );
    final tokenResponse =
        TokenResponse.fromJson(response.data as Map<String, dynamic>);
    await _persistToken(tokenResponse);
    return tokenResponse;
  }

  /// Step 1 of the forgot-password flow: asks the backend to e-mail a reset code.
  Future<void> forgotPassword(String email) async {
    await _client.post(
      '/auth/forgot-password',
      data: {'email': email},
    );
  }

  /// Step 2: submits the reset code and the new password.
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _client.post(
      '/auth/reset-password',
      data: {
        'email': email,
        'code': code,
        'new_password': newPassword,
      },
    );
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    return token != null;
  }

  Future<void> _persistToken(TokenResponse tokenResponse) async {
    await _storage.write(
      key: AppConstants.accessTokenKey,
      value: tokenResponse.accessToken,
    );
    await _storage.write(
      key: AppConstants.userIdKey,
      value: tokenResponse.user.id.toString(),
    );
  }

  Future<ProfileModel> setupProfile(ProfileModel profile) async {
    final response = await _client.post(
      '/profile',
      data: profile.toJson(),
    );
    return ProfileModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ProfileModel> getProfile() async {
    final response = await _client.get('/profile');
    return ProfileModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ProfileModel> updateProfile(ProfileModel profile) async {
    final response = await _client.put(
      '/profile',
      data: profile.toJson(),
    );
    return ProfileModel.fromJson(response.data as Map<String, dynamic>);
  }
}
