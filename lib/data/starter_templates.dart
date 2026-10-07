import 'package:flutter/material.dart';

import '../models/sprite_frame.dart';

/// A starter sprite defined as text rows, where each character maps to a
/// color ('.' is always transparent).
class StarterTemplate {
  final String name;
  final String kind; // 'character' or 'item'
  final List<String> rows;
  final Map<String, Color> colors;

  const StarterTemplate({
    required this.name,
    required this.kind,
    required this.rows,
    required this.colors,
  });

  SpriteFrame toFrame() {
    final height = rows.length;
    final width = rows.first.length;
    final frame = SpriteFrame(width: width, height: height);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final ch = rows[y][x];
        if (ch == '.') continue;
        frame.setPixel(x, y, colors[ch]);
      }
    }
    return frame;
  }
}

class StarterTemplates {
  static const slimeHero = StarterTemplate(
    name: 'Slime Hero',
    kind: 'character',
    rows: [
      '................',
      '................',
      '.....KKKKK......',
      '...KKGGGGGK.....',
      '..KGGGGGGGGK....',
      '.KGGWWGGWWGGK...',
      '.KGWKGGGGWKGK...',
      '.KGGGGGGGGGGK...',
      '.KGGGRGGGRGGK...',
      '..KGGGGGGGGK....',
      '..KGgGGGGgGK....',
      '...KKKKKKKK.....',
      '.....KKKK.......',
      '................',
      '................',
      '................',
    ],
    colors: {
      'K': Color(0xFF14141F),
      'G': Color(0xFF3DDC84),
      'g': Color(0xFF28A745),
      'W': Color(0xFFFFFFFF),
      'R': Color(0xFFFF6B6B),
    },
  );

  static const steelSword = StarterTemplate(
    name: 'Steel Sword',
    kind: 'item',
    rows: [
      '.......WW.......',
      '......WWWW......',
      '......WWWW......',
      '......WWWW......',
      '......WWWW......',
      '......WWWW......',
      '......WWWW......',
      '......WWWW......',
      '......WWWW......',
      '.....WWWWWW.....',
      '......YYYY......',
      '....YYYYYYYY....',
      '......YYYY......',
      '......KKKK......',
      '......KKKK......',
      '.....KKKKKK.....',
    ],
    colors: {
      'W': Color(0xFFDFE6F2),
      'Y': Color(0xFFF5B301),
      'K': Color(0xFF5A3A1E),
    },
  );

  static List<StarterTemplate> get all => [slimeHero, steelSword];
}
