import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/mutapixel_theme.dart';

/// Photoshop-style color picker dialog.
///
/// A big saturation/value field with a hue slider, numeric H/S/B and hex
/// inputs, and Photoshop's signature side-by-side **current** vs **new**
/// swatches — so shading colors can be compared before committing.
Future<Color?> showPhotoshopColorPicker({
  required BuildContext context,
  required Color initialColor,
}) {
  return showDialog<Color>(
    context: context,
    builder: (context) =>
        _PhotoshopColorPickerDialog(initialColor: initialColor),
  );
}

class _PhotoshopColorPickerDialog extends StatefulWidget {
  final Color initialColor;

  const _PhotoshopColorPickerDialog({required this.initialColor});

  @override
  State<_PhotoshopColorPickerDialog> createState() =>
      _PhotoshopColorPickerDialogState();
}

class _PhotoshopColorPickerDialogState
    extends State<_PhotoshopColorPickerDialog> {
  late HSVColor _new;
  late final Color _current;

  final _hCtrl = TextEditingController();
  final _sCtrl = TextEditingController();
  final _bCtrl = TextEditingController();
  final _hexCtrl = TextEditingController();
  final _hFocus = FocusNode();
  final _sFocus = FocusNode();
  final _bFocus = FocusNode();
  final _hexFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _current = widget.initialColor;
    _new = HSVColor.fromColor(widget.initialColor);
    _syncFields();
  }

  @override
  void dispose() {
    _hCtrl.dispose();
    _sCtrl.dispose();
    _bCtrl.dispose();
    _hexCtrl.dispose();
    _hFocus.dispose();
    _sFocus.dispose();
    _bFocus.dispose();
    _hexFocus.dispose();
    super.dispose();
  }

  /// Push the current HSV values into the text fields, unless the user
  /// is actively typing in one of them.
  void _syncFields() {
    if (!_hFocus.hasFocus) _hCtrl.text = _new.hue.round().toString();
    if (!_sFocus.hasFocus) {
      _sCtrl.text = (_new.saturation * 100).round().toString();
    }
    if (!_bFocus.hasFocus) _bCtrl.text = (_new.value * 100).round().toString();
    if (!_hexFocus.hasFocus) {
      final c = _new.toColor();
      _hexCtrl.text =
          '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    }
  }

  void _update(HSVColor next) {
    setState(() {
      _new = next;
      _syncFields();
    });
  }

  void _pickSV(Offset local, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final s = (local.dx / size.width).clamp(0.0, 1.0);
    final v = (1.0 - local.dy / size.height).clamp(0.0, 1.0);
    _update(_new.withSaturation(s).withValue(v));
  }

  void _pickHue(double dy, double height) {
    if (height <= 0) return;
    final h = (dy / height * 360).clamp(0.0, 360.0);
    _update(_new.withHue(h == 360 ? 0 : h));
  }

  void _submitHSB() {
    final h = (int.tryParse(_hCtrl.text) ?? _new.hue.round())
        .clamp(0, 360)
        .toDouble();
    final s = (int.tryParse(_sCtrl.text) ?? (_new.saturation * 100).round())
        .clamp(0, 100) /
        100;
    final v = (int.tryParse(_bCtrl.text) ?? (_new.value * 100).round())
        .clamp(0, 100) /
        100;
    _update(HSVColor.fromAHSV(1, h == 360 ? 0 : h, s, v));
  }

  void _submitHex() {
    var text = _hexCtrl.text.trim().replaceAll('#', '');
    if (text.length == 3) {
      text = text.split('').map((c) => '$c$c').join();
    }
    final value = int.tryParse(text, radix: 16);
    if (value == null || text.length != 6) {
      _syncFields();
      setState(() {});
      return;
    }
    _update(HSVColor.fromColor(Color(0xFF000000 | value)));
  }

  @override
  Widget build(BuildContext context) {
    final palette = MutapixelTheme.of(context);
    return AlertDialog(
      backgroundColor: palette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Color picker'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- big saturation/value field + hue slider ---
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = constraints.biggest;
                        return GestureDetector(
                          key: const Key('ps-sv-area'),
                          behavior: HitTestBehavior.opaque,
                          onPanDown: (d) => _pickSV(d.localPosition, size),
                          onPanUpdate: (d) => _pickSV(d.localPosition, size),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CustomPaint(
                              painter: _SVPainter(
                                hue: _new.hue,
                                saturation: _new.saturation,
                                value: _new.value,
                              ),
                              child: const SizedBox.expand(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final height = constraints.maxHeight;
                      return GestureDetector(
                        key: const Key('ps-hue-slider'),
                        behavior: HitTestBehavior.opaque,
                        onPanDown: (d) => _pickHue(d.localPosition.dy, height),
                        onPanUpdate: (d) =>
                            _pickHue(d.localPosition.dy, height),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CustomPaint(
                            painter: _HuePainter(hue: _new.hue),
                            child: const SizedBox(width: 26, height: double.infinity),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // --- current vs new swatches ---
            Row(
              children: [
                Expanded(
                  child: _swatch(
                    key: const Key('ps-current-swatch'),
                    label: 'current',
                    color: _current,
                    palette: palette,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _swatch(
                    key: const Key('ps-new-swatch'),
                    label: 'new',
                    color: _new.toColor(),
                    palette: palette,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // --- H/S/B numeric fields ---
            Row(
              children: [
                Expanded(
                  child: _numberField(
                    label: 'H',
                    controller: _hCtrl,
                    focusNode: _hFocus,
                    palette: palette,
                    onSubmitted: (_) => _submitHSB(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _numberField(
                    label: 'S',
                    controller: _sCtrl,
                    focusNode: _sFocus,
                    palette: palette,
                    onSubmitted: (_) => _submitHSB(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _numberField(
                    label: 'B',
                    controller: _bCtrl,
                    focusNode: _bFocus,
                    palette: palette,
                    onSubmitted: (_) => _submitHSB(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _numberField(
                    key: const Key('ps-hex-field'),
                    label: '#',
                    controller: _hexCtrl,
                    focusNode: _hexFocus,
                    palette: palette,
                    hex: true,
                    onSubmitted: (_) => _submitHex(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_new.toColor()),
          child: const Text('Use color'),
        ),
      ],
    );
  }

  Widget _swatch({
    required Key key,
    required String label,
    required Color color,
    required MutapixelPalette palette,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(color: palette.secondaryText, fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          key: key,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: palette.hairline),
          ),
        ),
      ],
    );
  }

  Widget _numberField({
    Key? key,
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required MutapixelPalette palette,
    required ValueChanged<String> onSubmitted,
    bool hex = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(color: palette.secondaryText, fontSize: 12)),
        const SizedBox(height: 4),
        SizedBox(
          height: 40,
          child: TextField(
            key: key,
            controller: controller,
            focusNode: focusNode,
            keyboardType: hex ? TextInputType.text : TextInputType.number,
            inputFormatters: hex
                ? [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F#]')),
                    LengthLimitingTextInputFormatter(7),
                  ]
                : [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.ink, fontSize: 13),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: palette.hairline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: palette.hairline),
              ),
            ),
            onSubmitted: onSubmitted,
          ),
        ),
      ],
    );
  }
}

/// The big Photoshop color field: horizontal = saturation,
/// vertical = brightness, at the currently selected hue.
class _SVPainter extends CustomPainter {
  final double hue;
  final double saturation;
  final double value;

  _SVPainter(
      {required this.hue, required this.saturation, required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
        rect, Paint()..color = HSVColor.fromAHSV(1, hue, 1, 1).toColor());
    canvas.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            colors: [Colors.white, Colors.transparent],
          ).createShader(rect));
    canvas.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black],
          ).createShader(rect));

    // Crosshair at the current saturation/value.
    final marker = Offset(saturation * size.width, (1 - value) * size.height);
    canvas.drawCircle(
        marker,
        9,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white);
    canvas.drawCircle(
        marker,
        9,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = Colors.black.withValues(alpha: 0.35));
  }

  @override
  bool shouldRepaint(_SVPainter old) =>
      old.hue != hue || old.saturation != saturation || old.value != value;
}

/// Vertical rainbow hue slider with a position marker.
class _HuePainter extends CustomPainter {
  final double hue;

  _HuePainter({required this.hue});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              for (var h = 0; h <= 360; h += 60)
                HSVColor.fromAHSV(1, h.toDouble(), 1, 1).toColor(),
            ],
          ).createShader(rect));

    final y = (hue / 360 * size.height).clamp(0.0, size.height);
    final marker = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(size.width / 2, y), width: size.width - 4, height: 6),
      const Radius.circular(3),
    );
    canvas.drawRRect(
        marker,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white);
  }

  @override
  bool shouldRepaint(_HuePainter old) => old.hue != hue;
}
