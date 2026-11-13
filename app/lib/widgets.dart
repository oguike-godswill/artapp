import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'api.dart';
import 'theme.dart';

final _money = NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 0);
String money(num v) => _money.format(v);

String timeLeft(DateTime end) {
  final d = end.difference(DateTime.now());
  if (d.isNegative) return 'Ended';
  if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h';
  if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
  return '${d.inMinutes}m ${d.inSeconds % 60}s';
}

String errorText(Object e) => e is ApiException ? e.message : 'Something went wrong. Please try again.';

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

class ArtImage extends StatelessWidget {
  const ArtImage(this.path, {super.key, this.radius = 0, this.fit = BoxFit.cover});
  final String? path;
  final double radius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final url = AppConfig.asset(path);
    final placeholder = Container(color: const Color(0xFFD9CBB4));
    final img = url.isEmpty
        ? placeholder
        : CachedNetworkImage(
            imageUrl: url,
            fit: fit,
            fadeInDuration: const Duration(milliseconds: 250),
            placeholder: (_, __) => placeholder,
            errorWidget: (_, __, ___) => Container(
              color: const Color(0xFFD9CBB4),
              child: const Icon(Icons.image_not_supported_outlined, color: Solis.muted),
            ),
          );
    return radius == 0 ? img : ClipRRect(borderRadius: BorderRadius.circular(radius), child: img);
  }
}

/// Dark gradient overlay for legible text on top of images.
class Scrim extends StatelessWidget {
  const Scrim({super.key, this.from = 0.35, this.strength = 0.85});
  final double from, strength;
  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [from, 1],
            colors: [Colors.transparent, Colors.black.withValues(alpha: strength)],
          ),
        ),
      );
}

class GlassChip extends StatelessWidget {
  const GlassChip({super.key, required this.text, this.dot = false, this.dark = false});
  final String text;
  final bool dot, dark;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: (dark ? Colors.black : Colors.white).withValues(alpha: dark ? 0.35 : 0.22),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (dot) ...[
                const PulseDot(),
                const SizedBox(width: 7),
              ],
              Text(text, style: Solis.label(color: Colors.white)),
            ]),
          ),
        ),
      );
}

class PulseDot extends StatefulWidget {
  const PulseDot({super.key, this.color = Solis.sun});
  final Color color;
  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween(begin: 0.45, end: 1.0).animate(_c),
        child: Container(width: 7, height: 7, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
      );
}

class CircleBtn extends StatelessWidget {
  const CircleBtn({super.key, required this.icon, this.onTap, this.glass = false, this.color});
  final IconData icon;
  final VoidCallback? onTap;
  final bool glass;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: glass ? Colors.white.withValues(alpha: 0.22) : Solis.card,
        border: Border.all(color: glass ? Colors.white.withValues(alpha: 0.3) : Solis.line),
      ),
      child: Icon(icon, size: 20, color: color ?? (glass ? Colors.white : Solis.ink)),
    );
    return GestureDetector(
      onTap: onTap,
      child: glass
          ? ClipOval(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: child))
          : child,
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.loading = false, this.color = Solis.ink, this.textColor = Solis.paper});
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Color color, textColor;
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 56,
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: color,
            disabledBackgroundColor: color.withValues(alpha: 0.5),
            shape: const StadiumBorder(),
          ),
          onPressed: loading ? null : onPressed,
          child: loading
              ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2, color: textColor))
              : Text(label, style: Solis.sans(15, color: textColor, weight: FontWeight.w600)),
        ),
      );
}

/// Rebuilds every second – for countdowns.
class Ticker extends StatefulWidget {
  const Ticker({super.key, required this.builder});
  final WidgetBuilder builder;
  @override
  State<Ticker> createState() => _TickerState();
}

class _TickerState extends State<Ticker> {
  late final Timer _t = Timer.periodic(const Duration(seconds: 1), (_) => mounted ? setState(() {}) : null);
  @override
  void dispose() {
    _t.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

/// Generic async loader with loading / error / retry states and pull-to-refresh.
class AsyncView<T> extends StatefulWidget {
  const AsyncView({super.key, required this.load, required this.builder});
  final Future<T> Function() load;
  final Widget Function(BuildContext, T, Future<void> Function() reload) builder;
  @override
  State<AsyncView<T>> createState() => AsyncViewState<T>();
}

class AsyncViewState<T> extends State<AsyncView<T>> {
  T? _data;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    if (_data == null) setState(() => _loading = true);
    try {
      final d = await widget.load();
      if (!mounted) return;
      setState(() {
        _data = d;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
      if (_data != null) toast(context, errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _data == null) {
      return const Center(child: CircularProgressIndicator(color: Solis.sun, strokeWidth: 2.4));
    }
    if (_data == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_rounded, size: 40, color: Solis.muted),
            const SizedBox(height: 12),
            Text(errorText(_error ?? 'Error'), textAlign: TextAlign.center, style: Solis.sans(14, color: Solis.muted)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: reload, child: const Text('Try again')),
          ]),
        ),
      );
    }
    return widget.builder(context, _data as T, reload);
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction, this.color = Solis.ink});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: Text(title, style: Solis.serif(22, color: color))),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Row(children: [
                Text(action!, style: Solis.sans(13, color: color, weight: FontWeight.w500)),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 15, color: color),
              ]),
            ),
        ],
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: Solis.card, borderRadius: BorderRadius.circular(22), border: Border.all(color: Solis.line)),
        child: Row(children: [
          Icon(icon, color: Solis.muted),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: Solis.sans(13.5, color: Solis.muted))),
        ]),
      );
}
