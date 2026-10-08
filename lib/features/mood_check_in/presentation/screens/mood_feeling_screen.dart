import '../../../../core/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/repositories/mood_repository.dart';
import '../../../../core/models/mood_entry.dart';
import '../../../crisis/presentation/screens/crisis_screens.dart';
import '../../../crisis/services/crisis_detector.dart';

class MoodFeelingScreen extends StatefulWidget {
  const MoodFeelingScreen({super.key, this.entry});

  final MoodEntry? entry;

  @override
  State<MoodFeelingScreen> createState() => _MoodFeelingScreenState();
}

class _MoodFeelingScreenState extends State<MoodFeelingScreen>
    with SingleTickerProviderStateMixin {
  static const int _totalSteps = 9;

  final CrisisDetector _crisisDetector = const CrisisDetector();
  late final AnimationController _entranceController;
  final TextEditingController _triggerController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  int _step = 1;
  String? _moodLabel;
  String? _moodEmoji;
  int _intensity = 5;
  final Set<String> _bodyZones = {};
  final Set<String> _triggers = {};
  int? _sleepQuality;
  int _energy = 5;
  final Set<String> _coping = {};
  bool _isSaving = false;
  bool _discardDialogOpen = false;

  late final List<_MoodOption> _moods = [
    _MoodOption(
      MoodEntry.moodEmojis['good']!,
      'good',
      'Good',
      AppColors.success,
      "That's lovely to hear.",
    ),
    _MoodOption(
      MoodEntry.moodEmojis['calm']!,
      'calm',
      'Calm',
      Theme.of(context).colorScheme.primary,
      'Peace looks good on you.',
    ),
    _MoodOption(
      MoodEntry.moodEmojis['okay']!,
      'okay',
      'Okay',
      Theme.of(context).colorScheme.onSurfaceVariant,
      'Thanks for being honest.',
    ),
    _MoodOption(
      MoodEntry.moodEmojis['low']!,
      'low',
      'Low',
      AppColors.warning,
      "I'm here with you.",
    ),
    _MoodOption(
      MoodEntry.moodEmojis['anxious']!,
      'anxious',
      'Anxious',
      AppColors.warmOrange,
      "That sounds heavy. Let's slow down.",
    ),
    _MoodOption(
      MoodEntry.moodEmojis['angry']!,
      'angry',
      'Angry',
      AppColors.danger,
      "That's valid. Let's work through it.",
    ),
  ];

  final List<String> _triggerOptions = const [
    'Work',
    'Family',
    'Friends',
    'Health',
    'School',
    'Money',
    'Sleep',
    'Relationships',
    'Body',
    'Weather',
    'News',
    'Self',
  ];

  final List<String> _bodyOptions = const [
    'Head',
    'Chest',
    'Stomach',
    'Shoulders',
    'Arms',
    'Legs',
  ];

  final List<_CopingOption> _copingOptions = const [
    _CopingOption('🌬', 'Box breathing', '2 minutes', AppRouter.breathing),
    _CopingOption(
      '🧘',
      '5-4-3-2-1 grounding',
      '3 minutes',
      AppRouter.grounding,
    ),
    _CopingOption('📝', 'Quick journal', '5 minutes', AppRouter.journal),
  ];

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    final entry = widget.entry;
    if (entry != null) {
      _moodLabel = MoodEntry.normalizeMoodKey(entry.mood);
      _moodEmoji = entry.emoji;
      _intensity = entry.intensity;
      _bodyZones.addAll(entry.bodySensations ?? const []);
      _triggers.addAll(entry.triggers ?? const []);
      _triggerController.text = entry.customTrigger ?? '';
      _sleepQuality = entry.sleepQuality;
      _energy = entry.energyLevel ?? 5;
      _noteController.text = entry.note ?? '';
      _coping.addAll(entry.copingStrategies ?? const []);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _restartEntrance());
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _triggerController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _restartEntrance() {
    if (!mounted) return;
    if (MediaQuery.of(context).disableAnimations) {
      _entranceController.value = 1;
      return;
    }
    _entranceController.forward(from: 0);
  }

  void _goToStep(int step) {
    setState(() => _step = step.clamp(1, _totalSteps));
    _restartEntrance();
  }

  void _next() {
    if (_step == _totalSteps) {
      _saveEntry();
      return;
    }
    _goToStep(_step + 1);
  }

  void _handleSystemBack() {
    if (_isSaving || _discardDialogOpen) return;
    if (_step > 1) {
      _goToStep(_step - 1);
      return;
    }
    if (_hasDraftContent()) {
      _showDiscardDialog();
    } else {
      _exitFlow();
    }
  }

  bool _hasDraftContent() =>
      _moodLabel != null ||
      _intensity != 5 ||
      _bodyZones.isNotEmpty ||
      _triggers.isNotEmpty ||
      _triggerController.text.trim().isNotEmpty ||
      _sleepQuality != null ||
      _energy != 5 ||
      _noteController.text.trim().isNotEmpty ||
      _coping.isNotEmpty;

  Future<void> _showDiscardDialog() async {
    if (_isSaving || _discardDialogOpen) return;
    _discardDialogOpen = true;
    final colorScheme = Theme.of(context).colorScheme;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          'Discard this entry?',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        content: Text(
          'Your progress will be lost.',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep editing'),
          ),
        ],
      ),
    );
    _discardDialogOpen = false;
    if (!mounted) return;
    if (discard == true) _discardAndExit();
  }

  void _exitFlow() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRouter.home);
    }
  }

  void _discardAndExit() {
    _step = 1;
    _moodLabel = null;
    _moodEmoji = null;
    _intensity = 5;
    _bodyZones.clear();
    _triggers.clear();
    _triggerController.clear();
    _sleepQuality = null;
    _energy = 5;
    _noteController.clear();
    _coping.clear();
    _exitFlow();
  }

  void _skip() {
    if (_step == 3) _bodyZones.clear();
    if (_step == 4) {
      _triggers.clear();
      _triggerController.clear();
    }
    if (_step == 5) _sleepQuality = null;
    if (_step == 6) _energy = 5;
    if (_step == 7) _noteController.clear();
    if (_step == 8) _coping.clear();
    _next();
  }

  Future<void> _saveEntry() async {
    setState(() => _isSaving = true);
    final note = _noteController.text.trim();
    final signal = _crisisDetector.analyze(note);
    final shouldShowCrisisSupport = _crisisDetector.canTrigger('mood', signal);

    final entry = MoodEntry(
      id: widget.entry?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      mood: _moodLabel ?? 'okay',
      intensity: _intensity,
      bodySensations: _bodyZones.toList(),
      triggers: _triggers.toList(),
      customTrigger: _triggerController.text.trim().isNotEmpty
          ? _triggerController.text.trim()
          : null,
      sleepQuality: _sleepQuality,
      energyLevel: _energy,
      note: note.isNotEmpty ? note : null,
      copingStrategies: _coping.toList(),
      isCrisisFlagged: shouldShowCrisisSupport,
      createdAt: widget.entry?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await MoodRepository().save(entry);
    } catch (e) {
      // Ignored for now - LocalDbService handles offline queueing
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (shouldShowCrisisSupport) {
      _crisisDetector.markTriggered('mood');
      await showCrisisSupportOverlay(context, signal: signal);
      if (!mounted) return;
    }

    context.go(AppRouter.moodSuccess);
  }

  bool get _canContinue => _step != 1 || _moodLabel != null;

  String? get _selectedMoodLabel {
    final key = _moodLabel;
    if (key == null) return null;
    return _moodDisplayLabel(key);
  }

  @override
  Widget build(BuildContext context) {
    final child = switch (_step) {
      1 => _moodSelection(),
      2 => _intensityStep(),
      3 => _bodyStep(),
      4 => _triggerStep(),
      5 => _sleepStep(),
      6 => _energyStep(),
      7 => _journalStep(),
      8 => _copingStep(),
      _ => _reviewStep(),
    };

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleSystemBack();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _MoodProgressHeader(
                step: _step,
                totalSteps: _totalSteps,
                onBack: _step == 1
                    ? () => context.pop()
                    : () => _goToStep(_step - 1),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
                  child: _AnimatedStep(
                    controller: _entranceController,
                    child: child,
                  ),
                ),
              ),
              _BottomActions(
                moodSelection: _step == 1,
                showSkip: _step >= 3 && _step <= 8,
                label: _step == _totalSteps ? 'Save Entry' : 'Continue',
                enabled: _canContinue && !_isSaving,
                busy: _isSaving,
                onContinue: _next,
                onSkip: _skip,
              ),
              if (_step == _totalSteps)
                TextButton(
                  onPressed: _isSaving ? null : _showDiscardDialog,
                  child: Text(
                    'Cancel this entry',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _moodSelection() {
    final selected = _moods.where((mood) => mood.key == _moodLabel).firstOrNull;

    return Column(
      children: [
        const _StepIntro(
          title: 'How are you\nfeeling right now?',
          subtitle: "Take your time.\nThere's no wrong answer.",
        ),
        const SizedBox(height: 32),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _moods.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final mood = _moods[index];
            final isSelected = mood.key == _moodLabel;
            return _MoodCard(
              mood: mood,
              selected: isSelected,
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _moodLabel = mood.key;
                  _moodEmoji = mood.emoji;
                });
                SemanticsService.sendAnnouncement(
                  View.of(context),
                  'Mood selected: ${mood.label}. Continue button enabled.',
                  Directionality.of(context),
                );
              },
            );
          },
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: selected == null
              ? const SizedBox(height: 122)
              : Padding(
                  padding: const EdgeInsets.only(top: 26),
                  child: _MascotMessage(message: selected.message),
                ),
        ),
      ],
    );
  }

  Widget _intensityStep() {
    return Column(
      children: [
        const _StepIntro(
          title: 'How strong is\nthis feeling?',
          subtitle: "There's no right\nanswer. Just notice.",
        ),
        const SizedBox(height: 44),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: Tween<double>(begin: .96, end: 1).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: Text(
            '$_intensity',
            key: ValueKey(_intensity),
            style: AppTextStyles.heading1.copyWith(
              fontSize: 72,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 34),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Mild', style: _captionStyle()),
            Text('Strong', style: _captionStyle()),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 8,
            activeTrackColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor: Theme.of(context).colorScheme.outline,
            thumbColor: Theme.of(context).colorScheme.onPrimary,
            overlayColor: AppColors.primarySoft,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
          ),
          child: Slider(
            min: 1,
            max: 10,
            divisions: 9,
            value: _intensity.toDouble(),
            semanticFormatterCallback: (value) =>
                'Intensity ${value.round()} of 10',
            onChanged: (value) {
              final next = value.round();
              if (next != _intensity) HapticFeedback.selectionClick();
              setState(() => _intensity = next);
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(10, (index) {
            return Text('${index + 1}', style: _captionStyle());
          }),
        ),
        const SizedBox(height: 34),
        _MascotMessage(message: _intensityMessage),
      ],
    );
  }

  Widget _bodyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepIntro(
          title: 'Where do you\nfeel it?',
          subtitle: 'Sometimes feelings\nshow up in our bodies.',
        ),
        const SizedBox(height: 26),
        _BodyMap(selectedZones: _bodyZones, onToggle: _toggleBodyZone),
        const SizedBox(height: 22),
        Text(
          'Or choose:',
          style: AppTextStyles.body1.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        _ChipWrap(
          values: _bodyOptions,
          selectedValues: _bodyZones,
          onToggle: _toggleBodyZone,
        ),
      ],
    );
  }

  Widget _triggerStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepIntro(
          title: "What's been\non your mind?",
          subtitle: 'Choose anything\nthat fits. Or skip.',
        ),
        const SizedBox(height: 28),
        _ChipWrap(
          values: _triggerOptions,
          selectedValues: _triggers,
          onToggle: (value) {
            setState(() {
              _triggers.contains(value)
                  ? _triggers.remove(value)
                  : _triggers.add(value);
            });
          },
        ),
        const SizedBox(height: 28),
        Text(
          'Or describe it yourself:',
          style: AppTextStyles.body1.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _triggerController,
          minLines: 3,
          maxLines: 4,
          decoration: _inputDecoration(''),
        ),
      ],
    );
  }

  Widget _sleepStep() {
    return Column(
      children: [
        const _StepIntro(title: 'How did you\nsleep?', subtitle: ''),
        const SizedBox(height: 42),
        const Text('🌙', style: TextStyle(fontSize: 54)),
        const SizedBox(height: 38),
        _WarmPanel(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) {
                  final value = index + 1;
                  final filled = (_sleepQuality ?? 0) >= value;
                  return Semantics(
                    button: true,
                    label: 'Sleep quality $value of 5',
                    child: IconButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() => _sleepQuality = value);
                      },
                      iconSize: 42,
                      icon: Icon(
                        filled ? Icons.star_rounded : Icons.star_border_rounded,
                        color: filled
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Poor', style: _captionStyle()),
                  Text('Great', style: _captionStyle()),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _energyStep() {
    return Column(
      children: [
        const _StepIntro(title: "How's your\nenergy?", subtitle: ''),
        const SizedBox(height: 44),
        const Text('🔋', style: TextStyle(fontSize: 54)),
        const SizedBox(height: 38),
        _WarmPanel(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Low', style: _captionStyle()),
                  Text('High', style: _captionStyle()),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 8,
                  activeTrackColor: AppColors.success,
                  inactiveTrackColor: Theme.of(context).colorScheme.outline,
                  thumbColor: Theme.of(context).colorScheme.onPrimary,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 14,
                  ),
                ),
                child: Slider(
                  min: 1,
                  max: 10,
                  divisions: 9,
                  value: _energy.toDouble(),
                  semanticFormatterCallback: (value) =>
                      'Energy ${value.round()} of 10',
                  onChanged: (value) => setState(() => _energy = value.round()),
                ),
              ),
              Text(
                '$_energy / 10',
                style: AppTextStyles.heading2.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _journalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepIntro(
          title: 'Want to say\nmore?',
          subtitle: 'Anything you write\nstays private.',
        ),
        const SizedBox(height: 28),
        TextField(
          controller: _noteController,
          minLines: 8,
          maxLines: 10,
          maxLength: 1000,
          textAlignVertical: TextAlignVertical.top,
          decoration: _inputDecoration("What's on your mind?"),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => context.push(AppRouter.voiceRecording),
          icon: Icon(Icons.mic_none_rounded),
          label: const Text('Voice note'),
        ),
      ],
    );
  }

  Widget _copingStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepIntro(
          title: 'Want to try\nsomething?',
          subtitle: 'Small things that\nmight help.',
        ),
        const SizedBox(height: 28),
        for (final option in _copingOptions) ...[
          _CopingCard(
            option: option,
            selected: _coping.contains(option.title),
            onSelect: () {
              setState(() {
                _coping.contains(option.title)
                    ? _coping.remove(option.title)
                    : _coping.add(option.title);
              });
            },
            onTry: () => context.push(option.route),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _reviewStep() {
    final rows = <_ReviewRowData>[
      _ReviewRowData(
        '${_moodEmoji ?? MoodEntry.moodEmojis['good']}  ${_selectedMoodLabel ?? 'Mood'}',
        'Intensity: $_intensity',
        1,
      ),
      if (_bodyZones.isNotEmpty)
        _ReviewRowData('Body', _bodyZones.join(', '), 3),
      if (_triggers.isNotEmpty || _triggerController.text.trim().isNotEmpty)
        _ReviewRowData(
          'Triggers',
          [
            ..._triggers,
            if (_triggerController.text.trim().isNotEmpty)
              _triggerController.text.trim(),
          ].join(', '),
          4,
        ),
      if (_sleepQuality != null)
        _ReviewRowData(
          'Sleep',
          '${'★' * _sleepQuality!}${'☆' * (5 - _sleepQuality!)}',
          5,
        ),
      _ReviewRowData('Energy', '$_energy/10', 6),
      if (_noteController.text.trim().isNotEmpty)
        _ReviewRowData('Note', '"${_noteController.text.trim()}"', 7),
      if (_coping.isNotEmpty) _ReviewRowData('Coping', _coping.join(', '), 8),
    ];

    return Column(
      children: [
        const _StepIntro(
          title: "Here's what\nyou logged.",
          subtitle: 'Tap any section\nto edit.',
        ),
        const SizedBox(height: 28),
        for (final row in rows) ...[
          _ReviewRow(data: row, onEdit: () => _goToStep(row.step)),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  String get _intensityMessage {
    if (_intensity <= 3) return 'A gentle feeling.';
    if (_intensity <= 6) return "That's noticeable.";
    if (_intensity <= 8) return "That's quite a lot.";
    return "That sounds really intense. I'm here.";
  }

  void _toggleBodyZone(String zone) {
    setState(() {
      _bodyZones.contains(zone)
          ? _bodyZones.remove(zone)
          : _bodyZones.add(zone);
    });
  }

  TextStyle _captionStyle() => AppTextStyles.body2.copyWith(
    color: Theme.of(context).colorScheme.onSurfaceVariant,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body1.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      counterStyle: AppTextStyles.body2.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      contentPadding: const EdgeInsets.all(16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.5,
        ),
      ),
    );
  }
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Entry saved.')));
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
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
    );
  }
}

class MoodHistoryScreen extends StatelessWidget {
  const MoodHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<MoodEntry>>(
          stream: MoodRepository().watchMoodEntries(),
          builder: (context, snapshot) {
            final entries = snapshot.data ?? const <MoodEntry>[];

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
                  const Center(child: CircularProgressIndicator())
                else if (entries.isEmpty)
                  EmptyState(
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
      label:
          '${_moodDisplayLabel(entry.mood)}, intensity ${entry.intensity} of 10',
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
                  color: AppColors.primarySoft,
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
                      _moodDisplayLabel(entry.mood),
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
  Widget build(BuildContext context) {
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
                  _moodDisplayLabel(moodEntry.mood),
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

String _moodDisplayLabel(String mood) {
  switch (MoodEntry.normalizeMoodKey(mood)) {
    case 'good':
      return 'Good';
    case 'calm':
      return 'Calm';
    case 'okay':
      return 'Okay';
    case 'low':
      return 'Low';
    case 'anxious':
      return 'Anxious';
    case 'angry':
      return 'Angry';
    default:
      return mood.trim().isEmpty ? 'Okay' : mood.trim();
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

class _MoodProgressHeader extends StatelessWidget {
  const _MoodProgressHeader({
    required this.step,
    required this.totalSteps,
    required this.onBack,
  });

  final int step;
  final int totalSteps;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 24, 0),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  tooltip: 'Back',
                  onPressed: onBack,
                  icon: Icon(
                    Icons.arrow_back,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Step $step of $totalSteps',
                style: AppTextStyles.body2.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                minHeight: 4,
                value: step / totalSteps,
                backgroundColor:
                    Theme.of(context).dividerTheme.color ??
                    Theme.of(context).colorScheme.outline,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIntro extends StatelessWidget {
  const _StepIntro({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading1.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.w600,
              height: 1.12,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.body1.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MoodCard extends StatelessWidget {
  const _MoodCard({
    required this.mood,
    required this.selected,
    required this.onTap,
  });

  final _MoodOption mood;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: mood.label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: selected ? 1.02 : 1,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primarySubtle
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: mood.color.withValues(alpha: .14),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(mood.emoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(height: 14),
                Text(
                  mood.label,
                  style: AppTextStyles.body1.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MascotMessage extends StatelessWidget {
  const _MascotMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.favorite_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 30,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '"$message"',
          textAlign: TextAlign.center,
          style: AppTextStyles.body2.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _BodyMap extends StatelessWidget {
  const _BodyMap({required this.selectedZones, required this.onToggle});

  final Set<String> selectedZones;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return _WarmPanel(
      child: Center(
        child: SizedBox(
          width: 220,
          height: 320,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 106,
                height: 260,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                    width: 2,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(58),
                    bottom: Radius.circular(44),
                  ),
                ),
              ),
              _BodyZone(
                label: 'Head',
                top: 14,
                selected: selectedZones.contains('Head'),
                onTap: onToggle,
              ),
              _BodyZone(
                label: 'Shoulders',
                top: 78,
                selected: selectedZones.contains('Shoulders'),
                onTap: onToggle,
              ),
              _BodyZone(
                label: 'Chest',
                top: 122,
                selected: selectedZones.contains('Chest'),
                onTap: onToggle,
              ),
              _BodyZone(
                label: 'Stomach',
                top: 168,
                selected: selectedZones.contains('Stomach'),
                onTap: onToggle,
              ),
              _BodyZone(
                label: 'Arms',
                top: 212,
                selected: selectedZones.contains('Arms'),
                onTap: onToggle,
              ),
              _BodyZone(
                label: 'Legs',
                top: 258,
                selected: selectedZones.contains('Legs'),
                onTap: onToggle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BodyZone extends StatelessWidget {
  const _BodyZone({
    required this.label,
    required this.top,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final double top;
  final bool selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      child: InkWell(
        onTap: () => onTap(label),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 112,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primarySubtle
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.body2.copyWith(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipWrap extends StatelessWidget {
  const _ChipWrap({
    required this.values,
    required this.selectedValues,
    required this.onToggle,
  });

  final List<String> values;
  final Set<String> selectedValues;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dividerColor = Theme.of(context).dividerTheme.color;

    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: values.map((value) {
        final selected = selectedValues.contains(value);
        return Semantics(
          button: true,
          selected: selected,
          label: value,
          child: FilterChip(
            label: Text(value),
            selected: selected,
            onSelected: (_) => onToggle(value),
            avatar: selected ? Icon(Icons.check_rounded, size: 16) : null,
            backgroundColor: colorScheme.surface,
            selectedColor: AppColors.primarySubtle,
            checkmarkColor: Theme.of(context).colorScheme.primary,
            side: BorderSide(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : dividerColor ?? Theme.of(context).colorScheme.outline,
            ),
            labelStyle: AppTextStyles.body2.copyWith(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : colorScheme.onSurface,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CopingCard extends StatelessWidget {
  const _CopingCard({
    required this.option,
    required this.selected,
    required this.onSelect,
    required this.onTry,
  });

  final _CopingOption option;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onTry;

  @override
  Widget build(BuildContext context) {
    return _WarmPanel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Text(option.emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: onSelect,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: AppTextStyles.body1.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.duration,
                    style: AppTextStyles.body2.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          TextButton(onPressed: onTry, child: const Text('Try')),
          Checkbox(value: selected, onChanged: (_) => onSelect()),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.data, required this.onEdit});

  final _ReviewRowData data;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return _WarmPanel(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: AppTextStyles.body1.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (data.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    data.subtitle,
                    style: AppTextStyles.body2.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit ${data.title}',
            onPressed: onEdit,
            icon: Icon(
              Icons.edit_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.moodSelection,
    required this.showSkip,
    required this.label,
    required this.enabled,
    required this.busy,
    required this.onContinue,
    required this.onSkip,
  });

  final bool moodSelection;
  final bool showSkip;
  final String label;
  final bool enabled;
  final bool busy;
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PrimaryButton(
            label: busy ? 'Saving...' : label,
            onPressed: enabled ? onContinue : null,
            disabledBackgroundColor: moodSelection
                ? Theme.of(context).colorScheme.surfaceContainerHighest
                : null,
            disabledForegroundColor: moodSelection
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : null,
          ),
          if (showSkip) ...[
            const SizedBox(height: 10),
            TextButton(onPressed: onSkip, child: const Text('Skip')),
          ],
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.disabledBackgroundColor,
    this.disabledForegroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? disabledBackgroundColor;
  final Color? disabledForegroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          disabledBackgroundColor:
              disabledBackgroundColor ?? Theme.of(context).colorScheme.outline,
          disabledForegroundColor: disabledForegroundColor,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label),
      ),
    );
  }
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
    final colorScheme = Theme.of(context).colorScheme;
    final dividerColor = Theme.of(context).dividerTheme.color;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dividerColor ?? Theme.of(context).colorScheme.outline,
        ),
      ),
      child: child,
    );
  }
}

class _AnimatedStep extends StatelessWidget {
  const _AnimatedStep({required this.controller, required this.child});

  final AnimationController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;
    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .05),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
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

class _MoodOption {
  const _MoodOption(this.emoji, this.key, this.label, this.color, this.message);

  final String emoji;
  final String key;
  final String label;
  final Color color;
  final String message;
}

class _CopingOption {
  const _CopingOption(this.emoji, this.title, this.duration, this.route);

  final String emoji;
  final String title;
  final String duration;
  final String route;
}

class _ReviewRowData {
  const _ReviewRowData(this.title, this.subtitle, this.step);

  final String title;
  final String subtitle;
  final int step;
}
