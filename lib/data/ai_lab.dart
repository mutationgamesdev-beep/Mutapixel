import '../models/ai_pack.dart';

/// The AI Lab's pack catalog. Pack 01: four dark-fantasy bosses,
/// generated with AI and curated by hand.
const aiPacks = <AiPack>[
  AiPack(
    id: 'abyssal-bosses',
    title: 'Abyssal Bosses',
    tagline: 'Pack 01 · 4 dark-fantasy bosses',
    description:
        'The first AI Lab drop: four boss-tier pieces forged by AI and '
        'hand-picked for detail — deep-sea horror, demon warlords, fungal '
        'colossi and stone kings. Open any piece in the editor and make it '
        'yours, or download the PNG straight into your game.',
    artworks: [
      AiArtwork(
        id: 'abyssal-leviathan',
        title: 'Abyssal Leviathan',
        blurb: 'Deep-sea serpent with bioluminescent markings',
        assetPath: 'assets/ai_lab/pack01/leviathan.png',
      ),
      AiArtwork(
        id: 'crimson-warlord',
        title: 'Crimson Warlord',
        blurb: 'Demon knight with a flaming greatsword',
        assetPath: 'assets/ai_lab/pack01/warlord.png',
      ),
      AiArtwork(
        id: 'fungal-colossus',
        title: 'Fungal Colossus',
        blurb: 'Towering spore horror glowing violet',
        assetPath: 'assets/ai_lab/pack01/colossus.png',
      ),
      AiArtwork(
        id: 'obsidian-golem-king',
        title: 'Obsidian Golem King',
        blurb: 'Volcanic-glass titan with lava cracks',
        assetPath: 'assets/ai_lab/pack01/golem.png',
      ),
    ],
  ),
];
