import 'package:amazing_icons/bulk.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tiermetry/features/profile/domain/entities/profile_entity.dart';

class WalletFlipCard extends StatelessWidget {
  final WalletEntity walletData;
  final VoidCallback onEarnPressed;
  final VoidCallback onRedeemPressed;

  const WalletFlipCard({
    required this.walletData,
    required this.onEarnPressed,
    required this.onRedeemPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2.0, // Much wider and shorter, not huge
      child: Container(
        padding: const EdgeInsets.all(12), // Added padding so inner sections float inside
        decoration: BoxDecoration(
          color: const Color(0xFF111111), // Deep black bottom
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Green Section (Balance & Info)
            Expanded(
              flex: 68,
              child: _GreenInnerSection(walletData: walletData),
            ),
            const SizedBox(height: 4),
            // Bottom Black Section (Actions)
            Expanded(
              flex: 32,
              child: _BottomActions(onEarnPressed: onEarnPressed, onRedeemPressed: onRedeemPressed),
            ),
          ],
        ),
      ),
    );
  }
}

class _GreenInnerSection extends StatelessWidget {
  final WalletEntity walletData;

  const _GreenInnerSection({required this.walletData});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF9CF46F), // Vibrant light green from the reference
        borderRadius: BorderRadius.circular(20), // Fully rounded corners
      ),
      child: Stack(
        children: [
          // Subtle Watermark Icon indicating recreational/event app
          Positioned(
            right: -10,
            bottom: -15,
            child: AmazingIconBulk.ticket(
              size: 110,
              color: Colors.black.withValues(alpha: 0.04),
            ),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  AmazingIconBulk.star(size: 14, color: const Color(0xFF0B3A11)),
                  const SizedBox(width: 6),
                  Text(
                    'AVAILABLE TIERGIES',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0B3A11).withValues(alpha: 0.7),
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              
              const Spacer(),
              
              // Balance & Pill Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    walletData.balance,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0B3A11),
                      letterSpacing: -1.0,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B3A11).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+ ${walletData.earned} recently',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0B3A11),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  final VoidCallback onEarnPressed;
  final VoidCallback onRedeemPressed;

  const _BottomActions({required this.onEarnPressed, required this.onRedeemPressed});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Action 1: Redeem Rewards
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onRedeemPressed();
            },
            child: Container(
              color: Colors.transparent, // expand gesture area
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AmazingIconBulk.wallet(size: 20, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Redeem',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Vertical Divider
        Container(
          width: 1,
          height: 18,
          color: Colors.white.withValues(alpha: 0.15),
        ),
        
        // Action 2: Earn More
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onEarnPressed();
            },
            child: Container(
              color: Colors.transparent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AmazingIconBulk.game(size: 20, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Earn More',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────
// Shimmer
// ────────────────────────────────────────────────
class WalletShimmerPlaceholder extends StatelessWidget {
  const WalletShimmerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1F2937),
      highlightColor: const Color(0xFF374151),
      child: AspectRatio(
        aspectRatio: 2.0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }
}
