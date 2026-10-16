import 'package:flutter/material.dart';
import '../../../../core/constants/app_avatars.dart';

class ProfileEntity {
  final String id;
  final String name;
  final String email;
  final String level;
  final String location;
  final String joinedDate;
  final int? age;
  final int avatarId;
  final String? image;
  final String? username;
  final String? phoneNumber;
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
  final bool profileSetupCompleted;

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
    this.profileSetupCompleted = false,
    this.age,
    this.avatarId = AppAvatar.defaultAvatarId,
    String? image,
    this.username,
    this.phoneNumber,
    this.dob,
    this.platforms = const [],
    this.interests = const [],
    this.preferredGames = const [],
  }) : image = image ?? AppAvatar.assetForId(avatarId);

  ProfileEntity copyWith({
    String? name,
    String? location,
    int? age,
    bool clearAge = false,
    int? avatarId,
    String? image,
    String? username,
    String? phoneNumber,
    String? dob,
    List<String>? platforms,
    List<String>? interests,
    List<String>? preferredGames,
    double? tiergies,
    bool? profileSetupCompleted,
  }) {
    final nextAvatarId = avatarId ?? this.avatarId;
    final nextImage =
        image ??
        (avatarId != null
            ? AppAvatar.assetForId(nextAvatarId)
            : this.image ?? AppAvatar.assetForId(nextAvatarId));

    return ProfileEntity(
      id: id,
      name: name ?? this.name,
      email: email,
      level: level,
      location: location ?? this.location,
      joinedDate: joinedDate,
      age: clearAge ? null : age ?? this.age,
      avatarId: nextAvatarId,
      image: nextImage,
      username: username ?? this.username,
      phoneNumber: phoneNumber ?? this.phoneNumber,
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
      profileSetupCompleted:
          profileSetupCompleted ?? this.profileSetupCompleted,
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

class ProfileAddress {
  final String id;
  final String label;
  final String addressLine;
  final String city;
  final bool isPrimary;

  const ProfileAddress({
    required this.id,
    required this.label,
    required this.addressLine,
    required this.city,
    required this.isPrimary,
  });
}

class AccountDeletionRequest {
  final String status;
  final String? reason;
  final DateTime requestedAt;

  const AccountDeletionRequest({
    required this.status,
    required this.reason,
    required this.requestedAt,
  });
}

class SupportRequestEntity {
  final String id;
  final String category;
  final String message;
  final String status;
  final String? bookingId;
  final String? paymentOrderId;
  final String? resolutionNote;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool alreadyOpen;

  const SupportRequestEntity({
    required this.id,
    required this.category,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.bookingId,
    this.paymentOrderId,
    this.resolutionNote,
    this.alreadyOpen = false,
  });
}
