import 'package:flutter/material.dart';

class ProfileEntity {
  final String id;
  final String name;
  final String email;
  final String level;
  final String location;
  final String joinedDate;
  final int? age;
  final String? image;
  final String tierName;
  final double tierProgress;
  final double tiergies;
  final int openedBadges;
  final int totalBadges;
  final List<BadgeEntity> badges;
  final WalletEntity wallet;

  ProfileEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.level,
    required this.location,
    required this.joinedDate,
    required this.tierName,
    required this.tierProgress,
    required this.tiergies,
    required this.openedBadges,
    required this.totalBadges,
    required this.badges,
    required this.wallet,
    this.age,
    this.image,
  });

  ProfileEntity copyWith({
    String? name,
    String? location,
    int? age,
    String? image,
    double? tiergies,
  }) {
    return ProfileEntity(
      id: id,
      name: name ?? this.name,
      email: email,
      level: level,
      location: location ?? this.location,
      joinedDate: joinedDate,
      age: age ?? this.age,
      image: image ?? this.image,
      tierName: tierName,
      tierProgress: tierProgress,
      tiergies: tiergies ?? this.tiergies,
      openedBadges: openedBadges,
      totalBadges: totalBadges,
      badges: badges,
      wallet: wallet,
    );
  }
}

class BadgeEntity {
  final String title;
  final Color color;

  BadgeEntity({required this.title, required this.color});
}

class WalletEntity {
  final String balance;
  final String earned;
  final String spent;
  final String txns;

  WalletEntity({
    required this.balance,
    required this.earned,
    required this.spent,
    required this.txns,
  });

  WalletEntity copyWith({
    String? balance,
    String? earned,
    String? spent,
    String? txns,
  }) {
    return WalletEntity(
      balance: balance ?? this.balance,
      earned: earned ?? this.earned,
      spent: spent ?? this.spent,
      txns: txns ?? this.txns,
    );
  }
}
