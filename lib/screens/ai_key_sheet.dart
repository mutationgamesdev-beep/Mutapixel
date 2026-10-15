import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/ai_settings.dart';
import '../theme/mutapixel_theme.dart';

/// Bottom sheet for managing the user's own OpenAI API key,
/// including the 3-step setup guide.
Future<void> showAiKeySheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _AiKeySheet(),
  );
}

class _AiKeySheet extends StatefulWidget {
  const _AiKeySheet();

  @override
  State<_AiKeySheet> createState() => _AiKeySheetState();
}

class _AiKeySheetState extends State<_AiKeySheet> {
  final _controller = TextEditingController();
  bool _hasKey = false;
  bool _obscured = true;
  String? _keyError;

  @override
  void initState() {
    super.initState();
    AiSettings.loadKey().then((key) {
      if (mounted) {
        setState(() {
          _hasKey = key != null;
          if (key != null) _controller.text = key;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final key = _controller.text.trim();
    if (key.isEmpty) return;
    if (!key.startsWith('sk-') || key.length < 20) {
      setState(() => _keyError =
          'That doesn\'t look like an API key — it should start '
          'with "sk-".');
      return;
    }
    setState(() => _keyError = null);
    await AiSettings.saveKey(key);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('API key saved. The AI is ready.')),
    );
  }

  Future<void> _remove() async {
    await AiSettings.clearKey();
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API key removed.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = MutapixelTheme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom:
              MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.key_outlined,
                    color: MutapixelTheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'AI API key',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Your key unlocks the full AI chat: conversation, '
              'pixel art, animations, and photo recreation. It is '
              'stored only on this device.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: palette.secondaryText,
              ),
            ),
            const SizedBox(height: 12),
            _step('1',
                'Go to platform.openai.com and sign in (or make an account).'),
            _step('2',
                'Add a few dollars of credit under Billing, then create an API key under API keys.'),
            _step('3', 'Paste the key below and save.'),
            const SizedBox(height: 4),
            Text(
              'About \$5 of credit makes roughly 1,000 images. '
              'Each image costs about half a cent; chatting is '
              'practically free.',
              style: TextStyle(
                fontSize: 12,
                color: palette.secondaryText,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              obscureText: _obscured,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'API key (starts with sk-)',
                errorText: _keyError,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(
                      () => _obscured = !_obscured),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          MutapixelTheme.primary,
                    ),
                    child: Text(
                        _hasKey ? 'Update key' : 'Save key'),
                  ),
                ),
                if (_hasKey) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _remove,
                    child: const Text('Remove'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: MutapixelTheme.primary
                  .withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: MutapixelTheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 13, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
