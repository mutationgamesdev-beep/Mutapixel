// Generates the 500 animation templates for the Animation Studio.
//
// Run with: dart tool/generate_animations.dart
// (from ~/workspace/app-build/sprite_builder)
//
// Writes:
//   lib/data/anim_walks.dart, anim_runs.dart, anim_jumps.dart,
//   anim_idles.dart, anim_attacks.dart, anim_effects.dart,
//   anim_emotes.dart, anim_misc.dart
//
// All art is original, drawn procedurally on a 16x16 pixel grid.
// Frames are emitted as text rows + color maps, mirroring ArtTemplate.

import 'dart:io';

// ------------------------------------------------------------------ canvas

/// A 16x16 grid of single-character color keys ('.' = transparent).
class Grid {
  final List<List<String>> p =
      List.generate(16, (_) => List.filled(16, '.'));

  void s(int x, int y, String c) {
    if (x < 0 || y < 0 || x > 15 || y > 15) return;
    p[y][x] = c;
  }

  void r(int x, int y, int w, int h, String c) {
    for (var j = y; j < y + h; j++) {
      for (var i = x; i < x + w; i++) {
        s(i, j, c);
      }
    }
  }

  /// Filled ellipse.
  void e(int cx, int cy, int rx, int ry, String c) {
    if (rx <= 0 || ry <= 0) return;
    for (var y = cy - ry; y <= cy + ry; y++) {
      for (var x = cx - rx; x <= cx + rx; x++) {
        final v = ((x - cx) * (x - cx)) / (rx * rx) +
            ((y - cy) * (y - cy)) / (ry * ry);
        if (v <= 1.0) s(x, y, c);
      }
    }
  }

  /// Filled ellipse with a 1px outline.
  void blob(int cx, int cy, int rx, int ry, String fill, String line) {
    e(cx, cy, rx + 1, ry + 1, line);
    e(cx, cy, rx, ry, fill);
  }

  /// Hollow ellipse (ring).
  void ring(int cx, int cy, int rx, int ry, String c) {
    if (rx <= 0 || ry <= 0) return;
    for (var y = cy - ry; y <= cy + ry; y++) {
      for (var x = cx - rx; x <= cx + rx; x++) {
        final v = ((x - cx) * (x - cx)) / (rx * rx) +
            ((y - cy) * (y - cy)) / (ry * ry);
        if (v <= 1.0 && v >= 0.45) s(x, y, c);
      }
    }
  }

  List<String> rows() => [for (final row in p) row.join()];
}

/// Shifts rows of pixels by (dx, dy), clipping at the edges.
List<String> shift(List<String> rows, int dx, int dy) {
  final m = List.generate(16, (_) => List.filled(16, '.'));
  for (var y = 0; y < 16; y++) {
    for (var x = 0; x < 16; x++) {
      final c = rows[y][x];
      if (c == '.') continue;
      final nx = x + dx, ny = y + dy;
      if (nx >= 0 && ny >= 0 && nx < 16 && ny < 16) m[ny][nx] = c;
    }
  }
  return [for (final row in m) row.join()];
}

// ---------------------------------------------------------------- palettes

// Logical color keys used by every drawing routine:
//   K = outline/dark, W = white, E = eye dark,
//   A = main body, B = shade, C = accent 1, D = accent 2.
const palettes = <String, Map<String, int>>{
  'Green': {
    'K': 0xFF2D3436,
    'W': 0xFFFFFFFF,
    'E': 0xFF2D3436,
    'A': 0xFF55EFC4,
    'B': 0xFF00B894,
    'C': 0xFFFDCB6E,
    'D': 0xFFE17055,
  },
  'Blue': {
    'K': 0xFF2D3436,
    'W': 0xFFFFFFFF,
    'E': 0xFF2D3436,
    'A': 0xFF74B9FF,
    'B': 0xFF0984E3,
    'C': 0xFF55EFC4,
    'D': 0xFFFDCB6E,
  },
  'Pink': {
    'K': 0xFF2D3436,
    'W': 0xFFFFFFFF,
    'E': 0xFF2D3436,
    'A': 0xFFFFA6C9,
    'B': 0xFFE84393,
    'C': 0xFF74B9FF,
    'D': 0xFFFDCB6E,
  },
  'Orange': {
    'K': 0xFF2D3436,
    'W': 0xFFFFFFFF,
    'E': 0xFF2D3436,
    'A': 0xFFFDCB6E,
    'B': 0xFFE17055,
    'C': 0xFF55EFC4,
    'D': 0xFFD63031,
  },
  'Purple': {
    'K': 0xFF2D3436,
    'W': 0xFFFFFFFF,
    'E': 0xFF2D3436,
    'A': 0xFFA29BFE,
    'B': 0xFF6C5CE7,
    'C': 0xFF55EFC4,
    'D': 0xFFE84393,
  },
  'Red': {
    'K': 0xFF2D3436,
    'W': 0xFFFFFFFF,
    'E': 0xFF2D3436,
    'A': 0xFFFF7675,
    'B': 0xFFD63031,
    'C': 0xFFFDCB6E,
    'D': 0xFF6C5CE7,
  },
};

// ----------------------------------------------------------------- emitter

/// Collects generated templates for one output file.
class Out {
  final StringBuffer sb = StringBuffer();
  final Set<String> usedPalettes = {};
  int count = 0;

  /// frames: list of frames; each frame is a list of 16 row-strings.
  void add(String name, String category, int fps, String palette,
      List<List<String>> frames) {
    for (final rows in frames) {
      assert(rows.length == 16, 'frame must have 16 rows: $name');
      for (final row in rows) {
        assert(row.length == 16, 'row must be 16 chars: $name / $row');
      }
      assert(rows.any((r) => r.contains(RegExp(r'[A-Z]'))),
          'frame must not be blank: $name');
    }
    usedPalettes.add(palette);
    sb.writeln('  AnimationTemplate(');
    sb.writeln("    name: '$name',");
    sb.writeln("    category: '$category',");
    sb.writeln('    fps: $fps,');
    sb.writeln('    frames: buildAnimFrames(_pal$palette, [');
    for (var fi = 0; fi < frames.length; fi++) {
      sb.writeln('      // frame ${fi + 1}');
      sb.writeln('      [');
      for (final row in frames[fi]) {
        sb.writeln("        '$row',");
      }
      sb.writeln('      ],');
    }
    sb.writeln('    ]),');
    sb.writeln('  ),');
    count++;
  }

  String paletteConsts() {
    final sb = StringBuffer();
    for (final p in usedPalettes) {
      sb.writeln('const _pal$p = <String, int>{');
      for (final e in palettes[p]!.entries) {
        sb.writeln(
            "  '${e.key}': 0x${e.value.toRadixString(16).toUpperCase().padLeft(8, '0')},");
      }
      sb.writeln('};');
      sb.writeln();
    }
    return sb.toString();
  }
}

void writeFile(String path, String varName, String doc, Out out) {
  final sb = StringBuffer();
  sb.writeln("import '../models/animation_template.dart';");
  sb.writeln();
  sb.writeln('// GENERATED CODE - do not edit by hand.');
  sb.writeln('// Generated by tool/generate_animations.dart.');
  sb.writeln();
  sb.write(out.paletteConsts());
  sb.writeln('/// $doc');
  sb.writeln('final $varName = <AnimationTemplate>[');
  sb.write(out.sb.toString());
  sb.writeln('];');
  File(path).writeAsStringSync(sb.toString());
  // ignore: avoid_print
  print('wrote $path (${out.count} templates)');
}

// --------------------------------------------------------------- characters
//
// Every character draws within a 16x16 grid. Signature:
//   draw(Grid g, int dy, int leg, bool blink, int arm, int squash)
//   dy: vertical bob offset, leg: 0/1 walk pose, blink: eyes closed,
//   arm: 0 rest / 1 raised-windup / 2 strike-forward, squash: +squashed.

void drawSlime(Grid g, int dy, int leg, bool blink, int arm, int squash) {
  final rx = 5 + squash, ry = 4 - squash;
  final cy = 10 + dy;
  g.blob(8, cy, rx, ry, 'A', 'K');
  g.s(6, cy - 2, 'W');
  g.s(5, cy - 1, 'W');
  for (var x = 8 - rx + 2; x <= 8 + rx - 2; x++) {
    g.s(x, cy + ry - 1, 'B');
  }
  if (blink) {
    g.r(5, cy - 1, 2, 1, 'K');
    g.r(9, cy - 1, 2, 1, 'K');
  } else {
    g.r(5, cy - 2, 2, 2, 'W');
    g.r(9, cy - 2, 2, 2, 'W');
    g.s(5, cy - 1, 'E');
    g.s(9, cy - 1, 'E');
  }
  g.r(7, cy + 1, 3, 1, 'K');
}

void drawGhost(Grid g, int dy, int leg, bool blink, int arm, int squash) {
  g.blob(8, 6 + dy, 4, 4, 'A', 'K');
  g.r(4, 6 + dy, 8, 5, 'K');
  g.r(5, 6 + dy, 6, 4, 'A');
  // wavy bottom hem
  for (var x = 4; x < 12; x++) {
    final h = (x % 2 == 0) ? 11 + dy : 10 + dy;
    g.s(x, h, 'A');
    g.s(x, h + 1, '.');
  }
  if (blink) {
    g.r(6, 6 + dy, 2, 1, 'K');
    g.r(9, 6 + dy, 2, 1, 'K');
  } else {
    g.r(6, 5 + dy, 2, 3, 'W');
    g.r(9, 5 + dy, 2, 3, 'W');
    g.s(6, 6 + dy, 'E');
    g.s(9, 6 + dy, 'E');
  }
  if (arm == 2) {
    g.r(7, 8 + dy, 3, 2, 'K'); // spook mouth open
  } else {
    g.r(7, 9 + dy, 2, 1, 'K');
  }
  // little arms
  if (arm == 1) {
    g.r(2, 4 + dy, 2, 2, 'K');
    g.r(12, 4 + dy, 2, 2, 'K');
  } else {
    g.r(2, 7 + dy, 2, 3, 'K');
    g.r(12, 7 + dy, 2, 3, 'K');
  }
}

void drawHumanoid(
    Grid g, String head, int dy, int leg, bool blink, int arm, int squash) {
  // legs
  if (leg == 0) {
    g.r(6, 12 + dy, 2, 2, 'K');
    g.r(8, 12 + dy, 2, 2, 'K');
  } else {
    g.r(5, 12 + dy, 2, 2, 'K');
    g.r(9, 12 + dy, 2, 2, 'K');
  }
  // body
  g.r(6, 7 + dy, 4, 5, 'K');
  g.r(7, 8 + dy, 2, 3, 'A');
  if (head == 'robot') {
    g.s(7, 9 + dy, 'C');
    g.s(8, 9 + dy, 'C');
  } else {
    g.r(6, 10 + dy, 4, 1, 'C'); // belt
  }
  // arms
  if (arm == 0) {
    g.r(4, 7 + dy, 2, 4, 'K');
    g.r(10, 7 + dy, 2, 4, 'K');
  } else if (arm == 1) {
    g.r(4, 7 + dy, 2, 4, 'K');
    g.r(10, 5 + dy, 2, 3, 'K');
  } else {
    g.r(4, 7 + dy, 2, 4, 'K');
    g.r(10, 8 + dy, 4, 2, 'K');
  }
  // heads
  if (head == 'robot') {
    g.r(6, 1 + dy, 4, 5, 'K');
    g.r(7, 2 + dy, 2, 3, 'A');
    g.s(7, 0 + dy, 'D');
    g.r(7, 1 + dy, 1, 1, 'K');
    if (blink) {
      g.r(7, 3 + dy, 2, 1, 'K');
    } else {
      g.s(7, 3 + dy, 'E');
      g.s(8, 3 + dy, 'E');
    }
    g.r(7, 4 + dy, 2, 1, 'K');
  } else if (head == 'knight') {
    g.r(6, 1 + dy, 4, 5, 'K');
    g.r(6, 1 + dy, 4, 2, 'B');
    g.s(8, 0 + dy, 'D');
    g.r(6, 3 + dy, 4, 1, 'E'); // visor
    g.r(7, 5 + dy, 2, 1, 'B');
    if (arm == 2) {
      g.r(13, 5 + dy, 1, 5, 'W'); // blade forward
      g.r(12, 8 + dy, 3, 1, 'C'); // guard
    } else if (arm == 1) {
      g.r(11, 1 + dy, 1, 4, 'W');
      g.r(10, 4 + dy, 3, 1, 'C');
    }
  } else if (head == 'skull') {
    g.r(6, 1 + dy, 4, 5, 'K');
    g.r(7, 2 + dy, 2, 3, 'W');
    g.s(7, 3 + dy, 'E');
    g.s(8, 3 + dy, 'E');
    g.r(7, 5 + dy, 2, 1, 'W');
    if (arm == 2) {
      g.r(13, 5 + dy, 1, 5, 'B');
      g.r(12, 8 + dy, 3, 1, 'C');
    }
  } else {
    // alien
    g.blob(8, 4 + dy, 3, 3, 'A', 'K');
    g.s(6, 0 + dy, 'D');
    g.s(10, 0 + dy, 'D');
    g.s(6, 1 + dy, 'K');
    g.s(10, 1 + dy, 'K');
    if (blink) {
      g.r(6, 4 + dy, 2, 1, 'K');
      g.r(8, 4 + dy, 2, 1, 'K');
    } else {
      g.r(5, 3 + dy, 2, 3, 'E');
      g.r(9, 3 + dy, 2, 3, 'E');
    }
    if (arm == 2) {
      // zap ray
      g.r(13, 8 + dy, 2, 1, 'C');
      g.s(15, 8 + dy, 'W');
    }
  }
}

void drawQuad(Grid g, String kind, int dy, int leg, bool blink, int arm,
    int squash) {
  // body
  g.blob(7, 10 + dy, 4, 3, 'A', 'K');
  if (kind == 'turtle') {
    g.e(7, 9 + dy, 3, 2, 'B');
    g.s(6, 8 + dy, 'A');
    g.s(8, 9 + dy, 'A');
  }
  if (kind == 'frog') {
    g.e(7, 11 + dy, 3, 1, 'W'); // belly
  }
  // legs
  if (leg == 0) {
    g.r(4, 12 + dy, 2, 2, 'K');
    g.r(8, 12 + dy, 2, 2, 'K');
  } else {
    g.r(5, 12 + dy, 2, 2, 'K');
    g.r(7, 12 + dy, 2, 2, 'K');
  }
  if (kind == 'crab') {
    // claws
    final clawY = leg == 0 ? 6 + dy : 4 + dy;
    g.blob(2, 7 + dy, 2, 2, 'A', 'K');
    g.blob(12, clawY, 2, 2, 'A', 'K');
    g.r(1, 6 + dy, 2, 1, 'K');
  }
  // head
  if (kind == 'frog') {
    g.blob(11, 7 + dy, 3, 2, 'A', 'K');
    g.r(9, 4 + dy, 2, 2, 'K');
    g.r(12, 4 + dy, 2, 2, 'K');
    if (blink) {
      g.r(9, 5 + dy, 2, 1, 'K');
      g.r(12, 5 + dy, 2, 1, 'K');
    } else {
      g.r(9, 4 + dy, 2, 2, 'W');
      g.r(12, 4 + dy, 2, 2, 'W');
      g.s(9, 5 + dy, 'E');
      g.s(12, 5 + dy, 'E');
    }
    g.r(10, 8 + dy, 3, 1, 'K');
  } else if (kind == 'turtle') {
    g.blob(12, 8 + dy, 2, 2, 'A', 'K');
    if (blink) {
      g.s(12, 8 + dy, 'K');
    } else {
      g.s(12, 8 + dy, 'E');
    }
  } else if (kind == 'crab') {
    g.r(6, 5 + dy, 1, 2, 'K');
    g.r(9, 5 + dy, 1, 2, 'K');
    g.s(6, 4 + dy, 'E');
    g.s(9, 4 + dy, 'E');
    g.r(7, 9 + dy, 2, 1, 'K');
  } else {
    // cat / dog / pig share a head plan
    g.blob(11, 6 + dy, 3, 3, 'A', 'K');
    if (kind == 'cat') {
      g.r(8, 3 + dy, 2, 2, 'K');
      g.r(12, 3 + dy, 2, 2, 'K');
      g.r(9, 4 + dy, 1, 1, 'A');
      g.r(12, 4 + dy, 1, 1, 'A');
    } else if (kind == 'dog') {
      g.r(8, 5 + dy, 1, 3, 'B');
      g.r(13, 5 + dy, 1, 3, 'B');
      g.r(10, 7 + dy, 3, 2, 'W'); // snout
      g.s(11, 7 + dy, 'E');
      if (arm == 2) g.r(11, 9 + dy, 1, 2, 'D'); // tongue!
    } else {
      // pig
      g.r(8, 4 + dy, 2, 1, 'K');
      g.r(12, 4 + dy, 2, 1, 'K');
      g.r(10, 7 + dy, 3, 2, 'D'); // snout
      g.s(10, 7 + dy, 'K');
      g.s(12, 7 + dy, 'K');
    }
    if (blink) {
      g.r(9, 6 + dy, 2, 1, 'K');
      g.r(12, 6 + dy, 1, 1, 'K');
    } else {
      g.s(10, 6 + dy, 'E');
      g.s(12, 6 + dy, 'E');
    }
    // tail
    if (leg == 0) {
      g.r(2, 7 + dy, 1, 3, 'K');
    } else {
      g.r(2, 6 + dy, 1, 3, 'K');
    }
    if (kind == 'pig') {
      g.s(2, 6 + dy, 'D');
      g.s(3, 6 + dy, 'D');
    }
  }
  // stripes for cat
  if (kind == 'cat') {
    g.s(5, 8 + dy, 'B');
    g.s(7, 8 + dy, 'B');
  }
}

void drawFlyer(Grid g, String kind, int dy, int leg, bool blink, int arm,
    int squash) {
  // kinds: bird, bat, bee. leg = wing pose 0/1.
  if (kind == 'bee') {
    g.blob(8, 9 + dy, 3, 3, 'A', 'K');
    g.r(7, 7 + dy, 3, 1, 'K');
    g.r(7, 10 + dy, 3, 1, 'K');
    g.s(9, 8 + dy, 'E');
    g.s(4, 9 + dy, 'K'); // stinger
    if (leg == 0) {
      g.e(6, 5 + dy, 2, 2, 'W');
    } else {
      g.e(10, 5 + dy, 2, 2, 'W');
    }
    return;
  }
  if (kind == 'bat') {
    g.blob(8, 8 + dy, 2, 3, 'A', 'K');
    g.s(7, 5 + dy, 'K');
    g.s(9, 5 + dy, 'K');
    g.s(7, 7 + dy, 'D');
    g.s(9, 7 + dy, 'D');
    if (leg == 0) {
      g.e(3, 6 + dy, 3, 2, 'B');
      g.e(13, 6 + dy, 3, 2, 'B');
    } else {
      g.e(3, 10 + dy, 3, 2, 'B');
      g.e(13, 10 + dy, 3, 2, 'B');
    }
    return;
  }
  // bird
  g.blob(8, 9 + dy, 3, 2, 'A', 'K');
  g.blob(11, 6 + dy, 2, 2, 'A', 'K');
  if (blink) {
    g.s(11, 6 + dy, 'K');
  } else {
    g.s(12, 6 + dy, 'E');
  }
  g.r(13, 7 + dy, 2, 1, 'C'); // beak
  if (leg == 0) {
    g.r(5, 9 + dy, 3, 2, 'B'); // wing down
  } else {
    g.r(5, 5 + dy, 3, 3, 'B'); // wing up
    g.r(5, 5 + dy, 3, 1, 'K');
  }
  g.r(3, 8 + dy, 2, 1, 'B'); // tail
  g.r(7, 11 + dy, 1, 2, 'C');
  g.r(9, 11 + dy, 1, 2, 'C');
  if (arm == 2) {
    // dive: beak forward handled by shift
  }
}

void drawShroom(Grid g, int dy, int leg, bool blink, int arm, int squash) {
  final capRy = 4 - (squash > 0 ? 1 : 0);
  g.blob(8, 5 + dy, 6, capRy, 'A', 'K');
  g.s(5, 4 + dy, 'W');
  g.s(8, 3 + dy, 'W');
  g.s(11, 4 + dy, 'W');
  g.r(6, 8 + dy, 4, 5, 'K');
  g.r(7, 9 + dy, 2, 3, 'W');
  if (blink) {
    g.r(7, 10 + dy, 2, 1, 'K');
    g.r(10, 10 + dy, 1, 1, 'K');
  } else {
    g.s(7, 10 + dy, 'E');
    g.s(9, 10 + dy, 'E');
  }
  g.r(7, 11 + dy, 3, 1, 'K');
  if (arm == 2) {
    // headbutt: cap spikes forward
    g.r(12, 4 + dy, 2, 2, 'K');
  }
}

// ----------------------------------------------------------------- objects

void drawCoin(Grid g, int t) {
  // 4-frame spin: widths shrink then grow.
  const widths = [6, 4, 2, 4];
  final w = widths[t % 4];
  g.e(8, 8, w + 1, 7, 'K');
  g.e(8, 8, w, 6, 'A');
  if (w >= 4) {
    g.e(8, 8, w - 2, 4, 'B');
    g.s(8 - w + 1, 6, 'W');
  }
  if (w >= 6) g.s(8, 8, 'C');
}

void drawStar(Grid g, int t) {
  // 4-frame twinkle spin: two star phases alternate + shimmer.
  final big = t % 2 == 0;
  final r = big ? 5 : 4;
  g.s(8, 8 - r, 'A');
  g.s(8, 8 + r, 'A');
  g.s(8 - r, 8, 'A');
  g.s(8 + r, 8, 'A');
  final d = big ? 3 : 2;
  g.s(8 - d, 8 - d, 'A');
  g.s(8 + d, 8 - d, 'A');
  g.s(8 - d, 8 + d, 'A');
  g.s(8 + d, 8 + d, 'A');
  g.s(8, 8, 'W');
  if (big) {
    g.s(8 - 1, 8, 'C');
    g.s(8 + 1, 8, 'C');
  } else {
    g.s(6, 6, 'W');
    g.s(10, 10, 'W');
  }
}

void drawHeartObj(Grid g, int t) {
  final big = t % 2 == 0;
  final w = big ? 3 : 2;
  g.e(6, 7, w, w, 'D');
  g.e(10, 7, w, w, 'D');
  g.r(4, 7, 8, 3, 'D');
  for (var i = 0; i < 4; i++) {
    g.r(5 + i, 10 + i, 6 - i * 2, 1, 'D');
  }
  g.e(6, 7, w + 1, w + 1, 'K');
  g.e(10, 7, w + 1, w + 1, 'K');
  g.s(5, 6, 'W');
}

void drawCrystal(Grid g, int t) {
  g.r(7, 3, 2, 1, 'K');
  g.e(8, 8, 4, 6, 'K');
  g.e(8, 8, 3, 5, 'A');
  g.r(7, 6, 2, 4, 'W');
  if (t % 2 == 0) {
    g.s(5, 5, 'W');
    g.s(11, 11, 'W');
  } else {
    g.s(11, 5, 'W');
    g.s(5, 11, 'W');
  }
  g.s(8, 13, 'C');
}

// ----------------------------------------------------------------- effects

/// 20 effect painters, each takes frame index t (0..n).
void drawEffect(Grid g, String kind, int t) {
  switch (kind) {
    case 'Explosion':
      if (t == 0) {
        g.blob(8, 8, 2, 2, 'W', 'C');
      } else if (t == 1) {
        g.blob(8, 8, 4, 4, 'C', 'A');
        g.e(8, 8, 2, 2, 'W');
      } else if (t == 2) {
        g.ring(8, 8, 6, 6, 'A');
        g.e(8, 8, 3, 3, 'C');
        for (var i = 0; i < 8; i++) {
          final a = i * 0.785;
          g.s(8 + (6.5 * (i % 2 == 0 ? 1 : -1) * (a > 3 ? -1 : 1)).round(), 8, 'B');
        }
        g.s(2, 8, 'B');
        g.s(14, 8, 'B');
        g.s(8, 2, 'B');
        g.s(8, 14, 'B');
      } else {
        g.ring(8, 8, 7, 7, 'B');
        g.s(1, 8, 'C');
        g.s(15, 8, 'C');
        g.s(8, 1, 'C');
        g.s(8, 15, 'C');
        g.s(4, 4, 'B');
        g.s(12, 12, 'B');
      }
      break;
    case 'Sparkle':
      final armLen = [2, 4, 3][t % 3];
      for (var i = -armLen; i <= armLen; i++) {
        g.s(8 + i, 8, 'W');
        g.s(8, 8 + i, 'W');
      }
      g.s(8, 8, 'C');
      if (t == 1) {
        g.s(5, 5, 'W');
        g.s(11, 11, 'W');
      }
      break;
    case 'Smoke':
      for (var i = 0; i <= t; i++) {
        final y = 11 - i * 3;
        final r = 1 + i;
        if ((t + i) % 2 == 0) {
          g.e(8, y, r, r, 'W');
        } else {
          g.ring(8, y, r, r, 'W');
        }
      }
      break;
    case 'Magic Burst':
      final r = 2 + t * 2;
      for (var i = 0; i < 8; i++) {
        final dx = [1, 0, -1, 0, 1, -1, 1, -1][i];
        final dy = [0, 1, 0, -1, 1, 1, -1, -1][i];
        g.s(8 + dx * r ~/ 2, 8 + dy * r ~/ 2, i % 2 == 0 ? 'C' : 'D');
      }
      g.s(8, 8, 'W');
      if (t >= 2) g.ring(8, 8, r, r, 'C');
      break;
    case 'Flame':
      final h = [6, 8, 7, 9][t % 4];
      g.e(8, 12, 4, 4, 'K');
      g.e(8, 12, 3, 3, 'A');
      g.e(8, 13 - h ~/ 2, 2, h ~/ 2, 'C');
      g.e(8, 14 - h ~/ 3, 1, h ~/ 3, 'W');
      break;
    case 'Splash':
      if (t == 0) {
        g.e(8, 12, 3, 2, 'A');
      } else {
        g.e(8, 13, 4, 1, 'B');
        final n = 3 + t * 2;
        for (var i = 0; i < n; i++) {
          final x = 4 + i * (8 ~/ (n - 1).clamp(1, 99));
          g.s(x, 11 - t, 'A');
          g.s(x + 1, 9 - t, 'W');
        }
      }
      break;
    case 'Zap':
      final jx = [0, 1, -1, 0][t % 4];
      g.s(8, 2, 'C');
      g.s(8 + jx, 4, 'C');
      g.s(7 + jx, 6, 'W');
      g.s(9 + jx, 8, 'C');
      g.s(8 + jx, 10, 'W');
      g.s(8, 12, 'C');
      g.s(5, 5, 'W');
      g.s(11, 3, 'W');
      break;
    case 'Heal':
      for (var i = 0; i < 3; i++) {
        final y = 12 - ((t + i * 2) % 6) * 2;
        final x = 5 + i * 3;
        g.s(x, y, 'W');
        g.s(x, y - 1, 'A');
        g.s(x, y + 1, 'A');
        g.s(x - 1, y, 'A');
        g.s(x + 1, y, 'A');
      }
      break;
    case 'Poof':
      final r = 2 + t;
      g.e(8, 9, r + 1, r, 'K');
      g.e(8, 9, r, r - 1, 'W');
      if (t >= 2) {
        g.s(5, 6, 'W');
        g.s(11, 6, 'W');
      }
      break;
    case 'Shockwave':
      g.ring(8, 10, 2 + t * 2, 1 + t, 'C');
      if (t >= 1) g.ring(8, 10, t * 2, t, 'W');
      g.e(8, 12, 2, 1, 'B');
      break;
    case 'Embers':
      for (var i = 0; i < 6; i++) {
        final y = 14 - ((t * 2 + i * 3) % 14);
        final x = 4 + (i * 5 + t) % 9;
        g.s(x, y, i % 2 == 0 ? 'A' : 'C');
      }
      g.e(8, 14, 3, 1, 'B');
      break;
    case 'Bubbles':
      for (var i = 0; i < 4; i++) {
        final y = 13 - ((t + i * 2) % 8);
        final x = 4 + i * 3;
        final r = 1 + (i + t) % 2;
        g.ring(x, y, r, r, 'A');
        g.s(x - 1, y - 1, 'W');
      }
      break;
    case 'Slash':
      if (t == 0) {
        for (var i = 0; i < 6; i++) {
          g.s(3 + i, 10 - i, 'W');
        }
      } else if (t == 1) {
        for (var i = 0; i < 9; i++) {
          g.s(3 + i, 11 - i, 'W');
          g.s(3 + i, 12 - i, 'C');
        }
      } else {
        for (var i = 0; i < 9; i++) {
          g.s(4 + i, 11 - i, 'C');
        }
        g.s(3, 12, 'W');
        g.s(13, 2, 'W');
      }
      break;
    case 'Confetti':
      for (var i = 0; i < 8; i++) {
        final y = (t * 3 + i * 4) % 16;
        final x = (i * 5 + t * 2) % 16;
        g.s(x, y, ['A', 'C', 'D', 'W'][i % 4]);
      }
      break;
    case 'Ring Pulse':
      g.ring(8, 8, 2 + t * 2, 2 + t * 2, 'C');
      if (t == 1) g.s(8, 8, 'W');
      if (t == 2) g.ring(8, 8, 3, 3, 'W');
      break;
    case 'Twinkle Stars':
      final spots = [
        [4, 4],
        [11, 3],
        [7, 10],
        [12, 11],
        [3, 12]
      ];
      for (var i = 0; i < spots.length; i++) {
        if ((i + t) % 2 == 0) {
          final x = spots[i][0], y = spots[i][1];
          g.s(x, y, 'W');
          g.s(x - 1, y, 'C');
          g.s(x + 1, y, 'C');
          g.s(x, y - 1, 'C');
          g.s(x, y + 1, 'C');
        }
      }
      break;
    case 'Falling Leaves':
      for (var i = 0; i < 5; i++) {
        final y = (t * 2 + i * 5) % 16;
        final x = (3 + i * 3 + (t ~/ 2)) % 16;
        g.s(x, y, 'B');
        g.s(x + 1, y, 'A');
      }
      break;
    case 'Snowfall':
      for (var i = 0; i < 9; i++) {
        final y = (t * 2 + i * 3) % 16;
        final x = (i * 4 + t) % 16;
        g.s(x, y, 'W');
      }
      break;
    case 'Beam':
      final w = [1, 3, 2][t % 3];
      g.r(8 - w, 2, w * 2, 12, 'C');
      g.r(8, 2, 1, 12, 'W');
      g.e(8, 8, 3, 3, 'W');
      break;
    default: // Nova
      if (t == 0) {
        g.s(8, 8, 'W');
      } else if (t == 1) {
        g.blob(8, 8, 3, 3, 'W', 'C');
      } else {
        g.ring(8, 8, 6, 6, 'C');
        g.e(8, 8, 2, 2, 'W');
        g.s(8, 1, 'W');
        g.s(8, 15, 'W');
        g.s(1, 8, 'W');
        g.s(15, 8, 'W');
      }
  }
}

// ------------------------------------------------------------------ emotes

void drawEmote(Grid g, String kind, int t) {
  // Bouncy face base.
  var dy = 0;
  if (kind == 'Happy') dy = [0, -2, 0][t % 3];
  if (kind == 'Excited') dy = [-1, -3, -1][t % 3];
  if (kind == 'Sad') dy = [0, 1][t % 2];
  if (kind == 'Angry') dy = 0;
  final dx = kind == 'Angry' ? [-1, 1, 0][t % 3] : 0;
  g.blob(8 + dx, 9 + dy, 4, 4, 'A', 'K');
  g.s(6 + dx, 7 + dy, 'W'); // highlight

  void eyes(String mode) {
    if (mode == 'happy') {
      g.r(5 + dx, 8 + dy, 2, 1, 'K');
      g.r(9 + dx, 8 + dy, 2, 1, 'K');
    } else if (mode == 'sad') {
      g.s(6 + dx, 8 + dy, 'E');
      g.s(10 + dx, 8 + dy, 'E');
      g.s(6 + dx, 7 + dy, 'K');
      g.s(10 + dx, 7 + dy, 'K');
    } else if (mode == 'angry') {
      g.r(5 + dx, 7 + dy, 3, 1, 'K');
      g.r(8 + dx, 7 + dy, 3, 1, 'K');
      g.s(6 + dx, 8 + dy, 'E');
      g.s(9 + dx, 8 + dy, 'E');
    } else if (mode == 'love') {
      g.s(6 + dx, 8 + dy, 'D');
      g.s(10 + dx, 8 + dy, 'D');
      g.s(6 + dx, 7 + dy, 'D');
      g.s(10 + dx, 7 + dy, 'D');
    } else if (mode == 'dizzy') {
      g.s(6 + dx, 8 + dy, 'K');
      g.s(7 + dx, 8 + dy, 'K');
      g.s(10 + dx, 8 + dy, 'K');
      g.s(9 + dx, 8 + dy, 'K');
    } else if (mode == 'sleepy') {
      g.r(5 + dx, 8 + dy, 2, 1, 'K');
      g.r(9 + dx, 8 + dy, 2, 1, 'K');
    } else {
      // normal / excited
      g.s(6 + dx, 8 + dy, 'E');
      g.s(10 + dx, 8 + dy, 'E');
      g.s(6 + dx, 7 + dy, 'W');
      g.s(10 + dx, 7 + dy, 'W');
    }
  }

  void mouth(String mode) {
    if (mode == 'smile') {
      g.r(6 + dx, 10 + dy, 4, 1, 'K');
      g.s(6 + dx, 9 + dy, 'K');
      g.s(9 + dx, 9 + dy, 'K');
    } else if (mode == 'frown') {
      g.r(6 + dx, 11 + dy, 4, 1, 'K');
      g.s(6 + dx, 12 + dy, 'K');
      g.s(9 + dx, 12 + dy, 'K');
    } else if (mode == 'open') {
      g.r(7 + dx, 10 + dy, 2, 2, 'K');
    } else if (mode == 'small') {
      g.r(7 + dx, 11 + dy, 2, 1, 'K');
    }
  }

  switch (kind) {
    case 'Happy':
      eyes('happy');
      mouth('smile');
      break;
    case 'Sad':
      eyes('sad');
      mouth('frown');
      if (t == 1) {
        g.s(5 + dx, 9 + dy, 'C'); // tear
        g.s(5 + dx, 10 + dy, 'W');
      }
      break;
    case 'Angry':
      eyes('angry');
      mouth('frown');
      // anger mark
      final ay = 3 - (t % 2);
      g.s(12, ay, 'D');
      g.s(13, ay + 1, 'D');
      g.s(12, ay + 2, 'D');
      g.s(11, ay + 1, 'D');
      break;
    case 'In Love':
      eyes('love');
      mouth('smile');
      if (t > 0) {
        g.s(12, 6 - t, 'D');
        g.s(4, 5 - t, 'D');
      }
      break;
    case 'Dizzy':
      eyes('dizzy');
      mouth('small');
      final sx = [11, 12, 11][t % 3];
      g.s(sx, 3, 'C');
      g.s(sx + 1, 3, 'C');
      g.s(4, 4, 'C');
      break;
    case 'Sleepy':
      eyes('sleepy');
      mouth('small');
      g.s(11 - t, 5 - t, 'C'); // Z rising
      g.s(12 - t, 4 - t, 'C');
      break;
    case 'Excited':
      eyes('normal');
      mouth('open');
      if (t == 1) {
        g.s(3, 5, 'W');
        g.s(13, 5, 'W');
      }
      break;
    default: // Shy
      eyes('normal');
      mouth('small');
      g.s(5 + dx, 9 + dy, 'D'); // blush
      g.s(11 + dx, 9 + dy, 'D');
  }
}

// -------------------------------------------------------------------- misc

void drawMisc(Grid g, String kind, int t) {
  switch (kind) {
    case 'Coin Spin':
      drawCoin(g, t);
      break;
    case 'Star Spin':
      drawStar(g, t);
      break;
    case 'Shuriken':
      if (t % 2 == 0) {
        g.r(7, 2, 2, 12, 'B');
        g.r(2, 7, 12, 2, 'B');
        g.r(7, 7, 2, 2, 'K');
      } else {
        for (var i = -5; i <= 5; i++) {
          g.s(8 + i, 8 + i, 'B');
          g.s(8 + i, 8 - i, 'B');
        }
        g.r(7, 7, 2, 2, 'K');
      }
      g.s(8, 8, 'W');
      break;
    case 'Heartbeat':
      drawHeartObj(g, t);
      if (t == 1) {
        g.s(3, 3, 'D');
        g.s(13, 3, 'D');
      }
      break;
    case 'Bouncy Ball':
      final dy = [0, -4, -1, -4][t % 4];
      final squash = (t % 4 == 0 || t % 4 == 2) ? 1 : 0;
      g.blob(8, 11 + dy, 3 + squash, 3 - squash, 'A', 'K');
      g.s(7, 10 + dy, 'W');
      g.s(8, 13, 'B'); // shadow
      break;
    case 'UFO Hover':
      final dy = [0, -1, 0, 1][t % 4];
      g.e(8, 9 + dy, 6, 2, 'K');
      g.e(8, 9 + dy, 5, 1, 'B');
      g.blob(8, 7 + dy, 2, 2, 'W', 'K');
      final on = t % 2 == 0;
      g.s(5, 9 + dy, on ? 'C' : 'E');
      g.s(8, 9 + dy, on ? 'E' : 'C');
      g.s(11, 9 + dy, on ? 'C' : 'E');
      if (t == 2 || t == 3) {
        g.s(7, 12, 'C');
        g.s(9, 12, 'C');
      }
      break;
    case 'Gear Turn':
      g.ring(8, 8, 5, 5, 'B');
      g.ring(8, 8, 2, 2, 'B');
      if (t % 2 == 0) {
        g.s(8, 3, 'K');
        g.s(8, 13, 'K');
        g.s(3, 8, 'K');
        g.s(13, 8, 'K');
      } else {
        g.s(5, 5, 'K');
        g.s(11, 5, 'K');
        g.s(5, 11, 'K');
        g.s(11, 11, 'K');
      }
      g.s(8, 8, 'C');
      break;
    default: // Crystal Shimmer
      drawCrystal(g, t);
  }
}

// ------------------------------------------------------------- registries

typedef CharDraw = void Function(
    Grid g, int dy, int leg, bool blink, int arm, int squash);

class Char {
  final String name;
  final CharDraw draw;
  final bool legless;
  const Char(this.name, this.draw, {this.legless = false});
}

final walkers = <Char>[
  Char('Slime', drawSlime, legless: true),
  Char('Ghost', drawGhost, legless: true),
  Char('Robot', (g, a, b, c, d, e) => drawHumanoid(g, 'robot', a, b, c, d, e)),
  Char('Knight', (g, a, b, c, d, e) => drawHumanoid(g, 'knight', a, b, c, d, e)),
  Char('Skeleton',
      (g, a, b, c, d, e) => drawHumanoid(g, 'skull', a, b, c, d, e)),
  Char('Alien', (g, a, b, c, d, e) => drawHumanoid(g, 'alien', a, b, c, d, e)),
  Char('Cat', (g, a, b, c, d, e) => drawQuad(g, 'cat', a, b, c, d, e)),
  Char('Dog', (g, a, b, c, d, e) => drawQuad(g, 'dog', a, b, c, d, e)),
  Char('Pig', (g, a, b, c, d, e) => drawQuad(g, 'pig', a, b, c, d, e)),
  Char('Frog', (g, a, b, c, d, e) => drawQuad(g, 'frog', a, b, c, d, e)),
  Char('Turtle', (g, a, b, c, d, e) => drawQuad(g, 'turtle', a, b, c, d, e)),
  Char('Crab', (g, a, b, c, d, e) => drawQuad(g, 'crab', a, b, c, d, e)),
  Char('Bird', (g, a, b, c, d, e) => drawFlyer(g, 'bird', a, b, c, d, e)),
  Char('Bat', (g, a, b, c, d, e) => drawFlyer(g, 'bat', a, b, c, d, e)),
  Char('Bee', (g, a, b, c, d, e) => drawFlyer(g, 'bee', a, b, c, d, e)),
  const Char('Mushroom', drawShroom),
];

/// Draws a character pose and returns shifted 16-row frame.
List<String> snap(
    Char c, int dy, int leg, bool blink, int arm, int squash, int dx) {
  final g = Grid();
  c.draw(g, dy, leg, blink, arm, squash);
  return shift(g.rows(), dx, 0);
}

List<String> snapFx(void Function(Grid, int) fn, int t) {
  final g = Grid();
  fn(g, t);
  return g.rows();
}

// ------------------------------------------------------------------ builds

void buildWalks() {
  final out = Out();
  const pals = ['Green', 'Blue', 'Pink', 'Orange', 'Purple'];
  for (final c in walkers) {
    for (final p in pals) {
      final frames = c.legless
          ? [
              snap(c, 0, 0, false, 0, 0, 0),
              snap(c, -1, 0, false, 0, 1, 0),
              snap(c, 0, 0, false, 0, 0, 0),
              snap(c, -1, 0, true, 0, 1, 0),
            ]
          : [
              snap(c, 0, 0, false, 0, 0, 0),
              snap(c, -1, 1, false, 0, 0, 0),
              snap(c, 0, 1, false, 0, 0, 0),
              snap(c, -1, 0, true, 0, 0, 0),
            ];
      out.add('${c.name} Walk ($p)', 'walks', 8, p, frames);
    }
  }
  writeFile('lib/data/anim_walks.dart', 'walkAnimations',
      '80 walk-cycle animations (4 frames each).', out);
}

void buildRuns() {
  final out = Out();
  const pals = ['Green', 'Blue', 'Orange', 'Red'];
  final runners = walkers
      .where((c) => const {
            'Robot',
            'Knight',
            'Cat',
            'Dog',
            'Bird',
            'Bee',
            'Frog',
            'Alien',
            'Skeleton',
            'Pig'
          }.contains(c.name))
      .toList();
  for (final c in runners) {
    for (final p in pals) {
      final frames = [
        snap(c, 0, 0, false, 0, 0, 0),
        snap(c, -2, 1, false, 0, 0, 1),
        snap(c, 0, 1, false, 0, 0, 0),
        snap(c, -2, 0, false, 0, 0, 1),
      ];
      out.add('${c.name} Run ($p)', 'runs', 10, p, frames);
    }
  }
  writeFile('lib/data/anim_runs.dart', 'runAnimations',
      '40 run-cycle animations (4 frames each).', out);
}

void buildJumps() {
  final out = Out();
  const pals = ['Green', 'Pink', 'Blue', 'Purple'];
  final jumpers = walkers
      .where((c) => const {
            'Slime',
            'Ghost',
            'Frog',
            'Cat',
            'Dog',
            'Bird',
            'Bee',
            'Pig',
            'Mushroom',
            'Turtle'
          }.contains(c.name))
      .toList();
  for (final c in jumpers) {
    for (final p in pals) {
      final frames = c.legless
          ? [
              snap(c, 1, 0, false, 0, 1, 0),
              snap(c, -4, 0, false, 0, -1, 0),
              snap(c, 1, 0, false, 0, 1, 0),
            ]
          : [
              snap(c, 2, 0, false, 0, 0, 0),
              snap(c, -4, 0, false, 1, 0, 0),
              snap(c, 1, 0, false, 0, 0, 0),
            ];
      out.add('${c.name} Jump ($p)', 'jumps', 8, p, frames);
    }
  }
  writeFile('lib/data/anim_jumps.dart', 'jumpAnimations',
      '40 jump animations (3 frames each).', out);
}

void buildIdles() {
  final out = Out();
  const pals = ['Green', 'Blue', 'Pink', 'Orange', 'Purple'];
  for (final c in walkers) {
    for (final p in pals) {
      out.add('${c.name} Idle ($p)', 'idles', 4, p, [
        snap(c, 0, 0, false, 0, 0, 0),
        snap(c, -1, 0, true, 0, 0, 0),
      ]);
    }
  }
  final objects = {
    'Coin': drawCoin,
    'Star': drawStar,
    'Heart': drawHeartObj,
    'Crystal': drawCrystal,
  };
  for (final e in objects.entries) {
    for (final p in pals) {
      out.add('${e.key} Idle ($p)', 'idles', 4, p, [
        snapFx(e.value, 0),
        snapFx(e.value, 1),
      ]);
    }
  }
  writeFile('lib/data/anim_idles.dart', 'idleAnimations',
      '100 idle animations (2 frames each).', out);
}

void buildAttacks() {
  final out = Out();
  const pals = ['Green', 'Blue', 'Pink', 'Orange', 'Purple', 'Red'];
  final attackers = walkers
      .where((c) => const {
            'Knight',
            'Robot',
            'Skeleton',
            'Slime',
            'Ghost',
            'Cat',
            'Alien',
            'Mushroom',
            'Bird',
            'Turtle'
          }.contains(c.name))
      .toList();
  for (final c in attackers) {
    for (final p in pals) {
      final frames = c.name == 'Slime'
          ? [
              snap(c, 0, 0, false, 0, 0, 0),
              snap(c, 0, 0, false, 0, -1, 2),
              snap(c, 0, 0, false, 0, 0, 0),
            ]
          : [
              snap(c, 0, 0, false, 1, 0, 0),
              snap(c, 0, 0, false, 2, 0, 1),
              snap(c, 0, 0, false, 0, 0, 0),
            ];
      out.add('${c.name} Attack ($p)', 'attacks', 8, p, frames);
    }
  }
  writeFile('lib/data/anim_attacks.dart', 'attackAnimations',
      '60 attack animations (3 frames each).', out);
}

void buildEffects() {
  final out = Out();
  const pals = ['Green', 'Blue', 'Orange', 'Purple', 'Red'];
  const kinds = {
    'Explosion': 4,
    'Sparkle': 3,
    'Smoke': 4,
    'Magic Burst': 4,
    'Flame': 4,
    'Splash': 3,
    'Zap': 4,
    'Heal': 3,
    'Poof': 4,
    'Shockwave': 3,
    'Embers': 4,
    'Bubbles': 4,
    'Slash': 3,
    'Confetti': 4,
    'Ring Pulse': 3,
    'Twinkle Stars': 4,
    'Falling Leaves': 4,
    'Snowfall': 4,
    'Beam': 3,
    'Nova': 3,
  };
  for (final e in kinds.entries) {
    for (final p in pals) {
      final frames = [
        for (var t = 0; t < e.value; t++) snapFx((g, tt) => drawEffect(g, e.key, tt), t),
      ];
      out.add('${e.key} ($p)', 'effects', 10, p, frames);
    }
  }
  writeFile('lib/data/anim_effects.dart', 'effectAnimations',
      '100 effect animations.', out);
}

void buildEmotes() {
  final out = Out();
  const pals = ['Green', 'Blue', 'Pink', 'Orange', 'Purple'];
  const kinds = {
    'Happy': 3,
    'Sad': 2,
    'Angry': 3,
    'In Love': 3,
    'Dizzy': 3,
    'Sleepy': 3,
    'Excited': 3,
    'Shy': 2,
  };
  for (final e in kinds.entries) {
    for (final p in pals) {
      final frames = [
        for (var t = 0; t < e.value; t++) snapFx((g, tt) => drawEmote(g, e.key, tt), t),
      ];
      out.add('${e.key} ($p)', 'emotes', 6, p, frames);
    }
  }
  writeFile('lib/data/anim_emotes.dart', 'emoteAnimations',
      '40 emote animations.', out);
}

void buildMisc() {
  final out = Out();
  const pals = ['Green', 'Blue', 'Orange', 'Purple', 'Red'];
  const kinds = {
    'Coin Spin': 4,
    'Star Spin': 4,
    'Shuriken': 2,
    'Heartbeat': 2,
    'Bouncy Ball': 4,
    'UFO Hover': 4,
    'Gear Turn': 2,
    'Crystal Shimmer': 2,
  };
  for (final e in kinds.entries) {
    for (final p in pals) {
      final frames = [
        for (var t = 0; t < e.value; t++) snapFx((g, tt) => drawMisc(g, e.key, tt), t),
      ];
      out.add('${e.key} ($p)', 'misc', 8, p, frames);
    }
  }
  writeFile('lib/data/anim_misc.dart', 'miscAnimations',
      '40 spin & misc animations.', out);
}

void main() {
  buildWalks();
  buildRuns();
  buildJumps();
  buildIdles();
  buildAttacks();
  buildEffects();
  buildEmotes();
  buildMisc();
  // ignore: avoid_print
  print('done');
}
