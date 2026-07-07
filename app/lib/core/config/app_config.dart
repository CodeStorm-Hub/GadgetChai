import '../platform_config.dart';

class AppConfig {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://fsdfqcnjcjtdmdjshrvu.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static String get bkashCreateAgreementUrl =>
      '$supabaseUrl/functions/v1/bkash-webhook?action=create-agreement';

  static String get bkashCreateInitialPaymentUrl =>
      '$supabaseUrl/functions/v1/bkash-webhook?action=create-initial-payment';

  /// Sandbox test wallet (merchant demo): 01770618575 · PIN 12121 · OTP 123456
  static const bkashSandboxWallet = '01770618575';

  static const kycServiceUrl = String.fromEnvironment(
    'KYC_SERVICE_URL',
    defaultValue: 'https://kycservice.vercel.app',
  );

  /// Android default: `gadgetchai://` · Web default: `http://localhost:3000`
  static String get clientAppUrl => PlatformConfig.clientAppUrl;

  static String get authEmailRedirectTo => PlatformConfig.authEmailRedirectTo;

  static String get verifyKycUrl => '$kycServiceUrl/verify_kyc';
}
