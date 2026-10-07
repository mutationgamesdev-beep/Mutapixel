import 'package:flutter_test/flutter_test.dart';
import 'package:sprite_builder/data/palette_presets.dart';
import 'package:sprite_builder/data/starter_templates.dart';

void main() {
  group('PalettePresets', () {
    test('all presets have names and colors', () {
      expect(PalettePresets.all, isNotEmpty);
      for (final palette in PalettePresets.all) {
        expect(palette.name, isNotEmpty);
        expect(palette.colors, isNotEmpty);
      }
    });

    test('PICO-8 has exactly 16 colors', () {
      expect(PalettePresets.pico8.colors.length, 16);
    });

    test('Game Boy has 4 colors', () {
      expect(PalettePresets.gameBoy.colors.length, 4);
    });
  });

  group('StarterTemplates', () {
    test('templates build valid 16x16 frames', () {
      for (final template in StarterTemplates.all) {
        final frame = template.toFrame();
        expect(frame.width, 16);
        expect(frame.height, 16);
        expect(frame.isEmpty, isFalse,
            reason: '${template.name} should not be blank');
      }
    });

    test('every template character maps to a color', () {
      for (final template in StarterTemplates.all) {
        for (final row in template.rows) {
          expect(row.length, 16);
          for (var i = 0; i < row.length; i++) {
            final ch = row[i];
            expect(
              ch == '.' || template.colors.containsKey(ch),
              isTrue,
              reason: 'unmapped char "$ch" in ${template.name}',
            );
          }
        }
      }
    });
  });
}
