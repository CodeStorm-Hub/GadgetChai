import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';

import '../../../theme.dart';
import '../../app_spacing.dart';

/// Expressive floating bottom navigation — M3E pill indicator, elevated container.
class GcBottomNavDestination {
  const GcBottomNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int? badgeCount;
}

class GcBottomNav extends StatelessWidget {
  const GcBottomNav({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<GcBottomNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const double barHeight = 72;
  static const double outerRadius = 28;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        0,
        AppSpacing.pageHorizontal,
        AppSpacing.sm,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(outerRadius),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.55),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.14),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(outerRadius),
          child: Material(
            color: scheme.surfaceContainerHigh,
            child: Theme(
              data: Theme.of(context).copyWith(
                navigationBarTheme: NavigationBarThemeData(
                  height: barHeight,
                  backgroundColor: Colors.transparent,
                  indicatorColor: scheme.primaryContainer,
                  indicatorShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    final selected = states.contains(WidgetState.selected);
                    return context.text.labelMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12,
                      color: selected ? scheme.primary : scheme.onSurfaceVariant,
                    );
                  }),
                  iconTheme: WidgetStateProperty.resolveWith((states) {
                    final selected = states.contains(WidgetState.selected);
                    return IconThemeData(
                      color: selected ? scheme.primary : scheme.onSurfaceVariant,
                      size: 24,
                    );
                  }),
                ),
              ),
              child: NavigationBarM3E(
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                labelBehavior: NavBarM3ELabelBehavior.alwaysShow,
                size: NavBarM3ESize.medium,
                shapeFamily: NavBarM3EShapeFamily.round,
                density: NavBarM3EDensity.regular,
                indicatorStyle: NavBarM3EIndicatorStyle.pill,
                backgroundColor: scheme.surfaceContainerHigh,
                indicatorColor: scheme.primaryContainer,
                elevation: 0,
                safeArea: false,
                destinations: [
                  for (var i = 0; i < destinations.length; i++)
                    NavigationDestinationM3E(
                      icon: Icon(destinations[i].icon),
                      selectedIcon: Icon(destinations[i].selectedIcon),
                      label: destinations[i].label,
                      badgeCount: destinations[i].badgeCount,
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

/// Bottom inset for scrollables when the floating nav is visible.
double gcBottomNavScrollPadding(BuildContext context) {
  return GcBottomNav.barHeight + AppSpacing.sm + MediaQuery.paddingOf(context).bottom + 16;
}
