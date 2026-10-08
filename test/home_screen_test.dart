import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutapixel/main.dart';

void main() {
  testWidgets('home screen shows hero, cards, search and template library',
      (tester) async {
    await tester.pumpWidget(const SpriteBuilderApp());
    await tester.pumpAndSettle();

    expect(find.text('Mutapixel'), findsOneWidget);
    expect(find.text('Pixel Art'), findsOneWidget);
    expect(find.text('Animation'), findsOneWidget);
    expect(find.text('Guided builder'), findsOneWidget);
    expect(find.text('Search templates...'), findsOneWidget);
    expect(find.text('Start from a template'), findsOneWidget);
    // Category chips (first ones are visible without scrolling).
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Heroes'), findsOneWidget);
  });

  testWidgets('Pixel Art card opens the canvas size picker',
      (tester) async {
    await tester.pumpWidget(const SpriteBuilderApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pixel Art'));
    await tester.pumpAndSettle();

    expect(find.text('Canvas size'), findsOneWidget);
    expect(find.text('16 x 16 pixels'), findsOneWidget);
    expect(find.text('128 x 128 pixels'), findsOneWidget);
  });

  testWidgets('picking a size opens a blank editor', (tester) async {
    await tester.pumpWidget(const SpriteBuilderApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pixel Art'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('32 x 32 pixels'));
    await tester.pumpAndSettle();

    // Editor screen: back button + tools visible.
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.byTooltip('Pencil'), findsOneWidget);
  });

  testWidgets('Animation card opens the animation studio',
      (tester) async {
    await tester.pumpWidget(const SpriteBuilderApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Animation'));
    await tester.pumpAndSettle();

    expect(find.text('Animation Studio'), findsOneWidget);
    expect(find.text('Timeline'), findsOneWidget);
  });

  testWidgets('search filters templates and opens the editor',
      (tester) async {
    await tester.pumpWidget(const SpriteBuilderApp());
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byType(TextField), 'slime hero');
    await tester.pumpAndSettle();

    expect(find.text('Slime Hero'), findsOneWidget);
    await tester.ensureVisible(find.text('Slime Hero'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Slime Hero'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.text('Templates'), findsOneWidget);
  });
}
