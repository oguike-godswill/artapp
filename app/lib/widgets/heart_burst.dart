import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../theme.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../widgets.dart';

class FavoriteButton extends StatefulWidget {
  const FavoriteButton({super.key, required this.art, this.glass = true, this.size = 22});
  final Artwork art;
  final bool glass;
  final double size;

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 35),
    TweenSequenceItem(tween: Tween(begin: 1.35, end: 0.9).chain(CurveTween(curve: Curves.easeInCubic)), weight: 30),
    TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 35),
  ]).animate(_anim);

  late final Animation<double> _particles = CurvedAnimation(parent: _anim, curve: Curves.easeOutQuad);

  bool _busy = false;

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_busy) return;
    final prev = widget.art.isFavorite;
    final next = !prev;

    HapticFeedback.lightImpact();
    if (next) {
      _anim.forward(from: 0.0);
    }

    setState(() {
      _busy = true;
      widget.art.isFavorite = next;
    });

    try {
      final d = await context.read<ApiClient>().post('/artworks/${widget.art.id}/favorite');
      if (mounted) {
        setState(() {
          widget.art.isFavorite = d['isFavorite'] == true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => widget.art.isFavorite = prev);
        toast(context, errorText(e));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.art.isFavorite;
    return GestureDetector(
      onTap: _toggle,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Sparkle particles when activated
          CustomPaint(
            size: Size(widget.size * 2.4, widget.size * 2.4),
            painter: _SparklePainter(progress: _particles.value, active: active),
          ),
          // Heart button with scale animation
          ScaleTransition(
            scale: _scale,
            child: CircleBtn(
              icon: active ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: active ? Solis.sun : (widget.glass ? Colors.white : Solis.ink),
              glass: widget.glass,
              onTap: _toggle,
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  _SparklePainter({required this.progress, required this.active});
  final double progress;
  final bool active;

  static const _colors = [Solis.sun, Solis.rust, Color(0xFFF7C244), Solis.teal];

  @override
  void paint(Canvas canvas, Size size) {
    if (!active || progress == 0 || progress >= 1.0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final count = 7;
    final baseRadius = size.width * 0.35;
    final distance = baseRadius + progress * 14;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    for (var i = 0; i < count; i++) {
      final angle = (i * 2 * math.pi / count) - (math.pi / 2);
      final offset = Offset(center.dx + math.cos(angle) * distance, center.dy + math.sin(angle) * distance);
      final p = Paint()
        ..color = _colors[i % _colors.length].withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      final particleRadius = (1.0 - progress * 0.5) * 2.8;
      canvas.drawCircle(offset, particleRadius, p);
    }
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) => oldDelegate.progress != progress;
}
