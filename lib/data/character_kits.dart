import '../models/character_kit.dart';
import 'anim_gameready.dart';
import 'anim_knight.dart';

/// The Character Kit library: complete, game-ready move sets.
///
/// Kit 01 is the Ashen Blade ranger (the original game-ready pilot).
/// Kit 02 is the Ember Knight, built on the same skeletal rig.
/// New kits are added here as their animation files land in lib/data.
final ashenBladeKit = CharacterKit(
  id: 'ashen-blade',
  name: 'Ashen Blade',
  tagline: 'Swift ranger of the cinder wilds',
  description:
      'A hooded ranger with a wind-tossed cape and a quick blade. '
      'Eight hand-tuned actions on a locked ground pivot with per-frame '
      'timing — drop the sheets straight into your engine.',
  coverFrame: grIdle.frames[0],
  actions: [
    grIdle,
    grWalk,
    grRun,
    grJump,
    grLand,
    grAttack,
    grHurt,
    grDeath,
  ],
);

final emberKnightKit = CharacterKit(
  id: 'ember-knight',
  name: 'Ember Knight',
  tagline: 'Oathbound blade of the ember court',
  description:
      'A plate-armored knight with a crested helm, red plume and tower '
      'shield. Same rig and timing discipline as the Ashen Blade, so the '
      'two kits animate interchangeably in your game.',
  coverFrame: knIdle.frames[0],
  actions: [
    knIdle,
    knWalk,
    knRun,
    knJump,
    knLand,
    knAttack,
    knHurt,
    knDeath,
  ],
);

/// Every published kit, in release order.
final characterKits = <CharacterKit>[
  ashenBladeKit,
  emberKnightKit,
];
