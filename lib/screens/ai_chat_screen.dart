import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/sprite_frame.dart';
import '../services/ai_generation.dart';
import '../services/photo_picker.dart';
import '../services/save_service.dart';
import '../services/sprite_exporter.dart';
import '../theme/mutapixel_theme.dart';
import '../utils/image_decode.dart';
import 'animation_screen.dart';
import 'editor_screen.dart';

enum _ChatMode { art, animate }

enum _MsgKind {
  userText,
  userPhoto,
  aiText,
  aiArt,
  aiAnimation,
  aiError,
}

class _ChatMsg {
  final _MsgKind kind;
  final String? text;
  final Uint8List? imageBytes;
  final SpriteFrame? frame;
  final List<SpriteFrame>? frames;
  final Uint8List? sheetPng;
  final String? sourceText;
  final Uint8List? sourcePhoto;

  const _ChatMsg({
    required this.kind,
    this.text,
    this.imageBytes,
    this.frame,
    this.frames,
    this.sheetPng,
    this.sourceText,
    this.sourcePhoto,
  });
}

/// The AI Lab chat: type what you want (or upload a photo) and the AI
/// forges pixel art or animations for you.
class AiChatScreen extends StatefulWidget {
  /// When false, renders without its own Scaffold/AppBar (for tab views).
  final bool showAppBar;

  const AiChatScreen({super.key, this.showAppBar = true});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _messages = <_ChatMsg>[];
  final _input = TextEditingController();
  final _scroll = ScrollController();
  _ChatMode _mode = _ChatMode.art;
  bool _busy = false;
  String _busyText = '';
  int _busySecs = 0;
  Timer? _busyTimer;

  static const _suggestions = [
    'Fire knight',
    'Cute slime',
    'Space pirate',
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _busyTimer?.cancel();
    super.dispose();
  }

  void _add(_ChatMsg msg) {
    setState(() => _messages.add(msg));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  void _setBusy(String? text) {
    _busyTimer?.cancel();
    setState(() {
      _busy = text != null;
      _busyText = text ?? '';
      _busySecs = 0;
    });
    if (text != null) {
      _busyTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => setState(() => _busySecs++),
      );
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _busy) return;
    _input.clear();
    _add(_ChatMsg(kind: _MsgKind.userText, text: text));
    if (_mode == _ChatMode.art) {
      await _generateArt(text);
    } else {
      await _generateAnimation(text, null);
    }
  }

  Future<void> _generateArt(String text) async {
    _setBusy('Forging your pixel art…');
    try {
      final bytes = await AiGeneration.generateArt(text);
      final frame = await spriteFrameFromBytes(bytes,
          size: 128, cropBottom: 0.06);
      final png = SpriteExporter.encodeFrame(frame, scale: 4);
      _setBusy(null);
      _add(_ChatMsg(
        kind: _MsgKind.aiArt,
        text: 'Here\'s your "$text". Tap to remix it.',
        imageBytes: png,
        frame: frame,
        sourceText: text,
      ));
    } on AiGenerationException catch (e) {
      _setBusy(null);
      _add(_ChatMsg(kind: _MsgKind.aiError, text: e.message));
    }
  }

  Future<void> _generateAnimation(
      String text, Uint8List? photoBytes) async {
    _setBusy('Dreaming up your animation… (this one takes longer)');
    try {
      final bytes = photoBytes == null
          ? await AiGeneration.generateAnimationSheet(text)
          : await AiGeneration.recreateAnimationSheet(
              photoBytes, text.isEmpty ? null : text);
      final frames = await spriteSheetFramesFromBytes(bytes,
          columns: 2, rows: 2, size: 128, cropBottom: 0.06);
      _setBusy(null);
      _add(_ChatMsg(
        kind: _MsgKind.aiAnimation,
        text: photoBytes == null
            ? 'Your "$text" animation is ready.'
            : 'Your photo, animated.',
        frames: frames,
        sheetPng: bytes,
        sourceText: text,
        sourcePhoto: photoBytes,
      ));
    } on AiGenerationException catch (e) {
      _setBusy(null);
      _add(_ChatMsg(kind: _MsgKind.aiError, text: e.message));
    }
  }

  Future<void> _pickPhoto() async {
    if (_busy) return;
    final bytes = await pickPhoto();
    if (bytes == null || !mounted) return;
    final hint = _input.text.trim();
    _input.clear();
    _add(_ChatMsg(kind: _MsgKind.userPhoto, imageBytes: bytes));
    _setBusy('Recreating your photo as pixel art…');
    try {
      final art =
          await AiGeneration.recreatePhoto(bytes, hint.isEmpty ? null : hint);
      final frame = await spriteFrameFromBytes(art,
          size: 128, cropBottom: 0.06);
      final png = SpriteExporter.encodeFrame(frame, scale: 4);
      _setBusy(null);
      _add(_ChatMsg(
        kind: _MsgKind.aiArt,
        text: 'Recreated as pixel art. Want it animated too?',
        imageBytes: png,
        frame: frame,
        sourceText: hint,
        sourcePhoto: bytes,
      ));
    } on AiGenerationException catch (e) {
      _setBusy(null);
      _add(_ChatMsg(kind: _MsgKind.aiError, text: e.message));
    }
  }

  Future<void> _animateArtwork(_ChatMsg msg) async {
    if (_busy) return;
    if (msg.sourcePhoto != null) {
      await _generateAnimation(msg.sourceText ?? '', msg.sourcePhoto);
    } else if (msg.sourceText != null) {
      await _generateAnimation(msg.sourceText!, null);
    }
  }

  void _openInEditor(SpriteFrame frame) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => EditorScreen(initialFrame: frame)),
    );
  }

  void _openInStudio(List<SpriteFrame> frames) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnimationScreen(
          initialFrames: [for (final f in frames) SpriteFrame.clone(f)],
        ),
      ),
    );
  }

  Future<void> _download(Uint8List png, String name) async {
    await SaveService.saveToFiles(png, name);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloaded.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = MutapixelTheme.of(context);
    final body = Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? _emptyState(palette)
              : ListView.builder(
                  controller: _scroll,
                  padding:
                      const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: _messages.length + (_busy ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == _messages.length) {
                      return _typingBubble(palette);
                    }
                    return _bubble(_messages[i], palette);
                  },
                ),
        ),
        _modeChips(palette),
        _inputRow(palette),
      ],
    );
    if (!widget.showAppBar) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('AI Chat')),
      body: body,
    );
  }

  Widget _emptyState(MutapixelPalette palette) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome,
                size: 48, color: MutapixelTheme.primary),
            const SizedBox(height: 16),
            Text(
              'Describe what you want.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: palette.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pixel art or animations — or upload a photo and I\'ll '
              'recreate it as pixel art.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: palette.secondaryText,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final s in _suggestions)
                  ActionChip(
                    label: Text(s),
                    onPressed: _busy
                        ? null
                        : () {
                            _input.text = s;
                            _send();
                          },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _typingBubble(MutapixelPalette palette) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(
              '$_busyText ${_busySecs}s',
              style: TextStyle(
                fontSize: 13,
                color: palette.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(_ChatMsg msg, MutapixelPalette palette) {
    switch (msg.kind) {
      case _MsgKind.userText:
        return Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: MutapixelTheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              msg.text!,
              style: const TextStyle(
                  fontSize: 14, color: Colors.white),
            ),
          ),
        );
      case _MsgKind.userPhoto:
        return Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.hairline),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.memory(msg.imageBytes!,
                width: 180, fit: BoxFit.cover),
          ),
        );
      case _MsgKind.aiText:
        return _aiBubble(
            palette, Text(msg.text!, style: const TextStyle(fontSize: 14)));
      case _MsgKind.aiError:
        return _aiBubble(
          palette,
          Text(msg.text!,
              style:
                  const TextStyle(fontSize: 14, color: Colors.red)),
        );
      case _MsgKind.aiArt:
        return _aiBubble(
          palette,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  msg.imageBytes!,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                ),
              ),
              if (msg.text != null) ...[
                const SizedBox(height: 8),
                Text(msg.text!,
                    style: const TextStyle(fontSize: 13)),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _action(palette, Icons.brush, 'Editor',
                      () => _openInEditor(msg.frame!)),
                  _action(palette, Icons.movie, 'Animate',
                      () => _animateArtwork(msg)),
                  _action(
                      palette,
                      Icons.download,
                      'PNG',
                      () => _download(msg.imageBytes!,
                          'ai-art-${DateTime.now().millisecondsSinceEpoch}.png')),
                ],
              ),
            ],
          ),
        );
      case _MsgKind.aiAnimation:
        return _aiBubble(
          palette,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _FramePlayer(frames: msg.frames!),
              ),
              if (msg.text != null) ...[
                const SizedBox(height: 8),
                Text(msg.text!,
                    style: const TextStyle(fontSize: 13)),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _action(palette, Icons.movie, 'Open in Studio',
                      () => _openInStudio(msg.frames!)),
                  _action(
                      palette,
                      Icons.download,
                      'Sheet PNG',
                      () => _download(msg.sheetPng!,
                          'ai-sheet-${DateTime.now().millisecondsSinceEpoch}.png')),
                ],
              ),
            ],
          ),
        );
    }
  }

  Widget _aiBubble(MutapixelPalette palette, Widget child) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.hairline),
        ),
        child: child,
      ),
    );
  }

  Widget _action(MutapixelPalette palette, IconData icon,
      String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _modeChips(MutapixelPalette palette) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          _modeChip(palette, _ChatMode.art, Icons.brush, 'Pixel Art'),
          const SizedBox(width: 8),
          _modeChip(
              palette, _ChatMode.animate, Icons.movie, 'Animation'),
        ],
      ),
    );
  }

  Widget _modeChip(MutapixelPalette palette, _ChatMode mode,
      IconData icon, String label) {
    final selected = _mode == mode;
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      avatar: Icon(icon, size: 16),
      onSelected: _busy ? null : (_) => setState(() => _mode = mode),
    );
  }

  Widget _inputRow(MutapixelPalette palette) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Upload a photo',
              icon: const Icon(Icons.add_photo_alternate_outlined),
              onPressed: _busy ? null : _pickPhoto,
            ),
            Expanded(
              child: TextField(
                controller: _input,
                enabled: !_busy,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: _mode == _ChatMode.art
                      ? 'Describe your pixel art…'
                      : 'Describe your animation…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Send',
              icon: const Icon(Icons.send),
              style: IconButton.styleFrom(
                backgroundColor: MutapixelTheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: _busy ? null : _send,
            ),
          ],
        ),
      ),
    );
  }
}

/// Loops animation frames inside a chat bubble.
class _FramePlayer extends StatefulWidget {
  final List<SpriteFrame> frames;

  const _FramePlayer({required this.frames});

  @override
  State<_FramePlayer> createState() => _FramePlayerState();
}

class _FramePlayerState extends State<_FramePlayer> {
  late final List<Uint8List> _pngs;
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pngs = [
      for (final f in widget.frames)
        SpriteExporter.encodeFrame(f, scale: 4),
    ];
    _timer = Timer.periodic(
      const Duration(milliseconds: 280),
      (_) => setState(
          () => _index = (_index + 1) % _pngs.length),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Image.memory(
      _pngs[_index],
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
    );
  }
}
