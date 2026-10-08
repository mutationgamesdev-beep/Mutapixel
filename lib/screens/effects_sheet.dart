import 'package:flutter/material.dart';

import '../models/sprite_frame.dart';
import '../services/sprite_effects.dart';
import '../theme/mutapixel_theme.dart';

/// Bottom sheet with one-tap "magic" effects.
/// Returns the transformed frame via Navigator.pop, or null if cancelled.
class EffectsSheet extends StatefulWidget {
  final SpriteFrame frame;
  final List<Color> paletteColors;

  const EffectsSheet({
    super.key,
    required this.frame,
    required this.paletteColors,
  });

  @override
  State<EffectsSheet> createState() => _EffectsSheetState();
}

class _EffectsSheetState extends State<EffectsSheet> {
  late SpriteFrame _preview;
  Color? _recolorFrom;
  Color _recolorTo = const Color(0xFFFF6B6B);

  @override
  void initState() {
    super.initState();
    _preview = SpriteFrame.clone(widget.frame);
  }

  void _apply(SpriteFrame Function(SpriteFrame) effect) {
    setState(() => _preview = effect(_preview));
  }

  @override
  Widget build(BuildContext context) {
    final spriteColors = SpriteEffects.paletteOf(widget.frame);
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Magic effects',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600)),
              ),
            ),
            // Live preview.
            Container(
              width: 120,
              height: 120,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: MutapixelTheme.cardDecoration(
                  radius: MutapixelTheme.smallCardRadius),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: CustomPaint(
                  painter: _EffectPreview(frame: _preview),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            // Effect buttons.
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _effectButton(
                    Icons.border_outer,
                    'Outline',
                    () => _apply((f) => SpriteEffects.addOutline(
                        f, const Color(0xFF14141F))),
                  ),
                  _effectButton(
                    Icons.layers,
                    'Shadow',
                    () => _apply(SpriteEffects.addDropShadow),
                  ),
                  _effectButton(
                    Icons.flip,
                    'Flip ↔',
                    () => _apply(SpriteEffects.flipHorizontal),
                  ),
                  _effectButton(
                    Icons.flip_camera_android,
                    'Flip ↕',
                    () => _apply(SpriteEffects.flipVertical),
                  ),
                ],
              ),
            ),
            // Recolor section.
            if (spriteColors.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Recolor',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                      'Pick a color in your sprite, then pick its replacement.',
                      style: TextStyle(
                          color: MutapixelTheme.secondaryText,
                          fontSize: 13)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    const Text('From: ',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                    for (final c in spriteColors.take(8))
                      _colorDot(c, _recolorFrom == c, () {
                        setState(() => _recolorFrom = c);
                      }),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    const Text('To: ',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                    for (final c in widget.paletteColors.take(10))
                      _colorDot(c,
                          _recolorTo.toARGB32() == c.toARGB32(),
                          () {
                        setState(() => _recolorTo = c);
                      }),
                    TextButton(
                      onPressed: _recolorFrom == null
                          ? null
                          : () => _apply((f) =>
                              SpriteEffects.recolor(
                                  f, _recolorFrom!, _recolorTo)),
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () =>
                        Navigator.of(context).pop(_preview),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _effectButton(
      IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: MutapixelTheme.subtleFill,
            borderRadius: BorderRadius.circular(999),
            border:
                Border.all(color: MutapixelTheme.hairline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 18, color: MutapixelTheme.ink),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: MutapixelTheme.ink)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _colorDot(Color color, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? MutapixelTheme.primary
                : MutapixelTheme.hairline,
            width: selected ? 3 : 1,
          ),
          boxShadow:
              selected ? MutapixelTheme.pillShadow : null,
        ),
      ),
    );
  }
}

class _EffectPreview extends CustomPainter {
  final SpriteFrame frame;
  _EffectPreview({required this.frame});

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
  bool shouldRepaint(_EffectPreview old) => old.frame != frame;
}
