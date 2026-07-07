import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/app_config.dart';
import '../../core/design/app_shapes.dart';
import '../../core/design/app_spacing.dart';
import '../../core/theme.dart';
import '../../core/widgets/gc_components.dart';
import '../../core/supabase/profile_repository.dart';
import '../../core/supabase/referral_repository.dart';

enum _AuthMode { signIn, signUp, confirmPending, forgotPassword, updatePassword }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _profileRepository = ProfileRepository();
  final _referralRepository = ReferralRepository();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _referralCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  _AuthMode _mode = _AuthMode.signIn;
  bool _isLoading = false;
  String _errorMessage = '';
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery && mounted) {
        setState(() => _mode = _AuthMode.updatePassword);
      }
      if (data.event == AuthChangeEvent.signedIn &&
          data.session != null &&
          _mode != _AuthMode.updatePassword &&
          mounted) {
        _onSignedIn(data.session!.user);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  String get _emailRedirectTo => AppConfig.authEmailRedirectTo;

  Future<void> _onSignedIn(User user) async {
    await _profileRepository.ensureProfile(
      user.id,
      fullName: user.userMetadata?['full_name'] as String?,
    );

    final referralCode = _referralCodeController.text.trim();
    if (referralCode.isNotEmpty) {
      try {
        final result = await _referralRepository.applyReferralCode(referralCode);
        if (result['success'] != true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] as String? ?? 'Referral code could not be applied.')),
          );
        }
      } catch (_) {
        // Non-blocking — account still works without referral
      }
    }

    if (mounted) context.go('/');
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on AuthException catch (e) {
      final message = e.message.toLowerCase();
      if (message.contains('email not confirmed')) {
        setState(() {
          _mode = _AuthMode.confirmPending;
          _errorMessage = '';
        });
      } else {
        setState(() => _errorMessage = e.message);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {
          if (_fullNameController.text.trim().isNotEmpty)
            'full_name': _fullNameController.text.trim(),
        },
        emailRedirectTo: _emailRedirectTo,
      );
      if (response.session == null) {
        setState(() => _mode = _AuthMode.confirmPending);
      } else if (response.user != null) {
        await _onSignedIn(response.user!);
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendConfirmation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: _emailController.text.trim(),
        emailRedirectTo: _emailRedirectTo,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Confirmation email sent again.')),
        );
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Enter your email address.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        _emailController.text.trim(),
        redirectTo: _emailRedirectTo,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset link sent to your email.')),
        );
        setState(() => _mode = _AuthMode.signIn);
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePassword() async {
    if (_passwordController.text.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters.');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passwordController.text),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully.')),
        );
        context.go('/');
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _switchMode(_AuthMode mode) {
    setState(() {
      _mode = mode;
      _errorMessage = '';
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
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
                              child: Icon(
                                Icons.bolt_rounded,
                                color: context.colors.primary,
                                size: 32,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            _title,
                            style: context.text.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            _subtitle,
                            style: context.text.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          ..._buildFields(),
                          if (_errorMessage.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              _errorMessage,
                              style: TextStyle(color: context.colors.error),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.xxl),
                          ..._buildActions(),
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

  String get _title {
    switch (_mode) {
      case _AuthMode.signIn:
        return 'Welcome to GadgetChai';
      case _AuthMode.signUp:
        return 'Create your account';
      case _AuthMode.confirmPending:
        return 'Check your email';
      case _AuthMode.forgotPassword:
        return 'Reset password';
      case _AuthMode.updatePassword:
        return 'Set new password';
    }
  }

  String get _subtitle {
    switch (_mode) {
      case _AuthMode.signIn:
        return 'Sign in with your email and password.';
      case _AuthMode.signUp:
        return 'Rent tech on flexible monthly plans in Bangladesh.';
      case _AuthMode.confirmPending:
        return 'We sent a confirmation link to ${_emailController.text.trim()}. Click it, then sign in.';
      case _AuthMode.forgotPassword:
        return 'Enter your email and we will send a reset link.';
      case _AuthMode.updatePassword:
        return 'Choose a new password for your account.';
    }
  }

  List<Widget> _buildFields() {
    if (_mode == _AuthMode.confirmPending) return [];

    return [
      if (_mode == _AuthMode.signUp) ...[
        TextFormField(
          controller: _fullNameController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Full name (optional)',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextFormField(
          controller: _referralCodeController,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Referral code (optional)',
            prefixIcon: Icon(Icons.card_giftcard_outlined),
            hintText: 'FRIEND500',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
      if (_mode != _AuthMode.updatePassword) ...[
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Enter your email';
            if (!value.contains('@')) return 'Enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
      if (_mode != _AuthMode.forgotPassword && _mode != _AuthMode.confirmPending) ...[
        TextFormField(
          controller: _passwordController,
          obscureText: true,
          textInputAction: _mode == _AuthMode.signUp || _mode == _AuthMode.updatePassword
              ? TextInputAction.next
              : TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock_outline_rounded),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Enter your password';
            if (_mode == _AuthMode.signUp && value.length < 8) {
              return 'Password must be at least 8 characters';
            }
            return null;
          },
          onFieldSubmitted: (_) {
            if (_mode == _AuthMode.signIn) _signIn();
          },
        ),
      ],
      if (_mode == _AuthMode.signUp || _mode == _AuthMode.updatePassword) ...[
        const SizedBox(height: AppSpacing.lg),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Confirm password',
            prefixIcon: Icon(Icons.lock_outline_rounded),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Confirm your password';
            return null;
          },
        ),
      ],
    ];
  }

  List<Widget> _buildActions() {
    switch (_mode) {
      case _AuthMode.signIn:
        return [
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: AppShapes.pill),
            ),
            onPressed: _isLoading ? null : _signIn,
            child: _loadingOrText('Sign in'),
          ),
          TextButton(
            onPressed: _isLoading ? null : () => _switchMode(_AuthMode.forgotPassword),
            child: const Text('Forgot password?'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: _isLoading ? null : () => _switchMode(_AuthMode.signUp),
            child: const Text('Create an account'),
          ),
        ];
      case _AuthMode.signUp:
        return [
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: AppShapes.pill),
            ),
            onPressed: _isLoading ? null : _signUp,
            child: _loadingOrText('Sign up'),
          ),
          TextButton(
            onPressed: _isLoading ? null : () => _switchMode(_AuthMode.signIn),
            child: const Text('Already have an account? Sign in'),
          ),
        ];
      case _AuthMode.confirmPending:
        return [
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: AppShapes.pill),
            ),
            onPressed: _isLoading ? null : _resendConfirmation,
            child: _loadingOrText('Resend confirmation email'),
          ),
          TextButton(
            onPressed: _isLoading ? null : () => _switchMode(_AuthMode.signIn),
            child: const Text('Back to sign in'),
          ),
        ];
      case _AuthMode.forgotPassword:
        return [
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: AppShapes.pill),
            ),
            onPressed: _isLoading ? null : _sendPasswordReset,
            child: _loadingOrText('Send reset link'),
          ),
          TextButton(
            onPressed: _isLoading ? null : () => _switchMode(_AuthMode.signIn),
            child: const Text('Back to sign in'),
          ),
        ];
      case _AuthMode.updatePassword:
        return [
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: AppShapes.pill),
            ),
            onPressed: _isLoading ? null : _updatePassword,
            child: _loadingOrText('Update password'),
          ),
        ];
    }
  }

  Widget _loadingOrText(String label) {
    return _isLoading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label);
  }
}
