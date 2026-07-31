class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'SCA_API_URL',
    defaultValue: 'https://securecommapp-backend.onrender.com',
  );

  static const String communitySlug = String.fromEnvironment(
    'SCA_COMMUNITY_SLUG',
    defaultValue: 'sca',
  );

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static const String _supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static String get supabasePublishableKey => _supabasePublishableKey.isNotEmpty
      ? _supabasePublishableKey
      : _supabaseAnonKey;
}
