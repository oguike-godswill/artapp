import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import '../widgets/bidder_paddle_dialog.dart';
import '../widgets/heart_burst.dart';
import '../widgets/interactive_audio_guide.dart';
import 'auction_screens.dart';
import 'collector_card_3d.dart';
import 'room_preview_sheet.dart';
import 'zoom_viewer.dart';

class CollectionData {
  final List<Artwork> artworks;
  final Exhibition? exhibition;
  final Auction? liveAuction;
  final Series? series;
  CollectionData(this.artworks, this.exhibition, this.liveAuction, this.series);

  static Future<CollectionData> load(ApiClient api, {bool favorites = false, String? q}) async {
    final params = <String>[if (favorites) 'favorites=true', if (q != null && q.isNotEmpty) 'q=${Uri.encodeQueryComponent(q)}'];
    final d = await api.get('/collection${params.isEmpty ? '' : '?${params.join('&')}'}');
    return CollectionData(
      (d['artworks'] as List).map((e) => Artwork.fromJson(e)).toList(),
      d['exhibition'] == null ? null : Exhibition.fromJson(d['exhibition']),
      d['liveAuction'] == null ? null : Auction.fromJson(d['liveAuction']),
      d['series'] == null ? null : Series.fromJson(d['series']),
    );
  }
}

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});
  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  bool _favorites = false;
  Key _k = UniqueKey();

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiClient>();
    return SafeArea(
      bottom: false,
      child: Column(children: [
        // Sticky top bar: category/filter dropdown and search icon
        Container(
          color: Solis.paper,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(children: [
            PopupMenuButton<bool>(
              onSelected: (v) => setState(() {
                _favorites = v;
                _k = UniqueKey();
              }),
              color: Solis.card,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              itemBuilder: (_) => const [
                PopupMenuItem(value: false, child: Text('All works')),
                PopupMenuItem(value: true, child: Text('Saved works')),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(color: Solis.card, borderRadius: BorderRadius.circular(30), border: Border.all(color: Solis.line)),
                child: Row(children: [
                  const Icon(Icons.tune_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(_favorites ? 'Saved works' : 'All works', style: Solis.sans(14, weight: FontWeight.w500)),
                  const SizedBox(width: 6),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                ]),
              ),
            ),
            const Spacer(),
            CircleBtn(icon: Icons.search, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()))),
          ]),
        ),
        const Divider(color: Solis.line, height: 1),
        Expanded(
          child: AsyncView<CollectionData>(
            key: _k,
            load: () => CollectionData.load(api, favorites: _favorites),
            builder: (context, d, reload) => RefreshIndicator(
              color: Solis.sun,
              onRefresh: reload,
              child: _favorites ? _grid(context, d, reload) : _bento(context, d, reload),
            ),
          ),
        ),
      ]),
    );
  }

  Future<void> _openArt(BuildContext context, Artwork a, Future<void> Function() reload) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ArtworkScreen(artworkId: a.id)));
    reload();
  }

  Widget _grid(BuildContext context, CollectionData d, Future<void> Function() reload) {
    if (d.artworks.isEmpty) {
      return ListView(padding: const EdgeInsets.all(20), children: const [
        EmptyState(icon: Icons.favorite_border, text: 'You haven’t saved any works yet. Tap the heart on a work to keep it here.'),
      ]);
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.78),
      itemCount: d.artworks.length,
      itemBuilder: (_, i) => _ArtTile(art: d.artworks[i], onTap: () => _openArt(context, d.artworks[i], reload)),
    );
  }

  /// Bento layout matching the design: two columns of mixed cards.
  Widget _bento(BuildContext context, CollectionData d, Future<void> Function() reload) {
    final arts = d.artworks;
    final left = <Widget>[];
    final right = <Widget>[];
    const gap = SizedBox(height: 12);

    if (d.series != null) left.addAll([_SeriesStack(series: d.series!), gap]);
    left.addAll([const _CuratorNote(), gap]);
    if (d.exhibition != null) right.addAll([_ExhibitionCard(ex: d.exhibition!), gap]);
    if (d.liveAuction != null) {
      right.addAll([
        _LiveLotCard(
          a: d.liveAuction!,
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => AuctionDetailScreen(auctionId: d.liveAuction!.id)));
            reload();
          },
        ),
        gap,
      ]);
    }
    for (var i = 0; i < arts.length; i++) {
      final tile = SizedBox(
        height: i % 3 == 0 ? 200 : 150,
        child: _ArtTile(art: arts[i], onTap: () => _openArt(context, arts[i], reload)),
      );
      // place into the shorter column (rough heuristic by count)
      ((left.length <= right.length) ? left : right).addAll([tile, gap]);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(children: left)),
          const SizedBox(width: 12),
          Expanded(child: Column(children: right)),
        ]),
      ],
    );
  }
}

class _ArtTile extends StatelessWidget {
  const _ArtTile({required this.art, required this.onTap});
  final Artwork art;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(fit: StackFit.expand, children: [
            Hero(tag: 'art-${art.id}', child: ArtImage(art.image)),
            const Scrim(from: 0.45),
            if (art.isFavorite)
              const Positioned(top: 10, right: 10, child: Icon(Icons.favorite, color: Colors.white, size: 18)),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(art.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Solis.serif(15, color: Colors.white)),
                if (art.printPrice != null)
                  Text('Print ${money(art.printPrice!)}', style: Solis.sans(11, color: Colors.white70)),
              ]),
            ),
          ]),
        ),
      );
}

class _SeriesStack extends StatelessWidget {
  const _SeriesStack({required this.series});
  final Series series;
  @override
  Widget build(BuildContext context) {
    final imgs = series.images;
    return SizedBox(
      height: 170,
      child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
        for (var i = 0; i < imgs.length; i++)
          Transform.rotate(
            angle: (i - (imgs.length - 1) / 2) * 0.14,
            child: Transform.translate(
              offset: Offset((i - (imgs.length - 1) / 2) * 22, 0),
              child: Container(
                width: 92,
                height: 128,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: ArtImage(imgs[math.min(i, imgs.length - 1)], radius: 9),
              ),
            ),
          ),
        Positioned(
          bottom: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Solis.ink, borderRadius: BorderRadius.circular(20)),
            child: Text('${series.name} · ${series.count} works', style: Solis.sans(11, color: Colors.white, weight: FontWeight.w500)),
          ),
        ),
      ]),
    );
  }
}

class _CuratorNote extends StatelessWidget {
  const _CuratorNote();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Solis.card, borderRadius: BorderRadius.circular(22), border: Border.all(color: Solis.line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(color: Solis.sun, shape: BoxShape.circle),
              child: const Icon(Icons.brush_outlined, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text('Curator', style: Solis.sans(13, weight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          Text('Every piece here began as a story told by hand.', style: Solis.serif(16, height: 1.25)),
          const SizedBox(height: 10),
          Text('From the Solis curatorial team', style: Solis.sans(11, color: Solis.muted)),
        ]),
      );
}

class _ExhibitionCard extends StatelessWidget {
  const _ExhibitionCard({required this.ex});
  final Exhibition ex;
  @override
  Widget build(BuildContext context) => Container(
        height: 170,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Solis.rust, borderRadius: BorderRadius.circular(22)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
              child: Center(child: Container(width: 9, height: 9, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))),
            ),
            const SizedBox(width: 8),
            Text('Now showing', style: Solis.sans(12, color: Colors.white, weight: FontWeight.w600)),
          ]),
          const Spacer(),
          Text(ex.title, style: Solis.serif(20, color: Colors.white, height: 1.15)),
          const SizedBox(height: 10),
          Text('${ex.workCount} works${ex.gallery != null ? ' · ${ex.gallery}' : ''}', style: Solis.sans(11, color: Colors.white70)),
        ]),
      );
}

class _LiveLotCard extends StatelessWidget {
  const _LiveLotCard({required this.a, required this.onTap});
  final Auction a;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Solis.ink, borderRadius: BorderRadius.circular(22)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const PulseDot(),
              const SizedBox(width: 7),
              Text('LIVE · ${a.lot}', style: Solis.label(color: Colors.white70)),
            ]),
            const SizedBox(height: 14),
            Text(a.artwork.title, style: Solis.serif(16, color: Colors.white)),
            const SizedBox(height: 14),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(money(a.currentBid), style: Solis.serif(24, color: Solis.sunSoft)),
              const Spacer(),
              Ticker(builder: (_) => Text(timeLeft(a.endsAt), style: Solis.sans(11, color: Colors.white60))),
            ]),
          ]),
        ),
      );
}

// ---------------- Artwork detail ----------------

class ArtworkScreen extends StatefulWidget {
  const ArtworkScreen({super.key, required this.artworkId});
  final String artworkId;
  @override
  State<ArtworkScreen> createState() => _ArtworkScreenState();
}

class _ArtworkScreenState extends State<ArtworkScreen> {
  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiClient>();
    return Scaffold(
      body: AsyncView<(Artwork, Auction?)>(
        load: () async {
          final d = await api.get('/artworks/${widget.artworkId}');
          return (Artwork.fromJson(d['artwork']), d['auction'] == null ? null : Auction.fromJson(d['auction']));
        },
        builder: (context, data, reload) {
          final (art, auction) = data;
          return CustomScrollView(slivers: [
            SliverAppBar(
              expandedHeight: MediaQuery.sizeOf(context).height * 0.55,
              pinned: true,
              backgroundColor: Solis.ink,
              leading: Padding(padding: const EdgeInsets.all(6), child: CircleBtn(icon: Icons.chevron_left, glass: true, onTap: () => Navigator.pop(context))),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: CircleBtn(
                    icon: Icons.zoom_in_rounded,
                    glass: true,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArtworkZoomViewer(art: art))),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: FavoriteButton(art: art),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArtworkZoomViewer(art: art))),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(tag: 'art-${art.id}', child: ArtImage(art.image)),
                      const Scrim(from: 0.7, strength: 0.4),
                      Positioned(
                        bottom: 12,
                        right: 16,
                        child: GlassChip(text: 'TAP TO ZOOM', dot: false),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 40),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(art.title, style: Solis.serif(32)),
                  const SizedBox(height: 8),
                  Text([art.byline, art.dimensions].whereType<String>().join(' · '), style: Solis.sans(13.5, color: Solis.muted)),
                  const SizedBox(height: 18),
                  // Sweet Interactive Quick Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            side: const BorderSide(color: Solis.line),
                          ),
                          icon: const Icon(Icons.zoom_in_rounded, size: 18, color: Solis.ink),
                          label: Text('Inspect Brushwork', style: Solis.sans(12.5, color: Solis.ink, weight: FontWeight.w600)),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArtworkZoomViewer(art: art))),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            side: const BorderSide(color: Solis.line),
                          ),
                          icon: const Icon(Icons.chair_outlined, size: 18, color: Solis.ink),
                          label: Text('View in Room', style: Solis.sans(12.5, color: Solis.ink, weight: FontWeight.w600)),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RoomPreviewSheet(art: art))),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            side: const BorderSide(color: Solis.line),
                          ),
                          icon: const Icon(Icons.style_outlined, size: 18, color: Solis.ink),
                          label: Text('3D Card 🎴', style: Solis.sans(12.5, color: Solis.ink, weight: FontWeight.w600)),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CollectorCard3DScreen(art: art))),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            side: const BorderSide(color: Solis.line),
                          ),
                          icon: const Icon(Icons.verified_outlined, size: 18, color: Solis.ink),
                          label: Text('View COA 📜', style: Solis.sans(12.5, color: Solis.ink, weight: FontWeight.w600)),
                          onPressed: () => showCertificateOfAuthenticity(context, art),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Interactive Curator Audio Guide Player with Animated Waveform
                  InteractiveAudioGuide(art: art),
                  const SizedBox(height: 20),
                  if (art.description != null) Text(art.description!, style: Solis.serif(17, height: 1.45)),
                  const SizedBox(height: 24),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    if (art.series != null) _Chip(art.series!),
                    _Chip('${art.saves} saves'),
                    if (art.editionSize != null) _Chip('Edition of ${art.editionSize}'),
                  ]),
                  const SizedBox(height: 28),
                  if (auction != null && auction.isLive) ...[
                    PrimaryButton(
                      label: 'Live auction · ${money(auction.currentBid)}',
                      color: Solis.sun,
                      textColor: Solis.ink,
                      onPressed: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => AuctionDetailScreen(auctionId: auction.id)));
                        reload();
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (art.printPrice != null)
                    PrimaryButton(
                      label: 'Buy print · ${money(art.printPrice!)}',
                      onPressed: () => showPrintSheet(context, art),
                    ),
                ]),
              ),
            ),
          ]);
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Solis.line), color: Solis.card),
        child: Text(text, style: Solis.sans(12, weight: FontWeight.w500)),
      );
}

void showPrintSheet(BuildContext context, Artwork art) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Solis.paper,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            SizedBox(width: 64, height: 80, child: ArtImage(art.image, radius: 12)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(art.title, style: Solis.serif(20)),
                const SizedBox(height: 4),
                Text('Giclée print · Edition of ${art.editionSize ?? '—'}', style: Solis.sans(12.5, color: Solis.muted)),
              ]),
            ),
            Text(money(art.printPrice ?? 0), style: Solis.serif(22)),
          ]),
          const SizedBox(height: 20),
          Text('Prints are collected from the museum shop. Online checkout is coming soon — reserve now and pay on pickup.',
              style: Solis.sans(13.5, color: Solis.muted)),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Reserve print',
            onPressed: () {
              Navigator.pop(ctx);
              toast(context, 'Reserved “${art.title}”. We’ll email you when it’s ready.');
            },
          ),
        ]),
      ),
    ),
  );
}

// ---------------- Search ----------------

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _c = TextEditingController();
  Timer? _debounce;
  List<Artwork> _results = [];
  bool _loading = false;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _c.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(q));
  }

  Future<void> _search(String q) async {
    final seq = ++_seq;
    setState(() => _loading = true);
    try {
      final d = await CollectionData.load(context.read<ApiClient>(), q: q.trim());
      if (mounted && seq == _seq) setState(() => _results = d.artworks);
    } catch (e) {
      if (mounted) toast(context, errorText(e));
    } finally {
      if (mounted && seq == _seq) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.chevron_left, size: 28), onPressed: () => Navigator.pop(context)),
              Expanded(
                child: TextField(
                  controller: _c,
                  autofocus: true,
                  onChanged: _onChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search works',
                    prefixIcon: const Icon(Icons.search),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Solis.line)),
                  ),
                ),
              ),
            ]),
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 2, color: Solis.sun, backgroundColor: Colors.transparent),
          Expanded(
            child: _results.isEmpty && !_loading
                ? Center(child: Text('No works found', style: Solis.sans(14, color: Solis.muted)))
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, i) {
                      final a = _results[i];
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArtworkScreen(artworkId: a.id))),
                        child: Row(children: [
                          SizedBox(width: 60, height: 74, child: ArtImage(a.image, radius: 12)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(a.title, style: Solis.serif(18)),
                              const SizedBox(height: 4),
                              Text(a.byline, style: Solis.sans(12.5, color: Solis.muted)),
                            ]),
                          ),
                          const Icon(Icons.chevron_right, color: Solis.muted),
                        ]),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}
