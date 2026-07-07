import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/config/app_config.dart';
import '../../core/platform_config.dart';
import '../../core/theme.dart';

class BkashAgreementWebview extends StatefulWidget {
  final String redirectUrl;
  final String rentalId;

  const BkashAgreementWebview({
    super.key,
    required this.redirectUrl,
    this.rentalId = '',
  });

  @override
  State<BkashAgreementWebview> createState() => _BkashAgreementWebviewState();
}

class _BkashAgreementWebviewState extends State<BkashAgreementWebview> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    final redirectUrl = widget.redirectUrl.trim();
    if (redirectUrl.isEmpty) {
      _errorMessage = 'No bKash payment URL was returned. Check sandbox credentials.';
      _isLoading = false;
      return;
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: (request) {
            final url = request.url;
            if (_handleReturnUrl(url)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            setState(() {
              _errorMessage = error.description;
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(redirectUrl));
  }

  bool _handleReturnUrl(String url) {
    final clientBase = AppConfig.clientAppUrl.replaceAll(RegExp(r'/$'), '');
    final statusPrefixes = [
      clientBase,
      '${AppConfig.supabaseUrl}/functions/v1/bkash-webhook',
      '${PlatformConfig.authRedirectScheme}://',
    ];

    final isReturn = statusPrefixes.any((prefix) => url.startsWith(prefix));
    if (!isReturn) return false;

    final params = PlatformConfig.parseCheckoutStatusUrl(url);
    if (params != null) {
      if (!mounted) return true;
      context.go(
        '/checkout/status?status=${params.status}&rental_id=${params.rentalId}&message=${Uri.encodeComponent(params.message)}',
      );
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('bKash payment')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Back to catalog'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('bKash secure payment'),
        backgroundColor: AppColors.bkashPink,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
