import 'package:flutter/material.dart';

import '../data/template_library.dart';
import '../models/sprite_frame.dart';

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
          preferredSize: const Size.fromHeight(48),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                for (final c in TemplateLibrary.categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 8),
                    child: ChoiceChip(
                      label: Text(_label(c)),
                      selected: _category == c,
                      onSelected: (_) =>
                          setState(() => _category = c),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E28),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: CustomPaint(
                        painter: _TemplatePreview(frame: t.toFrame()),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      t.name,
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
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
