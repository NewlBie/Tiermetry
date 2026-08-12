import '../../domain/entities/event_entity.dart';

class EventModel extends EventEntity {
  EventModel({
    required super.id,
    required super.title,
    required super.subtitle,
    required super.image,
    required super.date,
    required super.time,
    required super.location,
    required super.cost,
    required super.points,
    required super.enrollments,
    required super.dateTime,
    required super.desc,
    required super.tags,
    required super.perks,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      image: json['image'] as String? ?? '',
      date: json['date'] as String? ?? '',
      time: json['time'] as String? ?? '',
      location: json['location'] as String? ?? '',
      cost: json['cost'] as String? ?? '',
      points: json['points'] as int? ?? 0,
      enrollments: json['enrollments'] as int? ?? 0,
      dateTime: DateTime.parse(json['dateTime'] as String? ?? DateTime.now().toIso8601String()),
      desc: json['desc'] as String? ?? '',
      tags: List<String>.from(json['tags'] as List? ?? []),
      perks: (json['perks'] as List? ?? [])
          .map((dynamic p) => EventPerkModel.fromJson(p as Map<String, dynamic>))
          .toList(),
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
