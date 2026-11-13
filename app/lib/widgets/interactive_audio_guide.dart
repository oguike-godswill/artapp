import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models.dart';
import '../services/audio_service.dart';
import '../theme.dart';
import '../widgets.dart';

class InteractiveAudioGuide extends StatefulWidget {
  const InteractiveAudioGuide({super.key, required this.art});
  final Artwork art;

  @override
  State<InteractiveAudioGuide> createState() => _InteractiveAudioGuideState();
}

class _InteractiveAudioGuideState extends State<InteractiveAudioGuide> with SingleTickerProviderStateMixin {
  late final SolisAudioService _audio = SolisAudioService();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = const Duration(seconds: 35);
  StreamSubscription? _posSub;
  StreamSubscription? _stateSub;

  late final AnimationController _waveAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  void _initAudio() {
    _posSub = _audio.onPositionChanged.listen((p) {
      if (mounted) {
        setState(() {
          _position = p;
          if (_audio.duration > Duration.zero) {
            _duration = _audio.duration;
          }
        });
      }
    });

    _stateSub = _audio.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _isPlaying = s);
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _stateSub?.cancel();
    _audio.dispose();
    _waveAnim.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    final audioUrl = AppConfig.asset('/art/guide.wav');
    try {
      if (_isPlaying) {
        await _audio.pause();
      } else {
        await _audio.play(audioUrl);
      }
    } catch (e) {
      if (mounted) {
        toast(context, 'Audio note: Playing preview');
      }
    }
  }

  Future<void> _seekTo(double frac) async {
    await _audio.seek(frac);
  }

  String _format(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final durMs = _duration.inMilliseconds;
    final posMs = _position.inMilliseconds;
    final progress = durMs > 0 ? (posMs / durMs).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Solis.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Solis.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _isPlaying ? Solis.sun : Solis.ink,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isPlaying ? Solis.sun : Solis.ink).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: _isPlaying ? Solis.ink : Solis.paper,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('AUDIO GUIDE · ${_format(_duration)}', style: Solis.label(color: Solis.sun)),
                        const Spacer(),
                        Text('${_format(_position)} / ${_format(_duration)}', style: Solis.sans(11, color: Solis.muted)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Curator Notes on "${widget.art.title}"',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Solis.serif(15),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Animated Waveform Equalizer with tap & drag seek
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) {
              final box = context.findRenderObject() as RenderBox?;
              if (box != null) {
                final frac = (d.localPosition.dx / box.size.width).clamp(0.0, 1.0);
                _seekTo(frac);
              }
            },
            onHorizontalDragUpdate: (d) {
              final box = context.findRenderObject() as RenderBox?;
              if (box != null) {
                final frac = (d.localPosition.dx / box.size.width).clamp(0.0, 1.0);
                _seekTo(frac);
              }
            },
            child: SizedBox(
              height: 34,
              child: AnimatedBuilder(
                animation: _waveAnim,
                builder: (context, _) => CustomPaint(
                  size: const Size(double.infinity, 34),
                  painter: _WaveformPainter(
                    isPlaying: _isPlaying,
                    progress: progress,
                    phase: _waveAnim.value * 2 * math.pi,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('Narrated by Dr. Zawadi M.', style: Solis.sans(11, color: Solis.muted)),
              const Spacer(),
              GestureDetector(
                onTap: () => _showTranscript(context),
                child: Row(
                  children: [
                    Text('Transcript', style: Solis.sans(11.5, color: Solis.teal, weight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    const Icon(Icons.notes_rounded, size: 14, color: Solis.teal),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTranscript(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Solis.paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Solis.line, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 18),
              Text('Curator Commentary', style: Solis.serif(24)),
              const SizedBox(height: 4),
              Text('Spoken for "${widget.art.title}" by ${widget.art.artist}', style: Solis.sans(12.5, color: Solis.muted)),
              const SizedBox(height: 16),
              Text(
                widget.art.description ??
                    'This work investigates the interplay between light and organic form. The artist employs thick layers of paint to catch daylight as the viewer moves around the gallery.',
                style: Solis.serif(15.5, height: 1.55),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Close transcript',
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({required this.isPlaying, required this.progress, required this.phase});
  final bool isPlaying;
  final double progress;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    const barCount = 38;
    final barWidth = size.width / (barCount * 1.5);
    final gap = barWidth * 0.5;

    for (var i = 0; i < barCount; i++) {
      final frac = i / barCount;
      final x = i * (barWidth + gap);

      final base = 0.28 + 0.62 * math.sin(i * 0.45).abs();
      final wave = isPlaying ? math.sin(phase + i * 0.35) * 0.28 : 0.0;
      final h = ((base + wave).clamp(0.12, 1.0) * size.height);
      final y = (size.height - h) / 2;

      final isPlayed = frac <= progress;
      final paint = Paint()
        ..color = isPlayed ? Solis.sun : Solis.line
        ..strokeCap = StrokeCap.round
        ..strokeWidth = barWidth;

      canvas.drawLine(Offset(x, y), Offset(x, y + h), paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.isPlaying != isPlaying || old.progress != progress || old.phase != phase;
}
