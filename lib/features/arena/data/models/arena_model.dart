import '../../domain/entities/arena_details_entity.dart';
import '../../domain/entities/arena_entity.dart';

class ArenaModel extends ArenaEntity {
  ArenaModel({
    required super.id,
    required super.name,
    required super.image,
    required super.rating,
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
  });

  factory ArenaModel.fromJson(Map<String, dynamic> json) {
    return ArenaModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      image: json['cover_image'] as String? ?? '',
      rating: (json['rating'] as num? ?? 0.0).toDouble(),
      capacity: json['capacity'] as int? ?? 0,
      location: json['address'] as String? ?? '',
      screenCount: json['screen_count'] as int? ?? 0,
      activity: ArenaActivity.values.firstWhere(
        (e) => e.name == (json['activity'] as String?),
        orElse: () => ArenaActivity.gaming,
      ),
      shortAddress: json['short_address'] as String? ?? '',
      hours: json['hours'] as String? ?? '',
      isOpen: json['is_open'] as bool? ?? false,
      distance: (json['distance'] as num? ?? 0.0).toDouble(),
      priceTier: json['price_tier'] as int? ?? 0,
      isVerified: json['is_verified'] as bool? ?? false,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ArenaDeviceModel extends ArenaDevice {
  ArenaDeviceModel({
    required super.id,
    required super.name,
    required super.desc,
    required super.price,
    required super.image,
    super.isOccupied,
  });

  factory ArenaDeviceModel.fromJson(Map<String, dynamic> json) {
    return ArenaDeviceModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      desc: json['description'] as String? ?? '',
      price: (json['price'] as num? ?? 0).toInt(),
      image: json['image'] as String? ?? '',
      isOccupied: json['is_occupied'] as bool? ?? false,
    );
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
  });

  factory ArenaDetailsModel.fromJson(Map<String, dynamic> json) {
    final activity = ArenaActivity.values.firstWhere(
      (e) => e.name == (json['activity'] as String?),
      orElse: () => ArenaActivity.gaming,
    );

    ArenaSpecs specs;
    final specsJson = json['specs'] as Map<String, dynamic>? ?? {};
    if (activity == ArenaActivity.gaming) {
      specs = GamingSpecs(
        resolution: specsJson['resolution'] as String? ?? '',
        refreshRate: specsJson['refresh_rate'] as String? ?? '',
        processor: specsJson['processor'] as String? ?? '',
        peripherals: specsJson['peripherals'] as String? ?? '',
        graphicsCard: specsJson['graphics_card'] as String? ?? '',
      );
    } else {
      specs = TurfSpecs(
        surface: specsJson['surface'] as String? ?? '',
        size: specsJson['size'] as String? ?? '',
        lighting: specsJson['lighting'] as String? ?? '',
        facilities: specsJson['facilities'] as String? ?? '',
      );
    }

    return ArenaDetailsModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      image: json['cover_image'] as String? ?? '',
      rating: (json['rating'] as num? ?? 0.0).toDouble(),
      capacity: json['capacity'] as int? ?? 0,
      location: json['address'] as String? ?? '',
      screenCount: json['screen_count'] as int? ?? 0,
      activity: activity,
      shortAddress: json['short_address'] as String? ?? '',
      hours: json['hours'] as String? ?? '',
      isOpen: json['is_open'] as bool? ?? false,
      distance: (json['distance'] as num? ?? 0.0).toDouble(),
      priceTier: json['price_tier'] as int? ?? 0,
      isVerified: json['is_verified'] as bool? ?? false,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      desc: json['description'] as String? ?? '',
      tags: List<String>.from((json['tags'] as Iterable?) ?? []),
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
    );
  }
}
