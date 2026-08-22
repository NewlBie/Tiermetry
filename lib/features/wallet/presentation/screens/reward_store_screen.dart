import 'package:amazing_icons/bulk.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tiermetry/core/mixins/refresh_rate_mixin.dart';
import 'package:tiermetry/core/theme/colors.dart';

class RewardStoreScreen extends StatefulWidget {
  const RewardStoreScreen({super.key});

  @override
  State<RewardStoreScreen> createState() => _RewardStoreScreenState();
}

class _RewardStoreScreenState extends State<RewardStoreScreen>
    with RefreshRateMixin {
  final int userTiergies = 730; // Mock current balance

  final List<Map<String, dynamic>> _rewards = [
    {
      'id': 'r1',
      'title': 'Neon Avatar Skin',
      'description': 'Stand out on the leaderboards with this exclusive neon glow skin.',
      'cost': 500,
      'icon': Icons.person_outline,
      'color': Colors.purpleAccent,
    },
    {
      'id': 'r2',
      'title': '10% Arena Discount',
      'description': 'Get 10% off your next arena booking. Valid for 30 days.',
      'cost': 1500,
      'icon': Icons.discount_outlined,
      'color': Colors.amber,
    },
    {
      'id': 'r3',
      'title': 'Early Adopter Badge',
      'description': 'Show everyone you were here from the beginning.',
      'cost': 2500,
      'icon': Icons.shield_outlined,
      'color': Colors.tealAccent,
    },
    {
      'id': 'r4',
      'title': 'Free 1 Hour Session',
      'description': 'Book any standard rig for 1 hour completely free.',
      'cost': 5000,
      'icon': Icons.access_time,
      'color': TiermetryColors.accentNeonGreen,
    },
  ];

  void _showRedeemConfirm(Map<String, dynamic> reward) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (reward['color'] as Color).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    reward['icon'] as IconData,
                    color: reward['color'] as Color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reward['title'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${reward['cost']} Tiergies',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: TiermetryColors.accentNeonGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              reward['description'] as String,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (userTiergies >= (reward['cost'] as int)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Successfully redeemed ${reward['title']}!'),
                      backgroundColor: TiermetryColors.positive,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Not enough Tiergies.'),
                      backgroundColor: TiermetryColors.negative,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: TiermetryColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Redeem Now',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        middle: Text(
          'Reward Store',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        border: null,
      ),
      child: Material(
        color: Colors.black,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Redeem Tiergies',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: TiermetryColors.surfaceUnderlay,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                AmazingIconBulk.wallet(size: 14, color: TiermetryColors.accentNeonGreen),
                                const SizedBox(width: 6),
                                Text(
                                  '$userTiergies',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Exchange your hard-earned Tiergies for exclusive rewards, discounts, and perks.',
                        style: GoogleFonts.inter(fontSize: 14, color: Colors.white60),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final reward = _rewards[index];
                      final bool canAfford = userTiergies >= (reward['cost'] as int);
                      return GestureDetector(
                        onTap: () => _showRedeemConfirm(reward),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: (reward['color'] as Color).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  reward['icon'] as IconData,
                                  color: reward['color'] as Color,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      reward['title'] as String,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${reward['cost']} Tiergies',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: canAfford ? TiermetryColors.accentNeonGreen : Colors.white38,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: _rewards.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
