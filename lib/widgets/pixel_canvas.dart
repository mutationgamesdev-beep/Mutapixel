import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/art_layer.dart';
import '../models/sprite_frame.dart';
import '../theme/mutapixel_theme.dart';

/// Drawing tools available on the canvas.
enum CanvasTool { pencil, eraser, fill, stamp, eyedropper, move, select }

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

  /// Called when the selection changes. The parent uses this to show
  /// or hide the selection options popup.
  final ValueChanged<bool>? onSelectionChanged;

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
    this.onSelectionChanged,
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
  State<PixelCanvas> createState() => PixelCanvasState();
}

/// State for [PixelCanvas], exposed so the editor can drive the
/// selection tool's actions (delete, flip, duplicate, done).
class PixelCanvasState extends State<PixelCanvas> {
  bool _stroking = false;

  /// Anchor pixel of an in-progress Move drag (for incremental shifts).
  math.Point<int>? _moveAnchor;

  /// Selection (marquee) state for the Select tool.
  math.Rectangle<int>? _selection;
  math.Point<int>? _selectAnchor;

  /// Floating pixels being dragged (move-selection mode). [_floatPixels]
  /// holds the extracted pixel grid and [_floatPos] its top-left canvas
  /// position.
  List<List<Color?>>? _floatPixels;
  math.Point<int>? _floatPos;
  math.Point<int>? _floatAnchor;

  /// Whether a selection marquee is currently active.
  bool get hasSelection => _selection != null;

  /// Whether pixels are currently being dragged (floating).
  bool get isFloating => _floatPixels != null;

  void _notifySelection() =>
      widget.onSelectionChanged?.call(hasSelection || isFloating);

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
      case CanvasTool.select:
        // Tap-only tools (fill/eyedropper) and gesture tools
        // (stamp/move/select) are handled in onPanStart/onPanUpdate.
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
  /// Both the anchor and the current position are clamped to the
  /// canvas bounds so starting (or continuing) a drag outside the
  /// canvas can't cause a sudden jump that shoves pixels off-canvas.
  void _moveUpdate(Offset local, Size paintSize) {
    final anchor = _moveAnchor;
    if (anchor == null) return;
    final frame = _frame;
    final g = PixelCanvas.canvasGeometry(paintSize, frame);
    final px = (((local.dx - g.origin.dx) / g.pixelSize).floor())
        .clamp(0, frame.width - 1);
    final py = (((local.dy - g.origin.dy) / g.pixelSize).floor())
        .clamp(0, frame.height - 1);
    final dx = px - anchor.x;
    final dy = py - anchor.y;
    if (dx == 0 && dy == 0) return;
    ArtLayer.shift(widget.layers[widget.activeLayer], dx, dy);
    _moveAnchor = math.Point(px, py);
    widget.onChanged();
  }

  /// Select tool: begin a marquee drag, or grab the existing
  /// selection to move it.
  void _selectStart(Offset local, Size paintSize) {
    final p = _toPixel(local, paintSize);
    final frame = _frame;
    final cx = p.x.clamp(0, frame.width - 1);
    final cy = p.y.clamp(0, frame.height - 1);

    // If floating pixels are active and the tap is inside them,
    // grab them to continue moving.
    if (_floatPixels != null && _floatPos != null) {
      final fp = _floatPos!;
      final fw = _floatPixels![0].length;
      final fh = _floatPixels!.length;
      if (cx >= fp.x && cx < fp.x + fw && cy >= fp.y && cy < fp.y + fh) {
        _floatAnchor = math.Point(cx, cy);
        return;
      }
      // Tapped outside: merge the floating pixels down first.
      _mergeFloating();
    }

    // If there's a selection and the tap is inside it, pick it up.
    final sel = _selection;
    if (sel != null &&
        cx >= sel.left &&
        cx < sel.left + sel.width &&
        cy >= sel.top &&
        cy < sel.top + sel.height) {
      _pickUpSelection();
      _floatAnchor = math.Point(cx, cy);
      return;
    }

    // Otherwise start a fresh marquee.
    _selection = null;
    _selectAnchor = math.Point(cx, cy);
    _notifySelection();
  }

  /// Select tool: update the marquee or drag floating pixels.
  void _selectUpdate(Offset local, Size paintSize) {
    final frame = _frame;
    final p = _toPixel(local, paintSize);
    final cx = p.x.clamp(0, frame.width - 1);
    final cy = p.y.clamp(0, frame.height - 1);

    // Dragging floating pixels.
    if (_floatPixels != null &&
        _floatPos != null &&
        _floatAnchor != null) {
      final anchor = _floatAnchor!;
      final dx = cx - anchor.x;
      final dy = cy - anchor.y;
      if (dx != 0 || dy != 0) {
        _floatPos = math.Point(_floatPos!.x + dx, _floatPos!.y + dy);
        _floatAnchor = math.Point(cx, cy);
        widget.onChanged();
      }
      return;
    }

    // Growing the marquee.
    final anchor = _selectAnchor;
    if (anchor == null) return;
    final left = math.min(anchor.x, cx);
    final top = math.min(anchor.y, cy);
    final right = math.max(anchor.x, cx);
    final bottom = math.max(anchor.y, cy);
    _selection = math.Rectangle(
        left, top, right - left + 1, bottom - top + 1);
    widget.onChanged();
  }

  /// Select tool: finish the gesture.
  void _selectEnd() {
    _selectAnchor = null;
    _floatAnchor = null;
    // If the marquee is a single tap with no drag, clear it.
    final sel = _selection;
    if (sel != null && sel.width <= 1 && sel.height <= 1) {
      // Keep 1x1 selections: they're a valid single-pixel pick.
    }
    _notifySelection();
    widget.onChanged();
  }

  /// Lifts the selected pixels off the layer into [_floatPixels],
  /// leaving transparency behind. The selection rect stays so the
  /// user sees where the pixels came from.
  void _pickUpSelection() {
    final sel = _selection;
    if (sel == null) return;
    widget.onStrokeStart();
    final frame = _frame;
    final w = sel.width, h = sel.height;
    final pixels = List.generate(
      h,
      (y) => List<Color?>.generate(
        w,
        (x) => frame.getPixel(sel.left + x, sel.top + y),
      ),
    );
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        frame.setPixel(sel.left + x, sel.top + y, null);
      }
    }
    _floatPixels = pixels;
    _floatPos = math.Point(sel.left, sel.top);
    _notifySelection();
    widget.onChanged();
  }

  /// Merges floating pixels back onto the layer at their position.
  void _mergeFloating() {
    final pixels = _floatPixels;
    final pos = _floatPos;
    if (pixels == null || pos == null) return;
    final frame = _frame;
    for (var y = 0; y < pixels.length; y++) {
      for (var x = 0; x < pixels[y].length; x++) {
        final c = pixels[y][x];
        if (c == null) continue;
        final dx = pos.x + x, dy = pos.y + y;
        if (dx < 0 ||
            dy < 0 ||
            dx >= frame.width ||
            dy >= frame.height) {
          continue;
        }
        frame.setPixel(dx, dy, c);
      }
    }
    _floatPixels = null;
    _floatPos = null;
    _floatAnchor = null;
  }

  // ---- Public selection actions (called from the options popup) ----

  /// Clears the selection marquee (merging any floating pixels first).
  void clearSelection() {
    _mergeFloating();
    _selection = null;
    _selectAnchor = null;
    _notifySelection();
    widget.onChanged();
  }

  /// Deletes the selected pixels (or the floating ones).
  void deleteSelection() {
    widget.onStrokeStart();
    if (_floatPixels != null) {
      // Floating pixels are already lifted; just drop them.
      _floatPixels = null;
      _floatPos = null;
      _floatAnchor = null;
    } else {
      final sel = _selection;
      if (sel != null) {
        final frame = _frame;
        for (var y = 0; y < sel.height; y++) {
          for (var x = 0; x < sel.width; x++) {
            frame.setPixel(sel.left + x, sel.top + y, null);
          }
        }
      }
    }
    _selection = null;
    _notifySelection();
    widget.onChanged();
  }

  /// Flips the selection horizontally in place.
  void flipSelectionH() {
    widget.onStrokeStart();
    if (_floatPixels != null) {
      for (final row in _floatPixels!) {
        final reversed = row.reversed.toList();
        for (var i = 0; i < row.length; i++) {
          row[i] = reversed[i];
        }
      }
    } else {
      final sel = _selection;
      if (sel == null) return;
      final frame = _frame;
      for (var y = 0; y < sel.height; y++) {
        for (var x = 0; x < sel.width ~/ 2; x++) {
          final ax = sel.left + x;
          final bx = sel.left + sel.width - 1 - x;
          final yy = sel.top + y;
          final tmp = frame.getPixel(ax, yy);
          frame.setPixel(ax, yy, frame.getPixel(bx, yy));
          frame.setPixel(bx, yy, tmp);
        }
      }
    }
    widget.onChanged();
  }

  /// Flips the selection vertically in place.
  void flipSelectionV() {
    widget.onStrokeStart();
    if (_floatPixels != null) {
      final rows = _floatPixels!;
      for (var y = 0; y < rows.length ~/ 2; y++) {
        final tmp = rows[y];
        rows[y] = rows[rows.length - 1 - y];
        rows[rows.length - 1 - y] = tmp;
      }
    } else {
      final sel = _selection;
      if (sel == null) return;
      final frame = _frame;
      for (var x = 0; x < sel.width; x++) {
        for (var y = 0; y < sel.height ~/ 2; y++) {
          final ay = sel.top + y;
          final by = sel.top + sel.height - 1 - y;
          final xx = sel.left + x;
          final tmp = frame.getPixel(xx, ay);
          frame.setPixel(xx, ay, frame.getPixel(xx, by));
          frame.setPixel(xx, by, tmp);
        }
      }
    }
    widget.onChanged();
  }

  /// Duplicates the selection: merges any floating pixels, then
  /// re-picks-up the same area so the user can drag a copy.
  void duplicateSelection() {
    _mergeFloating();
    final sel = _selection;
    if (sel == null) return;
    widget.onStrokeStart();
    final frame = _frame;
    final w = sel.width, h = sel.height;
    _floatPixels = List.generate(
      h,
      (y) => List<Color?>.generate(
        w,
        (x) => frame.getPixel(sel.left + x, sel.top + y),
      ),
    );
    _floatPos = math.Point(sel.left, sel.top);
    _notifySelection();
    widget.onChanged();
  }

  /// Merges floating pixels and keeps the selection marquee.
  void doneSelection() {
    _mergeFloating();
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
              // Clamp the anchor to the canvas so a drag that starts
              // outside the canvas edge can't cause a jump.
              final p = _toPixel(local, paintSize);
              final frame = widget
                  .layers[widget.activeLayer].frame;
              _moveAnchor = math.Point(
                p.x.clamp(0, frame.width - 1),
                p.y.clamp(0, frame.height - 1),
              );
            } else if (widget.tool == CanvasTool.select) {
              _selectStart(local, paintSize);
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
            if (widget.tool == CanvasTool.select) {
              _selectUpdate(local, paintSize);
              return;
            }
            _paintAt(local, paintSize);
          },
          onPanEnd: (_) {
            _stroking = false;
            _moveAnchor = null;
            if (widget.tool == CanvasTool.select) _selectEnd();
          },
          onPanCancel: () {
            _stroking = false;
            _moveAnchor = null;
            if (widget.tool == CanvasTool.select) _selectEnd();
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
              selection: _selection,
              floatPixels: _floatPixels,
              floatPos: _floatPos,
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
  final math.Rectangle<int>? selection;
  final List<List<Color?>>? floatPixels;
  final math.Point<int>? floatPos;

  _CanvasPainter({
    required this.layers,
    required this.showGrid,
    required this.gridColor,
    required this.borderColor,
    this.selection,
    this.floatPixels,
    this.floatPos,
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

    // Floating pixels being dragged (drawn above everything).
    final fp = floatPixels;
    final fpos = floatPos;
    if (fp != null && fpos != null) {
      for (var y = 0; y < fp.length; y++) {
        for (var x = 0; x < fp[y].length; x++) {
          final color = fp[y][x];
          if (color == null) continue;
          canvas.drawRect(
            Rect.fromLTWH(
                ox + (fpos.x + x) * ps, oy + (fpos.y + y) * ps, ps, ps),
            Paint()..color = color,
          );
        }
      }
    }

    // Selection marquee (dashed highlight).
    final sel = selection;
    if (sel != null) {
      final rect = Rect.fromLTWH(
        ox + sel.left * ps,
        oy + sel.top * ps,
        sel.width * ps,
        sel.height * ps,
      );
      // Soft fill.
      canvas.drawRect(
        rect,
        Paint()
          ..color = MutapixelTheme.primary.withValues(alpha: 0.12),
      );
      // Dashed border (marching-ants style).
      const dashLen = 6.0;
      const gapLen = 4.0;
      final dashPaint = Paint()
        ..color = MutapixelTheme.primary
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      void dashedLine(Offset a, Offset b) {
        final total = (b - a).distance;
        var drawn = 0.0;
        final dir = (b - a) / total;
        while (drawn < total) {
          final segEnd = math.min(drawn + dashLen, total);
          canvas.drawLine(
              a + dir * drawn, a + dir * segEnd, dashPaint);
          drawn += dashLen + gapLen;
        }
      }

      dashedLine(rect.topLeft, rect.topRight);
      dashedLine(rect.topRight, rect.bottomRight);
      dashedLine(rect.bottomRight, rect.bottomLeft);
      dashedLine(rect.bottomLeft, rect.topLeft);
    }
  }

  @override
  bool shouldRepaint(_CanvasPainter old) => true;
}

