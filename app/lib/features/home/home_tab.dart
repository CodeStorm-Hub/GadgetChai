import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/adaptive_layout.dart';
import '../../core/design/app_motion.dart';
import '../../core/design/app_shapes.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/gc_motion.dart';
import '../../core/theme.dart';
import '../../core/widgets/gc_components.dart';
import '../../core/supabase/device_repository.dart';
import '../../core/supabase/home_repository.dart';
import '../../features/navigation/main_navigation_frame.dart';
import '../../features/catalog/catalog_screen.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  final _deviceRepository = DeviceRepository();
  final _homeRepository = HomeRepository();
  final _pageController = PageController(viewportFraction: 0.92);
  int _currentBannerPage = 0;

  List<Map<String, dynamic>> _promos = [];
  List<Map<String, dynamic>> _popularDevices = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadHomeData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        _homeRepository.fetchPromos(),
        _homeRepository.fetchCategories(),
        _deviceRepository.fetchFeatured(limit: 6),
      ]);
      setState(() {
        _promos = results[0];
        _categories = results[1];
        _popularDevices = results[2];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load home content: $e';
        _isLoading = false;
      });
    }
  }

  void _openExplore({String? category}) {
    if (category != null) {
      ref.read(selectedCategoryProvider.notifier).state = category;
    }
    ref.read(activeTabProvider.notifier).state = 1;
  }

  Color _parseColor(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    final value = hex.replaceFirst('#', '');
    if (value.length != 6) return fallback;
    return Color(int.parse('FF$value', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.colors.surfaceContainerLowest,
        body: Center(child: CircularProgressIndicator(color: context.colors.primary)),
      );
    }
    if (_errorMessage != null) {
      return Scaffold(
        body: GcEmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'Could not load home',
          message: _errorMessage,
          actionLabel: 'Retry',
          onAction: _loadHomeData,
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.colors.surfaceContainerLowest,
      body: RefreshIndicator(
        color: context.colors.primary,
        onRefresh: _loadHomeData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHero(context)),
            SliverToBoxAdapter(child: _buildQuickActions(context)),
            if (_promos.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sectionGap)),
              SliverToBoxAdapter(child: _buildPromoSlider(context)),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sectionGap)),
            SliverToBoxAdapter(
              child: GcSectionHeader(
                title: 'Most popular',
                subtitle: 'Trending rentals this week',
                actionLabel: 'See all',
                onAction: () => _openExplore(category: 'All'),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            SliverToBoxAdapter(child: _buildPopularScroll(context)),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sectionGap)),
            SliverToBoxAdapter(child: GcSectionHeader(title: 'Browse by category')),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontal),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: adaptiveGridCount(context, compact: 2, medium: 3, expanded: 4),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: context.isWide ? 1.15 : 1.05,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => GcMotion.staggeredFadeIn(
                    index: index,
                    child: _buildCategoryTile(context, _categories[index]),
                  ),
                  childCount: _categories.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sectionGap)),
            SliverToBoxAdapter(child: _buildReferralBanner(context)),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
            SliverToBoxAdapter(child: SizedBox(height: gcBottomNavScrollPadding(context))),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.colors.primary.withValues(alpha: 0.18),
            context.colors.surfaceContainerLowest,
            context.colors.secondary.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: context.expressive.heroRadius.bottomLeft,
          bottomRight: context.expressive.heroRadius.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            AppSpacing.md,
            AppSpacing.pageHorizontal,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: context.colors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.bolt_rounded, color: context.colors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'GadgetChai',
                    style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Rent the tech you actually want',
                style: context.text.headlineMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.15),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Phones, laptops, cameras & more — flexible monthly plans in Bangladesh.',
                style: context.text.bodyMedium?.copyWith(height: 1.45),
              ),
              const SizedBox(height: AppSpacing.lg),
              GcSearchEntry(
                hintText: 'Search brand, model, category…',
                onTap: () => _openExplore(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.lg,
        AppSpacing.pageHorizontal,
        0,
      ),
      child: Row(
        children: [
          GcQuickActionTile(
            icon: Icons.calendar_month_outlined,
            label: 'Flexible plans',
            onTap: () => _openExplore(),
          ),
          const SizedBox(width: AppSpacing.sm),
          GcQuickActionTile(
            icon: Icons.local_shipping_outlined,
            label: 'Fast delivery',
            onTap: () => _openExplore(),
          ),
          const SizedBox(width: AppSpacing.sm),
          GcQuickActionTile(
            icon: Icons.shield_outlined,
            label: 'Care Plus',
            onTap: () => _openExplore(),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoSlider(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontal),
          child: Text(
            'Offers for you',
            style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            physics: const ExpressivePageScrollPhysics(),
            onPageChanged: (idx) => setState(() => _currentBannerPage = idx),
            itemCount: _promos.length,
            itemBuilder: (context, index) {
              final promo = _promos[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GcHomePromoBanner(
                  title: promo['title'] as String? ?? '',
                  description: promo['description'] as String? ?? '',
                  imageUrl: promo['image_url'] as String? ?? '',
                  actionLabel: 'Explore deals',
                  accentColor: _parseColor(promo['bg_color'] as String?, context.colors.tertiary),
                  onTap: () => _openExplore(),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GcCarouselIndicator(count: _promos.length, activeIndex: _currentBannerPage),
      ],
    );
  }

  Widget _buildPopularScroll(BuildContext context) {
    return SizedBox(
      height: 252,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontal),
        itemCount: _popularDevices.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final device = _popularDevices[index];
          return GcHomeDeviceTile(
            name: device['name'] as String? ?? '',
            brand: device['brand'] as String? ?? '',
            imageUrl: device['image_url'] as String? ?? '',
            monthlyPrice: device['monthly_price_12m'] as num? ?? 0,
            isOutOfStock: device['is_out_of_stock'] == true,
            onTap: () => context.push('/device/${device['id']}'),
          );
        },
      ),
    );
  }

  Widget _buildCategoryTile(BuildContext context, Map<String, dynamic> cat) {
    final title = cat['title'] as String? ?? '';

    return Material(
      color: context.colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppShapes.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openExplore(category: title),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              cat['image_url'] as String? ?? '',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => ColoredBox(color: context.colors.surfaceContainerHigh),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontal),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              context.colors.tertiaryContainer,
              context.colors.primaryContainer.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: context.expressive.featureRadius,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.colors.surface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.card_giftcard_rounded, color: context.colors.tertiary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invite friends, earn ৳500',
                    style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Share GadgetChai — friends get their first month discounted too.',
                    style: context.text.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      minimumSize: const Size(0, 44),
                      shape: RoundedRectangleBorder(borderRadius: AppShapes.pill),
                    ),
                    onPressed: () {},
                    child: const Text('Learn more'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
