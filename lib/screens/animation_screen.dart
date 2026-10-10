import 'dart:async';

import 'package:flutter/material.dart';

import '../models/sprite_frame.dart';
import '../theme/mutapixel_theme.dart';
import '../widgets/template_preview.dart';
import 'editor_screen.dart';
import 'export_sheet.dart';

/// Animation Studio: a timeline of frames with playback, onion
/// skinning, and sprite-sheet export.
///
/// Tapping a frame opens it in the pixel art editor (canvas size
/// locked so every frame stays consistent); saving there returns
/// the updated frame here.
///
/// Pass [initialFrames] (e.g. from an animation template) to start
/// with those frames instead of a blank timeline; [initialFps] sets
/// the suggested playback speed.
class AnimationScreen extends StatefulWidget {
  final List<SpriteFrame>? initialFrames;
  final int? initialFps;

  const AnimationScreen({super.key, this.initialFrames, this.initialFps});

  @override
  State<AnimationScreen> createState() => _AnimationScreenState();
}

class _AnimationScreenState extends State<AnimationScreen> {
  static const int _canvasSize = 32;

  late final List<SpriteFrame> _frames = [
    SpriteFrame(width: _canvasSize, height: _canvasSize),
  ];
  int _selected = 0;

  bool _playing = false;
  int _playIndex = 0;
  double _fps = 6;
  bool _onionSkin = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialFrames;
    if (initial != null && initial.isNotEmpty) {
      _frames
        ..clear()
        ..addAll(
          initial.map((f) => f.resized(_canvasSize, _canvasSize)),
        );
    }
    if (widget.initialFps != null) {
      _fps = widget.initialFps!.toDouble();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPlayback() {
    _timer?.cancel();
    setState(() {
      _playing = true;
      _playIndex = 0;
    });
    _timer = Timer.periodic(
      Duration(milliseconds: (1000 / _fps).round()),
      (_) {
        if (!mounted) return;
        setState(() => _playIndex = (_playIndex + 1) % _frames.length);
      },
    );
  }

  void _stopPlayback() {
    _timer?.cancel();
    setState(() => _playing = false);
  }

  void _togglePlayback() {
    if (_frames.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Add at least 2 frames to play.')),
      );
      return;
    }
    if (_playing) {
      _stopPlayback();
    } else {
      _startPlayback();
    }
  }

  void _addFrame() {
    setState(() {
      _frames.add(
          SpriteFrame(width: _canvasSize, height: _canvasSize));
      _selected = _frames.length - 1;
    });
  }

  void _duplicateFrame(int i) {
    setState(() {
      _frames.insert(i + 1, SpriteFrame.clone(_frames[i]));
      _selected = i + 1;
    });
  }

  void _deleteFrame(int i) {
    if (_frames.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('An animation needs at least 1 frame.')),
      );
      return;
    }
    setState(() {
      _frames.removeAt(i);
      if (_selected >= _frames.length) _selected = _frames.length - 1;
    });
  }

  /// Opens frame [i] in the pixel editor; applies the returned frame.
  Future<void> _editFrame(int i) async {
    _stopPlayback();
    final updated = await Navigator.of(context).push<SpriteFrame>(
      MaterialPageRoute(
        builder: (_) => EditorScreen(
          initialFrame: SpriteFrame.clone(_frames[i]),
          initialCanvasSize: _canvasSize,
          lockCanvasSize: true,
        ),
      ),
    );
    if (updated == null || !mounted) return;
    setState(() => _frames[i] = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Frame ${i + 1} updated.')),
    );
  }

  void _openExport() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: MutapixelTheme.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => ExportSheet(frames: _frames),
    );
  }

  Widget _buildPreview() {
    final palette = MutapixelTheme.of(context);
    final frame = _playing ? _frames[_playIndex] : _frames[_selected];
    final ghost = !_playing && _onionSkin && _selected > 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(24),
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
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: CustomPaint(
              painter: _FramePreviewPainter(
                frame: frame,
                ghostFrame:
                    ghost ? _frames[_selected - 1] : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.tonalIcon(
                icon: Icon(
                    _playing ? Icons.pause : Icons.play_arrow),
                label:
                    Text(_playing ? 'Pause' : 'Play'),
                onPressed: _togglePlayback,
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Onion skin'),
                selected: _onionSkin,
                onSelected: (v) =>
                    setState(() => _onionSkin = v),
                avatar: Icon(
                  Icons.layers,
                  size: 16,
                  color: _onionSkin
                      ? MutapixelTheme.primary
                      : palette.secondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('Speed',
                  style: TextStyle(
                      fontSize: 12,
                      color: palette.secondaryText)),
              Expanded(
                child: Slider(
                  value: _fps,
                  min: 1,
                  max: 12,
                  divisions: 11,
                  label: '${_fps.round()} fps',
                  onChanged: (v) {
                    setState(() => _fps = v);
                    if (_playing) _startPlayback();
                  },
                ),
              ),
              SizedBox(
                width: 52,
                child: Text('${_fps.round()} fps',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                        fontSize: 12,
                        color: palette.secondaryText)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final palette = MutapixelTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text('Timeline',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: palette.ink)),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add frame'),
                onPressed: _addFrame,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _frames.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final selected = i == _selected;
              return GestureDetector(
                onTap: () =>
                    setState(() => _selected = i),
                onDoubleTap: () => _editFrame(i),
                onLongPress: () =>
                    _showFrameMenu(context, i),
                child: Column(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: selected
                            ? MutapixelTheme.primary
                                .withValues(alpha: 0.1)
                            : palette.surface,
                        borderRadius:
                            BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? MutapixelTheme.primary
                              : palette.hairline,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: CustomPaint(
                        painter: TemplatePreview(
                            frame: _frames[i]),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('F${i + 1}',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: selected
                                ? MutapixelTheme.primary
                                : palette.secondaryText)),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Text(
            'Tap a frame to select · double-tap to edit · long-press for options',
            style: TextStyle(
                fontSize: 11, color: palette.secondaryText),
          ),
        ),
      ],
    );
  }

  void _showFrameMenu(BuildContext context, int i) {
    final palette = MutapixelTheme.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text('Edit frame ${i + 1}'),
              onTap: () {
                Navigator.of(context).pop();
                _editFrame(i);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Duplicate frame'),
              onTap: () {
                Navigator.of(context).pop();
                _duplicateFrame(i);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete frame'),
              enabled: _frames.length > 1,
              onTap: () {
                Navigator.of(context).pop();
                _deleteFrame(i);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = MutapixelTheme.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Home',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Animation Studio'),
        actions: [
          IconButton(
            tooltip: 'Export sprite sheet',
            icon: const Icon(Icons.download),
            onPressed: _openExport,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPreview(),
              _buildTimeline(),
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: FilledButton.icon(
                  icon: const Icon(Icons.edit),
                  label: Text(
                      'Edit frame ${_selected + 1} in pixel editor'),
                  onPressed: () => _editFrame(_selected),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints a frame large, with an optional ghosted previous frame
/// underneath for onion skinning.
class _FramePreviewPainter extends CustomPainter {
  final SpriteFrame frame;
  final SpriteFrame? ghostFrame;

  _FramePreviewPainter({required this.frame, this.ghostFrame});

  @override
  void paint(Canvas canvas, Size size) {
    void paintFrame(SpriteFrame f, double alpha) {
      final s = size.width / f.width < size.height / f.height
          ? size.width / f.width
          : size.height / f.height;
      final ox = (size.width - f.width * s) / 2;
      final oy = (size.height - f.height * s) / 2;
      for (var y = 0; y < f.height; y++) {
        for (var x = 0; x < f.width; x++) {
          final color = f.getPixel(x, y);
          if (color == null) continue;
          canvas.drawRect(
            Rect.fromLTWH(ox + x * s, oy + y * s, s + 0.5, s + 0.5),
            Paint()
              ..color =
                  color.withValues(alpha: color.a * alpha),
          );
        }
      }
    }

    if (ghostFrame != null) paintFrame(ghostFrame!, 0.3);
    paintFrame(frame, 1.0);
  }

  @override
  bool shouldRepaint(_FramePreviewPainter old) =>
      old.frame != frame || old.ghostFrame != ghostFrame;
}
