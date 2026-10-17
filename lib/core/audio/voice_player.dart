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
  });
  final String source;
  final String? localPath;
  final int duration;
  final ApiClient? api;
  final bool journal;
  final List<double>? waveform;
  @override
  State<VoicePlayer> createState() => _VoicePlayerState();
}

class _VoicePlayerState extends State<VoicePlayer> {
  final _player = AudioPlayer();
  bool _loading = false;
  String? _error;
  bool _ready = false;
  Future<void> _prepare() async {
    if (_ready) return;
    final path = await VoiceAudio.playable(
      widget.localPath?.isNotEmpty == true ? widget.localPath! : widget.source,
      api: widget.api,
      journal: widget.journal,
    );
    if (!mounted) return;
    await _player.setFilePath(path);
    _ready = true;
  }

  Future<void> _seek(double fraction) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _prepare();
      if (!mounted) return;
      final total = _player.duration ?? Duration(seconds: widget.duration);
      await _player.seek(
        Duration(milliseconds: (total.inMilliseconds * fraction).round()),
      );
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not seek. Tap to retry.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _player.dispose();
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
      if (!mounted) return;
      setState(() => _loading = false);
      await _player.play();
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not play. Tap to retry.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
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
                    (_player.duration?.inMilliseconds ?? widget.duration * 1000)
                        .clamp(1, 3600000)
                        .toDouble();
                if (widget.waveform != null) {
                  return VoiceWaveform(
                    samples: widget.waveform!,
                    progress: ((snapshot.data?.inMilliseconds ?? 0) / total)
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
                      ? (value) =>
                            _player.seek(Duration(milliseconds: value.round()))
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
