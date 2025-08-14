class EventModel {
  final String title;
  final String subtitle;
  final String image;
  final String time;
  final String description;
  final String cost;
  final String date;
  final int points;
  final List<String> tags;
  final int enrollments;
  final DateTime dateTime;

  EventModel({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.time,
    required this.description,
    required this.cost,
    required this.date,
    required this.points,
    required this.tags,
    required this.enrollments,
    required this.dateTime,
  });
}
