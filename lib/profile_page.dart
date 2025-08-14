// 📱 Tiermetry Profile Page — UI Match to Reference Image

import 'dart:ui';
import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:tiermetry/theme/colors.dart';
import 'package:tiermetry/widget/tiergy_wallet_card.dart';
import 'package:tiermetry/widget/tier_and_badge_card.dart';
import 'package:tiermetry/widget/profile_settings_section.dart';

class ProfilePage extends StatefulWidget {
  final String userName;
  final String userLevel;
  String userLocation = 'India';
  String userJoined = 'Apr 2024';
  final int totalBadges;
  final int openedBadges;
  final String currentTierName;
  final double currentTierProgress;
  final List<String> badgeTitles;
  final List<Color> badgeColors;
  final int electronsCurrent;
  final int electronsSpent;
  final int electronsTotal;

  ProfilePage({
    super.key,
    required this.userName,
    required this.userLevel,
    required this.totalBadges,
    required this.openedBadges,
    required this.currentTierName,
    required this.currentTierProgress,
    required this.badgeTitles,
    required this.badgeColors,
    required this.electronsCurrent,
    required this.electronsSpent,
    required this.electronsTotal,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? userImage;
  String userName = '';
  int userAge = 19;
  String animatedBalanceText = '';
  late int finalTiergyBalance;
  Timer? _balanceTimer;
  int _revealIndex = 0;
  final String _randomChars = '0123456789';
  bool _isSaving = false;


  @override
  void initState() {
    super.initState();
    userName = widget.userName;
    finalTiergyBalance = widget.electronsCurrent * 2;
    _startMatrixBalanceAnimation();
  }

  @override
  void didUpdateWidget(ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _startMatrixBalanceAnimation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TiermetryColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 80),
          children: [
            _profileIdentityCard(context),
            const SizedBox(height: 24),
            TiergyWalletFlipCard(
              balance: animatedBalanceText,
              earned: "${widget.electronsCurrent * 2}",
              spent: "${widget.electronsSpent * 2}",
              txns: "24",
              onEarnPressed: () {
                print("Earn Tiergies tapped");
              },
            ),
            const SizedBox(height: 24),
            TierAndBadgeCard(
              tierName: widget.currentTierName,
              tierProgress: widget.currentTierProgress,
              openedBadges: widget.openedBadges,
              totalBadges: widget.totalBadges,
              totalUniqueBadges: 20,
              badgeTitles: widget.badgeTitles,
              badgeColors: widget.badgeColors,
            ),
            const SizedBox(height: 20,),
            ProfileSettingsSection(
              onItemTap: (title) {
                // TODO: Navigate to proper pages or show modals
                print("Tapped: $title");
              },
            ),
            const SizedBox(height: 100),
            // BalancePowerUsageGraph(overallEfficiency: 87, avgWhPerMi: 147),
            // const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // 👤 Cool Modern Top Bar
  Widget _profileIdentityCard(BuildContext context) {
    return GestureDetector(
      child: Container(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Image
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.grey.shade800,
                image: userImage != null
                    ? DecorationImage(image: FileImage(userImage!), fit: BoxFit.cover)
                    : const DecorationImage(
                    image: AssetImage('assets/placeholder.png'),
                    fit: BoxFit.cover),
              ),
            ),

            const SizedBox(width: 20),

            // Info section fixed to 100px
            Expanded(
              child: SizedBox(
                height: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Username
                    Text(
                      userName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: TiermetryColors.textPrimary,
                      ),
                    ),

                    // Age and Country
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildTag("Age: $userAge", Icons.cake),
                        _buildTag("India", Icons.flag),
                      ],
                    ),

                    // Predator label only
                    _buildTag("Predator", Icons.military_tech_rounded, isPrimary: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label, IconData icon, {bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isPrimary ? TiermetryColors.primary.withOpacity(0.15) : Colors.white10,
        border: Border.all(
          color: isPrimary ? TiermetryColors.primary.withOpacity(0.4) : Colors.white12,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isPrimary ? TiermetryColors.primary : Colors.white54),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: isPrimary ? TiermetryColors.primary : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }


  void _startMatrixBalanceAnimation() {
    const frameDuration = Duration(milliseconds: 33);
    const totalDuration = Duration(milliseconds: 500);
    final target = finalTiergyBalance.toString();
    final hindiChars = 'अआइउऊऋऌएकखगघचझटठडढनपफबभमयरलवशषसह';

    _revealIndex = 0;
    _balanceTimer?.cancel();

    final startTime = DateTime.now();

    _balanceTimer = Timer.periodic(frameDuration, (timer) {
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      final percent = elapsed / totalDuration.inMilliseconds;

      final revealCount = (target.length * percent).clamp(0, target.length).floor();

      final scrambled = List.generate(target.length, (i) {
        if (i < revealCount) return target[i];
        return hindiChars[(DateTime.now().microsecondsSinceEpoch + i * 17) % hindiChars.length];
      }).join();

      setState(() => animatedBalanceText = scrambled);

      if (revealCount >= target.length) {
        timer.cancel();
        setState(() => animatedBalanceText = target);
      }
    });
  }
}