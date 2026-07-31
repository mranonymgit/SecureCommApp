import '../entities/faq_item.dart';
import '../entities/notification_item.dart';
import '../entities/rule_item.dart';
import '../entities/user_profile.dart';
import '../entities/user_preferences.dart';

abstract class SettingsRepository {
  Future<List<RuleItem>> getCommunityRules();
  Future<List<FaqItem>> getFaqs();
  Future<List<NotificationItem>> getNotifications();
  Future<void> submitFaqQuestion(String question);
  Future<UserProfile> getProfile();
  Future<UserProfile> updateProfile(UserProfile profile);
  Future<UserPreferences> getPreferences();
  Future<UserPreferences> updatePreferences(UserPreferences preferences);
  Future<void> markNotificationRead(String id);
  Future<void> deleteNotification(String id);
}
