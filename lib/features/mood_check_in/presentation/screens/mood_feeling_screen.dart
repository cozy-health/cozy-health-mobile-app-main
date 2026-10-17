import 'mood_intensity_control.dart';
import '../../../../core/theme/cozy_colors.dart';
import 'mood_recording_layout.dart';
import '../../../../core/widgets/app_scroll_body.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../../core/theme/app_surface.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/data/mood_recording_catalog.dart';
import '../../../../core/models/mood_entry.dart';
import '../../../../core/repositories/mood_repository.dart';
import '../../../../core/repositories/wellness_repository.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/mood_draft_service.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/security_blur.dart';
import '../../../crisis/presentation/screens/crisis_screens.dart';
import '../../../crisis/services/crisis_detector.dart';

class MoodFeelingScreen extends StatefulWidget {
  const MoodFeelingScreen({super.key, this.entry, this.initialMood});
  final MoodEntry? entry;
  final String? initialMood;

  @override
  State<MoodFeelingScreen> createState() => _MoodFeelingScreenState();
}

class _MoodFeelingScreenState extends State<MoodFeelingScreen> {
  static const _groups = [
    'Angry',
    'Sad',
    'Good',
    'Upset',
    'Spectacular',
    'Happy',
  ];
  static const _causeGroups = [
    'Work',
    'School',
    'Relationship',
    'Sleep',
    'Health',
    'Life changes',
  ];
  static const _icons = [
    Icons.hourglass_empty,
    Icons.school_outlined,
    Icons.people_outline,
    Icons.bedtime_outlined,
    Icons.favorite_border,
    Icons.home_outlined,
  ];
  final _drafts = MoodDraftService();
  final _scroll = ScrollController();
  String _id = const Uuid().v4();
  final Set<String> _causes = {}, _coping = {};
  Map<String, dynamic> _catalog = moodRecordingCatalog;
  Map<String, dynamic>? _resume;
  Map<String, dynamic> _legacy = {};
  Future<void> _writes = Future.value();
  String? _mood, _expression;
  int _step = 0, _storedIntensity = 6;
  bool _saving = false, _loadingDraft = true, _closing = false;

  List<Map<String, dynamic>> _rows(String key) => (_catalog[key] as List)
      .map((r) => Map<String, dynamic>.from(r as Map))
      .toList();

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _mood = entry?.mood ?? widget.initialMood;
    if (entry != null) {
      _expression = entry.expressionSlug;
      _storedIntensity = entry.intensity;
      _causes.addAll(entry.triggers ?? []);
      _coping.addAll(entry.copingStrategies ?? []);
      _legacy = {
        'body': entry.bodySensations,
        'custom_trigger': entry.customTrigger,
        'sleep': entry.sleepQuality,
        'energy': entry.energyLevel,
        'note': entry.note,
        'coping_helped': entry.copingHelped,
      };
      _loadingDraft = false;
    } else {
      _loadDraft();
    }
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    final catalog = await WellnessRepository().catalog();
    if (!mounted || catalog == null || catalog['mood_recording_version'] != 2) {
      return;
    }
    if ([
      'moods',
      'expressions',
      'triggers',
      'coping',
    ].every((key) => catalog[key] is List)) {
      setState(() => _catalog = catalog);
    }
  }

  Future<void> _loadDraft() async {
    Map<String, dynamic>? draft;
    try {
      draft = await _drafts.loadToday();
    } catch (_) {
      /* Fresh recording remains available. */
    }
    if (mounted) {
      setState(() {
        _resume = draft;
        _loadingDraft = false;
      });
    }
  }

  Map<String, dynamic> _draft() => {
    ..._legacy,
    'version': 2,
    'id': _id,
    'step': _step,
    'mood': _mood,
    'expression_slug': _expression,
    'intensity': _storedIntensity,
    'triggers': _causes.toList(),
    'coping': _coping.toList(),
  };

  void _queueDraft() {
    if (widget.entry != null || _resume != null || _loadingDraft) return;
    final draft = _draft();
    _writes = _writes.then((_) => _drafts.save(draft)).catchError((Object _) {
      if (mounted) {
        AppSnackbar.show(
          context,
          AppSnackbar.error(
            "We couldn't save this draft. Please keep this screen open and try again.",
          ),
        );
      }
    });
  }

  void _resumeDraft() {
    final draft = migrateMoodRecordingDraft(_resume!);
    setState(() {
      _legacy = Map.of(draft);
      final id = draft['id'] as String?;
      if (id != null && Uuid.isValidUUID(fromString: id)) {
        _id = id;
      }
      _mood = draft['mood'] as String?;
      _expression = draft['expression_slug'] as String?;
      _storedIntensity = draft['intensity'] as int? ?? 6;
      _causes.addAll(List<String>.from(draft['triggers'] as List? ?? []));
      _coping.addAll(List<String>.from(draft['coping'] as List? ?? []));
      _step = draft['step'] as int;
      _resume = null;
    });
  }

  Future<void> _clearDraft() async {
    await _writes;
    await _drafts.clear();
    if (mounted) setState(() => _resume = null);
  }

  void _go(int step) {
    setState(() => _step = step);
    if (_scroll.hasClients) _scroll.jumpTo(0);
    _queueDraft();
  }

  void _exit() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRouter.home);
    }
  }

  Future<void> _close() async {
    if (_saving || _closing) return;
    _closing = true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard this entry?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    _closing = false;
    if (discard != true || !mounted) return;
    try {
      if (widget.entry == null) await _clearDraft();
    } catch (_) {
      if (mounted) {
        AppSnackbar.show(
          context,
          AppSnackbar.error("We couldn't discard your draft. Try again."),
        );
      }
      return;
    }
    if (mounted) _exit();
  }

  void _back() {
    if (_saving || _closing) return;
    if (_step > 0) {
      _go(_step - 1);
    } else {
      _close();
    }
  }

  Future<void> _selectFeeling(
    Map<String, dynamic> mood,
    Map<String, dynamic> feeling,
  ) async {
    var value = _expression == feeling['slug']
        ? moodIntensityToDisplay(_storedIntensity)
        : 3;
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: StatefulBuilder(
          builder: (context, update) {
            final theme = Theme.of(context);
            final scheme = theme.colorScheme;
            return Dialog(
              key: const ValueKey('recording-intensity-dialog'),
              constraints: const BoxConstraints(maxWidth: 360),
              backgroundColor:
                  theme.dialogTheme.backgroundColor ?? scheme.surface,
              surfaceTintColor: Colors.transparent,
              shape: AppSurface.shape(context, BorderRadius.circular(24)),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              child: SizedBox(
                key: const ValueKey('recording-intensity-body'),
                width: 360,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'How intense is this feeling?',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          feeling['name'] as String,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        MoodIntensityControl(
                          value: value,
                          feeling: feeling['name'] as String,
                          onChanged: (next) => update(() => value = next),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, value),
                            child: const Text('Done'),
                          ),
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
    );
    if (result == null || !mounted) return;
    setState(() {
      _mood = mood['slug'] as String;
      _expression = feeling['slug'] as String;
      _storedIntensity = moodIntensityToStorage(result);
    });
    _queueDraft();
  }

  Future<void> _save() async {
    if (_saving || _mood == null) return;
    setState(() => _saving = true);
    final old = widget.entry;
    final note = _legacy['note'] as String?;
    const detector = CrisisDetector();
    final signal = detector.analyze(note ?? '');
    final crisis = detector.canTrigger('mood', signal);
    final draftId = _legacy['id'] as String?;
    final entry = MoodEntry(
      id:
          old?.id ??
          (draftId != null && Uuid.isValidUUID(fromString: draftId)
              ? draftId
              : _id),
      mood: _mood!,
      expressionSlug: _expression,
      intensity: _storedIntensity,
      triggers: _causes.toList(),
      copingStrategies: _coping.toList(),
      bodySensations: (_legacy['body'] as List?)?.cast<String>(),
      customTrigger: _legacy['custom_trigger'] as String?,
      sleepQuality: _legacy['sleep'] as int?,
      energyLevel: _legacy['energy'] as int?,
      note: note,
      copingHelped: _legacy['coping_helped'] as String?,
      isCrisisFlagged: crisis || (old?.isCrisisFlagged ?? false),
      createdAt: old?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    try {
      await MoodRepository().save(entry);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        AppSnackbar.show(
          context,
          AppSnackbar.error(
            "We couldn't save your check-in. Your draft is still here.",
            onRetry: _save,
          ),
        );
      }
      return;
    }
    if (old == null) {
      try {
        await _clearDraft();
      } catch (_) {
        /* The entry is already saved. */
      }
    }
    if (!mounted) return;
    if (crisis) {
      detector.markTriggered('mood');
      await showCrisisSupportOverlay(context, signal: signal);
      if (!mounted) return;
    }
    context.go(AppRouter.moodSuccess);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled =
        !_loadingDraft &&
        _resume == null &&
        !_saving &&
        (_step != 0 || _expression != null || widget.entry != null);
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SecurityBlur(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 5, 8, 1),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: _saving ? null : _back,
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurfaceVariant,
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.chevron_left, size: 18),
                            Text('Back'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: const [
                              74 / 215,
                              145 / 215,
                              178 / 215,
                              1.0,
                            ][_step],
                            minHeight: 4,
                            color: theme.colorScheme.primary,
                            backgroundColor: theme.colorScheme.outlineVariant
                                .withValues(alpha: .35),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: _saving ? null : _close,
                        tooltip: 'Close check-in',
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                if (_resume != null)
                  MaterialBanner(
                    content: const Text(
                      'You have an unsaved check-in. Resume?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: _resumeDraft,
                        child: const Text('Resume'),
                      ),
                      TextButton(
                        onPressed: () async {
                          try {
                            await _clearDraft();
                          } catch (_) {
                            if (context.mounted) {
                              AppSnackbar.show(
                                context,
                                AppSnackbar.error(
                                  "We couldn't discard your draft.",
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Discard'),
                      ),
                    ],
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(15, 0, 15, 24),
                    child: IgnorePointer(
                      ignoring: _saving || _resume != null || _loadingDraft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            [
                              'How would you describe how you are feeling?',
                              'What made you feel this way?',
                              'How have you expressed these feelings?',
                              'Review your check-in',
                            ][_step],
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (_step == 0) ..._feelingCards(),
                          if (_step == 1) ..._causeCards(),
                          if (_step == 2)
                            _panel(
                              'Coping Mechanisms',
                              _chips('coping', _rows('coping'), 2, _coping),
                            ),
                          if (_step == 3) ..._review(),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: enabled
                          ? () {
                              if (_step == 3) {
                                _save();
                              } else {
                                _go(_step + 1);
                              }
                            }
                          : null,
                      child: _saving
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : Text(_step == 3 ? 'Save entry' : 'Continue'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggle(Set<String> values, String value) {
    setState(() {
      if (!values.add(value)) values.remove(value);
    });
    _queueDraft();
  }

  List<Widget> _feelingCards() {
    final moods = _rows('moods');
    final expressions = _rows('expressions');
    return [
      for (var i = 0; i < _groups.length; i++)
        for (final mood in moods.where(
          (m) => m['slug'] == _groups[i].toLowerCase(),
        ))
          _panel(
            mood['name'] as String,
            _chips(
              'expressions',
              expressions.where((e) => e['feeling_id'] == mood['id']).toList(),
              i,
              null,
              mood: mood,
            ),
          ),
    ];
  }

  List<Widget> _causeCards() {
    final rows = _rows('triggers');
    final groups = [
      ..._causeGroups,
      ...rows
          .map((r) => r['group_name'] as String? ?? 'Other')
          .where((g) => !_causeGroups.contains(g))
          .toSet(),
    ];
    return [
      for (var i = 0; i < groups.length; i++)
        if (rows.any((r) => (r['group_name'] ?? 'Other') == groups[i]))
          _panel(
            groups[i],
            _chips(
              'triggers',
              rows
                  .where((r) => (r['group_name'] ?? 'Other') == groups[i])
                  .toList(),
              i % 6,
              _causes,
            ),
          ),
    ];
  }

  Widget _chips(
    String collection,
    List<Map<String, dynamic>> options,
    int category,
    Set<String>? selection, {
    Map<String, dynamic>? mood,
  }) {
    final pending = {for (final row in options) row['slug'] as String: row};
    final rows = <List<Map<String, dynamic>>>[];
    for (final reference in moodRecordingReferenceRows[collection]!) {
      final row = [
        for (final slug in reference)
          if (pending.containsKey(slug)) pending.remove(slug)!,
      ];
      if (row.isNotEmpty) rows.add(row);
    }
    if (pending.isNotEmpty) rows.add(pending.values.toList());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          Wrap(
            key: ValueKey('recording-row-${rows[i].first['slug']}'),
            spacing: 10,
            runSpacing: 12,
            children: [
              for (final row in rows[i])
                _chip(
                  collection,
                  row,
                  category,
                  selection == null
                      ? _expression == row['slug']
                      : selection.contains(row['name']),
                  () {
                    if (mood != null) {
                      _selectFeeling(mood, row);
                    } else {
                      _toggle(selection!, row['name'] as String);
                    }
                  },
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _panel(String title, Widget child) => Container(
    width: double.infinity,
    margin: EdgeInsets.only(bottom: _step == 1 ? 24 : 16),
    padding: const EdgeInsets.fromLTRB(9, 12, 9, 16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: AppSurface.border(context),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: 16,
            height: 1.25,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );

  Widget _chip(
    String collection,
    Map<String, dynamic> row,
    int category,
    bool selected,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final contrast = MediaQuery.highContrastOf(context);
    final fill = contrast
        ? (selected ? scheme.primary : scheme.surface)
        : context.cozyColors.recordingCategoryFills[category];
    final preferredForeground = contrast && selected
        ? scheme.onPrimary
        : scheme.onSurface;
    double contrastRatio(Color ink) {
      final a = ink.computeLuminance();
      final b = fill.computeLuminance();
      return (a > b ? a + .05 : b + .05) / (a > b ? b + .05 : a + .05);
    }

    final foreground = contrastRatio(preferredForeground) >= 4.5
        ? preferredForeground
        : contrastRatio(Colors.black) > contrastRatio(Colors.white)
        ? Colors.black
        : Colors.white;
    return Semantics(
      button: true,
      selected: selected,
      label: row['name'] as String,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        key: ValueKey('recording-$collection-${row['slug']}'),
        color: fill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected
                ? (contrast ? scheme.onSurface : scheme.primary)
                : (contrast ? scheme.outline : Colors.transparent),
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _art(
                      collection,
                      row,
                      category,
                      foreground,
                      selected: contrast && selected,
                    ),
                    if (selected)
                      Positioned(
                        right: -3,
                        bottom: -3,
                        child: Container(
                          decoration: BoxDecoration(
                            color: fill,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            size: 12,
                            color: foreground,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    row['name'] as String,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _art(
    String collection,
    Map<String, dynamic> row,
    int category,
    Color foreground, {
    bool selected = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final bundled = (moodRecordingCatalog[collection] as List).any(
      (item) => item['slug'] == row['slug'],
    );
    if (collection == 'expressions') {
      if (!bundled) {
        return Text(
          row['emoji'] as String? ?? '',
          style: const TextStyle(fontSize: 24),
        );
      }
      return Image.asset(
        Theme.of(context).brightness == Brightness.dark ||
                MediaQuery.highContrastOf(context)
            ? 'assets/png/recording_emoji_${row['slug']}.png'
            : 'assets/png/recording_${collection}_${row['slug']}.png',
        width: 24,
        height: 24,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
      );
    }
    final ink = scheme.primary.computeLuminance();
    final background = scheme.surface.computeLuminance();
    final ratio = ink > background
        ? (ink + .05) / (background + .05)
        : (background + .05) / (ink + .05);
    final readableAccent = selected || ratio < 3 ? foreground : scheme.primary;
    final fallback = Icon(
      collection == 'coping' ? Icons.favorite_border : _icons[category],
      size: 18,
      color: readableAccent,
    );
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: MediaQuery.highContrastOf(context)
            ? Colors.transparent
            : scheme.primary.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: bundled
          ? Image.asset(
              'assets/png/recording_mask_${collection}_${row['slug']}.png',
              fit: BoxFit.contain,
              color: readableAccent,
              colorBlendMode: BlendMode.srcIn,
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) => fallback,
            )
          : fallback,
    );
  }

  List<Widget> _review() => [
    _reviewRow(
      'Feeling',
      '${_expression == null ? _mood ?? "Not selected" : moodExpressionLabel(_expression!)} (${_mood ?? ""})\nIntensity: ${moodIntensityToDisplay(_storedIntensity)}/5',
      0,
    ),
    _reviewRow(
      'Causes',
      _causes.isEmpty ? 'None selected' : _causes.join(', '),
      1,
    ),
    _reviewRow(
      'Coping mechanisms',
      _coping.isEmpty ? 'None selected' : _coping.join(', '),
      2,
    ),
  ];

  Widget _reviewRow(String title, String value, int step) => _panel(
    title,
    Row(
      children: [
        Expanded(child: Text(value)),
        IconButton(
          tooltip: 'Edit $title',
          onPressed: _saving ? null : () => _go(step),
          icon: const Icon(Icons.edit_outlined),
        ),
      ],
    ),
  );
}

class MoodCheckInSuccessScreen extends StatefulWidget {
  const MoodCheckInSuccessScreen({super.key});

  @override
  State<MoodCheckInSuccessScreen> createState() =>
      _MoodCheckInSuccessScreenState();
}

class _MoodCheckInSuccessScreenState extends State<MoodCheckInSuccessScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        AppSnackbar.fromLegacy(content: Text('Entry saved.')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: AppScrollBody(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!reduceMotion) ...[
                      const Positioned(top: 4, left: 80, child: _Sparkle()),
                      const Positioned(
                        bottom: 10,
                        right: 70,
                        child: _Sparkle(size: 5),
                      ),
                      const Positioned(
                        top: 28,
                        right: 102,
                        child: _Sparkle(size: 4),
                      ),
                    ],
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: AppColors.success,
                        size: 52,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 34),
                Text(
                  'Entry saved.',
                  style: AppTextStyles.heading1.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Thanks for checking\nin with yourself.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body1.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 42),
                _PrimaryButton(
                  label: 'Back to Home',
                  onPressed: () => context.go(AppRouter.home),
                ),
                const SizedBox(height: 12),
                _SecondaryButton(
                  label: 'Log another',
                  onPressed: () => context.go(AppRouter.moodFeeling),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.push(AppRouter.moodHistory),
                  child: const Text('See past entries'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MoodHistoryScreen extends StatelessWidget {
  const MoodHistoryScreen({super.key, this.selectedDay});
  final DateTime? selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<MoodEntry>>(
          stream: MoodRepository().watchMoodEntries(),
          initialData: LocalDbService().getAllMoodEntries(),
          builder: (context, snapshot) {
            final entries = (snapshot.data ?? const <MoodEntry>[]).where((
              entry,
            ) {
              if (selectedDay == null) return true;
              final day = entry.createdAt.toLocal();
              return day.year == selectedDay!.year &&
                  day.month == selectedDay!.month &&
                  day.day == selectedDay!.day;
            }).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          context.go(AppRouter.home);
                        }
                      },
                      icon: Icon(
                        Icons.arrow_back,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Mood history',
                        style: AppTextStyles.heading2.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData)
                  const SizedBox(height: 320, child: ListSkeleton())
                else if (entries.isEmpty)
                  EmptyState(
                    onOfflineRetry: () => MoodRepository().fetchMoodEntries(),
                    icon: Icons.mood_rounded,
                    title: 'Your moods will appear here.',
                    primaryCtaLabel: 'Log a mood',
                    onPrimaryCta: () => context.push(AppRouter.moodFeeling),
                  )
                else ...[
                  Text(
                    '${entries.length} ${entries.length == 1 ? 'entry' : 'entries'}',
                    style: AppTextStyles.body2.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final entry in entries) ...[
                    _MoodHistoryCard(entry: entry),
                    const SizedBox(height: 12),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MoodHistoryCard extends StatelessWidget {
  const _MoodHistoryCard({required this.entry});

  final MoodEntry entry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${entry.displayFeeling}, intensity ${entry.intensity} of 10',
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push(AppRouter.moodDetail, extra: entry),
        child: _WarmPanel(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  border: AppSurface.border(context),
                  color: AppSurface.tint(context, AppColors.primarySoft),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    entry.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.displayFeeling,
                      style: AppTextStyles.body1.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatMoodDate(entry.createdAt),
                      style: AppTextStyles.body2.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if ((entry.note ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        entry.note!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body2.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                '${entry.intensity}/10',
                style: AppTextStyles.body2.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MoodDetailViewScreen extends StatelessWidget {
  const MoodDetailViewScreen({super.key, this.entry});

  final MoodEntry? entry;

  @override
  Widget build(BuildContext context) =>
      SecurityBlur(child: _buildProtected(context));

  Widget _buildProtected(BuildContext context) {
    final moodEntry = entry;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.arrow_back),
                  ),
                  const Spacer(),
                  if (moodEntry != null)
                    TextButton(
                      onPressed: () =>
                          context.push(AppRouter.moodFeeling, extra: moodEntry),
                      child: const Text('Edit'),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              if (moodEntry == null)
                _WarmPanel(
                  child: Text(
                    'Mood entry not found.',
                    style: AppTextStyles.body1.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                )
              else ...[
                Text(moodEntry.emoji, style: const TextStyle(fontSize: 64)),
                Text(
                  moodEntry.displayFeeling,
                  style: AppTextStyles.heading1.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatMoodDate(moodEntry.createdAt),
                  style: AppTextStyles.body2.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 30),
                _DetailRow('Intensity: ${moodEntry.intensity}/10'),
                if ((moodEntry.bodySensations ?? []).isNotEmpty)
                  _DetailRow('Body: ${moodEntry.bodySensations!.join(', ')}'),
                if ((moodEntry.triggers ?? []).isNotEmpty)
                  _DetailRow('Triggers: ${moodEntry.triggers!.join(', ')}'),
                if ((moodEntry.customTrigger ?? '').isNotEmpty)
                  _DetailRow('Other trigger: ${moodEntry.customTrigger}'),
                if (moodEntry.sleepQuality != null &&
                    moodEntry.sleepQuality! > 0)
                  _DetailRow('Sleep: ${moodEntry.sleepQuality}/5'),
                if (moodEntry.energyLevel != null && moodEntry.energyLevel! > 0)
                  _DetailRow('Energy: ${moodEntry.energyLevel}/10'),
                if ((moodEntry.copingStrategies ?? []).isNotEmpty)
                  _DetailRow(
                    'Coping: ${moodEntry.copingStrategies!.join(', ')}',
                  ),
                if ((moodEntry.note ?? '').isNotEmpty)
                  _DetailRow('Note\n"${moodEntry.note}"'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _formatMoodDate(DateTime date) {
  final local = date.toLocal();
  final now = DateTime.now();
  final sameDay =
      local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  final dayLabel = sameDay
      ? 'Today'
      : '${local.month}/${local.day}/${local.year}';
  return '$dayLabel, $hour:$minute $period';
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 48,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label),
    ),
  );
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          side: BorderSide(color: Theme.of(context).colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _WarmPanel extends StatelessWidget {
  const _WarmPanel({
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: dark ? AppColors.surfaceSubtleDark : AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: dark ? AppColors.borderDefaultDark : AppColors.borderDefault,
        ),
      ),
      child: child,
    );
  }
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({this.size = 7});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.warmYellow,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _WarmPanel(
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: AppTextStyles.body1.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}
