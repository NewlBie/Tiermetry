import 'package:tiermetry/features/home/domain/entities/trending_activity.dart';
import 'package:tiermetry/features/profile/domain/entities/profile_entity.dart';

/// Thin abstraction over API calls.
///
/// For now the app uses a mock implementation, but keeping an interface avoids
/// leaking mock data shapes into the UI and makes the eventual network swap
/// straightforward.
abstract class ApiService {
  Future<WalletEntity> getWalletData();

  Future<List<TrendingActivity>> getTrendingActivities();
}
