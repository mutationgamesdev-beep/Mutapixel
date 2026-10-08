import 'package:flutter/material.dart';

import '../data/template_library.dart';
import '../models/sprite_frame.dart';
import '../theme/mutapixel_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/template_preview.dart';
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
              '${TemplateLibrary.all.length} pixel-art templates, ready to remix.',
              style: TextStyle(
                fontSize: 15,
                color: palette.secondaryText,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _showSizePicker,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Create new'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
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
                ),
              ],
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
            // Template library.
            Text(
              'Start from a template',
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
                  _categoryChip('all', 'All'),
                  for (final c
                      in TemplateLibrary.categories)
                    _categoryChip(
                        c, TemplateLibrary.categoryLabel(c)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _templateGrid(),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(String value, String label) {
    final selected =
        _category == value && _query.trim().isEmpty;
    final palette = MutapixelTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => setState(() {
            _category = value;
            _query = '';
          }),
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
}
