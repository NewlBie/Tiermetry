enum ArenaActivity { gaming, arcade, recreational }

class ArenaEntity {
  final String id;
  final String name;
  final String image;
  final double rating;
  final int capacity;
  final String location;
  final int screenCount;
  final ArenaActivity activity;
  final String shortAddress;
  final String hours;
  final bool isOpen;
  final double distance;
  final int priceTier;
  final bool isVerified;
  final double latitude;
  final double longitude;

  ArenaEntity({
    required this.id,
    required this.name,
    required this.image,
    required this.rating,
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
  });

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
