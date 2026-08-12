import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiermetry/core/services/api_service.dart';
import 'package:tiermetry/core/services/mock_api_service.dart';

import '../features/arena/data/repositories/arena_repo_impl.dart';
import '../features/arena/domain/repositories/arena_repo.dart';
import '../features/arena/domain/usecases/get_arena_details_uc.dart';
import '../features/arena/domain/usecases/get_arenas_uc.dart';
import '../features/arena/domain/usecases/get_available_units_uc.dart';
import '../features/arena/presentation/controllers/arena_ctrl.dart';
import '../features/auth/data/repositories/auth_repo_impl.dart';
import '../features/auth/domain/repositories/auth_repo.dart';
import '../features/auth/presentation/controllers/auth_ctrl.dart';
import '../features/booking/data/repositories/booking_repo_impl.dart';
import '../features/booking/domain/repositories/booking_repo.dart';
import '../features/booking/presentation/controllers/booking_ctrl.dart';
import '../features/event/data/repositories/event_repo_impl.dart';
import '../features/event/domain/repositories/event_repo.dart';
import '../features/event/presentation/controllers/event_ctrl.dart';
import '../features/home/presentation/controllers/trending_activity_ctrl.dart';
import '../features/payment/data/datasources/development_payment_provider.dart';
import '../features/payment/data/repositories/payment_repo_impl.dart';
import '../features/payment/domain/repositories/payment_provider.dart';
import '../features/payment/domain/repositories/payment_repo.dart';
import '../features/payment/presentation/controllers/payment_ctrl.dart';
import '../features/profile/data/repositories/profile_repo_impl.dart';
import '../features/profile/domain/repositories/profile_repo.dart';
import '../features/profile/presentation/controllers/profile_ctrl.dart';
import '../features/skill/data/repositories/skill_repo_impl.dart';
import '../features/skill/domain/repositories/skill_repo.dart';
import '../features/skill/presentation/controllers/skill_ctrl.dart';

class Locator {
  static final Locator _instance = Locator._();
  factory Locator() => _instance;
  Locator._();

  // Supabase
  final SupabaseClient supabase = Supabase.instance.client;

  // Repos
  late final ArenaRepo arenaRepo = ArenaRepoImpl(supabase);
  late final EventRepo eventRepo = EventRepoImpl(supabase);
  late final ProfileRepo profileRepo = ProfileRepoImpl(supabase);
  late final BookingRepo bookingRepo = BookingRepoImpl(supabase);
  late final SkillRepo skillRepo = SkillRepoImpl(SkillSourceImpl());
  late final AuthRepo authRepo = AuthRepoImpl(supabase);
  late final ApiService apiService = MockApiService();
  
  // Payment
  late final PaymentProvider paymentProvider = DevelopmentPaymentProvider();
  late final PaymentRepo paymentRepo = PaymentRepoImpl(supabase, paymentProvider);

  // UseCases
  late final GetArenasUC getArenasUC = GetArenasUC(arenaRepo);
  late final GetArenaDetailsUC getArenaDetailsUC = GetArenaDetailsUC(arenaRepo);
  late final GetAvailableUnitsUC getAvailableUnitsUC = GetAvailableUnitsUC(arenaRepo);

  // Controllers
  late final ArenaCtrl arenaCtrl = ArenaCtrl(
    getArenasUC: getArenasUC,
    getArenaDetailsUC: getArenaDetailsUC,
    getAvailableUnitsUC: getAvailableUnitsUC,
  );
  late final EventCtrl eventCtrl = EventCtrl(eventRepo);
  late final ProfileCtrl profileCtrl = ProfileCtrl(profileRepo);
  late final BookingCtrl bookingCtrl = BookingCtrl(bookingRepo);
  late final SkillCtrl skillCtrl = SkillCtrl(skillRepo);
  late final PaymentCtrl paymentCtrl = PaymentCtrl(
    repo: paymentRepo,
    provider: paymentProvider,
  );
  late final AuthCtrl authCtrl = AuthCtrl(authRepo);
  late final TrendingActivityCtrl trendingActivityCtrl = TrendingActivityCtrl(
    apiService: apiService,
  );
}

final locator = Locator();
