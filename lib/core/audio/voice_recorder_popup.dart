import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import '../permissions/permission_service.dart';
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
    barrierColor: Colors.black12,
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
              maxHeight: size.height * .58,
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
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: .55),
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
  StreamSubscription<Amplitude>? _amplitudes;
  final List<double> _samples = [];
  bool _showInfo = false;
  bool _recording = false, _busy = false;
  int _seconds = 0;
  String? _path, _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_start());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _recording && !_busy) {
      unawaited(_stop());
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
    _timer?.cancel();
    unawaited(_amplitudes?.cancel());
    _watch.stop();
    unawaited(_recorder.dispose());
    unawaited(_delete());
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final permission =
          await (widget.requestMicrophone?.call() ??
              PermissionService.requestMicrophone());
      if (!mounted) return;
      if (permission != MicPermissionResult.granted) {
        setState(
          () => _error = permission == MicPermissionResult.permanentlyDenied
              ? 'Microphone access is blocked. Enable it in Settings.'
              : 'Microphone access is needed to record.',
        );
        return;
      }
      await _delete();
      await _recorder.start();
      if (!mounted) {
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final label = _recording
        ? 'Recording'
        : _path != null
        ? 'Preview recording'
        : 'Ready when you are';
    final time =
        '${_seconds ~/ 60}:${(_seconds % 60).toString().padLeft(2, '0')}';
    return PopScope(
      canPop: !_busy && !_recording,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: .09),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.journal
                              ? Icons.graphic_eq_rounded
                              : Icons.mic_none_rounded,
                          color: colors.primary,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.journal ? 'Voice journal' : 'Voice message',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        tooltip: 'How is this saved?',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(() => _showInfo = !_showInfo),
                        icon: Icon(
                          _showInfo ? Icons.info : Icons.info_outline,
                          size: 20,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_recording) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: colors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                        ],
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurfaceVariant,
                            letterSpacing: .3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Center(
                    child: Text(
                      time,
                      style: TextStyle(
                        fontSize: 38,
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -1.5,
                        color: colors.onSurface,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: .055),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _path == null
                        ? VoiceWaveform(
                            samples: _samples,
                            recording: _recording,
                          )
                        : VoicePlayer(
                            key: ValueKey(_path),
                            source: _path!,
                            duration: _seconds,
                            waveform: List.of(_samples),
                          ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      _path != null
                          ? 'Listen back. Send when you are ready.'
                          : 'A quiet space. A moment for your voice.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (_showInfo)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.journal
                              ? 'Saved privately to your account when synced. Offline recordings stay on this device until uploaded. Your provider cannot hear your journal audio.'
                              : 'Uploaded only when you tap Send, then available to you and your provider. Keep this card open to retry a failed send.',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.5,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  if (_error != null)
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  if (_error?.contains('Settings') == true)
                    TextButton(
                      onPressed: PermissionService.openAppSettings,
                      child: const Text('Open Settings'),
                    ),
                  if (_busy)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(
                        semanticsLabel: 'Preparing voice recording',
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton.outlined(
                  tooltip: 'Discard recording',
                  onPressed: _busy
                      ? null
                      : () async {
                          _timer?.cancel();
                          await _amplitudes?.cancel();
                          await _recorder.cancel();
                          if (context.mounted) Navigator.pop(context);
                        },
                  icon: const Icon(Icons.delete_outline_rounded, size: 21),
                ),
                if (_recording) ...[
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: IconButton.filled(
                      tooltip: 'Stop',
                      onPressed: _busy ? null : _stop,
                      icon: const Icon(Icons.stop_rounded, size: 28),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '5:00\nmax',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.4,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ] else ...[
                  IconButton.outlined(
                    tooltip: 'Record again',
                    onPressed: _busy ? null : _start,
                    icon: const Icon(Icons.refresh_rounded, size: 21),
                  ),
                  if (_path != null)
                    FilledButton.icon(
                      onPressed: _busy ? null : _confirm,
                      icon: Icon(
                        widget.journal
                            ? Icons.check_rounded
                            : Icons.arrow_upward_rounded,
                        size: 17,
                      ),
                      label: Text(widget.journal ? 'Save' : 'Send'),
                    )
                  else
                    Text(
                      '5 minute limit',
                      style: TextStyle(
                        fontSize: 10,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
