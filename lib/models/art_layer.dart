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

  ArtLayer({
    required this.name,
    required this.frame,
    this.visible = true,
    this.opacity = 1.0,
  });

  /// Deep copy, used for undo snapshots and duplicating layers.
  ArtLayer clone() => ArtLayer(
        name: name,
        frame: SpriteFrame.clone(frame),
        visible: visible,
        opacity: opacity,
      );

  /// Shifts every pixel of the layer by ([dx], [dy]). Pixels pushed
  /// off the canvas are lost; the vacated area stays transparent.
  static void shift(ArtLayer layer, int dx, int dy) {
    if (dx == 0 && dy == 0) return;
    final frame = layer.frame;
    final w = frame.width;
    final h = frame.height;
    final copy = <List<Color?>>[
      for (final row in frame.pixels) [...row]
    ];
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final sx = x - dx;
        final sy = y - dy;
        frame.pixels[y][x] =
            (sx >= 0 && sx < w && sy >= 0 && sy < h)
                ? copy[sy][sx]
                : null;
      }
    }
  }

  /// Flattens the visible layers bottom-to-top into a single frame
  /// using proper src-over alpha compositing (with per-layer opacity).
  static SpriteFrame flatten(List<ArtLayer> layers) {
    assert(layers.isNotEmpty, 'need at least one layer');
    final w = layers.first.frame.width;
    final h = layers.first.frame.height;
    final out = SpriteFrame(width: w, height: h);
    for (final layer in layers) {
      if (!layer.visible) continue;
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          final src = layer.frame.getPixel(x, y);
          if (src == null) continue;
          out.setPixel(
              x, y, _compositeOver(src, layer.opacity, out.getPixel(x, y)));
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
