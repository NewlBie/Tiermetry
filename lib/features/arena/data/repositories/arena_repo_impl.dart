import 'dart:math' as math;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/arena_details_entity.dart';
import '../../domain/entities/arena_entity.dart';
import '../../domain/repositories/arena_repo.dart';
import '../models/arena_model.dart';
import '../models/mock_arena_data.dart';

class ArenaRepoImpl implements ArenaRepo {
  final SupabaseClient _supabase;
  final ({double latitude, double longitude})? Function()? _originProvider;

  ArenaRepoImpl(
    this._supabase, {
    ({double latitude, double longitude})? Function()? originProvider,
  }) : _originProvider = originProvider;

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
        'id, name, cover_image, images, rating, review_count, address, city, state, pin_code, activity, short_address, hours, schedule, is_open, price_tier, is_verified, latitude, longitude, services(name)';
    var supabaseQuery = _supabase.from('venues').select(listColumns);
    supabaseQuery = supabaseQuery.eq('is_listed', true);

    if (query != null && query.isNotEmpty) {
      final safeQuery = query.replaceAll(RegExp(r'[%_,().:*\\]'), ' ').trim();
      if (safeQuery.isEmpty) return const [];
      supabaseQuery = supabaseQuery.or(
        'name.ilike.%$safeQuery%,short_address.ilike.%$safeQuery%,activity.ilike.%$safeQuery%',
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

    final requiresClientWindow =
        onlyOpenNow == true || maxDistance != null || sortBy == 'Distance';
    final response = await finalQuery
        .order('id', ascending: true)
        .range(
          requiresClientWindow ? 0 : page * pageSize,
          requiresClientWindow ? 999 : (page + 1) * pageSize - 1,
        );

    final origin = _originProvider?.call();
    var arenas =
        (response as List)
            .map(
              (json) => ArenaModel.fromJson(
                json as Map<String, dynamic>,
                originLatitude: origin?.latitude,
                originLongitude: origin?.longitude,
              ),
            )
            .toList();

    if (onlyOpenNow == true) {
      arenas = arenas.where((arena) => arena.isOpenNow).toList();
    }
    if (maxDistance != null) {
      arenas =
          arenas
              .where(
                (arena) =>
                    arena.distance != null && arena.distance! <= maxDistance,
              )
              .toList();
    }
    if (sortBy == 'Distance') {
      arenas.sort((left, right) {
        final leftDistance = left.distance ?? double.infinity;
        final rightDistance = right.distance ?? double.infinity;
        final byDistance = leftDistance.compareTo(rightDistance);
        return byDistance != 0 ? byDistance : left.name.compareTo(right.name);
      });
    }
    if (requiresClientWindow) {
      final start = page * pageSize;
      if (start >= arenas.length) return const [];
      final end = math.min(start + pageSize, arenas.length);
      return arenas.sublist(start, end);
    }
    return arenas;
  }

  @override
  Future<ArenaDetailsEntity?> getArenaDetails(String id) async {
    if (id == 'mock-test-arena') {
      return getMockArenaDetails();
    }

    final responses = await Future.wait<dynamic>([
      _supabase
          .from('venues')
          .select(
            'id, name, description, address, city, state, pin_code, latitude, longitude, rating, review_count, cover_image, activity, short_address, hours, is_open, price_tier, is_verified, internet, amenity, specs, rules, contact_phone, has_ac, has_power_backup, game_library, cancellation_policy, schedule, images, services(id, name, service_units(id, name, description, price, image, status, sessions(id, status, scheduled_start_at, scheduled_end_at), service_unit_accessories(id, name, included_quantity, billing_type, billing_interval_minutes, unit_price)))',
          )
          .eq('id', id)
          .eq('is_listed', true)
          .maybeSingle(),
      _supabase
          .from('venue_reviews')
          .select('id, rating, comment, highlights, created_at')
          .eq('venue_id', id)
          .eq('is_published', true)
          .order('created_at', ascending: false)
          .limit(12),
    ]);
    final response = responses.first as Map<String, dynamic>?;
    if (response == null) return null;
    response['venue_reviews'] = responses.last;

    final origin = _originProvider?.call();
    return ArenaDetailsModel.fromJson(
      response,
      originLatitude: origin?.latitude,
      originLongitude: origin?.longitude,
    );
  }

  @override
  Future<List<ArenaDevice>> getAvailableUnits({
    required String serviceId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final response = await _supabase.rpc<List<dynamic>>(
      'get_bookable_unit_choices',
      params: {
        'p_service_id': serviceId,
        'p_start_time': startTime.toUtc().toIso8601String(),
        'p_end_time': endTime.toUtc().toIso8601String(),
      },
    );

    final units =
        response
            .whereType<Map<String, dynamic>>()
            .map(Map<String, dynamic>.from)
            .toList();
    if (units.isEmpty) return const [];

    final accessories = await _supabase
        .from('service_unit_accessories')
        .select(
          'id, service_unit_id, name, included_quantity, billing_type, billing_interval_minutes, unit_price',
        )
        .eq('is_active', true)
        .inFilter('service_unit_id', units.map((unit) => unit['id']).toList());
    final accessoriesByUnit = <String, List<Map<String, dynamic>>>{};
    for (final accessory in accessories) {
      final row = Map<String, dynamic>.from(accessory);
      final unitId = row['service_unit_id'] as String?;
      if (unitId == null) continue;
      (accessoriesByUnit[unitId] ??= []).add(row);
    }

    return units.map<ArenaDevice>((unit) {
      unit['service_unit_accessories'] =
          accessoriesByUnit[unit['id'] as String] ?? const [];
      return ArenaDeviceModel.fromJson(unit);
    }).toList();
  }

  @override
  Future<DateTime?> getNextAvailableBookingStart({
    required String serviceId,
    required Duration duration,
    required DateTime fromTime,
  }) async {
    final response = await _supabase.rpc<dynamic>(
      'get_next_available_booking_start',
      params: {
        'p_service_id': serviceId,
        'p_duration_minutes': duration.inMinutes,
        'p_from_time': fromTime.toUtc().toIso8601String(),
      },
    );
    if (response is! String || response.isEmpty) return null;
    return DateTime.parse(response).toLocal();
  }
}
