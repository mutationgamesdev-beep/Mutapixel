import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutapixel/models/sprite_frame.dart';
import 'package:mutapixel/services/sprite_effects.dart';

SpriteFrame _frame(List<String> rows, Map<String, Color> colors) {
  final f = SpriteFrame(width: rows.first.length, height: rows.length);
  for (var y = 0; y < rows.length; y++) {
    for (var x = 0; x < rows[y].length; x++) {
      final ch = rows[y][x];
      if (ch == '.') continue;
      f.setPixel(x, y, colors[ch]);
    }
  }
  return f;
}

void main() {
  const red = Color(0xFFFF0000);
  const blue = Color(0xFF0000FF);
  const black = Color(0xFF000000);

  test('outline adds border around solid pixels only', () {
    final src = _frame(['...', '.R.', '...'], {'R': red});
    final out = SpriteEffects.addOutline(src, black);
    // All 8 neighbors of the center pixel become outline.
    expect(out.getPixel(0, 0), black);
    expect(out.getPixel(1, 0), black);
    expect(out.getPixel(2, 2), black);
    // The original pixel is untouched.
    expect(out.getPixel(1, 1), red);
  });

  test('outline does not overwrite existing pixels', () {
    final src = _frame(['RB', '..'], {'R': red, 'B': blue});
    final out = SpriteEffects.addOutline(src, black);
    expect(out.getPixel(1, 0), blue);
  });

  test('drop shadow offsets a dark copy behind', () {
    final src = _frame(['R..', '...', '...'], {'R': red});
    final out = SpriteEffects.addDropShadow(src, dx: 1, dy: 1);
    expect(out.getPixel(0, 0), red);
    expect(out.getPixel(1, 1)?.toARGB32(),
        const Color(0x66000000).toARGB32());
  });

  test('recolor swaps one color for another', () {
    final src = _frame(['RB', 'BR'], {'R': red, 'B': blue});
    final out = SpriteEffects.recolor(src, red, black);
    expect(out.getPixel(0, 0), black);
    expect(out.getPixel(1, 1), black);
    expect(out.getPixel(1, 0), blue);
  });

  test('dominantColor finds the most frequent color', () {
    final src = _frame(['RRB', 'RRR'], {'R': red, 'B': blue});
    expect(SpriteEffects.dominantColor(src), red);
  });

  test('dominantColor returns null for empty frame', () {
    final src = SpriteFrame(width: 4, height: 4);
    expect(SpriteEffects.dominantColor(src), isNull);
  });

  test('flipHorizontal mirrors pixels', () {
    final src = _frame(['RB'], {'R': red, 'B': blue});
    final out = SpriteEffects.flipHorizontal(src);
    expect(out.getPixel(0, 0), blue);
    expect(out.getPixel(1, 0), red);
  });

  test('flipVertical mirrors pixels', () {
    final src = _frame(['R', 'B'], {'R': red, 'B': blue});
    final out = SpriteEffects.flipVertical(src);
    expect(out.getPixel(0, 0), blue);
    expect(out.getPixel(0, 1), red);
  });

  test('stamp overlays part and clips out of bounds', () {
    final src = SpriteFrame(width: 4, height: 4);
    final part = _frame(['RR', 'RR'], {'R': red});
    final out = SpriteEffects.stamp(src, part, 3, 3);
    // Only (3,3) fits; the rest is clipped.
    expect(out.getPixel(3, 3), red);
    expect(out.getPixel(0, 0), isNull);
  });

  test('stamp skips transparent part pixels', () {
    final src = _frame(['BB', 'BB'], {'B': blue});
    final part = _frame(['R.', '.R'], {'R': red});
    final out = SpriteEffects.stamp(src, part, 0, 0);
    expect(out.getPixel(0, 0), red);
    expect(out.getPixel(1, 0), blue); // transparent part pixel kept src
    expect(out.getPixel(1, 1), red);
  });
}
