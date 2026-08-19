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
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      category: json['category'] as String? ?? 'Content Creation',
      badge: json['badge'] as String? ?? '',
      image: json['image'] as String? ?? '',
      time: json['time'] as String? ?? '0h',
      level: json['level'] as String? ?? 'Beginner',
      price: json['price'] as String? ?? 'Free',
      oldPrice: json['oldPrice'] as String? ?? 'Rs. 0',
      rating: (json['rating'] as num? ?? 0.0).toDouble(),
    );
  }
}
