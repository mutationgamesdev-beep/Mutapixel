import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprite_builder/models/sprite_frame.dart';

void main() {
  group('SpriteFrame', () {
    test('starts fully transparent', () {
      final frame = SpriteFrame(width: 16, height: 16);
      expect(frame.isEmpty, isTrue);
      expect(frame.getPixel(0, 0), isNull);
    });

    test('set and get pixels', () {
      final frame = SpriteFrame(width: 16, height: 16);
      const red = Color(0xFFFF0000);
      frame.setPixel(3, 5, red);
      expect(frame.getPixel(3, 5), red);
      expect(frame.isEmpty, isFalse);
    });

    test('out-of-bounds access is safe', () {
      final frame = SpriteFrame(width: 16, height: 16);
      frame.setPixel(-1, 0, const Color(0xFFFF0000));
      frame.setPixel(16, 16, const Color(0xFFFF0000));
      expect(frame.getPixel(-1, 0), isNull);
      expect(frame.isEmpty, isTrue);
    });

    test('clone is independent', () {
      final frame = SpriteFrame(width: 8, height: 8);
      frame.setPixel(1, 1, const Color(0xFF00FF00));
      final copy = SpriteFrame.clone(frame);
      copy.setPixel(1, 1, null);
      expect(frame.getPixel(1, 1), isNotNull);
      expect(copy.getPixel(1, 1), isNull);
    });

    test('resize keeps top-left content', () {
      final frame = SpriteFrame(width: 16, height: 16);
      const blue = Color(0xFF0000FF);
      frame.setPixel(0, 0, blue);
      frame.setPixel(15, 15, blue);

      final bigger = frame.resized(32, 32);
      expect(bigger.getPixel(0, 0), blue);
      expect(bigger.getPixel(15, 15), blue);
      expect(bigger.getPixel(31, 31), isNull);

      final smaller = frame.resized(8, 8);
      expect(smaller.getPixel(0, 0), blue);
      expect(smaller.width, 8);
    });
  });
}
