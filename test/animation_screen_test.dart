import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutapixel/screens/animation_screen.dart';
import 'package:mutapixel/theme/mutapixel_theme.dart';

Widget _studio() => MaterialApp(
      theme: MutapixelTheme.light(),
      darkTheme: MutapixelTheme.dark(),
      home: const AnimationScreen(),
    );

void main() {
  testWidgets('animation studio builds with preview and timeline',
      (tester) async {
    await tester.pumpWidget(_studio());
    await tester.pumpAndSettle();

    expect(find.text('Animation Studio'), findsOneWidget);
    expect(find.text('Timeline'), findsOneWidget);
    expect(find.text('Add frame'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Onion skin'), findsOneWidget);
    expect(find.text('F1'), findsOneWidget);
  });

  testWidgets('adding a frame appends it to the timeline',
      (tester) async {
    await tester.pumpWidget(_studio());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Add frame'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add frame'));
    await tester.pumpAndSettle();

    expect(find.text('F1'), findsOneWidget);
    expect(find.text('F2'), findsOneWidget);
  });

  testWidgets('edit button opens the pixel editor for the frame',
      (tester) async {
    await tester.pumpWidget(_studio());
    await tester.pumpAndSettle();

    final editButton =
        find.text('Edit frame 1 in pixel editor');
    await tester.ensureVisible(editButton);
    await tester.pumpAndSettle();
    await tester.tap(editButton);
    await tester.pumpAndSettle();

    // Pixel editor opened (canvas size locked, so no size popup).
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.byTooltip('Pencil'), findsOneWidget);
    expect(find.byTooltip('Canvas size'), findsNothing);
  });

  testWidgets('editing a frame and saving updates the timeline',
      (tester) async {
    await tester.pumpWidget(_studio());
    await tester.pumpAndSettle();

    final editButton =
        find.text('Edit frame 1 in pixel editor');
    await tester.ensureVisible(editButton);
    await tester.pumpAndSettle();
    await tester.tap(editButton);
    await tester.pumpAndSettle();

    // Go back without drawing: flattened frame returns.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Animation Studio'), findsOneWidget);
    expect(find.text('Frame 1 updated.'), findsOneWidget);
  });
}
