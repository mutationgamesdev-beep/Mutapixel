import 'package:flutter/material.dart';

import '../models/sprite_palette.dart';

Color _hex(String hex) {
  final cleaned = hex.replaceAll('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}

/// Built-in retro and starter palettes.
class PalettePresets {
  static final pico8 = SpritePalette(
    name: 'PICO-8',
    colors: [
      '000000', '1D2B53', '7E2553', '008751',
      'AB5236', '5F574F', 'C2C3C7', 'FFF1E8',
      'FF004D', 'FFA300', 'FFEC27', '00E436',
      '29ADFF', '83769C', 'FF77A8', 'FFCCAA',
    ].map(_hex).toList(),
  );

  static final gameBoy = SpritePalette(
    name: 'Game Boy',
    colors: ['0F380F', '306230', '8BAC0F', '9BBC0F'].map(_hex).toList(),
  );

  static final nes = SpritePalette(
    name: 'NES',
    colors: [
      '000000', 'FCFCFC', 'F8F8F8', 'BCBCBC',
      '7C7C7C', 'A4E4FC', '3CBCFC', '0078F8',
      '0000FC', 'B8B8F8', '6888FC', '0058F8',
      '0000BC', 'D8B8F8', '9878F8', '6844FC',
      '4000A0', 'F8B8F8', 'F878F8', 'D800CC',
      '940084', 'F8B8D8', 'F87858', 'E45C10',
      'AC7C00', '503000', 'F8D8B8', 'FCA044',
      'E4B004', '884400', 'F8F8B8', 'B8F818',
      '00B800', '007800', '00FC44', 'A4E400',
      '58D854', '008800', '00FCFC', '00E8D8',
      '008888', '004058',
    ].map(_hex).toList(),
  );

  static final mutationStarter = SpritePalette(
    name: 'Mutation Starter',
    colors: [
      '000000', 'FFFFFF', 'FF3B30', 'FF9500',
      'FFCC00', '34C759', '0A84FF', 'BF5AF2',
      '5AC8FA', 'FF6482', 'AC8E68', '8E8E93',
    ].map(_hex).toList(),
  );

  static List<SpritePalette> get all => [mutationStarter, pico8, gameBoy, nes];
}
