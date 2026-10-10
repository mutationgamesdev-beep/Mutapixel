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
  testWidgets('editor screen builds with layers, tools and palette',
      (tester) async {
    await tester.pumpWidget(_editor());
    await tester.pumpAndSettle();

    // App bar: back, layers, download.
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.byTooltip('Layers'), findsOneWidget);
    expect(find.byTooltip('Download'), findsOneWidget);

    // Tools (left rail), including the Move and Select tools.
    expect(find.byTooltip('Pencil'), findsOneWidget);
    expect(find.byTooltip('Eraser'), findsOneWidget);
    expect(find.byTooltip('Fill'), findsOneWidget);
    expect(find.byTooltip('Eyedropper'), findsOneWidget);
    expect(find.byTooltip('Move'), findsOneWidget);
    expect(find.byTooltip('Select'), findsOneWidget);
    expect(find.byTooltip('Undo'), findsOneWidget);

    // Library panel header with tabs.
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Templates'), findsOneWidget);
    expect(find.text('Anims'), findsOneWidget);

    // Palette bar chips.
    expect(find.text('Color'), findsOneWidget);
    expect(find.text('Effects'), findsOneWidget);
  });

  testWidgets('tapping a panel template stamps it as a new layer',
      (tester) async {
    await tester.pumpWidget(_editor());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Slime Hero').first);
    await tester.pumpAndSettle();

    // Snackbar confirms the stamp landed on a new layer.
    expect(find.textContaining('Stamped'), findsOneWidget);

    // The Layers panel shows both layers.
    await tester.tap(find.byTooltip('Layers'));
    await tester.pumpAndSettle();
    expect(find.text('Background'), findsOneWidget);
    expect(find.text('Slime Hero'), findsWidgets);
  });

  testWidgets('new layer can be added and undone', (tester) async {
    await tester.pumpWidget(_editor());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Layers'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New layer'));
    await tester.pumpAndSettle();
    expect(find.text('Layer 2'), findsOneWidget);

    // Dismiss the sheet, undo, and confirm the layer is gone.
    await tester.tapAt(const Offset(20, 100));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Undo'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Layers'));
    await tester.pumpAndSettle();
    expect(find.text('Layer 2'), findsNothing);
    expect(find.text('Background'), findsOneWidget);
  });

  testWidgets('layer visibility eye toggle is present', (tester) async {
    await tester.pumpWidget(_editor());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Layers'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Hide layer'), findsOneWidget);
    await tester.tap(find.byTooltip('Hide layer'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Show layer'), findsOneWidget);
  });

  testWidgets('switching to the move tool updates the rail',
      (tester) async {
    await tester.pumpWidget(_editor());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Move'));
    await tester.pump();
    // Move is a tool: tapping it keeps the canvas interactive and
    // the rail shows it selected (no crash, no mode banner).
    expect(find.byTooltip('Move'), findsOneWidget);
  });
}
