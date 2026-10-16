import 'package:flutter/material.dart';
import '../../../../core/constants/app_avatars.dart';
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
    super.profileSetupCompleted = false,
    super.age,
    super.avatarId = AppAvatar.defaultAvatarId,
    super.image,
    super.username,
    super.phoneNumber,
    super.dob,
    super.platforms = const [],
    super.interests = const [],
    super.preferredGames = const [],
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final avatarId =
        json['avatar_id'] as int? ??
        AppAvatar.idFromAssetOrString(json['avatar_url']) ??
        AppAvatar.defaultAvatarId;

    return ProfileModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      level: json['level'] as String? ?? '',
      location: json['location'] as String? ?? '',
      joinedDate:
          json['created_at'] != null
              ? _formatDate(
                DateTime.parse(json['created_at'] as String).toLocal(),
              )
              : 'Unavailable',
      age: json['age'] as int?,
      avatarId: avatarId,
      image: AppAvatar.assetForId(avatarId),
      username: json['username'] as String?,
      phoneNumber: json['phone_number'] as String?,
      dob: json['dob'] as String?,
      platforms:
          (json['platforms'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      interests:
          (json['interests'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      preferredGames:
          (json['preferred_games'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      tierName: json['tier'] as String? ?? '',
      tierProgress: (json['tier_progress'] as num?)?.toDouble() ?? 0.0,
      tiergies: (json['tiergies'] as num?)?.toDouble() ?? 0.0,
      openedBadges: (json['user_badges'] as List<dynamic>?)?.length ?? 0,
      totalBadges:
          (json['total_badges'] as int?) ??
          (json['all_badges'] is List
              ? (json['all_badges'] as List).length
              : 0),
      badges:
          (json['user_badges'] as List<dynamic>?)?.map((ub) {
            final badgeJson = ub['badges'] as Map<String, dynamic>? ?? {};
            return BadgeModel.fromJson(badgeJson);
          }).toList() ??
          const [],
      wallet: () {
        final w = json['wallets'];
        if (w is List && w.isNotEmpty) {
          return WalletModel.fromJson(w.first as Map<String, dynamic>);
        } else if (w is Map<String, dynamic>) {
          return WalletModel.fromJson(w);
        }
        return WalletModel.fromJson({});
      }(),
      profileSetupCompleted: json['profile_setup_completed'] as bool? ?? false,
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
    // Attempt to parse color_hex like '#FFD4AF37' or '0xFFD4AF37'
    Color parseColor(String? hex) {
      if (hex == null) return Colors.grey;
      hex = hex.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.tryParse('0x$hex') ?? Colors.grey.toARGB32());
    }

    return BadgeModel(
      title: json['title'] as String? ?? '',
      color: parseColor(json['color_hex'] as String?),
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
      balance: (json['balance'] ?? 0).toString(),
      earned: (json['total_earned'] ?? 0).toString(),
      spent: (json['total_spent'] ?? 0).toString(),
      txns: (json['txn_count'] ?? 0).toString(),
    );
  }
}
