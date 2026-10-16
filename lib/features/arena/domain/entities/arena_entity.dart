import '../services/arena_operating_hours.dart';

enum ArenaActivity { gaming, arcade, recreational }

class ArenaEntity {
  final String id;
  final String name;
  final String image;
  final double rating;
  final int reviewCount;
  final int capacity;
  final String location;
  final int screenCount;
  final ArenaActivity activity;
  final String shortAddress;
  final String hours;
  final bool isOpen;
  final double? distance;
  final int priceTier;
  final bool isVerified;
  final double latitude;
  final double longitude;
  final List<String> images;
  final List<String> tags;
  final Map<String, dynamic> schedule;

  ArenaEntity({
    required this.id,
    required this.name,
    required this.image,
    required this.rating,
    required this.reviewCount,
    required this.capacity,
    required this.location,
    required this.screenCount,
    required this.activity,
    required this.shortAddress,
    required this.hours,
    required this.isOpen,
    required this.distance,
    required this.priceTier,
    required this.isVerified,
    required this.latitude,
    required this.longitude,
    required this.images,
    required this.tags,
    this.schedule = const {},
  });

  bool get isOpenNow =>
      ArenaOperatingHours.isOpenNow(schedule: schedule, fallback: isOpen);

  String get distanceLabel {
    final value = distance;
    if (value == null || !value.isFinite) return 'Enable location';
    if (value < 1) return '${(value * 1000).round()} m';
    return '${value.toStringAsFixed(value < 10 ? 1 : 0)} km';
  }

  List<String> get galleryImages {
    final result = <String>[];
    for (final value in <String>[image, ...images]) {
      final candidate = value.trim();
      if (candidate.isEmpty || result.contains(candidate)) continue;
      result.add(candidate);
    }
    return result;
  }

  bool get hasValidCoordinates {
    return latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        (latitude.abs() > 0.000001 || longitude.abs() > 0.000001);
  }

  String get activityLabel {
    switch (activity) {
      case ArenaActivity.gaming:
        return 'Gaming';
      case ArenaActivity.arcade:
        return 'Arcade';
      case ArenaActivity.recreational:
        return 'Turf/Court';
    }
  }
}
