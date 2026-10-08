import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/sprite_frame.dart';
import '../services/save_service.dart';
import '../services/sprite_exporter.dart';
import '../theme/mutapixel_theme.dart';

/// Export options: PNG or sprite sheet, scale, then save / share.
class ExportSheet extends StatefulWidget {
  final List<SpriteFrame> frames;

  const ExportSheet({super.key, required this.frames});

  @override
  State<ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<ExportSheet> {
  bool _asSheet = false;
  int _scale = 4;
  int _columns = 4;
  bool _busy = false;
  String? _status;

  Future<void> _run(
    String label,
    Future<void> Function(Uint8List bytes, String name) action,
  ) async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final bytes = _asSheet
          ? SpriteExporter.encodeSpriteSheet(
              widget.frames,
              scale: _scale,
              columns: _columns,
            )
          : SpriteExporter.encodeFrame(
              widget.frames.first,
              scale: _scale,
            );
      final name =
          'sprite_${DateTime.now().millisecondsSinceEpoch}.png';
      await action(bytes, name);
      if (mounted) setState(() => _status = '$label done!');
    } catch (e) {
      if (mounted) setState(() => _status = '$label failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveToGallery() => _run(
        kIsWeb ? 'Downloaded' : 'Saved to gallery',
        (bytes, name) => SaveService.saveToGallery(bytes, name),
      );

  Future<void> _saveToFiles() => _run(
        'Saved',
        (bytes, name) => SaveService.saveToFiles(bytes, name),
      );

  Future<void> _share() => _run('Shared', (bytes, name) async {
        final file = await SaveService.makeShareFile(bytes, name);
        await Share.shareXFiles(
          [file],
          text: 'Made with Mutapixel',
        );
      });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Export',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Lossless PNG, real transparency, crisp pixels.',
              style: TextStyle(
                  color: MutapixelTheme.of(context).secondaryText,
                  fontSize: 13),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Sprite sheet'),
              subtitle: Text(widget.frames.length == 1
                  ? 'Only one frame — exports as a single PNG'
                  : '${widget.frames.length} frames packed with a 2 px gutter'),
              value: _asSheet && widget.frames.length > 1,
              onChanged: widget.frames.length > 1
                  ? (v) => setState(() => _asSheet = v)
                  : null,
              contentPadding: EdgeInsets.zero,
            ),
            Text('Scale',
                style: TextStyle(
                    color: MutapixelTheme.of(context).secondaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [1, 2, 4, 8]
                  .map((s) => _SelectChip(
                        label: '${s}x',
                        selected: _scale == s,
                        onSelected: () =>
                            setState(() => _scale = s),
                      ))
                  .toList(),
            ),
            if (_asSheet && widget.frames.length > 1) ...[
              const SizedBox(height: 12),
              Text('Frames per row',
                  style: TextStyle(
                      color: MutapixelTheme.of(context).secondaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [2, 4, 8]
                    .map((c) => _SelectChip(
                          label: '$c',
                          selected: _columns == c,
                          onSelected: () =>
                              setState(() => _columns = c),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 20),
            if (_busy)
              const Center(child: CircularProgressIndicator())
            else if (kIsWeb)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _actionButton(
                      Icons.download, 'Download', _saveToGallery),
                  _actionButton(Icons.ios_share, 'Share', _share),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _actionButton(
                      Icons.photo_library, 'Gallery', _saveToGallery),
                  _actionButton(Icons.folder, 'Files', _saveToFiles),
                  _actionButton(Icons.ios_share, 'Share', _share),
                ],
              ),
            if (_status != null) ...[
              const SizedBox(height: 12),
              Center(
                child: Text(_status!,
                    style: TextStyle(
                        color: MutapixelTheme.of(context).secondaryText,
                        fontSize: 13)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _actionButton(
      IconData icon, String label, VoidCallback onPressed) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: MutapixelTheme.primary,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child:
                  Icon(icon, size: 22, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: MutapixelTheme.of(context).ink)),
      ],
    );
  }
}

/// Premium pill chip for single-select options.
class _SelectChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _SelectChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onSelected,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? MutapixelTheme.primary
                : MutapixelTheme.of(context).subtleFill,
            borderRadius: BorderRadius.circular(999),
            border: selected
                ? null
                : Border.all(color: MutapixelTheme.of(context).hairline),
            boxShadow:
                selected ? MutapixelTheme.pillShadow : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  selected ? FontWeight.w600 : FontWeight.w500,
              color:
                  selected ? Colors.white : MutapixelTheme.of(context).ink,
            ),
          ),
        ),
      ),
    );
  }
}
