import 'package:flutter/material.dart';

import 'animation_template.dart';
import 'sprite_frame.dart';

/// A complete, game-ready character: every action animation for one
/// character in a consistent style, bundled for one-click download.
///
/// Kits are the library's answer to "I need a whole character, not one
/// walk cycle" — idle, walk, run, jump, land, attack, hurt and death,
/// all sharing one palette, one ground pivot and one frame size.
@immutable
class CharacterKit {
  /// URL-safe id, e.g. 'ashen-blade'. Used for file names.
  final String id;

  /// Display name, e.g. 'Ashen Blade'.
  final String name;

  /// One-line hook shown on the kit card.
  final String tagline;

  /// Longer blurb shown on the kit detail page.
  final String description;

  /// Frame shown on the kit card (usually the idle pose).
  final SpriteFrame coverFrame;

  /// The kit's full move set, in display order.
  final List<AnimationTemplate> actions;

  const CharacterKit({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.coverFrame,
    required this.actions,
  }) : assert(actions.length >= 2, 'a kit needs at least 2 actions');

  /// Total frames across every action.
  int get totalFrames =>
      actions.fold(0, (sum, a) => sum + a.frames.length);

  /// Short action names for display, e.g. 'Idle' from 'Ashen Blade Idle'.
  static String shortActionName(String kitName, String actionName) {
    final prefix = '$kitName ';
    if (actionName.startsWith(prefix)) {
      return actionName.substring(prefix.length);
    }
    return actionName;
  }
}
