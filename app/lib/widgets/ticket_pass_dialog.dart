import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

void showMuseumTicketPass(BuildContext context, SolisEvent event, String attendeeName) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Museum Pass',
    pageBuilder: (ctx, anim, _) {
      return ScaleTransition(
        scale: Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
        child: FadeTransition(
          opacity: anim,
          child: _TicketPassDialog(event: event, attendeeName: attendeeName),
        ),
      );
    },
  );
}

class _TicketPassDialog extends StatelessWidget {
  const _TicketPassDialog({required this.event, required this.attendeeName});
  final SolisEvent event;
  final String attendeeName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Solis.card,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 36,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ticket Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Solis.teal,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('SOLIS MUSEUM PASS', style: Solis.label(color: Solis.paper).copyWith(letterSpacing: 2)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Solis.sun, borderRadius: BorderRadius.circular(10)),
                          child: Text('ADMIT 1', style: Solis.sans(10, color: Solis.ink, weight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(event.title, style: Solis.serif(22, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(event.venue ?? 'Main Gallery', style: Solis.sans(12.5, color: Colors.white70)),
                  ],
                ),
              ),

              // Notched perforation separator
              Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(double.infinity, 20),
                    painter: _DottedLinePainter(),
                  ),
                  Positioned(
                    left: -10,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                    ),
                  ),
                  Positioned(
                    right: -10,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                    ),
                  ),
                ],
              ),

              // Ticket Details + Stylized QR
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _Detail(label: 'DATE', value: DateFormat('EEE, d MMM').format(event.startsAt)),
                        _Detail(label: 'TIME', value: DateFormat('h:mm a').format(event.startsAt)),
                        _Detail(label: 'PRICE', value: event.priceLabel),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _Detail(label: 'GUEST', value: attendeeName.isEmpty ? 'Member' : attendeeName),
                        _Detail(label: 'PASS ID', value: '#SLS-${event.id.hashCode.abs().toString().substring(0, 5)}'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Stylized QR code
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Solis.line),
                      ),
                      child: Column(
                        children: [
                          CustomPaint(
                            size: const Size(120, 120),
                            painter: _MockQRPainter(),
                          ),
                          const SizedBox(height: 6),
                          Text('SCAN AT ENTRANCE', style: Solis.label(color: Solis.muted).copyWith(fontSize: 8.5)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: 'Add to Calendar',
                      color: Solis.ink,
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context);
                        toast(context, '✓ Added "${event.title}" to device calendar');
                      },
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Dismiss', style: Solis.sans(13, color: Solis.muted)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Solis.label(color: Solis.muted).copyWith(fontSize: 9.5)),
          const SizedBox(height: 2),
          Text(value, style: Solis.sans(13, weight: FontWeight.w600)),
        ],
      );
}

class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Solis.line
      ..strokeWidth = 1.5;
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    var startX = 14.0;
    final y = size.height / 2;
    while (startX < size.width - 14) {
      canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MockQRPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Solis.ink;
    // Outer corner finder squares
    void drawFinder(double x, double y) {
      canvas.drawRect(Rect.fromLTWH(x, y, 28, 28), p);
      canvas.drawRect(Rect.fromLTWH(x + 5, y + 5, 18, 18), Paint()..color = Colors.white);
      canvas.drawRect(Rect.fromLTWH(x + 9, y + 9, 10, 10), p);
    }

    drawFinder(0, 0);
    drawFinder(size.width - 28, 0);
    drawFinder(0, size.height - 28);

    // Decorative grid blocks
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        if ((r < 3 && c < 3) || (r < 3 && c > 4) || (r > 4 && c < 3)) continue;
        if ((r * 7 + c * 13) % 3 == 0) {
          final x = 32.0 + c * 7.5;
          final y = 32.0 + r * 7.5;
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, 5.5, 5.5), const Radius.circular(1.5)), p);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
