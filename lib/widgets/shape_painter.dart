import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ShapePainter extends CustomPainter {
  final List<Offset> points;
  final List<List<Offset>> holes;
  final List<Offset> cutPath;
  final bool gameEnded;

  ShapePainter({
    required this.points,
    this.holes = const [],
    required this.cutPath,
    this.gameEnded = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = AppColors.object
      ..style = PaintingStyle.fill;

    final path = Path();
    path.fillType = PathFillType.evenOdd;
    
    // Outer boundary
    path.moveTo(center.dx + points[0].dx, center.dy + points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(center.dx + points[i].dx, center.dy + points[i].dy);
    }
    path.close();

    // Holes
    for (var hole in holes) {
      if (hole.isEmpty) continue;
      path.moveTo(center.dx + hole[0].dx, center.dy + hole[0].dy);
      for (int i = 1; i < hole.length; i++) {
        path.lineTo(center.dx + hole[i].dx, center.dy + hole[i].dy);
      }
      path.close();
    }

    canvas.drawPath(path, paint);

    // Draw outline
    final outlinePaint = Paint()
      ..color = AppColors.text.withAlpha(50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, outlinePaint);

    // Draw cut path
    if (cutPath.length >= 2) {
      final cutPaint = Paint()
        ..color = AppColors.slash
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;
      
      final slashPath = Path();
      slashPath.moveTo(cutPath[0].dx, cutPath[0].dy);
      for (int i = 1; i < cutPath.length; i++) {
        slashPath.lineTo(cutPath[i].dx, cutPath[i].dy);
      }
      canvas.drawPath(slashPath, cutPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ShapePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.holes != holes ||
        oldDelegate.cutPath != cutPath ||
        oldDelegate.gameEnded != gameEnded;
  }
}
