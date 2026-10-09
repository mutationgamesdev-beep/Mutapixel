import 'package:flutter/material.dart';

import 'sprite_frame.dart';

/// A ready-made multi-frame animation for the Animation Studio.
///
/// Frames are 16x16; [AnimationScreen] scales them to its canvas size
/// when loading.
class AnimationTemplate {
  final String name;
  final String category; // walks, runs, jumps, idles, attacks, effects, emotes, misc
  final List<SpriteFrame> frames; // 2-4 frames each
  final int fps; // suggested playback speed

  const AnimationTemplate({
    required this.name,
    required this.category,
    required this.frames,
    required this.fps,
  });
}

/// Builds [SpriteFrame]s from text rows, mirroring [ArtTemplate].
///
/// [colors] maps a character to an ARGB int ('.' is always transparent).
/// Used by the generated animation files in lib/data/anim_*.dart.
List<SpriteFrame> buildAnimFrames(
  Map<String, int> colors,
  List<List<String>> frameRows,
) {
  return [
    for (final rows in frameRows) _buildFrame(colors, rows),
  ];
}

SpriteFrame _buildFrame(Map<String, int> colors, List<String> rows) {
  final frame = SpriteFrame(width: 16, height: 16);
  for (var y = 0; y < 16 && y < rows.length; y++) {
    final row = rows[y];
    for (var x = 0; x < 16 && x < row.length; x++) {
      final ch = row[x];
      if (ch == '.') continue;
      final argb = colors[ch];
      if (argb != null) frame.setPixel(x, y, Color(argb));
    }
  }
  return frame;
}
