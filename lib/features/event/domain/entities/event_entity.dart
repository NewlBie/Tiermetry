// lib/models/event_model.dart

// A dedicated model to hold all data for an event.
// This keeps your data structure clean and separate from the UI code.
class EventEntity {
  final String id;
  final String title;
  final String subtitle;
  final String image;
  final String date;
  final String time;
  final String location;
  final String cost;
  final int points;
  final int enrollments;
  final DateTime dateTime;
  final String desc;
  final List<String> tags;
  final List<EventPerkEntity> perks;

  EventEntity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.date,
    required this.time,
    required this.location,
    required this.cost,
    required this.points,
    required this.enrollments,
    required this.dateTime,
    required this.desc,
    required this.tags,
    required this.perks,
  });
}

class EventPerkEntity {
  final String name;
  final String icon;

  EventPerkEntity({required this.name, required this.icon});
}
