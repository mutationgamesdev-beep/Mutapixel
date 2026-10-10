import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutapixel/widgets/photoshop_color_picker.dart';

Future<void> pumpPicker(WidgetTester tester, Color initial) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () {
            showPhotoshopColorPicker(
              context: context,
              initialColor: initial,
            );
          },
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Color swatchColor(WidgetTester tester, Key key) {
  final container = tester.widget<Container>(find.byKey(key));
  final decoration = container.decoration as BoxDecoration;
  return decoration.color!;
}

/// Color equality by value (a MaterialColor and a plain Color with the
/// same ARGB are not `==` in this Flutter version).
void expectSameColor(Color actual, Color expected) {
  expect(actual.toARGB32(), expected.toARGB32());
}

void main() {
  testWidgets('current and new swatches start at the initial color',
      (tester) async {
    await pumpPicker(tester, Colors.red);
    expect(find.text('current'), findsOneWidget);
    expect(find.text('new'), findsOneWidget);
    expectSameColor(swatchColor(tester, const Key('ps-current-swatch')), Colors.red);
    expectSameColor(swatchColor(tester, const Key('ps-new-swatch')), Colors.red);
  });

  testWidgets('dragging the SV field changes new but not current',
      (tester) async {
    await pumpPicker(tester, Colors.red);
    // Drag toward the top-left: lower saturation, full brightness.
    await tester.drag(
        find.byKey(const Key('ps-sv-area')), const Offset(-120, -80));
    await tester.pump();
    final updated = swatchColor(tester, const Key('ps-new-swatch'));
    expect(updated, isNot(Colors.red));
    expectSameColor(swatchColor(tester, const Key('ps-current-swatch')), Colors.red);
  });

  testWidgets('dragging the hue slider changes the new color', (tester) async {
    await pumpPicker(tester, Colors.red);
    await tester.drag(
        find.byKey(const Key('ps-hue-slider')), const Offset(0, 60));
    await tester.pump();
    expect(swatchColor(tester, const Key('ps-new-swatch')), isNot(Colors.red));
    expectSameColor(swatchColor(tester, const Key('ps-current-swatch')), Colors.red);
  });

  testWidgets('cancel returns null', (tester) async {
    Color? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showPhotoshopColorPicker(
                context: context,
                initialColor: Colors.red,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('use color returns the adjusted color', (tester) async {
    Color? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showPhotoshopColorPicker(
                context: context,
                initialColor: Colors.red,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.drag(
        find.byKey(const Key('ps-hue-slider')), const Offset(0, 100));
    await tester.pump();
    final expected = swatchColor(tester, const Key('ps-new-swatch'));
    await tester.tap(find.text('Use color'));
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    expect(result, isNot(Colors.red));
    expect(result, expected);
  });

  testWidgets('hex field updates the new color', (tester) async {
    await pumpPicker(tester, Colors.red);
    await tester.enterText(find.byKey(const Key('ps-hex-field')), '#00FF00');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    final updated = swatchColor(tester, const Key('ps-new-swatch'));
    expect(updated.r, closeTo(0, 0.02));
    expect(updated.g, closeTo(1, 0.02));
    expect(updated.b, closeTo(0, 0.02));
    expectSameColor(swatchColor(tester, const Key('ps-current-swatch')), Colors.red);
  });
}
