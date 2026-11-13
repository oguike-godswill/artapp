import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets.dart';

class MuseumWing {
  final String id, name, floor, curatorHighlight;
  final IconData icon;
  final Color accent;
  final List<String> featuredWorks;

  const MuseumWing({
    required this.id,
    required this.name,
    required this.floor,
    required this.curatorHighlight,
    required this.icon,
    required this.accent,
    required this.featuredWorks,
  });
}

const _wings = [
  MuseumWing(
    id: 'west_wing',
    name: 'West Wing · Water Series',
    floor: 'Level 1',
    curatorHighlight: 'Elena Marwa’s oil impasto works & reflections',
    icon: Icons.water_drop_outlined,
    accent: Solis.teal,
    featuredWorks: ['Fan Palm Crossing', 'Blue Door Hibiscus', 'Still Water, Koi'],
  ),
  MuseumWing(
    id: 'east_wing',
    name: 'East Wing · Textile & Craft',
    floor: 'Level 2',
    curatorHighlight: 'Bolgatanga basket weaves and golden light studies',
    icon: Icons.texture_rounded,
    accent: Solis.rust,
    featuredWorks: ['Baskets of Bolga', 'Golden Hour Porch', 'Woven Crown'],
  ),
  MuseumWing(
    id: 'atrium',
    name: 'Grand Glass Atrium',
    floor: 'Ground',
    curatorHighlight: 'Central skylight with reflections & live auction room',
    icon: Icons.account_balance_outlined,
    accent: Solis.sun,
    featuredWorks: ['Whispers', 'The Teal Garden'],
  ),
  MuseumWing(
    id: 'sculpture',
    name: 'Outdoor Sculpture Court',
    floor: 'Garden',
    curatorHighlight: 'Open-air cypress trees and terracotta pottery',
    icon: Icons.park_outlined,
    accent: Color(0xFF2E6145),
    featuredWorks: ['The Teal Garden'],
  ),
];

class MuseumMap3DScreen extends StatefulWidget {
  const MuseumMap3DScreen({super.key});

  @override
  State<MuseumMap3DScreen> createState() => _MuseumMap3DScreenState();
}

class _MuseumMap3DScreenState extends State<MuseumMap3DScreen> with SingleTickerProviderStateMixin {
  double _rotX = -0.55;
  double _rotY = 0.65;
  int _selectedWing = 0;

  @override
  Widget build(BuildContext context) {
    final wing = _wings[_selectedWing];

    return Scaffold(
      backgroundColor: Solis.ink,
      appBar: AppBar(
        backgroundColor: Solis.ink,
        elevation: 0,
        leading: CircleBtn(
          icon: Icons.chevron_left,
          glass: true,
          onTap: () => Navigator.pop(context),
        ),
        title: Text('3D Museum Pavilion', style: Solis.serif(20, color: Solis.paper)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Solis.sun.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Solis.sun.withValues(alpha: 0.4)),
                ),
                child: Text('DRAG TO ROTATE', style: Solis.label(color: Solis.sunSoft).copyWith(fontSize: 9)),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 3D Architectural Viewport
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (d) {
                  setState(() {
                    _rotY += d.delta.dx * 0.01;
                    _rotX = (_rotX - d.delta.dy * 0.01).clamp(-1.1, -0.2);
                  });
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ambient radial glow behind the 3D pavilion
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 0.8,
                            colors: [
                              wing.accent.withValues(alpha: 0.22),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // The 3D Projected Isometric Pavilion
                    Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0012) // 3D Perspective
                        ..rotateX(_rotX)
                        ..rotateY(_rotY),
                      child: SizedBox(
                        width: 280,
                        height: 280,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Ground grid plane
                            Container(
                              width: 260,
                              height: 260,
                              decoration: BoxDecoration(
                                color: Solis.inkSoft,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white12, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    blurRadius: 32,
                                    offset: const Offset(0, 24),
                                  ),
                                ],
                              ),
                            ),

                            // Wing 0: West Wing
                            _BuildingBlock(
                              top: 25,
                              left: 25,
                              width: 100,
                              height: 95,
                              depth: 55,
                              label: 'West Wing',
                              sub: 'Water Series',
                              color: Solis.teal,
                              isSelected: _selectedWing == 0,
                              onTap: () => setState(() => _selectedWing = 0),
                            ),

                            // Wing 1: East Wing
                            _BuildingBlock(
                              top: 25,
                              right: 25,
                              width: 100,
                              height: 95,
                              depth: 70,
                              label: 'East Wing',
                              sub: 'Textile Hall',
                              color: Solis.rust,
                              isSelected: _selectedWing == 1,
                              onTap: () => setState(() => _selectedWing = 1),
                            ),

                            // Wing 2: Central Grand Atrium (Glass Dome)
                            _BuildingBlock(
                              bottom: 30,
                              left: 35,
                              width: 110,
                              height: 105,
                              depth: 85,
                              label: 'Atrium',
                              sub: 'Live Lot Hall',
                              color: Solis.sun,
                              isSelected: _selectedWing == 2,
                              onTap: () => setState(() => _selectedWing = 2),
                            ),

                            // Wing 3: Sculpture Court
                            _BuildingBlock(
                              bottom: 30,
                              right: 35,
                              width: 90,
                              height: 90,
                              depth: 35,
                              label: 'Courtyard',
                              sub: 'Garden',
                              color: const Color(0xFF2E6145),
                              isSelected: _selectedWing == 3,
                              onTap: () => setState(() => _selectedWing = 3),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Reset 3D angle button
                    Positioned(
                      bottom: 14,
                      right: 20,
                      child: CircleBtn(
                        icon: Icons.crop_rotate_rounded,
                        glass: true,
                        onTap: () {
                          setState(() {
                            _rotX = -0.55;
                            _rotY = 0.65;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Wing Info Card
            Container(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
              decoration: BoxDecoration(
                color: Solis.inkSoft,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: wing.accent, shape: BoxShape.circle),
                        child: Icon(wing.icon, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(wing.name, style: Solis.serif(20, color: Colors.white)),
                            const SizedBox(height: 2),
                            Text(wing.floor, style: Solis.sans(12, color: Colors.white60)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(wing.curatorHighlight, style: Solis.sans(13.5, color: Colors.white70)),
                  const SizedBox(height: 16),
                  Text('FEATURED WORKS ON VIEW', style: Solis.label(color: Colors.white54)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: wing.featuredWorks.map((title) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.palette_outlined, size: 13, color: Solis.sunSoft),
                            const SizedBox(width: 6),
                            Text(title, style: Solis.sans(12, color: Colors.white)),
                          ],
                        ),
                      );
                    }).toList(),
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

class _BuildingBlock extends StatelessWidget {
  const _BuildingBlock({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.width,
    required this.height,
    required this.depth,
    required this.label,
    required this.sub,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final double? top, bottom, left, right;
  final double width, height, depth;
  final String label, sub;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: isSelected ? 0.95 : 0.65),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? Colors.white : color.withValues(alpha: 0.5),
              width: isSelected ? 2.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isSelected ? 0.45 : 0.2),
                blurRadius: isSelected ? 18 : 6,
                offset: Offset(0, isSelected ? 10 : 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: Solis.serif(12, color: Colors.white, weight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                textAlign: TextAlign.center,
                style: Solis.sans(9.5, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
