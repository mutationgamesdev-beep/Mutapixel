import 'package:flutter_test/flutter_test.dart';
import 'package:mutapixel/data/palette_presets.dart';
import 'package:mutapixel/data/starter_templates.dart';
import 'package:mutapixel/data/template_library.dart';

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

  group('TemplateLibrary', () {
    test('has 171 templates across 9 categories', () {
      expect(TemplateLibrary.all.length, 171);
      expect(TemplateLibrary.categories.length, 9);
      for (final c in TemplateLibrary.categories) {
        expect(TemplateLibrary.byCategory(c), isNotEmpty,
            reason: 'category "$c" should not be empty');
      }
    });

    test('all templates are valid 16x16 or 32x32 with mapped colors', () {
      final names = <String>{};
      for (final template in TemplateLibrary.all) {
        expect(template.name, isNotEmpty);
        expect(names.add(template.name), isTrue,
            reason: 'duplicate template name "${template.name}"');
        final size = template.rows.length;
        expect(size == 16 || size == 32, isTrue,
            reason: '${template.name} should be 16x16 or 32x32');
        for (final row in template.rows) {
          expect(row.length, size);
          for (var i = 0; i < row.length; i++) {
            final ch = row[i];
            expect(
              ch == '.' || template.colors.containsKey(ch),
              isTrue,
              reason: 'unmapped char "$ch" in ${template.name}',
            );
          }
        }
        final frame = template.toFrame();
        expect(frame.isEmpty, isFalse,
            reason: '${template.name} should not be blank');
      }
    });

    test('detailed category has 30 native 32x32 templates', () {
      final detailed = TemplateLibrary.byCategory('detailed');
      expect(detailed.length, 30);
      for (final t in detailed) {
        expect(t.rows.length, 32);
        expect(t.toFrame().width, 32);
      }
    });
  });
}
