import 'package:flutter/material.dart';
import '../theme.dart';
import 'app_breakpoints.dart';
import 'app_spacing.dart';

/// Centers page content and applies canonical max-width constraints on large screens.
class GcAdaptivePage extends StatelessWidget {
  const GcAdaptivePage({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth = AppSpacing.maxContentWidth,
    this.alignTop = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double maxWidth;
  final bool alignTop;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignTop ? Alignment.topCenter : Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? pagePadding(context),
          child: child,
        ),
      ),
    );
  }
}

/// List-detail canonical layout: sidebar on medium+ windows, stacked on compact.
class GcAdaptiveListDetail extends StatelessWidget {
  const GcAdaptiveListDetail({
    super.key,
    required this.list,
    required this.detail,
    this.listWidth = 320,
    this.gap = AppSpacing.lg,
  });

  final Widget list;
  final Widget detail;
  final double listWidth;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final useSideBySide = AppBreakpoints.sizeClassOf(context).isMediumOrWider;

    if (!useSideBySide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [list, SizedBox(height: gap), Expanded(child: detail)],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: listWidth, child: list),
        SizedBox(width: gap),
        Expanded(child: detail),
      ],
    );
  }
}

/// Responsive grid column count for product/catalog layouts.
int adaptiveGridCount(BuildContext context, {int compact = 2, int medium = 3, int expanded = 4}) {
  switch (AppBreakpoints.sizeClassOf(context)) {
    case WindowSizeClass.compact:
      return compact;
    case WindowSizeClass.medium:
      return medium;
    case WindowSizeClass.expanded:
    case WindowSizeClass.large:
      return expanded;
  }
}

/// Expressive section surface — tonal container with M3 expressive corners.
class GcExpressiveSurface extends StatelessWidget {
  const GcExpressiveSurface({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.onTap,
    this.radius,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final VoidCallback? onTap;
  final BorderRadius? radius;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final shape = RoundedRectangleBorder(
      borderRadius: radius ?? context.expressive.featureRadius,
      side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.45)),
    );

    return Material(
      color: color ?? scheme.surfaceContainerLow,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
          child: child,
        ),
      ),
    );
  }
}
