import '../../domain/entities/event_entity.dart';

class EventModel extends EventEntity {
  EventModel({
    required super.id,
    required super.title,
    required super.startTime,
    required super.endTime,
    required super.registrationStart,
    required super.registrationEnd,
    required super.registrationType,
    required super.status,
    required super.cost,
    required super.location,
    super.description,
    super.image,
    super.venueId,
    super.maxParticipants,
    super.points,
    super.tags,
    super.perks,
    super.enrollments,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      image: json['image'] as String?,
      venueId: json['venue_id'] as String?,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      registrationStart: DateTime.parse(json['registration_start'] as String),
      registrationEnd: DateTime.parse(json['registration_end'] as String),
      maxParticipants: json['max_participants'] as int?,
      registrationType: json['registration_type'] as String? ?? 'individual',
      status: json['status'] as String? ?? 'draft',
      cost: json['cost'] as String? ?? 'Free',
      location: json['location'] as String? ?? 'Online',
      points: json['points'] as int? ?? 0,
      tags: List<String>.from(json['tags'] as List? ?? []),
      perks: (json['perks'] as List? ?? [])
          .map((dynamic p) => EventPerkModel.fromJson(p as Map<String, dynamic>))
          .toList(),
      enrollments: json['enrollments'] as int? ?? 0,
    );
  }
}

class EventPerkModel extends EventPerkEntity {
  EventPerkModel({required super.name, required super.icon});

  factory EventPerkModel.fromJson(Map<String, dynamic> json) {
    return EventPerkModel(
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
    );
  }
}
