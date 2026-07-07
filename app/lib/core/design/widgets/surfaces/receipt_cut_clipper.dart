import 'package:flutter/material.dart';

class ReceiptCutClipper extends CustomClipper<Path> {
  final double toothWidth;
  final double toothHeight;

  const ReceiptCutClipper({
    this.toothWidth = 8.0,
    this.toothHeight = 6.0,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height - toothHeight);

    double x = size.width;
    double y = size.height - toothHeight;
    bool toothUp = true;

    // Draw jagged pattern backwards along the bottom edge
    while (x > 0) {
      x -= toothWidth;
      if (x < 0) x = 0;
      y = toothUp ? size.height : size.height - toothHeight;
      path.lineTo(x, y);
      toothUp = !toothUp;
    }

    path.lineTo(0, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
