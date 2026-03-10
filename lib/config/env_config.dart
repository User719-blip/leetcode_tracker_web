/// Environment configuration for the application.
///
/// Uses compile-time environment variables (--dart-define flags) for configuration.
/// This approach works for all platforms including Flutter web on static hosting
/// like GitHub Pages.
///
/// Example usage:
/// ```
/// flutter run --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key
/// flutter build web --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key
/// ```
class EnvConfig {
  /// Application environment (dev, staging, prod)
  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  /// Supabase project URL
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  /// Supabase anonymous/public key
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Whether we're running in production mode
  static bool get isProduction =>
      appEnv.toLowerCase() == 'prod' || appEnv.toLowerCase() == 'production';

  /// Whether we're running in development mode
  static bool get isDevelopment =>
      appEnv.toLowerCase() == 'dev' || appEnv.toLowerCase() == 'development';

  /// Validates that all required environment variables are set
  static void validate() {
    if (supabaseUrl.isEmpty) {
      throw StateError(
        'SUPABASE_URL is not set. '
        'Please provide it via --dart-define=SUPABASE_URL=your_url',
      );
    }

    if (supabaseAnonKey.isEmpty) {
      throw StateError(
        'SUPABASE_ANON_KEY is not set. '
        'Please provide it via --dart-define=SUPABASE_ANON_KEY=your_key',
      );
    }
  }
}
