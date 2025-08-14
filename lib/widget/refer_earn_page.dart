import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:confetti/confetti.dart';
import 'package:lottie/lottie.dart';

class ReferEarnPage extends StatefulWidget {
  const ReferEarnPage({super.key});

  @override
  State<ReferEarnPage> createState() => _ReferEarnPageState();
}

class _ReferEarnPageState extends State<ReferEarnPage> {
  final String referralCode = "NEAL420";
  final int totalEarned = 730;
  final ConfettiController _confetti = ConfettiController(duration: const Duration(seconds: 1));

  final List<String> invitedFriends = [
    "Rohit K.",
    "Ananya J.",
    "Yusuf A.",
    "Tanya S.",
    "Jay M.",
  ];

  final List<Map<String, dynamic>> rewards = [
    {"label": "Free Avatar Skin", "threshold": 500},
    {"label": "10% Store Discount", "threshold": 1000},
    {"label": "Exclusive Badge", "threshold": 1500},
  ];

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: referralCode));
    _confetti.play();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Code zapped! 🚨")),
    );
  }

  void _shareCode() {
    Share.share("Use my referral code $referralCode on Tiermetry and earn Tiergies!");
    _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        middle: Text("Refer & Earn",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            )),
        border: null,
      ),
      child: Material(
        color: Colors.black,
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: _buildPageContent(context),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confetti,
                  blastDirectionality: BlastDirectionality.explosive,
                  maxBlastForce: 15,
                  minBlastForce: 5,
                  emissionFrequency: 0.2,
                  numberOfParticles: 20,
                  gravity: 0.2,
                  colors: const [Colors.tealAccent, Colors.amber, Colors.purpleAccent],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                // child: Lottie.asset(
                //   'assets/animations/celebrate.json',
                //   width: 100,
                //   height: 100,
                //   repeat: true,
                // ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Earn Tiergies 💎",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              )),
          const SizedBox(height: 10),
          Text("Invite your friends & both of you earn rewards!",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white60,
              )),
          const SizedBox(height: 24),
          Text("You’ve earned",
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white54,
              )),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("$totalEarned",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  )),
              const SizedBox(width: 8),
              Text("Tiergies",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white38,
                  )),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: (totalEarned % 1000) / 1000,
            minHeight: 8,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.tealAccent),
            borderRadius: BorderRadius.circular(20),
          ),
          const SizedBox(height: 30),
          Text("Unlockable Rewards 🎁",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              )),
          const SizedBox(height: 12),
          Column(
            children: rewards.map((reward) {
              final unlocked = totalEarned >= reward['threshold'];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: unlocked ? Colors.teal.withOpacity(0.2) : Colors.white10,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: unlocked ? Colors.tealAccent : Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(reward['label'],
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: unlocked ? Colors.tealAccent : Colors.white70,
                        )),
                    Text("${reward['threshold']} 🪙",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white38,
                        )),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 30),
          Center(
            child: QrImageView(
              data: "https://tiermetry.com/signup?ref=$referralCode",
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(12),
              size: 150,
              eyeStyle: const QrEyeStyle(color: Colors.black, eyeShape: QrEyeShape.circle),
              dataModuleStyle: const QrDataModuleStyle(
                color: Colors.black,
                dataModuleShape: QrDataModuleShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 30),
          Text("Leaderboard Preview 🏆",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              )),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _leaderboardTile("You", totalEarned, isYou: true),
                _leaderboardTile("Ashish 🐐", 2040),
                _leaderboardTile("Zainab ⚡", 1800),
                _leaderboardTile("Pranav 🔥", 1450),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Text("You’ve invited",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              )),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: invitedFriends.map((friend) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, size: 18, color: Colors.white54),
                      const SizedBox(width: 10),
                      Text(friend,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white70,
                          )),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text("More friends = more Tiergies 🚀",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white30,
                )),
          ),
        ],
      ),
    );
  }

  Widget _leaderboardTile(String name, int points, {bool isYou = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: isYou ? FontWeight.w600 : FontWeight.w500,
              color: isYou ? Colors.tealAccent : Colors.white70,
            ),
          ),
          Text(
            "$points Tiergies",
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}
