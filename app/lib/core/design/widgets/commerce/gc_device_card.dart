import 'package:flutter/material.dart';
import '../../gc_motion.dart';
import '../../../theme.dart';
import '../../app_shapes.dart';
import '../../app_spacing.dart';
import 'gc_price_tag.dart';

class GcHomePromoBanner extends StatelessWidget {
  const GcHomePromoBanner({
    super.key,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.actionLabel,
    this.onTap,
    this.accentColor,
  });

  final String title;
  final String description;
  final String imageUrl;
  final String? actionLabel;
  final VoidCallback? onTap;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    final accent = accentColor ?? context.colors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: context.expressive.featureRadius,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: context.expressive.featureRadius,
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.28),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: context.expressive.featureRadius,
            child: SizedBox(
              height: 220,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => ColoredBox(color: accent.withValues(alpha: 0.35)),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.05),
                          Colors.black.withValues(alpha: 0.78),
                        ],
                        stops: const [0.3, 1.0],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.92),
                            height: 1.35,
                          ),
                        ),
                        if (actionLabel != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: AppShapes.pill),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              minimumSize: const Size(0, 40),
                            ),
                            onPressed: onTap,
                            child: Text(actionLabel!),
                          ),
                        ],
                      ],
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

class GcHomeDeviceTile extends StatelessWidget {
  const GcHomeDeviceTile({
    super.key,
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.monthlyPrice,
    required this.onTap,
    this.isOutOfStock = false,
  });

  final String name;
  final String brand;
  final String imageUrl;
  final num monthlyPrice;
  final VoidCallback onTap;
  final bool isOutOfStock;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final textTheme = context.text;

    return GcMotion.pressable(
      onTap: isOutOfStock ? null : onTap,
      child: SizedBox(
        width: 172,
        height: 252,
        child: Material(
          color: scheme.surfaceContainerLow,
          borderRadius: AppShapes.card,
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppShapes.md)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, _, _) => ColoredBox(
                          color: scheme.surfaceContainerHigh,
                          child: Icon(Icons.devices, color: scheme.primary),
                        ),
                      ),
                      if (isOutOfStock)
                        Container(
                          color: Colors.black.withValues(alpha: 0.45),
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: scheme.errorContainer,
                              borderRadius: AppShapes.pill,
                            ),
                            child: Text(
                              'Waitlist',
                              style: textTheme.labelSmall?.copyWith(color: scheme.onErrorContainer),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      brand.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GcPriceTag(amount: monthlyPrice, compact: true, emphasized: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GcDeviceCard extends StatelessWidget {
  const GcDeviceCard({
    super.key,
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.monthlyPrice,
    required this.onTap,
    this.isOutOfStock = false,
    this.compact = false,
  });

  final String name;
  final String brand;
  final String imageUrl;
  final num monthlyPrice;
  final VoidCallback onTap;
  final bool isOutOfStock;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final textTheme = context.text;

    return GcMotion.pressable(
      onTap: isOutOfStock ? null : onTap,
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: AppShapes.card,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => ColoredBox(
                      color: scheme.surfaceContainerHigh,
                      child: Icon(Icons.devices, color: scheme.primary, size: 40),
                    ),
                  ),
                  if (isOutOfStock)
                    Container(
                      color: Colors.black.withValues(alpha: 0.45),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: scheme.errorContainer,
                          borderRadius: AppShapes.pill,
                        ),
                        child: Text(
                          'Waitlist',
                          style: textTheme.labelMedium?.copyWith(color: scheme.onErrorContainer),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(brand.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: textTheme.labelSmall),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: compact ? textTheme.titleSmall : textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  GcPriceTag(amount: monthlyPrice, compact: true, emphasized: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
