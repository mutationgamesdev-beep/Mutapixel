import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutapixel/models/art_layer.dart';
import 'package:mutapixel/models/sprite_frame.dart';

SpriteFrame _solid(int size, Color color) {
  final frame = SpriteFrame(width: size, height: size);
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      frame.setPixel(x, y, color);
    }
  }
  return frame;
}

void main() {
  group('ArtLayer', () {
    test('clone is a deep copy', () {
      final layer = ArtLayer(
          name: 'A', frame: _solid(4, const Color(0xFFFF0000)));
      final copy = layer.clone();
      copy.frame.setPixel(0, 0, null);
      copy.name = 'B';
      expect(layer.name, 'A');
      expect(layer.frame.getPixel(0, 0), const Color(0xFFFF0000));
    });

    test('defaults to visible and fully opaque', () {
      final layer =
          ArtLayer(name: 'A', frame: _solid(2, const Color(0xFFFF0000)));
      expect(layer.visible, isTrue);
      expect(layer.opacity, 1.0);
    });

    test('shift moves the offset and never touches pixels', () {
      final frame = SpriteFrame(width: 4, height: 4);
      frame.setPixel(0, 0, const Color(0xFFFF0000));
      final layer = ArtLayer(name: 'A', frame: frame);

      ArtLayer.shift(layer, 2, 1);

      // Pixels stay put in the frame; the offset records the move.
      expect(layer.frame.getPixel(0, 0), const Color(0xFFFF0000));
      expect(layer.offsetX, 2);
      expect(layer.offsetY, 1);
      // Canvas-space lookup reflects the move.
      expect(layer.getPixelAt(2, 1), const Color(0xFFFF0000));
      expect(layer.getPixelAt(0, 0), isNull);
    });

    test('shift off-canvas keeps pixels intact', () {
      final frame = SpriteFrame(width: 4, height: 4);
      frame.setPixel(3, 3, const Color(0xFFFF0000));
      final layer = ArtLayer(name: 'A', frame: frame);

      ArtLayer.shift(layer, 1, 0);

      // Nothing is lost: the pixel is still in the frame.
      expect(layer.frame.getPixel(3, 3), const Color(0xFFFF0000));
      // Moving back restores the full image.
      ArtLayer.shift(layer, -1, 0);
      expect(layer.getPixelAt(3, 3), const Color(0xFFFF0000));
    });

    test('shift with zero delta does nothing', () {
      final frame = SpriteFrame(width: 4, height: 4);
      frame.setPixel(1, 1, const Color(0xFFFF0000));
      final layer = ArtLayer(name: 'A', frame: frame);

      ArtLayer.shift(layer, 0, 0);

      expect(layer.frame.getPixel(1, 1), const Color(0xFFFF0000));
    });

    test('flatten composites bottom-to-top, top wins', () {
      final layers = [
        ArtLayer(name: 'bg', frame: _solid(2, const Color(0xFF0000FF))),
        ArtLayer(name: 'top', frame: _solid(2, const Color(0xFFFF0000))),
      ];
      final flat = ArtLayer.flatten(layers);
      final c = flat.getPixel(0, 0)!;
      expect(c.r, closeTo(1.0, 0.01));
      expect(c.b, closeTo(0.0, 0.01));
    });

    test('flatten respects per-layer opacity', () {
      final layers = [
        ArtLayer(name: 'bg', frame: _solid(2, const Color(0xFF0000FF))),
        ArtLayer(
            name: 'top',
            frame: _solid(2, const Color(0xFFFF0000)),
            opacity: 0.5),
      ];
      final flat = ArtLayer.flatten(layers);
      final c = flat.getPixel(0, 0)!;
      // 50% red over blue -> purple-ish midpoint.
      expect(c.r, closeTo(0.5, 0.05));
      expect(c.b, closeTo(0.5, 0.05));
    });

    test('flatten skips invisible layers', () {
      final layers = [
        ArtLayer(name: 'bg', frame: _solid(2, const Color(0xFF0000FF))),
        ArtLayer(
            name: 'hidden',
            frame: _solid(2, const Color(0xFFFF0000)),
            visible: false),
      ];
      final flat = ArtLayer.flatten(layers);
      final c = flat.getPixel(0, 0)!;
      expect(c.b, closeTo(1.0, 0.01));
      expect(c.r, closeTo(0.0, 0.01));
    });

    test('flatten keeps transparency where nothing is painted',
        () {
      final bg = SpriteFrame(width: 2, height: 2);
      bg.setPixel(0, 0, const Color(0xFFFF0000));
      final layers = [ArtLayer(name: 'bg', frame: bg)];
      final flat = ArtLayer.flatten(layers);
      expect(flat.getPixel(0, 0), isNotNull);
      expect(flat.getPixel(1, 1), isNull);
    });

    test('flatten respects layer offset', () {
      final frame = SpriteFrame(width: 2, height: 2);
      frame.setPixel(0, 0, const Color(0xFFFF0000));
      final layers = [
        ArtLayer(name: 'moved', frame: frame, offsetX: 1, offsetY: 0),
      ];
      final flat = ArtLayer.flatten(layers);
      expect(flat.getPixel(1, 0), const Color(0xFFFF0000));
      expect(flat.getPixel(0, 0), isNull);
    });

    test('sanitizeName makes filenames safe', () {
      expect(ArtLayer.sanitizeName('Background'), 'background');
      expect(ArtLayer.sanitizeName('Cool Eyes!'), 'cool_eyes');
      expect(ArtLayer.sanitizeName('  '), 'layer');
      expect(
          ArtLayer.sanitizeName('Layer 2 (copy)'), 'layer_2_copy');
    });
  });
}
