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
  final int points;
  final List<String> tags;
  final List<EventPerkEntity> perks;
  final int enrollments;

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
    this.maxParticipants,
    this.points = 0,
    this.tags = const [],
    this.perks = const [],
    this.enrollments = 0,
  });

  bool get isRegistrationOpen {
    final now = DateTime.now();
    return now.isAfter(registrationStart) && now.isBefore(registrationEnd);
  }

  bool get isFull => maxParticipants != null && enrollments >= maxParticipants!;
}

class EventPerkEntity {
  final String name;
  final String icon;

  EventPerkEntity({required this.name, required this.icon});
}
