import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../models/sprite_frame.dart';
import '../services/ai_settings.dart';
import '../services/openai_provider.dart';
import '../services/photo_picker.dart';
import '../services/save_service.dart';
import '../services/sprite_exporter.dart';
import '../theme/mutapixel_theme.dart';
import '../utils/image_decode.dart';
import 'ai_key_sheet.dart';
import 'animation_screen.dart';
import 'editor_screen.dart';

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

  const _ChatMsg({
    required this.kind,
    this.text,
    this.imageBytes,
    this.frame,
    this.frames,
    this.sheetPng,
  });
}

/// The AI Lab chat: a real conversational creative copilot. It listens,
/// asks questions, and generates pixel art or animations when asked.
/// Runs on the user's own OpenAI API key.
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
  final _history = <Map<String, dynamic>>[];

  String? _apiKey;
  bool _busy = false;
  String _busyText = '';
  int _busySecs = 0;
  Timer? _busyTimer;
  Uint8List? _pendingPhoto;

  static const _suggestions = [
    'Fire knight',
    'Cute slime',
    'Space pirate',
  ];

  @override
  void initState() {
    super.initState();
    _history.add({
      'role': 'system',
      'content': OpenAiProvider.systemPrompt,
    });
    AiSettings.loadKey().then((key) {
      if (mounted) setState(() => _apiKey = key);
    });
  }

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
        (_) {
          if (mounted) setState(() => _busySecs++);
        },
      );
    }
  }

  Future<void> _openKeySettings() async {
    await showAiKeySheet(context);
    final key = await AiSettings.loadKey();
    if (mounted) setState(() => _apiKey = key);
  }

  Future<void> _pickPhoto() async {
    if (_busy || _apiKey == null) return;
    final bytes = await pickPhoto();
    if (bytes == null || !mounted) return;
    setState(() => _pendingPhoto = bytes);
    _add(_ChatMsg(
        kind: _MsgKind.userPhoto, imageBytes: bytes));
    _add(const _ChatMsg(
      kind: _MsgKind.aiText,
      text: 'Got the photo. Tell me what to do with it — '
          '"make it pixel art", "turn it into a game sprite", ...',
    ));
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if ((text.isEmpty && _pendingPhoto == null) ||
        _busy ||
        _apiKey == null) {
      return;
    }
    _input.clear();
    final photo = _pendingPhoto;
    _pendingPhoto = null;

    if (text.isNotEmpty) {
      _add(_ChatMsg(kind: _MsgKind.userText, text: text));
    }

    // Build the model's message (vision when a photo is attached).
    final content = <Map<String, dynamic>>[];
    if (text.isNotEmpty) {
      content.add({'type': 'text', 'text': text});
    }
    if (photo != null) {
      content.add({
        'type': 'image_url',
        'image_url': {
          'url': _visionDataUrl(photo),
        },
      });
    }
    final userMessage = {
      'role': 'user',
      'content': content,
    };

    final provider = OpenAiProvider(_apiKey!);
    _setBusy('Thinking…');
    try {
      final requestMessages = [
        ..._history,
        userMessage,
      ];
      final turn = await provider.chat(requestMessages);
      _history.add(userMessage);
      _history.add({
        'role': 'assistant',
        'content': turn.text,
        if (turn.toolCalls.isNotEmpty)
          'tool_calls': [
            for (final tc in turn.toolCalls)
              {
                'id': tc.id,
                'type': 'function',
                'function': {
                  'name': tc.name,
                  'arguments': jsonEncode(tc.arguments),
                },
              },
          ],
      });

      // Run the requested tools.
      for (final tc in turn.toolCalls) {
        await _runTool(provider, tc, photo);
        _history.add({
          'role': 'tool',
          'tool_call_id': tc.id,
          'content': 'Done. The result was shown to the user.',
        });
      }

      // Final reply after any tool work.
      if (turn.toolCalls.isNotEmpty) {
        _setBusy('Thinking…');
        final followUp =
            await provider.chat(_history);
        _history.add({
          'role': 'assistant',
          'content': followUp.text,
        });
        final reply = (followUp.text ?? '').trim();
        if (reply.isNotEmpty) {
          _add(_ChatMsg(kind: _MsgKind.aiText, text: reply));
        }
      } else {
        final reply = (turn.text ?? '').trim();
        _add(_ChatMsg(
          kind: _MsgKind.aiText,
          text: reply.isEmpty
              ? 'Hmm, I drew a blank. What would you like to make?'
              : reply,
        ));
      }
      _trimHistory();
    } on AiApiException catch (e) {
      _add(_ChatMsg(kind: _MsgKind.aiError, text: e.message));
    } catch (_) {
      _add(const _ChatMsg(
        kind: _MsgKind.aiError,
        text: 'Something went wrong talking to the AI. '
            'Check your connection and try again.',
      ));
    } finally {
      _setBusy(null);
    }
  }

  Future<void> _runTool(OpenAiProvider provider, ToolCall tc,
      Uint8List? photo) async {
    final prompt =
        (tc.arguments['prompt'] as String? ?? '').trim();
    try {
      switch (tc.name) {
        case 'generate_pixel_art':
          _setBusy('Painting your pixel art…');
          final bytes =
              await provider.generateImage(prompt);
          final frame = await spriteFrameFromBytes(bytes,
              size: 128, cropBottom: 0.0);
          final png =
              SpriteExporter.encodeFrame(frame, scale: 4);
          _setBusy(null);
          _add(_ChatMsg(
            kind: _MsgKind.aiArt,
            imageBytes: png,
            frame: frame,
          ));
        case 'generate_animation':
          _setBusy(
              'Dreaming up your animation… (this one takes longer)');
          final bytes =
              await provider.generateAnimationSheet(prompt);
          final frames =
              await spriteSheetFramesFromBytes(bytes,
                  columns: 2,
                  rows: 2,
                  size: 128,
                  cropBottom: 0.0);
          _setBusy(null);
          _add(_ChatMsg(
            kind: _MsgKind.aiAnimation,
            frames: frames,
            sheetPng: bytes,
          ));
        case 'recreate_photo':
          final source = photo ?? _lastPhoto();
          if (source == null) {
            _add(const _ChatMsg(
              kind: _MsgKind.aiText,
              text: 'I need a photo first — tap the + button '
                  'to upload one.',
            ));
            return;
          }
          _setBusy('Recreating your photo as pixel art…');
          final bytes =
              await provider.editPhoto(source, prompt);
          final frame = await spriteFrameFromBytes(bytes,
              size: 128, cropBottom: 0.0);
          final png =
              SpriteExporter.encodeFrame(frame, scale: 4);
          _setBusy(null);
          _add(_ChatMsg(
            kind: _MsgKind.aiArt,
            imageBytes: png,
            frame: frame,
          ));
      }
    } on AiApiException catch (e) {
      _setBusy(null);
      _add(_ChatMsg(kind: _MsgKind.aiError, text: e.message));
    }
  }

  /// Finds the most recently uploaded photo in the conversation.
  Uint8List? _lastPhoto() {
    for (var i = _messages.length - 1; i >= 0; i--) {
      final m = _messages[i];
      if (m.kind == _MsgKind.userPhoto &&
          m.imageBytes != null) {
        return m.imageBytes;
      }
    }
    return null;
  }

  /// Keeps the model history bounded (system + last 12 turns).
  void _trimHistory() {
    const keep = 13; // system + 12
    if (_history.length > keep) {
      _history.removeRange(1, _history.length - keep + 1);
    }
  }

  /// Downscales a photo for vision input (small = fast + cheap).
  static String _visionDataUrl(Uint8List photoBytes) {
    final decoded = img.decodeImage(photoBytes)!;
    final small = img.copyResize(decoded,
        width:
            decoded.width >= decoded.height ? 512 : null,
        height:
            decoded.height > decoded.width ? 512 : null);
    final jpeg = img.encodeJpg(small, quality: 70);
    return 'data:image/jpeg;base64,${base64Encode(jpeg)}';
  }

  void _openInEditor(SpriteFrame frame) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) =>
              EditorScreen(initialFrame: frame)),
    );
  }

  void _openInStudio(List<SpriteFrame> frames) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnimationScreen(
          initialFrames: [
            for (final f in frames) SpriteFrame.clone(f)
          ],
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
          child: _apiKey == null
              ? _keyGate(palette)
              : _messages.isEmpty
                  ? _emptyState(palette)
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(
                          16, 12, 16, 12),
                      itemCount:
                          _messages.length + (_busy ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i == _messages.length) {
                          return _typingBubble(palette);
                        }
                        return _bubble(
                            _messages[i], palette);
                      },
                    ),
        ),
        if (_apiKey != null) _inputRow(palette),
      ],
    );
    if (!widget.showAppBar) return body;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat'),
        actions: [
          IconButton(
            tooltip: 'AI settings',
            icon: const Icon(Icons.key_outlined),
            onPressed: _openKeySettings,
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _keyGate(MutapixelPalette palette) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.key_outlined,
                size: 48, color: MutapixelTheme.primary),
            const SizedBox(height: 16),
            Text(
              'Connect your AI key',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: palette.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your own OpenAI API key and this chat becomes '
              'a real creative copilot — it listens, asks questions, '
              'and generates pixel art and animations. About \$5 of '
              'credit makes roughly 1,000 images, and the key stays '
              'on your device.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: palette.secondaryText,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _openKeySettings,
              icon: const Icon(Icons.key),
              label: const Text('Add API key'),
              style: FilledButton.styleFrom(
                backgroundColor: MutapixelTheme.primary,
              ),
            ),
          ],
        ),
      ),
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
              'What are we making?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: palette.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Just talk to me like ChatGPT. Ask for pixel art, '
              'ask for an animation, or upload a photo and I\'ll '
              'recreate it as a game sprite.',
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
              child:
                  CircularProgressIndicator(strokeWidth: 2),
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
            palette,
            Text(msg.text!,
                style:
                    const TextStyle(fontSize: 14)));
      case _MsgKind.aiError:
        return _aiBubble(
          palette,
          Text(msg.text!,
              style: const TextStyle(
                  fontSize: 14, color: Colors.red)),
        );
      case _MsgKind.aiArt:
        return _aiBubble(
          palette,
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  msg.imageBytes!,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _action(palette, Icons.brush, 'Editor',
                      () => _openInEditor(msg.frame!)),
                  _action(palette, Icons.movie, 'Animate',
                      () {
                    _input.text =
                        'animate this into a walk cycle';
                    _send();
                  }),
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
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _FramePlayer(frames: msg.frames!),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _action(palette, Icons.movie,
                      'Open in Studio',
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

  Widget _aiBubble(
      MutapixelPalette palette, Widget child) {
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
      label:
          Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _inputRow(MutapixelPalette palette) {
    final canSend =
        !_busy && (_input.text.trim().isNotEmpty);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Upload a photo',
              icon: const Icon(
                  Icons.add_photo_alternate_outlined),
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
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText:
                      'Ask for pixel art or an animation…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(
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
              onPressed: canSend ? _send : null,
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
  State<_FramePlayer> createState() =>
      _FramePlayerState();
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
      (_) {
        if (mounted) {
          setState(
              () => _index = (_index + 1) % _pngs.length);
        }
      },
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
