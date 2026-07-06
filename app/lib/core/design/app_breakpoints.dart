import 'package:flutter/material.dart';

/// Material 3 canonical window size classes.
/// https://m3.material.io/foundations/layout/applying-layout/window-size-classes
abstract final class AppBreakpoints {
  static const double compact = 600;
  static const double medium = 840;
  static const double expanded = 1200;

  static WindowSizeClass sizeClassOf(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < compact) return WindowSizeClass.compact;
    if (width < medium) return WindowSizeClass.medium;
    if (width < expanded) return WindowSizeClass.expanded;
    return WindowSizeClass.large;
  }
}

enum WindowSizeClass {
  compact,
  medium,
  expanded,
  large,
}

extension WindowSizeClassX on WindowSizeClass {
  bool get isCompact => this == WindowSizeClass.compact;
  bool get isMediumOrWider =>
      this == WindowSizeClass.medium ||
      this == WindowSizeClass.expanded ||
      this == WindowSizeClass.large;
  bool get isExpandedOrWider =>
      this == WindowSizeClass.expanded || this == WindowSizeClass.large;
}
