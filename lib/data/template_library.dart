import 'package:flutter/material.dart';

import '../models/sprite_frame.dart';
import 'templates_detailed.dart';
import 'templates_extra.dart';
import 'templates_faces.dart';
import 'templates_food.dart';
import 'templates_nature.dart';
import 'templates_space.dart';

/// A hand-designed sprite template, defined as text rows where each
/// character maps to a color ('.' is always transparent).
class ArtTemplate {
  final String name;
  final String category; // 'heroes', 'monsters', 'animals', 'items'
  final List<String> rows;
  final Map<String, Color> colors;

  const ArtTemplate({
    required this.name,
    required this.category,
    required this.rows,
    required this.colors,
  });

  SpriteFrame toFrame() {
    final frame = SpriteFrame(width: rows.first.length, height: rows.length);
    for (var y = 0; y < rows.length; y++) {
      for (var x = 0; x < rows[y].length; x++) {
        final ch = rows[y][x];
        if (ch == '.') continue;
        frame.setPixel(x, y, colors[ch]);
      }
    }
    return frame;
  }
}

class TemplateLibrary {
  // ---------------------------------------------------------------- heroes
  static const slimeHero = ArtTemplate(
    name: 'Slime Hero',
    category: 'heroes',
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

  static const knight = ArtTemplate(
    name: 'Knight',
    category: 'heroes',
    rows: [
      '......PP........',
      '.....PPPP....W..',
      '.....PPPP....W..',
      '....KKKKKK...W..',
      '....KSSSSK...W..',
      '....KSSSSK...W..',
      '....KDDDDK...W..',
      '....KSSSSK...W..',
      '.....KKKK....W..',
      '..KKKKKKKKKK.W..',
      '..KSSSEESSSK.W..',
      '..KSSSSSSSSKEEE.',
      '..KSSSSSSSSK.D..',
      '..KKKKKKKKKK.D..',
      '....KK..KK...E..',
      '...KKK..KKK.....',
    ],
    colors: {
      'K': Color(0xFF14141F),
      'S': Color(0xFFC7D0DD),
      'D': Color(0xFF8A99AD),
      'P': Color(0xFFE63946),
      'E': Color(0xFFF5B301),
      'W': Color(0xFFDFE6F2),
    },
  );

  static const wizard = ArtTemplate(
    name: 'Wizard',
    category: 'heroes',
    rows: [
      '.......H........',
      '......HKH.......',
      '......HKH.......',
      '.....HKHKH......',
      '.....HHEHH......',
      '....KHHHHHK.....',
      '..KKKKKKKKKKKK..',
      '......SSSS......',
      '......SKKS......',
      '....KRRBBRRK....',
      '....KRBBBBRK....',
      '....KRBBBBRK....',
      '....KRRBBRRK....',
      '....KRRRRRRK....',
      '....KRRRRRRK....',
      '.....KKKKKK.....',
    ],
    colors: {
      'K': Color(0xFF14141F),
      'H': Color(0xFF5B7FE8),
      'E': Color(0xFFF5B301),
      'S': Color(0xFFF2C89B),
      'R': Color(0xFF3B4A9E),
      'B': Color(0xFFF0F0F0),
    },
  );

  static const ninja = ArtTemplate(
    name: 'Ninja',
    category: 'heroes',
    rows: [
      '................',
      '................',
      '.....KKKKKK.....',
      '...KKHHHHHHKK...',
      '..HHKNNNNNNK....',
      '..HHKNNWWNNK....',
      '.....KNNNNK.....',
      '.....KNNNNK.....',
      '...KKNNNNNNKK...',
      '..KNNKNNNNKNNK..',
      '..KNKNNNNNNKNK..',
      '..KNKNNHHNNKNK..',
      '..KNNNNNNNNNNK..',
      '...KNNNNNNNNK...',
      '...KKK....KKK...',
      '................',
    ],
    colors: {
      'K': Color(0xFF14141F),
      'H': Color(0xFFE63946),
      'N': Color(0xFF2E2E42),
      'W': Color(0xFFFFFFFF),
    },
  );

  // --------------------------------------------------------------- monsters
  static const goblin = ArtTemplate(
    name: 'Goblin',
    category: 'monsters',
    rows: [
      '................',
      '................',
      '.....KKKKKK.....',
      '...KKGGGGGGKK...',
      '.KKGGGGGGGGGGKK.',
      '.KGGKWWKKWWKGGK.',
      '.KGGKWWKKWWKGGK.',
      '..KKGGGGGGGGKK..',
      '....KMMMMMMK....',
      '....KMWMMWMK....',
      '.....KKKKKK.....',
      '...KKGGGGGGKK...',
      '..KGGGGGGGGGGK..',
      '..KGGKGGGGKGGK..',
      '...KKKKKKKKKK...',
      '................',
    ],
    colors: {
      'K': Color(0xFF14141F),
      'G': Color(0xFF7BC950),
      'W': Color(0xFFFFFFFF),
      'M': Color(0xFF5A1F1F),
    },
  );

  static const bat = ArtTemplate(
    name: 'Bat',
    category: 'monsters',
    rows: [
      '................',
      '................',
      '................',
      '......K..K......',
      'KK....KBBK....KK',
      '.KBBBKBBBBKBBBK.',
      '.KBBBBBEEBBBBBK.',
      '..KBBBBBBBBBBK..',
      '..KBBKBBBBKBBK..',
      '...KBKBBBBKBK...',
      '...KBBKBBKBBK...',
      '....KBBBBBBK....',
      '....KBBBBBBK....',
      '.....KKKKKK.....',
      '................',
      '................',
    ],
    colors: {
      'K': Color(0xFF14141F),
      'B': Color(0xFF6B4E9E),
      'E': Color(0xFFFF3B3B),
    },
  );

  static const ghost = ArtTemplate(
    name: 'Ghost',
    category: 'monsters',
    rows: [
      '................',
      '.....KKKKKK.....',
      '...KKWWWWWWKK...',
      '..KWWWWWWWWWWK..',
      '..KWWWWWWWWWWK..',
      '..KWWKKWWKKWWK..',
      '..KWWKKWWKKWWK..',
      '..KWWWWWWWWWWK..',
      '..KWWWKKKKWWWK..',
      '..KWWWKMMKWWWK..',
      '..KWWWWWWWWWWK..',
      '..KWWWWWWWWWWK..',
      '..KWKWKWKWKWKWK.',
      '................',
      '................',
      '................',
    ],
    colors: {
      'K': Color(0xFF14141F),
      'W': Color(0xFFF2F2F2),
      'M': Color(0xFF3A3A4A),
    },
  );

  static const mushroom = ArtTemplate(
    name: 'Mushroom',
    category: 'monsters',
    rows: [
      '................',
      '................',
      '.....KKKKKK.....',
      '...KKRRRRRRKK...',
      '..KRRWWRRWWRRK..',
      '.KRRRWWRRWWRRRK.',
      '.KRRRRRRRRRRRRK.',
      '..KKKKKKKKKKKK..',
      '....KSSSSSSK....',
      '....KSSKKSSK....',
      '....KSSSSSSK....',
      '....KSSSSSSK....',
      '.....KKKKKK.....',
      '................',
      '................',
      '................',
    ],
    colors: {
      'K': Color(0xFF14141F),
      'R': Color(0xFFE63946),
      'W': Color(0xFFFFFFFF),
      'S': Color(0xFFF5E6C8),
    },
  );

  // ---------------------------------------------------------------- animals
  static const cat = ArtTemplate(
    name: 'Cat',
    category: 'animals',
    rows: [
      '................',
      '....K......K....',
      '...KOK....KOK...',
      '...KOOOOOOOOK...',
      '...KOOOOOOOOK...',
      '...KOOGGOOGOK...',
      '...KOOGGOOGOK...',
      'WW..KOONNOOK..WW',
      '....KOOWWOOK....',
      '.....KOOOOK.....',
      '...KKOOOOOOKK...',
      '..KOOOOOOOOOOK..',
      '..KOOOOOOOOOOK..',
      '..KKKOOOOOOKKK..',
      '...KKKKKKKKKK...',
      '................',
    ],
    colors: {
      'K': Color(0xFF14141F),
      'O': Color(0xFFF5A524),
      'G': Color(0xFF3DDC84),
      'N': Color(0xFFFF8FA3),
      'W': Color(0xFFFFFFFF),
    },
  );

  static const bird = ArtTemplate(
    name: 'Bird',
    category: 'animals',
    rows: [
      '................',
      '................',
      '................',
      '................',
      '......KKKK......',
      '....KKBBBBKK....',
      '...KBBBKBBKYY...',
      '...KBBBBBBKYYY..',
      '..KBBBWBBBKYY...',
      '.KTTKBBWBBBK....',
      '.KTTKBBWBBBK....',
      '..KTTKBBBBBK....',
      '...KBBBBBBK.....',
      '....KKK.KKK.....',
      '....KKK.KKK.....',
      '................',
    ],
    colors: {
      'K': Color(0xFF14141F),
      'B': Color(0xFF5B9CF5),
      'Y': Color(0xFFF5B301),
      'W': Color(0xFF3B7DE0),
      'T': Color(0xFF2E5FA3),
    },
  );

  static const frog = ArtTemplate(
    name: 'Frog',
    category: 'animals',
    rows: [
      '................',
      '...KK....KK.....',
      '..KWWK..KWWK....',
      '..KWKK..KWKK....',
      '..KWWKKKKWWK....',
      '...KGGGGGGK.....',
      '..KGGGGGGGGK....',
      '..KGGGGGGGGK....',
      '..KGMMMMMMGK....',
      '..KGGGGGGGGK....',
      '...KGGGGGGK.....',
      '..KKKGGGGKKK....',
      '..KGGKGGKGGK....',
      '...KKKKKKKK.....',
      '................',
      '................',
    ],
    colors: {
      'K': Color(0xFF14141F),
      'G': Color(0xFF4ECB71),
      'W': Color(0xFFFFFFFF),
      'M': Color(0xFF2E7D4F),
    },
  );

  // ------------------------------------------------------------------ items
  static const steelSword = ArtTemplate(
    name: 'Steel Sword',
    category: 'items',
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

  static const shield = ArtTemplate(
    name: 'Shield',
    category: 'items',
    rows: [
      '................',
      '................',
      '..KKKKKKKKKKKK..',
      '..KSSSSSSSSSSK..',
      '..KSSSEEEESSSK..',
      '..KSSSEEEESSSK..',
      '..KSEEEEEEEESK..',
      '..KSSSEEEESSSK..',
      '..KSSSEEEESSSK..',
      '...KSSEEEESSK...',
      '...KSSEEEESSK...',
      '....KSSEESSK....',
      '....KSSEESSK....',
      '.....KSSESK.....',
      '......KSK.......',
      '.......K........',
    ],
    colors: {
      'K': Color(0xFF14141F),
      'S': Color(0xFF5B9CF5),
      'E': Color(0xFFF5B301),
    },
  );

  static const potion = ArtTemplate(
    name: 'Potion',
    category: 'items',
    rows: [
      '................',
      '................',
      '.......KK.......',
      '......KCCK......',
      '......KCCK......',
      '.....KGGGGK.....',
      '....KGGGGGGK....',
      '...KGGWWGGGGK...',
      '...KGWGGGGGGK...',
      '...KGLLLLLLLK...',
      '..KGLLLLLLLLLK..',
      '..KGLLWWLLLLLK..',
      '..KGLLLLLLLLLK..',
      '...KLLLLLLLLK...',
      '....KKKKKKKK....',
      '................',
    ],
    colors: {
      'K': Color(0xFF14141F),
      'C': Color(0xFF8B5A2B),
      'G': Color(0xFFCFEAF5),
      'L': Color(0xFF9B5DE5),
      'W': Color(0xFFFFFFFF),
    },
  );

  static const gem = ArtTemplate(
    name: 'Gem',
    category: 'items',
    rows: [
      '................',
      '................',
      '................',
      '.....KKKKKK.....',
      '...KKGGGGGGKK...',
      '..KGGWWGGGGGGK..',
      '..KGWGGDDDDDGK..',
      '..KGGGGDDDDDGK..',
      '...KGGGGDDDGK...',
      '...KGGGGDDGK....',
      '....KGGGDDK.....',
      '....KGGDDK......',
      '.....KGDK.......',
      '.....KDK........',
      '......K.........',
      '................',
    ],
    colors: {
      'K': Color(0xFF14141F),
      'G': Color(0xFF5BE3E3),
      'W': Color(0xFFFFFFFF),
      'D': Color(0xFF2EA3A3),
    },
  );

  static const axe = ArtTemplate(
    name: 'Axe',
    category: 'items',
    rows: [
      '................',
      '................',
      '.......KK.......',
      '...KKKKHHKKK....',
      '..KSSSSSHHSSK...',
      '.KSSSSSSHHSSSSK.',
      '.KSDDDDSHHSSSSK.',
      '.KSSSSSSHHSSSSK.',
      '..KSSSSSHHSSK...',
      '...KKKKHHKKK....',
      '.......HH.......',
      '.......HH.......',
      '.......HH.......',
      '.......HH.......',
      '......KHHK......',
      '................',
    ],
    colors: {
      'K': Color(0xFF14141F),
      'H': Color(0xFF8B5A2B),
      'S': Color(0xFFB8C4D4),
      'D': Color(0xFFDFE6F2),
    },
  );

  static const List<ArtTemplate> all = [
    slimeHero,
    knight,
    wizard,
    ninja,
    goblin,
    bat,
    ghost,
    mushroom,
    cat,
    bird,
    frog,
    steelSword,
    shield,
    potion,
    gem,
    axe,
    ...FoodTemplates.all,
    ...NatureTemplates.all,
    ...SpaceTemplates.all,
    ...FacesTemplates.all,
    ...ExtraTemplates.all,
    ...DetailedTemplates.all,
  ];

  static List<ArtTemplate> byCategory(String c) =>
      all.where((t) => t.category == c).toList();

  static const List<String> categories = [
    'heroes',
    'monsters',
    'animals',
    'items',
    'food',
    'nature',
    'space',
    'faces',
    'detailed',
  ];

  /// Human-friendly label for a category id.
  static String categoryLabel(String category) {
    switch (category) {
      case 'heroes':
        return 'Heroes';
      case 'monsters':
        return 'Monsters';
      case 'animals':
        return 'Animals';
      case 'items':
        return 'Items';
      case 'food':
        return 'Food';
      case 'nature':
        return 'Nature';
      case 'space':
        return 'Space';
      case 'faces':
        return 'Faces';
      case 'detailed':
        return 'Detailed 32×32';
      default:
        return category;
    }
  }
}
