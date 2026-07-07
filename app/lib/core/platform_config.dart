import 'package:flutter/foundation.dart';

/// Android-first platform defaults. Web is optional.
class PlatformConfig {
  /// Deep link scheme for Supabase email confirm / password reset on Android.
  static const authRedirectScheme = 'gadgetchai';
  static const authRedirectHost = 'auth';

  /// Base URL the bKash edge function uses to redirect after payment.
  /// Must match `CLIENT_APP_URL` in Supabase edge secrets for the platform you test.
  static String get clientAppUrl {
    const fromEnv = String.fromEnvironment('CLIENT_APP_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) return 'http://localhost:3000';
    return '$authRedirectScheme://';
  }

  static String get authEmailRedirectTo {
    if (kIsWeb) {
      return clientAppUrl.replaceAll(RegExp(r'/$'), '');
    }
    return '$authRedirectScheme://$authRedirectHost';
  }

  /// Whether [url] is a post-checkout status redirect (web path or Android deep link).
  static bool isCheckoutStatusUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    if (uri.path.contains('/checkout/status')) return true;

    if (uri.scheme == authRedirectScheme) {
      if (uri.host == 'checkout' && uri.path == '/status') return true;
      if (uri.path == '/checkout/status') return true;
    }

    return uri.queryParameters.containsKey('status') &&
        uri.queryParameters.containsKey('rental_id');
  }

  static CheckoutStatusParams? parseCheckoutStatusUrl(String url) {
    if (!isCheckoutStatusUrl(url)) return null;
    final uri = Uri.parse(url);
    return CheckoutStatusParams(
      status: uri.queryParameters['status'] ?? 'failed',
      rentalId: uri.queryParameters['rental_id'] ?? '',
      message: uri.queryParameters['message'] ?? '',
    );
  }
}

class CheckoutStatusParams {
  const CheckoutStatusParams({
    required this.status,
    required this.rentalId,
    required this.message,
  });

  final String status;
  final String rentalId;
  final String message;
}
