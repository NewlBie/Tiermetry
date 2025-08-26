import 'package:flutter/material.dart';
import 'wallet_data.dart'; // Assuming you have this from the wallet enhancement

class ProfileData {
  final String userName;
  final String userLevel;
  final String userLocation;
  final String userJoinedDate;
  final int userAge;
  final String userImage; // URL or asset path
  final String currentTierName;
  final double currentTierProgress;
  final int openedBadges;
  final int totalBadges;
  final List<BadgeData> badges;
  final WalletData wallet;

  ProfileData({
    required this.userName,
    required this.userLevel,
    required this.userLocation,
    required this.userJoinedDate,
    required this.userAge,
    required this.userImage,
    required this.currentTierName,
    required this.currentTierProgress,
    required this.openedBadges,
    required this.totalBadges,
    required this.badges,
    required this.wallet,
  });
}

class BadgeData {
  final String title;
  final Color color;

  BadgeData({required this.title, required this.color});
}