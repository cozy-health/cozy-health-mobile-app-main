import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/api/api_exceptions.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/auth_service.dart';
import '../../data/signin_security.dart';

enum ProtectionStep {
  loading,
  challenge,
  identity,
  settingsCode,
  preferences,
  ready,
  held,
  done,
  ended,
}

/// Answers/passwords are command arguments, never persisted controller state.
class SignInProtectionController extends ChangeNotifier {
  SignInProtectionController({
    required this.auth,
    PendingSignIn? attempt,
    this.settings = false,
    DateTime Function()? now,
  }) : _attempt = attempt,
       generation = attempt?.generation ?? TokenStorage.generation,
       _now = now ?? DateTime.now {
    step = settings ? ProtectionStep.loading : ProtectionStep.challenge;
    _resendAt = _now().add(const Duration(seconds: 60));
    _clearing = TokenStorage.sessionClearing.listen((_) {
      if (!_finishing) _end();
    });
    _changes = TokenStorage.sessionChanges.listen((_) {
      if (!_finishing &&
          TokenStorage.generation != generation &&
          step != ProtectionStep.done) {
        _end();
      }
    });
  }
  final AuthService auth;
  final bool settings;
  final int generation;
  final DateTime Function() _now;
  PendingSignIn? _attempt;
  VerifiedSignIn? _verified;
  SignInChallenge? _settingsChallenge;
  String? _ticket;
  SignInPreferences? preferences;
  late ProtectionStep step;
  String method = 'questions';
  bool busy = false, recovered = false, uncertain = false;
  String? error;
  Map<String, dynamic>? result;
  bool _disposed = false, _finishing = false, _cancelled = false;
  late DateTime _resendAt;
  DateTime? _blockedUntil;
  StreamSubscription<void>? _clearing, _changes;
  SignInChallenge? get challenge => step == ProtectionStep.settingsCode
      ? _settingsChallenge
      : _attempt?.challenge;
  int get secondsLeft =>
      ((challenge?.expiresAt.difference(_now()).inMilliseconds ?? 0) / 1000)
          .ceil()
          .clamp(0, 86400)
          .toInt();
  int get resendSeconds => (_resendAt.difference(_now()).inMilliseconds / 1000)
      .ceil()
      .clamp(0, 86400)
      .toInt();
  int get blockedSeconds =>
      ((_blockedUntil?.difference(_now()).inMilliseconds ?? 0) / 1000)
          .ceil()
          .clamp(0, 86400)
          .toInt();
  bool get hasTicket => _ticket != null;
  bool get canResend =>
      !busy && resendSeconds == 0 && blockedSeconds == 0 && secondsLeft > 0;
  bool get _current =>
      !_disposed &&
      step != ProtectionStep.ended &&
      TokenStorage.generation == generation;
  void _guard() {
    if (!_current) throw const SignInAttemptChanged();
  }

  void _end() {
    if (_disposed || step == ProtectionStep.done) return;
    step = ProtectionStep.ended;
    _ticket = null;
    error = 'This sign-in attempt ended. Start sign-in again.';
    notifyListeners();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (busy ||
        _disposed ||
        step == ProtectionStep.ended ||
        step == ProtectionStep.done) {
      return;
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      _guard();
      await action();
    } on SignInAttemptChanged {
      _end();
    } on ApiRateLimitException catch (e) {
      _blockedUntil = _now().add(Duration(seconds: e.retryAfterSeconds));
      error = e.message;
    } on ApiException catch (e) {
      error = e.message;
    } on AuthLocalDataException catch (e) {
      error = e.message;
    } catch (_) {
      error =
          'The security check could not be completed. Retry, or start sign-in again.';
    } finally {
      _finishing = false;
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> loadPreferences() => _run(() async {
    final value = await auth.signInPreferences(provisional: _verified);
    _guard();
    preferences = value;
    if (!value.enabled) {
      step = ProtectionStep.held;
      return;
    }
    method = settings ? value.method : 'questions';
    step = _verified != null && value.enrolled
        ? ProtectionStep.ready
        : _verified != null || _ticket != null
        ? ProtectionStep.preferences
        : ProtectionStep.identity;
  });
  void chooseMethod(String value) {
    if (busy || !['questions', 'email'].contains(value)) return;
    method = value;
    error = null;
    notifyListeners();
  }

  Future<void> verify({
    String? code,
    Map<String, String>? answers,
  }) => _run(() async {
    if (secondsLeft == 0 || blockedSeconds > 0) {
      error =
          'This check expired or is temporarily limited. Wait, or start sign-in again.';
      return;
    }
    if (step == ProtectionStep.settingsCode) {
      final pending = _settingsChallenge;
      if (pending == null) {
        throw const FormatException('Missing settings check');
      }
      final ticket = await auth.confirmSecuritySettings(
        pending,
        code ?? '',
        expectedGeneration: generation,
      );
      _guard();
      _ticket = ticket;
      uncertain = false;
      recovered = false;
      step = ProtectionStep.loading;
      final value = await auth.signInPreferences(provisional: _verified);
      _guard();
      preferences = value;
      step = ProtectionStep.preferences;
      return;
    }
    final attempt = _attempt;
    if (attempt == null) throw const FormatException('Missing sign-in check');
    final verified = await auth.verifySignIn(
      attempt,
      code: code,
      answers: answers,
    );
    if (!_current) {
      unawaited(auth.discardVerifiedSignIn(verified));
      throw const SignInAttemptChanged();
    }
    _verified = verified;
    _ticket = verified.settingsToken;
    step = ProtectionStep.loading;
    if (!verified.requiresEnrollment) {
      await _finish();
      return;
    }
    final value = await auth.signInPreferences(provisional: verified);
    _guard();
    preferences = value;
    method = 'questions';
    step = value.enabled ? ProtectionStep.preferences : ProtectionStep.held;
  });
  Future<void> resend() => _run(() async {
    if (resendSeconds > 0 || blockedSeconds > 0 || secondsLeft == 0) return;
    final settingsChallenge = _settingsChallenge;
    final original =
        step == ProtectionStep.settingsCode && settingsChallenge != null
        ? PendingSignIn(
            challenge: settingsChallenge,
            generation: generation,
            stayLoggedIn: false,
            newAccount: false,
          )
        : _attempt;
    if (original == null) return;
    final next = await auth.resendSignIn(original);
    _guard();
    if (step == ProtectionStep.settingsCode) {
      _settingsChallenge = next.challenge;
    } else {
      _attempt = next;
    }
    _resendAt = _now().add(const Duration(seconds: 60));
  });
  Future<void> beginSettings(String password) => _run(() async {
    if (blockedSeconds > 0 || preferences?.enabled != true) return;
    final next = await auth.verifySecuritySettings(
      password,
      expectedGeneration: generation,
      provisional: _verified,
    );
    _guard();
    if (next.method != 'email') {
      throw const FormatException('Settings require email verification');
    }
    _settingsChallenge = next;
    _ticket = null;
    _resendAt = _now().add(const Duration(seconds: 60));
    step = ProtectionStep.settingsCode;
  });
  Future<void> save(List<Map<String, String>> questions) => _run(() async {
    final ticket = _ticket;
    if (step != ProtectionStep.preferences || preferences?.enabled != true) {
      return;
    }
    if (ticket == null) {
      error = 'Verify your identity again before changing this setting.';
      return;
    }
    if (method == 'questions' &&
        (questions.length != 3 ||
            questions.map((q) => q['id']).toSet().length != 3 ||
            questions.any((q) {
              final answer = (q['answer'] ?? '').trim().replaceAll(
                RegExp(r'\s+'),
                ' ',
              );
              return answer.runes.length < 3 ||
                  answer.runes.length > 200 ||
                  !(preferences?.questions.any(
                        (known) => known.id == q['id'],
                      ) ??
                      false);
            }))) {
      error =
          'Choose three different questions and an answer of 3 to 200 characters for each.';
      return;
    }
    try {
      final value = await auth.saveSignInPreferences(
        method: method,
        settingsToken: ticket,
        questions: method == 'questions' ? questions : null,
        provisional: _verified,
        expectedGeneration: generation,
      );
      _guard();
      preferences = value;
      _ticket = null;
      if (!value.enrolled || value.method != method) {
        throw const FormatException('Protection not confirmed');
      }
      if (settings) {
        step = ProtectionStep.done;
      } else {
        await _finish();
      }
    } on ApiNetworkException {
      _uncertain();
    } on ApiTimeoutException {
      _uncertain();
    } on ApiServerException {
      _uncertain();
    } on FormatException {
      _uncertain();
    }
  });
  void _uncertain() {
    _guard();
    _ticket = null;
    uncertain = true;
    error =
        'The save response was lost. Check the saved setting before continuing; do not assume the new answers were saved.';
  }

  Future<void> reconcile() => _run(() async {
    final value = await auth.signInPreferences(provisional: _verified);
    _guard();
    preferences = value;
    method = value.method;
    recovered = true;
    if (!value.enabled) {
      step = ProtectionStep.held;
      return;
    }
    step = !settings && value.enrolled
        ? ProtectionStep.ready
        : ProtectionStep.preferences;
    error =
        'The server currently uses ${value.method == 'questions' ? 'security questions' : 'an email code'}. You can keep that setting or verify your identity to replace it.';
  });
  Future<void> continueSaved() => _run(() async {
    if (preferences?.enrolled == true && !settings) await _finish();
  });
  Future<void> _finish() async {
    _guard();
    final verified = _verified;
    if (verified == null) {
      throw const FormatException('Missing verified sign-in');
    }
    _finishing = true;
    result = await auth.finishVerifiedSignIn(verified);
    if (!_disposed) step = ProtectionStep.done;
  }

  Future<void> cancel() async {
    if (step == ProtectionStep.done || _cancelled) return;
    _cancelled = true;
    final provisional = _verified;
    _end();
    if (provisional != null) await auth.discardVerifiedSignIn(provisional);
  }

  @override
  void dispose() {
    _disposed = true;
    _ticket = null;
    _clearing?.cancel();
    _changes?.cancel();
    super.dispose();
  }
}
