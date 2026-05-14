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
      id: json['id'],
      name: json['name'],
      image: json['image'],
      rating: (json['rating'] as num).toDouble(),
      capacity: json['capacity'],
      location: json['location'],
      screenCount: json['screenCount'],
      activity: ArenaActivity.values.firstWhere(
        (e) => e.name == json['activity'],
        orElse: () => ArenaActivity.gaming,
      ),
      shortAddress: json['shortAddress'],
      hours: json['hours'],
      isOpen: json['isOpen'],
      distance: (json['distance'] as num).toDouble(),
      priceTier: json['priceTier'],
      isVerified: json['isVerified'],
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'rating': rating,
      'capacity': capacity,
      'location': location,
      'screenCount': screenCount,
      'activity': activity.name,
      'shortAddress': shortAddress,
      'hours': hours,
      'isOpen': isOpen,
      'distance': distance,
      'priceTier': priceTier,
      'isVerified': isVerified,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
