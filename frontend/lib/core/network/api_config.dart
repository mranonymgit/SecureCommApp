class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'SCA_API_URL',
    defaultValue: 'https://securecommapp-backend.onrender.com',
  );

  static const String communitySlug = String.fromEnvironment(
    'SCA_COMMUNITY_SLUG',
    defaultValue: 'sca',
  );
}
