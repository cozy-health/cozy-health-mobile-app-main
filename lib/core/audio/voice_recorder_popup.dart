import '../widgets/wellness_sheet.dart';
import '../widgets/wellness_panel.dart';
import '../theme/cozy_colors.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import '../permissions/permission_service.dart';
import '../storage/token_storage.dart';
import 'audio_recorder_service.dart';
import 'voice_audio.dart';
import 'voice_player.dart';
import 'voice_waveform.dart';

Future<void> showVoiceRecorder(
  BuildContext context, {
  required bool journal,
  required Future<void> Function(RecordedAudio audio) onConfirm,
  AudioRecorderService? recorder,
  Future<MicPermissionResult> Function()? requestMicrophone,
}) async {
  final box = context.findRenderObject();
  final size = MediaQuery.sizeOf(context);
  final anchorTop = box is RenderBox && box.hasSize && box.size.height <= 100
      ? box.localToGlobal(Offset.zero).dy
      : size.height - 80;
  final bottom = (size.height - anchorTop + 8).clamp(80.0, size.height * .35);
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Voice recorder',
    barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: .32),
    pageBuilder: (context, animation, secondaryAnimation) => SafeArea(
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            math.max(bottom, MediaQuery.viewInsetsOf(context).bottom + 12),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 320,
              maxHeight: math.min(size.height * .58, 400),
            ),
            child: Material(
              elevation: 12,
              shadowColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.transparent
                  : Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: .18),
              color: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _Recorder(
                journal: journal,
                onConfirm: onConfirm,
                recorder: recorder,
                requestMicrophone: requestMicrophone,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Recorder extends StatefulWidget {
  const _Recorder({
    required this.journal,
    required this.onConfirm,
    this.recorder,
    this.requestMicrophone,
  });
  final bool journal;
  final Future<void> Function(RecordedAudio audio) onConfirm;
  final AudioRecorderService? recorder;
  final Future<MicPermissionResult> Function()? requestMicrophone;
  @override
  State<_Recorder> createState() => _RecorderState();
}

class _RecorderState extends State<_Recorder> with WidgetsBindingObserver {
  late final _recorder = widget.recorder ?? AudioRecorderService();
  final _watch = Stopwatch();
  Timer? _timer;
  StreamSubscription<void>? _clearing, _sessions;
  late final int _sessionGeneration = TokenStorage.generation;
  bool _sessionEnded = false;
  bool _settingsPending = false;
  StreamSubscription<Amplitude>? _amplitudes;
  final List<double> _samples = [];
  bool _showInfo = false;
  bool _confirmDiscard = false;
  bool _recording = false, _busy = false;
  int _seconds = 0;
  String? _path, _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clearing = TokenStorage.sessionClearing.listen((_) => _endSession());
    _sessions = TokenStorage.sessionChanges.listen((_) => _endSession());
    unawaited(_start());
  }

  void _endSession() {
    if (!mounted || _sessionEnded) return;
    _sessionEnded = true;
    _timer?.cancel();
    _watch.stop();
    unawaited(_recorder.cancel().catchError((Object _) {}));
    Navigator.of(context).pop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _settingsPending) {
      _settingsPending = false;
      unawaited(_checkPermission());
    }
    if (state != AppLifecycleState.resumed && _recording && !_busy) {
      unawaited(_stop());
    }
  }

  Future<void> _checkPermission() async {
    try {
      final status = await PermissionService.microphoneStatus();
      if (mounted && !_sessionEnded && status == MicPermissionResult.granted) {
        setState(() => _error = null);
      }
    } catch (_) {
      // Keep the existing explanation and explicit retry action.
    }
  }

  Future<void> _openSettings() async {
    _settingsPending = true;
    try {
      if (await PermissionService.openAppSettings()) return;
    } catch (_) {
      // Explain failure below instead of swallowing an unavailable settings app.
    }
    _settingsPending = false;
    if (mounted && !_sessionEnded) {
      setState(
        () => _error =
            'Could not open Settings. Open your phone settings and allow microphone access for Cozy Health.',
      );
    }
  }

  Future<void> _delete() async {
    final path = _path;
    _path = null;
    if (path != null) {
      try {
        await File(path).delete();
      } catch (_) {
        /* Already removed. */
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_clearing?.cancel());
    unawaited(_sessions?.cancel());
    _timer?.cancel();
    unawaited(_amplitudes?.cancel());
    _watch.stop();
    unawaited(_recorder.dispose());
    unawaited(_delete());
    super.dispose();
  }

  Future<void> _start() async {
    if (_sessionEnded || _sessionGeneration != TokenStorage.generation) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final permission =
          await (widget.requestMicrophone?.call() ??
              PermissionService.requestMicrophone());
      if (!mounted ||
          _sessionEnded ||
          _sessionGeneration != TokenStorage.generation) {
        return;
      }
      if (permission != MicPermissionResult.granted) {
        setState(
          () => _error = permission == MicPermissionResult.permanentlyDenied
              ? 'Microphone access is blocked. Enable it in Settings.'
              : permission == MicPermissionResult.restricted
              ? 'Microphone access is restricted by your device settings or administrator.'
              : 'Microphone access is needed to record.',
        );
        return;
      }
      await _delete();
      await _recorder.start();
      if (!mounted ||
          _sessionEnded ||
          _sessionGeneration != TokenStorage.generation) {
        await _recorder.cancel();
        return;
      }
      _watch
        ..reset()
        ..start();
      setState(() {
        _recording = true;
        _seconds = 0;
        _samples.clear();
      });
      await _amplitudes?.cancel();
      _amplitudes = _recorder.amplitudeStream.listen((amplitude) {
        if (!mounted || !_recording) return;
        final level = math
            .sqrt(math.pow(10, amplitude.current / 20) * 4)
            .clamp(0.0, 1.0)
            .toDouble();
        setState(() => _samples.add(level));
      });
      _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (!mounted) return;
        setState(() => _seconds = _watch.elapsed.inSeconds.clamp(0, 300));
        if (_seconds >= 300 && !_busy) unawaited(_stop());
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not start recording. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stop() async {
    setState(() => _busy = true);
    _timer?.cancel();
    await _amplitudes?.cancel();
    _watch.stop();
    try {
      final path = await _recorder.stop();
      if (!mounted) {
        if (path != null) await File(path).delete();
        return;
      }
      if (path == null ||
          !await File(path).exists() ||
          await File(path).length() == 0 ||
          await File(path).length() > 20 * 1024 * 1024) {
        if (path != null && await File(path).exists()) {
          await File(path).delete();
        }
        throw StateError('Invalid recording');
      }
      setState(() {
        _recording = false;
        _path = path;
        _seconds = math
            .max(1, (_watch.elapsedMilliseconds / 1000).ceil())
            .clamp(1, 300);
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _recording = false;
          _error = 'Could not capture audio. Please record again.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    if (_sessionEnded || _sessionGeneration != TokenStorage.generation) return;
    final path = _path;
    if (path == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onConfirm(RecordedAudio(path, _seconds));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not ${widget.journal ? 'save' : 'send'}. Your recording is ready to retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _requestDiscard() {
    if (_busy) return;
    if (_recording || _path != null) {
      setState(() => _confirmDiscard = true);
    } else {
      unawaited(_discard());
    }
  }

  Future<void> _discard() async {
    if (_busy) return;
    _timer?.cancel();
    await _amplitudes?.cancel();
    await _recorder.cancel();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final w = context.cozyColors.wellness;
    final label = _recording
        ? 'Recording'
        : _path != null
        ? 'Preview recording'
        : 'Ready when you are';
    final time =
        '${_seconds ~/ 60}:${(_seconds % 60).toString().padLeft(2, '0')}';
    return PopScope(
      canPop: !_busy && !_recording && _path == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _requestDiscard();
      },
      child: WellnessSheet(
        title: widget.journal ? 'Voice journal' : 'Voice message',
        busy: _busy,
        onClose: _requestDiscard,
        footer: _confirmDiscard
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Discard this recording? It has not been saved.'),
                  SizedBox(height: w.small),
                  WellnessAction(
                    label: 'Keep recording',
                    onPressed: () => setState(() => _confirmDiscard = false),
                  ),
                  SizedBox(height: w.small),
                  WellnessAction(
                    key: const ValueKey('voice-discard-confirm'),
                    label: 'Discard permanently',
                    onPressed: _discard,
                  ),
                ],
              )
            : _recording
            ? Tooltip(
                message: 'Stop',
                child: WellnessAction(
                  label: 'Stop',
                  icon: Icons.stop_rounded,
                  filled: true,
                  onPressed: _busy ? null : _stop,
                ),
              )
            : _path != null
            ? WellnessAction(
                key: const ValueKey('voice-confirm'),
                label: widget.journal ? 'Save' : 'Send',
                icon: widget.journal
                    ? Icons.check_rounded
                    : Icons.send_outlined,
                filled: true,
                onPressed: _busy ? null : _confirm,
              )
            : null,
        children: [
          Tooltip(
            message: 'How is this saved?',
            child: WellnessAction(
              label: 'How is this saved?',
              icon: Icons.info_outline_rounded,
              selected: _showInfo,
              onPressed: () => setState(() => _showInfo = !_showInfo),
            ),
          ),
          SizedBox(height: w.contentGap),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          Text(time, style: Theme.of(context).textTheme.headlineLarge),
          SizedBox(height: w.contentGap),
          WellnessPanel(
            tinted: true,
            child: _path == null
                ? VoiceWaveform(samples: _samples, recording: _recording)
                : VoicePlayer(
                    key: ValueKey(_path),
                    source: _path!,
                    duration: _seconds,
                    waveform: List.of(_samples),
                  ),
          ),
          SizedBox(height: w.small),
          Text(
            _path != null
                ? 'Listen back. Send when you are ready.'
                : 'A quiet space. A moment for your voice.',
          ),
          if (_showInfo) ...[
            SizedBox(height: w.contentGap),
            WellnessPanel(
              child: Text(
                widget.journal
                    ? 'Saved privately to your account when synced. Offline recordings stay on this device until uploaded. Your provider cannot hear your journal audio.'
                    : 'Uploaded only when you tap Send, then available to you and your provider. Keep this card open to retry a failed send.',
              ),
            ),
          ],
          if (_error != null) ...[
            SizedBox(height: w.small),
            Semantics(liveRegion: true, child: Text(_error!)),
          ],
          if (_error?.contains('Settings') == true)
            WellnessAction(label: 'Open Settings', onPressed: _openSettings),
          if (_busy)
            const LinearProgressIndicator(
              semanticsLabel: 'Preparing voice recording',
            ),
          SizedBox(height: w.contentGap),
          if (!_recording)
            Tooltip(
              message: 'Record again',
              child: WellnessAction(
                label: 'Record again',
                icon: Icons.refresh_rounded,
                onPressed: _busy ? null : _start,
              ),
            ),
          SizedBox(height: w.small),
          Tooltip(
            message: 'Discard recording',
            child: WellnessAction(
              label: 'Discard recording',
              icon: Icons.delete_outline_rounded,
              onPressed: _busy ? null : _requestDiscard,
            ),
          ),
          SizedBox(height: w.small),
          const Text('5 minute limit'),
        ],
      ),
    );
  }
}
