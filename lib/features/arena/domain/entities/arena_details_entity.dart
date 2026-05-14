import 'arena_entity.dart';

abstract class ArenaSpecs {}

class GamingSpecs extends ArenaSpecs {
  final String resolution;
  final String refreshRate;
  final String processor;
  final String peripherals;
  final String graphicsCard;

  GamingSpecs({
    required this.resolution,
    required this.refreshRate,
    required this.processor,
    required this.peripherals,
    required this.graphicsCard,
  });
}

class TurfSpecs extends ArenaSpecs {
  final String surface;
  final String size;
  final String lighting;
  final String facilities;

  TurfSpecs({
    required this.surface,
    required this.size,
    required this.lighting,
    required this.facilities,
  });
}

class Device {
  final String id;
  final String name;
  final String desc;
  final int price;
  final String image;
  final bool isOccupied;

  Device({
    required this.id,
    required this.name,
    required this.desc,
    required this.price,
    required this.image,
    this.isOccupied = false,
  });
}

class DeviceCat {
  final String name;
  final List<Device> units;

  DeviceCat({required this.name, required this.units});
}

class ArenaDetailsEntity extends ArenaEntity {
  final String desc;
  final List<String> tags;
  final int reviews;
  final double score;
  final String internet;
  final String amenity;
  final ArenaSpecs specs;
  final List<DeviceCat> devices;
  final List<String> rules;
  final String contactPhone;
  final bool hasAC;
  final bool hasPowerBackup;
  final List<String> gameLibrary;
  final String cancellationPolicy;

  ArenaDetailsEntity({
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
    required this.desc,
    required this.tags,
    required this.reviews,
    required this.score,
    required this.internet,
    required this.amenity,
    required this.specs,
    required this.devices,
    required this.rules,
    required this.contactPhone,
    required this.hasAC,
    required this.hasPowerBackup,
    required this.gameLibrary,
    required this.cancellationPolicy,
  });
}
