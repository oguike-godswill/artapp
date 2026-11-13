import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../api.dart';
import '../auth.dart';
import '../models.dart';
import '../services/realtime_service.dart';
import '../theme.dart';
import '../widgets.dart';
import '../widgets/bidder_paddle_dialog.dart';
import '../widgets/heart_burst.dart';
import '../widgets/live_activity_ticker.dart';
import 'collection_screen.dart';
import 'collector_card_3d.dart';
import 'room_preview_sheet.dart';
import 'zoom_viewer.dart';

class AuctionsScreen extends StatelessWidget {
  const AuctionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiClient>();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: Solis.ink,
        child: SafeArea(
          bottom: false,
          child: AsyncView<List<Auction>>(
            load: () async {
              final d = await api.get('/auctions');
              return (d['auctions'] as List).map((e) => Auction.fromJson(e)).toList();
            },
            builder: (context, list, reload) {
              final live = list.where((a) => a.isLive).toList();
              final ended = list.where((a) => !a.isLive).toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sticky top header
                  Container(
                    color: Solis.ink,
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Auction', style: Solis.serif(34, color: Solis.paper)),
                        const SizedBox(height: 4),
                        Text('${live.length} lots open for bidding', style: Solis.sans(14, color: Colors.white60)),
                      ],
                    ),
                  ),
                  Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                  Expanded(
                    child: RefreshIndicator(
                      color: Solis.sun,
                      onRefresh: reload,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                        children: [
                          for (final a in live) ...[_LotRow(a: a, reload: reload), const SizedBox(height: 14)],
                          if (ended.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text('CLOSED', style: Solis.label(color: Colors.white54)),
                            const SizedBox(height: 12),
                            for (final a in ended) ...[_LotRow(a: a, reload: reload), const SizedBox(height: 14)],
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LotRow extends StatelessWidget {
  const _LotRow({required this.a, required this.reload});
  final Auction a;
  final Future<void> Function() reload;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => AuctionDetailScreen(auctionId: a.id)));
          reload();
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Solis.inkSoft,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(children: [
            SizedBox(width: 84, height: 104, child: ArtImage(a.artwork.image, radius: 16)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  if (a.isLive) ...[const PulseDot(), const SizedBox(width: 6)],
                  Text('${a.lot}${a.isLive ? ' · LIVE' : ' · CLOSED'}', style: Solis.label(color: Colors.white60)),
                ]),
                const SizedBox(height: 8),
                Text(a.artwork.title, style: Solis.serif(18, color: Solis.paper)),
                const SizedBox(height: 2),
                Text(a.artwork.artist, style: Solis.sans(12, color: Colors.white54)),
                const SizedBox(height: 10),
                Row(children: [
                  Text(money(a.currentBid), style: Solis.serif(20, color: Solis.sunSoft)),
                  const SizedBox(width: 8),
                  if (a.isLeading)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Solis.teal, borderRadius: BorderRadius.circular(10)),
                      child: Text('Leading', style: Solis.sans(10, color: Colors.white, weight: FontWeight.w600)),
                    ),
                  const Spacer(),
                  Ticker(builder: (_) => Text(timeLeft(a.endsAt), style: Solis.sans(11.5, color: Colors.white60))),
                ]),
              ]),
            ),
          ]),
        ),
      );
}

// ---------------- Lot detail ----------------

class AuctionDetailScreen extends StatefulWidget {
  const AuctionDetailScreen({super.key, required this.auctionId});
  final String auctionId;
  @override
  State<AuctionDetailScreen> createState() => _AuctionDetailScreenState();
}

class _AuctionDetailScreenState extends State<AuctionDetailScreen> {
  Auction? _a;
  List<BidEntry> _bids = [];
  Object? _error;
  int _increment = 100;
  bool _placing = false;
  StreamSubscription? _rtSub;

  @override
  void initState() {
    super.initState();
    _load();
    final rt = RealtimeService();
    rt.connect();
    rt.subscribeAuction(widget.auctionId);
    _rtSub = rt.onBid.listen((ev) {
      if (ev.auctionId == widget.auctionId && mounted) {
        _load();
        toast(context, '⚡ Live Bid: ${money(ev.currentBid)} by ${ev.bidder}');
      }
    });
  }

  @override
  void dispose() {
    _rtSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final d = await context.read<ApiClient>().get('/auctions/${widget.auctionId}');
      if (!mounted) return;
      setState(() {
        _a = Auction.fromJson(d['auction']);
        _bids = (d['bids'] as List).map((e) => BidEntry.fromJson(e)).toList();
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _placeBid() async {
    final a = _a!;
    final amount = a.currentBid + _increment;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Solis.paper,
        title: Text('Confirm your bid', style: Solis.serif(22)),
        content: Text('You’re bidding ${money(amount)} on “${a.artwork.title}”. Bids are binding.', style: Solis.sans(14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Solis.ink),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Bid ${money(amount)}'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _placing = true);
    try {
      await context.read<ApiClient>().post('/auctions/${a.id}/bids', {'amount': amount});
      HapticFeedback.mediumImpact();
      if (mounted) toast(context, 'You’re the highest bidder at ${money(amount)}');
    } catch (e) {
      if (mounted) toast(context, errorText(e));
    } finally {
      await _load();
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = _a;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Solis.ink,
        body: a == null
            ? Center(
                child: _error == null
                    ? const CircularProgressIndicator(color: Solis.sun, strokeWidth: 2.4)
                    : Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(errorText(_error!), style: Solis.sans(14, color: Colors.white70)),
                        const SizedBox(height: 12),
                        OutlinedButton(onPressed: _load, child: const Text('Try again')),
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back')),
                      ]),
              )
            : RefreshIndicator(
                color: Solis.sun,
                onRefresh: _load,
                child: _content(a),
              ),
      ),
    );
  }

  Widget _content(Auction a) {
    final h = MediaQuery.sizeOf(context).height;
    return ListView(padding: EdgeInsets.zero, children: [
      SizedBox(
        height: h * 0.5,
        child: Stack(fit: StackFit.expand, children: [
          ArtImage(a.artwork.image),
          const Scrim(from: 0.55, strength: 0.9),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  CircleBtn(icon: Icons.chevron_left, glass: true, onTap: () => Navigator.pop(context)),
                  const Spacer(),
                  const LiveWatcherPill(baseCount: 6),
                  const SizedBox(width: 8),
                  CircleBtn(
                    icon: Icons.zoom_in_rounded,
                    glass: true,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArtworkZoomViewer(art: a.artwork))),
                  ),
                  const SizedBox(width: 8),
                  FavoriteButton(art: a.artwork),
                ]),
                const Spacer(),
                Row(
                  children: [
                    GlassChip(text: '${a.lot} · ${a.isLive ? 'LIVE' : 'CLOSED'}', dot: a.isLive),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CollectorCard3DScreen(art: a.artwork, lotNumber: a.lotNumber)),
                      ),
                      child: const GlassChip(text: '3D CARD 🎴', dot: false),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RoomPreviewSheet(art: a.artwork))),
                      child: const GlassChip(text: 'ROOM 🖼', dot: false),
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ]),
      ),
      Transform.translate(
        offset: const Offset(0, -8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            decoration: BoxDecoration(
              color: Solis.inkSoft,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.artwork.title, style: Solis.serif(28, color: Solis.paper)),
              const SizedBox(height: 6),
              Text([a.artwork.byline, a.artwork.dimensions].whereType<String>().join(' · '),
                  style: Solis.sans(12.5, color: Colors.white54)),
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.white12, height: 1)),
              Row(children: [
                Text('CURRENT BID · ${a.bidCount} BIDS', style: Solis.label(color: Colors.white54)),
                const Spacer(),
                Ticker(
                  builder: (_) => Text(a.isLive ? 'ENDS IN ${timeLeft(a.endsAt).toUpperCase()}' : 'AUCTION CLOSED',
                      style: Solis.label(color: Colors.white)),
                ),
              ]),
              const SizedBox(height: 6),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(money(a.currentBid), style: Solis.serif(42, color: Solis.sunSoft)),
                const SizedBox(width: 10),
                if (a.isLeading)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Solis.teal, borderRadius: BorderRadius.circular(12)),
                      child: Text('You’re leading', style: Solis.sans(11, color: Colors.white, weight: FontWeight.w600)),
                    ),
                  ),
              ]),
              const SizedBox(height: 14),
              Ticker(
                builder: (_) => ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: a.progress,
                    minHeight: 4,
                    color: Solis.sunSoft,
                    backgroundColor: Colors.white12,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (a.isLive) ...[
                Row(children: [
                  for (final inc in const [100, 250, 500]) ...[
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _increment = inc),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _increment == inc ? Solis.paper : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: _increment == inc ? Solis.paper : Colors.white24),
                          ),
                          child: Text('+${money(inc)}',
                              style: Solis.sans(13.5, color: _increment == inc ? Solis.ink : Solis.paper, weight: FontWeight.w600)),
                        ),
                      ),
                    ),
                    if (inc != 500) const SizedBox(width: 10),
                  ],
                ]),
                const SizedBox(height: 14),
                PrimaryButton(
                  label: 'Place bid · ${money(a.currentBid + _increment)}',
                  color: Solis.sunSoft,
                  textColor: Solis.ink,
                  loading: _placing,
                  onPressed: _placeBid,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Solis.paper,
                          side: const BorderSide(color: Colors.white24),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(Icons.gavel_rounded, size: 16, color: Solis.sunSoft),
                        label: Text('My Paddle #', style: Solis.sans(12, color: Colors.white, weight: FontWeight.w600)),
                        onPressed: () {
                          final user = context.read<AuthController>().user;
                          showBidderPaddle(context, user?.name ?? '', user?.id ?? '');
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Solis.paper,
                          side: const BorderSide(color: Colors.white24),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(Icons.verified_outlined, size: 16, color: Solis.sunSoft),
                        label: Text('View COA 📜', style: Solis.sans(12, color: Colors.white, weight: FontWeight.w600)),
                        onPressed: () => showCertificateOfAuthenticity(context, a.artwork),
                      ),
                    ),
                  ],
                ),
              ] else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(18)),
                  child: Text(a.isLeading ? 'You won this lot. We’ll be in touch.' : 'Bidding for this lot has closed.',
                      style: Solis.sans(14, color: Colors.white70)),
                ),
              const SizedBox(height: 16),
              Row(children: [
                Text('Edition of ${a.artwork.editionSize ?? '—'} prints', style: Solis.sans(12, color: Colors.white54)),
                const Spacer(),
                if (a.artwork.printPrice != null)
                  GestureDetector(
                    onTap: () => showPrintSheet(context, a.artwork),
                    child: Row(children: [
                      Text('Buy print · ${money(a.artwork.printPrice!)}', style: Solis.sans(12.5, color: Solis.paper, weight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward, size: 14, color: Solis.paper),
                    ]),
                  ),
              ]),
            ]),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Bid history', style: Solis.serif(20, color: Solis.paper)),
          const SizedBox(height: 12),
          if (_bids.isEmpty)
            Text('No bids yet — opening bid ${money(a.startingBid)}.', style: Solis.sans(13.5, color: Colors.white54)),
          for (final b in _bids)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: b.isMine ? Solis.sun : Colors.white12,
                  child: Text(b.bidder[0].toUpperCase(), style: Solis.sans(12, color: b.isMine ? Solis.ink : Colors.white)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(b.isMine ? 'You' : b.bidder, style: Solis.sans(14, color: Solis.paper))),
                Text(money(b.amount), style: Solis.sans(14, color: Solis.paper, weight: FontWeight.w600)),
              ]),
            ),
          if (a.artwork.description != null) ...[
            const SizedBox(height: 20),
            Text('About the work', style: Solis.serif(20, color: Solis.paper)),
            const SizedBox(height: 8),
            Text(a.artwork.description!, style: Solis.sans(14, color: Colors.white70).copyWith(height: 1.5)),
          ],
        ]),
      ),
    ]);
  }
}
