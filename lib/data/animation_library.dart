import '../models/animation_template.dart';
import 'anim_attacks.dart';
import 'anim_effects_a.dart';
import 'anim_effects_b.dart';
import 'anim_effects_c.dart';
import 'anim_effects_d.dart';
import 'anim_emotes.dart';
import 'anim_idles_a.dart';
import 'anim_idles_b.dart';
import 'anim_idles_c.dart';
import 'anim_idles_d.dart';
import 'anim_jumps.dart';
import 'anim_misc.dart';
import 'anim_runs.dart';
import 'anim_walks_a.dart';
import 'anim_walks_b.dart';
import 'anim_walks_c.dart';

/// The full animation-template library: 500 ready-made multi-frame
/// animations for the Animation Studio.
///
/// Generated content lives in the anim_*.dart files (see
/// tool/generate_animations.dart); this file only merges them.
class AnimationLibrary {
  static final List<AnimationTemplate> all = <AnimationTemplate>[
    ...walkAnimations_a,
    ...walkAnimations_b,
    ...walkAnimations_c,
    ...runAnimations,
    ...jumpAnimations,
    ...idleAnimations_a,
    ...idleAnimations_b,
    ...idleAnimations_c,
    ...idleAnimations_d,
    ...attackAnimations,
    ...effectAnimations_a,
    ...effectAnimations_b,
    ...effectAnimations_c,
    ...effectAnimations_d,
    ...emoteAnimations,
    ...miscAnimations,
  ];

  static const List<String> categories = [
    'walks',
    'runs',
    'jumps',
    'idles',
    'attacks',
    'effects',
    'emotes',
    'misc',
  ];

  static String categoryLabel(String category) {
    switch (category) {
      case 'walks':
        return 'Walks';
      case 'runs':
        return 'Runs';
      case 'jumps':
        return 'Jumps';
      case 'idles':
        return 'Idles';
      case 'attacks':
        return 'Attacks';
      case 'effects':
        return 'Effects';
      case 'emotes':
        return 'Emotes';
      case 'misc':
        return 'Spins & Misc';
      default:
        return category;
    }
  }

  static List<AnimationTemplate> byCategory(String category) =>
      all.where((t) => t.category == category).toList();
}
