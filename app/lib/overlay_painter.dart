import 'package:flutter/material.dart';
import 'models.dart';

class DetectionPainter extends CustomPainter {
  final List<YoloObject> objects;
  final Size imageSize; // исходный размер картинки в px (width,height)

  DetectionPainter({required this.objects, required this.imageSize});

  @override
  void paint(Canvas canvas, Size size) {
    // коэффициенты масштабирования от imageSize -> size (виджет на экране)
    final sx = size.width / imageSize.width;
    final sy = size.height / imageSize.height;

    final boxPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final polyPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final textStyle = TextStyle(color: Colors.white, fontSize: 12);

    for (final o in objects) {
      // цвет для класса
      final color = Colors.primaries[o.className.hashCode % Colors.primaries.length];
      boxPaint.color = color;
      polyPaint.color = color;

      // бокс
      if (o.bboxXYXY.length == 4) {
        final x1 = o.bboxXYXY[0] * sx;
        final y1 = o.bboxXYXY[1] * sy;
        final x2 = o.bboxXYXY[2] * sx;
        final y2 = o.bboxXYXY[3] * sy;
        final rect = Rect.fromLTRB(x1, y1, x2, y2);
        canvas.drawRect(rect, boxPaint);
        // подпись
        final tp = TextPainter(
          text: TextSpan(text: '${o.className} ${(o.score * 100).toStringAsFixed(0)}%', style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x1 + 2, y1 + 2));
      }

      // полигон
      if (o.polygon.isNotEmpty) {
        final path = Path();
        for (int i = 0; i < o.polygon.length; i++) {
          final x = o.polygon[i][0] * sx;
          final y = o.polygon[i][1] * sy;
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        canvas.drawPath(path, polyPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DetectionPainter oldDelegate) {
    return oldDelegate.objects != objects || oldDelegate.imageSize != imageSize;
  }
}