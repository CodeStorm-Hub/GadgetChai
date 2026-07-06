import 'package:flutter/material.dart';
import '../../../theme.dart';
import '../../app_shapes.dart';
import '../../app_spacing.dart';

class GcSearchEntry extends StatelessWidget {
  const GcSearchEntry({
    super.key,
    required this.hintText,
    required this.onTap,
  });

  final String hintText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Material(
      color: scheme.surface,
      elevation: 2,
      shadowColor: scheme.primary.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppShapes.lg)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppShapes.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 16),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: scheme.primary, size: 24),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  hintText,
                  style: context.text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
              Icon(Icons.tune_rounded, size: 20, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class GcChipSelector extends StatelessWidget {
  const GcChipSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.label,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final textTheme = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
        ],
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: options.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = option == selected;
              return FilterChip(
                label: Text(option),
                selected: isSelected,
                showCheckmark: false,
                selectedColor: scheme.primaryContainer,
                backgroundColor: scheme.surfaceContainer,
                side: BorderSide.none,
                onSelected: (_) => onSelected(option),
                labelStyle: textTheme.labelLarge?.copyWith(
                  color: isSelected ? scheme.onPrimaryContainer : scheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
