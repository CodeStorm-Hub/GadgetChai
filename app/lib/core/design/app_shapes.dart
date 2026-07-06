import 'package:flutter/material.dart';

/// Material 3 Expressive shape tokens — variable radii for hierarchy.
///
/// Usage guidelines:
/// - xs (8): Small elements (chips, badges)
/// - sm (12): Medium elements (buttons, inputs)
/// - md (16): Cards, containers
/// - lg (20): Large containers, dialogs
/// - xl (24): Extra large containers
/// - xxl (28): Hero sections, feature cards
/// - xxxl (32): Maximum rounded corners
abstract final class AppShapes {
  // Corner radii
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 28;
  static const double xxxl = 32;

  // Component shapes
  static BorderRadius get card => BorderRadius.circular(md);
  static BorderRadius get button => BorderRadius.circular(sm);
  static BorderRadius get input => BorderRadius.circular(sm);
  static BorderRadius get chip => BorderRadius.circular(999); // Pill shape
  static BorderRadius get pill => chip;
  static BorderRadius get avatar => BorderRadius.circular(999); // Circle
  static BorderRadius get sheet => BorderRadius.vertical(top: Radius.circular(xxl));
  static BorderRadius get dialog => BorderRadius.circular(lg);
  static BorderRadius get image => BorderRadius.circular(sm);
  static BorderRadius get badge => BorderRadius.circular(999);

  // Legacy expressive card (asymmetric) - kept for backward compatibility
  static BorderRadius get expressiveCard => const BorderRadius.only(
        topLeft: Radius.circular(xl),
        topRight: Radius.circular(md),
        bottomLeft: Radius.circular(md),
        bottomRight: Radius.circular(xxl),
      );

  /// M3 Expressive hero / marketing surfaces — contrasting corner radii.
  static BorderRadius get expressiveHero => const BorderRadius.only(
        topLeft: Radius.circular(xxxl),
        topRight: Radius.circular(lg),
        bottomLeft: Radius.circular(xl),
        bottomRight: Radius.circular(xxxl),
      );

  /// Feature cards and promo modules.
  static BorderRadius get expressiveFeature => const BorderRadius.only(
        topLeft: Radius.circular(xxl),
        topRight: Radius.circular(sm),
        bottomLeft: Radius.circular(sm),
        bottomRight: Radius.circular(xxl),
      );

  /// Pill chips and compact selectors.
  static BorderRadius get expressiveChip => BorderRadius.circular(999);

  // RoundedRectangleBorder helpers
  static RoundedRectangleBorder get cardShape => RoundedRectangleBorder(borderRadius: card);
  static RoundedRectangleBorder get buttonShape => RoundedRectangleBorder(borderRadius: button);
  static RoundedRectangleBorder get inputShape => RoundedRectangleBorder(borderRadius: input);
  static RoundedRectangleBorder get chipShape => RoundedRectangleBorder(borderRadius: chip);
  static RoundedRectangleBorder get dialogShape => RoundedRectangleBorder(borderRadius: dialog);
}
