import 'package:flutter/material.dart';
import '../../domain/entities/profile_entity.dart';

class ProfileModel extends ProfileEntity {
  ProfileModel({
    required super.id,
    required super.name,
    required super.email,
    required super.level,
    required super.location,
    required super.joinedDate,
    required super.tierName,
    required super.tierProgress,
    required super.tiergies,
    required super.openedBadges,
    required super.totalBadges,
    required super.badges,
    required super.wallet,
    super.age,
    super.image,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Gamer',
      email: json['email'] as String? ?? '',
      level: json['level'] as String? ?? 'Beginner',
      location: json['location'] as String? ?? 'India',
      joinedDate:
          json['created_at'] != null
              ? _formatDate(DateTime.parse(json['created_at'] as String))
              : 'Unknown',
      age: json['age'] as int?,
      image: json['avatar_url'] as String?,
      tierName: json['tier'] as String? ?? 'Bronze I',
      tierProgress: (json['tier_progress'] as num?)?.toDouble() ?? 0.0,
      tiergies: (json['tiergies'] as num?)?.toDouble() ?? 0.0,
      openedBadges: 0,
      totalBadges: 10,
      badges: [],
      wallet: WalletModel.fromJson({}),
    );
  }

  static String _formatDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.year}';
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
      balance: json['balance'] as String? ?? '0',
      earned: json['earned'] as String? ?? '0',
      spent: json['spent'] as String? ?? '0',
      txns: json['txns'] as String? ?? '0',
    );
  }
}
