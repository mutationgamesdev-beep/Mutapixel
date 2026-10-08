import 'package:flutter/material.dart';

import '../models/sprite_frame.dart';

/// One-tap "magic" effects for the Canva-style workflow.
/// Every function returns a NEW frame; the caller's undo stack stays valid.
class SpriteEffects {
  /// Adds a 1px outline around all non-transparent pixels.
  /// Only paints on transparent pixels adjacent (8-way) to a solid pixel.
  static SpriteFrame addOutline(SpriteFrame src, Color outline) {
    final out = SpriteFrame.clone(src);
    for (var y = 0; y < src.height; y++) {
      for (var x = 0; x < src.width; x++) {
        if (src.getPixel(x, y) != null) continue;
        var touchesSolid = false;
        for (var dy = -1; dy <= 1 && !touchesSolid; dy++) {
          for (var dx = -1; dx <= 1 && !touchesSolid; dx++) {
            if (dx == 0 && dy == 0) continue;
            if (src.getPixel(x + dx, y + dy) != null) {
              touchesSolid = true;
            }
          }
        }
        if (touchesSolid) out.setPixel(x, y, outline);
      }
    }
    return out;
  }

  /// Adds a drop shadow offset by (dx, dy) behind the sprite.
  /// Shadow pixels are drawn only where the sprite is transparent.
  static SpriteFrame addDropShadow(
    SpriteFrame src, {
    int dx = 2,
    int dy = 2,
    Color shadow = const Color(0x66000000),
  }) {
    final out = SpriteFrame.clone(src);
    for (var y = 0; y < src.height; y++) {
      for (var x = 0; x < src.width; x++) {
        if (src.getPixel(x, y) == null) continue;
        final tx = x + dx, ty = y + dy;
        if (tx < 0 || ty < 0 || tx >= out.width || ty >= out.height) continue;
        if (out.getPixel(tx, ty) == null) out.setPixel(tx, ty, shadow);
      }
    }
    return out;
  }

  /// Replaces every pixel of [from] with [to].
  static SpriteFrame recolor(SpriteFrame src, Color from, Color to) {
    final out = SpriteFrame.clone(src);
    final target = from.toARGB32();
    for (var y = 0; y < out.height; y++) {
      for (var x = 0; x < out.width; x++) {
        final p = out.getPixel(x, y);
        if (p != null && p.toARGB32() == target) {
          out.setPixel(x, y, to);
        }
      }
    }
    return out;
  }

  /// The most frequent non-transparent color, or null when empty.
  /// Used to suggest "recolor the main color".
  static Color? dominantColor(SpriteFrame src) {
    final counts = <int, int>{};
    final byArgb = <int, Color>{};
    for (var y = 0; y < src.height; y++) {
      for (var x = 0; x < src.width; x++) {
        final p = src.getPixel(x, y);
        if (p == null) continue;
        final key = p.toARGB32();
        counts[key] = (counts[key] ?? 0) + 1;
        byArgb[key] = p;
      }
    }
    if (counts.isEmpty) return null;
    var best = counts.entries.first;
    for (final e in counts.entries) {
      if (e.value > best.value) best = e;
    }
    return byArgb[best.key];
  }

  /// All distinct non-transparent colors, most frequent first.
  static List<Color> paletteOf(SpriteFrame src) {
    final counts = <int, int>{};
    final byArgb = <int, Color>{};
    for (var y = 0; y < src.height; y++) {
      for (var x = 0; x < src.width; x++) {
        final p = src.getPixel(x, y);
        if (p == null) continue;
        final key = p.toARGB32();
        counts[key] = (counts[key] ?? 0) + 1;
        byArgb[key] = p;
      }
    }
    final keys = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return [for (final k in keys) byArgb[k]!];
  }

  static SpriteFrame flipHorizontal(SpriteFrame src) {
    final out = SpriteFrame(width: src.width, height: src.height);
    for (var y = 0; y < src.height; y++) {
      for (var x = 0; x < src.width; x++) {
        out.setPixel(src.width - 1 - x, y, src.getPixel(x, y));
      }
    }
    return out;
  }

  static SpriteFrame flipVertical(SpriteFrame src) {
    final out = SpriteFrame(width: src.width, height: src.height);
    for (var y = 0; y < src.height; y++) {
      for (var x = 0; x < src.width; x++) {
        out.setPixel(x, src.height - 1 - y, src.getPixel(x, y));
      }
    }
    return out;
  }

  /// Stamps [part] onto [src] with its top-left at (ox, oy).
  /// Transparent part pixels are skipped; out-of-bounds pixels are clipped.
  static SpriteFrame stamp(
      SpriteFrame src, SpriteFrame part, int ox, int oy) {
    final out = SpriteFrame.clone(src);
    for (var y = 0; y < part.height; y++) {
      for (var x = 0; x < part.width; x++) {
        final p = part.getPixel(x, y);
        if (p == null) continue;
        out.setPixel(ox + x, oy + y, p);
      }
    }
    return out;
  }
}
