import 'dart:async';

import 'package:flutter/material.dart';

import '../data/palette_presets.dart';
import '../data/starter_templates.dart';
import '../models/sprite_frame.dart';
import '../models/sprite_palette.dart';
import '../widgets/pixel_canvas.dart';
import 'export_sheet.dart';

/// The main Sprite Builder editor: canvas, tools, palettes and frames.
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('New sprite',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Start from a template',
                    style: TextStyle(color: Colors.white70)),
              ),
            ),
            for (final t in StarterTemplates.all)
              ListTile(
                leading: const Icon(Icons.image),
                title: Text(t.name),
                subtitle: Text(t.kind),
                onTap: () => _newFromTemplate(t),
              ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Or start blank',
                    style: TextStyle(color: Colors.white70)),
              ),
            ),
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
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
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
          // Canvas.
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF14141C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: PixelCanvas(
                frame: _frame,
                drawColor: _drawColor,
                tool: _tool,
                mirror: _mirror,
                showGrid: _showGrid,
                onStrokeStart: _pushUndo,
                onChanged: () => setState(() {}),
              ),
            ),
          ),
          // Frame strip.
          SizedBox(
            height: 76,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _frames.length + 1,
              itemBuilder: (context, i) {
                if (i == _frames.length) {
                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Add frame',
                          icon: const Icon(Icons.add),
                          onPressed: () => _addFrame(),
                        ),
                        IconButton(
                          tooltip: 'Duplicate frame',
                          icon: const Icon(Icons.copy),
                          onPressed: () => _addFrame(duplicate: true),
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
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white24,
                        width: selected ? 2.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: CustomPaint(
                        painter: _PreviewPainter(frame: _frames[i]),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Toolbar.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _toolButton(CanvasTool.pencil, Icons.brush, 'Pencil'),
                _toolButton(CanvasTool.eraser, Icons.auto_fix_high, 'Eraser'),
                _toolButton(CanvasTool.fill, Icons.format_color_fill, 'Fill'),
                IconButton(
                  tooltip: 'Mirror (symmetry)',
                  icon: const Icon(Icons.flip),
                  color: _mirror
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  onPressed: () =>
                      setState(() => _mirror = !_mirror),
                ),
                IconButton(
                  tooltip: 'Undo',
                  icon: const Icon(Icons.undo),
                  onPressed: _undoStack.isEmpty ? null : _undo,
                ),
                IconButton(
                  tooltip: 'Clear frame',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    _pushUndo();
                    setState(() {
                      _frames[_activeFrame] = SpriteFrame(
                          width: _canvasSize, height: _canvasSize);
                    });
                  },
                ),
              ],
            ),
          ),
          // Palette bar.
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              children: [
                Row(
                  children: [
                    PopupMenuButton<SpritePalette>(
                      tooltip: 'Choose palette',
                      child: Row(
                        children: [
                          Text(_palette.name,
                              style:
                                  const TextStyle(color: Colors.white70)),
                          const Icon(Icons.arrow_drop_down,
                              color: Colors.white70),
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
                                  ? Colors.white
                                  : Colors.white24,
                              width: selected ? 3 : 1,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          SafeArea(child: Container()),
        ],
      ),
    );
  }

  Widget _toolButton(CanvasTool tool, IconData icon, String tip) {
    final selected = _tool == tool;
    return IconButton(
      tooltip: tip,
      icon: Icon(icon),
      color: selected ? Theme.of(context).colorScheme.primary : null,
      onPressed: () => setState(() => _tool = tool),
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
