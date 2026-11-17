import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A view of microphone samples, compressed uniformly across the whole clip.
class VoiceWaveform extends StatelessWidget {
  const VoiceWaveform({
    super.key,
    required this.samples,
    this.progress = 0,
    this.recording = false,
    this.onSeek,
  });
  final List<double> samples;
  final double progress;
  final bool recording;
  final ValueChanged<double>? onSeek;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final painting = SizedBox(
      height: 56,
      width: double.infinity,
      child: CustomPaint(
        painter: _WavePainter(
          samples: List.of(samples),
          progress: progress,
          recording: recording,
          color: colors.primary,
          muted: colors.primary.withValues(alpha: .22),
        ),
      ),
    );
    if (onSeek == null) {
      return Semantics(label: 'Live microphone waveform', child: painting);
    }
    return Semantics(
      label: 'Recording position',
      value: '${(progress * 100).round()} percent',
      increasedValue: '${((progress + .05).clamp(0, 1) * 100).round()} percent',
      decreasedValue: '${((progress - .05).clamp(0, 1) * 100).round()} percent',
      slider: true,
      onIncrease: () => onSeek!((progress + .05).clamp(0, 1)),
      onDecrease: () => onSeek!((progress - .05).clamp(0, 1)),
      child: LayoutBuilder(
        builder: (context, bounds) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) =>
              onSeek!((details.localPosition.dx / bounds.maxWidth).clamp(0, 1)),
          onHorizontalDragUpdate: (details) =>
              onSeek!((details.localPosition.dx / bounds.maxWidth).clamp(0, 1)),
          child: painting,
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter({
    required this.samples,
    required this.progress,
    required this.recording,
    required this.color,
    required this.muted,
  });
  final List<double> samples;
  final double progress;
  final bool recording;
  final Color color, muted;
  @override
  void paint(Canvas canvas, Size size) {
    const count = 48;
    final step = size.width / count;
    final width = math.max(1.0, step * .55);
    for (var bar = 0; bar < count; bar++) {
      final start = (bar * samples.length / count).floor();
      final end = ((bar + 1) * samples.length / count).ceil().clamp(
        0,
        samples.length,
      );
      var peak = 0.0;
      for (var i = start; i < end; i++) {
        peak = math.max(peak, samples[i]);
      }
      final height = 3 + peak.clamp(0, 1) * (size.height - 9);
      final paint = Paint()
        ..color = recording || bar / count <= progress ? color : muted;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            bar * step + (step - width) / 2,
            (size.height - height) / 2,
            width,
            height,
          ),
          Radius.circular(width),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => true;
}
