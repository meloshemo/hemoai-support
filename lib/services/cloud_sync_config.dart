class CloudSyncConfig {
  // Configure via --dart-define at build/run time to avoid hardcoding secrets
  // Example:
  // flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  // Storage bucket name for encrypted backups (create in Supabase Storage)
  static const storageBucket = String.fromEnvironment('SUPABASE_BACKUP_BUCKET', defaultValue: 'hemoai-backups');

  static bool get isConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
