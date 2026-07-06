import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final _phoneController = TextEditingController(text: "01723888888");
  final _otpController = TextEditingController();
  final _pinController = TextEditingController();

  int _step = 1; // 1: Wallet Number, 2: OTP, 3: PIN
  bool _isProcessing = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _nextStep() {
    setState(() {
      _isProcessing = true;
    });
    // Simulate API delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      setState(() {
        _isProcessing = false;
        _step += 1;
      });
    });
  }

  Future<void> _completeMandate() async {
    setState(() {
      _isProcessing = true;
    });

    final uri = Uri.parse(widget.redirectUrl);
    final rentalId = widget.rentalId.isNotEmpty
        ? widget.rentalId
        : (uri.queryParameters['rental_id'] ?? '');

    try {
      await Supabase.instance.client.functions.invoke(
        'bkash-webhook',
        body: {
          'action': 'execute-agreement',
          'rental_id': rentalId,
          'paymentID': 'TRX-${DateTime.now().millisecondsSinceEpoch}',
          'status': 'success',
        },
      );

      if (mounted) {
        context.go('/checkout/status?status=success&rental_id=$rentalId');
      }
    } catch (e) {
      if (mounted) {
        context.go('/checkout/status?status=failed&rental_id=$rentalId&message=${Uri.encodeComponent(e.toString())}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Secure payment'),
        centerTitle: true,
        backgroundColor: context.colors.surface,
        foregroundColor: context.colors.onSurface,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: AppColors.bkashPink,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Image.network(
                    'https://web.bka.sh/payment/assets/img/bkash_logo.png',
                    height: 60,
                    errorBuilder: (context, error, stackTrace) => Text(
                      'bKash',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Simulated Box
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _step == 1
                              ? 'Enter bKash Account Number'
                              : _step == 2
                                  ? 'Enter 6-Digit OTP Code'
                                  : 'Enter Your bKash PIN',
                          style: GoogleFonts.inter(
                            color: Colors.grey[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (_isProcessing)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation(AppColors.bkashPink),
                              ),
                            ),
                          )
                        else ...[
                          if (_step == 1) ...[
                            TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(color: Colors.black),
                              decoration: const InputDecoration(
                                hintText: "e.g., 017XXXXXXXX",
                                prefixText: "+88 ",
                                prefixStyle: TextStyle(color: Colors.black54),
                                filled: true,
                                fillColor: Color(0xFFF1F5F9),
                                border: OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.bkashPink)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _nextStep,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.bkashPink,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('PROCEED'),
                              ),
                            ),
                          ] else if (_step == 2) ...[
                            TextField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              style: const TextStyle(color: Colors.black),
                              decoration: const InputDecoration(
                                hintText: "Verification Code",
                                counterText: "",
                                filled: true,
                                fillColor: Color(0xFFF1F5F9),
                                border: OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.bkashPink)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => setState(() => _step = 1),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.bkashPink,
                                      side: const BorderSide(color: AppColors.bkashPink),
                                    ),
                                    child: const Text('BACK'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _nextStep,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.bkashPink,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('VERIFY'),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            TextField(
                              controller: _pinController,
                              obscureText: true,
                              keyboardType: TextInputType.number,
                              maxLength: 5,
                              style: const TextStyle(color: Colors.black),
                              decoration: const InputDecoration(
                                hintText: "Enter PIN",
                                counterText: "",
                                filled: true,
                                fillColor: Color(0xFFF1F5F9),
                                border: OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.bkashPink)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => setState(() => _step = 2),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.bkashPink,
                                      side: const BorderSide(color: AppColors.bkashPink),
                                    ),
                                    child: const Text('BACK'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _completeMandate,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.bkashPink,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('CONFIRM'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Agreement footnote text
                  Text(
                    'By clicking confirm, you agree to authorise monthly recurring payments matching your rent subscription details.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
