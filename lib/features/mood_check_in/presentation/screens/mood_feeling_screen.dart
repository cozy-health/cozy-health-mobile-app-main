import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/data/mood_recording_catalog.dart';
import '../../../../core/models/mood_entry.dart';
import '../../../../core/repositories/mood_repository.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_surface.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/cozy_colors.dart';
import '../../../../core/utils/motion.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../../../core/widgets/app_scroll_body.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/mood_artwork.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/security_blur.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../crisis/presentation/screens/crisis_screens.dart';
import '../../../crisis/services/crisis_detector.dart';
import '../mood_recording_controller.dart';
import 'mood_intensity_control.dart';
import '../../../../core/widgets/mood_category_grid.dart';
import 'mood_recording_widgets.dart';

class MoodFeelingScreen extends StatefulWidget {
  const MoodFeelingScreen({
    super.key,
    this.entry,
    this.initialMood,
    this.controller,
  });
  final MoodEntry? entry;
  final String? initialMood;
  final MoodRecordingController? controller;
  @override
  State<MoodFeelingScreen> createState() => _MoodFeelingScreenState();
}

class _MoodFeelingScreenState extends State<MoodFeelingScreen> {
  static const _causeGroups = [
    'Work',
    'School',
    'Relationship',
    'Sleep',
    'Health',
    'Life changes',
  ];
  static const _icons = [
    Icons.work_outline,
    Icons.school_outlined,
    Icons.people_outline,
    Icons.bedtime_outlined,
    Icons.favorite_border,
    Icons.home_outlined,
  ];
  final _scroll = ScrollController();
  String? _visibleCategory;
  String? _lastAnswerMood, _lastAnswerExpression;
  final Set<String> _expanded = {'Work', 'Previously selected'};
  late final MoodRecordingController _flow;
  MoodRecordingStep? _lastStep;
  String? _lastError;
  bool _closing = false;
  int get _step => _flow.state.step.index;
  List<Map<String, dynamic>> _rows(String key) => _flow.rows(key);
  @override
  void initState() {
    super.initState();
    _flow =
        widget.controller ??
        MoodRecordingController(
          entry: widget.entry,
          initialMood: widget.initialMood,
        );
    _visibleCategory = _flow.state.mood;
    _flow.addListener(_onFlow);
    _openSelectedGroups();
    unawaited(_flow.initialize());
  }

  void _openSelectedGroups() {
    for (final row in _rows('triggers')) {
      if (_flow.state.causes.contains(row['name'])) {
        _expanded.add(row['group_name'] as String? ?? 'Other');
      }
    }
  }

  void _onFlow() {
    if (!mounted) return;
    if (_flow.error == null) _lastError = null;
    final stage = _flow.state.step;
    final changed = _lastStep != stage;
    _lastStep = stage;
    if (stage == MoodRecordingStep.feeling &&
        (changed ||
            _visibleCategory == null ||
            _lastAnswerMood != _flow.state.mood ||
            _lastAnswerExpression != _flow.state.expression)) {
      _visibleCategory = _flow.state.mood;
    }
    _lastAnswerMood = _flow.state.mood;
    _lastAnswerExpression = _flow.state.expression;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (changed && _scroll.hasClients) _scroll.jumpTo(0);
      if (_flow.error != null && _flow.error != _lastError) {
        _lastError = _flow.error;
        AppSnackbar.show(context, AppSnackbar.error(_flow.error!));
      }
    });
  }

  void _selectFeeling(
    Map<String, dynamic> mood,
    Map<String, dynamic> feeling,
    BuildContext choiceContext,
  ) {
    _flow.selectFeeling(mood['slug'] as String, feeling['slug'] as String);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !choiceContext.mounted) return;
      Scrollable.ensureVisible(
        choiceContext,
        duration: motionDuration(
          context,
          context.cozyColors.wellness.transition,
        ),
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  void _exit() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRouter.home);
    }
  }

  Future<void> _close() async {
    if (_flow.saving || _closing) return;
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
      await _flow.discard();
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
    if (_flow.back()) unawaited(_close());
  }

  Future<void> _save() async {
    final saved = await _flow.save();
    if (!mounted || saved == null || !_flow.active) return;
    const detector = CrisisDetector();
    final signal = detector.analyze(saved.note ?? '');
    if (detector.canTrigger('mood', signal)) {
      detector.markTriggered('mood');
      await showCrisisSupportOverlay(context, signal: signal);
    }
    if (mounted && _flow.active) {
      context.go(AppRouter.moodSuccess, extra: saved);
    }
  }

  @override
  void dispose() {
    _flow.removeListener(_onFlow);
    if (widget.controller == null) _flow.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.cozyColors.recording;
    final stage = _flow.state.step;
    final feelingStage = stage == MoodRecordingStep.feeling;
    final heading = switch (stage) {
      MoodRecordingStep.feeling => 'How are you feeling?',
      MoodRecordingStep.intensity => 'How strong is this feeling?',
      MoodRecordingStep.causes => 'What made you feel this way?',
      MoodRecordingStep.coping => 'How have you expressed these feelings?',
      MoodRecordingStep.review => 'Review your check-in',
    };
    return PopScope<Object?>(
      canPop: !_flow.active,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        // Search lives in its own inset-aware sheet. Keep the check-in behind it
        // stable while the keyboard is open.
        resizeToAvoidBottomInset: false,
        backgroundColor: feelingStage
            ? context.cozyColors.wellness.canvas(
                theme.brightness,
                MediaQuery.highContrastOf(context),
              )
            : theme.scaffoldBackgroundColor,
        body: SecurityBlur(
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: t.contentWidth),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: t.small),
                      child: Row(
                        children: [
                          AppPressable(
                            label: 'Back',
                            onPressed: _flow.saving ? null : _back,
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.chevron_left),
                                Text('Back'),
                              ],
                            ),
                          ),
                          SizedBox(width: t.medium),
                          Expanded(
                            child: LinearProgressIndicator(
                              color: context.cozyColors.recording.controlColor(
                                theme.colorScheme.primary,
                                theme.colorScheme.surface,
                                theme.colorScheme.onSurface,
                                minimumContrast: 3,
                              ),
                              value:
                                  (_step + 1) / MoodRecordingStep.values.length,
                              minHeight: t.tiny,
                              semanticsLabel:
                                  'Check-in, step ${_step + 1} of 5',
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: t.small),
                            child: Text(
                              '${_step + 1} of 5',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          AppPressable(
                            label: 'Close check-in',
                            onPressed: _flow.saving ? null : _close,
                            child: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scroll,
                        padding: EdgeInsets.fromLTRB(
                          t.page,
                          t.small,
                          feelingStage ? 15 : t.page,
                          t.section,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!_flow.active) ...[
                              const Text(
                                'Your account changed. Return home to start a new check-in.',
                              ),
                              RecordingAction(
                                label: 'Back to Home',
                                onPressed: () => context.go(AppRouter.home),
                              ),
                            ] else ...[
                              if (_flow.resumeDraft != null) ...[
                                Text(
                                  _flow.supportedDraft
                                      ? 'You have an unsaved check-in. Resume?'
                                      : 'This draft was made by a newer app version. Keep it, or discard it to start again.',
                                ),
                                Row(
                                  children: [
                                    if (_flow.supportedDraft)
                                      TextButton(
                                        onPressed: () {
                                          _flow.resume();
                                          _openSelectedGroups();
                                        },
                                        child: const Text('Resume'),
                                      ),
                                    TextButton(
                                      onPressed: () async {
                                        try {
                                          await _flow.discard();
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
                              ],
                              IgnorePointer(
                                ignoring:
                                    _flow.loading ||
                                    _flow.saving ||
                                    _flow.resumeDraft != null,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Semantics(
                                      header: true,
                                      child: Text(
                                        heading,
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                              fontSize: feelingStage
                                                  ? context
                                                        .cozyColors
                                                        .wellness
                                                        .heading
                                                  : t.headingSize,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                    if (stage == MoodRecordingStep.causes ||
                                        stage == MoodRecordingStep.coping) ...[
                                      SizedBox(height: t.small),
                                      Text(
                                        'Optional · Choose any that apply.',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                    SizedBox(
                                      height: feelingStage
                                          ? t.small
                                          : t.section,
                                    ),
                                    if (feelingStage) ...[
                                      Text(
                                        'Choose a group, then the feeling that fits.',
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      SizedBox(height: t.large),
                                      ..._feelingCards(),
                                    ],
                                    if (stage ==
                                        MoodRecordingStep.intensity) ...[
                                      _summary(),
                                      SizedBox(height: t.section),
                                      Text(
                                        'Move the slider to match how strongly you feel it.',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      SizedBox(height: t.large),
                                      MoodIntensityControl(
                                        value: moodIntensityToDisplay(
                                          _flow.state.intensity,
                                        ),
                                        feeling: _flow.feeling,
                                        onChanged: _flow.setIntensity,
                                      ),
                                    ],
                                    if (stage == MoodRecordingStep.causes) ...[
                                      _summary(),
                                      SizedBox(height: t.large),
                                      ..._causes(),
                                    ],
                                    if (stage == MoodRecordingStep.coping) ...[
                                      _summary(),
                                      SizedBox(height: t.large),
                                      RecordingPanel(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    'Coping mechanisms',
                                                    style: theme
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ),
                                                SizedBox(width: t.small),
                                                AppPressable(
                                                  key: const ValueKey(
                                                    'coping-see-all',
                                                  ),
                                                  label:
                                                      'See all responses (${_allResponses().length})',
                                                  onPressed: _showResponses,
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: t.small,
                                                        ),
                                                    child: Text(
                                                      'See all (${_allResponses().length})',
                                                      style: TextStyle(
                                                        color: t.controlColor(
                                                          theme
                                                              .colorScheme
                                                              .primary,
                                                          theme
                                                              .colorScheme
                                                              .surface,
                                                          theme
                                                              .colorScheme
                                                              .onSurface,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: t.medium),
                                            RecordingChoices(
                                              options: _previewResponses(),
                                              selected: _flow.state.coping,
                                              collection: 'coping',
                                              onToggle: (name) {
                                                final values = Set.of(
                                                  _flow.state.coping,
                                                );
                                                if (!values.add(name)) {
                                                  values.remove(name);
                                                }
                                                _flow.setCoping(values);
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (stage == MoodRecordingStep.review)
                                      ..._review(),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (_flow.active) _footer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summary() => RecordingSummary(
    mood: _flow.state.mood ?? 'good',
    feeling: _flow.feeling,
    intensity: _flow.state.intensity,
  );
  Widget _footer() {
    final t = context.cozyColors.recording;
    final stage = _flow.state.step;
    final mood = _flow.state.mood;
    final moodLabel = mood == null || mood.isEmpty
        ? ''
        : '${mood[0].toUpperCase()}${mood.substring(1)}';
    final values = stage == MoodRecordingStep.causes
        ? _flow.state.causes
        : stage == MoodRecordingStep.coping
        ? _flow.state.coping
        : const <String>{};
    final optional =
        stage == MoodRecordingStep.causes || stage == MoodRecordingStep.coping;
    final noun = stage == MoodRecordingStep.causes ? 'cause' : 'response';
    return Padding(
      padding: EdgeInsets.fromLTRB(t.page, t.small, t.page, t.small),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (stage == MoodRecordingStep.feeling) ...[
            Text(
              _flow.canContinue
                  ? 'Selected: ${_flow.feeling} · $moodLabel'
                  : 'Choose a feeling to continue.',
              key: const ValueKey('feeling-selection-summary'),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            SizedBox(height: t.small),
          ],
          if (optional && values.isNotEmpty) ...[
            Text(
              '${values.length} $noun${values.length == 1 ? '' : 's'} selected',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              values.join(' · '),
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: t.small),
          ],
          RecordingAction(
            key: const ValueKey('recording-continue'),
            label: stage == MoodRecordingStep.review
                ? 'Save entry'
                : 'Continue',
            busy: _flow.saving,
            onPressed: _flow.canContinue
                ? () {
                    if (stage == MoodRecordingStep.review) {
                      unawaited(_save());
                    } else {
                      _flow.next();
                    }
                  }
                : null,
          ),
          if (optional && values.isEmpty && _flow.canContinue)
            AppPressable(
              key: const ValueKey('recording-skip'),
              label: 'Skip for now',
              onPressed: _flow.next,
              child: Center(
                child: Text(
                  'Skip for now',
                  style: TextStyle(
                    color: t.controlColor(
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _causes() {
    final t = context.cozyColors.recording;
    final catalogRows = _rows('triggers');
    final rows = [
      ...catalogRows,
      for (final name in _flow.state.causes)
        if (!catalogRows.any((row) => row['name'] == name))
          {
            'name': name,
            'slug': 'historical-$name',
            'group_name': 'Previously selected',
          },
    ];
    final groups = {
      ..._causeGroups,
      for (final row in rows) row['group_name'] as String? ?? 'Other',
    };
    return [
      for (final (index, group) in groups.indexed)
        Padding(
          padding: EdgeInsets.only(bottom: t.small),
          child: RecordingPanel(
            tinted: _expanded.contains(group),
            category: index % 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppPressable(
                  key: ValueKey('cause-group-$group'),
                  expanded: _expanded.contains(group),
                  onPressed: () => setState(() {
                    if (!_expanded.add(group)) _expanded.remove(group);
                  }),
                  child: Row(
                    children: [
                      Icon(
                        _icons[index % 6],
                        color: context
                            .cozyColors
                            .recording
                            .categoryInks[index % 6],
                      ),
                      SizedBox(width: t.small),
                      Expanded(
                        child: Text(
                          group,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Icon(
                        _expanded.contains(group)
                            ? Icons.expand_less
                            : Icons.expand_more,
                      ),
                    ],
                  ),
                ),
                if (_expanded.contains(group)) ...[
                  SizedBox(height: t.small),
                  RecordingChoices(
                    options: rows
                        .where((row) => (row['group_name'] ?? 'Other') == group)
                        .toList(),
                    selected: _flow.state.causes,
                    collection: 'triggers',
                    category: index % 6,
                    onToggle: _flow.toggleCause,
                  ),
                ],
              ],
            ),
          ),
        ),
    ];
  }

  List<Map<String, dynamic>> _allResponses() {
    final rows = _rows('coping');
    return [
      ...rows,
      for (final name in _flow.state.coping)
        if (!rows.any((row) => row['name'] == name))
          {'name': name, 'slug': 'historical-$name'},
    ];
  }

  List<Map<String, dynamic>> _previewResponses() {
    const names = {
      'Deep breathing',
      'Meditation',
      'Journaling',
      'Talking to a friend',
      'Exercise',
      'Listening to music',
      'Resting',
      'Taking a walk',
    };
    return _allResponses()
        .where(
          (row) =>
              names.contains(row['name']) ||
              _flow.state.coping.contains(row['name']),
        )
        .toList();
  }

  Future<void> _showResponses() async {
    final selected = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      sheetAnimationStyle: shouldReduceMotion(context)
          ? AnimationStyle.noAnimation
          : null,
      builder: (context) => FractionallySizedBox(
        heightFactor: .95,
        child: CopingResponseSheet(
          options: _allResponses(),
          selected: _flow.state.coping,
        ),
      ),
    );
    if (mounted && selected != null && _flow.active) _flow.setCoping(selected);
  }

  List<Widget> _review() {
    final t = context.cozyColors.recording;
    return [
      RecordingSummary(
        mood: _flow.state.mood ?? 'good',
        feeling: _flow.feeling,
        intensity: _flow.state.intensity,
        large: true,
      ),
      SizedBox(height: t.large),
      _reviewRow(
        'Feeling',
        '${_flow.feeling} · ${_flow.state.mood ?? ''}',
        MoodRecordingStep.feeling,
      ),
      _reviewRow(
        'Intensity',
        '${_flow.intensityLabel} · ${moodIntensityToDisplay(_flow.state.intensity)}/5',
        MoodRecordingStep.intensity,
      ),
      _reviewRow(
        'Causes',
        _flow.state.causes.isEmpty
            ? 'None selected'
            : _flow.state.causes.join(' · '),
        MoodRecordingStep.causes,
      ),
      _reviewRow(
        'Coping mechanisms',
        _flow.state.coping.isEmpty
            ? 'None selected'
            : _flow.state.coping.join(' · '),
        MoodRecordingStep.coping,
      ),
    ];
  }

  Widget _reviewRow(String title, String value, MoodRecordingStep section) {
    final t = context.cozyColors.recording;
    return Padding(
      padding: EdgeInsets.only(bottom: t.small),
      child: RecordingPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                AppPressable(
                  key: ValueKey('recording-edit-${section.name}'),
                  label: 'Edit $title',
                  onPressed: () => _flow.edit(section),
                  child: Center(
                    child: Text(
                      'Edit',
                      style: TextStyle(
                        color: t.controlColor(
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.surface,
                          Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  List<Widget> _feelingCards() {
    final t = context.cozyColors.recording;
    final scheme = Theme.of(context).colorScheme;
    final category = _visibleCategory;
    final moods = _rows('moods');
    final mood = moods.where((row) => row['slug'] == category).firstOrNull;
    final choices = mood == null
        ? <Map<String, dynamic>>[]
        : _rows(
            'expressions',
          ).where((row) => row['feeling_id'] == mood['id']).toList();
    final selection = t.controlColor(
      scheme.primary,
      scheme.surface,
      scheme.onSurface,
      minimumContrast: 3,
    );
    return [
      MoodCategoryGrid(
        compact: true,
        selected: category,
        onSelected: (value) => setState(() => _visibleCategory = value),
      ),
      SizedBox(height: t.section),
      if (mood == null)
        const Text('Choose a category to see its feelings.')
      else ...[
        Semantics(
          liveRegion: true,
          header: true,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  mood['name'] as String,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${choices.length} feelings',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        SizedBox(height: t.medium),
        AnimatedSwitcher(
          duration: motionDuration(
            context,
            context.cozyColors.wellness.transition,
          ),
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.topCenter,
            children: [
              for (final child in previous)
                IgnorePointer(child: ExcludeSemantics(child: child)),
              if (current != null) current,
            ],
          ),
          child: KeyedSubtree(
            key: ValueKey(category),
            child: LayoutBuilder(
              builder: (context, box) {
                final columns =
                    box.maxWidth >= t.twoColumnWidth &&
                        MediaQuery.textScalerOf(context).scale(t.bodySize) <
                            t.singleColumnTextSize
                    ? 2
                    : 1;
                return Wrap(
                  spacing: t.small,
                  runSpacing: t.small,
                  children: [
                    for (final feeling in choices)
                      SizedBox(
                        width:
                            (box.maxWidth - t.small * (columns - 1)) / columns,
                        child: Builder(
                          builder: (choiceContext) => AppPressable(
                            key: ValueKey(
                              'recording-hit-expressions-${feeling['slug']}',
                            ),
                            selected: _flow.state.expression == feeling['slug'],
                            label: feeling['name'] as String,
                            onPressed: () =>
                                _selectFeeling(mood, feeling, choiceContext),
                            child: Container(
                              key: ValueKey(
                                'recording-expressions-${feeling['slug']}',
                              ),
                              padding: EdgeInsets.all(t.medium),
                              decoration: BoxDecoration(
                                color: scheme.surface,
                                borderRadius: BorderRadius.circular(
                                  t.controlRadius,
                                ),
                                border: Border.all(
                                  color:
                                      _flow.state.expression == feeling['slug']
                                      ? selection
                                      : scheme.outline,
                                  width: t.selectedBorder,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      feeling['name'] as String,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: scheme.onSurface,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),
                                  ...[
                                    SizedBox(width: t.small),
                                    Opacity(
                                      opacity:
                                          _flow.state.expression ==
                                              feeling['slug']
                                          ? 1
                                          : 0,
                                      child: Icon(
                                        Icons.check_circle,
                                        size: t.iconSize,
                                        color: selection,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    ];
  }
}

class MoodCheckInSuccessScreen extends StatelessWidget {
  const MoodCheckInSuccessScreen({super.key, this.entry});
  final MoodEntry? entry;
  @override
  Widget build(BuildContext context) {
    final t = context.cozyColors.recording;
    final saved = entry;
    return Scaffold(
      body: SecurityBlur(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: t.contentWidth),
              child: AppScrollBody(
                child: Padding(
                  padding: EdgeInsets.all(t.page),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(t.section),
                        decoration: BoxDecoration(
                          color: context.cozyColors.recordingCategoryFills[0],
                          borderRadius: BorderRadius.circular(t.panelRadius),
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: t.touch,
                          color: context.cozyColors.triggerLow,
                        ),
                      ),
                      SizedBox(height: t.section),
                      Text(
                        'Entry saved.',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: t.medium),
                      Text(
                        'Thanks for checking in with yourself.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      SizedBox(height: t.section),
                      if (saved != null) ...[
                        RecordingPanel(
                          tinted: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              RecordingSummary(
                                mood: saved.mood,
                                feeling: saved.displayFeeling,
                                intensity: saved.intensity,
                              ),
                              SizedBox(height: t.medium),
                              Text(
                                (saved.triggers ?? []).isEmpty
                                    ? 'No causes selected'
                                    : saved.triggers!.join(' · '),
                              ),
                              SizedBox(height: t.medium),
                              Text(
                                (saved.copingStrategies ?? []).isEmpty
                                    ? 'No responses selected'
                                    : saved.copingStrategies!.join(' · '),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: t.section),
                      ],
                      RecordingAction(
                        label: 'Back to Home',
                        onPressed: () => context.go(AppRouter.home),
                      ),
                      SizedBox(height: t.medium),
                      RecordingAction(
                        label: 'Log another',
                        outlined: true,
                        onPressed: () => context.go(AppRouter.moodFeeling),
                      ),
                      SizedBox(height: t.small),
                      AppPressable(
                        label: 'See past entries',
                        onPressed: () => context.push(AppRouter.moodHistory),
                        child: Center(
                          child: Text(
                            'See past entries',
                            style: TextStyle(
                              color: t.controlColor(
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.surface,
                                Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
              if (MoodArtwork.assetFor(entry.mood) != null) ...[
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    border: AppSurface.border(context),
                    color: AppSurface.tint(context, AppColors.primarySoft),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(child: MoodArtwork(mood: entry.mood, size: 28)),
                ),
                const SizedBox(width: 14),
              ],
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
                MoodArtwork(mood: moodEntry.mood, size: 64),
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
