// lib/models/event_model.dart

// A dedicated model to hold all data for an event.
// This keeps your data structure clean and separate from the UI code.
class EventEntity {
  final String id;
  final String title;
  final String? description;
  final String? image;
  final String? venueId;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime registrationStart;
  final DateTime registrationEnd;
  final int? maxParticipants;
  final String registrationType;
  final String status;
  final String cost;
  final String location;
  final String? venueName;
  final String? venueAddress;
  final String? venueImage;
  final double? venueRating;
  final int? venueCapacity;
  final String? venueActivity;
  final String? venueHours;
  final bool? venueIsOpen;
  final int? venuePriceTier;
  final bool? venueIsVerified;
  final double? venueLatitude;
  final double? venueLongitude;
  final int points;
  final List<String> tags;
  final List<EventPerkEntity> perks;
  final int enrollments;

  // New fields for details checklist
  final String organizer;
  final String? game;
  final String? platform;
  final String? rules;
  final String? format;
  final List<Map<String, String>> schedule;
  final String? bracketUrl;
  final List<String> rewards;
  final List<Map<String, String>> faqs;
  final String? contactEmail;
  final String? userRegistrationId;
  final String? userRegistrationKind;
  final String? userRegistrationStatus;
  final String? userPaymentStatus;
  final String? userPaymentMethod;
  final String? userTeamName;
  final List<String> userParticipants;

  EventEntity({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.registrationStart,
    required this.registrationEnd,
    required this.registrationType,
    required this.status,
    required this.cost,
    required this.location,
    this.description,
    this.image,
    this.venueId,
    this.venueName,
    this.venueAddress,
    this.venueImage,
    this.venueRating,
    this.venueCapacity,
    this.venueActivity,
    this.venueHours,
    this.venueIsOpen,
    this.venuePriceTier,
    this.venueIsVerified,
    this.venueLatitude,
    this.venueLongitude,
    this.maxParticipants,
    this.points = 0,
    this.tags = const [],
    this.perks = const [],
    this.enrollments = 0,
    this.organizer = 'HOMIES Official',
    this.game,
    this.platform,
    this.rules,
    this.format,
    this.schedule = const [],
    this.bracketUrl,
    this.rewards = const [],
    this.faqs = const [],
    this.contactEmail,
    this.userRegistrationId,
    this.userRegistrationKind,
    this.userRegistrationStatus,
    this.userPaymentStatus,
    this.userPaymentMethod,
    this.userTeamName,
    this.userParticipants = const [],
  });

  bool get isRegistrationOpen {
    final now = DateTime.now();
    return now.isAfter(registrationStart) && now.isBefore(registrationEnd);
  }

  bool get isFull => maxParticipants != null && enrollments >= maxParticipants!;

  bool get hasVenue => venueId != null && venueId!.trim().isNotEmpty;

  String get venueDisplayName {
    final name = venueName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return location;
  }

  String get venueDisplayAddress {
    final address = venueAddress?.trim();
    if (address != null && address.isNotEmpty) return address;
    return location;
  }

  bool get isTournament {
    final haystack = '${title.toLowerCase()} ${tags.join(' ').toLowerCase()}';
    return haystack.contains('tournament') ||
        haystack.contains('cup') ||
        haystack.contains('clash');
  }

  bool get isCompetition {
    final haystack = '${title.toLowerCase()} ${tags.join(' ').toLowerCase()}';
    return haystack.contains('competitive') ||
        haystack.contains('competition') ||
        haystack.contains('hackathon') ||
        haystack.contains('pro-am');
  }

  bool get isStandardEvent => !isTournament && !isCompetition;

  String get kindLabel {
    if (isTournament) return 'Tournament';
    if (isCompetition) return 'Competition';
    return 'Event';
  }

  String get registrationLabel {
    if (isFull) return 'Full';
    if (isRegistrationOpen) return 'Registration open';
    final now = DateTime.now();
    if (now.isBefore(registrationStart)) return 'Registration upcoming';
    return 'Registration closed';
  }

  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  bool get isCompleted => DateTime.now().isAfter(endTime);

  bool get isUpcoming => DateTime.now().isBefore(startTime);
}

class EventPerkEntity {
  final String name;
  final String icon;

  EventPerkEntity({required this.name, required this.icon});
}
