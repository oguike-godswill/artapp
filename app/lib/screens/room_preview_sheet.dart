import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

class RoomPreviewSheet extends StatefulWidget {
  const RoomPreviewSheet({super.key, required this.art});
  final Artwork art;

  @override
  State<RoomPreviewSheet> createState() => _RoomPreviewSheetState();
}

class _RoomPreviewSheetState extends State<RoomPreviewSheet> {
  int _wallColorIndex = 0;
  int _frameIndex = 0;

  static const _wallColors = [
    ('Alabaster', Color(0xFFF1EBE1), true),
    ('Terracotta', Color(0xFF8C3E26), false),
    ('Teal Velvet', Color(0xFF133635), false),
    ('Midnight', Color(0xFF191B21), false),
  ];

  static const _frames = [
    ('Natural Oak', Color(0xFFC7986B), Color(0xFF9E6E41), 10.0),
    ('Matte Black', Color(0xFF161514), Color(0xFF2C2A29), 8.0),
    ('Brushed Brass', Color(0xFFD4AF37), Color(0xFFAA820A), 6.0),
    ('Frameless', Colors.transparent, Colors.transparent, 0.0),
  ];

  @override
  Widget build(BuildContext context) {
    final (_, wallColor, isLightWall) = _wallColors[_wallColorIndex];
    final (frameName, frameColor, innerBorder, frameWidth) = _frames[_frameIndex];

    return Scaffold(
      backgroundColor: Solis.ink,
      appBar: AppBar(
        backgroundColor: Solis.ink,
        elevation: 0,
        leading: CircleBtn(
          icon: Icons.close_rounded,
          glass: true,
          onTap: () => Navigator.pop(context),
        ),
        title: Text('View in Room', style: Solis.serif(20, color: Solis.paper)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Interactive 3D Room Environment
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: wallColor,
                  borderRadius: BorderRadius.circular(28),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ceiling spotlight beam gradient
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: const Alignment(0, -0.65),
                              radius: 1.1,
                              colors: [
                                Colors.white.withValues(alpha: isLightWall ? 0.35 : 0.18),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Crown molding line
                      Positioned(
                        top: 14,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 3,
                          color: (isLightWall ? Colors.black : Colors.white).withValues(alpha: 0.08),
                        ),
                      ),

                      // The Framed Artwork hanging on the wall
                      Positioned(
                        top: 70,
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 175,
                              height: 225,
                              decoration: BoxDecoration(
                                color: frameWidth > 0 ? Colors.white : Colors.transparent,
                                border: frameWidth > 0
                                    ? Border.all(color: frameColor, width: frameWidth)
                                    : null,
                                borderRadius: BorderRadius.circular(frameWidth > 0 ? 3 : 8),
                                boxShadow: [
                                  // Wall cast shadow
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.38),
                                    blurRadius: 28,
                                    spreadRadius: -4,
                                    offset: const Offset(0, 18),
                                  ),
                                  if (frameWidth > 0)
                                    BoxShadow(
                                      color: innerBorder.withValues(alpha: 0.4),
                                      blurRadius: 2,
                                      offset: const Offset(1, 1),
                                    ),
                                ],
                              ),
                              padding: EdgeInsets.all(frameWidth > 0 ? 10 : 0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  boxShadow: frameWidth > 0
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.2),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          )
                                        ]
                                      : null,
                                ),
                                child: ArtImage(widget.art.image),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isLightWall ? Colors.black : Colors.white).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.art.dimensions ?? 'Scale: ~70 × 50 cm',
                                style: Solis.sans(11, color: isLightWall ? Solis.ink : Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Floor baseboard and parquet floor
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 95,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFF4A3423).withValues(alpha: 0.85),
                                const Color(0xFF2C1D13),
                              ],
                            ),
                            border: Border(
                              top: BorderSide(
                                color: const Color(0xFFF1E7DD).withValues(alpha: 0.6),
                                width: 5,
                              ),
                            ),
                          ),
                          child: Center(
                            // Modern minimalist credenza / console table on the floor
                            child: Transform.translate(
                              offset: const Offset(0, -18),
                              child: Container(
                                width: 230,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1713),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Container(width: 8, height: 16, color: Solis.sunSoft.withValues(alpha: 0.6)),
                                    Container(width: 8, height: 16, color: Solis.sunSoft.withValues(alpha: 0.6)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Controls Panel: Wall Color + Frame Material
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              color: Solis.ink,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('WALL COLOUR', style: Solis.label(color: Colors.white60)),
                      const Spacer(),
                      Text(_wallColors[_wallColorIndex].$1, style: Solis.sans(12, color: Solis.sunSoft)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(_wallColors.length, (i) {
                      final (name, col, _) = _wallColors[i];
                      final sel = i == _wallColorIndex;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _wallColorIndex = i),
                          child: Container(
                            height: 38,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: col,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: sel ? Solis.sun : Colors.white24,
                                width: sel ? 2.5 : 1,
                              ),
                            ),
                            child: sel
                                ? Center(
                                    child: Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: i == 0 ? Solis.ink : Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text('FRAME STYLE', style: Solis.label(color: Colors.white60)),
                      const Spacer(),
                      Text(frameName, style: Solis.sans(12, color: Solis.sunSoft)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(_frames.length, (i) {
                      final (name, col, _, _) = _frames[i];
                      final sel = i == _frameIndex;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _frameIndex = i),
                          child: Container(
                            height: 38,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: i == 3 ? Colors.white10 : col,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: sel ? Solis.sun : Colors.white24,
                                width: sel ? 2.5 : 1,
                              ),
                            ),
                            child: sel
                                ? Center(
                                    child: Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: i == 2 ? Solis.ink : Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
