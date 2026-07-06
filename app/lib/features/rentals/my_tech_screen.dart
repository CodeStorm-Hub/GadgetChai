import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/design/app_spacing.dart';
import '../../core/theme.dart';
import '../../core/theme_mode_provider.dart';
import '../../core/widgets/gc_components.dart';
import '../../core/supabase/profile_repository.dart';
import '../../core/supabase/rental_repository.dart';

class MyTechScreen extends ConsumerStatefulWidget {
  const MyTechScreen({super.key});

  @override
  ConsumerState<MyTechScreen> createState() => _MyTechScreenState();
}

class _MyTechScreenState extends ConsumerState<MyTechScreen> {
  final _profileRepository = ProfileRepository();
  final _rentalRepository = RentalRepository();

  List<Map<String, dynamic>> _rentals = [];
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  final _addressController = TextEditingController(text: "12/A, Dhanmondi, Dhaka");
  final _contactController = TextEditingController(text: "+8801912345678 (Brother)");

  @override
  void initState() {
    super.initState();
    _fetchUserData();
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

      setState(() {
        _profile = profile;
        _rentals = rentals;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load account data: $e';
        _isLoading = false;
      });
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
    try {
      await _rentalRepository.scheduleReturn(rentalId);
      await _fetchUserData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Return pickup scheduled successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to schedule return: $e'), backgroundColor: context.colors.error),
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
            actions: [
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
                    Text('Phone: ${_profile?['phone'] ?? ""}', style: context.text.bodyMedium),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: kycVerified ? scheme.secondaryContainer : AppColors.warningContainer,
                        borderRadius: BorderRadius.circular(99),
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
                      Text('$score', style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Divider(color: scheme.outlineVariant, height: 32),
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
    final startDate = DateTime.parse(rental['start_date']);
    final nextBillDate = DateTime.parse(rental['next_billing_date']);
    final endDate = DateTime.parse(rental['end_date']);
    final scheme = context.colors;

    final totalDays = endDate.difference(startDate).inDays;
    final elapsedDays = DateTime.now().difference(startDate).inDays;
    final progress = (elapsedDays / totalDays).clamp(0.0, 1.0);

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
                    Text('${rental['plan_months']}-month rental plan', style: context.text.bodyMedium),
                    const SizedBox(height: 6),
                    GcPriceTag(amount: rental['monthly_price'] as num, compact: true, emphasized: true),
                  ],
                ),
              ),
            ],
          ),
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
                  Text(DateFormat('dd MMM yyyy').format(startDate), style: context.text.bodySmall),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Next bill', style: context.text.labelSmall),
                  Text(
                    DateFormat('dd MMM yyyy').format(nextBillDate),
                    style: context.text.bodySmall?.copyWith(color: scheme.secondary, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Ends', style: context.text.labelSmall),
                  Text(DateFormat('dd MMM yyyy').format(endDate), style: context.text.bodySmall),
                ],
              ),
            ],
          ),
          Divider(color: scheme.outlineVariant, height: 28),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () {
                  context.push('/my-tech/damage-report?rental_id=${rental['id']}');
                },
                style: OutlinedButton.styleFrom(foregroundColor: scheme.error, side: BorderSide(color: scheme.error)),
                child: const Text('Report damage'),
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
}
