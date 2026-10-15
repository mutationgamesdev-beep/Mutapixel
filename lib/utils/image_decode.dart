import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../models/sprite_frame.dart';

/// Decodes an image asset into a [SpriteFrame].
///
/// The source image is scaled to fit inside a [size]×[size] square
/// (aspect preserved) and centered on transparency, so portrait and
/// landscape artwork both land cleanly on the square canvas.
Future<SpriteFrame> spriteFrameFromAsset(
  String assetPath, {
  int size = 256,
}) async {
  final data = await rootBundle.load(assetPath);
  return spriteFrameFromBytes(data.buffer.asUint8List(), size: size);
}

/// Decodes raw image bytes (PNG/JPEG) into a [SpriteFrame].
///
/// The source is scaled to fit inside a [size]×[size] square
/// (aspect preserved) and centered on transparency. When
/// [cropBottom] is set, that fraction of the source's bottom edge is
/// discarded first — used to strip generator watermarks.
Future<SpriteFrame> spriteFrameFromBytes(
  Uint8List bytes, {
  int size = 128,
  double cropBottom = 0.0,
}) async {
  final frames = await spriteSheetFramesFromBytes(
    bytes,
    columns: 1,
    rows: 1,
    size: size,
    cropBottom: cropBottom,
  );
  return frames.single;
}

/// Slices a sprite-sheet image into [columns]×[rows] animation frames.
///
/// Each cell is sampled down to a [size]×[size] [SpriteFrame] with
/// nearest-neighbor sampling, which keeps the crunchy pixel look.
/// [cropBottom] discards that fraction of the source's bottom edge first
/// (generator watermarks live there).
Future<List<SpriteFrame>> spriteSheetFramesFromBytes(
  Uint8List bytes, {
  int columns = 2,
  int rows = 2,
  int size = 128,
  double cropBottom = 0.0,
}) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;
  try {
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) {
      throw const FormatException('Could not decode image bytes');
    }
    final src = byteData.buffer.asUint8List();
    final srcW = image.width;
    final srcH =
        (image.height * (1.0 - cropBottom)).round().clamp(1, image.height);

    Color sample(double fx, double fy) {
      final sx = (fx * srcW).floor().clamp(0, srcW - 1);
      final sy = (fy * srcH).floor().clamp(0, srcH - 1);
      final i = (sy * srcW + sx) * 4;
      return Color.fromARGB(src[i + 3], src[i], src[i + 1], src[i + 2]);
    }

    final out = <SpriteFrame>[];
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < columns; c++) {
        final cell = SpriteFrame(width: size, height: size);
        for (var y = 0; y < size; y++) {
          for (var x = 0; x < size; x++) {
            cell.setPixel(
              x,
              y,
              sample((c + x / size) / columns, (r + y / size) / rows),
            );
          }
        }
        out.add(cell);
      }
    }
    return out;
  } finally {
    image.dispose();
  }
}
