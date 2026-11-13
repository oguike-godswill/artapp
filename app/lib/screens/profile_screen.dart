import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../api.dart';
import '../auth.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import '../widgets/bidder_paddle_dialog.dart';
import 'aesthetic_quiz_screen.dart';
import 'auction_screens.dart';
import 'collection_screen.dart';
import 'events_screen.dart';
import 'museum_map_3d.dart';
import 'shell.dart';

class Activity {
  final List<Artwork> favorites;
  final List<(int, Auction)> bids;
  final List<SolisEvent> bookings;
  Activity(this.favorites, this.bids, this.bookings);
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Activity? _act;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    AppShell.activeTab.addListener(_onTabChange);
    _load();
  }

  @override
  void dispose() {
    AppShell.activeTab.removeListener(_onTabChange);
    super.dispose();
  }

  void _onTabChange() {
    if (AppShell.activeTab.value == 4) {
      _load();
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    if (_act == null) setState(() => _loading = true);
    final api = context.read<ApiClient>();
    try {
      final d = await api.get('/me/activity');
      if (!mounted) return;
      setState(() {
        _act = Activity(
          (d['favorites'] as List).map((e) => Artwork.fromJson(e)).toList(),
          (d['bids'] as List).map((e) => ((e['myMax'] as num).toInt(), Auction.fromJson(e['auction']))).toList(),
          (d['bookings'] as List).map((e) => SolisEvent.fromJson(e)).toList(),
        );
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.user;
    final act = _act;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // Sticky top header: title and settings icon
          Container(
            color: Solis.paper,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(children: [
              Expanded(child: Text('Profile', style: Solis.serif(34))),
              CircleBtn(icon: Icons.settings_outlined, onTap: () => _settings(context)),
            ]),
          ),
          const Divider(color: Solis.line, height: 1),
          Expanded(
            child: _loading && act == null
                ? const Center(child: CircularProgressIndicator(color: Solis.sun))
                : _error != null && act == null
                    ? Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(errorText(_error!), style: Solis.sans(14, color: Solis.muted)),
                          const SizedBox(height: 12),
                          OutlinedButton(onPressed: _load, child: const Text('Try again')),
                        ]),
                      )
                    : RefreshIndicator(
                        color: Solis.sun,
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(color: Solis.teal, borderRadius: BorderRadius.circular(26)),
                              child: Row(children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Solis.sun,
                                  child: Text(user?.initials ?? '?', style: Solis.serif(22, color: Solis.ink)),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(user?.name ?? '', style: Solis.serif(22, color: Solis.paper)),
                                    const SizedBox(height: 2),
                                    Text(user?.email ?? '', style: Solis.sans(13, color: Colors.white70)),
                                  ]),
                                ),
                              ]),
                            ),
                            const SizedBox(height: 14),
                            Row(children: [
                              _Stat(value: '${act?.bids.length ?? 0}', label: 'Lots bid'),
                              const SizedBox(width: 10),
                              _Stat(value: '${act?.favorites.length ?? 0}', label: 'Saved'),
                              const SizedBox(width: 10),
                              _Stat(value: '${act?.bookings.length ?? 0}', label: 'Bookings'),
                            ]),
                            const SizedBox(height: 16),
                            // VIP Collector Privileges: Paddle, 3D Map, Aesthetic
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => showBidderPaddle(context, user?.name ?? '', user?.id ?? ''),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: Solis.card,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Solis.sunSoft, width: 1.2),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.gavel_rounded, size: 16, color: Solis.sun),
                                          const SizedBox(width: 6),
                                          Text('Paddle #', style: Solis.sans(12, color: Solis.ink, weight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MuseumMap3DScreen())),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: Solis.card,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Solis.line),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.view_in_ar_rounded, size: 16, color: Solis.teal),
                                          const SizedBox(width: 6),
                                          Text('3D Pavilion', style: Solis.sans(12, color: Solis.ink, weight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AestheticQuizScreen())),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: Solis.card,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Solis.line),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.auto_awesome_rounded, size: 16, color: Solis.rust),
                                          const SizedBox(width: 6),
                                          Text('Art Quiz', style: Solis.sans(12, color: Solis.ink, weight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            const SectionHeader('My bids'),
                            const SizedBox(height: 12),
                            if (act?.bids.isEmpty ?? true) const EmptyState(icon: Icons.gavel_rounded, text: 'You haven’t placed any bids yet.'),
                            if (act != null)
                              for (final (myMax, a) in act.bids)
                                _Row(
                                  image: a.artwork.image,
                                  title: a.artwork.title,
                                  subtitle: 'Your max ${money(myMax)} · Current ${money(a.currentBid)}',
                                  trailing: _Badge(
                                    text: !a.isLive ? (a.isLeading ? 'Won' : 'Closed') : (a.isLeading ? 'Leading' : 'Outbid'),
                                    color: a.isLeading ? Solis.teal : (a.isLive ? Solis.rust : Solis.muted),
                                  ),
                                  onTap: () async {
                                    await Navigator.push(context, MaterialPageRoute(builder: (_) => AuctionDetailScreen(auctionId: a.id)));
                                    _load();
                                  },
                                ),
                            const SizedBox(height: 24),
                            const SectionHeader('Upcoming bookings'),
                            const SizedBox(height: 12),
                            if (act?.bookings.isEmpty ?? true) const EmptyState(icon: Icons.event_outlined, text: 'No bookings yet. Find something in Events.'),
                            if (act != null)
                              for (final e in act.bookings)
                                _Row(
                                  image: e.image,
                                  title: e.title,
                                  subtitle: DateFormat('EEE d MMM · h:mm a').format(e.startsAt),
                                  onTap: () async {
                                    await showEventSheet(context, e);
                                    _load();
                                  },
                                ),
                            const SizedBox(height: 24),
                            const SectionHeader('Saved works'),
                            const SizedBox(height: 12),
                            if (act?.favorites.isEmpty ?? true) const EmptyState(icon: Icons.favorite_border, text: 'Tap the heart on any work to save it.'),
                            if (act != null && act.favorites.isNotEmpty)
                              SizedBox(
                                height: 140,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: act.favorites.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                                  itemBuilder: (_, i) {
                                    final a = act.favorites[i];
                                    return GestureDetector(
                                      onTap: () async {
                                        await Navigator.push(context, MaterialPageRoute(builder: (_) => ArtworkScreen(artworkId: a.id)));
                                        _load();
                                      },
                                      child: SizedBox(width: 110, child: ArtImage(a.image, radius: 18)),
                                    );
                                  },
                                ),
                              ),
                            const SizedBox(height: 30),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                shape: const StadiumBorder(),
                                side: const BorderSide(color: Solis.line),
                                foregroundColor: Solis.rust,
                              ),
                              icon: const Icon(Icons.logout_rounded, size: 18),
                              label: const Text('Sign out'),
                              onPressed: () => context.read<AuthController>().logout(),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _settings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Solis.paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => const _SettingsSheet(),
    );
  }
}

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet();
  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: context.read<AuthController>().user?.name);
  final _current = TextEditingController();
  final _next = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final auth = context.read<AuthController>();
    try {
      if (_name.text.trim() != auth.user?.name) await auth.updateName(_name.text);
      if (_next.text.isNotEmpty) await auth.changePassword(_current.text, _next.text);
      if (mounted) {
        Navigator.pop(context);
        toast(context, 'Profile updated');
      }
    } catch (e) {
      if (mounted) toast(context, errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(22, 22, 22, 22 + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _form,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Account', style: Solis.serif(26)),
          const SizedBox(height: 18),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name'),
            validator: (v) => (v == null || v.trim().length < 2) ? 'Please enter your name' : null,
          ),
          const SizedBox(height: 22),
          Text('CHANGE PASSWORD', style: Solis.label()),
          const SizedBox(height: 10),
          TextFormField(
            controller: _current,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Current password'),
            validator: (v) => (_next.text.isNotEmpty && (v == null || v.isEmpty)) ? 'Enter your current password' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _next,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New password'),
            validator: (v) {
              final s = v ?? '';
              if (s.isEmpty) return null;
              if (s.length < 8) return 'Use at least 8 characters';
              if (!RegExp(r'[A-Za-z]').hasMatch(s) || !RegExp(r'\d').hasMatch(s)) return 'Include a letter and a number';
              return null;
            },
          ),
          const SizedBox(height: 22),
          PrimaryButton(label: 'Save', loading: _busy, onPressed: _save),
        ]),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value, label;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: Solis.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: Solis.line)),
          child: Column(children: [
            Text(value, style: Solis.serif(24)),
            const SizedBox(height: 2),
            Text(label, style: Solis.sans(11.5, color: Solis.muted)),
          ]),
        ),
      );
}

class _Row extends StatelessWidget {
  const _Row({required this.image, required this.title, required this.subtitle, this.trailing, this.onTap});
  final String? image;
  final String title, subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Solis.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: Solis.line)),
            child: Row(children: [
              SizedBox(width: 54, height: 64, child: ArtImage(image, radius: 12)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: Solis.serif(16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Solis.sans(12, color: Solis.muted)),
                ]),
              ),
              if (trailing != null) trailing!,
              const SizedBox(width: 4),
            ]),
          ),
        ),
      );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
        child: Text(text, style: Solis.sans(11, color: Colors.white, weight: FontWeight.w600)),
      );
}
