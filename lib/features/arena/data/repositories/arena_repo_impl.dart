import '../../domain/entities/arena_entity.dart';
import '../../domain/entities/arena_details_entity.dart';
import '../../domain/repositories/arena_repo.dart';

class ArenaRepoImpl implements ArenaRepo {
  final List<ArenaEntity> _arenas = [
    ArenaEntity(
      id: 'arena_1',
      name: 'Vortex Gaming Lounge',
      image: 'assets/arena1.jpeg',
      rating: 4.8,
      capacity: 30,
      screenCount: 30,
      activity: ArenaActivity.gaming,
      shortAddress: 'Koramangala, Bangalore',
      location: 'Koramangala, Bangalore',
      hours: '10AM - 11PM',
      isOpen: true,
      distance: 2.5,
      priceTier: 2,
      isVerified: true,
      latitude: 12.9352,
      longitude: 77.6245,
    ),
    ArenaEntity(
      id: 'arena_2',
      name: 'Kicks on Fire Turf',
      image: 'assets/kart_arena.png',
      rating: 4.5,
      capacity: 2,
      screenCount: 0,
      activity: ArenaActivity.recreational,
      shortAddress: 'HSR Layout, Bangalore',
      location: 'HSR Layout, Bangalore',
      hours: '6AM - 12AM',
      isOpen: true,
      distance: 4.1,
      priceTier: 3,
      isVerified: true,
      latitude: 12.9141,
      longitude: 77.6302,
    ),
  ];

  final Map<String, ArenaDetailsEntity> _details = {
    'arena_1': ArenaDetailsEntity(
      id: 'arena_1',
      name: 'Vortex Gaming Lounge',
      image: 'assets/arena1.jpeg',
      rating: 4.8,
      capacity: 30,
      screenCount: 30,
      activity: ArenaActivity.gaming,
      shortAddress: 'Koramangala, Bangalore',
      location: 'Koramangala, Bangalore',
      hours: '10AM - 11PM',
      isOpen: true,
      distance: 2.5,
      priceTier: 2,
      isVerified: true,
      latitude: 12.9352,
      longitude: 77.6245,
      desc: 'A premier destination for high-end gaming. Featuring next-gen consoles, VR, and performance-tuned PCs. We offer a toxic-free environment with a dedicated staff ensuring a premium experience.',
      tags: ['Arcade', 'PS5', 'PC Gaming', 'VR Arena'],
      reviews: 412,
      score: 9.2,
      internet: 'Fiber Optic (500Mbps)',
      amenity: 'Lounge & Cafe',
      specs: GamingSpecs(
        resolution: 'Up to 4K',
        refreshRate: '120-240Hz',
        processor: 'Ryzen 7 / i7',
        peripherals: 'Logitech G Pro, Razer BlackWidow',
        graphicsCard: 'RTX 4080 / 3080',
      ),
      devices: [
        DeviceCat(
          name: 'PlayStation 5',
          units: [
            Device(
              id: 'ps5_1',
              name: 'Console 1',
              desc: 'FIFA, UFC 5',
              price: 120,
              image: 'assets/pc_card.png',
            ),
            Device(
              id: 'ps5_2',
              name: 'Console 2',
              desc: 'COD, Fortnite',
              price: 120,
              image: 'assets/pc_card.png',
              isOccupied: true,
            ),
          ],
        ),
      ],
      rules: ['No outside food', 'Please carry ID proof', 'Maintain silence in the lounge area'],
      contactPhone: '+91 9876543210',
      hasAC: true,
      hasPowerBackup: true,
      gameLibrary: ['Valorant', 'CS2', 'Dota 2', 'FIFA 24', 'Cyberpunk 2077', 'Spider-Man 2'],
      cancellationPolicy: 'Full refund if cancelled 2 hours before booking time.',
    ),
    'arena_2': ArenaDetailsEntity(
      id: 'arena_2',
      name: 'Kicks on Fire Turf',
      image: 'assets/kart_arena.png',
      rating: 4.5,
      capacity: 2,
      screenCount: 0,
      activity: ArenaActivity.recreational,
      shortAddress: 'HSR Layout, Bangalore',
      location: 'HSR Layout, Bangalore',
      hours: '6AM - 12AM',
      isOpen: true,
      distance: 4.1,
      priceTier: 3,
      isVerified: true,
      latitude: 12.9141,
      longitude: 77.6302,
      desc: 'State-of-the-art 5-a-side football turf with premium AstroTurf. Well-lit for night matches and equipped with showers.',
      tags: ['Football', '5-a-side', 'Cricket'],
      reviews: 289,
      score: 8.8,
      internet: 'N/A',
      amenity: 'Changing Rooms',
      specs: TurfSpecs(
        surface: 'AstroTurf Pro',
        size: '5-a-side',
        lighting: 'LED Floodlights',
        facilities: 'Showers & Lockers',
      ),
      devices: [],
      rules: ['Studs not allowed', 'Advance payment required', 'Arrive 15 mins early'],
      contactPhone: '+91 8765432109',
      hasAC: false,
      hasPowerBackup: true,
      gameLibrary: ['Football', 'Cricket'],
      cancellationPolicy: 'Refund only if cancelled 24 hours prior.',
    ),
  };

  @override
  Future<List<ArenaEntity>> getArenas() async {
    await Future.delayed(const Duration(seconds: 1));
    return _arenas;
  }

  @override
  Future<ArenaDetailsEntity?> getArenaDetails(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _details[id];
  }
}
