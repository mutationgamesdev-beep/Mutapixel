import 'dart:async';

import 'package:flutter/material.dart';

import '../data/palette_presets.dart';
import '../data/starter_templates.dart';
import '../data/template_library.dart';
import '../data/sprite_parts.dart';
import '../models/sprite_frame.dart';
import '../models/sprite_palette.dart';
import '../theme/mutapixel_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/pixel_canvas.dart';
import 'export_sheet.dart';
import 'templates_panel.dart';
import 'parts_sheet.dart';
import 'effects_sheet.dart';
import 'guided_builder.dart';

/// The main Mutapixel editor: canvas, tools, palettes and frames.
///
/// Opens blank by default; [initialTemplate] or [initialFrame] preload
/// the canvas (from the home screen).
class EditorScreen extends StatefulWidget {
  final ArtTemplate? initialTemplate;
  final SpriteFrame? initialFrame;
  final int initialCanvasSize;

  const EditorScreen({
    super.key,
    this.initialTemplate,
    this.initialFrame,
    this.initialCanvasSize = 16,
  });

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
  bool _railCollapsed = false;
  bool _templatesPanelOpen = false;

  /// Key for the canvas, used to convert drag-drop offsets to pixels.
  final GlobalKey _canvasKey = GlobalKey();

  /// Part selected for stamping (null when not in stamp mode).
  SpriteFrame? _stampPart;

  final List<SpriteFrame> _undoStack = [];

  SpriteFrame get _frame => _frames[_activeFrame];

  @override
  void initState() {
    super.initState();
    _drawColor = _palette.colors.first;
    // Preload from the home screen when provided.
    if (widget.initialFrame != null) {
      _canvasSize = widget.initialFrame!.width;
      _frames = [widget.initialFrame!];
    } else if (widget.initialTemplate != null) {
      final frame = widget.initialTemplate!.toFrame();
      _canvasSize = frame.width;
      _frames = [frame];
    } else {
      _canvasSize = widget.initialCanvasSize;
      _frames = [SpriteFrame(width: _canvasSize, height: _canvasSize)];
    }
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

  /// Toggles the right-side templates panel (replaces the old
  /// full-screen gallery navigation).
  void _toggleTemplatesPanel() {
    setState(() => _templatesPanelOpen = !_templatesPanelOpen);
  }

  /// Stamps [template] merged onto the current frame, centered on
  /// ([cx], [cy]) in canvas pixel coordinates. Clips at canvas edges.
  void _stampTemplateAt(ArtTemplate template, int cx, int cy) {
    final stamp = template.toFrame();
    final ox = cx - stamp.width ~/ 2;
    final oy = cy - stamp.height ~/ 2;
    for (var y = 0; y < stamp.height; y++) {
      for (var x = 0; x < stamp.width; x++) {
        final color = stamp.getPixel(x, y);
        if (color == null) continue;
        _frame.setPixel(ox + x, oy + y, color);
      }
    }
  }

  /// Stamps a template dropped from the panel onto the canvas.
  void _onTemplateDropped(ArtTemplate template, Offset globalOffset) {
    final renderObject =
        _canvasKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) return;
    final point = PixelCanvas.dropToPixel(
      canvasBox: renderObject,
      globalOffset: globalOffset,
      frame: _frame,
    );
    if (point == null) return;
    _pushUndo();
    setState(() {
      _stampTemplateAt(template, point.x, point.y);
    });
  }

  /// Tapping a panel card stamps the template centered on the canvas.
  void _onPanelTemplateTapped(ArtTemplate template) {
    _pushUndo();
    setState(() {
      _stampTemplateAt(
          template, _frame.width ~/ 2, _frame.height ~/ 2);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Stamped "${template.name}" — draw over it!'),
        duration: const Duration(seconds: 2),
      ),
    );
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
                title: const Text('Template panel'),
                subtitle:
                    const Text('Drag templates onto your canvas'),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() => _templatesPanelOpen = true);
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
          style: TextStyle(
            color: MutapixelTheme.of(context).secondaryText,
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
                      Border.all(color: MutapixelTheme.of(context).hairline),
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
        leading: IconButton(
          tooltip: 'Home',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Mutapixel'),
        actions: [
          IconButton(
            tooltip: 'Templates',
            icon: const Icon(Icons.grid_view),
            color: _templatesPanelOpen
                ? MutapixelTheme.primary
                : null,
            onPressed: _toggleTemplatesPanel,
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
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sideRail(),
          Expanded(
            child: Column(
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
          // Canvas area: tinted backdrop so the bordered canvas card pops.
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _canvasTint(context),
                borderRadius: BorderRadius.circular(20),
              ),
              child: DragTarget<ArtTemplate>(
                onWillAcceptWithDetails: (_) => true,
                onAcceptWithDetails: (details) =>
                    _onTemplateDropped(
                        details.data, details.offset),
                builder: (context, candidate, rejected) {
                  final dragging = candidate.isNotEmpty;
                  final dark = Theme.of(context).brightness ==
                      Brightness.dark;
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          MutapixelTheme.of(context).surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: dragging
                            ? MutapixelTheme.primary
                            : (dark
                                ? const Color(0x24FFFFFF)
                                : const Color(0xFFD8D8E0)),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: dark
                              ? const Color(0x40000000)
                              : const Color(0x14000000),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: PixelCanvas(
                      key: _canvasKey,
                      frame: _frame,
                      drawColor: _drawColor,
                      tool: _tool,
                      mirror: _mirror,
                      showGrid: _showGrid,
                      stampFrame: _stampPart,
                      onStrokeStart: _pushUndo,
                      onChanged: () => setState(() {}),
                      onColorPicked: (color) => setState(() {
                        _drawColor = color;
                        _tool = CanvasTool.pencil;
                      }),
                    ),
                  );
                },
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
                      color: MutapixelTheme.of(context).surface,
                      border: Border.all(
                        color: selected
                            ? MutapixelTheme.primary
                            : MutapixelTheme.of(context).hairline,
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
          // Palette bar.
          Container(
            margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: MutapixelTheme.cardDecoration(context, radius: MutapixelTheme.smallCardRadius),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: PopupMenuButton<SpritePalette>(
                      tooltip: 'Choose palette',
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              _palette.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: MutapixelTheme.of(context).secondaryText,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_drop_down,
                              color:
                                  MutapixelTheme.of(context).secondaryText),
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
                      ),
                    ),
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
                          if (_tool == CanvasTool.eraser ||
                              _tool == CanvasTool.eyedropper) {
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
                                  : MutapixelTheme.of(context).hairline,
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
          ),
          _templatesPanel(),
        ],
      ),
    );
  }

  /// Tint behind the canvas card so the bordered card pops.
  /// Light: #EDEDF2, dark: #0F0F12.
  Color _canvasTint(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0F0F12)
          : const Color(0xFFEDEDF2);

  /// Collapsible right-side templates panel (Canva style).
  ///
  /// Expanded: search + category chips + draggable template cards.
  /// Collapsed: a slim strip showing only the expand toggle.
  Widget _templatesPanel() {
    final palette = MutapixelTheme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: _templatesPanelOpen ? 280 : 52,
      margin: const EdgeInsets.fromLTRB(0, 12, 12, 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.hairline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: _templatesPanelOpen ? 12 : 6,
                  vertical: 5),
              child: Tooltip(
                message: _templatesPanelOpen
                    ? 'Hide templates'
                    : 'Show templates',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _toggleTemplatesPanel,
                    child: Container(
                      width:
                          _templatesPanelOpen ? 52 : 40,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _templatesPanelOpen
                            ? MutapixelTheme.primary
                                .withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _templatesPanelOpen
                            ? Icons.chevron_right
                            : Icons.chevron_left,
                        size: 20,
                        color: _templatesPanelOpen
                            ? MutapixelTheme.primary
                            : palette.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_templatesPanelOpen)
              Expanded(
                child: TemplatesPanel(
                  onTapTemplate: _onPanelTemplateTapped,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _frameActionButton(
      IconData icon, String tooltip, VoidCallback onPressed) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: MutapixelTheme.of(context).subtleFill,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon,
                size: 20, color: MutapixelTheme.of(context).ink),
          ),
        ),
      ),
    );
  }

  /// Collapsible vertical tool rail (Photoshop/Figma style).
  ///
  /// Expanded: tool buttons stacked vertically with a collapse toggle on
  /// top. Collapsed: a slim strip showing only the expand toggle.
  Widget _sideRail() {
    final palette = MutapixelTheme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: _railCollapsed ? 52 : 76,
      margin: const EdgeInsets.fromLTRB(12, 12, 0, 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.hairline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            _sideRailButton(
              icon: _railCollapsed
                  ? Icons.chevron_right
                  : Icons.chevron_left,
              tip: _railCollapsed
                  ? 'Expand tools'
                  : 'Collapse tools',
              onTap: () =>
                  setState(() => _railCollapsed = !_railCollapsed),
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 4),
              color: palette.hairline,
            ),
            if (!_railCollapsed)
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      _sideRailToolButton(CanvasTool.pencil,
                          Icons.brush, 'Pencil'),
                      _sideRailToolButton(CanvasTool.eraser,
                          Icons.auto_fix_high, 'Eraser'),
                      _sideRailToolButton(CanvasTool.fill,
                          Icons.format_color_fill, 'Fill'),
                      _sideRailToolButton(CanvasTool.eyedropper,
                          Icons.colorize, 'Eyedropper'),
                      Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        color: palette.hairline,
                      ),
                      _sideRailButton(
                        icon: Icons.flip,
                        tip: 'Mirror (symmetry)',
                        selected: _mirror,
                        onTap: () => setState(
                            () => _mirror = !_mirror),
                      ),
                      _sideRailButton(
                        icon: Icons.undo,
                        tip: 'Undo',
                        onTap:
                            _undoStack.isEmpty ? null : _undo,
                      ),
                      _sideRailButton(
                        icon: Icons.delete_outline,
                        tip: 'Clear frame',
                        onTap: () {
                          _pushUndo();
                          setState(() {
                            _frames[_activeFrame] = SpriteFrame(
                                width: _canvasSize,
                                height: _canvasSize);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sideRailToolButton(
      CanvasTool tool, IconData icon, String tip) {
    return _sideRailButton(
      icon: icon,
      tip: tip,
      selected: _tool == tool,
      onTap: () => setState(() {
        _tool = tool;
        if (tool != CanvasTool.stamp) _exitStampMode();
      }),
    );
  }

  Widget _sideRailButton({
    required IconData icon,
    required String tip,
    bool selected = false,
    VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    final palette = MutapixelTheme.of(context);
    final buttonWidth = _railCollapsed ? 40.0 : 52.0;
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: _railCollapsed ? 6 : 12, vertical: 5),
      child: Tooltip(
        message: tip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: buttonWidth,
              height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? MutapixelTheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                boxShadow: selected
                    ? MutapixelTheme.pillShadow
                    : null,
              ),
              child: Icon(
                icon,
                size: 20,
                color: selected
                    ? Colors.white
                    : enabled
                        ? palette.ink
                        : palette.secondaryText
                            .withValues(alpha: 0.5),
              ),
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
