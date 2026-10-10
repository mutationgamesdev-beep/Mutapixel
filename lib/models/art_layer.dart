import 'package:flutter/material.dart';

import 'sprite_frame.dart';

/// One Photoshop-style layer of a sprite.
///
/// Every layer holds a FULL canvas-size [frame]; empty areas stay
/// transparent. Layers composite bottom-to-top ([index 0] is the
/// bottom). Stamping a part or template creates a new layer, so it
/// can be repositioned with the Move tool instead of being merged
/// into the pixels immediately.
class ArtLayer {
  String name;
  SpriteFrame frame;
  bool visible;
  double opacity; // 0.0 - 1.0

  /// Position offset in canvas pixels. The Move tool changes this
  /// instead of shifting pixels, so moving a layer partially (or
  /// fully) off-canvas never destroys pixels — moving it back
  /// restores the full image.
  int offsetX;
  int offsetY;

  ArtLayer({
    required this.name,
    required this.frame,
    this.visible = true,
    this.opacity = 1.0,
    this.offsetX = 0,
    this.offsetY = 0,
  });

  /// Deep copy, used for undo snapshots and duplicating layers.
  ArtLayer clone() => ArtLayer(
        name: name,
        frame: SpriteFrame.clone(frame),
        visible: visible,
        opacity: opacity,
        offsetX: offsetX,
        offsetY: offsetY,
      );

  /// Moves the layer by ([dx], [dy]) without touching pixels.
  /// Nothing is ever lost, even off-canvas.
  static void shift(ArtLayer layer, int dx, int dy) {
    if (dx == 0 && dy == 0) return;
    layer.offsetX += dx;
    layer.offsetY += dy;
  }

  /// Samples the layer at canvas pixel ([x], [y]), accounting for
  /// the layer's offset. Returns null when transparent or outside
  /// the layer's frame.
  Color? getPixelAt(int x, int y) =>
      frame.getPixel(x - offsetX, y - offsetY);

  /// Paints onto the layer at canvas pixel ([x], [y]), accounting
  /// for the layer's offset. Out-of-frame paints are ignored.
  void setPixelAt(int x, int y, Color? color) =>
      frame.setPixel(x - offsetX, y - offsetY, color);

  /// Flattens the visible layers bottom-to-top into a single frame
  /// using proper src-over alpha compositing (with per-layer opacity).
  /// Each layer is composited at its [offsetX]/[offsetY].
  static SpriteFrame flatten(List<ArtLayer> layers) {
    assert(layers.isNotEmpty, 'need at least one layer');
    final w = layers.first.frame.width;
    final h = layers.first.frame.height;
    final out = SpriteFrame(width: w, height: h);
    for (final layer in layers) {
      if (!layer.visible) continue;
      final lf = layer.frame;
      for (var y = 0; y < lf.height; y++) {
        for (var x = 0; x < lf.width; x++) {
          final src = lf.getPixel(x, y);
          if (src == null) continue;
          final dx = x + layer.offsetX;
          final dy = y + layer.offsetY;
          if (dx < 0 || dy < 0 || dx >= w || dy >= h) continue;
          out.setPixel(
              dx, dy, _compositeOver(src, layer.opacity, out.getPixel(dx, dy)));
        }
      }
    }
    return out;
  }

  /// Src-over blend of [src] (scaled by [opacity]) onto [dst].
  @visibleForTesting
  static Color compositeOver(Color src, double opacity, Color? dst) =>
      _compositeOver(src, opacity, dst);

  static Color _compositeOver(Color src, double opacity, Color? dst) {
    final sa = (src.a * opacity).clamp(0.0, 1.0);
    if (dst == null) return src.withValues(alpha: sa);
    final da = dst.a;
    final outA = sa + da * (1 - sa);
    if (outA <= 0) return const Color(0x00000000);
    double mix(double s, double d) =>
        (s * sa + d * da * (1 - sa)) / outA;
    int byte(double v) => (v * 255).round().clamp(0, 255);
    return Color.fromARGB(
      byte(outA),
      byte(mix(src.r, dst.r)),
      byte(mix(src.g, dst.g)),
      byte(mix(src.b, dst.b)),
    );
  }

  /// Makes a layer name safe for filenames: lowercase, _ separators.
  static String sanitizeName(String name) {
    final s = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return s.isEmpty ? 'layer' : s;
  }
}
