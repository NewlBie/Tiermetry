import 'package:flutter/material.dart';
import '../models/profile_model.dart';

abstract class ProfileSource {
  Future<ProfileModel> getProfileData();
}

class ProfileSourceImpl implements ProfileSource {
  @override
  Future<ProfileModel> getProfileData() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    return ProfileModel(
      name: 'Neal',
      level: 'Predator',
      location: 'India',
      joinedDate: 'Apr 2024',
      age: 19,
      image: 'assets/Seller.png',
      tierName: 'Gold III',
      tierProgress: 0.75,
      openedBadges: 8,
      totalBadges: 20,
      badges: [
        BadgeModel(title: 'Pioneer', color: Colors.blueAccent),
        BadgeModel(title: 'Innovator', color: Colors.purpleAccent),
        BadgeModel(title: 'Strategist', color: Colors.orangeAccent),
      ],
      wallet: WalletModel(
        balance: '2500',
        earned: '700',
        spent: '350',
        txns: '24',
      ),
    );
  }
}
