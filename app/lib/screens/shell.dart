import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';
import 'auction_screens.dart';
import 'collection_screen.dart';
import 'discover_screen.dart';
import 'events_screen.dart';
import 'profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  static AppShellState? of(BuildContext context) => context.findAncestorStateOfType<AppShellState>();
  static final ValueNotifier<int> activeTab = ValueNotifier<int>(0);
  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell> {
  int index = 0;
  void go(int i) {
    setState(() => index = i);
    AppShell.activeTab.value = i;
  }

  static const _items = [
    (Icons.account_balance_outlined, 'Discover'),
    (Icons.photo_outlined, 'Collection'),
    (Icons.gavel_rounded, 'Auction'),
    (Icons.calendar_month_outlined, 'Events'),
    (Icons.person_outline_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final dark = index == 2;
    return Scaffold(
      backgroundColor: dark ? Solis.ink : Solis.paper,
      extendBody: true,
      body: IndexedStack(index: index, children: const [
        DiscoverScreen(),
        CollectionScreen(),
        AuctionsScreen(),
        EventsScreen(),
        ProfileScreen(),
      ]),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: (dark ? const Color(0xFF2A241D) : Solis.ink).withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Row(
                children: List.generate(_items.length, (i) {
                  final selected = i == index;
                  final (icon, label) = _items[i];
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => go(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                        decoration: BoxDecoration(
                          color: selected ? Colors.white.withValues(alpha: 0.14) : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(icon, size: 21, color: selected ? Solis.paper : Solis.paper.withValues(alpha: 0.6)),
                          const SizedBox(height: 3),
                          Text(label,
                              style: Solis.sans(10,
                                  color: selected ? Solis.paper : Solis.paper.withValues(alpha: 0.6),
                                  weight: selected ? FontWeight.w600 : FontWeight.w400)),
                        ]),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
