import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/design/app_shapes.dart';
import '../../core/design/app_spacing.dart';
import '../../core/theme.dart';
import '../../core/widgets/gc_components.dart';
import '../../core/supabase/profile_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _profileRepository = ProfileRepository();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isOtpSent = false;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final phone = _phoneController.text.trim();
      final formattedPhone =
          phone.startsWith('+') ? phone : '+880${phone.replaceFirst(RegExp('^0'), '')}';
      await Supabase.instance.client.auth.signInWithOtp(phone: formattedPhone);
      setState(() => _isOtpSent = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code sent to your phone.')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('AuthException: ', '');
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().length != 6) {
      setState(() => _errorMessage = 'Enter the 6-digit code from your SMS.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final phone = _phoneController.text.trim();
      final formattedPhone =
          phone.startsWith('+') ? phone : '+880${phone.replaceFirst(RegExp('^0'), '')}';
      final response = await Supabase.instance.client.auth.verifyOTP(
        phone: formattedPhone,
        token: _otpController.text.trim(),
        type: OtpType.sms,
      );
      if (response.user != null) {
        await _profileRepository.ensureProfile(response.user!.id, phone: formattedPhone);
        if (mounted) context.go('/');
      } else {
        throw Exception('Verification failed. Please try again.');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('AuthException: ', '');
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: heroMeshDecoration(context)),
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.colors.primary.withValues(alpha: 0.12),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: GcCard(
                    expressive: true,
                    child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: context.colors.primaryContainer,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Icon(Icons.bolt_rounded, color: context.colors.primary, size: 32),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              'Welcome to GadgetChai',
                              style: context.text.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Sign in with your Bangladesh phone number — no password needed.',
                              style: context.text.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            if (!_isOtpSent) ...[
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: 'Phone number',
                                  hintText: '01712345678',
                                  fillColor: context.colors.surface,
                                  hintStyle: TextStyle(color: context.colors.onSurfaceVariant),
                                  labelStyle: TextStyle(color: context.colors.onSurface),
                                  prefixIcon: Icon(Icons.phone_android_rounded, color: context.colors.onSurfaceVariant),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Enter your phone number';
                                  if (value.length < 10) return 'Enter a valid phone number';
                                  return null;
                                },
                              ),
                            ] else ...[
                              Text(
                                'Code sent to ${_phoneController.text.trim()}',
                                style: context.text.bodyMedium,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              TextFormField(
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                textAlign: TextAlign.center,
                                style: context.text.displaySmall?.copyWith(letterSpacing: 8),
                                decoration: const InputDecoration(
                                  labelText: '6-digit code',
                                  counterText: '',
                                ),
                              ),
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => setState(() {
                                          _isOtpSent = false;
                                          _otpController.clear();
                                        }),
                                child: const Text('Change phone number'),
                              ),
                            ],
                            if (_errorMessage.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                _errorMessage,
                                style: TextStyle(color: context.colors.error),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: AppSpacing.xxl),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(double.infinity, 52),
                                shape: RoundedRectangleBorder(borderRadius: AppShapes.pill),
                              ),
                              onPressed: _isLoading
                                  ? null
                                  : (_isOtpSent ? _verifyOtp : _sendOtp),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Text(_isOtpSent ? 'Verify & Continue' : 'Send Verification Code'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
