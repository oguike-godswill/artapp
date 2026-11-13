import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

class ArtworkZoomViewer extends StatefulWidget {
  const ArtworkZoomViewer({super.key, required this.art});
  final Artwork art;

  @override
  State<ArtworkZoomViewer> createState() => _ArtworkZoomViewerState();
}

class _ArtworkZoomViewerState extends State<ArtworkZoomViewer> {
  final TransformationController _ctrl = TransformationController();
  TapDownDetails? _doubleTapDetails;
  bool _showControls = true;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (_ctrl.value != Matrix4.identity()) {
      _ctrl.value = Matrix4.identity();
    } else if (_doubleTapDetails != null) {
      final pos = _doubleTapDetails!.localPosition;
      _ctrl.value = Matrix4.identity()
        // ignore: deprecated_member_use
        ..translate(-pos.dx * 1.5, -pos.dy * 1.5)
        // ignore: deprecated_member_use
        ..scale(2.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0C0A09),
        body: GestureDetector(
          onTap: () => setState(() => _showControls = !_showControls),
          onDoubleTapDown: (d) => _doubleTapDetails = d,
          onDoubleTap: _handleDoubleTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Zoomable and pannable image
              Center(
                child: InteractiveViewer(
                  transformationController: _ctrl,
                  minScale: 0.9,
                  maxScale: 5.0,
                  panEnabled: true,
                  scaleEnabled: true,
                  child: Hero(
                    tag: 'art-zoom-${widget.art.id}',
                    child: ArtImage(widget.art.image, fit: BoxFit.contain),
                  ),
                ),
              ),

              // Animated Top Bar (Back button + pinch hint)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                top: _showControls ? 0 : -80,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        CircleBtn(
                          icon: Icons.close_rounded,
                          glass: true,
                          onTap: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white70),
                              const SizedBox(width: 6),
                              Text('Double-tap or pinch to inspect', style: Solis.sans(11, color: Colors.white70)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Animated Bottom info panel
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                bottom: _showControls ? 0 : -100,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.art.title, style: Solis.serif(18, color: Colors.white)),
                                const SizedBox(height: 2),
                                Text(
                                  [widget.art.artist, widget.art.medium, widget.art.dimensions].whereType<String>().join(' · '),
                                  style: Solis.sans(12, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          if (widget.art.year != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Solis.sun.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('${widget.art.year}', style: Solis.sans(12, color: Solis.sunSoft, weight: FontWeight.w600)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
