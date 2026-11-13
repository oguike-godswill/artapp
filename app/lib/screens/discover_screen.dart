import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import '../widgets/live_activity_ticker.dart';
import 'aesthetic_quiz_screen.dart';
import 'auction_screens.dart';
import 'collection_screen.dart';
import 'museum_map_3d.dart';
import 'shell.dart';

class DiscoverData {
  final Auction? featured;
  final List<Auction> auctions;
  DiscoverData(this.featured, this.auctions);
}

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  bool _scrolled = false;

  Future<DiscoverData> _load(ApiClient api) async {
    final d = await api.get('/discover');
    return DiscoverData(
      d['featured'] == null ? null : Auction.fromJson(d['featured']),
      (d['auctions'] as List).map((e) => Auction.fromJson(e)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiClient>();
    return AsyncView<DiscoverData>(
      load: () => _load(api),
      builder: (context, data, reload) {
        final h = MediaQuery.sizeOf(context).height;
        final f = data.featured;
        Future<void> open(Auction a) async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => AuctionDetailScreen(auctionId: a.id)));
          reload();
        }

        return Stack(
          children: [
            // Scrollable content
            NotificationListener<ScrollNotification>(
              onNotification: (notif) {
                if (notif.metrics.axis == Axis.vertical) {
                  final s = notif.metrics.pixels > 60;
                  if (s != _scrolled) setState(() => _scrolled = s);
                }
                return false;
              },
              child: RefreshIndicator(
                color: Solis.sun,
                onRefresh: reload,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(children: [
                    // ---------- Hero ----------
                    SizedBox(
                      height: h * 0.68,
                      child: Stack(fit: StackFit.expand, children: [
                        if (f != null) ArtImage(f.artwork.image) else Container(color: Solis.sun),
                        const Scrim(from: 0.4, strength: 0.75),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.center,
                              colors: [Colors.black.withValues(alpha: 0.35), Colors.transparent],
                            ),
                          ),
                        ),
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(22, 64, 22, 44),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Spacer(),
                              if (f != null) ...[
                                Row(
                                  children: [
                                    GlassChip(text: 'LIVE AUCTION · ${f.lot}', dot: true),
                                    const Spacer(),
                                    const LiveWatcherPill(baseCount: 7),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Text(f.artwork.title, style: Solis.serif(36, color: Colors.white)),
                                const SizedBox(height: 8),
                                Text(f.artwork.byline, style: Solis.sans(13, color: Colors.white.withValues(alpha: 0.85))),
                                const SizedBox(height: 18),
                                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Ticker(
                                        builder: (_) => Text('CURRENT BID · ENDS IN ${timeLeft(f.endsAt).toUpperCase()}',
                                            style: Solis.label(color: Colors.white.withValues(alpha: 0.85))),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(money(f.currentBid), style: Solis.serif(30, color: Colors.white)),
                                    ]),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Solis.ink,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                      shape: const StadiumBorder(),
                                    ),
                                    onPressed: () => open(f),
                                    child: Text('Place bid', style: Solis.sans(14, weight: FontWeight.w600)),
                                  ),
                                ]),
                              ] else
                                Text('No live auctions right now', style: Solis.serif(30, color: Colors.white)),
                            ]),
                          ),
                        ),
                      ]),
                    ),
                    // ---------- Panel ----------
                    Transform.translate(
                      offset: const Offset(0, -26),
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Solis.paper,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                        ),
                        padding: const EdgeInsets.only(top: 10, bottom: 110),
                        child: Column(children: [
                          Container(width: 40, height: 4, decoration: BoxDecoration(color: Solis.line, borderRadius: BorderRadius.circular(4))),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
                            child: SectionHeader('On auction', action: 'View all', onAction: () => AppShell.of(context)?.go(2)),
                          ),
                          SizedBox(
                            height: 210,
                            child: data.auctions.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 22),
                                    child: EmptyState(icon: Icons.gavel_rounded, text: 'More lots are coming soon.'),
                                  )
                                : ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 22),
                                    itemCount: data.auctions.length,
                                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                                    itemBuilder: (_, i) => AuctionCard(auction: data.auctions[i], onTap: () => open(data.auctions[i])),
                                  ),
                          ),
                          const SizedBox(height: 26),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            child: SectionHeader('Visit the collection', action: 'Browse', onAction: () => AppShell.of(context)?.go(1)),
                          ),
                          const SizedBox(height: 14),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            child: GestureDetector(
                              onTap: () => AppShell.of(context)?.go(3),
                              child: Container(
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(color: Solis.teal, borderRadius: BorderRadius.circular(26)),
                                child: Row(children: [
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('OPEN TODAY · 10:00 – 18:00', style: Solis.label(color: Solis.paper.withValues(alpha: 0.7))),
                                      const SizedBox(height: 8),
                                      Text('See what’s on at Solis this week', style: Solis.serif(22, color: Solis.paper)),
                                    ]),
                                  ),
                                  const SizedBox(width: 12),
                                  const CircleAvatar(
                                    radius: 22,
                                    backgroundColor: Solis.paper,
                                    child: Icon(Icons.arrow_forward, color: Solis.ink, size: 18),
                                  ),
                                ]),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MuseumMap3DScreen())),
                                    child: Container(
                                      padding: const EdgeInsets.all(18),
                                      decoration: BoxDecoration(
                                        color: Solis.ink,
                                        borderRadius: BorderRadius.circular(22),
                                        border: Border.all(color: Colors.white12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: const BoxDecoration(color: Solis.sun, shape: BoxShape.circle),
                                            child: const Icon(Icons.view_in_ar_rounded, size: 16, color: Solis.ink),
                                          ),
                                          const SizedBox(height: 12),
                                          Text('3D Pavilion', style: Solis.serif(18, color: Colors.white)),
                                          const SizedBox(height: 2),
                                          Text('Rotate & explore', style: Solis.sans(11, color: Colors.white60)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AestheticQuizScreen())),
                                    child: Container(
                                      padding: const EdgeInsets.all(18),
                                      decoration: BoxDecoration(
                                        color: Solis.rust,
                                        borderRadius: BorderRadius.circular(22),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                                            child: const Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.white),
                                          ),
                                          const SizedBox(height: 12),
                                          Text('Art Quiz', style: Solis.serif(18, color: Colors.white)),
                                          const SizedBox(height: 2),
                                          Text('Find your match', style: Solis.sans(11, color: Colors.white70)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
            // Sticky top text and icon
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: _scrolled ? 16 : 0, sigmaY: _scrolled ? 16 : 0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: _scrolled ? Solis.paper.withValues(alpha: 0.92) : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: _scrolled ? Solis.line : Colors.transparent,
                          width: 1,
                        ),
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 10, 22, 10),
                        child: Row(children: [
                          Text(
                            'SOLIS',
                            style: Solis.serif(22, color: _scrolled ? Solis.ink : Colors.white).copyWith(letterSpacing: 7),
                          ),
                          const Spacer(),
                          CircleBtn(
                            icon: Icons.search,
                            glass: !_scrolled,
                            color: _scrolled ? Solis.ink : Colors.white,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class AuctionCard extends StatelessWidget {
  const AuctionCard({super.key, required this.auction, required this.onTap, this.width = 150});
  final Auction auction;
  final VoidCallback onTap;
  final double width;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(fit: StackFit.expand, children: [
              ArtImage(auction.artwork.image),
              const Scrim(from: 0.35),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Spacer(),
                  Text(auction.artwork.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Solis.serif(16, color: Colors.white)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Text(money(auction.currentBid), style: Solis.sans(12.5, color: Colors.white, weight: FontWeight.w600)),
                    const Spacer(),
                    Ticker(builder: (_) => Text(timeLeft(auction.endsAt), style: Solis.sans(11, color: Colors.white70))),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
      );
}
