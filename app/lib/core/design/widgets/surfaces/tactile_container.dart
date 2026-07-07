import 'package:flutter/material.dart';
import '../../tokens/app_colors.dart';

class TactileContainer extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const TactileContainer({
    super.key,
    required this.child,
    this.backgroundColor,
    this.borderColor = AppColors.onSurface,
    this.borderWidth = 2.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final containerChild = Padding(
      padding: padding ?? const EdgeInsets.all(12),
      child: child,
    );

    final decoration = BoxDecoration(
      color: backgroundColor ?? Colors.white,
      borderRadius: borderRadius,
      border: Border.all(
        color: borderColor,
        width: borderWidth,
      ),
    );

    return Container(
      margin: margin,
      decoration: decoration,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Material(
          color: Colors.transparent,
          child: onTap != null
              ? InkWell(
                  onTap: onTap,
                  borderRadius: borderRadius,
                  child: containerChild,
                )
              : containerChild,
        ),
      ),
    );
  }
}
