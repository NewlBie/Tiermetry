// Arena feature
import '../features/arena/domain/repositories/arena_repo.dart';
import '../features/arena/data/repositories/arena_repo_impl.dart';
import '../features/arena/domain/usecases/get_arenas_uc.dart';
import '../features/arena/domain/usecases/get_arena_details_uc.dart';
import '../features/arena/presentation/controllers/arena_ctrl.dart';

// Event feature
import '../features/event/data/repositories/event_repo_impl.dart';
import '../features/event/domain/repositories/event_repo.dart';
import '../features/event/data/datasources/event_source.dart';
import '../features/event/presentation/controllers/event_ctrl.dart';

// Profile feature
import '../features/profile/data/datasources/profile_source.dart';
import '../features/profile/data/repositories/profile_repo_impl.dart';
import '../features/profile/domain/repositories/profile_repo.dart';
import '../features/profile/presentation/controllers/profile_ctrl.dart';

// Booking feature
import '../features/booking/data/repositories/booking_repo_impl.dart';
import '../features/booking/domain/repositories/booking_repo.dart';
import '../features/booking/presentation/controllers/booking_ctrl.dart';

// Skill feature
import '../features/skill/data/repositories/skill_repo_impl.dart';
import '../features/skill/domain/repositories/skill_repo.dart';
import '../features/skill/presentation/controllers/skill_ctrl.dart';

// Home feature
import '../features/home/presentation/controllers/trending_activity_ctrl.dart';
import 'package:tiermetry/core/services/api_service.dart';
import 'package:tiermetry/core/services/mock_api_service.dart';

class Locator {
  static final Locator _instance = Locator._();
  factory Locator() => _instance;
  Locator._();

  // Repos
  late final ArenaRepo arenaRepo = ArenaRepoImpl();
  late final EventRepo eventRepo = EventRepoImpl(EventSourceImpl());
  late final ProfileRepo profileRepo = ProfileRepoImpl(ProfileSourceImpl());
  late final BookingRepo bookingRepo = BookingRepoImpl(BookingSourceImpl());
  late final SkillRepo skillRepo = SkillRepoImpl(SkillSourceImpl());
  late final ApiService apiService = MockApiService();

  // UseCases
  late final GetArenasUC getArenasUC = GetArenasUC(arenaRepo);
  late final GetArenaDetailsUC getArenaDetailsUC = GetArenaDetailsUC(arenaRepo);

  // Controllers
  late final ArenaCtrl arenaCtrl = ArenaCtrl(
    getArenasUC: getArenasUC,
    getArenaDetailsUC: getArenaDetailsUC,
  );
  late final EventCtrl eventCtrl = EventCtrl(eventRepo);
  late final ProfileCtrl profileCtrl = ProfileCtrl(profileRepo);
  late final BookingCtrl bookingCtrl = BookingCtrl(bookingRepo);
  late final SkillCtrl skillCtrl = SkillCtrl(skillRepo);
  late final TrendingActivityCtrl trendingActivityCtrl = TrendingActivityCtrl(
    apiService: apiService,
  );
}

final locator = Locator();
