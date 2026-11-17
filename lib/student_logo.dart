import 'package:material_ui/material_ui.dart';

class StudentLogo extends StatelessWidget {
  const StudentLogo({super.key, this.size = 80});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _StudentLogoPainter()),
    );
  }
}

class _StudentLogoPainter extends CustomPainter {
  static const _navy = Color(0xFF123B66);
  static const _sky = Color(0xFF82C7F5);
  static const _gold = Color(0xFFFFC857);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);

    final circle = Path()..addOval(const Rect.fromLTWH(1, 1, 98, 98));
    canvas.drawShadow(circle, const Color(0x33123B66), 4, true);
    canvas.drawPath(
      circle,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_sky, _navy],
        ).createShader(const Rect.fromLTWH(1, 1, 98, 98)),
    );
    canvas.drawPath(
      circle,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final cap = Path()
      ..moveTo(50, 20)
      ..lineTo(79, 33)
      ..lineTo(50, 46)
      ..lineTo(21, 33)
      ..close();
    canvas.drawPath(cap, Paint()..color = Colors.white);

    final capBand = Path()
      ..moveTo(38, 38)
      ..lineTo(62, 38)
      ..lineTo(60, 48)
      ..quadraticBezierTo(50, 54, 40, 48)
      ..close();
    canvas.drawPath(capBand, Paint()..color = const Color(0xFFD8F0FF));

    final tassel = Paint()
      ..color = _gold
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(79, 33), const Offset(81, 47), tassel);
    canvas.drawCircle(const Offset(81, 49), 2.4, Paint()..color = _gold);

    final leftPage = Path()
      ..moveTo(50, 60)
      ..cubicTo(42, 54, 30, 54, 22, 58)
      ..lineTo(22, 78)
      ..cubicTo(32, 74, 43, 76, 50, 82)
      ..close();
    final rightPage = Path()
      ..moveTo(50, 60)
      ..cubicTo(58, 54, 70, 54, 78, 58)
      ..lineTo(78, 78)
      ..cubicTo(68, 74, 57, 76, 50, 82)
      ..close();
    final pagePaint = Paint()..color = Colors.white;
    canvas.drawPath(leftPage, pagePaint);
    canvas.drawPath(rightPage, pagePaint);

    final pageDetail = Paint()
      ..color = _sky
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(28, 63), const Offset(42, 63), pageDetail);
    canvas.drawLine(const Offset(28, 68), const Offset(42, 68), pageDetail);
    canvas.drawLine(const Offset(58, 63), const Offset(72, 63), pageDetail);
    canvas.drawLine(const Offset(58, 68), const Offset(72, 68), pageDetail);
    canvas.drawLine(
      const Offset(50, 60),
      const Offset(50, 82),
      Paint()
        ..color = _navy
        ..strokeWidth = 1.5,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StudentLogoPainter oldDelegate) => false;
}
