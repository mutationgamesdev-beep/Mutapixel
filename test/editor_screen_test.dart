import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutapixel/screens/editor_screen.dart';
import 'package:mutapixel/theme/mutapixel_theme.dart';

Widget _editor() => MaterialApp(
      theme: MutapixelTheme.light(),
      darkTheme: MutapixelTheme.dark(),
      home: const EditorScreen(),
    );

void main() {
  testWidgets('editor screen builds with canvas, tools and palette',
      (tester) async {
    await tester.pumpWidget(_editor());
    await tester.pumpAndSettle();

    // App bar and title, plus home back button.
    expect(find.text('Mutapixel'), findsOneWidget);
    expect(find.byTooltip('Home'), findsOneWidget);

    // Tools (left rail).
    expect(find.byTooltip('Pencil'), findsOneWidget);
    expect(find.byTooltip('Eraser'), findsOneWidget);
    expect(find.byTooltip('Fill'), findsOneWidget);
    expect(find.byTooltip('Mirror (symmetry)'), findsOneWidget);
    expect(find.byTooltip('Undo'), findsOneWidget);

    // Templates panel toggle.
    expect(find.byTooltip('Templates'), findsOneWidget);

    // Palette switcher and custom color button.
    expect(find.text('Mutation Starter'), findsOneWidget);
    expect(find.text('Custom'), findsOneWidget);

    // Export action.
    expect(find.byTooltip('Export'), findsOneWidget);
  });

  testWidgets('toggling the templates panel shows search and cards',
      (tester) async {
    await tester.pumpWidget(_editor());
    await tester.pumpAndSettle();

    // Panel starts collapsed: no search field yet.
    expect(find.text('Search templates...'), findsNothing);

    await tester.tap(find.byTooltip('Templates'));
    await tester.pumpAndSettle();

    expect(find.text('Search templates...'), findsOneWidget);
    expect(find.text('Slime Hero'), findsWidgets);
  });

  testWidgets('tapping a panel template stamps it on the canvas',
      (tester) async {
    await tester.pumpWidget(_editor());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Templates'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Slime Hero').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('Stamped'), findsOneWidget);
  });

  testWidgets('switching tools updates selection', (tester) async {
    await tester.pumpWidget(_editor());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Eraser'));
    await tester.pump();
    // Tapping a palette color switches back to pencil.
    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();
    expect(find.text('Custom color'), findsOneWidget);
  });
}
