import '../../domain/entities/user_preferences.dart';

class UserPreferencesModel extends UserPreferences {
  const UserPreferencesModel({
    required super.themeMode,
    required super.notificationsEnabled,
    required super.language,
    super.address,
    super.latitude,
    super.longitude,
  });

  factory UserPreferencesModel.fromJson(Map<String, dynamic> json) {
    return UserPreferencesModel(
      themeMode: (json['theme_mode'] ?? 'default').toString(),
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      language: (json['language'] ?? 'es').toString(),
      address: (json['address'] ?? json['address_text'])?.toString(),
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme_mode': themeMode,
      'notifications_enabled': notificationsEnabled,
      'language': language,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
