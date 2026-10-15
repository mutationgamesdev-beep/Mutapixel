import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutapixel/screens/ai_chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
      'gate Add API key button opens the settings sheet',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(home: AiChatScreen()),
    );
    await tester.pumpAndSettle();

    // Key gate is showing (no key stored).
    expect(find.text('Connect your AI key'), findsOneWidget);

    // Tap the gate's Add API key button.
    await tester.tap(find.text('Add API key'));
    await tester.pumpAndSettle();

    // The settings bottom sheet opens with the guide.
    expect(find.text('AI API key'), findsOneWidget);
    expect(find.textContaining('platform.openai.com'),
        findsOneWidget);
  });
}
