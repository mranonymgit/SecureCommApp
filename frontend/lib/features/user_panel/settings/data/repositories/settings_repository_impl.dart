import 'dart:typed_data';

import '../../../../../core/network/api_client.dart';
import '../../domain/entities/faq_item.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/entities/rule_item.dart';
import '../../domain/entities/user_preferences.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/settings_repository.dart';
import '../models/faq_item_model.dart';
import '../models/notification_item_model.dart';
import '../models/rule_item_model.dart';
import '../models/user_preferences_model.dart';
import '../models/user_profile_model.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<List<RuleItem>> getCommunityRules() async {
    final items = await _apiClient.getList('/api/community/rules');
    return items
        .cast<Map<String, dynamic>>()
        .map(RuleItemModel.fromJson)
        .toList(growable: false);
  }

  @override
  Future<List<FaqItem>> getFaqs() async {
    final items = await _apiClient.getList('/api/community/faqs');
    return items
        .cast<Map<String, dynamic>>()
        .map(FaqItemModel.fromJson)
        .toList(growable: false);
  }

  @override
  Future<List<NotificationItem>> getNotifications() async {
    final items = await _apiClient.getList('/api/me/notifications');
    return items
        .cast<Map<String, dynamic>>()
        .map(NotificationItemModel.fromJson)
        .toList(growable: false);
  }

  @override
  Future<void> submitFaqQuestion(String question) async {
    await _apiClient.postJson('/api/community/faqs/questions', {
      'question': question,
    });
  }

  @override
  Future<UserProfile> getProfile() async {
    final data = await _apiClient.getJson('/api/me/profile');
    return UserProfileModel.fromJson(data);
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    final payload = UserProfileModel(
      id: profile.id,
      fullName: profile.fullName,
      email: profile.email,
      phone: profile.phone,
      avatarUrl: profile.avatarUrl,
      address: profile.address,
      latitude: profile.latitude,
      longitude: profile.longitude,
    ).toJson();
    final data = await _apiClient.patchJson('/api/me/profile', payload);
    return UserProfileModel.fromJson(data);
  }

  Future<String> uploadAvatar(Uint8List bytes, String filename) async {
    final contentType = filename.toLowerCase().endsWith('.png')
        ? 'image/png'
        : filename.toLowerCase().endsWith('.webp')
        ? 'image/webp'
        : 'image/jpeg';
    final data = await _apiClient.uploadBytes(
      '/api/storage/avatar',
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    );
    return (data['object_path'] ?? '').toString();
  }

  @override
  Future<UserPreferences> getPreferences() async {
    final data = await _apiClient.getJson('/api/me/preferences');
    return UserPreferencesModel.fromJson(data);
  }

  @override
  Future<UserPreferences> updatePreferences(UserPreferences preferences) async {
    final payload = UserPreferencesModel(
      themeMode: preferences.themeMode,
      notificationsEnabled: preferences.notificationsEnabled,
      language: preferences.language,
      address: preferences.address,
      latitude: preferences.latitude,
      longitude: preferences.longitude,
    ).toJson();
    final data = await _apiClient.patchJson('/api/me/preferences', payload);
    return UserPreferencesModel.fromJson(data);
  }

  @override
  Future<void> markNotificationRead(String id) async {
    await _apiClient.patchJson('/api/me/notifications/$id/read', {});
  }

  @override
  Future<void> deleteNotification(String id) async {
    await _apiClient.deleteJson('/api/me/notifications/$id');
  }
}
