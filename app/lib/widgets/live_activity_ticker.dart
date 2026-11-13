import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets.dart';

class LiveWatcherPill extends StatefulWidget {
  const LiveWatcherPill({super.key, this.baseCount = 4});
  final int baseCount;

  @override
  State<LiveWatcherPill> createState() => _LiveWatcherPillState();
}

class _LiveWatcherPillState extends State<LiveWatcherPill> {
  late int _count = widget.baseCount;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (mounted) {
        setState(() {
          final delta = math.Random().nextBool() ? 1 : -1;
          _count = (_count + delta).clamp(3, 14);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PulseDot(color: Color(0xFF68D391)),
          const SizedBox(width: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(anim),
                child: child,
              ),
            ),
            child: Text(
              '$_count viewing now',
              key: ValueKey(_count),
              style: Solis.sans(11, color: Colors.white, weight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
