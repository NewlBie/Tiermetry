import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/arena_details_entity.dart';
import '../../domain/entities/arena_entity.dart';
import '../../domain/repositories/arena_repo.dart';
import '../models/arena_model.dart';
import '../models/mock_arena_data.dart';

class ArenaRepoImpl implements ArenaRepo {
  final SupabaseClient _supabase;

  ArenaRepoImpl(this._supabase);

  @override
  Future<List<ArenaEntity>> getArenas({
    String? query,
    String? activity,
    double? maxDistance,
    int? maxPriceTier,
    double? minRating,
    Set<String>? platforms,
    bool? onlyOpenNow,
    bool? hasOffers,
    String? sortBy,
    int page = 0,
    int pageSize = 20,
  }) async {
    const listColumns =
        'id, name, cover_image, rating, address, activity, short_address, hours, is_open, price_tier, is_verified, latitude, longitude';
    var supabaseQuery = _supabase.from('venues').select(listColumns);

    if (query != null && query.isNotEmpty) {
      supabaseQuery = supabaseQuery.or(
        'name.ilike.%$query%,short_address.ilike.%$query%,activity.ilike.%$query%',
      );
    }

    if (activity != null && activity != 'All') {
      final activityValue = switch (activity) {
        'Gaming cafes' => 'gaming',
        'Turfs' => 'recreational',
        'Paintball' => 'arcade',
        'Karting' => 'recreational',
        _ => null,
      };
      if (activityValue != null) {
        supabaseQuery = supabaseQuery.eq('activity', activityValue);
      }
    }

    if (maxPriceTier != null) {
      supabaseQuery = supabaseQuery.lte('price_tier', maxPriceTier);
    }

    if (onlyOpenNow == true) {
      supabaseQuery = supabaseQuery.eq('is_open', true);
    }

    if (minRating != null) {
      supabaseQuery = supabaseQuery.gte('rating', minRating);
    }

    // Platform, amenities, hasOffers could be complex depending on schema. 
    // We will do basic filtering if the columns exist or skip them if not yet supported in DB schema.
    // For now, let's assume they are handled by DB or skipped. (We're focusing on UI/Controller flow).
    // If platforms was an array column: 
    // if (platforms != null && platforms.isNotEmpty) {
    //   supabaseQuery = supabaseQuery.contains('platforms', platforms.toList());
    // }

    // Sorting and pagination
    dynamic finalQuery = supabaseQuery;

    if (sortBy != null) {
      switch (sortBy) {
        case 'Distance':
          // Assuming distance is handled via a DB function, or client side. For now, order by name.
          finalQuery = finalQuery.order('name', ascending: true);
          break;
        case 'Rating':
          finalQuery = finalQuery.order('rating', ascending: false);
          break;
        case 'Price: Low → High':
          finalQuery = finalQuery.order('price_tier', ascending: true);
          break;
        case 'Price: High → Low':
          finalQuery = finalQuery.order('price_tier', ascending: false);
          break;
        case 'Popularity':
          finalQuery = finalQuery.order('review_count', ascending: false);
          break;
        case 'Newest':
          finalQuery = finalQuery.order('created_at', ascending: false);
          break;
        case 'Recommended':
        default:
          finalQuery = finalQuery.order('rating', ascending: false);
          break;
      }
    } else {
      finalQuery = finalQuery.order('rating', ascending: false);
    }

    final response = await finalQuery
        .order('id', ascending: true)
        .range(page * pageSize, (page + 1) * pageSize - 1);

    return (response as List)
        .map((json) => ArenaModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ArenaDetailsEntity?> getArenaDetails(String id) async {
    if (id == 'mock-test-arena') {
      return getMockArenaDetails();
    }

    final response =
        await _supabase
            .from('venues')
            .select('*, services(*, service_units(*))')
            .eq('id', id)
            .single();

    return ArenaDetailsModel.fromJson(response);
  }

  @override
  Future<List<ArenaDevice>> getAvailableUnits({
    required String serviceId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final response = await _supabase.rpc<List<dynamic>>(
      'get_available_units',
      params: {
        'p_service_id': serviceId,
        'p_start_time': startTime.toUtc().toIso8601String(),
        'p_end_time': endTime.toUtc().toIso8601String(),
      },
    );

    return response
        .map<ArenaDevice>(
          (json) => ArenaDeviceModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }
}
