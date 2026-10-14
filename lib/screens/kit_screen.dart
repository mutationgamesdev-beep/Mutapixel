import 'dart:async';

import 'package:flutter/material.dart';

import '../models/animation_template.dart';
import '../models/character_kit.dart';
import '../services/sprite_exporter.dart';
import '../services/save_service.dart';
import '../theme/mutapixel_theme.dart';
import '../widgets/template_preview.dart';

/// Detail page for one character kit: every action with a live
/// animated preview, per-action downloads, and one-click full-kit ZIP.
class KitScreen extends StatelessWidget {
  final CharacterKit kit;

  const KitScreen({super.key, required this.kit});

  Future<void> _downloadKit(BuildContext context) async {
    final bytes = SpriteExporter.encodeKitZip(kit);
    await SaveService.saveToFiles(bytes, '${kit.id}-kit.zip');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloaded ${kit.name} kit.')),
      );
    }
  }

  Future<void> _downloadAction(
      BuildContext context, AnimationTemplate action) async {
    final bytes = SpriteExporter.encodeSpriteSheetZip(
      action.frames,
      name: action.name,
      frameDurations: action.frameDurations,
      fps: action.fps,
    );
    await SaveService.saveToFiles(bytes, '${kit.id}-${action.name}.zip');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloaded ${action.name}.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = MutapixelTheme.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text(kit.name),
        backgroundColor: palette.background,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(context, palette),
            _actionList(context, palette),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, MutapixelPalette palette) {
    final idle =
        kit.actions.firstWhere((a) => a.name.endsWith('Idle'));
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: palette.hairline),
            ),
            child: Center(
              child: SizedBox(
                width: 160,
                height: 160,
                child: _LoopPreview(action: idle),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E9E5B),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'CHARACTER KIT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${kit.actions.length} actions · ${kit.totalFrames} frames',
                style: TextStyle(
                  fontSize: 13,
                  color: palette.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            kit.name,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              color: palette.ink,
            ),
          ),
          Text(
            kit.tagline,
            style: TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: palette.secondaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            kit.description,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: palette.secondaryText,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _downloadKit(context),
              icon: const Icon(Icons.download),
              label: const Text('Download full kit (.zip)',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              style: FilledButton.styleFrom(
                backgroundColor: MutapixelTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Every action as a sprite sheet + engine JSON, with a kit manifest.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12, color: palette.secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _actionList(BuildContext context, MutapixelPalette palette) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The full move set',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 12),
          for (final action in kit.actions)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: palette.hairline),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: palette.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: _LoopPreview(action: action),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            CharacterKit.shortActionName(
                                kit.name, action.name),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: palette.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${action.frames.length} frames · ${action.fps} fps',
                            style: TextStyle(
                              fontSize: 13,
                              color: palette.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Download sprite sheet + JSON',
                      icon: const Icon(Icons.download),
                      color: MutapixelTheme.primary,
                      onPressed: () =>
                          _downloadAction(context, action),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Loops an animation's frames, honouring per-frame durations.
class _LoopPreview extends StatefulWidget {
  final AnimationTemplate action;

  const _LoopPreview({required this.action});

  @override
  State<_LoopPreview> createState() => _LoopPreviewState();
}

class _LoopPreviewState extends State<_LoopPreview> {
  int _frame = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  void _schedule() {
    final d = widget.action.frameDurations;
    final ms = d != null
        ? d[_frame % d.length]
        : (1000 / widget.action.fps).round();
    _timer = Timer(Duration(milliseconds: ms), () {
      if (!mounted) return;
      setState(() => _frame++);
      _schedule();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frames = widget.action.frames;
    return CustomPaint(
      painter:
          TemplatePreview(frame: frames[_frame % frames.length]),
      child: const SizedBox.expand(),
    );
  }
}
