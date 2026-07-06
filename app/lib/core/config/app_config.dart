class AppConfig {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://fsdfqcnjcjtdmdjshrvu.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const kycServiceUrl = String.fromEnvironment(
    'KYC_SERVICE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static String get verifyKycUrl => '$kycServiceUrl/verify_kyc';
}
