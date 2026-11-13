import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

class CollectorCard3DScreen extends StatefulWidget {
  const CollectorCard3DScreen({super.key, required this.art, this.lotNumber});
  final Artwork art;
  final int? lotNumber;

  @override
  State<CollectorCard3DScreen> createState() => _CollectorCard3DScreenState();
}

class _CollectorCard3DScreenState extends State<CollectorCard3DScreen> with SingleTickerProviderStateMixin {
  double _tiltX = 0.0;
  double _tiltY = 0.0;
  bool _isFlipped = false;
  late final AnimationController _flipCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    HapticFeedback.lightImpact();
    if (_isFlipped) {
      _flipCtrl.reverse();
    } else {
      _flipCtrl.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0D0B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: CircleBtn(
          icon: Icons.close_rounded,
          glass: true,
          onTap: () => Navigator.pop(context),
        ),
        title: Text('3D Collector Card', style: Solis.serif(18, color: Solis.paper)),
        centerTitle: true,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.flip_rounded, size: 18, color: Solis.sunSoft),
            label: Text('Flip', style: Solis.sans(13, color: Solis.sunSoft, weight: FontWeight.w600)),
            onPressed: _toggleFlip,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // 3D Tiltable & Flippable Card
            Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (d) {
                  setState(() {
                    _tiltY = (_tiltY + d.delta.dx * 0.008).clamp(-0.45, 0.45);
                    _tiltX = (_tiltX - d.delta.dy * 0.008).clamp(-0.45, 0.45);
                  });
                },
                onPanEnd: (_) {
                  setState(() {
                    _tiltX = 0.0;
                    _tiltY = 0.0;
                  });
                },
                onTap: _toggleFlip,
                child: AnimatedBuilder(
                  animation: _flipCtrl,
                  builder: (context, _) {
                    final flipAngle = _flipCtrl.value * math.pi;
                    final isBack = flipAngle > math.pi / 2;

                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0015) // Perspective
                        ..rotateX(_tiltX)
                        ..rotateY(_tiltY + flipAngle),
                      child: isBack
                          ? Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(math.pi),
                              child: _buildCardBack(),
                            )
                          : _buildCardFront(),
                    );
                  },
                ),
              ),
            ),
            const Spacer(),
            Text('Drag to tilt in 3D · Tap to flip', style: Solis.sans(12.5, color: Colors.white54)),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: PrimaryButton(
                label: 'Share Collector Story 📸',
                color: Solis.sun,
                textColor: Solis.ink,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  toast(context, '✓ Collector card saved to gallery');
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCardFront() {
    return Container(
      width: 290,
      height: 440,
      decoration: BoxDecoration(
        color: Solis.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Solis.sunSoft, width: 2),
        boxShadow: [
          BoxShadow(
            color: Solis.sun.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: Offset(-_tiltY * 30, _tiltX * 30 + 16),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Card Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('SOLIS COLLECTOR', style: Solis.label(color: Solis.rust).copyWith(letterSpacing: 1.5)),
                      const Spacer(),
                      if (widget.lotNumber != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Solis.ink, borderRadius: BorderRadius.circular(8)),
                          child: Text('LOT ${widget.lotNumber}', style: Solis.sans(10, color: Solis.paper, weight: FontWeight.w700)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Artwork Frame
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Solis.line, width: 1.5),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: ArtImage(widget.art.image),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(widget.art.title, style: Solis.serif(20)),
                  const SizedBox(height: 2),
                  Text(widget.art.artist, style: Solis.sans(12.5, color: Solis.muted)),
                  const SizedBox(height: 12),
                  // Solis Palette Swatches
                  Row(
                    children: [
                      _paletteDot(Solis.paper),
                      _paletteDot(Solis.sun),
                      _paletteDot(Solis.teal),
                      _paletteDot(Solis.rust),
                      _paletteDot(Solis.ink),
                      const Spacer(),
                      Text('EDITION ${widget.art.editionSize ?? 250}', style: Solis.label().copyWith(fontSize: 9)),
                    ],
                  ),
                ],
              ),
            ),

            // Dynamic Holographic Foil Glare Shader Simulation
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1.0 + _tiltY * 3, -1.0 + _tiltX * 3),
                      end: Alignment(1.0 + _tiltY * 3, 1.0 + _tiltX * 3),
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.22),
                        const Color(0xFFFBD38D).withValues(alpha: 0.25),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.45, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      width: 290,
      height: 440,
      decoration: BoxDecoration(
        color: Solis.inkSoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Solis.sunSoft, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('PROVENANCE & CERTIFICATION', style: Solis.label(color: Solis.sunSoft).copyWith(letterSpacing: 1.5)),
              const Spacer(),
              const Icon(Icons.verified_outlined, size: 16, color: Solis.sunSoft),
            ],
          ),
          const SizedBox(height: 16),
          Text(widget.art.title, style: Solis.serif(20, color: Solis.paper)),
          const SizedBox(height: 4),
          Text(widget.art.byline, style: Solis.sans(12, color: Colors.white60)),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Colors.white12, height: 1)),
          if (widget.art.description != null)
            Text(
              widget.art.description!,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: Solis.serif(13.5, color: Colors.white70, height: 1.4),
            ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CURATOR SEAL', style: Solis.label(color: Colors.white54).copyWith(fontSize: 8)),
                    const SizedBox(height: 2),
                    Text('Authentic Museum Lot', style: Solis.sans(11, color: Colors.white, weight: FontWeight.w600)),
                  ],
                ),
                const Spacer(),
                Text('#SLS-${widget.art.id.hashCode.abs().toString().substring(0, 6)}',
                    style: Solis.sans(11, color: Solis.sunSoft, weight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paletteDot(Color color) => Container(
        width: 14,
        height: 14,
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Solis.line)),
      );
}
