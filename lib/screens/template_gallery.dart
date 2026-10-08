import 'package:flutter/material.dart';

import '../data/template_library.dart';
import '../models/sprite_frame.dart';
import '../theme/mutapixel_theme.dart';

/// Canva-style template gallery: pick a ready-made sprite by category.
class TemplateGallery extends StatefulWidget {
  const TemplateGallery({super.key});

  @override
  State<TemplateGallery> createState() => _TemplateGalleryState();
}

class _TemplateGalleryState extends State<TemplateGallery> {
  String _category = TemplateLibrary.categories.first;

  @override
  Widget build(BuildContext context) {
    final templates = TemplateLibrary.byCategory(_category);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Templates'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final c in TemplateLibrary.categories)
                  Padding(
                    padding:
                        const EdgeInsets.only(right: 8, bottom: 12),
                    child: _CategoryChip(
                      label: _label(c),
                      selected: _category == c,
                      onSelected: () =>
                          setState(() => _category = c),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
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
            onTap: () => Navigator.of(context).pop(t),
            child: Container(
              decoration: MutapixelTheme.cardDecoration(context, radius: MutapixelTheme.smallCardRadius),
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: CustomPaint(
                        painter:
                            _TemplatePreview(frame: t.toFrame()),
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
                        color: MutapixelTheme.of(context).ink,
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
      ),
    );
  }

  String _label(String category) {
    switch (category) {
      case 'heroes':
        return 'Heroes';
      case 'monsters':
        return 'Monsters';
      case 'animals':
        return 'Animals';
      case 'items':
        return 'Items';
      case 'food':
        return 'Food';
      case 'nature':
        return 'Nature';
      case 'space':
        return 'Space';
      case 'faces':
        return 'Faces';
      default:
        return category;
    }
  }
}

/// Premium pill chip: selected = filled indigo, unselected = subtle gray.
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onSelected,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? MutapixelTheme.primary
                : MutapixelTheme.of(context).subtleFill,
            borderRadius: BorderRadius.circular(999),
            border: selected
                ? null
                : Border.all(color: MutapixelTheme.of(context).hairline),
            boxShadow:
                selected ? MutapixelTheme.pillShadow : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  selected ? FontWeight.w600 : FontWeight.w500,
              color: selected
                  ? Colors.white
                  : MutapixelTheme.of(context).ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders a frame scaled to fit, pixelated.
class _TemplatePreview extends CustomPainter {
  final SpriteFrame frame;
  _TemplatePreview({required this.frame});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / frame.width < size.height / frame.height
        ? size.width / frame.width
        : size.height / frame.height;
    final ox = (size.width - frame.width * s) / 2;
    final oy = (size.height - frame.height * s) / 2;
    for (var y = 0; y < frame.height; y++) {
      for (var x = 0; x < frame.width; x++) {
        final color = frame.getPixel(x, y);
        if (color == null) continue;
        canvas.drawRect(
          Rect.fromLTWH(ox + x * s, oy + y * s, s + 0.5, s + 0.5),
          Paint()..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_TemplatePreview old) => old.frame != frame;
}
