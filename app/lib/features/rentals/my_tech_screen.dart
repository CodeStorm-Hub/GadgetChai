import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/design/app_spacing.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../core/theme_mode_provider.dart';
import '../../core/widgets/gc_components.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/supabase/b2b_repository.dart';
import '../../core/supabase/review_repository.dart';
import '../../core/widgets/whatsapp_support_button.dart';
import '../../core/supabase/profile_repository.dart';
import '../../core/supabase/rental_repository.dart';
import '../../core/supabase/transaction_repository.dart';

class MyTechScreen extends ConsumerStatefulWidget {
  const MyTechScreen({super.key});

  @override
  ConsumerState<MyTechScreen> createState() => _MyTechScreenState();
}

class _MyTechScreenState extends ConsumerState<MyTechScreen> {
  final _profileRepository = ProfileRepository();
  final _rentalRepository = RentalRepository();
  final _transactionRepository = TransactionRepository();
  final _b2bRepository = B2bRepository();
  final _reviewRepository = ReviewRepository();

  List<Map<String, dynamic>> _rentals = [];
  List<Map<String, dynamic>> _transactions = [];
  Map<String, dynamic>? _profile;
  Map<String, dynamic> _sustainability = {};
  bool _isLoading = true;
  String? _errorMessage;

  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  final _phoneController = TextEditingController();
  final _studentIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _profile = null;
        _rentals = [];
        _isLoading = false;
      });
      return;
    }

    try {
      final profileRes = await _profileRepository.fetchProfile(user.id);
      if (profileRes == null) {
        await _profileRepository.ensureProfile(user.id, phone: user.phone);
      }

      final profile = await _profileRepository.fetchProfile(user.id);
      final rentals = await _rentalRepository.fetchUserRentals(user.id);
      final transactions = await _transactionRepository.fetchForUser(user.id);
      final sustainability = await _b2bRepository.fetchSustainabilityStats(user.id);

      setState(() {
        _profile = profile;
        _rentals = rentals;
        _transactions = transactions;
        _sustainability = sustainability;
        _isLoading = false;
        _errorMessage = null;
        _phoneController.text = profile?['phone'] as String? ?? '';
        _addressController.text = profile?['delivery_address'] as String? ?? '';
        _contactController.text = profile?['emergency_contact'] as String? ?? '';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load account data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveFulfillmentDetails() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final address = _addressController.text.trim();
    final contact = _contactController.text.trim();
    if (address.isEmpty || contact.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter delivery address and emergency contact.')),
      );
      return;
    }

    await _profileRepository.updateFulfillmentDetails(
      userId: user.id,
      deliveryAddress: address,
      emergencyContact: contact,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fulfillment details saved.')),
      );
    }
  }

  Future<void> _saveBkashPhone() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final phone = _phoneController.text.trim();
    if (!isValidBdPhone(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid bKash number (01XXXXXXXXX).')),
      );
      return;
    }
    await _profileRepository.updatePhone(user.id, normalizeBdPhone(phone));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('bKash wallet number saved.')),
      );
      await _fetchUserData();
    }
  }

  Future<void> _linkSocial(String platform) async {
    if (_profile == null) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final newScore = ((_profile!['trust_score'] as num).toInt() + 10).clamp(0, 100);
    await _profileRepository.updateTrustScore(user.id, newScore);
    await _fetchUserData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Linked $platform. Trust score updated.')),
    );
  }

  Future<void> _scheduleReturn(String rentalId) async {
    final pickupDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 2)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      helpText: 'Select pickup date',
    );
    if (pickupDate == null) return;

    try {
      await _rentalRepository.scheduleReturnWithPickup(
        rentalId,
        DateTime(pickupDate.year, pickupDate.month, pickupDate.day, 10),
      );
      await _fetchUserData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Return scheduled for ${DateFormat.yMMMd().format(pickupDate)}.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to schedule return: $e'), backgroundColor: context.colors.error),
      );
    }
  }

  Future<void> _extendRental(String rentalId) async {
    final months = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Extend rental'),
        children: [1, 3, 6]
            .map(
              (m) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, m),
                child: Text('+$m month${m > 1 ? 's' : ''}'),
              ),
            )
            .toList(),
      ),
    );
    if (months == null) return;

    try {
      await _rentalRepository.extendRental(rentalId, months);
      await _fetchUserData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rental extended by $months month(s).')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Extension failed: $e'), backgroundColor: context.colors.error),
      );
    }
  }

  Future<void> _logOut() async {
    await Supabase.instance.client.auth.signOut();
    setState(() {
      _profile = null;
      _rentals = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final user = Supabase.instance.client.auth.currentUser;
    final isAdmin = ref.watch(userRoleProvider).valueOrNull == 'admin';

    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.colors.surfaceContainerLowest,
        body: Center(child: CircularProgressIndicator(color: context.colors.primary)),
      );
    }

    // 1. Guest Screen Layout
    if (user == null || _profile == null) {
      return _buildGuestAccountScreen(textTheme);
    }

    // 2. Logged-In User Screen Layout
    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _fetchUserData, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.colors.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Tech', style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                Text('Your rentals & account', style: context.text.bodySmall),
              ],
            ),
            elevation: 0,
            backgroundColor: context.colors.surface,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(color: context.colors.outline, height: 1, thickness: 1.5),
            ),
            actions: [
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  tooltip: 'Admin dashboard',
                  onPressed: () => context.push('/admin'),
                ),
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                onPressed: _logOut,
                tooltip: 'Log out',
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildProfileOverview(textTheme),
                const SizedBox(height: AppSpacing.lg),
                _buildSustainabilityCard(),
                const SizedBox(height: AppSpacing.lg),
                _buildQuickLinks(),
                const SizedBox(height: AppSpacing.lg),
                const WhatsappSupportBanner(),
                const SizedBox(height: AppSpacing.lg),
                _buildDiscountPrograms(),
                const SizedBox(height: AppSpacing.xl),
                _buildAppearanceSection(),
                const SizedBox(height: AppSpacing.xl),
                Text('Active subscriptions', style: context.text.displaySmall),
                const SizedBox(height: AppSpacing.lg),
                if (_rentals.isEmpty)
                  GcEmptyState(
                    icon: Icons.devices_other_rounded,
                    title: 'No active rentals',
                    message: 'Your rented devices will appear here.',
                    actionLabel: 'Browse catalog',
                    onAction: () => context.go('/'),
                  )
                else
                  ..._rentals.map((rental) => _buildRentalCard(rental, textTheme)),
                const SizedBox(height: AppSpacing.xl),
                Text('Payment history', style: context.text.displaySmall),
                const SizedBox(height: AppSpacing.lg),
                if (_transactions.isEmpty)
                  GcEmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'No payments yet',
                    message: 'bKash charges will appear here after your first payment.',
                  )
                else
                  ..._transactions.take(10).map(_buildTransactionTile),
                const SizedBox(height: AppSpacing.xxxl),
                SizedBox(height: gcBottomNavScrollPadding(context)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestAccountScreen(TextTheme textTheme) {
    return Scaffold(
      backgroundColor: context.colors.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.xxxl,
                AppSpacing.pageHorizontal,
                AppSpacing.lg,
              ),
              child: GcCard(
                expressive: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome', style: context.text.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Sign in to manage rentals, trust score, and deliveries.', style: context.text.bodyLarge),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: () => context.push('/auth'),
                            child: const Text('Sign up'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.push('/auth'),
                            child: const Text('Log in'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontal),
              child: _buildAppearanceSection(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
          SliverToBoxAdapter(child: SizedBox(height: gcBottomNavScrollPadding(context))),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection() {
    final themeMode = ref.watch(themeModeProvider);

    return GcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Appearance', style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Choose light, dark, or match your system setting.',
            style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('System'),
                icon: Icon(Icons.brightness_auto_rounded, size: 18),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode_rounded, size: 18),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode_rounded, size: 18),
              ),
            ],
            selected: {themeMode},
            onSelectionChanged: (selection) {
              ref.read(themeModeProvider.notifier).state = selection.first;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(ref.watch(stringsProvider).language, style: context.text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<AppLocale>(
            segments: [
              ButtonSegment(value: AppLocale.en, label: Text(ref.watch(stringsProvider).english)),
              ButtonSegment(value: AppLocale.bn, label: Text(ref.watch(stringsProvider).bangla)),
            ],
            selected: {ref.watch(localeProvider)},
            onSelectionChanged: (selection) {
              ref.read(localeProvider.notifier).setLocale(selection.first);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOverview(TextTheme textTheme) {
    final score = _profile?['trust_score'] ?? 50;
    final scheme = context.colors;
    final kycVerified = _profile?['kyc_status'] == 'verified';

    return GcCard(
      expressive: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: scheme.primaryContainer,
                child: Icon(Icons.person, size: 36, color: scheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _profile?['full_name'] ?? 'Naimur Rahman',
                      style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Phone: ${_profile?['phone'] ?? "Not set"}',
                      style: context.monoStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: kycVerified ? scheme.secondaryContainer : AppColors.warningContainer,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: kycVerified ? scheme.secondary : AppColors.warning,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'IDENTITY ${_profile?['kyc_status']?.toUpperCase() ?? "NONE"}',
                        style: context.text.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: kycVerified ? scheme.onSecondaryContainer : AppColors.onWarningContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text('Trust score', style: context.text.labelSmall),
                  const SizedBox(height: 6),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          value: score / 100,
                          backgroundColor: scheme.surfaceContainerHigh,
                          color: score > 75 ? scheme.secondary : scheme.primary,
                          strokeWidth: 6,
                        ),
                      ),
                      Text(
                        '$score',
                        style: context.monoStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Divider(color: scheme.outlineVariant, height: 32),
          Text('bKash wallet', style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Wallet number',
                    hintText: '01770618575',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _saveBkashPhone,
                child: const Text('Save'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Fulfillment details', style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Delivery address'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _contactController,
                  decoration: const InputDecoration(labelText: 'Emergency reference'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonal(
              onPressed: _saveFulfillmentDetails,
              child: const Text('Save fulfillment details'),
            ),
          ),
          const SizedBox(height: 24),
          Text('Increase trust score', style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Verify external credentials to waive security deposits on premium hardware.',
            style: context.text.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _linkSocial('LinkedIn'),
                  icon: const Icon(Icons.link, size: 16),
                  label: const Text('LinkedIn (+10)'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _linkSocial('Facebook'),
                  icon: const Icon(Icons.link, size: 16),
                  label: const Text('Facebook (+10)'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRentalCard(Map<String, dynamic> rental, TextTheme textTheme) {
    final device = rental['devices'];
    final startRaw = rental['start_date'] as String?;
    final nextBillRaw = rental['next_billing_date'] as String?;
    final endRaw = rental['end_date'] as String?;
    final scheme = context.colors;

    final startDate = startRaw != null ? DateTime.tryParse(startRaw) : null;
    final nextBillDate = nextBillRaw != null ? DateTime.tryParse(nextBillRaw) : null;
    final endDate = endRaw != null ? DateTime.tryParse(endRaw) : null;

    double progress = 0;
    if (startDate != null && endDate != null) {
      final totalDays = endDate.difference(startDate).inDays;
      if (totalDays > 0) {
        final elapsedDays = DateTime.now().difference(startDate).inDays;
        progress = (elapsedDays / totalDays).clamp(0.0, 1.0);
      }
    }

    final status = rental['status'] as String? ?? 'pending_kyc';

    return GcCard(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  device['image_url'],
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(width: 72, height: 72, color: scheme.surfaceContainerHigh),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device['name'], style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('${rental['plan_months']}-month rental · ${status.replaceAll('_', ' ')}',
                        style: context.text.bodyMedium),
                    const SizedBox(height: 6),
                    GcPriceTag(amount: rental['monthly_price'] as num, compact: true, emphasized: true),
                  ],
                ),
              ),
            ],
          ),
          if (startDate != null && endDate != null) ...[
            Divider(color: scheme.outlineVariant, height: 28),
            Text('Subscription timeline', style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: scheme.surfaceContainerHigh,
                color: scheme.primary,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Start', style: context.text.labelSmall),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('dd MMM yyyy').format(startDate),
                      style: context.monoStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
                if (nextBillDate != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('Next bill', style: context.text.labelSmall),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('dd MMM yyyy').format(nextBillDate),
                        style: context.monoStyle(
                          fontSize: 11,
                          color: scheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Ends', style: context.text.labelSmall),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('dd MMM yyyy').format(endDate),
                      style: context.monoStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ],
          Divider(color: scheme.outlineVariant, height: 28),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: rental['status'] == 'active'
                    ? () => _extendRental(rental['id'] as String)
                    : null,
                child: const Text('Extend'),
              ),
              OutlinedButton(
                onPressed: () {
                  context.push('/my-tech/damage-report?rental_id=${rental['id']}');
                },
                style: OutlinedButton.styleFrom(foregroundColor: scheme.error, side: BorderSide(color: scheme.error)),
                child: const Text('Report damage'),
              ),
              if (rental['status'] == 'returned')
                OutlinedButton(
                  onPressed: () => _promptReview(rental['id'] as String),
                  child: Text(ref.watch(stringsProvider).writeReview),
                ),
              FilledButton(
                onPressed: rental['status'] == 'returned' ? null : () => _scheduleReturn(rental['id']),
                child: Text(rental['status'] == 'returned' ? 'Returned' : 'Schedule return'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSustainabilityCard() {
    final s = ref.watch(stringsProvider);
    final co2 = _sustainability['estimated_co2_kg_saved'] as int? ?? 0;
    final devices = _sustainability['devices_kept_active'] as int? ?? 0;

    return GcCard(
      color: context.colors.secondaryContainer.withValues(alpha: 0.35),
      child: Row(
        children: [
          Icon(Icons.eco_rounded, color: context.colors.secondary, size: 36),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.sustainability, style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                    children: [
                      TextSpan(text: '${s.co2Saved}: '),
                      TextSpan(
                        text: '~${co2}kg',
                        style: context.monoStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: context.colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                    children: [
                      TextSpan(text: '${s.devicesActive}: '),
                      TextSpan(
                        text: '$devices',
                        style: context.monoStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: context.colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLinks() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push('/wishlist'),
            icon: const Icon(Icons.favorite_border_rounded, size: 18),
            label: Text(ref.watch(stringsProvider).wishlist),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push('/business'),
            icon: const Icon(Icons.business_center_outlined, size: 18),
            label: Text(ref.watch(stringsProvider).business),
          ),
        ),
      ],
    );
  }

  Widget _buildDiscountPrograms() {
    final discount = (_profile?['discount_percent'] as num?)?.toDouble() ?? 0;
    final s = ref.watch(stringsProvider);

    return GcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Discount programs', style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          if (discount > 0) ...[
            const SizedBox(height: 8),
            Text('Active: ${discount.toInt()}% off monthly rent', style: context.text.bodyMedium),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(s.studentDiscount, style: context.text.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _studentIdController,
                  decoration: const InputDecoration(
                    labelText: 'Student ID number',
                    hintText: 'NID / student card',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.tonal(
                onPressed: () async {
                  final user = Supabase.instance.client.auth.currentUser;
                  if (user == null) return;
                  try {
                    await _b2bRepository.applyDiscountProgram(
                      accountType: 'student',
                      identifier: _studentIdController.text.trim(),
                    );
                    await _fetchUserData();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Student discount applied (10%).')),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$e'), backgroundColor: context.colors.error),
                    );
                  }
                },
                child: const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _promptReview(String rentalId) async {
    var rating = 5;
    final reviewController = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(ref.watch(stringsProvider).writeReview),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return IconButton(
                    onPressed: () => setDialogState(() => rating = i + 1),
                    icon: Icon(
                      i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: context.colors.tertiary,
                    ),
                  );
                }),
              ),
              TextField(
                controller: reviewController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Share your experience (optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit')),
          ],
        ),
      ),
    );

    if (submitted != true) return;

    try {
      await _reviewRepository.submitReview(
        rentalId: rentalId,
        rating: rating,
        reviewText: reviewController.text.trim().isEmpty ? null : reviewController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your review!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: context.colors.error),
      );
    } finally {
      reviewController.dispose();
    }
  }

  Widget _buildTransactionTile(Map<String, dynamic> tx) {
    final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
    final status = tx['status'] as String? ?? 'unknown';
    final created = tx['created_at'] as String?;
    final date = created != null ? DateTime.tryParse(created) : null;
    final isSuccess = status == 'success';

    return GcCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle_outline : Icons.error_outline,
            color: isSuccess ? context.colors.secondary : context.colors.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '৳${amount.toInt()}',
                  style: context.monoStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSuccess ? context.colors.primary : context.colors.error,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date != null ? DateFormat('dd MMM yyyy, HH:mm').format(date) : '—',
                  style: context.monoStyle(fontSize: 11, color: context.colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            status.toUpperCase(),
            style: context.monoStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSuccess ? context.colors.secondary : context.colors.error,
            ),
          ),
        ],
      ),
    );
  }
}
