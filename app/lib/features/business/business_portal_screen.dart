import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/design/app_spacing.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/supabase/b2b_repository.dart';
import '../../core/theme.dart';
import '../../core/widgets/gc_components.dart';
import '../../core/widgets/whatsapp_support_button.dart';

class BusinessPortalScreen extends ConsumerStatefulWidget {
  const BusinessPortalScreen({super.key});

  @override
  ConsumerState<BusinessPortalScreen> createState() => _BusinessPortalScreenState();
}

class _BusinessPortalScreenState extends ConsumerState<BusinessPortalScreen> {
  final _b2bRepository = B2bRepository();
  final _formKey = GlobalKey<FormState>();

  final _companyController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _countController = TextEditingController(text: '10');
  final _notesController = TextEditingController();
  final _discountIdController = TextEditingController();

  final _selectedTypes = <String>{'laptop'};
  bool _submitting = false;

  @override
  void dispose() {
    _companyController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _countController.dispose();
    _notesController.dispose();
    _discountIdController.dispose();
    super.dispose();
  }

  Future<void> _submitInquiry() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      await _b2bRepository.submitInquiry(
        userId: user?.id,
        companyName: _companyController.text.trim(),
        contactName: _nameController.text.trim(),
        contactPhone: _phoneController.text.trim(),
        contactEmail: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        deviceCount: int.parse(_countController.text.trim()),
        deviceTypes: _selectedTypes.toList(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fleet inquiry submitted. We will contact you within 1 business day.')),
      );
      _formKey.currentState!.reset();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: context.colors.error),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _applyCorporateDiscount() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to apply corporate discount.')),
      );
      return;
    }
    final id = _discountIdController.text.trim();
    if (id.isEmpty) return;
    try {
      final result = await _b2bRepository.applyDiscountProgram(
        accountType: 'corporate',
        identifier: id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Corporate discount applied: ${result['discount_percent']}%')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: context.colors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${s.business} Fleet Portal'),
        elevation: 0,
        backgroundColor: context.colors.surface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: context.colors.outline, height: 1, thickness: 1.5),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GcCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rent tech for your team', style: context.text.headlineSmall),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Bulk laptop, phone, and camera rentals with MDM-ready delivery, centralized billing, and doorstep pickup across Bangladesh.',
                        style: context.text.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const WhatsappSupportBanner(),
                const SizedBox(height: AppSpacing.xl),
                Text('Request a fleet quote', style: context.text.titleLarge),
                const SizedBox(height: AppSpacing.md),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _companyController,
                        decoration: const InputDecoration(labelText: 'Company name'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Contact name'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Phone'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email (optional)'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _countController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Number of devices'),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n < 1) return 'Enter a valid count';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: 8,
                        children: ['laptop', 'phone', 'camera', 'console'].map((type) {
                          final selected = _selectedTypes.contains(type);
                          return FilterChip(
                            label: Text(type),
                            selected: selected,
                            side: BorderSide(
                              color: selected ? context.colors.primary : context.colors.outline,
                              width: 1.5,
                            ),
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  _selectedTypes.add(type);
                                } else {
                                  _selectedTypes.remove(type);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Notes (optional)'),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      FilledButton(
                        onPressed: _submitting ? null : _submitInquiry,
                        child: _submitting
                            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Submit inquiry'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(s.corporateDiscount, style: context.text.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _discountIdController,
                        decoration: const InputDecoration(
                          labelText: 'Company / trade license name',
                          hintText: 'Acme Ltd.',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.tonal(
                      onPressed: _applyCorporateDiscount,
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
