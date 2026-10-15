import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mutapixel/services/openai_provider.dart';

void main() {
  group('OpenAiProvider', () {
    test('system prompt frames it as a pixel-art copilot', () {
      expect(OpenAiProvider.systemPrompt,
          contains('pixel art'));
      expect(OpenAiProvider.systemPrompt, contains('Mutapixel'));
    });

    test('exposes three tools the model can call', () {
      final names = [
        for (final t in OpenAiProvider.tools)
          (t['function'] as Map)['name'] as String,
      ];
      expect(
          names,
          containsAll([
            'generate_pixel_art',
            'generate_animation',
            'recreate_photo',
          ]));
    });

    test('chat body uses the chat model with tools on auto', () {
      final body = OpenAiProvider.chatBody([
        {'role': 'user', 'content': 'hi'},
      ]);
      expect(body['model'], OpenAiProvider.chatModel);
      expect(body['tool_choice'], 'auto');
      expect((body['tools'] as List), hasLength(3));
      expect((body['messages'] as List), hasLength(1));
    });

    test('tool call arguments survive a JSON round trip', () {
      final args = {'prompt': 'a fire knight'};
      final tc = ToolCall(
        id: 'call_1',
        name: 'generate_pixel_art',
        arguments: Map<String, dynamic>.from(
            jsonDecode(jsonEncode(args)) as Map),
      );
      expect(tc.arguments['prompt'], 'a fire knight');
    });

    test('AiApiException shows its friendly message', () {
      const e = AiApiException('That API key was rejected.');
      expect(e.toString(), 'That API key was rejected.');
    });
  });
}
