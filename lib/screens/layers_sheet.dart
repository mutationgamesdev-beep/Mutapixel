import 'package:flutter/material.dart';

import '../models/art_layer.dart';
import '../theme/mutapixel_theme.dart';
import '../widgets/template_preview.dart';

/// Photoshop-style layers panel (bottom sheet).
///
/// Rows show top layer first. Tap a row to make it the active layer;
/// the eye toggles visibility; the popup menu offers duplicate,
/// merge down, delete, and reorder actions. An opacity slider at the
/// bottom controls the active layer.
class LayersSheet extends StatefulWidget {
  final List<ArtLayer> layers;
  final int activeLayer;
  final VoidCallback onAddLayer;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onToggleVisibility;
  final ValueChanged<int> onDuplicate;
  final ValueChanged<int> onMergeDown;
  final ValueChanged<int> onDelete;
  final void Function(int from, int to) onMove;
  final void Function(int index, double opacity) onOpacity;

  const LayersSheet({
    super.key,
    required this.layers,
    required this.activeLayer,
    required this.onAddLayer,
    required this.onSelect,
    required this.onToggleVisibility,
    required this.onDuplicate,
    required this.onMergeDown,
    required this.onDelete,
    required this.onMove,
    required this.onOpacity,
  });

  @override
  State<LayersSheet> createState() => _LayersSheetState();
}

class _LayersSheetState extends State<LayersSheet> {
  /// Layer indices in display order (top layer first).
  List<int> get _displayOrder => List.generate(
      widget.layers.length, (d) => widget.layers.length - 1 - d);

  void _refresh(VoidCallback action) => setState(action);

  @override
  Widget build(BuildContext context) {
    final palette = MutapixelTheme.of(context);
    final order = _displayOrder;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Layers',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w600)),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New layer'),
                  onPressed: () =>
                      _refresh(widget.onAddLayer),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Flexible(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxHeight: 320),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: order.length,
                  itemBuilder: (context, d) {
                    final i = order[d];
                    final layer = widget.layers[i];
                    final selected = i == widget.activeLayer;
                    final isBottom = i == 0;
                    final isTop = i == widget.layers.length - 1;
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius:
                              BorderRadius.circular(14),
                          onTap: () =>
                              _refresh(() => widget.onSelect(i)),
                          child: AnimatedContainer(
                            duration: const Duration(
                                milliseconds: 150),
                            padding:
                                const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? MutapixelTheme.primary
                                      .withValues(alpha: 0.1)
                                  : palette.subtleFill,
                              borderRadius:
                                  BorderRadius.circular(14),
                              border: Border.all(
                                color: selected
                                    ? MutapixelTheme.primary
                                    : palette.hairline,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: palette.surface,
                                    borderRadius:
                                        BorderRadius.circular(
                                            8),
                                    border: Border.all(
                                        color:
                                            palette.hairline),
                                  ),
                                  child: ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(
                                            7),
                                    child: CustomPaint(
                                      painter:
                                          TemplatePreview(
                                              frame:
                                                  layer.frame),
                                      child:
                                          const SizedBox.expand(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Text(
                                        layer.name,
                                        maxLines: 1,
                                        overflow: TextOverflow
                                            .ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight:
                                              FontWeight.w600,
                                          color: layer.visible
                                              ? palette.ink
                                              : palette
                                                  .secondaryText,
                                        ),
                                      ),
                                      Text(
                                        '${(layer.opacity * 100).round()}% opacity',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: palette
                                              .secondaryText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: layer.visible
                                      ? 'Hide layer'
                                      : 'Show layer',
                                  icon: Icon(
                                    layer.visible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    size: 20,
                                    color: layer.visible
                                        ? palette.ink
                                        : palette.secondaryText,
                                  ),
                                  onPressed: () => _refresh(()
                                      => widget.onToggleVisibility(
                                          i)),
                                ),
                                PopupMenuButton<String>(
                                  tooltip: 'Layer actions',
                                  icon: Icon(
                                      Icons.more_vert,
                                      size: 20,
                                      color: palette
                                          .secondaryText),
                                  onSelected: (action) =>
                                      _refresh(() {
                                    switch (action) {
                                      case 'up':
                                        widget.onMove(i, i + 1);
                                      case 'down':
                                        widget.onMove(i, i - 1);
                                      case 'duplicate':
                                        widget
                                            .onDuplicate(i);
                                      case 'merge':
                                        widget
                                            .onMergeDown(i);
                                      case 'delete':
                                        widget.onDelete(i);
                                    }
                                  }),
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'up',
                                      enabled: !isTop,
                                      child: const Text(
                                          'Move up'),
                                    ),
                                    PopupMenuItem(
                                      value: 'down',
                                      enabled: !isBottom,
                                      child: const Text(
                                          'Move down'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'duplicate',
                                      child: Text(
                                          'Duplicate'),
                                    ),
                                    PopupMenuItem(
                                      value: 'merge',
                                      enabled: !isBottom,
                                      child: const Text(
                                          'Merge down'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      enabled: widget
                                              .layers.length >
                                          1,
                                      child: const Text(
                                          'Delete'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Opacity',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: palette.secondaryText,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: widget
                        .layers[widget.activeLayer].opacity,
                    onChanged: (v) => _refresh(() =>
                        widget.onOpacity(
                            widget.activeLayer, v)),
                  ),
                ),
                SizedBox(
                  width: 44,
                  child: Text(
                    '${(widget.layers[widget.activeLayer].opacity * 100).round()}%',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 13,
                      color: palette.secondaryText,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
