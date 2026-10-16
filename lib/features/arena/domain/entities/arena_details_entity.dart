import 'arena_entity.dart';

abstract class ArenaSpecs {}

class DynamicSpecs extends ArenaSpecs {
  final Map<String, dynamic> specs;
  DynamicSpecs(this.specs);
}

class ArenaDevice {
  final String id;
  final String name;
  final String desc;
  final double price;
  final Map<String, double> dayPrices;
  final String image;
  final bool isOccupied;
  final DateTime? occupiedTill;
  final DateTime? nextBookingAt;
  final List<ArenaAccessory> accessories;
  final String availabilityStatus;

  ArenaDevice({
    required this.id,
    required this.name,
    required this.desc,
    required this.price,
    required this.image,
    this.dayPrices = const {},
    this.isOccupied = false,
    this.occupiedTill,
    this.nextBookingAt,
    this.accessories = const [],
    this.availabilityStatus = 'available',
  });

  bool get isBookable => availabilityStatus == 'available';
  bool get isMaintenance => availabilityStatus == 'maintenance';

  /// The owner-configured rate for this unit on the selected Indian calendar
  /// day. The base price remains the fallback for older inventory records.
  double priceFor(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return dayPrices[days[date.weekday - 1]] ?? price;
  }

  String get priceRangeLabel {
    if (dayPrices.isEmpty) return '₹${price.toStringAsFixed(0)}';
    final rates = [...dayPrices.values, price];
    final lowest = rates.reduce((a, b) => a < b ? a : b);
    final highest = rates.reduce((a, b) => a > b ? a : b);
    if (lowest == highest) return '₹${lowest.toStringAsFixed(0)}';
    return '₹${lowest.toStringAsFixed(0)}–₹${highest.toStringAsFixed(0)}';
  }
}

class ArenaAccessory {
  final String id;
  final String name;
  final int includedQuantity;
  final String billingType;
  final int billingIntervalMinutes;
  final double unitPrice;

  const ArenaAccessory({
    required this.id,
    required this.name,
    required this.includedQuantity,
    required this.billingType,
    required this.billingIntervalMinutes,
    required this.unitPrice,
  });

  bool get isTimeBased => billingType == 'time_based';
}

class ArenaDeviceCat {
  final String id;
  final String name;
  final List<ArenaDevice> units;

  ArenaDeviceCat({required this.id, required this.name, required this.units});
}

class ArenaReview {
  final String id;
  final int rating;
  final String? comment;
  final List<String> highlights;
  final DateTime createdAt;

  const ArenaReview({
    required this.id,
    required this.rating,
    required this.comment,
    required this.highlights,
    required this.createdAt,
  });
}

class ArenaDetailsEntity extends ArenaEntity {
  final String desc;
  final int reviews;
  final double score;
  final String internet;
  final String amenity;
  final ArenaSpecs specs;
  final List<ArenaDeviceCat> devices;
  final List<String> rules;
  final String contactPhone;
  final bool hasAC;
  final bool hasPowerBackup;
  final List<String> gameLibrary;
  final String cancellationPolicy;
  final List<ArenaReview> reviewItems;

  ArenaDetailsEntity({
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
    required this.desc,
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
    required this.reviewItems,
  });
}
