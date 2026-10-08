import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mutapixel/models/sprite_frame.dart';
import 'package:mutapixel/services/sprite_exporter.dart';

SpriteFrame _testFrame() {
  final frame = SpriteFrame(width: 4, height: 4);
  frame.setPixel(0, 0, const Color(0xFFFF0000)); // opaque red
  frame.setPixel(3, 3, const Color(0xFF0000FF)); // opaque blue
  // (1,1) stays transparent
  return frame;
}

void main() {
  group('SpriteExporter', () {
    test('single frame PNG has correct scaled size', () {
      final bytes = SpriteExporter.encodeFrame(_testFrame(), scale: 4);
      final decoded = img.decodePng(bytes)!;
      expect(decoded.width, 16);
      expect(decoded.height, 16);
    });

    test('integer scaling keeps pixels crisp', () {
      final bytes = SpriteExporter.encodeFrame(_testFrame(), scale: 4);
      final decoded = img.decodePng(bytes)!;
      // The 4x4 block for pixel (0,0) should be uniformly red.
      for (var y = 0; y < 4; y++) {
        for (var x = 0; x < 4; x++) {
          final p = decoded.getPixel(x, y);
          expect(p.r, 255);
          expect(p.g, 0);
          expect(p.b, 0);
          expect(p.a, 255);
        }
      }
    });

    test('transparency is preserved', () {
      final bytes = SpriteExporter.encodeFrame(_testFrame(), scale: 2);
      final decoded = img.decodePng(bytes)!;
      // Pixel (1,1) was transparent -> 2x2 block at (2,2).
      final p = decoded.getPixel(2, 2);
      expect(p.a, 0);
    });

    test('sprite sheet packs frames with a 2px gutter', () {
      final frames = [_testFrame(), _testFrame(), _testFrame()];
      const scale = 2;
      const gutter = 2;
      final bytes = SpriteExporter.encodeSpriteSheet(
        frames,
        scale: scale,
        columns: 2,
        gutter: gutter,
      );
      final decoded = img.decodePng(bytes)!;
      // 2 cols x 8px frames + 3 gutters of 2px = 22
      expect(decoded.width, 2 * 8 + 3 * gutter);
      // 2 rows x 8px frames + 3 gutters of 2px = 22
      expect(decoded.height, 2 * 8 + 3 * gutter);

      // The gutter column between frame 1 and 2 must be transparent.
      final gutterX = gutter + 8; // right after first frame
      final p = decoded.getPixel(gutterX, gutter + 2);
      expect(p.a, 0);
    });
  });
}
