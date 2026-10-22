import 'package:flutter/material.dart';

import '../../../../core/data/mood_recording_catalog.dart';
import '../../../../core/theme/cozy_colors.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../../../core/widgets/mood_artwork.dart';

class RecordingAction extends StatelessWidget {
  const RecordingAction({
    super.key,
    required this.label,
    this.onPressed,
    this.outlined = false,
    this.busy = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool outlined, busy;
  @override
  Widget build(BuildContext context) {
    final t = context.cozyColors.recording;
    final s = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: busy,
      child: AppPressable(
        label: busy ? 'Saving check-in' : label,
        onPressed: busy ? null : onPressed,
        child: Container(
          alignment: Alignment.center,
          constraints: BoxConstraints(minHeight: t.buttonHeight),
          padding: EdgeInsets.symmetric(
            horizontal: t.large,
            vertical: t.medium,
          ),
          decoration: BoxDecoration(
            color: outlined
                ? s.surface
                : !busy && onPressed == null
                ? s.surfaceContainerHighest
                : s.primary,
            borderRadius: BorderRadius.circular(t.controlRadius),
            border: outlined ? Border.all(color: s.outlineVariant) : null,
          ),
          child: busy
              ? SizedBox.square(
                  dimension: t.iconSize,
                  child: CircularProgressIndicator(
                    strokeWidth: t.selectedBorder,
                    color: s.onPrimary,
                  ),
                )
              : Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: outlined
                        ? s.primary
                        : onPressed == null
                        ? s.onSurfaceVariant
                        : s.onPrimary,
                  ),
                ),
        ),
      ),
    );
  }
}

class RecordingPanel extends StatelessWidget {
  const RecordingPanel({
    super.key,
    required this.child,
    this.tinted = false,
    this.category = 0,
  });
  final Widget child;
  final bool tinted;
  final int category;
  @override
  Widget build(BuildContext context) {
    final t = context.cozyColors.recording;
    final s = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(t.large),
      decoration: BoxDecoration(
        color: tinted && !MediaQuery.highContrastOf(context)
            ? context.cozyColors.recordingCategoryFills[category]
            : s.surface,
        border: Border.all(
          color: s.outlineVariant.withValues(
            alpha: MediaQuery.highContrastOf(context) ? 1 : .45,
          ),
        ),
        borderRadius: BorderRadius.circular(t.panelRadius),
      ),
      child: child,
    );
  }
}

class RecordingSummary extends StatelessWidget {
  const RecordingSummary({
    super.key,
    required this.mood,
    required this.feeling,
    this.intensity,
    this.large = false,
  });
  final String mood, feeling;
  final int? intensity;
  final bool large;
  @override
  Widget build(BuildContext context) {
    final t = context.cozyColors.recording;
    final value = intensity;
    return RecordingPanel(
      tinted: true,
      child: Row(
        children: [
          if (MoodArtwork.assetFor(mood) != null) ...[
            MoodArtwork(mood: mood, size: large ? t.touch : t.faceSize),
            SizedBox(width: t.medium),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feeling,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (large && mood.isNotEmpty)
                  Text('${mood[0].toUpperCase()}${mood.substring(1)}'),
                if (value != null)
                  Text(
                    '${MoodIntensityLabels.values[moodIntensityToDisplay(value) - 1]} · ${moodIntensityToDisplay(value)}/5',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

abstract final class MoodIntensityLabels {
  static const values = ['Slight', 'Mild', 'Moderate', 'Strong', 'Very strong'];
}

class RecordingChoice extends StatelessWidget {
  const RecordingChoice({
    super.key,
    required this.name,
    required this.slug,
    required this.collection,
    required this.selected,
    required this.onPressed,
    this.category = 2,
  });
  final String name, slug, collection;
  final bool selected;
  final VoidCallback onPressed;
  final int category;
  @override
  Widget build(BuildContext context) {
    final t = context.cozyColors.recording;
    final s = Theme.of(context).colorScheme;
    final contrast = MediaQuery.highContrastOf(context);
    final accent = contrast || category == 2
        ? s.primary
        : t.categoryInks[category];
    return AppPressable(
      key: ValueKey('recording-hit-$collection-$slug'),
      checked: selected,
      onPressed: onPressed,
      child: Container(
        key: ValueKey('recording-$collection-$slug'),
        padding: EdgeInsets.all(t.small),
        decoration: BoxDecoration(
          color: contrast
              ? s.surface
              : context.cozyColors.recordingCategoryFills[category],
          borderRadius: BorderRadius.circular(t.controlRadius),
          border: Border.all(
            color: selected
                ? accent
                : contrast
                ? s.outline
                : Colors.transparent,
            width: selected ? t.selectedBorder : t.border,
          ),
        ),
        child: Row(
          children: [
            Image.asset(
              'assets/png/recording_mask_${collection}_$slug.png',
              width: t.iconSize,
              height: t.iconSize,
              color: accent,
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) => Icon(
                collection == 'coping'
                    ? Icons.favorite_border
                    : Icons.work_outline,
                size: t.iconSize,
                color: accent,
              ),
            ),
            SizedBox(width: t.small),
            Expanded(
              child: Text(name, style: Theme.of(context).textTheme.bodyMedium),
            ),
            if (selected) ...[
              SizedBox(width: t.tiny),
              Icon(Icons.check_circle, color: accent, size: t.iconSize),
            ],
          ],
        ),
      ),
    );
  }
}

/// Uses wrapping equal-width cells, never a fixed-height grid that clips large text.
class RecordingChoices extends StatelessWidget {
  const RecordingChoices({
    super.key,
    required this.options,
    required this.selected,
    required this.collection,
    required this.onToggle,
    this.category = 2,
  });
  final List<Map<String, dynamic>> options;
  final Set<String> selected;
  final String collection;
  final ValueChanged<String> onToggle;
  final int category;
  @override
  Widget build(BuildContext context) {
    final t = context.cozyColors.recording;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth >= t.twoColumnWidth &&
                MediaQuery.textScalerOf(context).scale(t.bodySize) <
                    t.singleColumnTextSize
            ? 2
            : 1;
        final width =
            (constraints.maxWidth - t.small * (columns - 1)) / columns;
        return Wrap(
          spacing: t.small,
          runSpacing: t.small,
          children: [
            for (final option in options)
              SizedBox(
                width: width,
                child: RecordingChoice(
                  name: option['name'] as String,
                  slug: option['slug'] as String,
                  collection: collection,
                  category: category,
                  selected: selected.contains(option['name']),
                  onPressed: () => onToggle(option['name'] as String),
                ),
              ),
          ],
        );
      },
    );
  }
}

class CopingResponseSheet extends StatefulWidget {
  const CopingResponseSheet({
    super.key,
    required this.options,
    required this.selected,
  });
  final List<Map<String, dynamic>> options;
  final Set<String> selected;
  @override
  State<CopingResponseSheet> createState() => _CopingResponseSheetState();
}

class _CopingResponseSheetState extends State<CopingResponseSheet> {
  late final Set<String> _pending = Set.of(widget.selected);
  final _search = TextEditingController();
  void _toggle(String name) => setState(() {
    if (!_pending.add(name)) _pending.remove(name);
  });
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.cozyColors.recording;
    final query = _search.text.trim().toLowerCase();
    final options = [
      for (final row in widget.options)
        if ((row['name'] as String).toLowerCase().contains(query)) row,
    ];
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          t.page,
          t.small,
          t.page,
          MediaQuery.viewInsetsOf(context).bottom + t.small,
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'All coping responses',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        AppPressable(
                          key: const ValueKey('coping-sheet-close'),
                          label: 'Close responses',
                          onPressed: () => Navigator.pop(context),
                          child: const Icon(Icons.close),
                        ),
                      ],
                    ),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('${widget.options.length} responses'),
                    ),
                    SizedBox(height: t.medium),
                    TextField(
                      key: const ValueKey('coping-search'),
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search responses',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _search.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                onPressed: () {
                                  _search.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close),
                              ),
                      ),
                    ),
                    if (_pending.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: t.small),
                        child: Wrap(
                          spacing: t.small,
                          runSpacing: t.small,
                          children: [
                            for (final name in _pending)
                              Padding(
                                padding: EdgeInsets.only(right: t.small),
                                child: AppPressable(
                                  label: 'Remove $name',
                                  onPressed: () => _toggle(name),
                                  child: Container(
                                    padding: EdgeInsets.all(t.small),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                        t.controlRadius,
                                      ),
                                      border: Border.all(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(child: Text(name)),
                                        SizedBox(width: t.small),
                                        Icon(Icons.close, size: t.iconSize),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${_pending.length} response${_pending.length == 1 ? '' : 's'} selected',
                        key: const ValueKey('coping-sheet-count'),
                      ),
                    ),
                    SizedBox(height: t.small),
                    if (options.isEmpty)
                      Text(
                        'No responses found. Try a different search.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      )
                    else
                      RecordingChoices(
                        options: options,
                        selected: _pending,
                        collection: 'coping',
                        onToggle: _toggle,
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: t.small),
            RecordingAction(
              key: const ValueKey('coping-sheet-apply'),
              label: 'Use selected responses',
              onPressed: () => Navigator.pop(context, Set.of(_pending)),
            ),
          ],
        ),
      ),
    );
  }
}
