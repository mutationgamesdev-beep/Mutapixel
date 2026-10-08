import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/art_layer.dart';
import '../models/sprite_frame.dart';
import '../theme/mutapixel_theme.dart';

/// Drawing tools available on the canvas.
enum CanvasTool { pencil, eraser, fill, stamp, eyedropper, move }

/// Touch-driven pixel canvas, Photoshop-style.
///
/// Composites [layers] bottom-to-top for display. Drawing tools
/// (pencil/eraser/fill) and the Move tool operate on the layer at
/// [activeLayer]; the eyedropper samples the topmost visible pixel.
/// Stamping is tap-only and reported via [onStampTap] so the parent
/// can create a new layer instead of merging pixels.
class PixelCanvas extends StatefulWidget {
  final List<ArtLayer> layers;
  final int activeLayer;
  final Color drawColor;
  final CanvasTool tool;
  final bool mirror;
  final bool showGrid;
  final VoidCallback onStrokeStart;
  final VoidCallback onChanged;

  /// Called when [tool] is [CanvasTool.stamp] and the user taps the
  /// canvas. Coordinates are canvas pixels (the tap point).
  final void Function(int cx, int cy)? onStampTap;

  /// Called when [tool] is [CanvasTool.eyedropper] and the user taps a
  /// non-transparent pixel. The parent should adopt the color.
  final ValueChanged<Color>? onColorPicked;

  const PixelCanvas({
    super.key,
    required this.layers,
    required this.activeLayer,
    required this.drawColor,
    required this.tool,
    required this.mirror,
    required this.showGrid,
    required this.onStrokeStart,
    required this.onChanged,
    this.onStampTap,
    this.onColorPicked,
  });

  /// Shared canvas geometry: pixel size (clamped to 64) and the
  /// top-left origin of the frame inside a box of [paintSize].
  /// Mirrors [_CanvasPainter].
  static ({double pixelSize, Offset origin}) canvasGeometry(
    Size paintSize,
    SpriteFrame frame,
  ) {
    var pixelSize = paintSize.width / frame.width <
            paintSize.height / frame.height
        ? paintSize.width / frame.width
        : paintSize.height / frame.height;
    if (pixelSize > 64.0) pixelSize = 64.0;
    final origin = Offset(
      (paintSize.width - frame.width * pixelSize) / 2,
      (paintSize.height - frame.height * pixelSize) / 2,
    );
    return (pixelSize: pixelSize, origin: origin);
  }

  /// Converts a global pointer/drop offset to canvas pixel coordinates.
  ///
  /// [canvasBox] must be the [RenderBox] of this [PixelCanvas].
  /// Returns null when the offset falls outside the frame.
  static math.Point<int>? dropToPixel({
    required RenderBox canvasBox,
    required Offset globalOffset,
    required SpriteFrame frame,
  }) {
    final local = canvasBox.globalToLocal(globalOffset);
    final g = canvasGeometry(canvasBox.size, frame);
    final px = ((local.dx - g.origin.dx) / g.pixelSize).floor();
    final py = ((local.dy - g.origin.dy) / g.pixelSize).floor();
    if (px < 0 || py < 0 || px >= frame.width || py >= frame.height) {
      return null;
    }
    return math.Point(px, py);
  }

  @override
  State<PixelCanvas> createState() => _PixelCanvasState();
}

class _PixelCanvasState extends State<PixelCanvas> {
  bool _stroking = false;

  /// Anchor pixel of an in-progress Move drag (for incremental shifts).
  math.Point<int>? _moveAnchor;

  SpriteFrame get _frame =>
      widget.layers[widget.activeLayer].frame;

  void _paintAt(Offset local, Size paintSize) {
    final frame = _frame;
    final g = PixelCanvas.canvasGeometry(paintSize, frame);

    final px = ((local.dx - g.origin.dx) / g.pixelSize).floor();
    final py = ((local.dy - g.origin.dy) / g.pixelSize).floor();
    if (px < 0 || py < 0 || px >= frame.width || py >= frame.height) {
      return;
    }

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
      case CanvasTool.stamp:
      case CanvasTool.eyedropper:
      case CanvasTool.move:
        // Tap-only tools (fill/eyedropper) and gesture tools
        // (stamp/move) are handled in onPanStart/onPanUpdate.
        return;
    }
    widget.onChanged();
  }

  /// Eyedropper samples the topmost visible, non-transparent pixel.
  void _pickAt(Offset local, Size paintSize) {
    final frame = _frame;
    final g = PixelCanvas.canvasGeometry(paintSize, frame);

    final px = ((local.dx - g.origin.dx) / g.pixelSize).floor();
    final py = ((local.dy - g.origin.dy) / g.pixelSize).floor();
    if (px < 0 || py < 0 || px >= frame.width || py >= frame.height) {
      return;
    }

    for (var i = widget.layers.length - 1; i >= 0; i--) {
      final layer = widget.layers[i];
      if (!layer.visible) continue;
      final color = layer.frame.getPixel(px, py);
      if (color != null) {
        widget.onColorPicked?.call(color);
        return;
      }
    }
    // Tapped transparency: keep the current color.
  }

  void _fillAt(Offset local, Size paintSize) {
    final frame = _frame;
    final g = PixelCanvas.canvasGeometry(paintSize, frame);

    final sx = ((local.dx - g.origin.dx) / g.pixelSize).floor();
    final sy = ((local.dy - g.origin.dy) / g.pixelSize).floor();
    if (sx < 0 || sy < 0 || sx >= frame.width || sy >= frame.height) {
      return;
    }

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

  /// Move tool: shift the active layer's pixels by the drag delta.
  void _moveUpdate(Offset local, Size paintSize) {
    final anchor = _moveAnchor;
    if (anchor == null) return;
    final frame = _frame;
    final g = PixelCanvas.canvasGeometry(paintSize, frame);
    final px = ((local.dx - g.origin.dx) / g.pixelSize).floor();
    final py = ((local.dy - g.origin.dy) / g.pixelSize).floor();
    final dx = px - anchor.x;
    final dy = py - anchor.y;
    if (dx == 0 && dy == 0) return;
    ArtLayer.shift(widget.layers[widget.activeLayer], dx, dy);
    _moveAnchor = math.Point(px, py);
    widget.onChanged();
  }

  math.Point<int> _toPixel(Offset local, Size paintSize) {
    final frame = _frame;
    final g = PixelCanvas.canvasGeometry(paintSize, frame);
    return math.Point(
      ((local.dx - g.origin.dx) / g.pixelSize).floor(),
      ((local.dy - g.origin.dy) / g.pixelSize).floor(),
    );
  }

  bool _sameColor(Color? a, Color? b) {
    if (a == null || b == null) return a == null && b == null;
    return a.toARGB32() == b.toARGB32();
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
            if (widget.tool == CanvasTool.stamp) {
              final p = _toPixel(local, paintSize);
              widget.onStampTap?.call(p.x, p.y);
              return;
            }
            widget.onStrokeStart();
            _stroking = true;
            if (widget.tool == CanvasTool.fill) {
              _fillAt(local, paintSize);
            } else if (widget.tool == CanvasTool.eyedropper) {
              _pickAt(local, paintSize);
            } else if (widget.tool == CanvasTool.move) {
              _moveAnchor = _toPixel(local, paintSize);
            } else {
              _paintAt(local, paintSize);
            }
          },
          onPanUpdate: (details) {
            if (!_stroking ||
                widget.tool == CanvasTool.fill ||
                widget.tool == CanvasTool.stamp ||
                widget.tool == CanvasTool.eyedropper) {
              return;
            }
            final box = context.findRenderObject() as RenderBox;
            final local = box.globalToLocal(details.globalPosition);
            if (widget.tool == CanvasTool.move) {
              _moveUpdate(local, paintSize);
              return;
            }
            _paintAt(local, paintSize);
          },
          onPanEnd: (_) {
            _stroking = false;
            _moveAnchor = null;
          },
          onPanCancel: () {
            _stroking = false;
            _moveAnchor = null;
          },
          child: CustomPaint(
            size: paintSize,
            painter: _CanvasPainter(
              layers: widget.layers,
              showGrid: widget.showGrid,
              gridColor: MutapixelTheme.of(context)
                  .ink
                  .withValues(alpha: 0.07),
              borderColor:
                  MutapixelTheme.of(context).hairline,
            ),
          ),
        );
      },
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final List<ArtLayer> layers;
  final bool showGrid;
  final Color gridColor;
  final Color borderColor;

  _CanvasPainter({
    required this.layers,
    required this.showGrid,
    required this.gridColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (layers.isEmpty) return;
    final frame = layers.first.frame;
    final g = PixelCanvas.canvasGeometry(size, frame);
    final ps = g.pixelSize;
    final ox = g.origin.dx;
    final oy = g.origin.dy;

    // Transparency checkerboard (light, premium).
    final light = Paint()..color = const Color(0xFFFFFFFF);
    final dark = Paint()..color = const Color(0xFFF1F1F4);
    for (var y = 0; y < frame.height; y++) {
      for (var x = 0; x < frame.width; x++) {
        canvas.drawRect(
          Rect.fromLTWH(ox + x * ps, oy + y * ps, ps, ps),
          (x + y).isEven ? light : dark,
        );
      }
    }

    // Composite visible layers bottom-to-top (canvas blends them).
    for (final layer in layers) {
      if (!layer.visible) continue;
      final lf = layer.frame;
      for (var y = 0; y < lf.height; y++) {
        for (var x = 0; x < lf.width; x++) {
          final color = lf.getPixel(x, y);
          if (color == null) continue;
          canvas.drawRect(
            Rect.fromLTWH(ox + x * ps, oy + y * ps, ps, ps),
            Paint()
              ..color = color.withValues(
                  alpha: (color.a * layer.opacity).clamp(0.0, 1.0)),
          );
        }
      }
    }

    // Grid.
    if (showGrid) {
      final gridPaint = Paint()
        ..color = gridColor
        ..strokeWidth = 1;
      for (var x = 0; x <= frame.width; x++) {
        final dx = ox + x * ps;
        canvas.drawLine(
            Offset(dx, oy), Offset(dx, oy + frame.height * ps), gridPaint);
      }
      for (var y = 0; y <= frame.height; y++) {
        final dy = oy + y * ps;
        canvas.drawLine(
            Offset(ox, dy), Offset(ox + frame.width * ps, dy), gridPaint);
      }
      // Mirror guide down the middle.
      final midPaint = Paint()
        ..color = MutapixelTheme.primary.withValues(alpha: 0.45)
        ..strokeWidth = 1.5;
      final midX = ox + frame.width * ps / 2;
      canvas.drawLine(
          Offset(midX, oy), Offset(midX, oy + frame.height * ps), midPaint);
    }

    // Border.
    canvas.drawRect(
      Rect.fromLTWH(ox, oy, frame.width * ps, frame.height * ps),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = borderColor,
    );
  }

  @override
  bool shouldRepaint(_CanvasPainter old) => true;
}

