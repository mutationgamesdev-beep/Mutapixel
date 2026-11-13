import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutapixel/main.dart';
import 'package:mutapixel/screens/editor_screen.dart';

/// Regression tests for the mobile layout: the landing page, the
/// app home and the editor must all lay out at a phone size
/// (390x844) without overflow exceptions, and the editor must
/// keep a usable canvas with the library panel closed/overlaid.
void main() {
  testWidgets('phone-size layouts do not overflow', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    // Landing page.
    await tester.pumpWidget(const SpriteBuilderApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Pixel art for\nyour next game.'), findsOneWidget);

    // App home (template grids go 2-up at this width).
    await tester.tap(find.text('Start Creating').first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Scroll the home page to force the animation grid to build.
    await tester.drag(
        find.byType(SingleChildScrollView).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('editor at phone size keeps canvas wide, panel overlays',
      (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
        const MaterialApp(home: EditorScreen(initialCanvasSize: 32)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Panel starts closed on phones: the open-panel button shows.
    expect(find.byTooltip('Show templates'), findsOneWidget);

    // Canvas card gets nearly the full width minus the tool rail.
    final canvasFinder = find.byWidgetPredicate(
        (w) => w is Container && w.key != null);
    expect(canvasFinder, findsWidgets);

    // Opening the library overlays it instead of crushing the canvas.
    await tester.tap(find.byTooltip('Show templates'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Library'), findsOneWidget);

    // Tapping the scrim (left side, over the canvas) closes it.
    await tester.tapAt(const Offset(40, 400));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Show templates'), findsOneWidget);
  });
}
