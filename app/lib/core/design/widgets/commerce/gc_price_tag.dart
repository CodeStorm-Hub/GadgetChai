import 'package:flutter/material.dart';
import '../../../theme.dart';

class GcPriceTag extends StatelessWidget {
  const GcPriceTag({
    super.key,
    required this.amount,
    this.suffix = '/mo',
    this.compact = false,
    this.emphasized = false,
  });

  final num amount;
  final String suffix;
  final bool compact;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    final scheme = context.colors;
    final priceStyle = (compact ? textTheme.titleMedium : textTheme.titleLarge)?.copyWith(
      fontWeight: emphasized ? FontWeight.w800 : FontWeight.w700,
      color: scheme.primary,
    );
    return RichText(
      text: TextSpan(
        style: priceStyle,
        children: [
          TextSpan(text: '৳${amount.toInt()}'),
          TextSpan(
            text: ' $suffix',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
