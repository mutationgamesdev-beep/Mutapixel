import 'package:flutter/material.dart';

/// One frame of a sprite: a grid of pixels.
/// A pixel holds a [Color], or null when it is transparent.
class SpriteFrame {
  final int width;
  final int height;
  final List<List<Color?>> pixels;

  SpriteFrame({required this.width, required this.height})
      : pixels = List.generate(
          height,
          (_) => List<Color?>.filled(width, null),
          growable: false,
        );

  /// Deep copy, used for undo snapshots and duplicating frames.
  SpriteFrame.clone(SpriteFrame other)
      : width = other.width,
        height = other.height,
        pixels = [
          for (final row in other.pixels) [...row]
        ];

  Color? getPixel(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return null;
    return pixels[y][x];
  }

  void setPixel(int x, int y, Color? color) {
    if (x < 0 || y < 0 || x >= width || y >= height) return;
    pixels[y][x] = color;
  }

  /// Returns a copy resized to [newWidth] x [newHeight], keeping the
  /// top-left content and cropping or padding with transparency.
  SpriteFrame resized(int newWidth, int newHeight) {
    final out = SpriteFrame(width: newWidth, height: newHeight);
    final copyW = width < newWidth ? width : newWidth;
    final copyH = height < newHeight ? height : newHeight;
    for (var y = 0; y < copyH; y++) {
      for (var x = 0; x < copyW; x++) {
        out.pixels[y][x] = pixels[y][x];
      }
    }
    return out;
  }

  /// True when every pixel is transparent.
  bool get isEmpty {
    for (final row in pixels) {
      for (final pixel in row) {
        if (pixel != null) return false;
      }
    }
    return true;
  }
}
