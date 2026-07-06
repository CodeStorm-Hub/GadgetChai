import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../../core/config/app_config.dart';
import '../../core/design/app_shapes.dart';
import '../../core/design/app_spacing.dart';
import '../../core/theme.dart';
import '../../core/widgets/gc_components.dart';
import '../../core/supabase/device_repository.dart';
import '../../core/supabase/rental_repository.dart';
import 'cart_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final String deviceId;
  final int planMonths;

  const CheckoutScreen({
    super.key,
    required this.deviceId,
    required this.planMonths,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _deviceRepository = DeviceRepository();
  final _rentalRepository = RentalRepository();

  static const _stepLabels = ['Documents', 'Selfie', 'Verify', 'Payment'];

  int _currentStep = 0;
  bool _isVerifying = false;
  String? _errorMessage;

  String? _nidFrontPath;
  String? _nidBackPath;
  String? _selfiePath;

  bool _kycVerified = false;
  String _kycStatus = 'none';
  double _similarityScore = 0.0;
  double _securityDeposit = 0.0;
  String _extractedName = '';
  String _extractedNid = '';

  Map<String, dynamic>? _device;

  @override
  void initState() {
    super.initState();
    _fetchDeviceDetails();
  }

  Future<void> _fetchDeviceDetails() async {
    try {
      final device = await _deviceRepository.fetchById(widget.deviceId);
      setState(() {
        _device = device;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load device: $e';
      });
    }
  }

  double _getMonthlyPrice() {
    if (_device == null) return 0;
    switch (widget.planMonths) {
      case 1:
        return (_device!['monthly_price_1m'] as num).toDouble();
      case 3:
        return (_device!['monthly_price_3m'] as num).toDouble();
      case 6:
        return (_device!['monthly_price_6m'] as num).toDouble();
      case 12:
        return (_device!['monthly_price_12m'] as num).toDouble();
      default:
        return (_device!['monthly_price_3m'] as num).toDouble();
    }
  }

  Future<void> _runEkycPipeline() async {
    setState(() {
      _isVerifying = true;
      _currentStep = 2;
    });

    final userId = Supabase.instance.client.auth.currentUser!.id;

    try {
      final uri = Uri.parse(AppConfig.verifyKycUrl);
      final request = http.MultipartRequest('POST', uri);

      request.fields['user_id'] = userId;
      request.files.add(await http.MultipartFile.fromPath('nid_front', _nidFrontPath!));
      request.files.add(await http.MultipartFile.fromPath('nid_back', _nidBackPath!));
      request.files.add(await http.MultipartFile.fromPath('selfie', _selfiePath!));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _kycVerified = data['verified'] ?? false;
          _kycStatus = data['status'] ?? 'rejected';
          _similarityScore = (data['similarity_score'] as num?)?.toDouble() ?? 0.0;

          final extData = data['extracted_data'] ?? {};
          _extractedName = extData['name'] ?? '';
          _extractedNid = extData['nid_number'] ?? '';

          if (_kycStatus == 'pending') {
            _securityDeposit = 2500.0;
          } else if (_kycStatus == 'rejected') {
            _securityDeposit = 5000.0;
          } else {
            _securityDeposit = 0.0;
          }
          _errorMessage = null;
        });
      } else {
        throw Exception('KYC server error: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'KYC verification failed: $e';
        _kycVerified = false;
        _kycStatus = 'rejected';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() {
        _isVerifying = false;
        _currentStep = 3;
      });
    }
  }

  Future<void> _proceedToBkash() async {
    setState(() => _isVerifying = true);

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _isVerifying = false);
      return;
    }

    try {
      final monthlyPrice = _getMonthlyPrice();
      final rentalRes = await _rentalRepository.createRental(
        userId: user.id,
        deviceId: widget.deviceId,
        planMonths: widget.planMonths,
        monthlyPrice: monthlyPrice,
        securityDeposit: _securityDeposit,
      );

      final rentalId = rentalRes['id'] as String;
      String redirectUrl;

      try {
        final edgeResponse = await Supabase.instance.client.functions.invoke(
          'bkash-webhook',
          body: {
            'action': 'create-agreement',
            'rental_id': rentalId,
          },
        );
        final data = edgeResponse.data;
        if (data is Map && data['redirect_url'] != null) {
          redirectUrl = data['redirect_url'] as String;
        } else {
          redirectUrl =
              '${AppConfig.supabaseUrl}/functions/v1/bkash-webhook?action=execute-agreement&rental_id=$rentalId';
        }
      } catch (_) {
        redirectUrl =
            '${AppConfig.supabaseUrl}/functions/v1/bkash-webhook?action=execute-agreement&rental_id=$rentalId';
      }

      ref.read(cartProvider.notifier).clearCart();
      if (!mounted) return;
      context.push('/checkout/bkash-webview', extra: {
        'redirectUrl': redirectUrl,
        'rentalId': rentalId,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checkout failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Secure checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GcStepIndicator(steps: _stepLabels, currentStep: _currentStep),
                const SizedBox(height: AppSpacing.xl),
                if (_device != null) _buildOrderSummary(context),
                const SizedBox(height: AppSpacing.lg),
                GcCard(
                  child: _buildStepContent(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary(BuildContext context) {
    return GcCard(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: AppShapes.image,
            child: Image.network(
              _device!['image_url'] as String? ?? '',
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 56,
                height: 56,
                color: context.colors.surfaceContainerHigh,
                child: Icon(Icons.devices, color: context.colors.primary),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_device!['name'] as String? ?? '', style: context.text.titleMedium),
                Text(
                  '${widget.planMonths}-month plan',
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          GcPriceTag(amount: _getMonthlyPrice(), compact: true),
        ],
      ),
    );
  }

  Widget _buildStepContent(BuildContext context) {
    switch (_currentStep) {
      case 0:
        return _buildDocumentCaptureStep(context);
      case 1:
        return _buildSelfieStep(context);
      case 2:
        return _buildVerifyingStep(context);
      default:
        return _buildKycSummaryStep(context);
    }
  }

  Widget _buildDocumentCaptureStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('ID document verification', style: context.text.displaySmall),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Capture the front and back of your Bangladesh NID card.',
          style: context.text.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        _buildUploadCard(
          label: 'NID front photo',
          path: _nidFrontPath,
          onTap: () => context.push('/checkout/camera', extra: {
            'type': 'back',
            'onCapture': (path) => setState(() => _nidFrontPath = path),
          }),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildUploadCard(
          label: 'NID back photo',
          path: _nidBackPath,
          onTap: () => context.push('/checkout/camera', extra: {
            'type': 'back',
            'onCapture': (path) => setState(() => _nidBackPath = path),
          }),
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          onPressed: (_nidFrontPath != null && _nidBackPath != null)
              ? () => setState(() => _currentStep = 1)
              : null,
          child: const Text('Continue to selfie'),
        ),
      ],
    );
  }

  Widget _buildSelfieStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Biometric liveness check', style: context.text.displaySmall),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Ensure your face is well-lit and centered in the frame.',
          style: context.text.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        _buildUploadCard(
          label: 'Take selfie',
          path: _selfiePath,
          onTap: () => context.push('/checkout/camera', extra: {
            'type': 'front',
            'onCapture': (path) => setState(() => _selfiePath = path),
          }),
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          onPressed: _selfiePath != null ? _runEkycPipeline : null,
          child: const Text('Start face matching'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: () => setState(() => _currentStep = 0),
          child: const Text('Back to documents'),
        ),
      ],
    );
  }

  Widget _buildVerifyingStep(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.xl),
          Text('Processing e-KYC…', style: context.text.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Running OCR extraction and facial comparison between your NID and selfie.',
            textAlign: TextAlign.center,
            style: context.text.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildKycSummaryStep(BuildContext context) {
    final monthlyPrice = _getMonthlyPrice();
    final totalInitialCharge = monthlyPrice + _securityDeposit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              _kycVerified ? Icons.verified_rounded : Icons.warning_amber_rounded,
              color: _kycVerified ? context.colors.secondary : AppColors.warning,
              size: 32,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                _kycVerified ? 'Verification approved' : 'Manual review flagged',
                style: context.text.displaySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        GcCard(
          child: Column(
            children: [
              _buildSummaryRow('Name', _extractedName),
              const Divider(),
              _buildSummaryRow('NID number', _extractedNid),
              const Divider(),
              _buildSummaryRow('Match confidence', '${(_similarityScore * 100).toInt()}%'),
              const Divider(),
              _buildSummaryRow('KYC status', _kycStatus.toUpperCase()),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Billing breakdown', style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: AppSpacing.md),
        GcCard(
          color: context.colors.surfaceContainerLow,
          child: Column(
            children: [
              _buildSummaryRow('1st month rent', '৳${monthlyPrice.toInt()}'),
              const SizedBox(height: AppSpacing.sm),
              _buildSummaryRow(
                'Security deposit',
                _securityDeposit == 0 ? '৳0 (waived)' : '৳${_securityDeposit.toInt()}',
                valueColor: _securityDeposit == 0 ? context.colors.secondary : AppColors.warning,
              ),
              const Divider(height: AppSpacing.xl),
              _buildSummaryRow(
                'Initial bKash charge',
                '৳${totalInitialCharge.toInt()}',
                valueColor: context.colors.primary,
                bold: true,
              ),
            ],
          ),
        ),
        if (_securityDeposit > 0) ...[
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.warningContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppShapes.sm),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'A security deposit is required due to a marginal trust score. Fully refundable on return.',
                    style: context.text.bodySmall?.copyWith(color: AppColors.onWarningContainer),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          onPressed: _isVerifying ? null : _proceedToBkash,
          child: _isVerifying
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Authorize bKash & pay'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: () => setState(() {
            _currentStep = 0;
            _nidFrontPath = null;
            _nidBackPath = null;
            _selfiePath = null;
          }),
          child: const Text('Re-verify KYC'),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: context.text.bodyMedium),
          Text(
            value,
            style: context.text.titleSmall?.copyWith(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadCard({
    required String label,
    required String? path,
    required VoidCallback onTap,
  }) {
    final scheme = context.colors;
    final content = Container(
      height: 140,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppShapes.md),
        border: path != null
            ? Border.all(color: scheme.primary, width: 1.5)
            : null,
      ),
      child: path == null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt_rounded, color: scheme.primary, size: 32),
                const SizedBox(height: AppSpacing.md),
                Text(label, style: context.text.labelLarge),
              ],
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(AppShapes.md),
              child: Image.file(
                File(path),
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, _, _) => Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded, color: context.colors.secondary, size: 24),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '$label uploaded',
                        style: context.text.labelLarge?.copyWith(color: context.colors.secondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );

    return GestureDetector(
      onTap: onTap,
      child: path == null
          ? CustomPaint(
              painter: _GcDashedBorderPainter(
                color: scheme.primary.withValues(alpha: 0.55),
                radius: AppShapes.md,
              ),
              child: content,
            )
          : content,
    );
  }
}

class _GcDashedBorderPainter extends CustomPainter {
  const _GcDashedBorderPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;
  static const double _strokeWidth = 2;
  static const double _dashLength = 7;
  static const double _gapLength = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            _strokeWidth / 2,
            _strokeWidth / 2,
            size.width - _strokeWidth,
            size.height - _strokeWidth,
          ),
          Radius.circular(radius),
        ),
      );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + _dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += _dashLength + _gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GcDashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

class CheckoutStatusScreen extends StatelessWidget {
  final String status;
  final String rentalId;
  final String message;

  const CheckoutStatusScreen({
    super.key,
    required this.status,
    required this.rentalId,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isSuccess = status == 'success';

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: GcCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                  color: isSuccess ? context.colors.secondary : context.colors.error,
                  size: 80,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  isSuccess ? 'Rental subscribed!' : 'Transaction failed',
                  style: context.text.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  isSuccess
                      ? 'Your bKash recurring billing agreement is active. A rider will verify your delivery OTP at handover.'
                      : 'Message: ${Uri.decodeComponent(message.isNotEmpty ? message : 'Payment authorization was cancelled or failed.')}',
                  textAlign: TextAlign.center,
                  style: context.text.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.go(isSuccess ? '/my-tech' : '/'),
                    child: Text(isSuccess ? 'Go to My Tech' : 'Back to catalog'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
