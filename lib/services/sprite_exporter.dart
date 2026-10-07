import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../models/sprite_frame.dart';

/// Turns sprite frames into PNG bytes.
///
/// Quality rules (locked in with MutationGames Dev):
/// - Always lossless PNG, never JPEG.
/// - Real transparency: empty pixels stay transparent.
/// - Integer scaling only (1x, 2x, 4x, 8x) with nearest-neighbor sampling,
///   so pixels stay crisp and never blur.
/// - Full color: no 256-color limit.
class SpriteExporter {
  /// Encodes one frame as a lossless PNG at [scale]x size.
  static Uint8List encodeFrame(SpriteFrame frame, {int scale = 1}) {
    assert(scale >= 1, 'scale must be at least 1');
    final outW = frame.width * scale;
    final outH = frame.height * scale;
    final image = img.Image(width: outW, height: outH, numChannels: 4);

    for (var y = 0; y < frame.height; y++) {
      for (var x = 0; x < frame.width; x++) {
        final color = frame.getPixel(x, y);
        final pixel = color == null
            ? img.ColorRgba8(0, 0, 0, 0)
            : img.ColorRgba8(
                (color.r * 255).round(),
                (color.g * 255).round(),
                (color.b * 255).round(),
                (color.a * 255).round(),
              );
        // Integer scale: stamp the pixel as a solid scale x scale block.
        for (var dy = 0; dy < scale; dy++) {
          for (var dx = 0; dx < scale; dx++) {
            image.setPixel(x * scale + dx, y * scale + dy, pixel);
          }
        }
      }
    }
    return Uint8List.fromList(img.encodePng(image));
  }

  /// Packs [frames] into one sprite-sheet PNG.
  ///
  /// A [gutter] of transparent pixels separates frames so a game engine's
  /// linear filtering never smears one frame's edge into the next.
  /// [columns] controls how many frames sit in each row.
  static Uint8List encodeSpriteSheet(
    List<SpriteFrame> frames, {
    int scale = 1,
    int columns = 4,
    int gutter = 2,
  }) {
    assert(frames.isNotEmpty, 'need at least one frame');
    assert(scale >= 1, 'scale must be at least 1');

    final frameW = frames.first.width * scale;
    final frameH = frames.first.height * scale;
    final cols = columns < frames.length ? columns : frames.length;
    final rows = (frames.length / cols).ceil();

    final outW = cols * frameW + (cols + 1) * gutter;
    final outH = rows * frameH + (rows + 1) * gutter;
    final sheet = img.Image(width: outW, height: outH, numChannels: 4);

    for (var i = 0; i < frames.length; i++) {
      final frame = frames[i];
      final col = i % cols;
      final row = i ~/ cols;
      final ox = gutter + col * (frameW + gutter);
      final oy = gutter + row * (frameH + gutter);

      for (var y = 0; y < frame.height; y++) {
        for (var x = 0; x < frame.width; x++) {
          final color = frame.getPixel(x, y);
          final pixel = color == null
              ? img.ColorRgba8(0, 0, 0, 0)
              : img.ColorRgba8(
                  (color.r * 255).round(),
                  (color.g * 255).round(),
                  (color.b * 255).round(),
                  (color.a * 255).round(),
                );
          for (var dy = 0; dy < scale; dy++) {
            for (var dx = 0; dx < scale; dx++) {
              sheet.setPixel(ox + x * scale + dx, oy + y * scale + dy, pixel);
            }
          }
        }
      }
    }
    return Uint8List.fromList(img.encodePng(sheet));
  }
}
