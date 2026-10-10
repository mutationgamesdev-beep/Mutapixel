import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/art_layer.dart';
import '../models/sprite_frame.dart';
import '../data/sprite_parts.dart';
import '../data/template_library.dart';
import '../data/animation_library.dart';
import '../theme/mutapixel_theme.dart';
import '../widgets/photoshop_color_picker.dart';
import '../widgets/pixel_canvas.dart';
import '../widgets/template_preview.dart';
import 'animation_screen.dart';
import 'effects_sheet.dart';
import 'export_sheet.dart';
import 'layers_sheet.dart';
import 'parts_sheet.dart';

/// The pixel art editor: single canvas, Photoshop-style layers.
///
/// Drawing tools paint on the active layer only; stamping a part or
/// template creates a new layer that can be repositioned with the
/// Move tool. Everything (pixels, layers, moves) is undoable.
/// Popping the screen returns the flattened frame (used by the
/// Animation Studio when editing a frame).
class EditorScreen extends StatefulWidget {
  final ArtTemplate? initialTemplate;
  final SpriteFrame? initialFrame;
  final int initialCanvasSize;

  /// When true the canvas-size control is hidden (Animation Studio
  /// keeps every frame the same size).
  final bool lockCanvasSize;

  const EditorScreen({
    super.key,
    this.initialTemplate,
    this.initialFrame,
    this.initialCanvasSize = 16,
    this.lockCanvasSize = false,
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  // ---------- layers ----------
  List<ArtLayer> _layers = [];
  int _activeLayer = 0;
  int _canvasSize = 16;

  SpriteFrame get _frame => _layers[_activeLayer].frame;

  // ---------- undo ----------
  final List<List<ArtLayer>> _undoStack = [];

  void _pushUndo() {
    _undoStack.add([for (final l in _layers) l.clone()]);
    if (_undoStack.length > 50) _undoStack.removeAt(0);
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    setState(() {
      _layers = _undoStack.removeLast();
      if (_activeLayer >= _layers.length) {
        _activeLayer = _layers.length - 1;
      }
    });
  }

  // ---------- tools ----------
  Color _drawColor = MutapixelTheme.primary;
  CanvasTool _tool = CanvasTool.pencil;
  bool _mirror = false;
  bool _showGrid = true;
  bool _panelCollapsed = false;

  SpritePart? _stampPart;

  /// Right panel tab: 0 = Templates, 1 = Parts, 2 = Animations.
  int _panelTab = 0;

  final GlobalKey _canvasKey = GlobalKey();
  final GlobalKey<PixelCanvasState> _selectionKey =
      GlobalKey<PixelCanvasState>();

  /// Whether the selection tool has an active selection (drives the
  /// options popup).
  bool _hasSelection = false;

  final List<Color> _defaultPalette = const [
    Colors.transparent,
    Color(0xFF000000),
    Color(0xFF1D2B53),
    Color(0xFF7E2553),
    Color(0xFF008751),
    Color(0xFFAB5236),
    Color(0xFF5F574F),
    Color(0xFFC2C3C7),
    Color(0xFFFFFFFF),
    Color(0xFFFF004D),
    Color(0xFFFFA300),
    Color(0xFFFFEC27),
    Color(0xFF00E436),
    Color(0xFF29ADFF),
    Color(0xFF83769C),
    Color(0xFFFF77A8),
  ];

  final List<Color> _customColors = [];

  @override
  void initState() {
    super.initState();
    _canvasSize = widget.initialCanvasSize;
    if (widget.initialFrame != null) {
      _layers = [
        ArtLayer(
            name: 'Background',
            frame: SpriteFrame.clone(widget.initialFrame!)),
      ];
    } else if (widget.initialTemplate != null) {
      final t = widget.initialTemplate!;
      _layers = [
        ArtLayer(name: t.name, frame: t.toFrame()),
      ];
      _canvasSize = t.toFrame().width;
    } else {
      _layers = [
        ArtLayer(
            name: 'Background',
            frame: SpriteFrame(
                width: _canvasSize, height: _canvasSize)),
      ];
    }
  }

  // ---------- layer operations ----------
  void _addLayer(String name) {
    _pushUndo();
    setState(() {
      _layers.add(ArtLayer(
          name: name,
          frame: SpriteFrame(
              width: _canvasSize, height: _canvasSize)));
      _activeLayer = _layers.length - 1;
    });
  }

  /// Stamps a part/template as a NEW full-canvas layer positioned at
  /// the tapped point, then switches to the Move tool so the user
  /// can drag it into place right away.
  void _addStampLayer(SpriteFrame part, String name, int cx, int cy) {
    _pushUndo();
    final layer =
        SpriteFrame(width: _canvasSize, height: _canvasSize);
    final ox = cx - part.width ~/ 2;
    final oy = cy - part.height ~/ 2;
    for (var y = 0; y < part.height; y++) {
      for (var x = 0; x < part.width; x++) {
        final c = part.getPixel(x, y);
        if (c == null) continue;
        layer.setPixel(ox + x, oy + y, c);
      }
    }
    setState(() {
      _layers.add(ArtLayer(name: name, frame: layer));
      _activeLayer = _layers.length - 1;
      _tool = CanvasTool.move;
    });
  }

  void _deleteLayer(int i) {
    if (_layers.length <= 1) return;
    _pushUndo();
    setState(() {
      _layers.removeAt(i);
      if (_activeLayer >= _layers.length) {
        _activeLayer = _layers.length - 1;
      }
    });
  }

  void _duplicateLayer(int i) {
    _pushUndo();
    setState(() {
      final copy = _layers[i].clone()
        ..name = '${_layers[i].name} copy';
      _layers.insert(i + 1, copy);
      _activeLayer = i + 1;
    });
  }

  void _mergeDown(int i) {
    if (i <= 0) return;
    _pushUndo();
    setState(() {
      _layers[i - 1].frame =
          ArtLayer.flatten([_layers[i - 1], _layers[i]]);
      _layers.removeAt(i);
      _activeLayer = i - 1;
    });
  }

  void _moveLayer(int from, int to) {
    if (from == to ||
        from < 0 ||
        to < 0 ||
        from >= _layers.length ||
        to >= _layers.length) {
      return;
    }
    _pushUndo();
    final active = _layers[_activeLayer];
    setState(() {
      final l = _layers.removeAt(from);
      _layers.insert(to, l);
      _activeLayer = _layers.indexOf(active);
    });
  }

  void _toggleLayerVisibility(int i) =>
      setState(() => _layers[i].visible = !_layers[i].visible);

  void _setLayerOpacity(int i, double v) =>
      setState(() => _layers[i].opacity = v.clamp(0.0, 1.0));

  void _selectLayer(int i) => setState(() => _activeLayer = i);

  Future<void> _openLayersSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: MutapixelTheme.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => LayersSheet(
        layers: _layers,
        activeLayer: _activeLayer,
        onAddLayer: () =>
            _addLayer('Layer ${_layers.length + 1}'),
        onSelect: _selectLayer,
        onToggleVisibility: _toggleLayerVisibility,
        onDuplicate: _duplicateLayer,
        onMergeDown: _mergeDown,
        onDelete: _deleteLayer,
        onMove: _moveLayer,
        onOpacity: _setLayerOpacity,
      ),
    );
  }

  // ---------- document operations ----------
  void _resizeCanvas(int size) {
    if (size == _canvasSize) return;
    setState(() {
      _canvasSize = size;
      _layers = [
        for (final l in _layers)
          ArtLayer(
            name: l.name,
            frame: l.frame.resized(size, size),
            visible: l.visible,
            opacity: l.opacity,
          ),
      ];
      _undoStack.clear();
    });
  }

  void _resetLayers(SpriteFrame first, {String name = 'Background'}) {
    setState(() {
      _layers = [ArtLayer(name: name, frame: first)];
      _activeLayer = 0;
      _canvasSize = first.width;
      _undoStack.clear();
      _stampPart = null;
      _tool = CanvasTool.pencil;
    });
  }

  void _newBlank(int size) {
    _resetLayers(SpriteFrame(width: size, height: size));
    Navigator.of(context).pop();
  }

  void _openNewSpriteMenu() {
    final palette = MutapixelTheme.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.hairline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('New sprite',
                  style:
                      TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ...[16, 32, 64].map(
                (size) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    onPressed: () => _newBlank(size),
                    child: Text('$size x $size'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- stamping ----------
  void _exitStampMode() {
    _stampPart = null;
    if (_tool == CanvasTool.stamp) _tool = CanvasTool.pencil;
  }

  Future<void> _openPartsSheet() async {
    final part = await showModalBottomSheet<SpritePart>(
      context: context,
      isScrollControlled: true,
      backgroundColor: MutapixelTheme.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const PartsSheet(),
    );
    if (part == null) return;
    setState(() {
      _stampPart = part;
      _tool = CanvasTool.stamp;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Stamp mode: tap the canvas to place "${part.name}".')),
    );
  }

  Future<void> _openEffectsSheet() async {
    final result = await showModalBottomSheet<SpriteFrame>(
      context: context,
      isScrollControlled: true,
      backgroundColor: MutapixelTheme.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => EffectsSheet(
        frame: _frame,
        paletteColors: [
          ..._defaultPalette.where((c) => c != Colors.transparent),
          ..._customColors,
        ],
      ),
    );
    if (result == null) return;
    _pushUndo();
    setState(() => _layers[_activeLayer].frame = result);
  }

  // ---------- export ----------
  void _openExport() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: MutapixelTheme.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => ExportSheet(
        frames: [ArtLayer.flatten(_layers)],
        layers: _layers.length > 1 ? _layers : null,
      ),
    );
  }

  void _clearLayer() {
    _pushUndo();
    setState(() => _layers[_activeLayer].frame =
        SpriteFrame(width: _canvasSize, height: _canvasSize));
  }

  // ---------- canvas helpers ----------
  math.Point<int>? _dropToPixel(Offset globalOffset) {
    final box =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    return PixelCanvas.dropToPixel(
      canvasBox: box,
      globalOffset: globalOffset,
      frame: _frame,
    );
  }

  void _onTemplateDropped(ArtTemplate template, Offset globalOffset) {
    final point = _dropToPixel(globalOffset);
    if (point == null) return;
    _addStampLayer(
        template.toFrame(), template.name, point.x, point.y);
  }

  void _onPanelTemplateTapped(ArtTemplate template) {
    final center = _canvasSize ~/ 2;
    _addStampLayer(template.toFrame(), template.name, center, center);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Stamped "${template.name}" as a new layer — drag to position it.')),
    );
  }

  // ---------- UI ----------
  void _pickCustomColor() async {
    final picked = await showPhotoshopColorPicker(
      context: context,
      initialColor: _drawColor,
    );
    if (picked == null) return;
    setState(() {
      _drawColor = picked;
      if (!_customColors.any((c) => c.toARGB32() == picked.toARGB32())) {
        _customColors.add(picked);
      }
    });
  }

  Widget _sideRailToolButton(
      CanvasTool tool, IconData icon, String tooltip) {
    final palette = MutapixelTheme.of(context);
    final selected = _tool == tool;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (tool != CanvasTool.stamp) _exitStampMode();
          setState(() => _tool = tool);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: selected
                ? MutapixelTheme.primary.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon,
              size: 22,
              color: selected
                  ? MutapixelTheme.primary
                  : palette.secondaryText),
        ),
      ),
    );
  }

  Widget _sideRailActionButton(
      {required IconData icon,
      required String tooltip,
      VoidCallback? onPressed}) {
    final palette = MutapixelTheme.of(context);
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon,
              size: 22,
              color: enabled
                  ? palette.secondaryText
                  : palette.secondaryText.withValues(alpha: 0.3)),
        ),
      ),
    );
  }

  Widget _buildSideRail() {
    final palette = MutapixelTheme.of(context);
    return Container(
      width: 64,
      margin: const EdgeInsets.fromLTRB(8, 8, 0, 8),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.hairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _sideRailToolButton(
                CanvasTool.pencil, Icons.brush, 'Pencil'),
            _sideRailToolButton(
                CanvasTool.eraser, Icons.auto_fix_normal, 'Eraser'),
            _sideRailToolButton(
                CanvasTool.fill, Icons.format_color_fill, 'Fill'),
            _sideRailToolButton(CanvasTool.eyedropper,
                Icons.colorize, 'Eyedropper'),
            _sideRailToolButton(
                CanvasTool.move, Icons.open_with, 'Move'),
            _sideRailToolButton(
                CanvasTool.select, Icons.select_all, 'Select'),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Container(
                  height: 1,
                  width: 32,
                  color: palette.hairline),
            ),
            _sideRailActionButton(
              icon: Icons.flip,
              tooltip: _mirror ? 'Mirror off' : 'Mirror on',
              onPressed: () =>
                  setState(() => _mirror = !_mirror),
            ),
            _sideRailActionButton(
              icon: Icons.undo,
              tooltip: 'Undo',
              onPressed: _undoStack.isEmpty ? null : _undo,
            ),
            _sideRailActionButton(
              icon: Icons.delete_outline,
              tooltip: 'Clear layer',
              onPressed: _clearLayer,
            ),
            _sideRailActionButton(
              icon: _showGrid ? Icons.grid_on : Icons.grid_off,
              tooltip: 'Toggle grid',
              onPressed: () =>
                  setState(() => _showGrid = !_showGrid),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatesPanel() {
    final palette = MutapixelTheme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _panelCollapsed ? 0 : 132,
      child: _panelCollapsed
          ? const SizedBox.shrink()
          : Container(
              margin: const EdgeInsets.fromLTRB(0, 8, 8, 8),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: palette.hairline),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(12, 12, 4, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('Library',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: palette.secondaryText)),
                        ),
                        InkWell(
                          borderRadius:
                              BorderRadius.circular(8),
                          onTap: () => setState(
                              () => _panelCollapsed = true),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.chevron_right,
                                size: 18,
                                color: palette.secondaryText),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tabs: Templates | Parts | Animations (vertical).
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(8, 4, 8, 8),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        _panelTabButton(0, 'Templates', palette),
                        const SizedBox(height: 6),
                        _panelTabButton(1, 'Parts', palette),
                        const SizedBox(height: 6),
                        _panelTabButton(2, 'Animations', palette),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _panelTab == 0
                        ? _buildPanelTemplates(palette)
                        : _panelTab == 1
                            ? _buildPanelParts(palette)
                            : _buildPanelAnimations(palette),
                  ),
                ],
              ),
            ),
    );
  }

  /// A tab button for the right library panel (full-width, vertical).
  Widget _panelTabButton(
      int index, String label, MutapixelPalette palette) {
    final selected = _panelTab == index;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => _panelTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? MutapixelTheme.primary
              : palette.subtleFill,
          borderRadius: BorderRadius.circular(10),
          border: selected
              ? null
              : Border.all(color: palette.hairline),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : palette.ink,
          ),
        ),
      ),
    );
  }

  /// Small badge showing pixel dimensions, top-right on thumbnails.
  Widget _sizeBadge(String label) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Templates tab content (art templates, as before).
  Widget _buildPanelTemplates(MutapixelPalette palette) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      itemCount: TemplateLibrary.all.length,
      itemBuilder: (context, i) {
        final template = TemplateLibrary.all[i];
        final frame = template.toFrame();
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: LongPressDraggable<ArtTemplate>(
            data: template,
            feedback: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 64,
                height: 64,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: CustomPaint(
                  painter:
                      TemplatePreview(frame: frame),
                ),
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _onPanelTemplateTapped(template),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: palette.subtleFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.hairline),
                ),
                child: Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: Stack(
                        children: [
                          CustomPaint(
                            painter: TemplatePreview(
                                frame: frame),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: _sizeBadge(
                                '${frame.width}×${frame.height}'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      template.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Parts tab content: tap a part to enter stamp mode.
  Widget _buildPanelParts(MutapixelPalette palette) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      itemCount: SpriteParts.all.length,
      itemBuilder: (context, i) {
        final part = SpriteParts.all[i];
        final frame = part.toFrame();
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                _stampPart = part;
                _tool = CanvasTool.stamp;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'Stamp mode: tap the canvas to place "${part.name}".')),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _stampPart == part
                    ? MutapixelTheme.primary.withValues(alpha: 0.12)
                    : palette.subtleFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _stampPart == part
                      ? MutapixelTheme.primary
                      : palette.hairline,
                ),
              ),
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      children: [
                        CustomPaint(
                          painter:
                              TemplatePreview(frame: frame),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: _sizeBadge(
                              '${frame.width}×${frame.height}'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    part.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Animations tab content: tap to open in Animation Studio.
  Widget _buildPanelAnimations(MutapixelPalette palette) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      itemCount: AnimationLibrary.all.length,
      itemBuilder: (context, i) {
        final anim = AnimationLibrary.all[i];
        final first = anim.frames.first;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AnimationScreen(
                    initialFrames: anim.frames,
                    initialFps: anim.fps,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: palette.subtleFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.hairline),
              ),
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      children: [
                        CustomPaint(
                          painter: TemplatePreview(
                              frame: first),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: _sizeBadge(
                              '${first.width}×${first.height}'),
                        ),
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black
                                  .withValues(alpha: 0.65),
                              borderRadius:
                                  BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${anim.frames.length}f',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    anim.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Floating options popup shown when the Select tool has an
  /// active selection. Offers move (drag), delete, flip, duplicate,
  /// and done actions.
  Widget _buildSelectionPopup() {
    final palette = MutapixelTheme.of(context);
    final canvas = _selectionKey.currentState;
    return Positioned(
      left: 12,
      right: 12,
      bottom: 12,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(20),
        color: palette.surface,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.hairline),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Selection — drag to move',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: palette.secondaryText,
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _selectionAction(
                      Icons.delete_outline,
                      'Delete',
                      () => canvas?.deleteSelection(),
                    ),
                    _selectionAction(
                      Icons.flip,
                      'Flip H',
                      () => canvas?.flipSelectionH(),
                    ),
                    _selectionAction(
                      Icons.flip_camera_android,
                      'Flip V',
                      () => canvas?.flipSelectionV(),
                    ),
                    _selectionAction(
                      Icons.copy,
                      'Duplicate',
                      () => canvas?.duplicateSelection(),
                    ),
                    _selectionAction(
                      Icons.check,
                      'Done',
                      () {
                        canvas?.doneSelection();
                        canvas?.clearSelection();
                        setState(() =>
                            _tool = CanvasTool.pencil);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectionAction(
      IconData icon, String label, VoidCallback onTap) {
    final palette = MutapixelTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 22, color: MutapixelTheme.primary),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: palette.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaletteBar() {
    final palette = MutapixelTheme.of(context);
    final all = [..._defaultPalette, ..._customColors];
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.hairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: all.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final color = all[i];
                final selected =
                    _drawColor.toARGB32() == color.toARGB32() &&
                        _tool != CanvasTool.eraser;
                return GestureDetector(
                  onTap: () {
                    if (color == Colors.transparent) {
                      setState(
                          () => _tool = CanvasTool.eraser);
                    } else {
                      setState(() {
                        _drawColor = color;
                        if (_tool == CanvasTool.eraser ||
                            _tool == CanvasTool.eyedropper) {
                          _tool = CanvasTool.pencil;
                        }
                      });
                    }
                  },
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color == Colors.transparent
                          ? palette.subtleFill
                          : color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? MutapixelTheme.primary
                            : palette.hairline,
                        width: selected ? 3 : 1,
                      ),
                    ),
                    child: color == Colors.transparent
                        ? Icon(Icons.block,
                            size: 16,
                            color: palette.secondaryText)
                        : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _paletteChip(Icons.brush, 'Color',
                          _drawColor, _pickCustomColor),
                      const SizedBox(width: 8),
                      _paletteChip(
                          Icons.interests, 'Parts', null,
                          _openPartsSheet),
                      const SizedBox(width: 8),
                      _paletteChip(Icons.auto_awesome,
                          'Effects', null, _openEffectsSheet),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paletteChip(
      IconData icon, String label, Color? color, VoidCallback onTap) {
    final palette = MutapixelTheme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: palette.subtleFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: palette.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null)
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: palette.hairline),
                ),
              )
            else
              Icon(icon, size: 16, color: palette.ink),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = MutapixelTheme.of(context);
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: palette.background,
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context)
                .pop(ArtLayer.flatten(_layers)),
          ),
          title: Text(
              '${_layers[_activeLayer].name} · ${_canvasSize}x$_canvasSize'),
          actions: [
            if (!widget.lockCanvasSize)
              PopupMenuButton<int>(
                tooltip: 'Canvas size',
                icon: const Icon(Icons.aspect_ratio),
                onSelected: _resizeCanvas,
                itemBuilder: (context) => [16, 32, 64]
                    .map((s) => PopupMenuItem(
                          value: s,
                          child: Text('$s x $s'
                              '${s == _canvasSize ? ' ✓' : ''}'),
                        ))
                    .toList(),
              ),
            IconButton(
              tooltip: 'New',
              icon: const Icon(Icons.add),
              onPressed: _openNewSpriteMenu,
            ),
            IconButton(
              tooltip: 'Layers',
              icon: Badge(
                isLabelVisible: _layers.length > 1,
                label: Text('${_layers.length}'),
                child: const Icon(Icons.layers),
              ),
              onPressed: _openLayersSheet,
            ),
            IconButton(
              tooltip: 'Download',
              icon: const Icon(Icons.download),
              onPressed: _openExport,
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (_tool == CanvasTool.stamp)
                Container(
                  margin:
                      const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: MutapixelTheme.primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: MutapixelTheme.primary
                            .withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.touch_app,
                          size: 18,
                          color: MutapixelTheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tap the canvas to place "${_stampPart?.name ?? ''}" as a new layer.',
                          style: TextStyle(
                              fontSize: 12,
                              color: palette.ink),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(
                            () => _exitStampMode()),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    _buildSideRail(),
                    Expanded(
                      child: DragTarget<ArtTemplate>(
                        onWillAcceptWithDetails: (_) => true,
                        onAcceptWithDetails: (details) =>
                            _onTemplateDropped(
                                details.data,
                                details.offset),
                        builder: (context, candidate,
                            rejected) {
                          return Container(
                            key: _canvasKey,
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: palette.surface,
                              borderRadius:
                                  BorderRadius.circular(
                                      20),
                              border: Border.all(
                                color: candidate.isNotEmpty
                                    ? MutapixelTheme.primary
                                    : palette.hairline,
                                width:
                                    candidate.isNotEmpty
                                        ? 2
                                        : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(
                                          alpha: 0.06),
                                  blurRadius: 16,
                                  offset: const Offset(
                                      0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(
                                      19),
                              child: Stack(
                                children: [
                                  PixelCanvas(
                                    key: _selectionKey,
                                layers: _layers,
                                activeLayer: _activeLayer,
                                drawColor: _drawColor,
                                tool: _tool,
                                mirror: _mirror,
                                showGrid: _showGrid,
                                onStrokeStart: _pushUndo,
                                onChanged: () =>
                                    setState(() {}),
                                onSelectionChanged: (has) =>
                                    setState(() =>
                                        _hasSelection = has),
                                onStampTap: (cx, cy) {
                                  final part =
                                      _stampPart;
                                  if (part == null) {
                                    return;
                                  }
                                  _addStampLayer(
                                      part.toFrame(),
                                      part.name,
                                      cx,
                                      cy);
                                },
                                onColorPicked: (color) {
                                  setState(() {
                                    _drawColor = color;
                                    _tool =
                                        CanvasTool.pencil;
                                  });
                                  ScaffoldMessenger.of(
                                          context)
                                      .showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Color picked')),
                                  );
                                },
                              ),
                                  if (_hasSelection)
                                    _buildSelectionPopup(),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    _buildTemplatesPanel(),
                  ],
                ),
              ),
              _buildPaletteBar(),
            ],
          ),
        ),
        floatingActionButton: _panelCollapsed
            ? FloatingActionButton.small(
                tooltip: 'Show templates',
                onPressed: () => setState(
                    () => _panelCollapsed = false),
                child:
                    const Icon(Icons.dashboard_customize),
              )
            : null,
      ),
    );
  }
}
