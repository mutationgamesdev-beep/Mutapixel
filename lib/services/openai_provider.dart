import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Talks to OpenAI with the user's own API key: real conversation,
/// pixel-art image generation, and photo edits.
///
/// One key covers everything: chat runs on a cheap chat model, images on
/// the cheap image model (about half a cent per image at low quality).
class OpenAiProvider {
  final String apiKey;

  OpenAiProvider(this.apiKey);

  static const _base = 'https://api.openai.com/v1';
  static const chatModel = 'gpt-4o-mini';
  static const imageModel = 'gpt-image-1-mini';

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      };

  static const systemPrompt = '''
You are the Mutapixel AI Lab assistant, a creative copilot for making pixel art and animations for video games.

RULES:
- Chat naturally and briefly, like a helpful creative partner. Keep replies to 1-3 short sentences unless the user asks for more.
- When the user wants a NEW image (words like draw, make, create, generate + a thing), call generate_pixel_art with a rich prompt describing the subject as pixel art.
- When the user wants an ANIMATION (words like animate, walk cycle, moving, animation), call generate_animation with a rich prompt describing the character and motion.
- When the user uploaded a photo and wants it recreated/edited as pixel art, call recreate_photo with a prompt describing the transformation.
- If the request is vague, ask ONE short clarifying question instead of guessing.
- Never claim you did something you didn't. If a tool fails, say so plainly and suggest a fix.
- Do not repeat the image prompt back verbatim; just describe what you made in your own words.
''';

  /// Tools the chat model may call. Pure data so tests can inspect it.
  static List<Map<String, dynamic>> get tools => [
        {
          'type': 'function',
          'function': {
            'name': 'generate_pixel_art',
            'description':
                'Generate a new pixel-art image from a text description. Use when the user asks for a sprite, character, item, background, or any new artwork.',
            'parameters': {
              'type': 'object',
              'properties': {
                'prompt': {
                  'type': 'string',
                  'description':
                      'Rich description of the artwork, e.g. "a fire knight with a flaming sword, 32-bit pixel art style"',
                },
              },
              'required': ['prompt'],
            },
          },
        },
        {
          'type': 'function',
          'function': {
            'name': 'generate_animation',
            'description':
                'Generate a 4-frame pixel-art animation (walk cycle / motion) from a text description. Use when the user asks for an animation or moving character.',
            'parameters': {
              'type': 'object',
              'properties': {
                'prompt': {
                  'type': 'string',
                  'description':
                      'Rich description of the character and motion, e.g. "a cute slime bouncing, idle animation"',
                },
              },
              'required': ['prompt'],
            },
          },
        },
        {
          'type': 'function',
          'function': {
            'name': 'recreate_photo',
            'description':
                'Recreate the user\'s uploaded photo as pixel art. Only use when the user has uploaded a photo in this conversation.',
            'parameters': {
              'type': 'object',
              'properties': {
                'prompt': {
                  'type': 'string',
                  'description':
                      'Description of the transformation, e.g. "recreate as 32-bit pixel art game sprite, same pose and colors"',
                },
              },
              'required': ['prompt'],
            },
          },
        },
      ];

  /// Builds the chat request body. Pure function for tests.
  static Map<String, dynamic> chatBody(
      List<Map<String, dynamic>> messages) {
    return {
      'model': chatModel,
      'messages': messages,
      'tools': tools,
      'tool_choice': 'auto',
      'max_tokens': 500,
    };
  }

  /// One conversational turn. Returns text and any tool calls.
  Future<ChatTurn> chat(
      List<Map<String, dynamic>> messages) async {
    final response = await http
        .post(
          Uri.parse('$_base/chat/completions'),
          headers: _headers,
          body: jsonEncode(chatBody(messages)),
        )
        .timeout(const Duration(seconds: 60));
    final data = _checked(response);
    final message =
        (data['choices'] as List).first['message']
            as Map<String, dynamic>;
    final toolCalls = <ToolCall>[];
    for (final tc in (message['tool_calls'] as List?) ?? []) {
      final fn = tc['function'] as Map<String, dynamic>;
      toolCalls.add(ToolCall(
        id: tc['id'] as String,
        name: fn['name'] as String,
        arguments: jsonDecode(fn['arguments'] as String)
            as Map<String, dynamic>,
      ));
    }
    return ChatTurn(
      text: message['content'] as String?,
      toolCalls: toolCalls,
    );
  }

  /// Generates one image. Returns raw bytes (b64 from the API).
  Future<Uint8List> generateImage(String prompt) async {
    final response = await http
        .post(
          Uri.parse('$_base/images/generations'),
          headers: _headers,
          body: jsonEncode({
            'model': imageModel,
            'prompt': _artPrompt(prompt),
            'size': '1024x1024',
            'quality': 'low',
            'n': 1,
            'response_format': 'b64_json',
          }),
        )
        .timeout(const Duration(minutes: 3));
    final data = _checked(response);
    final b64 =
        (data['data'] as List).first['b64_json'] as String;
    return base64Decode(b64);
  }

  /// Generates a 2x2 sprite sheet for animation. Returns raw bytes.
  Future<Uint8List> generateAnimationSheet(String prompt) {
    return generateImage(_sheetPrompt(prompt));
  }

  /// Recreates the user's photo as pixel art. Returns raw bytes.
  Future<Uint8List> editPhoto(
      Uint8List photoBytes, String prompt) async {
    final request = http.MultipartRequest(
        'POST', Uri.parse('$_base/images/edits'))
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..fields['model'] = imageModel
      ..fields['prompt'] = _photoPrompt(prompt)
      ..fields['size'] = '1024x1024'
      ..fields['quality'] = 'low'
      ..files.add(http.MultipartFile.fromBytes(
          'image[]', photoBytes,
          filename: 'photo.png'));
    final streamed = await request
        .send()
        .timeout(const Duration(minutes: 4));
    final response =
        await http.Response.fromStream(streamed);
    final data = _checked(response);
    final b64 =
        (data['data'] as List).first['b64_json'] as String;
    return base64Decode(b64);
  }

  static String _artPrompt(String user) =>
      'pixel art game sprite of ${user.trim()}, 32-bit style, limited '
      'color palette, clean readable silhouette, centered, solid dark '
      'background, game asset, no text, no watermark';

  static String _sheetPrompt(String user) =>
      'pixel art sprite sheet, 2x2 grid of 4 animation frames of '
      '${user.trim()}, walk cycle, the exact same character with '
      'identical design and colors in every frame, 32-bit pixel art '
      'style, limited color palette, solid dark background, small gaps '
      'between frames, no text, no watermark';

  static String _photoPrompt(String user) =>
      'recreate this photo as a clean 32-bit pixel art game sprite, '
      '${user.trim()}, keep the same subject, pose and colors, limited '
      'color palette, clean readable silhouette, solid dark background, '
      'no text, no watermark';

  /// Throws [AiApiException] with a user-friendly message on error.
  Map<String, dynamic> _checked(http.Response response) {
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    String detail = '';
    try {
      final data =
          jsonDecode(response.body) as Map<String, dynamic>;
      detail = (data['error'] as Map<String, dynamic>?)?['message']
              as String? ??
          '';
    } catch (_) {}
    switch (response.statusCode) {
      case 401:
        throw AiApiException(
            'That API key was rejected. Double-check it in AI Lab settings — it should start with "sk-".',
            detail);
      case 429:
        throw const AiApiException(
            'The AI is rate-limited right now. Wait a minute and try again.');
      case 402:
        throw const AiApiException(
            'This key is out of credit. Add a few dollars at platform.openai.com and try again.');
      default:
        throw AiApiException(
            'The AI service returned an error (${response.statusCode}). Try again in a moment.',
            detail);
    }
  }
}

/// One parsed chat turn: reply text plus any tool calls the model made.
class ChatTurn {
  final String? text;
  final List<ToolCall> toolCalls;

  const ChatTurn({this.text, required this.toolCalls});
}

/// A single tool call requested by the chat model.
class ToolCall {
  final String id;
  final String name;
  final Map<String, dynamic> arguments;

  const ToolCall(
      {required this.id,
      required this.name,
      required this.arguments});
}

/// A friendly, user-facing AI failure.
class AiApiException implements Exception {
  final String message;
  final String detail;

  const AiApiException(this.message, [this.detail = '']);

  @override
  String toString() => message;
}
