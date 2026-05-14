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
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      image: json['image'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      location: json['location'] ?? '',
      cost: json['cost'] ?? '',
      points: json['points'] ?? 0,
      enrollments: json['enrollments'] ?? 0,
      dateTime: DateTime.parse(json['dateTime']),
      desc: json['desc'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      perks: (json['perks'] as List? ?? [])
          .map((p) => EventPerkModel.fromJson(p))
          .toList(),
    );
  }
}

class EventPerkModel extends EventPerkEntity {
  EventPerkModel({required super.name, required super.icon});

  factory EventPerkModel.fromJson(Map<String, dynamic> json) {
    return EventPerkModel(
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
    );
  }
}
