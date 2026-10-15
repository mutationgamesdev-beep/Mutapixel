import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mutapixel/services/ai_generation.dart';

void main() {
  group('AiGeneration prompts', () {
    test('pixelArtPrompt wraps the user words as pixel art', () {
      final prompt = AiGeneration.pixelArtPrompt('fire knight');
      expect(prompt, contains('fire knight'));
      expect(prompt, contains('pixel art'));
      expect(prompt, isNot(contains('null')));
    });

    test('spriteSheetPrompt asks for a 2x2 frame grid', () {
      final prompt =
          AiGeneration.spriteSheetPrompt('running robot');
      expect(prompt, contains('running robot'));
      expect(prompt, contains('2x2'));
      expect(prompt, contains('4 animation frames'));
    });

    test('photoPrompt works with and without a hint', () {
      final withHint = AiGeneration.photoPrompt('dragon');
      expect(withHint, contains('dragon'));
      final withoutHint = AiGeneration.photoPrompt(null);
      expect(withoutHint, isNot(contains('null')));
      expect(withoutHint, contains('pixel art'));
    });

    test('photoSheetPrompt falls back to the photo subject', () {
      final fallback = AiGeneration.photoSheetPrompt(null);
      expect(fallback, contains('2x2'));
      final withHint = AiGeneration.photoSheetPrompt('knight');
      expect(withHint, contains('knight'));
    });

    test('artUrl builds a valid pollinations URL', () {
      final uri = AiGeneration.artUrl('fire knight');
      expect(uri.scheme, 'https');
      expect(uri.host, 'image.pollinations.ai');
      expect(uri.queryParameters['model'], isNotNull);
      expect(uri.queryParameters['width'], isNotNull);
    });

    test('photoDataUrl produces a small JPEG data URL', () {
      final image = img.Image(width: 8, height: 8);
      final png =
          Uint8List.fromList(img.encodePng(image));
      final url = AiGeneration.photoDataUrl(png);
      expect(url, startsWith('data:image/jpeg;base64,'));
      // Downscaled + JPEG: must stay small enough for a URL.
      expect(url.length, lessThan(20000));
    });
  });
}
