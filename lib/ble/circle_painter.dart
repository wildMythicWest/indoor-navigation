import 'package:flutter/material.dart';

class CirclePainter extends CustomPainter {
  final Offset center;
  final double radius;

  CirclePainter({required this.center, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.limeAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CirclePainter oldDelegate) {
    return oldDelegate.center != center || oldDelegate.radius != radius;
  }
}