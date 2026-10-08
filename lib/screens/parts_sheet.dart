import 'package:flutter/material.dart';

import '../data/sprite_parts.dart';
import '../models/sprite_frame.dart';

/// Bottom sheet: pick a mix-and-match part to stamp onto the canvas.
class PartsSheet extends StatefulWidget {
  const PartsSheet({super.key});

  @override
  State<PartsSheet> createState() => _PartsSheetState();
}

class _PartsSheetState extends State<PartsSheet> {
  String _category = 'eyes';

  static const _categories = ['eyes', 'mouths', 'hats', 'extras'];

  @override
  Widget build(BuildContext context) {
    final parts = SpriteParts.byCategory(_category);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Parts',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Tap a part, then tap the canvas to stamp it.',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                for (final c in _categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
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
          SizedBox(
            height: 220,
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.8,
              ),
              itemCount: parts.length,
              itemBuilder: (context, i) {
                final p = parts[i];
                return GestureDetector(
                  onTap: () => Navigator.of(context).pop(p),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E28),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: CustomPaint(
                              painter:
                                  _PartPreview(frame: p.toFrame()),
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(p.name,
                              style: const TextStyle(fontSize: 10),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
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

  String _label(String category) {
    switch (category) {
      case 'eyes':
        return 'Eyes';
      case 'mouths':
        return 'Mouths';
      case 'hats':
        return 'Hats';
      case 'extras':
        return 'Extras';
      default:
        return category;
    }
  }
}

class _PartPreview extends CustomPainter {
  final SpriteFrame frame;
  _PartPreview({required this.frame});

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
  bool shouldRepaint(_PartPreview old) => old.frame != frame;
}
