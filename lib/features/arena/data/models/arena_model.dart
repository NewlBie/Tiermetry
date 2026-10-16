import 'dart:convert';
import 'dart:math' as math;

import '../../domain/entities/arena_details_entity.dart';
import '../../domain/entities/arena_entity.dart';

class ArenaModel extends ArenaEntity {
  ArenaModel({
    required super.id,
    required super.name,
    required super.image,
    required super.rating,
    required super.reviewCount,
    required super.capacity,
    required super.location,
    required super.screenCount,
    required super.activity,
    required super.shortAddress,
    required super.hours,
    required super.isOpen,
    required super.distance,
    required super.priceTier,
    required super.isVerified,
    required super.latitude,
    required super.longitude,
    required super.images,
    required super.tags,
    required super.schedule,
  });

  factory ArenaModel.fromJson(
    Map<String, dynamic> json, {
    double? originLatitude,
    double? originLongitude,
  }) {
    final images = _parseImages(json['images']);
    final coverImage = json['cover_image']?.toString().trim() ?? '';
    final latitude = (json['latitude'] as num?)?.toDouble() ?? 0.0;
    final longitude = (json['longitude'] as num?)?.toDouble() ?? 0.0;
    return ArenaModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      image:
          coverImage.isNotEmpty
              ? coverImage
              : (images.isEmpty ? '' : images.first),
      rating: (json['rating'] as num? ?? 0.0).toDouble(),
      reviewCount: json['review_count'] as int? ?? 0,
      capacity: json['capacity'] as int? ?? 0,
      location: composeFullAddress(json),
      screenCount: json['screen_count'] as int? ?? 0,
      activity: ArenaActivity.values.firstWhere(
        (e) => e.name == (json['activity'] as String?),
        orElse: () => ArenaActivity.gaming,
      ),
      shortAddress: json['short_address'] as String? ?? '',
      hours: json['hours'] as String? ?? '',
      isOpen: json['is_open'] as bool? ?? false,
      distance: _distanceFromJson(
        json,
        latitude: latitude,
        longitude: longitude,
        originLatitude: originLatitude,
        originLongitude: originLongitude,
      ),
      priceTier: json['price_tier'] as int? ?? 0,
      isVerified: json['is_verified'] as bool? ?? false,
      latitude: latitude,
      longitude: longitude,
      images: images,
      tags: _parseTags(json['services']),
      schedule: _parseMap(json['schedule']),
    );
  }

  static List<String> _parseImages(dynamic value) {
    if (value is! Iterable) return const [];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static Map<String, dynamic> _parseMap(dynamic value) {
    if (value is! Map) return const {};
    return Map<String, dynamic>.from(value);
  }

  static double? _distanceFromJson(
    Map<String, dynamic> json, {
    required double latitude,
    required double longitude,
    required double? originLatitude,
    required double? originLongitude,
  }) {
    final serverDistance = (json['distance'] as num?)?.toDouble();
    if (serverDistance != null && serverDistance.isFinite) {
      return serverDistance;
    }
    if (originLatitude == null ||
        originLongitude == null ||
        (latitude.abs() < 0.000001 && longitude.abs() < 0.000001)) {
      return null;
    }

    const earthRadiusKm = 6371.0088;
    double radians(double value) => value * math.pi / 180;
    final dLat = radians(latitude - originLatitude);
    final dLng = radians(longitude - originLongitude);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(radians(originLatitude)) *
            math.cos(radians(latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static String composeFullAddress(Map<String, dynamic> json) {
    final parts = <String>[];

    void addIfMissing(dynamic value) {
      final part = value?.toString().trim() ?? '';
      if (part.isEmpty) return;

      final current = parts.join(', ').toLowerCase();
      if (!current.contains(part.toLowerCase())) {
        parts.add(part);
      }
    }

    addIfMissing(json['address']);
    addIfMissing(json['city']);
    addIfMissing(json['state']);
    addIfMissing(json['pin_code']);

    return parts.join(', ');
  }

  static List<String> _parseTags(dynamic servicesJson) {
    if (servicesJson == null || servicesJson is! List) return [];

    return servicesJson
        .map((s) => s['name']?.toString())
        .where((name) => name != null && name.isNotEmpty)
        .cast<String>()
        .toList();
  }
}

class ArenaDeviceModel extends ArenaDevice {
  ArenaDeviceModel({
    required super.id,
    required super.name,
    required super.desc,
    required super.price,
    required super.image,
    super.dayPrices,
    super.isOccupied,
    super.occupiedTill,
    super.nextBookingAt,
    super.accessories,
    super.availabilityStatus,
  });

  factory ArenaDeviceModel.fromJson(Map<String, dynamic> json) {
    final sessions = json['sessions'] as List<dynamic>? ?? [];
    final now = DateTime.now();
    bool isOccupied = false;
    DateTime? occupiedTill;
    DateTime? nextBookingAt;

    for (final sessionData in sessions) {
      if (sessionData is! Map<String, dynamic>) continue;
      final status = sessionData['status'] as String?;
      final scheduledStart =
          sessionData['scheduled_start_at'] != null
              ? DateTime.tryParse(
                sessionData['scheduled_start_at'] as String,
              )?.toLocal()
              : null;
      final scheduledEnd =
          sessionData['scheduled_end_at'] != null
              ? DateTime.tryParse(
                sessionData['scheduled_end_at'] as String,
              )?.toLocal()
              : null;

      if (status == 'active') {
        isOccupied = true;
        if (scheduledEnd != null) {
          if (occupiedTill == null || scheduledEnd.isAfter(occupiedTill)) {
            occupiedTill = scheduledEnd;
          }
        }
      } else if (status == 'not_started' || status == 'checked_in') {
        if (scheduledStart != null && scheduledStart.isAfter(now)) {
          if (nextBookingAt == null || scheduledStart.isBefore(nextBookingAt)) {
            nextBookingAt = scheduledStart;
          }
        }
      }
    }

    return ArenaDeviceModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      desc: json['description'] as String? ?? '',
      price: (json['price'] as num? ?? 0).toDouble(),
      dayPrices: _dayPricesFromDescription(json['description']),
      image: json['image'] as String? ?? '',
      isOccupied: isOccupied,
      occupiedTill: occupiedTill,
      nextBookingAt: nextBookingAt,
      accessories:
          (json['service_unit_accessories'] as List? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(
                (accessory) => ArenaAccessory(
                  id: accessory['id'] as String? ?? '',
                  name: accessory['name'] as String? ?? 'Accessory',
                  includedQuantity:
                      (accessory['included_quantity'] as num? ?? 0).toInt(),
                  billingType: accessory['billing_type'] as String? ?? 'fixed',
                  billingIntervalMinutes:
                      (accessory['billing_interval_minutes'] as num? ?? 60)
                          .toInt(),
                  unitPrice: (accessory['unit_price'] as num? ?? 0).toDouble(),
                ),
              )
              .where((accessory) => accessory.id.isNotEmpty)
              .toList(),
      availabilityStatus:
          json['availability_status'] as String? ??
          json['status'] as String? ??
          'available',
    );
  }

  static Map<String, double> _dayPricesFromDescription(dynamic description) {
    if (description is! String || description.trim().isEmpty) return const {};

    try {
      final decoded = jsonDecode(description);
      if (decoded is! Map) return const {};
      final dayPricing = decoded['dayPricing'];
      if (dayPricing is! Map) return const {};

      final isTieredMode = dayPricing['isTieredMode'] == true;
      final flatPrices = dayPricing['flatPrices'];
      if (!isTieredMode && flatPrices is Map) {
        return flatPrices.map<String, double>((day, value) {
          return MapEntry(day.toString(), (value as num).toDouble());
        });
      }

      // Tiered pricing is per player. Until a player count is selected, use
      // the one-player rate for the availability-card preview.
      final tieredMatrix = dayPricing['tieredMatrix'];
      if (tieredMatrix is Map) {
        final result = <String, double>{};
        for (final entry in tieredMatrix.entries) {
          final players = entry.value;
          if (players is Map && players['1'] is num) {
            result[entry.key.toString()] = (players['1'] as num).toDouble();
          }
        }
        return result;
      }
    } catch (_) {
      // Legacy units may have free-text descriptions rather than rate JSON.
    }
    return const {};
  }
}

class ArenaDeviceCatModel extends ArenaDeviceCat {
  ArenaDeviceCatModel({
    required super.id,
    required super.name,
    required super.units,
  });

  factory ArenaDeviceCatModel.fromJson(Map<String, dynamic> json) {
    return ArenaDeviceCatModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      units:
          (json['service_units'] as List? ?? [])
              .map((e) => ArenaDeviceModel.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}

class ArenaDetailsModel extends ArenaDetailsEntity {
  ArenaDetailsModel({
    required super.id,
    required super.name,
    required super.image,
    required super.rating,
    required super.reviewCount,
    required super.capacity,
    required super.location,
    required super.screenCount,
    required super.activity,
    required super.shortAddress,
    required super.hours,
    required super.isOpen,
    required super.distance,
    required super.priceTier,
    required super.isVerified,
    required super.latitude,
    required super.longitude,
    required super.images,
    required super.desc,
    required super.tags,
    required super.reviews,
    required super.score,
    required super.internet,
    required super.amenity,
    required super.specs,
    required super.devices,
    required super.rules,
    required super.contactPhone,
    required super.hasAC,
    required super.hasPowerBackup,
    required super.gameLibrary,
    required super.cancellationPolicy,
    required super.schedule,
    required super.reviewItems,
  });

  factory ArenaDetailsModel.fromJson(
    Map<String, dynamic> json, {
    double? originLatitude,
    double? originLongitude,
  }) {
    final activity = ArenaActivity.values.firstWhere(
      (e) => e.name == (json['activity'] as String?),
      orElse: () => ArenaActivity.gaming,
    );

    final specsJson = json['specs'] as Map<String, dynamic>? ?? {};
    final ArenaSpecs specs = DynamicSpecs(specsJson);

    final base = ArenaModel.fromJson(
      json,
      originLatitude: originLatitude,
      originLongitude: originLongitude,
    );
    return ArenaDetailsModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      image: base.image,
      rating: (json['rating'] as num? ?? 0.0).toDouble(),
      reviewCount: json['review_count'] as int? ?? 0,
      capacity: json['capacity'] as int? ?? 0,
      location: ArenaModel.composeFullAddress(json),
      screenCount: json['screen_count'] as int? ?? 0,
      activity: activity,
      shortAddress: json['short_address'] as String? ?? '',
      hours: json['hours'] as String? ?? '',
      isOpen: json['is_open'] as bool? ?? false,
      distance: base.distance,
      priceTier: json['price_tier'] as int? ?? 0,
      isVerified: json['is_verified'] as bool? ?? false,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      images: base.images,
      desc: json['description'] as String? ?? '',
      tags: base.tags,
      reviews: json['review_count'] as int? ?? 0,
      score: (json['score'] as num? ?? 0.0).toDouble(),
      internet: json['internet'] as String? ?? '',
      amenity: json['amenity'] as String? ?? '',
      specs: specs,
      devices:
          (json['services'] as List? ?? [])
              .map(
                (e) => ArenaDeviceCatModel.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      rules: List<String>.from((json['rules'] as Iterable?) ?? []),
      contactPhone: json['contact_phone'] as String? ?? '',
      hasAC: json['has_ac'] as bool? ?? false,
      hasPowerBackup: json['has_power_backup'] as bool? ?? false,
      gameLibrary: List<String>.from((json['game_library'] as Iterable?) ?? []),
      cancellationPolicy: json['cancellation_policy'] as String? ?? '',
      schedule: base.schedule,
      reviewItems: (json['venue_reviews'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(
            (review) => ArenaReview(
              id: review['id']?.toString() ?? '',
              rating: review['rating'] as int? ?? 0,
              comment: review['comment'] as String?,
              highlights: (review['highlights'] as List? ?? const [])
                  .map((item) => item.toString())
                  .toList(growable: false),
              createdAt:
                  DateTime.tryParse(
                    review['created_at']?.toString() ?? '',
                  )?.toLocal() ??
                  DateTime.now(),
            ),
          )
          .toList(growable: false),
    );
  }
}
