import 'package:flutter/material.dart';

import '../data/animation_library.dart';
import '../data/character_kits.dart';
import '../data/template_library.dart';
import '../theme/mutapixel_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/template_preview.dart';
import 'home_screen.dart';
import 'kit_screen.dart';
import 'ai_lab_screen.dart';
import '../data/ai_lab.dart';

/// The website's home page.
///
/// The site opens here: a landing page introducing Mutapixel, with the
/// full app (editor, animation studio, template library) one tap away
/// behind "Start Creating". Tapping the "Mutapixel" logo scrolls to top.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final ScrollController _scroll = ScrollController();
  final GlobalKey _galleryKey = GlobalKey();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _openApp() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _scrollToTop() {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollToGallery() {
    final ctx = _galleryKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = MutapixelTheme.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: GestureDetector(
          onTap: _scrollToTop,
          child: const Text('Mutapixel'),
        ),
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeController.mode,
            builder: (context, mode, _) => IconButton(
              tooltip: 'Toggle theme',
              icon: Icon(mode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode),
              onPressed: ThemeController.toggle,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _openApp,
              style: FilledButton.styleFrom(
                backgroundColor: MutapixelTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 10),
              ),
              child: const Text('Open App',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scroll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _hero(palette),
            _statsStrip(palette),
            _features(palette),
            _gallery(palette),
            _gameReadyBand(palette),
            _characterKitsSection(palette),
            _aiLabSection(palette),
            _finalCta(palette),
            _footer(palette),
          ],
        ),
      ),
    );
  }

  /// Hero: headline, subtext, CTAs and a featured sprite card.
  Widget _hero(MutapixelPalette palette) {
    final artCount = TemplateLibrary.all.length;
    final animCount = AnimationLibrary.all.length;
    final featured =
        TemplateLibrary.byCategory('detailed').first.toFrame();
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: MutapixelTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                  color:
                      MutapixelTheme.primary.withValues(alpha: 0.3)),
            ),
            child: Text(
              '$artCount art templates · $animCount animations',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: MutapixelTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Pixel art for\nyour next game.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 44,
              height: 1.05,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Draw characters, animate them, and export\ngame-ready sprite sheets — free in your browser.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: palette.secondaryText,
            ),
          ),
          const SizedBox(height: 26),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: _openApp,
                style: FilledButton.styleFrom(
                  backgroundColor: MutapixelTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 16),
                ),
                child: const Text('Start Creating',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              OutlinedButton(
                onPressed: _scrollToGallery,
                style: OutlinedButton.styleFrom(
                  foregroundColor: palette.ink,
                  side: BorderSide(color: palette.hairline),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 16),
                ),
                child: const Text('Browse Templates',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Featured sprite card.
          GestureDetector(
            onTap: _openApp,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    MutapixelTheme.primary.withValues(alpha: 0.16),
                    MutapixelTheme.primary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: palette.hairline),
              ),
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  SizedBox(
                    height: 220,
                    child: CustomPaint(
                      painter: TemplatePreview(frame: featured),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Hand-made pixel art, ready to remix',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: palette.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Three quick stats under the hero.
  Widget _statsStrip(MutapixelPalette palette) {
    final items = [
      ('${TemplateLibrary.all.length}', 'Art templates'),
      ('${AnimationLibrary.all.length}', 'Animations'),
      ('100%', 'Free to use'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 8),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(
              child: Column(
                children: [
                  Text(
                    items[i].$1,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: palette.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items[i].$2,
                    style: TextStyle(
                      fontSize: 13,
                      color: palette.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            if (i < items.length - 1)
              Container(
                  width: 1, height: 44, color: palette.hairline),
          ],
        ],
      ),
    );
  }

  /// Feature cards.
  Widget _features(MutapixelPalette palette) {
    final features = [
      (
        Icons.brush_outlined,
        'Pixel Editor',
        'Layers, mirror mode, pro palettes and a Photoshop-style color picker.'
      ),
      (
        Icons.movie_outlined,
        'Animation Studio',
        'Timeline, onion skin and per-frame timing for smooth game animation.'
      ),
      (
        Icons.file_download_outlined,
        'Game-Ready Export',
        'Sprite sheets plus JSON metadata tuned for Unity, Godot and Unreal.'
      ),
      (
        Icons.grid_view_outlined,
        'Template Library',
        'Heroes, monsters, items and effects — every one free to remix.'
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Everything you need to ship sprites',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.92,
            ),
            itemCount: features.length,
            itemBuilder: (context, i) {
              final f = features[i];
              return Container(
                decoration: MutapixelTheme.cardDecoration(context,
                    radius: MutapixelTheme.smallCardRadius),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: MutapixelTheme.primary
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(f.$1,
                          color: MutapixelTheme.primary, size: 22),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      f.$2,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        f.$3,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: palette.secondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Horizontal strip of real template art.
  Widget _gallery(MutapixelPalette palette) {
    final picks = [
      ...TemplateLibrary.byCategory('heroes').take(3),
      ...TemplateLibrary.byCategory('monsters').take(3),
      ...TemplateLibrary.byCategory('detailed').take(3),
      ...TemplateLibrary.byCategory('ultra').take(3),
    ];
    return Padding(
      key: _galleryKey,
      padding: const EdgeInsets.fromLTRB(0, 40, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fresh from the library',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: palette.ink,
                  ),
                ),
                TextButton(
                  onPressed: _openApp,
                  child: Text('Open app',
                      style: TextStyle(
                          color: MutapixelTheme.primary,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 148,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: picks.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final frame = picks[i].toFrame();
                return GestureDetector(
                  onTap: _openApp,
                  child: Container(
                    width: 128,
                    decoration: MutapixelTheme.cardDecoration(context,
                        radius: MutapixelTheme.smallCardRadius),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Expanded(
                          child: CustomPaint(
                            painter:
                                TemplatePreview(frame: frame),
                            child: const SizedBox.expand(),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          picks[i].name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: palette.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Game-ready highlight band.
  Widget _gameReadyBand(MutapixelPalette palette) {
    final heroes = AnimationLibrary.byCategory('gameready').take(4);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
      child: GestureDetector(
        onTap: _openApp,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2E9E5B).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: const Color(0xFF2E9E5B)
                    .withValues(alpha: 0.25)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E9E5B),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'GAME-READY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Animations tuned for real games',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: palette.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Per-frame timing, locked ground pivots and sprite-sheet export — drop them straight into your engine.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: palette.secondaryText,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 96,
                child: Row(
                  children: [
                    for (final h in heroes)
                      Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsets.only(right: 8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: palette.surface,
                              borderRadius:
                                  BorderRadius.circular(16),
                              border: Border.all(
                                  color: palette.hairline),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: CustomPaint(
                              painter: TemplatePreview(
                                  frame: h.frames.first),
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Character Kits: complete move sets, one download each.
  Widget _characterKitsSection(MutapixelPalette palette) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 40, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: MutapixelTheme.primary
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'NEW',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: MutapixelTheme.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Character Kits',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: palette.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'A whole character, not one walk cycle. Every kit ships the full move set — idle, walk, run, jump, attack and more — as game-ready sprite sheets.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: palette.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 260,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24),
              itemCount: characterKits.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final kit = characterKits[i];
                return GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => KitScreen(kit: kit)),
                  ),
                  child: Container(
                    width: 200,
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: palette.hairline),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: palette.background,
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            padding:
                                const EdgeInsets.all(8),
                            child: CustomPaint(
                              painter: TemplatePreview(
                                  frame: kit.coverFrame),
                              child:
                                  const SizedBox.expand(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          kit.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: palette.ink,
                          ),
                        ),
                        Text(
                          kit.tagline,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: palette.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${kit.actions.length} actions · ${kit.totalFrames} frames',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: MutapixelTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// AI Lab: themed drops of AI-forged pixel art.
  Widget _aiLabSection(MutapixelPalette palette) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 40, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: MutapixelTheme.primary
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'NEW',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: MutapixelTheme.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'AI Lab',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: palette.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Forged by AI, finished by you. Themed drops of AI-generated pixel art — open any piece in the editor to remix it, or download the PNG straight into your game.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: palette.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24),
              itemCount: aiPacks.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final pack = aiPacks[i];
                return GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) =>
                            AiLabScreen()),
                  ),
                  child: Container(
                    width: 300,
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: palette.hairline),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Image.asset(
                            pack.artworks.first.assetPath,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, _, __) =>
                                Container(
                              color: palette.hairline,
                              child: const Center(
                                child: Icon(
                                    Icons.image_not_supported),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                pack.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: palette.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                pack.tagline,
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      palette.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Final call to action.
  Widget _finalCta(MutapixelPalette palette) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
      child: Column(
        children: [
          Text(
            'Start creating today.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Free forever. No account needed.',
            style: TextStyle(
              fontSize: 15,
              color: palette.secondaryText,
            ),
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: _openApp,
            style: FilledButton.styleFrom(
              backgroundColor: MutapixelTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 36, vertical: 18),
            ),
            child: const Text('Open Mutapixel',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _footer(MutapixelPalette palette) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 32),
      child: Column(
        children: [
          Container(
              height: 1, color: palette.hairline),
          const SizedBox(height: 20),
          Text(
            'Mutapixel',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '© 2026 Mutation Games Development · Made for game makers',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: palette.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
