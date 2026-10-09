import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/security_service.dart';
import 'storage/token_storage.dart';
import 'routing/app_router.dart';

class SecurityGate extends StatefulWidget {
  const SecurityGate({
    super.key,
    required this.child,
    this.journal = false,
    this.journalRoot = false,
    this.security,
    this.onSessionExpired,
  });
  final Widget child;
  final bool journal;
  final bool journalRoot;
  final SecurityService? security;
  final VoidCallback? onSessionExpired;
  @override
  State<SecurityGate> createState() => _SecurityGateState();
}

class _SecurityGateState extends State<SecurityGate>
    with WidgetsBindingObserver {
  bool _locked = true;
  bool _busy = false;
  bool _backgrounded = false;
  bool _obscured = false;
  bool _ready = false;
  int _revision = 0;
  String? _error;
  final _pin = TextEditingController();
  late final SecurityService _security;

  @override
  void initState() {
    super.initState();
    _security = widget.security ?? SecurityService.instance;
    WidgetsBinding.instance.addObserver(this);
    _security.addListener(_securityChanged);
    _check();
  }

  void _securityChanged() {
    if (!mounted) return;
    if (widget.journal) {
      _check();
    } else if (!_busy &&
        !_security.authenticating &&
        _backgrounded &&
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      _backgrounded = false;
      _resume();
    }
  }

  Future<void> _check() async {
    final revision = ++_revision;
    try {
      final enabled = widget.journal
          ? await _security.hasPin() && !_security.journalUnlocked
          : await TokenStorage().getToken() != null &&
                await _security.appLockEnabled();
      if (!mounted || revision != _revision) return;
      setState(() {
        _locked = enabled;
        _ready = true;
      });
      if (enabled && !widget.journal && !_backgrounded && !_obscured) {
        await _unlock();
      }
    } catch (_) {
      if (!mounted || revision != _revision) return;
      setState(() {
        _ready = true;
        _locked = true;
        _error = 'Unable to read security settings. Try again.';
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      setState(() => _obscured = true);
    }
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _backgrounded = true;
      ++_revision;
      setState(() {
        _locked = true;
        _obscured = true;
        _pin.clear();
      });
      _security.lockJournal();
    }
    if (state == AppLifecycleState.resumed) {
      setState(() => _obscured = false);
      if (_backgrounded && !_security.authenticating) {
        _backgrounded = false;
        _resume();
      }
    }
  }

  Future<void> _resume() async {
    final path = AppRouter.router.routeInformationProvider.value.uri.path;
    final sensitive = path.contains('crisis') || path.contains('safety-plan');
    final expired =
        !widget.journal &&
        await TokenStorage().getToken() != null &&
        await TokenStorage().inactivityExpired(sensitive: sensitive);
    if (!widget.journal && (TokenStorage().isSessionOnly || expired)) {
      await TokenStorage().clearToken();
      _security.lockJournal();
      if (!mounted) return;
      if (widget.onSessionExpired != null) {
        widget.onSessionExpired!();
      } else {
        AppRouter.router.go(AppRouter.login);
      }
    }
    await _check();
  }

  Future<void> _unlock() async {
    if (_busy) return;
    final revision = _revision;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ok = widget.journal
          ? await _security.verifyPin(_pin.text)
          : await _security.authenticate();
      if (!mounted) return;
      if (_backgrounded &&
          !widget.journal &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _backgrounded = false;
        if (TokenStorage().isSessionOnly) {
          await _resume();
          return;
        }
      } else if (revision != _revision || _backgrounded || _obscured) {
        return;
      }
      if (ok && widget.journal) _security.unlockJournal();
      if (!mounted) return;
      setState(() {
        _locked = !ok;
        _error = ok
            ? null
            : (widget.journal
                  ? 'Incorrect PIN.'
                  : 'Unable to unlock. Try again.');
        _pin.clear();
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to unlock. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _security.removeListener(_securityChanged);
    if (widget.journalRoot) _security.lockJournal();
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final covered = _locked || _obscured;
    return Stack(
      children: [
        if (_ready)
          Offstage(
            offstage: covered,
            child: TickerMode(
              enabled: !covered,
              child: ExcludeFocus(excluding: covered, child: widget.child),
            ),
          ),
        if (covered) Positioned.fill(child: _buildLockScreen(context)),
      ],
    );
  }

  Widget _buildLockScreen(BuildContext context) => Scaffold(
    appBar: widget.journal ? AppBar(title: const Text('Journal locked')) : null,
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48),
              const SizedBox(height: 20),
              Text(
                widget.journal
                    ? 'Enter your journal PIN'
                    : 'Unlock Cozy Health',
              ),
              if (widget.journal)
                TextField(
                  controller: _pin,
                  obscureText: true,
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onSubmitted: (_) => _unlock(),
                ),
              if (_error != null) Text(_error!),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy || !_ready ? null : _unlock,
                child: Text(
                  widget.journal
                      ? 'Open journal'
                      : 'Unlock with Face ID / biometrics',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<bool> journalPinDialog(
  BuildContext context, {
  bool setup = false,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (_) => _PinDialog(setup: setup),
      ) ??
      false;
}

class _PinDialog extends StatefulWidget {
  const _PinDialog({required this.setup});
  final bool setup;
  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _busy = false;
  @override
  void dispose() {
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!SecurityService.validPin(_pin.text) ||
        (widget.setup && _pin.text != _confirm.text)) {
      setState(() => _error = 'Use 4–6 digits and matching PINs.');
      return;
    }
    setState(() => _busy = true);
    try {
      if (widget.setup) {
        await SecurityService.instance.setPin(_pin.text);
      } else {
        if (!await SecurityService.instance.verifyPin(_pin.text)) {
          if (mounted) setState(() => _error = 'Incorrect PIN.');
          return;
        }
        await SecurityService.instance.removePin();
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to save PIN. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.setup ? 'Set journal PIN' : 'Enter current journal PIN'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _pin,
          obscureText: true,
          maxLength: 6,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: '4–6 digit PIN'),
        ),
        if (widget.setup)
          TextField(
            controller: _confirm,
            obscureText: true,
            maxLength: 6,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Confirm PIN'),
          ),
        if (_error != null) Text(_error!),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _busy ? null : _save, child: const Text('Save')),
    ],
  );
}
