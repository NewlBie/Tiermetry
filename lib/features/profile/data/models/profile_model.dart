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
      name: json['userName'] as String? ?? '',
      level: json['userLevel'] as String? ?? '',
      location: json['userLocation'] as String? ?? '',
      joinedDate: json['userJoinedDate'] as String? ?? '',
      age: json['userAge'] as int? ?? 0,
      image: json['userImage'] as String? ?? '',
      tierName: json['currentTierName'] as String? ?? '',
      tierProgress: (json['currentTierProgress'] as num?)?.toDouble() ?? 0.0,
      openedBadges: json['openedBadges'] as int? ?? 0,
      totalBadges: json['totalBadges'] as int? ?? 0,
      badges: (json['badges'] as List? ?? [])
          .map((dynamic b) => BadgeModel.fromJson(b as Map<String, dynamic>))
          .toList(),
      wallet: WalletModel.fromJson(json['wallet'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class BadgeModel extends BadgeEntity {
  BadgeModel({required super.title, required super.color});

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      title: json['title'] as String? ?? '',
      color: json['color'] != null ? Color(json['color'] as int) : Colors.grey,
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
      balance: json['balance'] as String? ?? '',
      earned: json['earned'] as String? ?? '',
      spent: json['spent'] as String? ?? '',
      txns: json['txns'] as String? ?? '',
    );
  }
}

