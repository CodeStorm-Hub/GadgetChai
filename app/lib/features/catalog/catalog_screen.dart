import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/adaptive_layout.dart';
import '../../core/design/app_breakpoints.dart';
import '../../core/design/app_spacing.dart';
import '../../core/theme.dart';
import '../../core/widgets/gc_components.dart';
import '../../core/supabase/device_repository.dart';
import 'compare_provider.dart';

final selectedCategoryProvider = StateProvider<String>((ref) => 'All');
final selectedBrandProvider = StateProvider<String>((ref) => 'All');
final budgetLimitProvider = StateProvider<double>((ref) => 15000.0);
final searchQueryProvider = StateProvider<String>((ref) => '');

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final _deviceRepository = DeviceRepository();
  List<Map<String, dynamic>> _devices = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCatalog();
  }

  Future<void> _fetchCatalog() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final devices = await _deviceRepository.fetchCatalog();
      setState(() {
        _devices = devices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load catalog: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedBrand = ref.watch(selectedBrandProvider);
    final budgetLimit = ref.watch(budgetLimitProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    final filteredDevices = _devices.where((device) {
      final matchesCategory = selectedCategory == 'All' || device['category'] == selectedCategory;
      final matchesBrand = selectedBrand == 'All' || device['brand'] == selectedBrand;
      final matchesBudget = device['monthly_price_12m'] <= budgetLimit;
      final matchesSearch = device['name'].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
          device['brand'].toString().toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesBrand && matchesBudget && matchesSearch;
    }).toList();

    const categories = ['All', 'Phones & Tablets', 'Computers', 'Cameras', 'Gaming Consoles'];
    const brands = ['All', 'Apple', 'Samsung', 'Sony', 'ASUS', 'DJI', 'Nintendo'];
    final useSidebar = AppBreakpoints.sizeClassOf(context).isMediumOrWider;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.colors.surfaceContainerLowest,
        body: Center(child: CircularProgressIndicator(color: context.colors.primary)),
      );
    }
    if (_errorMessage != null) {
      return Scaffold(
        body: GcEmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'Catalog unavailable',
          message: _errorMessage,
          actionLabel: 'Retry',
          onAction: _fetchCatalog,
        ),
      );
    }

    final grid = _DeviceGrid(devices: filteredDevices);

    if (useSidebar) {
      final filters = _FiltersPanel(
        categories: categories,
        brands: brands,
        selectedCategory: selectedCategory,
        selectedBrand: selectedBrand,
        budgetLimit: budgetLimit,
        searchQuery: searchQuery,
        deviceCount: filteredDevices.length,
        showHeader: true,
      );

      return Scaffold(
        backgroundColor: context.colors.surfaceContainerLowest,
        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 300,
                child: Material(
                  color: context.colors.surfaceContainerLow,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: filters,
                  ),
                ),
              ),
              VerticalDivider(
                width: 1,
                color: context.colors.outlineVariant.withValues(alpha: 0.4),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchCatalog,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.lg,
                            AppSpacing.lg,
                            AppSpacing.md,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Explore catalog', style: context.text.headlineSmall),
                              Text(
                                '${filteredDevices.length} devices match your filters',
                                style: context.text.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                      grid,
                      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final compareCount = ref.watch(compareProvider).length;

    return Scaffold(
      backgroundColor: context.colors.surfaceContainerLowest,
      appBar: _CatalogExpressiveAppBar(
        deviceCount: filteredDevices.length,
        searchQuery: searchQuery,
        activeFilterCount: _activeFilterCount(
          selectedCategory,
          selectedBrand,
          budgetLimit,
        ),
        onOpenFilters: () => _openFilterSheet(
          categories: categories,
          brands: brands,
          deviceCount: filteredDevices.length,
        ),
        onClearFilters: () {
          ref.read(selectedCategoryProvider.notifier).state = 'All';
          ref.read(selectedBrandProvider.notifier).state = 'All';
          ref.read(budgetLimitProvider.notifier).state = 15000;
        },
      ),
      body: RefreshIndicator(
        onRefresh: _fetchCatalog,
        child: CustomScrollView(
          slivers: [
            grid,
            SliverToBoxAdapter(child: SizedBox(height: gcBottomNavScrollPadding(context))),
          ],
        ),
      ),
      floatingActionButton: compareCount > 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/compare'),
              icon: const Icon(Icons.compare_arrows_rounded),
              label: Text('Compare ($compareCount)'),
            )
          : null,
    );
  }

  int _activeFilterCount(String category, String brand, double budget) {
    var count = 0;
    if (category != 'All') count++;
    if (brand != 'All') count++;
    if (budget < 15000) count++;
    return count;
  }

  Future<void> _openFilterSheet({
    required List<String> categories,
    required List<String> brands,
    required int deviceCount,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.colors.surfaceContainerHigh,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (_, scrollController) {
            return Consumer(
              builder: (context, ref, _) {
                final selectedCategory = ref.watch(selectedCategoryProvider);
                final selectedBrand = ref.watch(selectedBrandProvider);
                final budgetLimit = ref.watch(budgetLimitProvider);

                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageHorizontal,
                    0,
                    AppSpacing.pageHorizontal,
                    AppSpacing.xl,
                  ),
                  children: [
                    Text('Filters', style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: AppSpacing.lg),
                    _FiltersPanel(
                      categories: categories,
                      brands: brands,
                      selectedCategory: selectedCategory,
                      selectedBrand: selectedBrand,
                      budgetLimit: budgetLimit,
                      searchQuery: '',
                      deviceCount: deviceCount,
                      showHeader: false,
                      showSearch: false,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: Text('Show $deviceCount devices'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _CatalogExpressiveAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const _CatalogExpressiveAppBar({
    required this.deviceCount,
    required this.searchQuery,
    required this.activeFilterCount,
    required this.onOpenFilters,
    required this.onClearFilters,
  });

  final int deviceCount;
  final String searchQuery;
  final int activeFilterCount;
  final VoidCallback onOpenFilters;
  final VoidCallback onClearFilters;

  static const double _toolbarHeight = 152;

  @override
  Size get preferredSize => const Size.fromHeight(_toolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          bottom: BorderSide(color: context.colors.outline, width: 2.0),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            8,
            AppSpacing.pageHorizontal,
            12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Explore',
                          style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '$deviceCount devices available',
                          style: context.monoStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onOpenFilters,
                    icon: Badge(
                      isLabelVisible: activeFilterCount > 0,
                      label: Text('$activeFilterCount'),
                      child: const Icon(Icons.tune_rounded, size: 18),
                    ),
                    label: const Text('Filters'),
                  ),
                  if (activeFilterCount > 0) ...[
                    const SizedBox(width: AppSpacing.sm),
                    IconButton(
                      tooltip: 'Clear filters',
                      onPressed: onClearFilters,
                      icon: const Icon(Icons.filter_alt_off_rounded),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SearchBar(
                hintText: 'Search brand, model, category…',
                leading: const Icon(Icons.search_rounded),
                elevation: const WidgetStatePropertyAll(0),
                onChanged: (val) => ref.read(searchQueryProvider.notifier).state = val,
                trailing: searchQuery.isNotEmpty
                    ? [
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => ref.read(searchQueryProvider.notifier).state = '',
                        ),
                      ]
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FiltersPanel extends ConsumerWidget {
  const _FiltersPanel({
    required this.categories,
    required this.brands,
    required this.selectedCategory,
    required this.selectedBrand,
    required this.budgetLimit,
    required this.searchQuery,
    required this.deviceCount,
    required this.showHeader,
    this.showSearch = true,
  });

  final List<String> categories;
  final List<String> brands;
  final String selectedCategory;
  final String selectedBrand;
  final double budgetLimit;
  final String searchQuery;
  final int deviceCount;
  final bool showHeader;
  final bool showSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageHorizontal,
              AppSpacing.lg,
              AppSpacing.pageHorizontal,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Explore', style: context.text.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('$deviceCount devices available', style: context.text.bodyMedium),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontal),
            child: SearchBar(
              hintText: 'Search brand, model, category…',
              leading: const Icon(Icons.search_rounded),
              elevation: const WidgetStatePropertyAll(0),
              onChanged: (val) => ref.read(searchQueryProvider.notifier).state = val,
              trailing: searchQuery.isNotEmpty
                  ? [
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => ref.read(searchQueryProvider.notifier).state = '',
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ] else ...[
          if (showSearch) ...[
            Text('Filters', style: context.text.titleLarge),
            const SizedBox(height: AppSpacing.md),
            SearchBar(
              hintText: 'Search…',
              leading: const Icon(Icons.search_rounded),
              elevation: const WidgetStatePropertyAll(0),
              onChanged: (val) => ref.read(searchQueryProvider.notifier).state = val,
              trailing: searchQuery.isNotEmpty
                  ? [
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => ref.read(searchQueryProvider.notifier).state = '',
                      ),
                    ]
                  : null,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ],
        Padding(
          padding: EdgeInsets.symmetric(horizontal: showHeader ? AppSpacing.pageHorizontal : 0),
          child: GcChipSelector(
            label: 'Brands',
            options: brands,
            selected: selectedBrand,
            onSelected: (v) => ref.read(selectedBrandProvider.notifier).state = v,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: showHeader ? AppSpacing.pageHorizontal : 0),
          child: GcCard(
            color: context.colors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Category', style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    DropdownButton<String>(
                      value: selectedCategory,
                      underline: const SizedBox(),
                      items: categories
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(selectedCategoryProvider.notifier).state = val;
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Monthly budget', style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Text(
                      '৳${budgetLimit.toInt()}/mo',
                      style: context.monoStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: context.colors.primary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: budgetLimit,
                  min: 2000,
                  max: 15000,
                  activeColor: context.colors.primary,
                  inactiveColor: context.colors.surfaceContainerHigh,
                  divisions: 13,
                  label: '৳${budgetLimit.toInt()}/mo',
                  onChanged: (val) => ref.read(budgetLimitProvider.notifier).state = val,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DeviceGrid extends StatelessWidget {
  const _DeviceGrid({required this.devices});

  final List<Map<String, dynamic>> devices;

  @override
  Widget build(BuildContext context) {
    if (devices.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: GcEmptyState(
          icon: Icons.search_off_rounded,
          title: 'No matches',
          message: 'Try adjusting your filters or search query.',
        ),
      );
    }

    final columns = adaptiveGridCount(context, compact: 2, medium: 2, expanded: 3);
    final horizontalPad = AppBreakpoints.sizeClassOf(context).isMediumOrWider
        ? AppSpacing.lg
        : AppSpacing.pageHorizontal;

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPad),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.58,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final device = devices[index];
            return GcDeviceCard(
              name: device['name'] as String? ?? '',
              brand: device['brand'] as String? ?? '',
              imageUrl: device['image_url'] as String? ?? '',
              monthlyPrice: device['monthly_price_12m'] as num? ?? 0,
              isOutOfStock: device['is_out_of_stock'] == true,
              onTap: () => context.push('/device/${device['id']}'),
            );
          },
          childCount: devices.length,
        ),
      ),
    );
  }
}
