import 'package:flutter/material.dart';
import '../models/skill.dart';
import '../models/event.dart';
import '../models/arena.dart';
import '../models/wallet_data.dart';
import '../models/profile_data.dart';
import 'package:tiermetry/models/discount.dart';

// Base class for any type of specification
abstract class ArenaSpecifications {}

class GamingSpecifications extends ArenaSpecifications {
  final String resolution;
  final String refreshRate;
  final String processor;
  final String peripherals;

  GamingSpecifications({
    required this.resolution,
    required this.refreshRate,
    required this.processor,
    required this.peripherals,
  });
}

class TurfSpecifications extends ArenaSpecifications {
  final String surfaceType;
  final String fieldSize;
  final String lighting;
  final String facilities;

  TurfSpecifications({
    required this.surfaceType,
    required this.fieldSize,
    required this.lighting,
    required this.facilities,
  });
}

// Represents a single bookable unit (e.g., a PS5 console, a PC)
class GamingDevice {
  final String id;
  final String name;
  final String description;
  final int pricePerHour;
  final String imagePath;
  final bool isOccupied;

  GamingDevice({
    required this.id,
    required this.name,
    required this.description,
    required this.pricePerHour,
    required this.imagePath,
    this.isOccupied = false,
  });
}

// Represents a category of devices (e.g., "PlayStation 5")
class DeviceCategory {
  final String categoryName;
  final List<GamingDevice> units;

  DeviceCategory({required this.categoryName, required this.units});
}

// A comprehensive model that extends the base Arena class with detailed info.
class FullArenaDetails extends Arena {
  final String description;
  final List<String> tags;
  final int reviewCount;
  final double tiermetryScore;
  final String internetType;
  final String mainAmenity;
  final ArenaSpecifications specifications;
  final List<DeviceCategory> devices;

  FullArenaDetails({
    required super.id,
    required super.name,
    required super.image,
    required super.rating,
    required super.capacity,
    required super.screenCount,
    required super.mainActivity,
    required super.shortAddress,
    required super.location, // Added location to super
    required super.hours,
    required super.isOpen,
    required super.distance,
    required super.priceTier,
    required super.isVerified,
    required this.description,
    required this.tags,
    required this.reviewCount,
    required this.tiermetryScore,
    required this.internetType,
    required this.mainAmenity,
    required this.specifications,
    required this.devices,
  });
}


class ApiService {

  // Your existing methods...
  Future<List<Discount>> getDiscounts() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Return mock data with image paths.
    // In a real app, these would be URLs from your backend.
    return [
      Discount(id: 'promo_01', imageUrl: 'assets/promo_banner_1.jpg'),
      Discount(id: 'promo_02', imageUrl: 'assets/promo_banner_2.jpg'),
    ];
  }
  Future<ProfileData> getProfileData() async {
    // Simulate a network delay
    await Future.delayed(const Duration(seconds: 2));
    return ProfileData(
      userName: "Neal",
      userLevel: "Predator",
      userLocation: "India",
      userJoinedDate: "Apr 2024",
      userAge: 19,
      userImage: 'assets/placeholder.png', // Placeholder image asset
      currentTierName: "Gold III",
      currentTierProgress: 0.75,
      openedBadges: 8,
      totalBadges: 20,
      badges: [
        BadgeData(title: "Pioneer", color: Colors.blueAccent),
        BadgeData(title: "Innovator", color: Colors.purpleAccent),
        BadgeData(title: "Strategist", color: Colors.orangeAccent),
      ],
      wallet: WalletData(
        balance: "2500", // The number will be animated
        earned: "700",
        spent: "350",
        txns: "24",
      ),
    );
  }
  Future<WalletData> getWalletData() async {
    // Simulate a network delay
    await Future.delayed(const Duration(seconds: 2));
    return WalletData(
      balance: "\$1,250.75",
      earned: "350.20",
      spent: "180.50",
      txns: "42",
    );
  }
  Future<List<Skill>> getFeaturedSkills() async {
    await Future.delayed(const Duration(seconds: 2));
    return [
      Skill(
        id: '1',
        title: "YouTube Masterclass",
        subtitle: "Learn from MKBHD",
        badge: "Sponsored",
        image: 'assets/skills_side.png',
        time: "1h 30m",
        level: "Intermediate",
        price: "\$80",
        oldPrice: "\$100",
      ),
      Skill(
        id: '2',
        title: "Viral Video Editing",
        subtitle: "with Adobe Premiere Pro",
        badge: "New",
        image: 'assets/Hackathon.jpg',
        time: "2h 45m",
        level: "Beginner",
        price: "\$60",
        oldPrice: "\$90",
      ),
    ];
  }
  Future<List<Event>> getUpcomingEvents() async {
    await Future.delayed(const Duration(seconds: 2));
    return [
      Event(
        id: '1',
        title: "Flutter Hackathon 2025",
        subtitle: "Join us for a 2-day hackathon!", 
        image: 'assets/Hackathon.jpg',
        date: "12 July 2025",
        time: "10:00 AM",
        location: "Bhubaneswar Tech Park",
        cost: "Free", 
        points: 100, 
        enrollments: 50, 
        dateTime: DateTime(2025, 7, 12, 10, 0, 0), 
        description: "A fun and engaging hackathon for Flutter developers.", 
        tags: ['Flutter', 'Hackathon', 'Mobile Development'], 
        perks: [
          EventPerk(name: 'Networking', iconAsset: 'assets/ticket_cut.svg'), 
          EventPerk(name: 'Free Swag', iconAsset: 'assets/ticket_cut.svg') 
        ],
      ),
      Event(
        id: '2',
        title: "Tech Innovators Meetup",
        subtitle: "Monthly meetup for tech enthusiasts.", 
        image: 'assets/arena color.png',
        date: "18 Aug 2025",
        time: "6:00 PM",
        location: "Online",
        cost: "Free", 
        points: 20, 
        enrollments: 120, 
        dateTime: DateTime(2025, 8, 18, 18, 0, 0), 
        description: "Discuss the latest trends in technology and innovation.", 
        tags: ['Tech', 'Innovation', 'Meetup'], 
        perks: [
          EventPerk(name: 'Online Access', iconAsset: 'assets/ticket_cut.svg'), 
          EventPerk(name: 'Q&A Session', iconAsset: 'assets/ticket_cut.svg') 
        ],
      ),
    ];
  }


  final List<Arena> _arenas = [
    Arena(
        id: 'arena_1', // Changed ID to match details map
        name: 'Vortex Gaming Lounge',
        image: 'assets/arena1.jpeg',
        rating: 4.8,
        capacity: 30,
        screenCount: 30,
        mainActivity: MainActivity.gaming,
        shortAddress: 'Koramangala, Bangalore',
        location: 'Koramangala, Bangalore', // Added location
        hours: '10AM - 11PM',
        isOpen: true,
        distance: 2.5,
        priceTier: 2,
        isVerified: true
    ),
    Arena(
        id: 'arena_2', // Changed ID to match details map
        name: 'Kicks on Fire Turf',
        image: 'assets/kart_arena.png',
        rating: 4.5,
        capacity: 2,
        screenCount: 0,
        mainActivity: MainActivity.recreational,
        shortAddress: 'HSR Layout, Bangalore',
        location: 'HSR Layout, Bangalore', // Added location
        hours: '6AM - 12AM',
        isOpen: true,
        distance: 4.1,
        priceTier: 3,
        isVerified: true
    ),
  ];

  Future<List<Arena>> getArenas() async {
    await Future.delayed(const Duration(seconds: 1));
    return _arenas;
  }

  // --- NEW MOCK DATA AND METHOD ---

  static final Map<String, FullArenaDetails> _mockDetailsDatabase = {
    'arena_1': FullArenaDetails(
      id: 'arena_1',
      name: 'Vortex Gaming Lounge',
      image: 'assets/arena1.jpeg',
      rating: 4.8,
      capacity: 30,
      screenCount: 30,
      mainActivity: MainActivity.gaming,
      shortAddress: 'Koramangala, Bangalore',
      location: 'Koramangala, Bangalore', // Added location
      hours: '10AM - 11PM',
      isOpen: true,
      distance: 2.5,
      priceTier: 2,
      isVerified: true,
      description: 'A premier destination for high-end gaming. Featuring next-gen consoles, VR, and performance-tuned PCs. Ideal for both solo sessions and group tournaments.',
      tags: ['Arcade', 'PS5', 'PC Gaming', 'VR Arena'],
      reviewCount: 412,
      tiermetryScore: 9.2,
      internetType: 'Fiber Optic',
      mainAmenity: 'Lounge & Cafe',
      specifications: GamingSpecifications(
        resolution: 'Up to 4K',
        refreshRate: '120-240Hz',
        processor: 'Ryzen 7 / i7',
        peripherals: 'Pro-grade',
      ),
      devices: [
        DeviceCategory(
          categoryName: '🎮 PlayStation 5',
          units: [
            GamingDevice(id: 'ps5_1', name: 'Console 1', description: 'FIFA, UFC 5', pricePerHour: 120, imagePath: 'assets/ps5_card.png', isOccupied: false),
            GamingDevice(id: 'ps5_2', name: 'Console 2', description: 'COD, Fortnite', pricePerHour: 120, imagePath: 'assets/ps5_card.png', isOccupied: true),
          ],
        ),
        DeviceCategory(
          categoryName: '🖥️ High-Performance PC',
          units: [
            GamingDevice(id: 'pc_1', name: 'PC - 1', description: 'Valorant', pricePerHour: 150, imagePath: 'assets/pc_card.png', isOccupied: false),
            GamingDevice(id: 'pc_2', name: 'PC - 2', description: 'With VR Headset', pricePerHour: 160, imagePath: 'assets/pc_card.png', isOccupied: true),
          ],
        ),
      ],
    ),
    'arena_2': FullArenaDetails(
      id: 'arena_2',
      name: 'Kicks on Fire Turf',
      image: 'assets/turf_arena.jpg',
      rating: 4.5,
      capacity: 2,
      screenCount: 0,
      mainActivity: MainActivity.recreational,
      shortAddress: 'HSR Layout, Bangalore',
      location: 'HSR Layout, Bangalore', // Added location
      hours: '6AM - 12AM',
      isOpen: true,
      distance: 4.1,
      priceTier: 3,
      isVerified: true,
      description: 'State-of-the-art 5-a-side football turf with premium AstroTurf and powerful floodlights for an unmatched playing experience, day or night.',
      tags: ['Football', '5-a-side', 'Cricket'],
      reviewCount: 289,
      tiermetryScore: 8.8,
      internetType: 'N/A',
      mainAmenity: 'Changing Rooms',
      specifications: TurfSpecifications(
        surfaceType: 'AstroTurf Pro',
        fieldSize: '5-a-side',
        lighting: 'LED Floodlights',
        facilities: 'Showers & Lockers',
      ),
      devices: [],
    ),
  };

  // New method to fetch detailed data for a specific arena
  Future<FullArenaDetails?> getArenaDetails(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockDetailsDatabase[id];
  }
}
