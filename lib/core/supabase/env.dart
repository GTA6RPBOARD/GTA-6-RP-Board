class AppEnv {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured =>
      supabaseUrl.startsWith('https://') && supabaseAnonKey.length > 20;

  static const oauthRedirect = 'io.gta6rpboard.app://login-callback/';
}
