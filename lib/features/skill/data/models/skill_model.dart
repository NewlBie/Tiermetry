import '../../domain/entities/skill_entity.dart';

class SkillModel extends SkillEntity {
  SkillModel({
    required super.id,
    required super.title,
    required super.subtitle,
    required super.category,
    required super.badge,
    required super.image,
    required super.time,
    required super.level,
    required super.price,
    required super.oldPrice,
    required super.rating,
  });

  factory SkillModel.fromJson(Map<String, dynamic> json) {
    return SkillModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      category: json['category'] ?? "Content Creation",
      badge: json['badge'] ?? '',
      image: json['image'] ?? '',
      time: json['time'] ?? '0h',
      level: json['level'] ?? 'Beginner',
      price: json['price'] ?? 'Free',
      oldPrice: json['oldPrice'] ?? 'Rs. 0',
      rating: (json['rating'] ?? 0.0).toDouble(),
    );
  }
}
