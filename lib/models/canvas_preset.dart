import 'package:flutter/material.dart';

/// A named canvas size: the job first, the pixel count second.
///
/// Instead of handing creators raw numbers, the size pickers show
/// what each size is *for* — "Boss 256" beats "256 x 256" when
/// someone just wants to draw a boss.
@immutable
class CanvasPreset {
  /// Display name, e.g. 'Hero'.
  final String name;

  /// Square edge length in pixels.
  final int size;

  /// One-line guidance, e.g. 'Heroes & portraits'.
  final String blurb;

  const CanvasPreset({
    required this.name,
    required this.size,
    required this.blurb,
  });

  String get label => '$size × $size';
}

/// The standard ladder, from tiny tiles to showcase bosses.
const canvasPresets = <CanvasPreset>[
  CanvasPreset(
      name: 'Minion', size: 16, blurb: 'Tiles, icons & tiny sprites'),
  CanvasPreset(
      name: 'Sprite', size: 32, blurb: 'Classic game characters'),
  CanvasPreset(
      name: 'Character', size: 64, blurb: 'Detailed game characters'),
  CanvasPreset(name: 'Hero', size: 128, blurb: 'Heroes & portraits'),
  CanvasPreset(name: 'Boss', size: 192, blurb: 'Big enemies & bosses'),
  CanvasPreset(
      name: 'Titan', size: 256, blurb: 'Showcase bosses & scenes'),
];

/// Bounds for user-typed custom sizes (square, pixels).
const minCustomCanvasSize = 8;
const maxCustomCanvasSize = 512;

/// Parses a custom canvas size, or returns null with [error] set
/// when the input is not a usable size.
int? parseCustomCanvasSize(String input, {StringBuffer? error}) {
  final value = int.tryParse(input.trim());
  if (value == null) {
    error?.write('Enter a whole number.');
    return null;
  }
  if (value < minCustomCanvasSize || value > maxCustomCanvasSize) {
    error?.write(
        'Pick a size between $minCustomCanvasSize and $maxCustomCanvasSize.');
    return null;
  }
  return value;
}
