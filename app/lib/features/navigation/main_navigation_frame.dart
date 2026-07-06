import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_collection/m3e_collection.dart';
import '../../core/design/app_breakpoints.dart';
import '../../core/design/app_motion.dart';
import '../../core/design/widgets/navigation/gc_bottom_nav.dart';
import '../../core/theme.dart';
import '../../features/checkout/cart_provider.dart';
import '../home/home_tab.dart';
import '../catalog/catalog_screen.dart';
import '../checkout/cart_tab.dart';
import '../rentals/my_tech_screen.dart';

final activeTabProvider = StateProvider<int>((ref) => 0);

class MainNavigationFrame extends ConsumerWidget {
  const MainNavigationFrame({super.key});

  static const _destinations = [
    GcBottomNavDestination(icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: 'Home'),
    GcBottomNavDestination(icon: Icons.explore_outlined, selectedIcon: Icons.explore_rounded, label: 'Explore'),
    GcBottomNavDestination(icon: Icons.shopping_bag_outlined, selectedIcon: Icons.shopping_bag_rounded, label: 'Cart'),
    GcBottomNavDestination(icon: Icons.person_outline_rounded, selectedIcon: Icons.person_rounded, label: 'Account'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(activeTabProvider);
    final cartCount = ref.watch(cartProvider).fold<int>(0, (sum, item) => sum + item.quantity);
    final sizeClass = AppBreakpoints.sizeClassOf(context);
    final useRail = sizeClass.isMediumOrWider;

    const tabs = [
      HomeTab(),
      CatalogScreen(),
      CartTab(),
      MyTechScreen(),
    ];

    final tabContent = AnimatedSwitcher(
      duration: AppMotion.tabCrossFade,
      switchInCurve: AppMotion.emphasizedDecelerate,
      switchOutCurve: AppMotion.standard,
      child: KeyedSubtree(
        key: ValueKey<int>(activeTab),
        child: tabs[activeTab],
      ),
    );

    if (useRail) {
      final extended = sizeClass.isExpandedOrWider;
      return Scaffold(
        backgroundColor: context.colors.surfaceContainerLowest,
        body: Row(
          children: [
            NavigationRailM3E(
              type: extended
                  ? NavigationRailM3EType.alwaysExpand
                  : NavigationRailM3EType.alwaysCollapse,
              selectedIndex: activeTab,
              onDestinationSelected: (index) =>
                  ref.read(activeTabProvider.notifier).state = index,
              sections: [
                NavigationRailM3ESection(
                  header: extended
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: context.colors.primaryContainer,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(Icons.bolt_rounded, color: context.colors.primary),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'GadgetChai',
                                style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: context.colors.primaryContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(Icons.bolt_rounded, color: context.colors.primary),
                          ),
                        ),
                  destinations: [
                    for (var i = 0; i < _destinations.length; i++)
                      NavigationRailM3EDestination(
                        icon: Icon(_destinations[i].icon),
                        selectedIcon: Icon(_destinations[i].selectedIcon),
                        label: _destinations[i].label,
                        badgeCount: i == 2 && cartCount > 0 ? cartCount : null,
                      ),
                  ],
                ),
              ],
            ),
            VerticalDivider(
              width: 1,
              color: context.colors.outlineVariant.withValues(alpha: 0.5),
            ),
            Expanded(child: tabContent),
          ],
        ),
      );
    }

    final navDestinations = [
      for (var i = 0; i < _destinations.length; i++)
        GcBottomNavDestination(
          icon: _destinations[i].icon,
          selectedIcon: _destinations[i].selectedIcon,
          label: _destinations[i].label,
          badgeCount: i == 2 && cartCount > 0 ? cartCount : null,
        ),
    ];

    return Scaffold(
      backgroundColor: context.colors.surfaceContainerLowest,
      extendBody: true,
      body: tabContent,
      bottomNavigationBar: SafeArea(
        top: false,
        child: GcBottomNav(
          destinations: navDestinations,
          selectedIndex: activeTab,
          onDestinationSelected: (index) =>
              ref.read(activeTabProvider.notifier).state = index,
        ),
      ),
    );
  }
}
