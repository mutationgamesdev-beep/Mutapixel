import 'package:flutter/material.dart';

import '../models/sprite_frame.dart';
import 'parts_eyes2.dart';
import 'parts_mouths2.dart';
import 'parts_hats2.dart';
import 'parts_hair.dart';
import 'parts_bodies2.dart';
import 'parts_arms.dart';
import 'parts_legs.dart';
import 'parts_extras2.dart';
import 'parts_wings.dart';
import 'parts_features.dart';

/// A mix-and-match sprite part, defined as text rows where each character
/// maps to a color ('.' is always transparent). Parts are stamped onto a
/// canvas by the guided builder and the parts picker.
/// Categories: 'bodies', 'eyes', 'mouths', 'hats', 'hair', 'features',
/// 'arms', 'legs', 'wings', 'extras'.
class SpritePart {
  final String name;
  final String category; // 'bodies', 'eyes', 'mouths', 'hats', 'hair',
  // 'features', 'arms', 'legs', 'wings', 'extras'
  final List<String> rows;
  final Map<String, Color> colors;

  const SpritePart({
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

  int get width => rows.first.length;
  int get height => rows.length;
}

class SpriteParts {
  // ----------------------------------------------------------------- bodies
  // Faceless 16x16 bases for the guided builder.
  static const roundBody = SpritePart(
    name: 'Round Body',
    category: 'bodies',
    rows: [
      '................',
      '................',
      '.....KKKKK......',
      '...KKGGGGGK.....',
      '..KGGGGGGGGK....',
      '.KGGGGGGGGGGK...',
      '.KGGGGGGGGGGK...',
      '.KGGGGGGGGGGK...',
      '.KGGGGGGGGGGK...',
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
    },
  );

  static const knightBody = SpritePart(
    name: 'Knight Body',
    category: 'bodies',
    rows: [
      '................',
      '................',
      '................',
      '................',
      '...KKKKKKKKKK...',
      '..KSSKSSSSKSSK..',
      '..KSKSSSSSSKSK..',
      '..KSKSESSSEKSK..',
      '..KSSSSSSSSSSK..',
      '..KSSSSSSSSSSK..',
      '...KKKKKKKKKK...',
      '...KSSK..KSSK...',
      '...KSSK..KSSK...',
      '...KKK....KKK...',
      '................',
      '................',
    ],
    colors: {
      'K': Color(0xFF14141F),
      'S': Color(0xFFC7D0DD),
      'E': Color(0xFFF5B301),
    },
  );

  static const robotBody = SpritePart(
    name: 'Robot Body',
    category: 'bodies',
    rows: [
      '.......K........',
      '.......K........',
      '......KOK.......',
      '.....KKKKK......',
      '....KMMMMMMK....',
      '....KMMMMMMK....',
      '....KMDMMDMK....',
      '....KMMMMMMK....',
      '....KMMMMMMK....',
      '...KKMMMMMMKK...',
      '..KMMKMMMMKMMK..',
      '..KMMKMDMDKMMK..',
      '..KMMMMMMMMMMK..',
      '...KKKKKKKKKK...',
      '...KKK....KKK...',
      '................',
    ],
    colors: {
      'K': Color(0xFF14141F),
      'M': Color(0xFF9AA5B1),
      'D': Color(0xFF6B7684),
      'O': Color(0xFFFF3B3B),
    },
  );

  static const ghostBody = SpritePart(
    name: 'Ghost Body',
    category: 'bodies',
    rows: [
      '................',
      '.....KKKKKK.....',
      '...KKWWWWWWKK...',
      '..KWWWWWWWWWWK..',
      '..KWWWWWWWWWWK..',
      '..KWWWWWWWWWWK..',
      '..KWWWWWWWWWWK..',
      '..KWWWWWWWWWWK..',
      '..KWWWWWWWWWWK..',
      '..KWWWWWWWWWWK..',
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
    },
  );

  // ------------------------------------------------------------------- eyes
  // All 6 wide x 3 tall.
  static const roundEyes = SpritePart(
    name: 'Round Eyes',
    category: 'eyes',
    rows: [
      'WW..WW',
      'KW..WK',
      'WW..WW',
    ],
    colors: {
      'W': Color(0xFFFFFFFF),
      'K': Color(0xFF14141F),
    },
  );

  static const happyEyes = SpritePart(
    name: 'Happy Eyes',
    category: 'eyes',
    rows: [
      '.K..K.',
      'K.KK.K',
      '......',
    ],
    colors: {
      'K': Color(0xFF14141F),
    },
  );

  static const angryEyes = SpritePart(
    name: 'Angry Eyes',
    category: 'eyes',
    rows: [
      'KK..KK',
      '.KKKK.',
      '......',
    ],
    colors: {
      'K': Color(0xFF14141F),
    },
  );

  static const sleepyEyes = SpritePart(
    name: 'Sleepy Eyes',
    category: 'eyes',
    rows: [
      'WW..WW',
      'KKKKKK',
      '......',
    ],
    colors: {
      'W': Color(0xFFFFFFFF),
      'K': Color(0xFF14141F),
    },
  );

  static const starEyes = SpritePart(
    name: 'Star Eyes',
    category: 'eyes',
    rows: [
      '.S..S.',
      'SS..SS',
      '.S..S.',
    ],
    colors: {
      'S': Color(0xFFF5B301),
    },
  );

  // ----------------------------------------------------------------- mouths
  // All 6 wide x 2 tall.
  static const smile = SpritePart(
    name: 'Smile',
    category: 'mouths',
    rows: [
      'K....K',
      '.KKKK.',
    ],
    colors: {
      'K': Color(0xFF14141F),
    },
  );

  static const fangs = SpritePart(
    name: 'Fangs',
    category: 'mouths',
    rows: [
      'KKKKKK',
      '.K..K.',
    ],
    colors: {
      'K': Color(0xFF14141F),
    },
  );

  static const openMouth = SpritePart(
    name: 'Open',
    category: 'mouths',
    rows: [
      '.KKKK.',
      'KMMMMK',
    ],
    colors: {
      'K': Color(0xFF14141F),
      'M': Color(0xFF8B2E2E),
    },
  );

  static const catMouth = SpritePart(
    name: 'Cat Mouth',
    category: 'mouths',
    rows: [
      'K.KK.K',
      '.K..K.',
    ],
    colors: {
      'K': Color(0xFF14141F),
    },
  );

  // ------------------------------------------------------------------- hats
  // ~12 wide x 5 tall; bottom row is the brim.
  static const redCap = SpritePart(
    name: 'Red Cap',
    category: 'hats',
    rows: [
      '....KKKK....',
      '..KKRRRRKK..',
      '..KRRRRRRK..',
      '..KRRRRRRRRK',
      '..KKKKKKKKKK',
    ],
    colors: {
      'K': Color(0xFF14141F),
      'R': Color(0xFFE63946),
    },
  );

  static const goldCrown = SpritePart(
    name: 'Gold Crown',
    category: 'hats',
    rows: [
      '...K..K..K..',
      '...KK.KK.KK.',
      '...KGEKGEKG.',
      '...KGGGGGGK.',
      '...KKKKKKKK.',
    ],
    colors: {
      'K': Color(0xFF14141F),
      'G': Color(0xFFF5B301),
      'E': Color(0xFFE63946),
    },
  );

  static const wizardHat = SpritePart(
    name: 'Wizard Hat',
    category: 'hats',
    rows: [
      '.....K......',
      '....KGK.....',
      '...KGEGK....',
      '...KGGGGK...',
      '.KKKKKKKKKK.',
    ],
    colors: {
      'K': Color(0xFF14141F),
      'G': Color(0xFF5B7FE8),
      'E': Color(0xFFF5B301),
    },
  );

  static const ninjaHeadband = SpritePart(
    name: 'Ninja Headband',
    category: 'hats',
    rows: [
      '.....KK.....',
      'HH..KHHK....',
      '.HHKHHHHHHK.',
      '.KHHHHHHHHK.',
      '.KKKKKKKKKK.',
    ],
    colors: {
      'K': Color(0xFF14141F),
      'H': Color(0xFFE63946),
    },
  );

  static const beanie = SpritePart(
    name: 'Beanie',
    category: 'hats',
    rows: [
      '.....WW.....',
      '....KKKK....',
      '..KKPPPPKK..',
      '..KPPPPPPPK.',
      '..KPPPPPPPPK',
    ],
    colors: {
      'K': Color(0xFF14141F),
      'P': Color(0xFF9B5DE5),
      'W': Color(0xFFFFFFFF),
    },
  );

  // ----------------------------------------------------------------- extras
  // ~8x8.
  static const tinySword = SpritePart(
    name: 'Tiny Sword',
    category: 'extras',
    rows: [
      '...W....',
      '...W....',
      '...W....',
      '...W....',
      '..EEE...',
      '...D....',
      '...D....',
      '...E....',
    ],
    colors: {
      'W': Color(0xFFDFE6F2),
      'E': Color(0xFFF5B301),
      'D': Color(0xFF8B5A2B),
    },
  );

  static const tinyShield = SpritePart(
    name: 'Tiny Shield',
    category: 'extras',
    rows: [
      '.KKKKKK.',
      'KSSSSSSK',
      'KSSEESSK',
      'KSSEESSK',
      '.KSSESK.',
      '..KSSK..',
      '..KSK...',
      '...K....',
    ],
    colors: {
      'K': Color(0xFF14141F),
      'S': Color(0xFF5B9CF5),
      'E': Color(0xFFF5B301),
    },
  );

  static const magicWand = SpritePart(
    name: 'Magic Wand',
    category: 'extras',
    rows: [
      '......S.',
      '.....SSS',
      '......S.',
      '.....H..',
      '....H...',
      '...H....',
      '..H.....',
      '.H......',
    ],
    colors: {
      'S': Color(0xFFF5B301),
      'H': Color(0xFF8B5A2B),
    },
  );

  static const heart = SpritePart(
    name: 'Heart',
    category: 'extras',
    rows: [
      '.KK..KK.',
      'KRRKKRRK',
      'KWRRRRRK',
      'KRRRRRRK',
      '.KRRRRK.',
      '..KRRK..',
      '...KK...',
      '........',
    ],
    colors: {
      'K': Color(0xFF14141F),
      'R': Color(0xFFFF3B6B),
      'W': Color(0xFFFFFFFF),
    },
  );

  static const List<SpritePart> all = [
    roundBody,
    knightBody,
    robotBody,
    ghostBody,
    roundEyes,
    happyEyes,
    angryEyes,
    sleepyEyes,
    starEyes,
    smile,
    fangs,
    openMouth,
    catMouth,
    redCap,
    goldCrown,
    wizardHat,
    ninjaHeadband,
    beanie,
    tinySword,
    tinyShield,
    magicWand,
    heart,
    ...EyesParts2.all,
    ...MouthsParts2.all,
    ...HatsParts2.all,
    ...HairParts.all,
    ...BodiesParts2.all,
    ...ArmsParts.all,
    ...LegsParts.all,
    ...ExtrasParts2.all,
    ...WingsParts.all,
    ...FeaturesParts.all,
  ];

  static List<SpritePart> byCategory(String c) =>
      all.where((p) => p.category == c).toList();

  // Default stamp offsets (top-left x,y) for the guided builder
  // on a 16x16 canvas.
  static const Map<String, List<int>> defaultOffset = {
    'eyes': [5, 6],
    'mouths': [5, 10],
    'hats': [2, -1],
  };
}
