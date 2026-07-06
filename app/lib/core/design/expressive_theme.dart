import 'package:flutter/material.dart';
import 'app_motion.dart';
import 'app_shapes.dart';

/// Material 3 Expressive design tokens as a [ThemeExtension].
@immutable
class GcExpressiveTheme extends ThemeExtension<GcExpressiveTheme> {
  const GcExpressiveTheme({
    required this.heroRadius,
    required this.featureRadius,
    required this.chipRadius,
    required this.navIndicatorRadius,
    required this.ctaRadius,
    required this.motionShort,
    required this.motionMedium,
    required this.motionEmphasized,
    required this.standardCurve,
    required this.emphasizedCurve,
    required this.springDescription,
  });

  final BorderRadius heroRadius;
  final BorderRadius featureRadius;
  final BorderRadius chipRadius;
  final BorderRadius navIndicatorRadius;
  final BorderRadius ctaRadius;
  final Duration motionShort;
  final Duration motionMedium;
  final Duration motionEmphasized;
  final Curve standardCurve;
  final Curve emphasizedCurve;
  final SpringDescription springDescription;

  static final light = GcExpressiveTheme(
    heroRadius: AppShapes.expressiveHero,
    featureRadius: AppShapes.expressiveFeature,
    chipRadius: AppShapes.expressiveChip,
    navIndicatorRadius: const BorderRadius.all(Radius.circular(20)),
    ctaRadius: AppShapes.pill,
    motionShort: AppMotion.fast,
    motionMedium: AppMotion.medium,
    motionEmphasized: AppMotion.slow,
    standardCurve: AppMotion.standard,
    emphasizedCurve: AppMotion.emphasized,
    springDescription: AppMotion.expressiveSpring,
  );

  static final dark = GcExpressiveTheme(
    heroRadius: AppShapes.expressiveHero,
    featureRadius: AppShapes.expressiveFeature,
    chipRadius: AppShapes.expressiveChip,
    navIndicatorRadius: const BorderRadius.all(Radius.circular(20)),
    ctaRadius: AppShapes.pill,
    motionShort: AppMotion.fast,
    motionMedium: AppMotion.medium,
    motionEmphasized: AppMotion.slow,
    standardCurve: AppMotion.standard,
    emphasizedCurve: AppMotion.emphasized,
    springDescription: AppMotion.expressiveSpring,
  );

  @override
  GcExpressiveTheme copyWith({
    BorderRadius? heroRadius,
    BorderRadius? featureRadius,
    BorderRadius? chipRadius,
    BorderRadius? navIndicatorRadius,
    BorderRadius? ctaRadius,
    Duration? motionShort,
    Duration? motionMedium,
    Duration? motionEmphasized,
    Curve? standardCurve,
    Curve? emphasizedCurve,
    SpringDescription? springDescription,
  }) {
    return GcExpressiveTheme(
      heroRadius: heroRadius ?? this.heroRadius,
      featureRadius: featureRadius ?? this.featureRadius,
      chipRadius: chipRadius ?? this.chipRadius,
      navIndicatorRadius: navIndicatorRadius ?? this.navIndicatorRadius,
      ctaRadius: ctaRadius ?? this.ctaRadius,
      motionShort: motionShort ?? this.motionShort,
      motionMedium: motionMedium ?? this.motionMedium,
      motionEmphasized: motionEmphasized ?? this.motionEmphasized,
      standardCurve: standardCurve ?? this.standardCurve,
      emphasizedCurve: emphasizedCurve ?? this.emphasizedCurve,
      springDescription: springDescription ?? this.springDescription,
    );
  }

  @override
  GcExpressiveTheme lerp(ThemeExtension<GcExpressiveTheme>? other, double t) {
    if (other is! GcExpressiveTheme) return this;
    return t < 0.5 ? this : other;
  }
}
