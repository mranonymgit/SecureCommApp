class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'SCA_API_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const String communitySlug = String.fromEnvironment(
    'SCA_COMMUNITY_SLUG',
    defaultValue: 'sca',
  );
}
