import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tiermetry/theme/colors.dart';
import '../models/profile_data.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../widget/tier_and_badge_card.dart';
import '../widget/profile_settings_section.dart';
import '../widget/tiergy_wallet_card.dart'; // Assuming this is now backend-ready

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ApiService _apiService = ApiService();
  late Future<ProfileData> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _apiService.getProfileData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      body: SafeArea(
        child: FutureBuilder<ProfileData>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _ProfileShimmerPlaceholder();
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const Center(
                child: Text("Failed to load profile.", style: TextStyle(color: Colors.white70)),
              );
            }
            final profileData = snapshot.data!;
            return _ProfileContentView(profileData: profileData);
          },
        ),
      ),
    );
  }
}

class _ProfileContentView extends StatefulWidget {
  final ProfileData profileData;
  const _ProfileContentView({required this.profileData});

  @override
  State<_ProfileContentView> createState() => _ProfileContentViewState();
}

class _ProfileContentViewState extends State<_ProfileContentView> {
  File? _userImage;
  String _animatedBalanceText = '';
  Timer? _balanceTimer;

  @override
  void initState() {
    super.initState();
    _startMatrixBalanceAnimation();
  }

  @override
  void dispose() {
    _balanceTimer?.cancel();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _userImage = File(pickedFile.path);
      });
    }
  }

  void _startMatrixBalanceAnimation() {
    const frameDuration = Duration(milliseconds: 33);
    const totalDuration = Duration(milliseconds: 500);
    final target = widget.profileData.wallet.balance;
    final hindiChars = 'अआइउऊऋऌएकखगघचझटठडढनपफबभमयरलवशषसह';

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

      if (mounted) setState(() => _animatedBalanceText = scrambled);

      if (revealCount >= target.length) {
        timer.cancel();
        if (mounted) setState(() => _animatedBalanceText = target);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profileData;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        _ProfileIdentityCard(
          userName: profile.userName,
          userAge: profile.userAge,
          userLevel: profile.userLevel,
          imageFile: _userImage,
          imageAsset: profile.userImage,
          onImageTap: _pickImage,
        ),
        const SizedBox(height: 24),
        TiergyWalletFlipCard(
          // Pass the wallet data model directly
          walletData: profile.wallet.copyWith(balance: _animatedBalanceText),
          onEarnPressed: () => print("Earn Tiergies tapped"),
        ),
        const SizedBox(height: 24),
        TierAndBadgeCard(
          tierName: profile.currentTierName,
          tierProgress: profile.currentTierProgress,
          openedBadges: profile.openedBadges,
          totalBadges: profile.totalBadges,
          totalUniqueBadges: 20, // This could also come from the API
          badgeTitles: profile.badges.map((b) => b.title).toList(),
          badgeColors: profile.badges.map((b) => b.color).toList(),
        ),
        const SizedBox(height: 20),
        ProfileSettingsSection(
          onItemTap: (title) => print("Tapped: $title"),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

// Reusable UI Components for this page

class _ProfileIdentityCard extends StatelessWidget {
  final String userName;
  final int userAge;
  final String userLevel;
  final File? imageFile;
  final String imageAsset;
  final VoidCallback onImageTap;

  const _ProfileIdentityCard({
    required this.userName,
    required this.userAge,
    required this.userLevel,
    this.imageFile,
    required this.imageAsset,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onImageTap,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.grey.shade800,
              image: imageFile != null
                  ? DecorationImage(image: FileImage(imageFile!), fit: BoxFit.cover)
                  : DecorationImage(image: AssetImage(imageAsset), fit: BoxFit.cover),
            ),
            child: const Center(
              child: Icon(Icons.camera_alt, color: Colors.white54),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: SizedBox(
            height: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  userName,
                  style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: TiermetryColors.textPrimary),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildTag("Age: $userAge", Icons.cake_outlined),
                    _buildTag("India", Icons.flag_outlined),
                  ],
                ),
                _buildTag(userLevel, Icons.military_tech_rounded, isPrimary: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String label, IconData icon, {bool isPrimary = false}) {
    final color = isPrimary ? TiermetryColors.primary : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isPrimary ? color.withOpacity(0.15) : Colors.white10,
        border: Border.all(color: isPrimary ? color.withOpacity(0.4) : Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color.withOpacity(isPrimary ? 1.0 : 0.6)),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500, color: color.withOpacity(isPrimary ? 1.0 : 0.8)),
          ),
        ],
      ),
    );
  }
}

class _ProfileShimmerPlaceholder extends StatelessWidget {
  const _ProfileShimmerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[900]!,
      highlightColor: Colors.grey[800]!,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // Profile Header Shimmer
          Row(
            children: [
              Container(width: 100, height: 100, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20))),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 120, height: 20, color: Colors.black),
                    const SizedBox(height: 12),
                    Container(width: 150, height: 16, color: Colors.black),
                    const SizedBox(height: 12),
                    Container(width: 80, height: 24, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(14))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Wallet Card Shimmer
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Container(decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(28))),
          ),
          const SizedBox(height: 24),
          // Tier & Badge Card Shimmer
          Container(height: 250, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(28))),
          const SizedBox(height: 20),
          // Settings Section Shimmer
          Container(height: 200, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(28))),
        ],
      ),
    );
  }
}