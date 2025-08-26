class Skill {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String badge;
  final String image;
  final String time;
  final String level;
  final String price;
  final String oldPrice;
  final double rating;

  Skill({
    required this.id,
    required this.title,
    required this.subtitle,
    this.category = "Content Creation",
    required this.badge,
    required this.image,
    required this.time,
    required this.level,
    required this.price,
    required this.oldPrice,
    this.rating = 4.9,
  });
}