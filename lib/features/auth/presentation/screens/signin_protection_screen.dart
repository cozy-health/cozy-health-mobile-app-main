import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/widgets/wellness_panel.dart';
import '../../../../core/widgets/wellness_sheet.dart';
import '../../data/auth_service.dart';
import '../../data/signin_security.dart';
import '../controllers/signin_protection_controller.dart';
import '../widgets/auth_ui.dart';

class SignInProtectionScreen extends StatefulWidget {
  const SignInProtectionScreen({
    super.key,
    this.attempt,
    this.auth,
    this.settings = false,
  });
  final PendingSignIn? attempt;
  final AuthService? auth;
  final bool settings;
  @override
  State<SignInProtectionScreen> createState() => _SignInProtectionScreenState();
}

class _SignInProtectionScreenState extends State<SignInProtectionScreen> {
  late final SignInProtectionController _model;
  final _code = TextEditingController(), _password = TextEditingController();
  final _answers = List.generate(3, (_) => TextEditingController());
  final _selected = List<String?>.filled(3, null);
  Timer? _ticker;
  ProtectionStep? _previous;
  BuildContext? _identityContext;
  String? _validation;
  bool _popping = false;
  @override
  void initState() {
    super.initState();
    _model = SignInProtectionController(
      auth: widget.auth ?? AuthService(),
      attempt: widget.attempt,
      settings: widget.settings,
    );
    _model.addListener(_changed);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    if (widget.settings) unawaited(_model.loadPreferences());
  }

  void _clearSecrets() {
    _code.clear();
    _password.clear();
    for (final answer in _answers) {
      answer.clear();
    }
  }

  void _changed() {
    if (!mounted) return;
    if (_previous != _model.step) {
      _clearSecrets();
      _validation = null;
      _previous = _model.step;
    }
    final questions = _model.preferences?.questions ?? const <SignInQuestion>[];
    if (questions.length >= 3) {
      for (var i = 0; i < 3; i++) {
        if (!questions.any((q) => q.id == _selected[i])) {
          _selected[i] = questions[i].id;
        }
      }
    }
    if (_model.step == ProtectionStep.ended) {
      final dialog = _identityContext;
      if (dialog != null &&
          dialog.mounted &&
          ModalRoute.of(dialog)?.isCurrent == true) {
        Navigator.of(dialog).pop();
      }
    }
    setState(() {});
    if (!widget.settings && _model.step == ProtectionStep.done && !_popping) {
      _popping = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ModalRoute.of(context)?.isCurrent == true) {
          Navigator.of(context).pop(_model.result);
        }
      });
    }
  }

  Future<void> _leave() async {
    if (_model.busy || _popping) return;
    _popping = true;
    _clearSecrets();
    // Navigation is immediate; revocation is bound to the provisional credential.
    unawaited(_model.cancel());
    if (mounted) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        GoRouter.maybeOf(context)?.go(widget.settings ? '/settings' : '/login');
      }
    }
  }

  Future<void> _verify() async {
    FocusScope.of(context).unfocus();
    final challenge = _model.challenge;
    if (challenge == null) return;
    if (challenge.method == 'email' &&
        !RegExp(r'^\d{6}$').hasMatch(_code.text.trim())) {
      setState(() => _validation = 'Enter the six-digit code from your email.');
      return;
    }
    if (challenge.method == 'questions' &&
        _answers
            .take(2)
            .any((a) => a.text.trim().isEmpty || a.text.runes.length > 200)) {
      setState(
        () => _validation =
            'Enter an answer for both questions, up to 200 characters each.',
      );
      return;
    }
    setState(() => _validation = null);
    try {
      await _model.verify(
        code: challenge.method == 'email' ? _code.text.trim() : null,
        answers: challenge.method == 'questions'
            ? {
                for (var i = 0; i < challenge.questions.length; i++)
                  challenge.questions[i].id: _answers[i].text,
              }
            : null,
      );
    } finally {
      if (mounted) _clearSecrets();
    }
  }

  Future<void> _identity() async {
    _password.clear();
    final accepted = await showWellnessDialog<bool>(
      context: context,
      builder: (dialog) {
        _identityContext = dialog;
        return WellnessSheet(
          title: 'Confirm your identity',
          children: [
            const Text(
              'Enter your current password. We will then send an email code before you can change sign-in protection.',
            ),
            const SizedBox(height: 16),
            AuthTextField(
              label: 'Current password',
              controller: _password,
              obscure: true,
              maxLength: 255,
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _password,
              builder: (_, value, _) => WellnessAction(
                label: 'Send verification code',
                onPressed: value.text.isNotEmpty
                    ? () => Navigator.of(dialog).pop(true)
                    : null,
                icon: Icons.mark_email_read_outlined,
              ),
            ),
            WellnessAction(
              label: 'Cancel',
              onPressed: () => Navigator.of(dialog).pop(false),
            ),
          ],
        );
      },
    );
    _identityContext = null;
    if (!mounted) return;
    final password = _password.text;
    _password.clear();
    if (accepted == true && password.isNotEmpty) {
      await _model.beginSettings(password);
    }
  }

  Future<void> _chooseQuestion(int index) async {
    final questions = _model.preferences?.questions ?? const <SignInQuestion>[];
    final selected = await showWellnessDialog<String>(
      context: context,
      builder: (dialog) => WellnessSheet(
        title: 'Choose a security question',
        children: [
          for (final q in questions)
            WellnessAction(
              label: q.prompt,
              selected: _selected[index] == q.id,
              onPressed: () => Navigator.of(dialog).pop(q.id),
              icon: Icons.help_outline,
            ),
        ],
      ),
    );
    if (mounted && selected != null) {
      setState(() {
        _selected[index] = selected;
        _answers[index].clear();
      });
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    try {
      await _model.save([
        for (var i = 0; i < 3; i++)
          {'id': _selected[i] ?? '', 'answer': _answers[i].text},
      ]);
    } finally {
      if (mounted) _clearSecrets();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _model.removeListener(_changed);
    unawaited(_model.cancel());
    _model.dispose();
    _code.dispose();
    _password.dispose();
    for (final answer in _answers) {
      answer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = _model.step, challenge = _model.challenge;
    final checking =
        step == ProtectionStep.challenge || step == ProtectionStep.settingsCode;
    final enabled = !_model.busy && _model.blockedSeconds == 0;
    final message = _validation ?? _model.error;
    final delivery = challenge?.emailDelivery;
    return PopScope<Map<String, dynamic>>(
      canPop: !_model.busy,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) unawaited(_model.cancel());
      },
      child: AuthScaffold(
        title: widget.settings ? 'Sign-in protection' : 'Confirm your sign-in',
        subtitle:
            'Use security questions or an email code. Your answers stay private and are never shown to support.',
        onBack: _leave,
        children: [
          if (_model.busy)
            const LinearProgressIndicator(
              semanticsLabel: 'Checking sign-in protection',
            ),
          if (message != null) ...[
            Text(message, semanticsLabel: message),
            const SizedBox(height: 16),
          ],
          if (_model.blockedSeconds > 0)
            Text('Try again in ${_model.blockedSeconds} seconds.'),
          if (checking && challenge != null) ...[
            Text(
              _model.secondsLeft > 0
                  ? 'Check expires in ${_model.secondsLeft ~/ 60}m ${_model.secondsLeft % 60}s.'
                  : 'This check has expired. Start sign-in again.',
            ),
            const SizedBox(height: 16),
            if (challenge.method == 'email') ...[
              Text(
                delivery == 'queued'
                    ? 'A code is queued for email delivery. Check your inbox and spam folder.'
                    : delivery == 'failed' || delivery == 'unavailable'
                    ? 'The email could not be queued. You can retry sending after the cooldown.'
                    : 'Use the latest code from your email.',
              ),
              const SizedBox(height: 16),
              AuthTextField(
                key: const ValueKey('protection-email-code'),
                label: 'Six-digit email code',
                controller: _code,
                keyboardType: TextInputType.number,
                maxLength: 6,
                enabled: enabled,
                autofillHints: const [AutofillHints.oneTimeCode],
              ),
            ] else ...[
              const Text('Answer the two questions you previously chose.'),
              for (var i = 0; i < challenge.questions.length; i++) ...[
                AuthTextField(
                  key: ValueKey('protection-challenge-answer-$i'),
                  label: challenge.questions[i].prompt,
                  controller: _answers[i],
                  obscure: true,
                  maxLength: 200,
                  enabled: enabled,
                ),
                const SizedBox(height: 16),
              ],
            ],
            const SizedBox(height: 16),
            WellnessAction(
              key: const ValueKey('protection-verify'),
              label: 'Verify and continue',
              onPressed: enabled && _model.secondsLeft > 0 ? _verify : null,
              icon: Icons.verified_user_outlined,
            ),
            const SizedBox(height: 8),
            WellnessAction(
              key: const ValueKey('protection-resend'),
              label: _model.resendSeconds > 0
                  ? 'Send email code in ${_model.resendSeconds}s'
                  : challenge.method == 'questions'
                  ? 'Use an email code instead'
                  : 'Resend email code',
              onPressed: _model.canResend
                  ? () {
                      _clearSecrets();
                      unawaited(_model.resend());
                    }
                  : null,
              icon: Icons.email_outlined,
            ),
          ],
          if (step == ProtectionStep.preferences) ...[
            const Text(
              'Choose how to confirm future sign-ins on a new device or after 14 days of inactivity. Email remains available if you forget your answers.',
            ),
            const SizedBox(height: 16),
            WellnessAction(
              label: 'Security questions',
              selected: _model.method == 'questions',
              onPressed: enabled
                  ? () {
                      _clearSecrets();
                      _model.chooseMethod('questions');
                    }
                  : null,
              icon: Icons.help_outline,
            ),
            WellnessAction(
              label: 'Email code',
              selected: _model.method == 'email',
              onPressed: enabled
                  ? () {
                      _clearSecrets();
                      _model.chooseMethod('email');
                    }
                  : null,
              icon: Icons.email_outlined,
            ),
            if (_model.method == 'questions') ...[
              const Text(
                'Choose three different questions. Use memorable secret answers that other people cannot easily guess.',
              ),
              for (var i = 0; i < 3; i++) ...[
                const SizedBox(height: 16),
                WellnessAction(
                  label:
                      'Question ${i + 1}: ${_model.preferences?.questions.where((q) => q.id == _selected[i]).firstOrNull?.prompt ?? 'Choose a question'}',
                  onPressed: enabled ? () => _chooseQuestion(i) : null,
                  icon: Icons.help_outline,
                ),
                AuthTextField(
                  key: ValueKey('protection-enrollment-answer-$i'),
                  label: 'Secret answer ${i + 1}',
                  controller: _answers[i],
                  obscure: true,
                  maxLength: 200,
                  enabled: enabled,
                ),
              ],
            ],
            const SizedBox(height: 16),
            WellnessAction(
              key: const ValueKey('protection-save'),
              label: 'Save sign-in protection',
              onPressed: enabled && _model.hasTicket ? _save : null,
              icon: Icons.shield_outlined,
            ),
            if (!_model.hasTicket)
              WellnessAction(
                label: 'Confirm identity again',
                onPressed: enabled ? _identity : null,
                icon: Icons.badge_outlined,
              ),
            if (_model.uncertain)
              WellnessAction(
                label: 'Check saved protection',
                onPressed: enabled ? _model.reconcile : null,
                icon: Icons.refresh,
              ),
          ],
          if (step == ProtectionStep.identity) ...[
            Text(
              'Current saved method: ${_model.preferences?.method == 'questions' ? 'security questions' : 'email code'}.',
            ),
            const Text(
              'Changing this setting requires your current password and a fresh email code.',
            ),
            const SizedBox(height: 16),
            WellnessAction(
              label: 'Confirm identity',
              onPressed: enabled ? _identity : null,
              icon: Icons.badge_outlined,
            ),
          ],
          if (step == ProtectionStep.ready) ...[
            const Text(
              'The saved server setting has been checked. Continuing uses that current setting; it does not confirm that an earlier unanswered save succeeded.',
            ),
            WellnessAction(
              label: 'Continue with saved protection',
              onPressed: enabled ? _model.continueSaved : null,
              icon: Icons.login,
            ),
            WellnessAction(
              label: 'Confirm identity to replace it',
              onPressed: enabled ? _identity : null,
              icon: Icons.badge_outlined,
            ),
          ],
          if (step == ProtectionStep.held)
            const Text(
              'Sign-in protection setup is not available in this development build yet. This screen has not changed your protection settings.',
            ),
          if ((step == ProtectionStep.loading && !_model.busy) ||
              step == ProtectionStep.held)
            WellnessAction(
              label: 'Retry loading',
              onPressed: enabled ? _model.loadPreferences : null,
              icon: Icons.refresh,
            ),
          if (step == ProtectionStep.done && widget.settings)
            const Text('Your sign-in protection setting is saved.'),
          const SizedBox(height: 16),
          WellnessAction(
            label: widget.settings ? 'Back to settings' : 'Start sign-in again',
            onPressed: !_model.busy ? _leave : null,
            icon: Icons.arrow_back,
          ),
        ],
      ),
    );
  }
}
