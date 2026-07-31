import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/api_session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;

  AuthRepositoryImpl({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  @override
  Future<UserEntity?> login(String username, String password) async {
    final data = await _apiClient.postJson('/api/auth/login', {
      'community_slug': ApiConfig.communitySlug,
      'email': username,
      'password': password,
    });

    final token = (data['access_token'] ?? '').toString();
    if (token.isEmpty) return null;

    ApiSession.instance.accessToken = token;
    ApiSession.instance.realtimeToken = (data['realtime_token'] ?? '')
        .toString();
    if (ApiConfig.supabaseUrl.isNotEmpty &&
        ApiConfig.supabasePublishableKey.isNotEmpty &&
        ApiSession.instance.realtimeToken!.isNotEmpty) {
      await Supabase.instance.client.realtime.setAuth(
        ApiSession.instance.realtimeToken!,
      );
    }

    final userJson = (data['user'] as Map?)?.cast<String, dynamic>() ?? {};
    ApiSession.instance.userId = (userJson['id'] ?? '').toString();
    ApiSession.instance.communityId = (userJson['community_id'] ?? '')
        .toString();
    ApiSession.instance.userRole = (userJson['role'] ?? '').toString();
    return UserModel.fromJson(userJson);
  }

  @override
  Future<bool> resetPassword(String username, String newPassword) async {
    final data = await _apiClient
        .postJson('/api/auth/password-change-request', {
          'community_slug': ApiConfig.communitySlug,
          'email': username,
          'new_password': newPassword,
        });
    return data['success'] == true;
  }
}
