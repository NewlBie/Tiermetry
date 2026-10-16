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
    super.venueName,
    super.venueAddress,
    super.venueImage,
    super.venueRating,
    super.venueCapacity,
    super.venueActivity,
    super.venueHours,
    super.venueIsOpen,
    super.venuePriceTier,
    super.venueIsVerified,
    super.venueLatitude,
    super.venueLongitude,
    super.maxParticipants,
    super.points,
    super.tags,
    super.perks,
    super.enrollments,
    super.organizer,
    super.game,
    super.platform,
    super.rules,
    super.format,
    super.schedule,
    super.bracketUrl,
    super.rewards,
    super.faqs,
    super.contactEmail,
    super.userRegistrationId,
    super.userRegistrationKind,
    super.userRegistrationStatus,
    super.userPaymentStatus,
    super.userPaymentMethod,
    super.userTeamName,
    super.userParticipants,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      image: json['image'] as String?,
      venueId: json['venue_id'] as String?,
      startTime: DateTime.parse(json['start_time'] as String).toLocal(),
      endTime: DateTime.parse(json['end_time'] as String).toLocal(),
      registrationStart:
          DateTime.parse(json['registration_start'] as String).toLocal(),
      registrationEnd:
          DateTime.parse(json['registration_end'] as String).toLocal(),
      maxParticipants: json['max_participants'] as int?,
      registrationType: json['registration_type'] as String? ?? 'individual',
      status: json['status'] as String? ?? 'draft',
      cost: json['cost'] as String? ?? 'Free',
      location: json['location'] as String? ?? 'Online',
      venueName: json['venue_name'] as String?,
      venueAddress: json['venue_address'] as String?,
      venueImage: json['venue_image'] as String?,
      venueRating: (json['venue_rating'] as num?)?.toDouble(),
      venueCapacity: json['venue_capacity'] as int?,
      venueActivity: json['venue_activity'] as String?,
      venueHours: json['venue_hours'] as String?,
      venueIsOpen: json['venue_is_open'] as bool?,
      venuePriceTier: json['venue_price_tier'] as int?,
      venueIsVerified: json['venue_is_verified'] as bool?,
      venueLatitude: (json['venue_latitude'] as num?)?.toDouble(),
      venueLongitude: (json['venue_longitude'] as num?)?.toDouble(),
      points: json['points'] as int? ?? 0,
      tags: List<String>.from(json['tags'] as List? ?? []),
      perks:
          (json['perks'] as List? ?? [])
              .map(
                (dynamic p) =>
                    EventPerkModel.fromJson(p as Map<String, dynamic>),
              )
              .toList(),
      enrollments: json['enrollments'] as int? ?? 0,
      organizer: json['organizer'] as String? ?? 'HOMIES Official',
      game: json['game'] as String?,
      platform: json['platform'] as String?,
      rules: json['rules'] as String?,
      format: json['format'] as String?,
      schedule: _stringMapList(json['schedule']),
      bracketUrl: json['bracket_url'] as String?,
      rewards:
          json['rewards'] != null
              ? (json['rewards'] as Iterable<dynamic>)
                  .map((reward) => reward.toString())
                  .toList()
              : const [],
      faqs: _stringMapList(json['faqs']),
      contactEmail: json['contact_email'] as String?,
      userRegistrationId: json['user_registration_id'] as String?,
      userRegistrationKind: json['user_registration_kind'] as String?,
      userRegistrationStatus: json['user_registration_status'] as String?,
      userPaymentStatus: json['user_payment_status'] as String?,
      userPaymentMethod: json['user_payment_method'] as String?,
      userTeamName: json['user_team_name'] as String?,
      userParticipants:
          json['user_participants'] != null
              ? (json['user_participants'] as Iterable<dynamic>)
                  .map((participant) => participant.toString())
                  .toList()
              : const [],
    );
  }

  static List<Map<String, String>> _stringMapList(dynamic value) {
    if (value is! Iterable) return const [];

    return value
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (item) => item.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          ),
        )
        .toList();
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
