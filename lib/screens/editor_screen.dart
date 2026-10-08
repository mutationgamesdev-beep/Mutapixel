import 'dart:async';

import 'package:flutter/material.dart';

import '../data/palette_presets.dart';
import '../data/starter_templates.dart';
import '../data/template_library.dart';
import '../data/sprite_parts.dart';
import '../models/sprite_frame.dart';
import '../models/sprite_palette.dart';
import '../theme/mutapixel_theme.dart';
import '../widgets/pixel_canvas.dart';
import 'export_sheet.dart';
import 'template_gallery.dart';
import 'parts_sheet.dart';
import 'effects_sheet.dart';
import 'guided_builder.dart';

/// The main Mutapixel editor: canvas, tools, palettes and frames.
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  static const _canvasSizes = [16, 32, 64, 128];

  List<SpriteFrame> _frames = [SpriteFrame(width: 16, height: 16)];
  int _activeFrame = 0;
  int _canvasSize = 16;

  SpritePalette _palette = PalettePresets.all.first;
  Color _drawColor = const Color(0xFFFFFFFF);

  CanvasTool _tool = CanvasTool.pencil;
  bool _mirror = false;
  bool _showGrid = true;

  /// Part selected for stamping (null when not in stamp mode).
  SpriteFrame? _stampPart;

  final List<SpriteFrame> _undoStack = [];

  SpriteFrame get _frame => _frames[_activeFrame];

  @override
  void initState() {
    super.initState();
    _drawColor = _palette.colors.first;
  }

  // ---------- undo ----------

  void _pushUndo() {
    _undoStack.add(SpriteFrame.clone(_frame));
    if (_undoStack.length > 50) _undoStack.removeAt(0);
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    setState(() {
      final snapshot = _undoStack.removeLast();
      _frames[_activeFrame] = snapshot;
    });
  }

  // ---------- frames ----------

  void _addFrame({bool duplicate = false}) {
    setState(() {
      _frames.add(duplicate
          ? SpriteFrame.clone(_frame)
          : SpriteFrame(width: _canvasSize, height: _canvasSize));
      _activeFrame = _frames.length - 1;
      _undoStack.clear();
    });
  }

  void _deleteFrame(int index) {
    if (_frames.length <= 1) return;
    setState(() {
      _frames.removeAt(index);
      if (_activeFrame >= _frames.length) {
        _activeFrame = _frames.length - 1;
      }
      _undoStack.clear();
    });
  }

  // ---------- canvas size & new sprite ----------

  void _resizeCanvas(int size) {
    if (size == _canvasSize) return;
    setState(() {
      _canvasSize = size;
      _frames = _frames.map((f) => f.resized(size, size)).toList();
      _undoStack.clear();
    });
  }

  void _newFromTemplate(StarterTemplate template) {
    final frame = template.toFrame();
    setState(() {
      _canvasSize = frame.width;
      _frames = [frame];
      _activeFrame = 0;
      _undoStack.clear();
    });
    Navigator.of(context).pop();
  }

  // ---------- Canva-style: templates, parts, effects, guided builder ----------

  Future<void> _openTemplateGallery() async {
    final template = await Navigator.of(context).push<ArtTemplate>(
      MaterialPageRoute(builder: (_) => const TemplateGallery()),
    );
    if (template == null) return;
    final frame = template.toFrame();
    setState(() {
      _canvasSize = frame.width;
      _frames = [frame];
      _activeFrame = 0;
      _undoStack.clear();
      _exitStampMode();
    });
  }

  Future<void> _openGuidedBuilder() async {
    final frame = await Navigator.of(context).push<SpriteFrame>(
      MaterialPageRoute(builder: (_) => const GuidedBuilder()),
    );
    if (frame == null) return;
    setState(() {
      _canvasSize = frame.width;
      _frames = [frame];
      _activeFrame = 0;
      _undoStack.clear();
      _exitStampMode();
    });
  }

  Future<void> _openPartsSheet() async {
    final part = await showModalBottomSheet<SpritePart>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const PartsSheet(),
    );
    if (part == null) return;
    setState(() {
      _stampPart = part.toFrame();
      _tool = CanvasTool.stamp;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tap the canvas to stamp the part.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _exitStampMode() {
    _stampPart = null;
    if (_tool == CanvasTool.stamp) _tool = CanvasTool.pencil;
  }

  Future<void> _openEffectsSheet() async {
    final result = await showModalBottomSheet<SpriteFrame>(
      context: context,
      isScrollControlled: true,
      builder: (context) => EffectsSheet(
        frame: _frame,
        paletteColors: _palette.colors,
      ),
    );
    if (result == null) return;
    _pushUndo();
    setState(() {
      _frames[_activeFrame] = result;
    });
  }

  void _newBlank(int size) {
    setState(() {
      _canvasSize = size;
      _frames = [SpriteFrame(width: size, height: size)];
      _activeFrame = 0;
      _undoStack.clear();
    });
    Navigator.of(context).pop();
  }

  void _showNewSpriteMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('New sprite',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w600)),
                ),
              ),
              _menuSectionLabel('Start easy'),
              ListTile(
                leading: const Icon(Icons.auto_awesome,
                    color: MutapixelTheme.primary),
                title: const Text('Character builder'),
                subtitle: const Text('Step-by-step: body, face, hat, colors'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openGuidedBuilder();
                },
              ),
              ListTile(
                leading: const Icon(Icons.grid_view,
                    color: MutapixelTheme.primary),
                title: const Text('Template gallery'),
                subtitle:
                    const Text('Heroes, monsters, animals, items and more'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openTemplateGallery();
                },
              ),
              const Divider(),
              _menuSectionLabel('Start from a template'),
              for (final t in StarterTemplates.all)
                ListTile(
                  leading: const Icon(Icons.image),
                  title: Text(t.name),
                  subtitle: Text(t.kind),
                  onTap: () => _newFromTemplate(t),
                ),
              const Divider(),
              _menuSectionLabel('Or start blank'),
              for (final size in _canvasSizes)
                ListTile(
                  leading: const Icon(Icons.grid_on),
                  title: Text('$size x $size'),
                  onTap: () => _newBlank(size),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            color: MutapixelTheme.secondaryText,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ---------- custom color ----------

  Future<void> _pickCustomColor() async {
    var r = (_drawColor.r * 255).round();
    var g = (_drawColor.g * 255).round();
    var b = (_drawColor.b * 255).round();
    final picked = await showDialog<Color>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text('Custom color'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, r, g, b),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: MutapixelTheme.hairline),
                ),
              ),
              const SizedBox(height: 12),
              for (final entry in [
                ('R', r, Colors.red),
                ('G', g, Colors.green),
                ('B', b, Colors.blue),
              ])
                Row(
                  children: [
                    SizedBox(width: 16, child: Text(entry.$1)),
                    Expanded(
                      child: Slider(
                        value: entry.$2.toDouble(),
                        max: 255,
                        divisions: 255,
                        activeColor: entry.$3,
                        onChanged: (v) => setDialog(() {
                          if (entry.$1 == 'R') {
                            r = v.round();
                          } else if (entry.$1 == 'G') {
                            g = v.round();
                          } else {
                            b = v.round();
                          }
                        }),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context)
                  .pop(Color.fromARGB(255, r, g, b)),
              child: const Text('Use color'),
            ),
          ],
        ),
      ),
    );
    if (picked != null) {
      setState(() => _drawColor = picked);
    }
  }

  // ---------- animation preview ----------

  void _showAnimationPreview() {
    Timer? timer;
    var index = 0;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) {
          timer ??= Timer.periodic(
            const Duration(milliseconds: 125),
            (_) {
              if (context.mounted) {
                setDialog(() => index = (index + 1) % _frames.length);
              }
            },
          );
          return AlertDialog(
            title: const Text('Animation preview'),
            content: SizedBox(
              width: 240,
              height: 240,
              child: CustomPaint(
                painter: _PreviewPainter(frame: _frames[index]),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  timer?.cancel();
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    ).then((_) => timer?.cancel());
  }

  // ---------- export ----------

  void _openExport() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ExportSheet(frames: _frames),
    );
  }

  // ---------- build ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mutapixel'),
        actions: [
          IconButton(
            tooltip: 'Templates',
            icon: const Icon(Icons.grid_view),
            onPressed: _openTemplateGallery,
          ),
          IconButton(
            tooltip: 'Parts',
            icon: const Icon(Icons.extension),
            onPressed: _openPartsSheet,
          ),
          IconButton(
            tooltip: 'Magic effects',
            icon: const Icon(Icons.auto_fix_high),
            onPressed: _openEffectsSheet,
          ),
          IconButton(
            tooltip: 'New sprite',
            icon: const Icon(Icons.add_box_outlined),
            onPressed: _showNewSpriteMenu,
          ),
          PopupMenuButton<int>(
            tooltip: 'Canvas size',
            icon: const Icon(Icons.aspect_ratio),
            onSelected: _resizeCanvas,
            itemBuilder: (context) => [
              for (final size in _canvasSizes)
                PopupMenuItem(
                  value: size,
                  child: Text('$size x $size'),
                ),
            ],
          ),
          IconButton(
            tooltip: 'Toggle grid',
            icon: Icon(
                _showGrid ? Icons.grid_on : Icons.grid_off),
            onPressed: () => setState(() => _showGrid = !_showGrid),
          ),
          if (_frames.length > 1)
            IconButton(
              tooltip: 'Preview animation',
              icon: const Icon(Icons.play_arrow),
              onPressed: _showAnimationPreview,
            ),
          IconButton(
            tooltip: 'Export',
            icon: const Icon(Icons.ios_share),
            onPressed: _openExport,
          ),
        ],
      ),
      body: Column(
        children: [
          // Stamp mode banner.
          if (_tool == CanvasTool.stamp)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: MutapixelTheme.primary
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: MutapixelTheme.primary
                      .withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.extension,
                      size: 18,
                      color: MutapixelTheme.primary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Stamp mode: tap the canvas to place.',
                        style: TextStyle(fontSize: 13)),
                  ),
                  TextButton(
                    onPressed: () =>
                        setState(() => _exitStampMode()),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          // Canvas in a premium white card.
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: MutapixelTheme.cardDecoration(),
              child: PixelCanvas(
                frame: _frame,
                drawColor: _drawColor,
                tool: _tool,
                mirror: _mirror,
                showGrid: _showGrid,
                stampFrame: _stampPart,
                onStrokeStart: _pushUndo,
                onChanged: () => setState(() {}),
              ),
            ),
          ),
          // Frame strip.
          SizedBox(
            height: 84,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _frames.length + 1,
              itemBuilder: (context, i) {
                if (i == _frames.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 14),
                    child: Row(
                      children: [
                        _frameActionButton(
                          Icons.add,
                          'Add frame',
                          () => _addFrame(),
                        ),
                        const SizedBox(width: 8),
                        _frameActionButton(
                          Icons.copy,
                          'Duplicate frame',
                          () => _addFrame(duplicate: true),
                        ),
                      ],
                    ),
                  );
                }
                final selected = i == _activeFrame;
                return GestureDetector(
                  onTap: () => setState(() {
                    _activeFrame = i;
                    _undoStack.clear();
                  }),
                  onLongPress: () => _deleteFrame(i),
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: MutapixelTheme.surface,
                      border: Border.all(
                        color: selected
                            ? MutapixelTheme.primary
                            : MutapixelTheme.hairline,
                        width: selected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: selected
                          ? MutapixelTheme.pillShadow
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: CustomPaint(
                        painter: _PreviewPainter(frame: _frames[i]),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Toolbar: segmented control rail.
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 4),
            child: Center(child: _toolRail()),
          ),
          // Palette bar.
          Container(
            margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: MutapixelTheme.cardDecoration(
                radius: MutapixelTheme.smallCardRadius),
            child: Column(
              children: [
                Row(
                  children: [
                    PopupMenuButton<SpritePalette>(
                      tooltip: 'Choose palette',
                      child: Row(
                        children: [
                          Text(
                            _palette.name,
                            style: const TextStyle(
                              color: MutapixelTheme.secondaryText,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down,
                              color:
                                  MutapixelTheme.secondaryText),
                        ],
                      ),
                      onSelected: (p) => setState(() {
                        _palette = p;
                        _drawColor = p.colors.first;
                      }),
                      itemBuilder: (context) => [
                        for (final p in PalettePresets.all)
                          PopupMenuItem(value: p, child: Text(p.name)),
                      ],
                    ),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.colorize, size: 18),
                      label: const Text('Custom'),
                      onPressed: _pickCustomColor,
                    ),
                  ],
                ),
                SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _palette.colors.length,
                    itemBuilder: (context, i) {
                      final color = _palette.colors[i];
                      final selected =
                          _sameColor(color, _drawColor);
                      return GestureDetector(
                        onTap: () => setState(() {
                          _drawColor = color;
                          if (_tool == CanvasTool.eraser) {
                            _tool = CanvasTool.pencil;
                          }
                        }),
                        child: Container(
                          width: 36,
                          height: 36,
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? MutapixelTheme.primary
                                  : MutapixelTheme.hairline,
                              width: selected ? 3 : 1,
                            ),
                            boxShadow: selected
                                ? MutapixelTheme.pillShadow
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SafeArea(child: SizedBox(height: 8)),
        ],
      ),
    );
  }

  Widget _frameActionButton(
      IconData icon, String tooltip, VoidCallback onPressed) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: MutapixelTheme.subtleFill,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon,
                size: 20, color: MutapixelTheme.ink),
          ),
        ),
      ),
    );
  }

  /// Segmented tool rail: selected tool is a filled indigo pill.
  Widget _toolRail() {
    return Container(
      decoration: BoxDecoration(
        color: MutapixelTheme.subtleFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MutapixelTheme.hairline),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _railToolButton(
              CanvasTool.pencil, Icons.brush, 'Pencil'),
          _railToolButton(
              CanvasTool.eraser, Icons.auto_fix_high, 'Eraser'),
          _railToolButton(
              CanvasTool.fill, Icons.format_color_fill, 'Fill'),
          _railToggleButton(
            Icons.flip,
            'Mirror (symmetry)',
            _mirror,
            () => setState(() => _mirror = !_mirror),
          ),
          _railToggleButton(
            Icons.undo,
            'Undo',
            false,
            _undoStack.isEmpty ? null : _undo,
          ),
          _railToggleButton(
            Icons.delete_outline,
            'Clear frame',
            false,
            () {
              _pushUndo();
              setState(() {
                _frames[_activeFrame] = SpriteFrame(
                    width: _canvasSize, height: _canvasSize);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _railToolButton(
      CanvasTool tool, IconData icon, String tip) {
    final selected = _tool == tool;
    return _railPill(
      tip: tip,
      selected: selected,
      onTap: () => setState(() => _tool = tool),
      icon: icon,
    );
  }

  Widget _railToggleButton(IconData icon, String tip, bool active,
      VoidCallback? onTap) {
    return _railPill(
      tip: tip,
      selected: active,
      onTap: onTap,
      icon: icon,
    );
  }

  Widget _railPill({
    required String tip,
    required bool selected,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return Tooltip(
      message: tip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? MutapixelTheme.primary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              boxShadow:
                  selected ? MutapixelTheme.pillShadow : null,
            ),
            child: Icon(
              icon,
              size: 20,
              color: selected
                  ? Colors.white
                  : enabled
                      ? MutapixelTheme.ink
                      : MutapixelTheme.secondaryText
                          .withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  bool _sameColor(Color a, Color b) =>
      a.toARGB32() == b.toARGB32();
}

/// Small static preview of a frame (thumbnails, animation dialog).
class _PreviewPainter extends CustomPainter {
  final SpriteFrame frame;

  _PreviewPainter({required this.frame});

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
  bool shouldRepaint(_PreviewPainter old) => old.frame != frame;
}
