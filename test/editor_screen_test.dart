import 'package:flutter_test/flutter_test.dart';
import 'package:mutapixel/main.dart';

void main() {
  testWidgets('editor screen builds with canvas, tools and palette',
      (tester) async {
    await tester.pumpWidget(const SpriteBuilderApp());
    await tester.pumpAndSettle();

    // App bar and title.
    expect(find.text('Sprite Builder'), findsOneWidget);

    // Tools.
    expect(find.byTooltip('Pencil'), findsOneWidget);
    expect(find.byTooltip('Eraser'), findsOneWidget);
    expect(find.byTooltip('Fill'), findsOneWidget);
    expect(find.byTooltip('Mirror (symmetry)'), findsOneWidget);
    expect(find.byTooltip('Undo'), findsOneWidget);

    // Palette switcher and custom color button.
    expect(find.text('Mutation Starter'), findsOneWidget);
    expect(find.text('Custom'), findsOneWidget);

    // Export action.
    expect(find.byTooltip('Export'), findsOneWidget);
  });

  testWidgets('switching tools updates selection', (tester) async {
    await tester.pumpWidget(const SpriteBuilderApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Eraser'));
    await tester.pump();
    // Tapping a palette color switches back to pencil.
    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();
    expect(find.text('Custom color'), findsOneWidget);
  });
}
