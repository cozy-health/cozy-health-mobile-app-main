import 'dart:async';
import 'package:flutter/widgets.dart';
import '../models/affirmation_assignment.dart';
import '../repositories/affirmation_repository.dart';
import '../storage/token_storage.dart';
import 'local_db_service.dart';

enum AffirmationStatus { loading, ready, guest, empty, error }

class AffirmationState {
  const AffirmationState({
    this.assignment,
    this.status = AffirmationStatus.guest,
  });
  static const encouragement = "You're doing great.\nSmall steps count.";
  final AffirmationAssignment? assignment;
  final AffirmationStatus status;
  String get text => assignment?.body ?? encouragement;
  String get reflection {
    final words = text.toLowerCase();
    if (RegExp(r'\b(rest|slowing|pause|pace|breathing)\b').hasMatch(words)) {
      return 'You can give yourself a little room to pause. Rest and a slower '
          'pace do not make your effort less valuable. You deserve care even '
          'when you are not getting things done.';
    }
    if (RegExp(r'\b(help|support|alone|carry)\b').hasMatch(words)) {
      return 'You deserve support as well as space to be heard. You do not '
          'have to solve everything by yourself or find perfect words before '
          'telling someone you trust that today feels difficult.';
    }
    if (RegExp(r'\b(feeling|feelings|feel|okay)\b').hasMatch(words)) {
      return 'There is room for how you feel today. You do not need to hide '
          'a difficult feeling or turn it into a positive one to deserve '
          'kindness. Start by noticing what you need in this moment.';
    }
    if (RegExp(r'\b(step|progress|learning|begin|small)\b').hasMatch(words)) {
      return 'Small efforts are worth noticing, even when the result is not '
          'obvious yet. You can begin with what feels manageable today and '
          'give yourself patience while you find your way.';
    }
    return 'These words offer a gentler way to speak to yourself. A difficult '
        'moment does not erase your worth, your effort or the care you '
        'deserve. You can let this be a little encouragement, without '
        'expecting yourself to feel different straight away.';
  }

  bool get canRetry =>
      status == AffirmationStatus.error || status == AffirmationStatus.empty;
  String label(DateTime now) => assignment == null
      ? 'General encouragement'
      : assignment!.isExpired(now)
      ? 'Last saved affirmation'
      : 'Your affirmation';
}

/// Shared by Home and detail; only visible consumers keep refresh timers alive.
class AffirmationController extends ChangeNotifier with WidgetsBindingObserver {
  AffirmationController({
    AffirmationRepository? repository,
    DateTime Function()? now,
    Stream<void>? accountChanges,
    String? Function()? activeUserId,
  }) : _repository = repository ?? AffirmationRepository(now: now),
       _now = now ?? DateTime.now,
       _accountChanges = accountChanges ?? LocalDbService().accountChanges,
       _activeUserId = activeUserId ?? (() => LocalDbService().activeUserId);
  static final instance = AffirmationController();
  final AffirmationRepository _repository;
  final DateTime Function() _now;
  final Stream<void> _accountChanges;
  final String? Function() _activeUserId;
  AffirmationState state = const AffirmationState();
  String get label => state.label(_now());
  Timer? _timer;
  Future<void>? _work;
  StreamSubscription<void>? _accounts, _sessions, _sessionChanges;
  String? _owner, _user;
  int _consumers = 0, _generation = 0;
  bool _disposed = false;
  bool _foreground = true;
  bool _awaitingToken = false;

  void attach() {
    if (_disposed) return;
    if (_consumers++ > 0) return;
    _awaitingToken = false;
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _user = _activeUserId();
    WidgetsBinding.instance.addObserver(this);
    _accounts = _accountChanges.listen((_) {
      final user = _activeUserId();
      if (_user != user) {
        _user = user;
        _awaitingToken = true;
        _reset();
        // Login activates account storage before replacing its auth token.
        // Wait for the completed token change rather than reading the old cache.
      }
    });
    _sessions = TokenStorage.sessionClearing.listen((_) {
      _awaitingToken = true;
      _reset();
    });
    _sessionChanges = TokenStorage.sessionChanges.listen((_) {
      _awaitingToken = false;
      _reset();
      if (_consumers > 0 && _foreground) {
        scheduleMicrotask(() {
          if (!_disposed && _consumers > 0) unawaited(refresh());
        });
      }
    });
    scheduleMicrotask(() {
      if (_consumers > 0 && !_disposed && _foreground) unawaited(refresh());
    });
  }

  void detach() {
    if (_consumers == 0 || --_consumers > 0) return;
    WidgetsBinding.instance.removeObserver(this);
    _accounts?.cancel();
    _sessions?.cancel();
    _sessionChanges?.cancel();
    _reset(notify: false);
  }

  void _reset({bool notify = true}) {
    _generation++;
    _work = null;
    _owner = null;
    _timer?.cancel();
    state = const AffirmationState();
    if (notify && !_disposed) notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _timer?.cancel();
    }
    if (_foreground && _consumers > 0) {
      unawaited(refresh(force: true));
    }
  }

  Future<void> refresh({bool force = false}) {
    if (_disposed || _awaitingToken) return Future.value();
    if (_work != null) return _work!;
    final work = _load(_generation, force);
    _work = work;
    return work.whenComplete(() {
      if (identical(_work, work)) _work = null;
    });
  }

  Future<bool> _active(int generation, String? scope) async {
    if (_disposed || generation != _generation) return false;
    final current = await _repository.owner();
    if (_disposed || generation != _generation) return false;
    if (scope != current) {
      _reset();
      if (_consumers > 0 && _foreground) {
        scheduleMicrotask(() => unawaited(refresh()));
      }
      return false;
    }
    return true;
  }

  Future<void> _load(int generation, bool force) async {
    String? scope;
    try {
      scope = await _repository.owner();
      if (!await _active(generation, scope)) return;
      if (_owner != scope) state = const AffirmationState();
      _owner = scope;
      if (scope == null) {
        state = const AffirmationState();
        notifyListeners();
        return;
      }
      state = AffirmationState(
        assignment: state.assignment,
        status: AffirmationStatus.loading,
      );
      notifyListeners();
      final cached = await _repository.cached(allowExpired: true);
      if (!await _active(generation, scope)) return;
      state = AffirmationState(
        assignment: cached,
        status: AffirmationStatus.loading,
      );
      notifyListeners();
      final current = await _repository.fetchCurrent(force: force);
      if (!await _active(generation, scope)) return;
      state = AffirmationState(
        assignment: current,
        status: current == null
            ? AffirmationStatus.empty
            : AffirmationStatus.ready,
      );
      notifyListeners();
    } catch (_) {
      if (_disposed || generation != _generation) return;
      String? current;
      try {
        current = await _repository.owner();
      } catch (_) {
        /* Show a retryable storage error. */
      }
      if (_disposed || generation != _generation) return;
      state = AffirmationState(
        assignment: scope != null && scope == current ? state.assignment : null,
        status: AffirmationStatus.error,
      );
      notifyListeners();
    } finally {
      if (!_disposed &&
          generation == _generation &&
          _consumers > 0 &&
          _foreground) {
        _schedule();
      }
    }
  }

  void _schedule() {
    _timer?.cancel();
    if (_owner == null && state.status != AffirmationStatus.error) return;
    final remaining = state.assignment?.expiresAt.difference(_now().toUtc());
    final delay =
        state.status == AffirmationStatus.ready &&
            remaining != null &&
            remaining > Duration.zero
        ? remaining + const Duration(milliseconds: 100)
        : const Duration(minutes: 5);
    _timer = Timer(delay, () => unawaited(refresh(force: true)));
  }

  @override
  void dispose() {
    _disposed = true;
    _reset(notify: false);
    _accounts?.cancel();
    _sessions?.cancel();
    _sessionChanges?.cancel();
    if (_consumers > 0) WidgetsBinding.instance.removeObserver(this);
    _consumers = 0;
    super.dispose();
  }
}
