import 'package:tiermetry/core/services/api_service.dart';
import 'package:tiermetry/features/home/domain/entities/trending_activity.dart';
import 'package:tiermetry/features/profile/domain/entities/profile_entity.dart';

class MockApiService implements ApiService {
  @override
  Future<WalletEntity> getWalletData() async {
    await Future.delayed(const Duration(seconds: 2));
    return WalletEntity(
      balance: r'$1,250.75',
      earned: '350.20',
      spent: '180.50',
      txns: '42',
    );
  }

  @override
  Future<List<TrendingActivity>> getTrendingActivities() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      TrendingActivity(
        id: '1',
        name: 'Bowling',
        icon: 'bowling',
        playersToday: 1245,
        rating: 4.8,
      ),
      TrendingActivity(
        id: '2',
        name: 'Go Kart',
        icon: 'gokart',
        playersToday: 892,
        rating: 4.6,
      ),
      TrendingActivity(
        id: '3',
        name: 'Football Turf',
        icon: 'football',
        playersToday: 567,
        rating: 4.9,
      ),
      TrendingActivity(
        id: '4',
        name: 'Gaming Cafe',
        icon: 'gaming',
        playersToday: 2105,
        rating: 4.7,
      ),
    ];
  }
}

