import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../api.dart';
import '../auth.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import '../widgets/ticket_pass_dialog.dart';

DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});
  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  late DateTime _selected = _dayOnly(DateTime.now());
  final _today = _dayOnly(DateTime.now());

  Future<List<SolisEvent>> _load() async {
    final to = _today.add(const Duration(days: 45));
    final d = await context.read<ApiClient>().get(
        '/events?from=${Uri.encodeQueryComponent(_today.toUtc().toIso8601String())}&to=${Uri.encodeQueryComponent(to.toUtc().toIso8601String())}');
    return (d['events'] as List).map((e) => SolisEvent.fromJson(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: AsyncView<List<SolisEvent>>(
        load: _load,
        builder: (context, events, reload) {
          final week = List.generate(7, (i) => _today.add(Duration(days: i)));
          final weekEnd = week.last.add(const Duration(days: 1));
          final dayEvents = events.where((e) => _dayOnly(e.startsAt) == _selected).toList();
          final later = events.where((e) => !e.startsAt.isBefore(weekEnd)).toList();
          final hasEvents = events.map((e) => _dayOnly(e.startsAt)).toSet();

          Future<void> open(SolisEvent e) async {
            await showEventSheet(context, e);
            reload();
          }

          return Column(
            children: [
              // Sticky top header: text, icon, and week nav
              Container(
                color: Solis.paper,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text('What’s on', style: Solis.serif(34))),
                      CircleBtn(icon: Icons.calendar_month_outlined, onTap: () => _pickDate(events)),
                    ]),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        for (final d in week)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2.5),
                              child: _DayPill(
                                day: d,
                                selected: d == _selected,
                                hasEvents: hasEvents.contains(d),
                                onTap: () => setState(() => _selected = d),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(color: Solis.line, height: 1),
              Expanded(
                child: RefreshIndicator(
                  color: Solis.sun,
                  onRefresh: reload,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                    children: [
                      Text('${DateFormat('EEE d MMM').format(_selected).toUpperCase()} · ${dayEvents.length} EVENT${dayEvents.length == 1 ? '' : 'S'}',
                          style: Solis.label()),
                      const SizedBox(height: 12),
                      if (dayEvents.isEmpty)
                        const EmptyState(icon: Icons.event_busy_outlined, text: 'Nothing scheduled this day. The galleries are open 10:00 – 18:00.'),
                      for (final e in dayEvents) ...[
                        _EventCard(e: e, onTap: () => open(e)),
                        const SizedBox(height: 12),
                      ],
                      if (later.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        SectionHeader('Later this month', action: 'Calendar', onAction: () => _pickDate(events)),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 150,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: later.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (_, i) => _SmallEventCard(e: later[i], onTap: () => open(later[i])),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickDate(List<SolisEvent> events) async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selected,
      firstDate: _today,
      lastDate: _today.add(const Duration(days: 44)),
      selectableDayPredicate: (_) => true,
    );
    if (d != null && mounted) {
      final picked = _dayOnly(d);
      final inWeek = picked.difference(_today).inDays < 7;
      if (inWeek) {
        setState(() => _selected = picked);
      } else {
        final evs = events.where((e) => _dayOnly(e.startsAt) == picked).toList();
        if (evs.isEmpty) {
          toast(context, 'No events on ${DateFormat('EEE d MMM').format(picked)}');
        } else {
          await showEventSheet(context, evs.first);
        }
      }
    }
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({required this.day, required this.selected, required this.hasEvents, required this.onTap});
  final DateTime day;
  final bool selected, hasEvents;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 72,
          decoration: BoxDecoration(
            color: selected ? Solis.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: selected ? Solis.ink : Solis.line),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(DateFormat('EEE').format(day).toUpperCase(), style: Solis.label(color: selected ? Colors.white70 : Solis.muted).copyWith(fontSize: 9)),
            const SizedBox(height: 3),
            Text('${day.day}', style: Solis.serif(19, color: selected ? Colors.white : Solis.ink)),
            const SizedBox(height: 3),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(shape: BoxShape.circle, color: hasEvents ? (selected ? Solis.sun : Solis.rust) : Colors.transparent),
            ),
          ]),
        ),
      );
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.e, required this.onTap});
  final SolisEvent e;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: SizedBox(
          height: 180,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(fit: StackFit.expand, children: [
              ArtImage(e.image),
              const Scrim(from: 0.3, strength: 0.8),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    GlassChip(text: DateFormat('h:mm a').format(e.startsAt).toUpperCase()),
                    const Spacer(),
                    if (e.isBooked)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Solis.teal, borderRadius: BorderRadius.circular(20)),
                        child: Row(children: [
                          const Icon(Icons.check, size: 13, color: Colors.white),
                          const SizedBox(width: 4),
                          Text('Booked', style: Solis.sans(11, color: Colors.white, weight: FontWeight.w600)),
                        ]),
                      ),
                  ]),
                  const Spacer(),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(e.title, style: Solis.serif(22, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(e.meta, style: Solis.sans(12, color: Colors.white.withValues(alpha: 0.85))),
                      ]),
                    ),
                    const CircleAvatar(radius: 20, backgroundColor: Colors.white, child: Icon(Icons.arrow_forward, size: 18, color: Solis.ink)),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
      );
}

class _SmallEventCard extends StatelessWidget {
  const _SmallEventCard({required this.e, required this.onTap});
  final SolisEvent e;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 160,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(fit: StackFit.expand, children: [
              ArtImage(e.image),
              const Scrim(from: 0.25, strength: 0.85),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Spacer(),
                  Text(DateFormat('EEE d MMM').format(e.startsAt).toUpperCase(), style: Solis.label(color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(e.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Solis.serif(16, color: Colors.white)),
                ]),
              ),
            ]),
          ),
        ),
      );
}

Future<void> showEventSheet(BuildContext context, SolisEvent e) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Solis.paper,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => _EventSheet(e: e),
  );
}

class _EventSheet extends StatefulWidget {
  const _EventSheet({required this.e});
  final SolisEvent e;
  @override
  State<_EventSheet> createState() => _EventSheetState();
}

class _EventSheetState extends State<_EventSheet> {
  late SolisEvent e = widget.e;
  bool _busy = false;

  Future<void> _toggle() async {
    setState(() => _busy = true);
    final api = context.read<ApiClient>();
    try {
      final d = e.isBooked ? await api.delete('/events/${e.id}/book') : await api.post('/events/${e.id}/book');
      setState(() => e = SolisEvent.fromJson(d['event']));
      if (mounted) toast(context, e.isBooked ? 'You’re booked for ${e.title}' : 'Booking cancelled');
    } catch (err) {
      if (mounted) toast(context, errorText(err));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Solis.line, borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 16),
          SizedBox(height: 180, width: double.infinity, child: ArtImage(e.image, radius: 22)),
          const SizedBox(height: 18),
          Text(DateFormat('EEEE d MMMM · h:mm a').format(e.startsAt).toUpperCase(), style: Solis.label()),
          const SizedBox(height: 6),
          Text(e.title, style: Solis.serif(28)),
          const SizedBox(height: 6),
          Text(e.meta, style: Solis.sans(13.5, color: Solis.muted)),
          if (e.description != null) ...[
            const SizedBox(height: 14),
            Text(e.description!, style: Solis.sans(14.5).copyWith(height: 1.5)),
          ],
          const SizedBox(height: 14),
          Text('${e.spotsLeft} of ${e.capacity} places left', style: Solis.sans(12.5, color: e.spotsLeft < 10 ? Solis.rust : Solis.muted, weight: FontWeight.w500)),
          const SizedBox(height: 18),
          if (e.isBooked) ...[
            PrimaryButton(
              label: '🎟 View Museum Pass (QR)',
              color: Solis.teal,
              onPressed: () {
                final user = context.read<AuthController>().user;
                showMuseumTicketPass(context, e, user?.name ?? '');
              },
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.cancel_outlined, size: 16, color: Solis.rust),
                label: Text('Cancel booking', style: Solis.sans(13, color: Solis.rust, weight: FontWeight.w500)),
                onPressed: _busy ? null : _toggle,
              ),
            ),
          ] else ...[
            PrimaryButton(
              label: e.spotsLeft == 0 ? 'Fully booked' : 'Book · ${e.priceLabel}',
              color: Solis.ink,
              loading: _busy,
              onPressed: e.spotsLeft == 0 ? null : _toggle,
            ),
          ],
        ]),
      ),
    );
  }
}
