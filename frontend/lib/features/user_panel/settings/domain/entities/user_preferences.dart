class UserPreferences {
  final String themeMode;
  final bool notificationsEnabled;
  final String language;
  final String? address;
  final double? latitude;
  final double? longitude;

  const UserPreferences({
    required this.themeMode,
    required this.notificationsEnabled,
    required this.language,
    this.address,
    this.latitude,
    this.longitude,
  });

  UserPreferences copyWith({
    String? themeMode,
    bool? notificationsEnabled,
    String? language,
    String? address,
    double? latitude,
    double? longitude,
  }) {
    return UserPreferences(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      language: language ?? this.language,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
