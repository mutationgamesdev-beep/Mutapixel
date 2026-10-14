import 'dart:ui' as ui;

import 'package:flutter/material.dart';
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
  final codec =
      await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  final image = frame.image;
  try {
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) {
      throw StateError('Could not decode $assetPath');
    }
    final src = byteData.buffer.asUint8List();
    final out = SpriteFrame(width: size, height: size);

    final longEdge =
        image.width > image.height ? image.width : image.height;
    final scale = size / longEdge;
    final w = (image.width * scale).round().clamp(1, size);
    final h = (image.height * scale).round().clamp(1, size);
    final ox = (size - w) ~/ 2;
    final oy = (size - h) ~/ 2;

    for (var y = 0; y < h; y++) {
      final sy =
          (y / scale).floor().clamp(0, image.height - 1);
      for (var x = 0; x < w; x++) {
        final sx =
            (x / scale).floor().clamp(0, image.width - 1);
        final i = (sy * image.width + sx) * 4;
        out.setPixel(
          ox + x,
          oy + y,
          Color.fromARGB(
            src[i + 3],
            src[i],
            src[i + 1],
            src[i + 2],
          ),
        );
      }
    }
    return out;
  } finally {
    image.dispose();
  }
}
