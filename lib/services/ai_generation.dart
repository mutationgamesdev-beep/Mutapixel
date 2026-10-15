import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

/// AI image generation for the AI Lab chat.
///
/// Uses the Pollinations free image API (no key needed). The provider sits
/// behind this small interface so a premium key-based provider (e.g.
/// Replicate) can be slotted in later without touching the chat UI.
class AiGeneration {
  static const _base = 'https://image.pollinations.ai/prompt';
  static const _model = 'flux';

  /// Builds the pixel-art prompt from the user's plain words.
  static String pixelArtPrompt(String userPrompt) {
    final clean = userPrompt.trim();
    return 'pixel art game sprite of $clean, 32-bit style, limited color '
        'palette, clean readable silhouette, centered, solid dark background, '
        'game asset, no text, no watermark, no signature';
  }

  /// Builds the sprite-sheet prompt: one image, 2x2 grid of animation frames.
  static String spriteSheetPrompt(String userPrompt) {
    final clean = userPrompt.trim();
    return 'pixel art sprite sheet, 2x2 grid of 4 animation frames of $clean, '
        'walk cycle, the exact same character with identical design and colors '
        'in every frame, 32-bit pixel art style, limited color palette, solid '
        'dark background, 4 frames in 2 rows and 2 columns with small gaps '
        'between them, no text, no watermark, no signature';
  }

  /// Builds the photo-recreation prompt.
  static String photoPrompt(String? userPrompt) {
    final hint = (userPrompt == null || userPrompt.trim().isEmpty)
        ? ''
        : ', ${userPrompt.trim()}';
    return 'recreate this image as a clean 32-bit pixel art game sprite$hint, '
        'keep the same subject, pose and colors, limited color palette, clean '
        'readable silhouette, solid dark background, no text, no watermark, '
        'no signature';
  }

  /// Builds the photo-to-animation prompt: same character, 4 frames.
  static String photoSheetPrompt(String? userPrompt) {
    final subject = (userPrompt == null || userPrompt.trim().isEmpty)
        ? 'the character in the photo'
        : userPrompt.trim();
    return 'pixel art sprite sheet, 2x2 grid of 4 animation frames of '
        '$subject, walk cycle, the exact same character with identical design '
        'and colors in every frame, 32-bit pixel art style, limited color '
        'palette, solid dark background, 4 frames in 2 rows and 2 columns '
        'with small gaps between them, no text, no watermark, no signature';
  }

  /// Public for tests: the raw image URL for a pixel-art prompt.
  static Uri artUrl(String userPrompt) =>
      _uri(pixelArtPrompt(userPrompt));

  /// Recreates the user's photo as a 4-frame animation sheet.
  static Future<Uint8List> recreateAnimationSheet(
      Uint8List photoBytes, String? userPrompt) async {
    final dataUrl = photoDataUrl(photoBytes);
    final uri = _uri(photoSheetPrompt(userPrompt),
        width: 1024, height: 1024, imageDataUrl: dataUrl);
    try {
      return await _fetch(uri,
          timeout: const Duration(minutes: 4));
    } catch (_) {
      throw const AiGenerationException(
          'The AI could not animate that photo. Try a clearer photo with '
          'the subject centered.');
    }
  }

  static Uri _uri(String prompt,
      {int width = 512, int height = 512, String? imageDataUrl}) {
    final params = <String, String>{
      'width': '$width',
      'height': '$height',
      'model': _model,
      'nologo': 'true',
      'seed': '${DateTime.now().millisecondsSinceEpoch % 1000000}',
    };
    if (imageDataUrl case final url?) params['image'] = url;
    return Uri.parse('$_base/${Uri.encodeComponent(prompt)}')
        .replace(queryParameters: params);
  }

  /// Generates one pixel-art image from the user's words. Returns raw bytes.
  static Future<Uint8List> generateArt(String userPrompt) {
    return _fetch(_uri(pixelArtPrompt(userPrompt)));
  }

  /// Generates one 2x2 sprite sheet of animation frames. Returns raw bytes.
  static Future<Uint8List> generateAnimationSheet(String userPrompt) {
    return _fetch(
        _uri(spriteSheetPrompt(userPrompt), width: 1024, height: 1024));
  }

  /// Recreates the user's photo as pixel art. Returns raw bytes.
  ///
  /// The photo is downscaled and sent inline as a data URL (no hosting
  /// needed). Throws [AiGenerationException] with a friendly message when
  /// the AI can't do it.
  static Future<Uint8List> recreatePhoto(
      Uint8List photoBytes, String? userPrompt) async {
    final dataUrl = photoDataUrl(photoBytes);
    final uri = _uri(photoPrompt(userPrompt), imageDataUrl: dataUrl);
    try {
      return await _fetch(uri,
          timeout: const Duration(minutes: 4));
    } catch (_) {
      throw const AiGenerationException(
          'The AI could not recreate that photo. Try a clearer photo with '
          'the subject centered.');
    }
  }

  /// Downscales the photo and packs it as a small JPEG data URL.
  /// Public for tests.
  static String photoDataUrl(Uint8List photoBytes) {
    final decoded = img.decodeImage(photoBytes);
    if (decoded == null) {
      throw const AiGenerationException(
          'That file could not be read as a photo. Try a PNG or JPEG.');
    }
    final small = img.copyResize(decoded,
        width: decoded.width >= decoded.height ? 256 : null,
        height: decoded.height > decoded.width ? 256 : null);
    final jpeg = img.encodeJpg(small, quality: 70);
    return 'data:image/jpeg;base64,${base64Encode(jpeg)}';
  }

  static Future<Uint8List> _fetch(Uri uri,
      {Duration timeout = const Duration(minutes: 3)}) async {
    try {
      final response =
          await http.get(uri).timeout(timeout);
      if (response.statusCode != 200 ||
          response.bodyBytes.isEmpty) {
        throw AiGenerationException(
            'The AI service returned an error (${response.statusCode}). '
            'Try again in a moment.');
      }
      return response.bodyBytes;
    } on AiGenerationException {
      rethrow;
    } catch (_) {
      throw const AiGenerationException(
          'The AI took too long to answer. Check your connection and try again.');
    }
  }
}

/// A friendly, user-facing AI failure.
class AiGenerationException implements Exception {
  final String message;
  const AiGenerationException(this.message);

  @override
  String toString() => message;
}
