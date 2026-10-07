import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sprite_builder/data/starter_templates.dart';
import 'package:sprite_builder/services/sprite_exporter.dart';

/// Generates real export PNGs so the pipeline can be eyeballed.
/// Run with: flutter test test/sample_export_test.dart
/// Files land in /tmp/sprite_builder_samples/
void main() {
  test('generate sample export PNGs', () {
    final outDir = Directory('/tmp/sprite_builder_samples');
    outDir.createSync(recursive: true);

    // Single slime hero at 8x.
    final slime = StarterTemplates.slimeHero.toFrame();
    final slimePng = SpriteExporter.encodeFrame(slime, scale: 8);
    File('${outDir.path}/slime_hero_8x.png')
        .writeAsBytesSync(slimePng);

    // Sword at 8x.
    final sword = StarterTemplates.steelSword.toFrame();
    final swordPng = SpriteExporter.encodeFrame(sword, scale: 8);
    File('${outDir.path}/steel_sword_8x.png')
        .writeAsBytesSync(swordPng);

    // Two-frame walk cycle sheet (slime + slime shifted) at 4x.
    final frame2 = StarterTemplates.slimeHero.toFrame();
    final sheetPng = SpriteExporter.encodeSpriteSheet(
      [slime, frame2],
      scale: 4,
      columns: 2,
    );
    File('${outDir.path}/slime_sheet_4x.png')
        .writeAsBytesSync(sheetPng);

    expect(slimePng, isNotEmpty);
    expect(swordPng, isNotEmpty);
    expect(sheetPng, isNotEmpty);
  });
}
