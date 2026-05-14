import 'package:flutter/material.dart';
import '../../domain/entities/profile_entity.dart';

class ProfileModel extends ProfileEntity {
  ProfileModel({
    required super.name,
    required super.level,
    required super.location,
    required super.joinedDate,
    required super.age,
    required super.image,
    required super.tierName,
    required super.tierProgress,
    required super.openedBadges,
    required super.totalBadges,
    required super.badges,
    required super.wallet,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      name: json['userName'] ?? '',
      level: json['userLevel'] ?? '',
      location: json['userLocation'] ?? '',
      joinedDate: json['userJoinedDate'] ?? '',
      age: json['userAge'] ?? 0,
      image: json['userImage'] ?? '',
      tierName: json['currentTierName'] ?? '',
      tierProgress: (json['currentTierProgress'] as num?)?.toDouble() ?? 0.0,
      openedBadges: json['openedBadges'] ?? 0,
      totalBadges: json['totalBadges'] ?? 0,
      badges: (json['badges'] as List? ?? [])
          .map((b) => BadgeModel.fromJson(b))
          .toList(),
      wallet: WalletModel.fromJson(json['wallet'] ?? {}),
    );
  }
}

class BadgeModel extends BadgeEntity {
  BadgeModel({required super.title, required super.color});

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      title: json['title'] ?? '',
      color: json['color'] != null ? Color(json['color']) : Colors.grey,
    );
  }
}

class WalletModel extends WalletEntity {
  WalletModel({
    required super.balance,
    required super.earned,
    required super.spent,
    required super.txns,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      balance: json['balance'] ?? '',
      earned: json['earned'] ?? '',
      spent: json['spent'] ?? '',
      txns: json['txns'] ?? '',
    );
  }
}

