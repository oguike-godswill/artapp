import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

void showBidderPaddle(BuildContext context, String userName, String userId) {
  final paddleNumber = (userId.hashCode.abs() % 900 + 100).toString();
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Bidder Paddle',
    pageBuilder: (ctx, anim, _) {
      return ScaleTransition(
        scale: Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
        child: FadeTransition(
          opacity: anim,
          child: _PaddleDialog(paddleNumber: paddleNumber, userName: userName),
        ),
      );
    },
  );
}

class _PaddleDialog extends StatelessWidget {
  const _PaddleDialog({required this.paddleNumber, required this.userName});
  final String paddleNumber;
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 310,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 3D Paddle Head
              Container(
                width: 250,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 26),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2C241D), Color(0xFF161310)],
                  ),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Solis.sunSoft, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Solis.sun.withValues(alpha: 0.35),
                      blurRadius: 32,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.gavel_rounded, size: 14, color: Solis.sunSoft),
                        const SizedBox(width: 6),
                        Text('SOLIS LIVE AUCTION', style: Solis.label(color: Solis.sunSoft).copyWith(letterSpacing: 2)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      paddleNumber,
                      style: Solis.serif(64, color: Colors.white, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        userName.isEmpty ? 'Verified Collector' : userName.toUpperCase(),
                        style: Solis.sans(11, color: Colors.white70, weight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

              // Paddle Handle Neck
              Container(
                width: 28,
                height: 55,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E1A16), Color(0xFF100E0C)],
                  ),
                  border: Border.symmetric(vertical: BorderSide(color: Solis.sunSoft.withValues(alpha: 0.5), width: 1.5)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              // Close button
              CircleBtn(
                icon: Icons.close_rounded,
                glass: true,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showCertificateOfAuthenticity(BuildContext context, Artwork art) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Certificate',
    pageBuilder: (ctx, anim, _) {
      return ScaleTransition(
        scale: Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
        child: FadeTransition(
          opacity: anim,
          child: _CertificateDialog(art: art),
        ),
      );
    },
  );
}

class _CertificateDialog extends StatelessWidget {
  const _CertificateDialog({required this.art});
  final Artwork art;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF6EE),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Solis.sunSoft, width: 2),
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
              Text('CERTIFICATE OF AUTHENTICITY',
                  textAlign: TextAlign.center,
                  style: Solis.label(color: Solis.rust).copyWith(letterSpacing: 2, fontSize: 10)),
              const SizedBox(height: 8),
              Text(art.title, textAlign: TextAlign.center, style: Solis.serif(24)),
              const SizedBox(height: 4),
              Text(art.byline, textAlign: TextAlign.center, style: Solis.sans(12.5, color: Solis.muted)),
              const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(color: Solis.line, height: 1)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _coItem('MEDIUM', art.medium ?? 'Original Work'),
                  _coItem('YEAR', '${art.year ?? 2024}'),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _coItem('DIMENSIONS', art.dimensions ?? 'Catalog Standard'),
                  _coItem('EDITION', '#${art.editionSize ?? 250} Prints'),
                ],
              ),
              const SizedBox(height: 20),
              // Wax Seal simulation
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Solis.rust,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Solis.rust.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                      border: Border.all(color: Solis.sunSoft, width: 1.5),
                    ),
                    child: const Center(
                      child: Text('SLS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('VERIFIED MUSEUM PROVENANCE', style: Solis.label(color: Solis.muted).copyWith(fontSize: 8)),
                      const SizedBox(height: 2),
                      Text('Signed: Dr. Zawadi Mensah', style: Solis.sans(12, weight: FontWeight.w600)),
                      Text('Chief Curator · Solis Museum', style: Solis.sans(10.5, color: Solis.muted)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 22),
              PrimaryButton(
                label: 'Save Certificate',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                  toast(context, '✓ Certificate of Authenticity saved');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _coItem(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Solis.label(color: Solis.muted).copyWith(fontSize: 8.5)),
          const SizedBox(height: 2),
          Text(value, style: Solis.sans(12, weight: FontWeight.w600)),
        ],
      );
}
