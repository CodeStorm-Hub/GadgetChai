import 'package:flutter/material.dart';
import '../../../theme.dart';
import '../../app_shapes.dart';
import '../../app_spacing.dart';
import 'tactile_container.dart';

class GcCard extends StatelessWidget {
  const GcCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.margin,
    this.expressive = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final EdgeInsetsGeometry? margin;
  final bool expressive;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return TactileContainer(
      margin: margin,
      backgroundColor: color ?? scheme.surface,
      borderRadius: expressive ? context.expressive.featureRadius : AppShapes.card,
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      onTap: onTap,
      borderWidth: expressive ? 2.5 : 2.0,
      child: child,
    );
  }
}

/// Contained icon+label tile for quick actions (Plans, Delivery, Care Plus).
class GcQuickActionTile extends StatelessWidget {
  const GcQuickActionTile({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Expanded(
      child: TactileContainer(
        backgroundColor: scheme.surfaceContainerHigh.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppShapes.md),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
        onTap: onTap,
        borderWidth: 1.5,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: scheme.primary),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
