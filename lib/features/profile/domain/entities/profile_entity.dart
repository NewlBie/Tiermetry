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
  final String? username;
  final String? dob;
  final List<String> platforms;
  final List<String> interests;
  final List<String> preferredGames;
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
    this.username,
    this.dob,
    this.platforms = const [],
    this.interests = const [],
    this.preferredGames = const [],
  });

  ProfileEntity copyWith({
    String? name,
    String? location,
    int? age,
    String? image,
    String? username,
    String? dob,
    List<String>? platforms,
    List<String>? interests,
    List<String>? preferredGames,
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
      username: username ?? this.username,
      dob: dob ?? this.dob,
      platforms: platforms ?? this.platforms,
      interests: interests ?? this.interests,
      preferredGames: preferredGames ?? this.preferredGames,
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
