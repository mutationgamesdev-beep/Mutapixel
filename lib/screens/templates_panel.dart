import 'package:flutter/material.dart';

import '../data/template_library.dart';
import '../theme/mutapixel_theme.dart';
import '../widgets/template_preview.dart';

/// Canva-style right-side templates panel for the editor.
///
/// Search field + category chips + scrollable template cards. Each card
/// is a [LongPressDraggable] so it can be dropped onto the canvas;
/// tapping a card stamps it centered instead.
class TemplatesPanel extends StatefulWidget {
  final ValueChanged<ArtTemplate> onTapTemplate;

  const TemplatesPanel({super.key, required this.onTapTemplate});

  @override
  State<TemplatesPanel> createState() => _TemplatesPanelState();
}

class _TemplatesPanelState extends State<TemplatesPanel> {
  String _category = 'all';
  String _query = '';

  List<ArtTemplate> get _visible {
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      return TemplateLibrary.all
          .where((t) => t.name.toLowerCase().contains(q))
          .toList();
    }
    if (_category == 'all') return TemplateLibrary.all;
    return TemplateLibrary.byCategory(_category);
  }

  @override
  Widget build(BuildContext context) {
    final palette = MutapixelTheme.of(context);
    final templates = _visible;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Text(
            'Templates',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: palette.ink,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            style: TextStyle(fontSize: 13, color: palette.ink),
            decoration: InputDecoration(
              hintText: 'Search templates...',
              hintStyle: TextStyle(
                  fontSize: 13, color: palette.secondaryText),
              prefixIcon: Icon(Icons.search,
                  size: 18, color: palette.secondaryText),
              filled: true,
              fillColor: palette.subtleFill,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _chip('all', 'All'),
              for (final c in TemplateLibrary.categories)
                _chip(c, TemplateLibrary.categoryLabel(c)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: templates.isEmpty
              ? Center(
                  child: Text(
                    'No templates found',
                    style: TextStyle(
                        fontSize: 13,
                        color: palette.secondaryText),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: templates.length,
                  itemBuilder: (context, i) =>
                      _draggableCard(templates[i]),
                ),
        ),
      ],
    );
  }

  Widget _chip(String value, String label) {
    final selected = _category == value && _query.trim().isEmpty;
    final palette = MutapixelTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 6, top: 4, bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => setState(() {
            _category = value;
            _query = '';
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: selected
                  ? MutapixelTheme.primary
                  : palette.subtleFill,
              borderRadius: BorderRadius.circular(999),
              border: selected
                  ? null
                  : Border.all(color: palette.hairline),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w500,
                color:
                    selected ? Colors.white : palette.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _draggableCard(ArtTemplate template) {
    final palette = MutapixelTheme.of(context);
    final card = Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.hairline),
      ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: CustomPaint(
                painter: TemplatePreview(frame: template.toFrame()),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          // Flexible (not fixed height): during the panel's expand
          // animation cards lay out very narrow, and a fixed label
          // height would overflow. Flexible shrinks gracefully.
          Flexible(
            child: Center(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  template.name,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: palette.ink),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return LongPressDraggable<ArtTemplate>(
      data: template,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 96,
          height: 110,
          decoration: BoxDecoration(
            color: palette.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: MutapixelTheme.primary, width: 2),
            boxShadow: MutapixelTheme.pillShadow,
          ),
          padding: const EdgeInsets.all(8),
          child: CustomPaint(
            painter: TemplatePreview(frame: template.toFrame()),
          ),
        ),
      ),
      childWhenDragging:
          Opacity(opacity: 0.35, child: card),
      child: GestureDetector(
        onTap: () => widget.onTapTemplate(template),
        child: card,
      ),
    );
  }
}
