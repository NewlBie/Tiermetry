// lib/models/event_model.dart

// A dedicated model to hold all data for an event.
// This keeps your data structure clean and separate from the UI code.
class Event {
  final String id;
  final String title;
  final String subtitle;
  final String image;
  final String date;
  final String time;
  final String location; // Added location field
  final String cost;
  final int points;
  final int enrollments;
  final DateTime dateTime; // The precise date and time for the countdown
  final String description;
  final List<String> tags;
  final List<EventPerk> perks;

  Event({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.date,
    required this.time,
    required this.location, // Added location to constructor
    required this.cost,
    required this.points,
    required this.enrollments,
    required this.dateTime,
    required this.description,
    required this.tags,
    required this.perks,
  });
}

// A simple class to represent the perks or benefits of attending an event.
class EventPerk {
  final String name;
  final String iconAsset; // Using SVG assets for icons

  EventPerk({required this.name, required this.iconAsset});
}
