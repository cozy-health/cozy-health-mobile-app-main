import 'dart:async';
import '../../../core/services/plan_access_service.dart';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/data/mood_recording_catalog.dart';
import '../../../core/models/mood_entry.dart';
import '../../../core/repositories/mood_repository.dart';
import '../../../core/repositories/wellness_repository.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/services/mood_draft_service.dart';
import '../../crisis/services/crisis_detector.dart';

enum MoodRecordingStep { feeling, intensity, causes, coping, review }

@immutable
class MoodRecordingState {
  const MoodRecordingState({
    required this.step,
    required this.mood,
    required this.expression,
    required this.intensity,
    required this.causes,
    required this.coping,
  });
  final MoodRecordingStep step;
  final String? mood, expression;
  final int intensity;
  final Set<String> causes, coping;
}

/// One controller per check-in. Review editors operate on a temporary snapshot.
class MoodRecordingController extends ChangeNotifier {
  MoodRecordingController({
    this.entry,
    String? initialMood,
    MoodRepository? repository,
    MoodDraftService? drafts,
    WellnessRepository? wellness,
    String Function()? accountScope,
    Stream<void>? accountChanges,
    DateTime Function()? now,
  }) : _repository = repository ?? MoodRepository(),
       _drafts = drafts ?? MoodDraftService(),
       _wellness = wellness ?? WellnessRepository(),
       _accountScope = accountScope ?? _currentScope,
       _now = now ?? DateTime.now {
    _owner = _accountScope();
    _id = entry?.id ?? const Uuid().v4();
    _mood = entry?.mood ?? initialMood;
    _expression = entry?.expressionSlug;
    _intensity = entry?.intensity ?? 6;
    _createdAt = entry?.createdAt ?? _now();
    _causes.addAll(entry?.triggers ?? const []);
    _coping.addAll(entry?.copingStrategies ?? const []);
    if (entry != null) {
      _legacy = {
        'body': entry!.bodySensations,
        'custom_trigger': entry!.customTrigger,
        'sleep': entry!.sleepQuality,
        'energy': entry!.energyLevel,
        'note': entry!.note,
        'coping_helped': entry!.copingHelped,
      };
    }
    _accounts = (accountChanges ?? LocalDbService().accountChanges).listen((_) {
      if (_owner != _accountScope()) {
        accountInvalidated = true;
        _emit();
      }
    });
  }

  static String _currentScope() =>
      LocalDbService().boxName(LocalDbService.userSettingsBoxName);
  final MoodEntry? entry;
  final MoodRepository _repository;
  final MoodDraftService _drafts;
  final WellnessRepository _wellness;
  final String Function() _accountScope;
  final DateTime Function() _now;
  late final String _owner;
  late String _id;
  late DateTime _createdAt;
  StreamSubscription<void>? _accounts;
  bool _disposed = false;
  bool loading = true, saving = false, accountInvalidated = false;
  String? error;
  Map<String, dynamic>? resumeDraft;
  Map<String, dynamic> _catalog = moodRecordingCatalog;
  Map<String, dynamic> _legacy = {};
  Future<void> _writes = Future.value();
  MoodRecordingStep _step = MoodRecordingStep.feeling;
  String? _mood, _expression;
  int _intensity = 6;
  final Set<String> _causes = {}, _coping = {};
  MoodRecordingState? _reviewSnapshot;
  bool _completed = false;

  bool get active =>
      !_disposed && !accountInvalidated && _owner == _accountScope();
  bool get editingReview => _reviewSnapshot != null;
  bool get supportedDraft =>
      resumeDraft == null ||
      (resumeDraft!['version'] is! int ||
          (resumeDraft!['version'] as int) <= 3);
  MoodRecordingState get state => MoodRecordingState(
    step: _step,
    mood: _mood,
    expression: _expression,
    intensity: _intensity,
    causes: Set.unmodifiable(_causes),
    coping: Set.unmodifiable(_coping),
  );
  Map<String, dynamic> get catalog => Map.unmodifiable(_catalog);
  bool get canContinue =>
      active &&
      !loading &&
      !saving &&
      !_completed &&
      resumeDraft == null &&
      _mood != null &&
      (_expression != null || entry != null);
  String get feeling {
    if (_expression == null) return _mood ?? 'Feeling';
    for (final row in rows('expressions')) {
      if (row['slug'] == _expression) return row['name'] as String;
    }
    return moodExpressionLabel(_expression!);
  }

  static const intensityLabels = [
    'Slight',
    'Mild',
    'Moderate',
    'Strong',
    'Very strong',
  ];
  String get intensityLabel =>
      intensityLabels[moodIntensityToDisplay(_intensity) - 1];
  List<Map<String, dynamic>> rows(String key) {
    final source = _catalog[key];
    if (source is! List) return const [];
    return [
      for (final row in source)
        if (row is Map && row['slug'] is String && row['name'] is String)
          Map<String, dynamic>.from(row),
    ];
  }

  Future<void> initialize() async {
    if (entry == null) {
      try {
        resumeDraft = await _drafts.loadToday();
      } catch (_) {
        error = "We couldn't load your draft. You can start a new check-in.";
      }
    }
    if (!active) return;
    loading = false;
    _emit();
    try {
      final remote = await _wellness.catalog();
      if (!active || remote == null || remote['mood_recording_version'] != 2) {
        return;
      }
      if (['moods', 'expressions', 'triggers', 'coping'].every(
        (key) =>
            remote[key] is List &&
            (remote[key] as List).every(
              (row) =>
                  row is Map && row['slug'] is String && row['name'] is String,
            ),
      )) {
        _catalog = remote;
        _emit();
      }
    } catch (_) {
      /* The bundled catalog remains available offline. */
    }
  }

  Map<String, dynamic> _draft() => {
    ..._legacy,
    'version': 3,
    'id': _id,
    'step': _step.index,
    'mood': _mood,
    'expression_slug': _expression,
    'intensity': _intensity,
    'triggers': _causes.toList(),
    'coping': _coping.toList(),
    'created_at': _createdAt.toIso8601String(),
  };

  void _queueDraft() {
    if (!active ||
        entry != null ||
        loading ||
        resumeDraft != null ||
        editingReview ||
        _completed ||
        saving) {
      return;
    }
    final draft = _draft();
    _writes = _writes
        .then((_) async {
          if (active) await _drafts.save(draft);
        })
        .catchError((Object _) {
          if (active) {
            error =
                "We couldn't save this draft. Please keep this screen open and try again.";
            _emit();
          }
        });
  }

  void resume() {
    if (!active || resumeDraft == null || !supportedDraft) return;
    final draft = migrateMoodRecordingDraft(resumeDraft!);
    _legacy = Map.of(draft);
    final id = draft['id'];
    if (id is String && Uuid.isValidUUID(fromString: id)) _id = id;
    _mood = _nonEmptyString(draft['mood']);
    _expression = _nonEmptyString(draft['expression_slug']);
    final intensity = draft['intensity'];
    _intensity = intensity is int && intensity >= 1 && intensity <= 10
        ? intensity
        : 6;
    _causes
      ..clear()
      ..addAll(_strings(draft['triggers']));
    _coping
      ..clear()
      ..addAll(_strings(draft['coping']));
    _createdAt = DateTime.tryParse('${draft['created_at']}') ?? _createdAt;
    _step = MoodRecordingStep.values[draft['step'] as int];
    if (_mood == null || _expression == null) _step = MoodRecordingStep.feeling;
    resumeDraft = null;
    _changed();
  }

  static Iterable<String> _strings(Object? value) =>
      value is List ? value.whereType<String>() : const [];

  Future<void> discard() async {
    await _writes;
    if (!active) return;
    if (entry == null) await _drafts.clear();
    if (!active) return;
    resumeDraft = null;
    _emit();
  }

  void selectFeeling(String mood, String expression) {
    if (!active || saving) return;
    if (_expression != expression) _intensity = 6;
    _mood = mood;
    _expression = expression;
    _changed();
  }

  void setIntensity(int level) {
    if (!active || saving || level < 1 || level > 5) return;
    // Visiting or re-announcing 4/5 must not round a historical stored 7 to 8.
    if (level == moodIntensityToDisplay(_intensity)) return;
    _intensity = moodIntensityToStorage(level);
    _changed();
  }

  void toggleCause(String name) {
    if (!active || saving) return;
    if (!_causes.add(name)) _causes.remove(name);
    _changed();
  }

  void setCoping(Set<String> selected) {
    if (!active || saving) return;
    _coping
      ..clear()
      ..addAll(selected);
    _changed();
  }

  void edit(MoodRecordingStep section) {
    if (!active ||
        saving ||
        _step != MoodRecordingStep.review ||
        section == _step) {
      return;
    }
    _reviewSnapshot = state;
    _step = section;
    _emit();
  }

  void next() {
    if (!canContinue || _step == MoodRecordingStep.review) return;
    if (editingReview) {
      if (_step == MoodRecordingStep.feeling &&
          _expression != _reviewSnapshot!.expression) {
        _step = MoodRecordingStep.intensity;
        _emit();
        return;
      }
      _reviewSnapshot = null;
      _step = MoodRecordingStep.review;
    } else {
      _step = MoodRecordingStep.values[_step.index + 1];
    }
    _changed();
  }

  /// Returns true when the caller should run the whole-flow close confirmation.
  bool back() {
    if (!active || saving) return false;
    final snapshot = _reviewSnapshot;
    if (snapshot != null) {
      _mood = snapshot.mood;
      _expression = snapshot.expression;
      _intensity = snapshot.intensity;
      _causes
        ..clear()
        ..addAll(snapshot.causes);
      _coping
        ..clear()
        ..addAll(snapshot.coping);
      _reviewSnapshot = null;
      _step = MoodRecordingStep.review;
      _emit();
      return false;
    }
    if (_step == MoodRecordingStep.feeling) return true;
    _step = MoodRecordingStep.values[_step.index - 1];
    _changed();
    return false;
  }

  Future<MoodEntry?> save() async {
    if (!canContinue || _step != MoodRecordingStep.review || _completed) {
      return null;
    }
    saving = true;
    error = null;
    _emit();
    final detector = const CrisisDetector();
    final note = _string(_legacy['note']);
    final crisis = detector.canTrigger('mood', detector.analyze(note ?? ''));
    final candidate = MoodEntry(
      id: _id,
      mood: _mood!,
      expressionSlug: _expression,
      intensity: _intensity,
      triggers: _causes.toList(),
      copingStrategies: _coping.toList(),
      bodySensations: _strings(_legacy['body']).toList(),
      customTrigger: _string(_legacy['custom_trigger']),
      sleepQuality: _integer(_legacy['sleep']),
      energyLevel: _integer(_legacy['energy']),
      note: note,
      copingHelped: _string(_legacy['coping_helped']),
      isCrisisFlagged: crisis || (entry?.isCrisisFlagged ?? false),
      createdAt: _createdAt,
      updatedAt: _now(),
    );
    try {
      await _writes;
      if (!active) return null;
      final saved = await _repository.save(candidate);
      if (!active) return null;
      _completed = true;
      if (entry == null) {
        try {
          await _drafts.clear();
        } catch (_) {
          /* Persistence already succeeded. */
        }
      }
      return active ? saved : null;
    } catch (failure) {
      if (active) {
        error = failure is PlanAccessException
            ? failure.message
            : "We couldn't save your check-in. Your draft is still here.";
      }
      return null;
    } finally {
      saving = false;
      _emit();
    }
  }

  void _changed() {
    _queueDraft();
    _emit();
  }

  static String? _string(Object? value) => value is String ? value : null;
  static String? _nonEmptyString(Object? value) =>
      value is String && value.trim().isNotEmpty ? value : null;
  static int? _integer(Object? value) => value is int ? value : null;

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _accounts?.cancel();
    super.dispose();
  }
}
