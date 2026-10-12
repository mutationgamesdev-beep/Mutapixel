import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;

import '../models/art_layer.dart';
import '../models/sprite_frame.dart';

/// Turns sprite frames into PNG bytes.
///
/// Quality rules (locked in with MutationGames Dev):
/// - Always lossless PNG, never JPEG.
/// - Real transparency: empty pixels stay transparent.
/// - Integer scaling only (1x, 2x, 4x, 8x) with nearest-neighbor sampling,
///   so pixels stay crisp and never blur.
/// - Full color: no 256-color limit.
class SpriteExporter {
  /// Encodes one frame as a lossless PNG at [scale]x size.
  static Uint8List encodeFrame(SpriteFrame frame, {int scale = 1}) {
    assert(scale >= 1, 'scale must be at least 1');
    final outW = frame.width * scale;
    final outH = frame.height * scale;
    final image = img.Image(width: outW, height: outH, numChannels: 4);

    for (var y = 0; y < frame.height; y++) {
      for (var x = 0; x < frame.width; x++) {
        final color = frame.getPixel(x, y);
        final pixel = color == null
            ? img.ColorRgba8(0, 0, 0, 0)
            : img.ColorRgba8(
                (color.r * 255).round(),
                (color.g * 255).round(),
                (color.b * 255).round(),
                (color.a * 255).round(),
              );
        // Integer scale: stamp the pixel as a solid scale x scale block.
        for (var dy = 0; dy < scale; dy++) {
          for (var dx = 0; dx < scale; dx++) {
            image.setPixel(x * scale + dx, y * scale + dy, pixel);
          }
        }
      }
    }
    return Uint8List.fromList(img.encodePng(image));
  }

  /// Packs [frames] into one sprite-sheet PNG.
  ///
  /// A [gutter] of transparent pixels separates frames so a game engine's
  /// linear filtering never smears one frame's edge into the next.
  /// [columns] controls how many frames sit in each row.
  static Uint8List encodeSpriteSheet(
    List<SpriteFrame> frames, {
    int scale = 1,
    int columns = 4,
    int gutter = 2,
  }) {
    assert(frames.isNotEmpty, 'need at least one frame');
    assert(scale >= 1, 'scale must be at least 1');

    final frameW = frames.first.width * scale;
    final frameH = frames.first.height * scale;
    final cols = columns < frames.length ? columns : frames.length;
    final rows = (frames.length / cols).ceil();

    final outW = cols * frameW + (cols + 1) * gutter;
    final outH = rows * frameH + (rows + 1) * gutter;
    final sheet = img.Image(width: outW, height: outH, numChannels: 4);

    for (var i = 0; i < frames.length; i++) {
      final frame = frames[i];
      final col = i % cols;
      final row = i ~/ cols;
      final ox = gutter + col * (frameW + gutter);
      final oy = gutter + row * (frameH + gutter);

      for (var y = 0; y < frame.height; y++) {
        for (var x = 0; x < frame.width; x++) {
          final color = frame.getPixel(x, y);
          final pixel = color == null
              ? img.ColorRgba8(0, 0, 0, 0)
              : img.ColorRgba8(
                  (color.r * 255).round(),
                  (color.g * 255).round(),
                  (color.b * 255).round(),
                  (color.a * 255).round(),
                );
          for (var dy = 0; dy < scale; dy++) {
            for (var dx = 0; dx < scale; dx++) {
              sheet.setPixel(ox + x * scale + dx, oy + y * scale + dy, pixel);
            }
          }
        }
      }
    }
    return Uint8List.fromList(img.encodePng(sheet));
  }

  /// Game-ready export: a ZIP with `sheet.png` (frames in one
  /// horizontal strip at native size, 2px transparent gutter) and
  /// `sheet.json` (frame rects, per-frame durations, and engine
  /// import notes for Unity, Godot, and Unreal).
  ///
  /// [frameDurations] gives each frame's display time in
  /// milliseconds; when null, every frame uses `1000 / fps` ms.
  static Uint8List encodeSpriteSheetZip(
    List<SpriteFrame> frames, {
    required String name,
    List<int>? frameDurations,
    int fps = 8,
  }) {
    assert(frames.isNotEmpty, 'need at least one frame');
    assert(frameDurations == null ||
        frameDurations.length == frames.length);
    final safeName = ArtLayer.sanitizeName(name);
    const gutter = 2;
    final frameW = frames.first.width;
    final frameH = frames.first.height;

    // sheet.png: horizontal strip at native size.
    final outW = frames.length * frameW + (frames.length + 1) * gutter;
    final outH = frameH + gutter * 2;
    final sheet = img.Image(width: outW, height: outH, numChannels: 4);
    for (var i = 0; i < frames.length; i++) {
      final frame = frames[i];
      final ox = gutter + i * (frameW + gutter);
      for (var y = 0; y < frame.height; y++) {
        for (var x = 0; x < frame.width; x++) {
          final color = frame.getPixel(x, y);
          sheet.setPixel(
            ox + x,
            gutter + y,
            color == null
                ? img.ColorRgba8(0, 0, 0, 0)
                : img.ColorRgba8(
                    (color.r * 255).round(),
                    (color.g * 255).round(),
                    (color.b * 255).round(),
                    (color.a * 255).round(),
                  ),
          );
        }
      }
    }
    final png = Uint8List.fromList(img.encodePng(sheet));

    // sheet.json: metadata for game engines.
    final defaultMs = (1000 / fps).round();
    final frameEntries = [
      for (var i = 0; i < frames.length; i++)
        {
          'index': i,
          'x': gutter + i * (frameW + gutter),
          'y': gutter,
          'w': frameW,
          'h': frameH,
          'durationMs': frameDurations?[i] ?? defaultMs,
        },
    ];
    final jsonMap = {
      'meta': {
        'app': 'Mutapixel',
        'name': name,
        'frameSize': {'w': frameW, 'h': frameH},
        'frameCount': frames.length,
      },
      'frames': frameEntries,
      'animations': {
        name: {
          'frames': [for (var i = 0; i < frames.length; i++) i],
          'fps': fps,
          'loop': true,
        },
      },
      'engines': {
        'unity':
            'Import PNG as Sprite (Multiple), slice ${frameW}x$frameH grid; apply per-frame durations to the clip.',
        'godot':
            'Use as AnimatedSprite2D SpriteFrames; set each frame duration from JSON.',
        'unreal':
            'Import as Paper2D flipbook; match frame order and durations.',
      },
    };
    final jsonBytes =
        Uint8List.fromList(utf8.encode(jsonEncode(jsonMap)));

    final archive = Archive();
    archive.addFile(ArchiveFile('sheet.png', png.length, png));
    archive.addFile(ArchiveFile(
        '${safeName}_sheet.json', jsonBytes.length, jsonBytes));
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  /// Packs every VISIBLE layer into a ZIP: one PNG per layer
  /// (`01_background.png`, `02_eyes.png`, ... in bottom-to-top
  /// order) plus `complete.png` (the flattened composite).
  /// Hidden layers are skipped; empty ZIPs can't happen because
  /// callers only offer this when more than one layer exists.
  static Uint8List encodeLayersZip(
    List<ArtLayer> layers, {
    int scale = 1,
  }) {
    assert(layers.isNotEmpty, 'need at least one layer');
    assert(scale >= 1, 'scale must be at least 1');
    final archive = Archive();
    final visible = layers.where((l) => l.visible).toList();
    for (var i = 0; i < visible.length; i++) {
      final name =
          '${(i + 1).toString().padLeft(2, '0')}_${ArtLayer.sanitizeName(visible[i].name)}.png';
      final png = encodeFrame(visible[i].frame, scale: scale);
      archive.addFile(ArchiveFile(name, png.length, png));
    }
    final complete = encodeFrame(ArtLayer.flatten(layers), scale: scale);
    archive.addFile(
        ArchiveFile('complete.png', complete.length, complete));
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }
}
