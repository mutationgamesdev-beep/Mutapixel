import 'package:flutter/material.dart';

/// A named set of colors the artist can pick from.
/// Palettes are just picking helpers: pixels store full [Color] values,
/// so art is never limited to 256 colors.
class SpritePalette {
  final String name;
  final List<Color> colors;

  const SpritePalette({required this.name, required this.colors});
}
