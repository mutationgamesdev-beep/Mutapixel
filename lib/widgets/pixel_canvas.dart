import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/sprite_frame.dart';

/// Drawing tools available on the canvas.
enum CanvasTool { pencil, eraser, fill, stamp }

/// Touch-driven pixel canvas.
///
/// Paints directly onto [frame] and notifies the parent so it can
/// refresh and manage undo snapshots.
class PixelCanvas extends StatefulWidget {
  final SpriteFrame frame;
  final Color drawColor;
  final CanvasTool tool;
  final bool mirror;
  final bool showGrid;
  final VoidCallback onStrokeStart;
  final VoidCallback onChanged;

  /// When [tool] is [CanvasTool.stamp], this part is stamped onto the
  /// canvas centered at the tap position. Null disables stamping.
  final SpriteFrame? stampFrame;

  const PixelCanvas({
    super.key,
    required this.frame,
    required this.drawColor,
    required this.tool,
    required this.mirror,
    required this.showGrid,
    required this.onStrokeStart,
    required this.onChanged,
    this.stampFrame,
  });

  @override
  State<PixelCanvas> createState() => _PixelCanvasState();
}

class _PixelCanvasState extends State<PixelCanvas> {
  bool _stroking = false;

  void _paintAt(Offset local, Size paintSize) {
    final frame = widget.frame;
    final pixelSize = _pixelSize(paintSize, frame);
    final origin = _origin(paintSize, frame, pixelSize);

    final px = ((local.dx - origin.dx) / pixelSize).floor();
    final py = ((local.dy - origin.dy) / pixelSize).floor();
    if (px < 0 || py < 0 || px >= frame.width || py >= frame.height) return;

    switch (widget.tool) {
      case CanvasTool.pencil:
        frame.setPixel(px, py, widget.drawColor);
        if (widget.mirror) {
          frame.setPixel(frame.width - 1 - px, py, widget.drawColor);
        }
      case CanvasTool.eraser:
        frame.setPixel(px, py, null);
        if (widget.mirror) {
          frame.setPixel(frame.width - 1 - px, py, null);
        }
      case CanvasTool.fill:
        // Fill happens on tap only; drags are ignored for fill.
        return;
      case CanvasTool.stamp:
        // Stamping happens on tap only via _stampAt; drags are ignored.
        return;
    }
    widget.onChanged();
  }

  void _fillAt(Offset local, Size paintSize) {
    final frame = widget.frame;
    final pixelSize = _pixelSize(paintSize, frame);
    final origin = _origin(paintSize, frame, pixelSize);

    final sx = ((local.dx - origin.dx) / pixelSize).floor();
    final sy = ((local.dy - origin.dy) / pixelSize).floor();
    if (sx < 0 || sy < 0 || sx >= frame.width || sy >= frame.height) return;

    final target = frame.getPixel(sx, sy);
    final replacement =
        widget.tool == CanvasTool.eraser ? null : widget.drawColor;
    if (_sameColor(target, replacement)) return;

    // Flood fill.
    final stack = <ui.Offset>[ui.Offset(sx.toDouble(), sy.toDouble())];
    while (stack.isNotEmpty) {
      final p = stack.removeLast();
      final x = p.dx.toInt(), y = p.dy.toInt();
      if (x < 0 || y < 0 || x >= frame.width || y >= frame.height) continue;
      if (!_sameColor(frame.getPixel(x, y), target)) continue;
      frame.setPixel(x, y, replacement);
      if (widget.mirror) {
        frame.setPixel(frame.width - 1 - x, y, replacement);
      }
      stack.add(ui.Offset((x + 1).toDouble(), y.toDouble()));
      stack.add(ui.Offset((x - 1).toDouble(), y.toDouble()));
      stack.add(ui.Offset(x.toDouble(), (y + 1).toDouble()));
      stack.add(ui.Offset(x.toDouble(), (y - 1).toDouble()));
    }
    widget.onChanged();
  }

  void _stampAt(Offset local, Size paintSize) {
    final part = widget.stampFrame;
    if (part == null) return;
    final frame = widget.frame;
    final pixelSize = _pixelSize(paintSize, frame);
    final origin = _origin(paintSize, frame, pixelSize);

    final px = ((local.dx - origin.dx) / pixelSize).floor();
    final py = ((local.dy - origin.dy) / pixelSize).floor();
    // Center the part on the tapped pixel.
    final ox = px - part.width ~/ 2;
    final oy = py - part.height ~/ 2;
    for (var y = 0; y < part.height; y++) {
      for (var x = 0; x < part.width; x++) {
        final color = part.getPixel(x, y);
        if (color == null) continue;
        frame.setPixel(ox + x, oy + y, color);
      }
    }
    widget.onChanged();
  }

  bool _sameColor(Color? a, Color? b) {
    if (a == null || b == null) return a == null && b == null;
    return a.toARGB32() == b.toARGB32();
  }

  double _pixelSize(Size paintSize, SpriteFrame frame) {
    final s = paintSize.width / frame.width < paintSize.height / frame.height
        ? paintSize.width / frame.width
        : paintSize.height / frame.height;
    return s > 64.0 ? 64.0 : s;
  }

  Offset _origin(Size paintSize, SpriteFrame frame, double pixelSize) {
    return Offset(
      (paintSize.width - frame.width * pixelSize) / 2,
      (paintSize.height - frame.height * pixelSize) / 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final paintSize =
            Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) {
            final box = context.findRenderObject() as RenderBox;
            final local = box.globalToLocal(details.globalPosition);
            widget.onStrokeStart();
            _stroking = true;
            if (widget.tool == CanvasTool.fill) {
              _fillAt(local, paintSize);
            } else if (widget.tool == CanvasTool.stamp) {
              _stampAt(local, paintSize);
            } else {
              _paintAt(local, paintSize);
            }
          },
          onPanUpdate: (details) {
            if (!_stroking ||
                widget.tool == CanvasTool.fill ||
                widget.tool == CanvasTool.stamp) {
              return;
            }
            final box = context.findRenderObject() as RenderBox;
            _paintAt(box.globalToLocal(details.globalPosition), paintSize);
          },
          onPanEnd: (_) => _stroking = false,
          onPanCancel: () => _stroking = false,
          child: CustomPaint(
            size: paintSize,
            painter: _CanvasPainter(
              frame: widget.frame,
              showGrid: widget.showGrid,
            ),
          ),
        );
      },
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final SpriteFrame frame;
  final bool showGrid;

  _CanvasPainter({required this.frame, required this.showGrid});

  @override
  void paint(Canvas canvas, Size size) {
    final pixelSize = size.width / frame.width < size.height / frame.height
        ? size.width / frame.width
        : size.height / frame.height;
    final clamped = pixelSize > 64.0 ? 64.0 : pixelSize;
    final ox = (size.width - frame.width * clamped) / 2;
    final oy = (size.height - frame.height * clamped) / 2;

    // Transparency checkerboard.
    final light = Paint()..color = const Color(0xFF2A2A35);
    final dark = Paint()..color = const Color(0xFF1E1E28);
    for (var y = 0; y < frame.height; y++) {
      for (var x = 0; x < frame.width; x++) {
        canvas.drawRect(
          Rect.fromLTWH(ox + x * clamped, oy + y * clamped, clamped, clamped),
          (x + y).isEven ? light : dark,
        );
      }
    }

    // Pixels.
    for (var y = 0; y < frame.height; y++) {
      for (var x = 0; x < frame.width; x++) {
        final color = frame.getPixel(x, y);
        if (color == null) continue;
        canvas.drawRect(
          Rect.fromLTWH(ox + x * clamped, oy + y * clamped, clamped, clamped),
          Paint()..color = color,
        );
      }
    }

    // Grid.
    if (showGrid) {
      final gridPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..strokeWidth = 1;
      for (var x = 0; x <= frame.width; x++) {
        final dx = ox + x * clamped;
        canvas.drawLine(
            Offset(dx, oy), Offset(dx, oy + frame.height * clamped), gridPaint);
      }
      for (var y = 0; y <= frame.height; y++) {
        final dy = oy + y * clamped;
        canvas.drawLine(
            Offset(ox, dy), Offset(ox + frame.width * clamped, dy), gridPaint);
      }
      // Mirror guide down the middle.
      final midPaint = Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.35)
        ..strokeWidth = 1.5;
      final midX = ox + frame.width * clamped / 2;
      canvas.drawLine(
          Offset(midX, oy), Offset(midX, oy + frame.height * clamped), midPaint);
    }

    // Border.
    canvas.drawRect(
      Rect.fromLTWH(
          ox, oy, frame.width * clamped, frame.height * clamped),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white24,
    );
  }

  @override
  bool shouldRepaint(_CanvasPainter old) =>
      old.frame != frame || old.showGrid != showGrid;
}
