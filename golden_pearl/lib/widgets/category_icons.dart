import 'package:flutter/material.dart';

class DressIcon extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;

  const DressIcon({super.key, this.size = 28, this.color = const Color(0xFFB89B5E), this.strokeWidth = 1.8});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size, child: CustomPaint(painter: _DressPainter(color, strokeWidth)));
  }
}

class _DressPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  _DressPainter(this.color, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    final path = Path();
    path.moveTo(w * 0.35, h * 0.08);
    path.lineTo(w * 0.65, h * 0.08);

    path.moveTo(w * 0.38, h * 0.08);
    path.quadraticBezierTo(w * 0.32, h * 0.18, w * 0.28, h * 0.30);
    path.lineTo(w * 0.30, h * 0.42);

    path.moveTo(w * 0.62, h * 0.08);
    path.quadraticBezierTo(w * 0.68, h * 0.18, w * 0.72, h * 0.30);
    path.lineTo(w * 0.70, h * 0.42);

    path.moveTo(w * 0.30, h * 0.42);
    path.lineTo(w * 0.70, h * 0.42);

    path.moveTo(w * 0.30, h * 0.42);
    path.quadraticBezierTo(w * 0.22, h * 0.65, w * 0.15, h * 0.92);

    path.moveTo(w * 0.70, h * 0.42);
    path.quadraticBezierTo(w * 0.78, h * 0.65, w * 0.85, h * 0.92);

    path.moveTo(w * 0.15, h * 0.92);
    path.quadraticBezierTo(w * 0.50, h * 0.88, w * 0.85, h * 0.92);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class KaftanIcon extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;

  const KaftanIcon({super.key, this.size = 28, this.color = const Color(0xFFB89B5E), this.strokeWidth = 1.8});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size, child: CustomPaint(painter: _KaftanPainter(color, strokeWidth)));
  }
}

class _KaftanPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  _KaftanPainter(this.color, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    final path = Path();
    path.moveTo(w * 0.42, h * 0.06);
    path.quadraticBezierTo(w * 0.50, h * 0.10, w * 0.58, h * 0.06);

    path.moveTo(w * 0.42, h * 0.06);
    path.lineTo(w * 0.38, h * 0.14);
    path.lineTo(w * 0.18, h * 0.22);
    path.lineTo(w * 0.18, h * 0.42);
    path.lineTo(w * 0.34, h * 0.38);

    path.moveTo(w * 0.58, h * 0.06);
    path.lineTo(w * 0.62, h * 0.14);
    path.lineTo(w * 0.82, h * 0.22);
    path.lineTo(w * 0.82, h * 0.42);
    path.lineTo(w * 0.66, h * 0.38);

    path.moveTo(w * 0.34, h * 0.38);
    path.quadraticBezierTo(w * 0.30, h * 0.65, w * 0.28, h * 0.94);

    path.moveTo(w * 0.66, h * 0.38);
    path.quadraticBezierTo(w * 0.70, h * 0.65, w * 0.72, h * 0.94);

    path.moveTo(w * 0.28, h * 0.94);
    path.lineTo(w * 0.72, h * 0.94);

    path.moveTo(w * 0.50, h * 0.10);
    path.lineTo(w * 0.50, h * 0.32);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RibbonBowIcon extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;

  const RibbonBowIcon({super.key, this.size = 28, this.color = const Color(0xFFB89B5E), this.strokeWidth = 1.8});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size, child: CustomPaint(painter: _RibbonBowPainter(color, strokeWidth)));
  }
}

class _RibbonBowPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  _RibbonBowPainter(this.color, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    final path = Path();
    path.moveTo(w * 0.50, h * 0.38);
    path.quadraticBezierTo(w * 0.25, h * 0.15, w * 0.12, h * 0.28);
    path.quadraticBezierTo(w * 0.08, h * 0.42, w * 0.50, h * 0.38);

    path.moveTo(w * 0.50, h * 0.38);
    path.quadraticBezierTo(w * 0.75, h * 0.15, w * 0.88, h * 0.28);
    path.quadraticBezierTo(w * 0.92, h * 0.42, w * 0.50, h * 0.38);

    path.moveTo(w * 0.42, h * 0.38);
    path.quadraticBezierTo(w * 0.35, h * 0.65, w * 0.30, h * 0.88);

    path.moveTo(w * 0.58, h * 0.38);
    path.quadraticBezierTo(w * 0.65, h * 0.65, w * 0.70, h * 0.88);

    final knot = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(w * 0.50, h * 0.38), w * 0.05, knot);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GiftBoxIcon extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;

  const GiftBoxIcon({super.key, this.size = 28, this.color = const Color(0xFFB89B5E), this.strokeWidth = 1.8});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size, child: CustomPaint(painter: _GiftBoxPainter(color, strokeWidth)));
  }
}

class _GiftBoxPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  _GiftBoxPainter(this.color, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    final r = w * 0.04;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(w * 0.12, h * 0.22, w * 0.88, h * 0.38), Radius.circular(r)),
      paint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(w * 0.16, h * 0.38, w * 0.84, h * 0.90), Radius.circular(r)),
      paint,
    );

    canvas.drawLine(Offset(w * 0.50, h * 0.22), Offset(w * 0.50, h * 0.90), paint);

    canvas.drawLine(Offset(w * 0.50, h * 0.38), Offset(w * 0.12, h * 0.38), paint..strokeWidth = 0);

    final path = Path();
    path.moveTo(w * 0.50, h * 0.22);
    path.quadraticBezierTo(w * 0.35, h * 0.08, w * 0.22, h * 0.14);
    path.quadraticBezierTo(w * 0.28, h * 0.22, w * 0.50, h * 0.22);

    path.moveTo(w * 0.50, h * 0.22);
    path.quadraticBezierTo(w * 0.65, h * 0.08, w * 0.78, h * 0.14);
    path.quadraticBezierTo(w * 0.72, h * 0.22, w * 0.50, h * 0.22);

    canvas.drawPath(path, paint..strokeWidth = strokeWidth);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
