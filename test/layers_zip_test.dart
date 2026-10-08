import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mutapixel/models/art_layer.dart';
import 'package:mutapixel/models/sprite_frame.dart';
import 'package:mutapixel/services/sprite_exporter.dart';
import 'dart:typed_data';

List<ArtLayer> _twoLayers() {
  final bg = SpriteFrame(width: 4, height: 4);
  for (var y = 0; y < 4; y++) {
    for (var x = 0; x < 4; x++) {
      bg.setPixel(x, y, const Color(0xFFFF0000));
    }
  }
  final eyes = SpriteFrame(width: 4, height: 4);
  eyes.setPixel(1, 1, const Color(0xFF0000FF));
  eyes.setPixel(2, 1, const Color(0xFF0000FF));
  return [
    ArtLayer(name: 'Background', frame: bg),
    ArtLayer(name: 'Cool Eyes!', frame: eyes),
  ];
}

void main() {
  group('encodeLayersZip', () {
    test('contains one PNG per visible layer plus complete.png',
        () {
      final zipBytes =
          SpriteExporter.encodeLayersZip(_twoLayers(), scale: 1);
      final archive = ZipDecoder().decodeBytes(zipBytes);
      final names =
          archive.files.map((f) => f.name).toList();

      expect(
          names,
          unorderedEquals([
            '01_background.png',
            '02_cool_eyes.png',
            'complete.png',
          ]));
    });

    test('complete.png is the flattened composite', () {
      final zipBytes =
          SpriteExporter.encodeLayersZip(_twoLayers(), scale: 1);
      final archive = ZipDecoder().decodeBytes(zipBytes);
      final file =
          archive.files.firstWhere((f) => f.name == 'complete.png');
      final image = img.decodePng(Uint8List.fromList(file.content))!;

      expect(image.width, 4);
      expect(image.height, 4);
      // Background red shows through...
      final bg = image.getPixel(0, 0);
      expect(bg.r, 255);
      expect(bg.g, 0);
      // ...and the top layer's blue pixel lands on top.
      final eye = image.getPixel(1, 1);
      expect(eye.b, 255);
      expect(eye.r, 0);
    });

    test('layer PNGs are encoded at the requested scale', () {
      final zipBytes =
          SpriteExporter.encodeLayersZip(_twoLayers(), scale: 2);
      final archive = ZipDecoder().decodeBytes(zipBytes);
      final file = archive.files
          .firstWhere((f) => f.name == '01_background.png');
      final image = img.decodePng(Uint8List.fromList(file.content))!;
      expect(image.width, 8);
      expect(image.height, 8);
    });

    test('hidden layers are skipped', () {
      final layers = _twoLayers()
        ..add(ArtLayer(
            name: 'Hidden',
            frame: SpriteFrame(width: 4, height: 4),
            visible: false));
      final zipBytes =
          SpriteExporter.encodeLayersZip(layers, scale: 1);
      final archive = ZipDecoder().decodeBytes(zipBytes);
      final names =
          archive.files.map((f) => f.name).toList();

      expect(names, hasLength(3));
      expect(
          names.any((n) => n.contains('hidden')), isFalse);
      expect(names, contains('complete.png'));
    });

    test('works with a single layer (complete.png still present)',
        () {
      final zipBytes = SpriteExporter.encodeLayersZip(
          [_twoLayers().first],
          scale: 1);
      final archive = ZipDecoder().decodeBytes(zipBytes);
      final names =
          archive.files.map((f) => f.name).toList();
      expect(
          names,
          unorderedEquals(
              ['01_background.png', 'complete.png']));
    });
  });
}
