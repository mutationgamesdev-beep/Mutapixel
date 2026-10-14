import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/ai_lab.dart';
import '../models/ai_pack.dart';
import '../services/save_service.dart';
import '../theme/mutapixel_theme.dart';
import '../utils/image_decode.dart';
import 'editor_screen.dart';

/// The AI Lab: themed drops of AI-forged pixel art.
/// Browse packs, open any piece in the editor, or download the PNG.
class AiLabScreen extends StatelessWidget {
  const AiLabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = MutapixelTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Lab'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            'Forged by AI, finished by you.',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Themed drops of AI-generated pixel art. Open any piece in '
            'the editor to remix it, or download the PNG straight into '
            'your game.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: palette.secondaryText,
            ),
          ),
          const SizedBox(height: 20),
          for (final pack in aiPacks) _packCard(context, pack, palette),
        ],
      ),
    );
  }

  Widget _packCard(
      BuildContext context, AiPack pack, MutapixelPalette palette) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AiPackScreen(pack: pack)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: palette.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.asset(
                pack.artworks.first.assetPath,
                fit: BoxFit.cover,
                errorBuilder: (context, _, __) => Container(
                  color: palette.hairline,
                  child: const Center(
                    child: Icon(Icons.image_not_supported),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pack.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: palette.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pack.tagline,
                    style: TextStyle(
                      fontSize: 13,
                      color: palette.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One pack: the full artwork grid.
class AiPackScreen extends StatelessWidget {
  final AiPack pack;

  const AiPackScreen({super.key, required this.pack});

  @override
  Widget build(BuildContext context) {
    final palette = MutapixelTheme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(pack.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            pack.description,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: palette.secondaryText,
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemCount: pack.artworks.length,
            itemBuilder: (context, i) {
              final art = pack.artworks[i];
              return GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) =>
                          AiArtworkScreen(artwork: art)),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: palette.hairline),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Image.asset(
                          art.assetPath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, _, __) =>
                              Container(
                            color: palette.hairline,
                            child: const Center(
                              child: Icon(
                                  Icons.image_not_supported),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          art.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: palette.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// One artwork: big preview, open in editor, download.
class AiArtworkScreen extends StatefulWidget {
  final AiArtwork artwork;

  const AiArtworkScreen({super.key, required this.artwork});

  @override
  State<AiArtworkScreen> createState() =>
      _AiArtworkScreenState();
}

class _AiArtworkScreenState extends State<AiArtworkScreen> {
  bool _opening = false;

  Future<void> _openInEditor() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final frame =
          await spriteFrameFromAsset(widget.artwork.assetPath);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EditorScreen(initialFrame: frame),
        ),
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _download() async {
    final data =
        await rootBundle.load(widget.artwork.assetPath);
    await SaveService.saveToFiles(
      data.buffer.asUint8List(),
      '${widget.artwork.id}.png',
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = MutapixelTheme.of(context);
    final art = widget.artwork;
    return Scaffold(
      appBar: AppBar(title: Text(art.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: palette.hairline),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              art.assetPath,
              fit: BoxFit.contain,
              errorBuilder: (context, _, __) => Container(
                height: 240,
                color: palette.hairline,
                child: const Center(
                  child: Icon(Icons.image_not_supported),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            art.blurb,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: palette.secondaryText,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _opening ? null : _openInEditor,
            icon: _opening
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2),
                  )
                : const Icon(Icons.brush),
            label: Text(_opening
                ? 'Opening…'
                : 'Open in Editor'),
            style: FilledButton.styleFrom(
              backgroundColor: MutapixelTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _download,
            icon: const Icon(Icons.download),
            label: const Text('Download PNG'),
            style: OutlinedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
