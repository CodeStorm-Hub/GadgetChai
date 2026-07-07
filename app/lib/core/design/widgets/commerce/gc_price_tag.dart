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
    final scheme = context.colors;
    final priceStyle = context.monoStyle(
      fontSize: compact ? 16 : 20,
      fontWeight: emphasized ? FontWeight.bold : FontWeight.w700,
      color: scheme.primary,
    );
    return RichText(
      text: TextSpan(
        style: priceStyle,
        children: [
          TextSpan(text: '৳${amount.toInt()}'),
          TextSpan(
            text: ' $suffix',
            style: context.monoStyle(
              fontSize: compact ? 12 : 14,
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
