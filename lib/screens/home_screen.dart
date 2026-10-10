import 'package:flutter/material.dart';

import '../data/animation_library.dart';
import '../data/template_library.dart';
import '../models/animation_template.dart';
import '../models/sprite_frame.dart';
import '../theme/mutapixel_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/template_preview.dart';
import 'animation_screen.dart';
import 'editor_screen.dart';
import 'guided_builder.dart';

/// Canva-style home page: the app's entry point.
///
/// Search templates, start from a blank canvas, browse the template
/// library, or launch the guided character builder.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _canvasSizes = [16, 32, 64, 128];

  String _category = 'all';
  String _query = '';
  String _animCategory = 'all';
  String _animQuery = '';

  List<ArtTemplate> get _visible {
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      return TemplateLibrary.all
          .where((t) => t.name.toLowerCase().contains(q))
          .toList();
    }
    if (_category == 'all') return TemplateLibrary.all;
    return TemplateLibrary.byCategory(_category);
  }

  List<AnimationTemplate> get _visibleAnims {
    final q = _animQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      return AnimationLibrary.all
          .where((t) => t.name.toLowerCase().contains(q))
          .toList();
    }
    if (_animCategory == 'all') return AnimationLibrary.all;
    return AnimationLibrary.byCategory(_animCategory);
  }

  void _openEditorBlank(int size) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditorScreen(initialCanvasSize: size),
      ),
    );
  }

  void _openEditorTemplate(ArtTemplate template) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditorScreen(initialTemplate: template),
      ),
    );
  }

  Future<void> _openGuidedBuilder() async {
    final frame = await Navigator.of(context).push<SpriteFrame>(
      MaterialPageRoute(builder: (_) => const GuidedBuilder()),
    );
    if (frame == null || !mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditorScreen(initialFrame: frame),
      ),
    );
  }

  void _openAnimation() {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => const AnimationScreen()),
    );
  }

  void _openAnimationTemplate(AnimationTemplate template) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnimationScreen(
          initialFrames: template.frames,
          initialFps: template.fps,
        ),
      ),
    );
  }

  Future<void> _showSizePicker() async {
    final size = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Canvas size'),
        children: [
          for (final s in _canvasSizes)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(s),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8),
                child: Text('$s x $s pixels',
                    style: const TextStyle(fontSize: 15)),
              ),
            ),
        ],
      ),
    );
    if (size != null && mounted) _openEditorBlank(size);
  }

  @override
  Widget build(BuildContext context) {
    final palette = MutapixelTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mutapixel'),
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
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero.
            const SizedBox(height: 8),
            Text(
              'What will you\ncreate today?',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                height: 1.15,
                letterSpacing: -0.5,
                color: palette.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${TemplateLibrary.all.length} art templates · ${AnimationLibrary.all.length} animation templates.',
              style: TextStyle(
                fontSize: 15,
                color: palette.secondaryText,
              ),
            ),
            const SizedBox(height: 20),
            // Two big entry cards: pixel art + animation.
            Row(
              children: [
                Expanded(
                  child: _bigCard(
                    title: 'Pixel Art',
                    subtitle: 'Draw & remix sprites',
                    icon: Icons.brush,
                    gradient: const [
                      Color(0xFF6C5CE7),
                      Color(0xFF4A3FB5),
                    ],
                    onTap: _showSizePicker,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _bigCard(
                    title: 'Animation',
                    subtitle: 'Bring sprites to life',
                    icon: Icons.movie,
                    gradient: const [
                      Color(0xFFE84393),
                      Color(0xFFB72C6E),
                    ],
                    onTap: _openAnimation,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _openGuidedBuilder,
              icon: const Icon(Icons.auto_awesome,
                  size: 20),
              label: const Text('Guided builder'),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    MutapixelTheme.primary,
                side: const BorderSide(
                    color: MutapixelTheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
              ),
            ),
            const SizedBox(height: 28),
            // Search.
            TextField(
              onChanged: (v) =>
                  setState(() => _query = v),
              style:
                  TextStyle(fontSize: 15, color: palette.ink),
              decoration: InputDecoration(
                hintText: 'Search templates...',
                hintStyle: TextStyle(
                    color: palette.secondaryText),
                prefixIcon: Icon(Icons.search,
                    color: palette.secondaryText),
                filled: true,
                fillColor: palette.surface,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      BorderSide(color: palette.hairline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                      color: MutapixelTheme.primary,
                      width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Art templates.
            Text(
              'Art Templates',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: palette.ink,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _categoryChip('all', 'All',
                      _category == 'all' && _query.isEmpty,
                      () => _selectCategory('all')),
                  for (final c
                      in TemplateLibrary.categories)
                    _categoryChip(
                        c,
                        TemplateLibrary.categoryLabel(c),
                        _category == c && _query.isEmpty,
                        () => _selectCategory(c)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _templateGrid(),
            const SizedBox(height: 28),
            // Animation templates.
            Text(
              'Animation Templates',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: palette.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap one to open it in the Animation Studio, ready to play and remix.',
              style: TextStyle(
                fontSize: 13,
                color: palette.secondaryText,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) =>
                  setState(() => _animQuery = v),
              style:
                  TextStyle(fontSize: 15, color: palette.ink),
              decoration: InputDecoration(
                hintText: 'Search animations...',
                hintStyle: TextStyle(
                    color: palette.secondaryText),
                prefixIcon: Icon(Icons.search,
                    color: palette.secondaryText),
                filled: true,
                fillColor: palette.surface,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      BorderSide(color: palette.hairline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                      color: MutapixelTheme.primary,
                      width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _categoryChip('all', 'All',
                      _animCategory == 'all' && _animQuery.isEmpty,
                      () => _selectAnimCategory('all')),
                  for (final c
                      in AnimationLibrary.categories)
                    _categoryChip(
                        c,
                        AnimationLibrary.categoryLabel(c),
                        _animCategory == c && _animQuery.isEmpty,
                        () => _selectAnimCategory(c)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _animationGrid(),
          ],
        ),
      ),
    );
  }

  void _selectCategory(String value) {
    setState(() {
      _category = value;
      _query = '';
    });
  }

  void _selectAnimCategory(String value) {
    setState(() {
      _animCategory = value;
      _animQuery = '';
    });
  }

  /// A big gradient entry card (Pixel Art / Animation).
  Widget _bigCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: MutapixelTheme.pillShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon,
                    size: 26, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white
                      .withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryChip(
      String value, String label, bool selected, VoidCallback onTap) {
    final palette = MutapixelTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? MutapixelTheme.primary
                  : palette.subtleFill,
              borderRadius: BorderRadius.circular(999),
              border: selected
                  ? null
                  : Border.all(color: palette.hairline),
              boxShadow: selected
                  ? MutapixelTheme.pillShadow
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected
                    ? FontWeight.w600
                    : FontWeight.w500,
                color: selected
                    ? Colors.white
                    : palette.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _templateGrid() {
    final templates = _visible;
    final palette = MutapixelTheme.of(context);
    if (templates.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'No templates found',
            style: TextStyle(
                fontSize: 15,
                color: palette.secondaryText),
          ),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: templates.length,
      itemBuilder: (context, i) {
        final t = templates[i];
        return GestureDetector(
          onTap: () => _openEditorTemplate(t),
          child: Container(
            decoration: MutapixelTheme.cardDecoration(
                context,
                radius: MutapixelTheme.smallCardRadius),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: CustomPaint(
                      painter:
                          TemplatePreview(frame: t.toFrame()),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      left: 8, right: 8, bottom: 10),
                  child: Text(
                    t.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: palette.ink,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Grid of animation templates. Each cell previews the first frame
  /// with a frame-count badge; tapping opens it in the Animation Studio.
  Widget _animationGrid() {
    final templates = _visibleAnims;
    final palette = MutapixelTheme.of(context);
    if (templates.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'No animations found',
            style: TextStyle(
                fontSize: 15,
                color: palette.secondaryText),
          ),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: templates.length,
      itemBuilder: (context, i) {
        final t = templates[i];
        return GestureDetector(
          onTap: () => _openAnimationTemplate(t),
          child: Container(
            decoration: MutapixelTheme.cardDecoration(
                context,
                radius: MutapixelTheme.smallCardRadius),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Stack(
                      children: [
                        CustomPaint(
                          painter: TemplatePreview(
                              frame: t.frames.first),
                          child: const SizedBox.expand(),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black
                                  .withValues(alpha: 0.65),
                              borderRadius:
                                  BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${t.frames.length} frames',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      left: 8, right: 8, bottom: 10),
                  child: Text(
                    t.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: palette.ink,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
