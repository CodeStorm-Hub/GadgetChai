/// Consistent spacing scale (8px grid base, 4px increments).
///
/// Usage guidelines:
/// - xs (4): Tight spacing within components
/// - sm (8): Small gaps between related elements
/// - md (12): Medium gaps within sections
/// - lg (16): Standard padding and margins
/// - xl (24): Large gaps between sections
/// - xxl (32): Extra large gaps
/// - xxxl (48): Section separators
abstract final class AppSpacing {
  // Base spacing units
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double xxxxl = 64;

  // Layout spacing
  static const double pageHorizontal = 16; // Mobile
  static const double pageHorizontalTablet = 24; // Tablet (>600px)
  static const double pageHorizontalDesktop = 32; // Desktop (>840px)

  // Section spacing
  static const double sectionGap = 24;
  static const double sectionGapLarge = 32;
  static const double sectionGapSmall = 16;

  // Content constraints
  static const double maxContentWidth = 1200;
  static const double maxContentWidthTablet = 800;
  static const double maxContentWidthMobile = 480;

  // Component spacing
  static const double cardGap = 12;
  static const double listItemGap = 8;
  static const double buttonGap = 16;
  static const double formFieldGap = 16;
}
