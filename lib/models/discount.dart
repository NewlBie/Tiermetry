// lib/models/discount.dart

class Discount {
  final String id;
  final String imageUrl; // URL for the 16:9 banner image

  Discount({
    required this.id,
    required this.imageUrl,
  });

  factory Discount.fromJson(Map<String, dynamic> json) {
    return Discount(
      id: json['id'] as String,
      imageUrl: json['imageUrl'] as String,
    );
  }
}