import 'package:flutter/material.dart';

import '../data/sprite_parts.dart';
import '../models/sprite_frame.dart';
import '../services/sprite_effects.dart';
import '../theme/mutapixel_theme.dart';

/// Step-by-step character builder for people who don't draw.
/// Body -> eyes -> mouth -> hat -> colors -> done.
class GuidedBuilder extends StatefulWidget {
  const GuidedBuilder({super.key});

  @override
  State<GuidedBuilder> createState() => _GuidedBuilderState();
}

class _GuidedBuilderState extends State<GuidedBuilder> {
  int _step = 0;

  static const _steps = ['Body', 'Eyes', 'Mouth', 'Hat', 'Colors'];
  static const _stepCategories = ['bodies', 'eyes', 'mouths', 'hats', null];

  SpritePart? _body;
  SpritePart? _eyes;
  SpritePart? _mouth;
  SpritePart? _hat;
  Color? _themeColor;

  static const _themes = [
    ('Slime Green', Color(0xFF3DDC84)),
    ('Ocean Blue', Color(0xFF4DA6FF)),
    ('Fire Red', Color(0xFFFF6B6B)),
    ('Royal Purple', Color(0xFFB366FF)),
    ('Sunny Yellow', Color(0xFFFFD93D)),
    ('Shadow', Color(0xFF3A3A4A)),
  ];

  SpriteFrame _buildFrame() {
    var frame = SpriteFrame(width: 16, height: 16);
    if (_body != null) {
      frame = SpriteEffects.stamp(frame, _body!.toFrame(), 0, 0);
    }
    if (_eyes != null) {
      final o = SpriteParts.defaultOffset['eyes']!;
      frame = SpriteEffects.stamp(frame, _eyes!.toFrame(), o[0], o[1]);
    }
    if (_mouth != null) {
      final o = SpriteParts.defaultOffset['mouths']!;
      frame = SpriteEffects.stamp(frame, _mouth!.toFrame(), o[0], o[1]);
    }
    if (_hat != null) {
      final o = SpriteParts.defaultOffset['hats']!;
      frame = SpriteEffects.stamp(frame, _hat!.toFrame(), o[0], o[1]);
    }
    if (_themeColor != null) {
      final dom = SpriteEffects.dominantColor(frame);
      if (dom != null) {
        frame = SpriteEffects.recolor(frame, dom, _themeColor!);
      }
    }
    return frame;
  }

  void _pick(SpritePart part) {
    setState(() {
      switch (_stepCategories[_step]) {
        case 'bodies':
          _body = part;
        case 'eyes':
          _eyes = part;
        case 'mouths':
          _mouth = part;
        case 'hats':
          _hat = part;
      }
      if (_step < _steps.length - 1) _step++;
    });
  }

  bool get _canContinue {
    if (_step == 0) return _body != null;
    return true; // eyes/mouth/hat/colors are optional
  }

  @override
  Widget build(BuildContext context) {
    final isColorStep = _step == _steps.length - 1;
    final parts = isColorStep
        ? <SpritePart>[]
        : SpriteParts.byCategory(_stepCategories[_step]!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Character Builder'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Step indicator.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                for (var i = 0; i < _steps.length; i++) ...[
                  _stepDot(i),
                  if (i < _steps.length - 1)
                    const Expanded(
                        child: _StepConnector()),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _stepTitle(),
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Step ${_step + 1} of ${_steps.length}',
              style: TextStyle(
                fontSize: 13,
                color: MutapixelTheme.of(context).secondaryText,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Live preview.
          Container(
            width: 160,
            height: 160,
            decoration: MutapixelTheme.cardDecoration(context, radius: MutapixelTheme.smallCardRadius),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: CustomPaint(
                painter: _BuilderPreview(frame: _buildFrame()),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Options.
          Expanded(
            child: isColorStep ? _themeGrid() : _partsGrid(parts),
          ),
          // Nav buttons.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _step == 0
                      ? null
                      : () => setState(() => _step--),
                  child: const Text('Back'),
                ),
                if (_step < _steps.length - 1)
                  FilledButton(
                    onPressed: _canContinue
                        ? () => setState(() => _step++)
                        : null,
                    child: const Text('Next'),
                  )
                else
                  FilledButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Finish'),
                    onPressed: _body == null
                        ? null
                        : () =>
                            Navigator.of(context).pop(_buildFrame()),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _stepTitle() {
    switch (_step) {
      case 0:
        return 'Pick a body';
      case 1:
        return 'Pick eyes';
      case 2:
        return 'Pick a mouth';
      case 3:
        return 'Pick a hat (optional)';
      case 4:
        return 'Pick a color theme';
      default:
        return '';
    }
  }

  Widget _stepDot(int i) {
    final done = i < _step;
    final current = i == _step;
    final filled = done || current;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled
            ? MutapixelTheme.primary
            : MutapixelTheme.of(context).subtleFill,
        border: filled
            ? null
            : Border.all(color: MutapixelTheme.of(context).hairline),
        boxShadow: current ? MutapixelTheme.pillShadow : null,
      ),
      child: Center(
        child: done
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : Text('${i + 1}',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: current
                        ? Colors.white
                        : MutapixelTheme.of(context).secondaryText)),
      ),
    );
  }

  Widget _partsGrid(List<SpritePart> parts) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: parts.length,
      itemBuilder: (context, i) {
        final p = parts[i];
        final selected = _isSelected(p);
        return GestureDetector(
          onTap: () => _pick(p),
          child: Container(
            decoration: BoxDecoration(
              color: MutapixelTheme.of(context).surface,
              borderRadius: BorderRadius.circular(
                  MutapixelTheme.smallCardRadius),
              border: Border.all(
                color: selected
                    ? MutapixelTheme.primary
                    : MutapixelTheme.of(context).hairline,
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? MutapixelTheme.pillShadow
                  : const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: CustomPaint(
                      painter: _BuilderPreview(frame: p.toFrame()),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(p.name,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: MutapixelTheme.of(context).ink)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isSelected(SpritePart p) {
    switch (_stepCategories[_step]) {
      case 'bodies':
        return _body == p;
      case 'eyes':
        return _eyes == p;
      case 'mouths':
        return _mouth == p;
      case 'hats':
        return _hat == p;
      default:
        return false;
    }
  }

  Widget _themeGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: _themes.length,
      itemBuilder: (context, i) {
        final theme = _themes[i];
        final selected = _themeColor?.toARGB32() == theme.$2.toARGB32();
        return GestureDetector(
          onTap: () => setState(() => _themeColor = theme.$2),
          child: Container(
            decoration: BoxDecoration(
              color: MutapixelTheme.of(context).surface,
              borderRadius: BorderRadius.circular(
                  MutapixelTheme.smallCardRadius),
              border: Border.all(
                color: selected
                    ? MutapixelTheme.primary
                    : MutapixelTheme.of(context).hairline,
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? MutapixelTheme.pillShadow
                  : const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.$2,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: MutapixelTheme.of(context).hairline),
                  ),
                ),
                const SizedBox(height: 6),
                Text(theme.$1,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: MutapixelTheme.of(context).ink)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: MutapixelTheme.of(context).hairline,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}

class _BuilderPreview extends CustomPainter {
  final SpriteFrame frame;
  _BuilderPreview({required this.frame});

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
  bool shouldRepaint(_BuilderPreview old) => old.frame != frame;
}
