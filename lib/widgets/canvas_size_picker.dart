import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/canvas_preset.dart';
import '../theme/mutapixel_theme.dart';

/// Shows the canvas size picker: named presets ("Hero 128 — heroes &
/// portraits") plus a custom size field (8–512 px). Returns the chosen
/// square edge length, or null when dismissed.
Future<int?> showCanvasSizePicker(BuildContext context) {
  return showDialog<int>(
    context: context,
    builder: (context) => const _CanvasSizeDialog(),
  );
}

class _CanvasSizeDialog extends StatefulWidget {
  const _CanvasSizeDialog();

  @override
  State<_CanvasSizeDialog> createState() => _CanvasSizeDialogState();
}

class _CanvasSizeDialogState extends State<_CanvasSizeDialog> {
  bool _customOpen = false;
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitCustom() {
    final error = StringBuffer();
    final size = parseCustomCanvasSize(_controller.text, error: error);
    if (size == null) {
      setState(() => _error = error.toString());
      return;
    }
    Navigator.of(context).pop(size);
  }

  @override
  Widget build(BuildContext context) {
    final palette = MutapixelTheme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: 340,
        padding: const EdgeInsets.fromLTRB(8, 20, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Canvas size',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final preset in canvasPresets)
                      _presetRow(preset, palette),
                    const Divider(height: 16),
                    _customRow(palette),
                    if (_customOpen) _customField(palette),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _presetRow(CanvasPreset preset, MutapixelPalette palette) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).pop(preset.size),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${preset.name} · ${preset.label}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    preset.blurb,
                    style: TextStyle(
                      fontSize: 12,
                      color: palette.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: palette.secondaryText, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _customRow(MutapixelPalette palette) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _customOpen = !_customOpen),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Custom size…',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Type the exact pixels you need',
                    style: TextStyle(
                      fontSize: 12,
                      color: palette.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              _customOpen
                  ? Icons.expand_less
                  : Icons.expand_more,
              color: palette.secondaryText,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _customField(MutapixelPalette palette) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  decoration: InputDecoration(
                    hintText: 'e.g. 96',
                    helperText:
                        '$minCustomCanvasSize–$maxCustomCanvasSize px, square',
                    errorText: _error,
                    border: const OutlineInputBorder(),
                    contentPadding:
                        const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                  ),
                  onSubmitted: (_) => _submitCustom(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _submitCustom,
                style: FilledButton.styleFrom(
                  backgroundColor: MutapixelTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Create'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
