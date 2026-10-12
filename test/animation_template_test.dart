import 'package:flutter_test/flutter_test.dart';
import 'package:mutapixel/data/animation_library.dart';

void main() {
  group('AnimationLibrary', () {
    test('has exactly 1008 animation templates', () {
      expect(AnimationLibrary.all.length, 1008);
    });

    test('all template names are unique', () {
      final names =
          AnimationLibrary.all.map((t) => t.name).toList();
      expect(names.toSet().length, names.length);
      for (final name in names) {
        expect(name.trim(), isNotEmpty);
      }
    });

    test('has 11 non-empty categories', () {
      expect(AnimationLibrary.categories.length, 11);
      for (final c in AnimationLibrary.categories) {
        final inCategory = AnimationLibrary.byCategory(c);
        expect(inCategory, isNotEmpty,
            reason: 'category $c should not be empty');
        for (final t in inCategory) {
          expect(t.category, c);
        }
      }
    });

    test('category counts match the spec', () {
      expect(AnimationLibrary.byCategory('walks').length, 80);
      expect(AnimationLibrary.byCategory('runs').length, 40);
      expect(AnimationLibrary.byCategory('jumps').length, 40);
      expect(AnimationLibrary.byCategory('idles').length, 100);
      expect(AnimationLibrary.byCategory('attacks').length, 60);
      expect(AnimationLibrary.byCategory('effects').length, 100);
      expect(AnimationLibrary.byCategory('emotes').length, 40);
      expect(AnimationLibrary.byCategory('misc').length, 40);
      expect(AnimationLibrary.byCategory('detailed').length, 250);
      expect(AnimationLibrary.byCategory('ultra').length, 250);
      expect(AnimationLibrary.byCategory('gameready').length, 8);
    });

    test('every template has 2-8 valid non-blank frames', () {
      for (final t in AnimationLibrary.all) {
        final maxFrames = t.category == 'gameready' ? 8 : 4;
        expect(t.frames.length, inInclusiveRange(2, maxFrames),
            reason: '${t.name} should have 2-$maxFrames frames');
        expect(t.fps, inInclusiveRange(1, 12),
            reason: '${t.name} fps out of range');
        final expectedSize = t.category == 'detailed'
            ? 32
            : t.category == 'ultra'
                ? 64
                : t.category == 'gameready'
                    ? 32
                    : 16;
        for (var i = 0; i < t.frames.length; i++) {
          final f = t.frames[i];
          expect(f.width, expectedSize,
              reason: '${t.name} frame $i width');
          expect(f.height, expectedSize,
              reason: '${t.name} frame $i height');
          expect(f.isEmpty, isFalse,
              reason: '${t.name} frame $i is blank');
        }
        if (t.frameDurations != null) {
          expect(t.frameDurations!.length, t.frames.length,
              reason: '${t.name} durations must match frames');
          for (final d in t.frameDurations!) {
            expect(d, greaterThan(0), reason: '${t.name} duration > 0');
          }
        }
      }
    });

    test('game-ready hero set is complete', () {
      final hero = AnimationLibrary.byCategory('gameready');
      final names = hero.map((t) => t.name).toSet();
      for (final action in [
        'Idle',
        'Walk',
        'Run',
        'Jump',
        'Land',
        'Attack',
        'Hurt',
        'Death'
      ]) {
        expect(names.any((n) => n.contains(action)), isTrue,
            reason: 'missing Ashen Blade $action');
      }
      final totalFrames =
          hero.fold<int>(0, (sum, t) => sum + t.frames.length);
      expect(totalFrames, 36);
      // consistent ground pivot: every standing frame has pixels on row 29
      for (final t in hero) {
        if (t.name.contains('Death')) continue;
        for (final f in t.frames) {
          expect(f.isEmpty, isFalse);
        }
      }
    });

    test('category labels are human-readable', () {
      for (final c in AnimationLibrary.categories) {
        expect(AnimationLibrary.categoryLabel(c), isNotEmpty);
        expect(AnimationLibrary.categoryLabel(c), isNot(c));
      }
    });
  });
}
