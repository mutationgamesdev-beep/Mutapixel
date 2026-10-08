import 'package:flutter/material.dart';

import '../models/sprite_frame.dart';

/// Renders a [SpriteFrame] scaled to fit, pixelated.
///
/// Shared by the home screen template grid and the editor's
/// right-side templates panel.
class TemplatePreview extends CustomPainter {
  final SpriteFrame frame;
  TemplatePreview({required this.frame});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / frame.width < size.height / frame.height
        ? size.width / frame.width
        : size.height / frame.height;
    final ox = (size.width - frame.width * s) / 2;
    final oy = (size.height - frame.height * s) / 2;
    for (var y = 0; y < frame.height; y++) {
      for (var x = 0; x < frame.width; x++) {
        final color = frame.getPixel(x, y);
        if (color == null) continue;
        canvas.drawRect(
          Rect.fromLTWH(ox + x * s, oy + y * s, s + 0.5, s + 0.5),
          Paint()..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(TemplatePreview old) => old.frame != frame;
}
