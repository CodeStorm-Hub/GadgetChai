import 'package:flutter/material.dart';
import 'app_motion.dart';

/// Shared spring-physics motion helpers for M3 Expressive interactions.
abstract final class GcMotion {
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

  static Animation<double> springScale(AnimationController controller) {
    return Tween<double>(begin: 0.97, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: AppMotion.springCurve),
    );
  }

  static Widget pressable({
    required Widget child,
    required VoidCallback? onTap,
    SpringDescription spring = expressiveSpring,
  }) {
    return _GcPressable(onTap: onTap, spring: spring, child: child);
  }

  static Widget staggeredFadeIn({
    required int index,
    required Widget child,
    Duration baseDelay = const Duration(milliseconds: 50),
  }) {
    return _GcStaggeredFade(index: index, baseDelay: baseDelay, child: child);
  }
}

class _GcPressable extends StatefulWidget {
  const _GcPressable({
    required this.child,
    required this.onTap,
    required this.spring,
  });

  final Widget child;
  final VoidCallback? onTap;
  final SpringDescription spring;

  @override
  State<_GcPressable> createState() => _GcPressableState();
}

class _GcPressableState extends State<_GcPressable> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.medium);
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.springCurve),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? _onTapDown : null,
      onTapUp: widget.onTap != null ? _onTapUp : null,
      onTapCancel: widget.onTap != null ? _onTapCancel : null,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

class _GcStaggeredFade extends StatefulWidget {
  const _GcStaggeredFade({
    required this.index,
    required this.baseDelay,
    required this.child,
  });

  final int index;
  final Duration baseDelay;
  final Widget child;

  @override
  State<_GcStaggeredFade> createState() => _GcStaggeredFadeState();
}

class _GcStaggeredFadeState extends State<_GcStaggeredFade> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.medium);
    _opacity = CurvedAnimation(parent: _controller, curve: AppMotion.emphasizedDecelerate);
    _offset = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(_opacity);
    Future<void>.delayed(widget.baseDelay * widget.index, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}
