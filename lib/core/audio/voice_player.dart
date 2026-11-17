import 'dart:async';
import 'dart:io';
import '../services/local_db_service.dart';
import '../storage/token_storage.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../api/api_client.dart';
import 'voice_audio.dart';
import 'voice_waveform.dart';

class VoicePlayer extends StatefulWidget {
  const VoicePlayer({
    super.key,
    required this.source,
    required this.duration,
    this.localPath,
    this.api,
    this.journal = false,
    this.waveform,
    this.preview,
    this.onlineOnly = false,
  });
  final String source;
  final String? localPath;
  final int duration;
  final ApiClient? api;
  final bool journal;
  final List<double>? waveform;
  final VoicePreview? preview;
  final bool onlineOnly;
  @override
  State<VoicePlayer> createState() => _VoicePlayerState();
}

class _VoicePlayerState extends State<VoicePlayer> {
  final _player = AudioPlayer();
  final _owner = LocalDbService().activeUserId;
  StreamSubscription<void>? _clearing, _accounts;
  bool _ended = false;
  bool get _current =>
      mounted && !_ended && _owner == LocalDbService().activeUserId;
  @override
  void initState() {
    super.initState();
    _clearing = TokenStorage.sessionClearing.listen((_) => _end());
    _accounts = LocalDbService().accountChanges.listen((_) {
      if (_owner != LocalDbService().activeUserId) _end();
    });
  }

  void _end() {
    if (!mounted || _ended) return;
    setState(() {
      _ended = true;
      _ready = false;
    });
    unawaited(
      _player.stop().catchError((Object _) {}).whenComplete(_deleteTemporary),
    );
  }

  bool _loading = false;
  String? _error;
  bool _ready = false;
  String? _temporaryPath;
  Future<void> _deleteTemporary() async {
    final path = _temporaryPath;
    _temporaryPath = null;
    if (path != null) {
      try {
        await File(path).delete();
      } catch (_) {
        /* Already removed. */
      }
    }
  }

  Future<void> _prepare() async {
    if (!_current) throw StateError('Account changed');
    if (_ready && !widget.onlineOnly) return;
    final position = _player.processingState == ProcessingState.completed
        ? Duration.zero
        : _player.position;
    final path = await VoiceAudio.playable(
      widget.source,
      api: widget.api,
      journal: widget.journal,
      localPath: widget.localPath,
      preview: widget.preview,
      onlineOnly: widget.onlineOnly,
    );
    if (!_current) {
      if (widget.onlineOnly) await File(path).delete();
      return;
    }
    if (widget.onlineOnly) {
      await _player.stop();
      await _deleteTemporary();
      _temporaryPath = path;
    }
    await _player.setFilePath(path);
    if (widget.onlineOnly) await _player.seek(position);
    if (!_current) {
      await _player.stop();
      return;
    }
    _ready = true;
  }

  Future<void> _seek(double fraction) async {
    if (_loading || !_current) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _prepare();
      if (!_current) return;
      final total = _player.duration ?? Duration(seconds: widget.duration);
      await _player.seek(
        Duration(milliseconds: (total.inMilliseconds * fraction).round()),
      );
    } catch (_) {
      if (widget.onlineOnly) {
        await _player.stop();
        _ready = false;
        await _deleteTemporary();
      }
      if (mounted) setState(() => _error = 'Could not seek. Tap to retry.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    unawaited(_clearing?.cancel());
    unawaited(_accounts?.cancel());
    unawaited(_player.dispose().whenComplete(_deleteTemporary));
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_loading) return;
    if (_player.playing &&
        _player.processingState != ProcessingState.completed) {
      await _player.pause();
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _prepare();
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      if (!_current) return;
      setState(() => _loading = false);
      await _player.play();
    } catch (_) {
      if (widget.onlineOnly) {
        await _player.stop();
        _ready = false;
        await _deleteTemporary();
      }
      if (mounted) setState(() => _error = 'Could not play. Tap to retry.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => _ended
      ? const SizedBox.shrink()
      : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                StreamBuilder<PlayerState>(
                  stream: _player.playerStateStream,
                  builder: (context, snapshot) => IconButton.filledTonal(
                    tooltip: _player.playing
                        ? 'Pause voice recording'
                        : 'Play voice recording',
                    onPressed: _loading ? null : _toggle,
                    icon: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _player.playing &&
                                    _player.processingState !=
                                        ProcessingState.completed
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<Duration>(
                    stream: _player.positionStream,
                    builder: (context, snapshot) {
                      final total =
                          (_player.duration?.inMilliseconds ??
                                  widget.duration * 1000)
                              .clamp(1, 3600000)
                              .toDouble();
                      if (widget.waveform != null) {
                        return VoiceWaveform(
                          samples: widget.waveform!,
                          progress:
                              ((snapshot.data?.inMilliseconds ?? 0) / total)
                                  .clamp(0, 1),
                          onSeek: _seek,
                        );
                      }
                      return Slider(
                        label: 'Recording position',
                        value: (snapshot.data?.inMilliseconds ?? 0)
                            .clamp(0, total)
                            .toDouble(),
                        max: total,
                        onChanged: _ready
                            ? (value) => _seek(value / total)
                            : null,
                      );
                    },
                  ),
                ),
                if (widget.waveform == null)
                  Text(
                    '${widget.duration ~/ 60}:${(widget.duration % 60).toString().padLeft(2, '0')}',
                  ),
              ],
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        );
}
