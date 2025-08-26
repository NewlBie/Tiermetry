enum MainActivity { gaming, arcade, recreational }

class Arena {
  final String id;
  final String name;
  final String image;
  final double rating;
  final int capacity;
  final String location;
  final int screenCount;
  final MainActivity mainActivity;
  final String shortAddress;
  final String hours;
  final bool isOpen;
  final double distance;
  final int priceTier;
  final bool isVerified; // Add this line

  Arena({
    required this.id,
    required this.name,
    required this.image,
    required this.rating,
    required this.capacity,
    required this.location,
    required this.screenCount,
    required this.mainActivity,
    required this.shortAddress,
    required this.hours,
    required this.isOpen,
    required this.distance,
    required this.priceTier,
    required this.isVerified, // Add this line to the constructor
  });

  String get mainActivityDisplay {
    switch (mainActivity) {
      case MainActivity.gaming:
        return 'Gaming';
      case MainActivity.arcade:
        return 'Arcade';
      case MainActivity.recreational:
        return 'Recreational';
      default:
        return '';
    }
  }
}