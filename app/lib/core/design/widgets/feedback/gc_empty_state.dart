import 'package:flutter/material.dart';
import '../../../theme.dart';
import '../../app_shapes.dart';
import '../../app_spacing.dart';

class GcEmptyState extends StatelessWidget {
  const GcEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final textTheme = context.text;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: context.expressive.featureRadius,
            ),
            child: Icon(icon, size: 52, color: scheme.primary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(message!, style: textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(160, 48),
                shape: RoundedRectangleBorder(borderRadius: AppShapes.pill),
              ),
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class GcStepIndicator extends StatelessWidget {
  const GcStepIndicator({
    super.key,
    required this.steps,
    required this.currentStep,
  });

  final List<String> steps;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final progress = steps.isEmpty ? 0.0 : (currentStep + 1) / steps.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: AppShapes.pill,
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: scheme.surfaceContainerHigh,
            color: scheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: List.generate(steps.length, (index) {
            final isActive = index == currentStep;
            final isComplete = index < currentStep;
            final color = isComplete
                ? scheme.secondary
                : isActive
                    ? scheme.primary
                    : scheme.onSurfaceVariant;

            return Expanded(
              child: Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isComplete || isActive
                          ? color.withValues(alpha: 0.15)
                          : scheme.surfaceContainerHigh,
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: isActive ? 2.5 : 1),
                    ),
                    child: Center(
                      child: isComplete
                          ? Icon(Icons.check_rounded, size: 18, color: scheme.secondary)
                          : Text(
                              '${index + 1}',
                              style: context.text.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isActive ? scheme.primary : scheme.onSurfaceVariant,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    steps[index],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: context.text.labelSmall?.copyWith(
                      color: isActive ? scheme.primary : scheme.onSurfaceVariant,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// Waveform-style page indicator for carousels.
class GcCarouselIndicator extends StatelessWidget {
  const GcCarouselIndicator({
    super.key,
    required this.count,
    required this.activeIndex,
  });

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (idx) {
        final active = activeIndex == idx;
        return AnimatedContainer(
          duration: context.expressive.motionMedium,
          curve: context.expressive.emphasizedCurve,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            color: active ? scheme.primary : scheme.surfaceContainerHighest,
          ),
        );
      }),
    );
  }
}
