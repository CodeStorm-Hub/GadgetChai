import 'package:flutter/material.dart';
/// Motion physics inspired by Material 3 Expressive spring curves.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration tabCrossFade = Duration(milliseconds: 200);

  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve emphasizedDecelerate = Curves.easeOutQuart;
  static const Curve standard = Curves.easeInOutCubic;
  static const Curve springCurve = Curves.easeOutBack;

  static const SpringDescription expressiveSpring = SpringDescription(
    mass: 1,
    stiffness: 400,
    damping: 28,
  );

  static const SpringDescription gentleSpring = SpringDescription(
    mass: 1,
    stiffness: 200,
    damping: 22,
  );

  static Animation<double> fadeSlide(AnimationController controller, {double offsetY = 16}) {
    return CurvedAnimation(parent: controller, curve: emphasizedDecelerate);
  }
}

/// Spring-based page snapping for expressive promo carousels.
class ExpressivePageScrollPhysics extends PageScrollPhysics {
  const ExpressivePageScrollPhysics({super.parent});

  @override
  ExpressivePageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return ExpressivePageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => AppMotion.expressiveSpring;
}
