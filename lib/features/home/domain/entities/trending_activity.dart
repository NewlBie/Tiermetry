class TrendingActivity {
  final String id;
  final String name;
  final String icon;
  final int playersToday;
  final double rating;
  final bool isSelected;

  TrendingActivity({
    required this.id,
    required this.name,
    required this.icon,
    required this.playersToday,
    required this.rating,
    this.isSelected = false,
  });

  TrendingActivity copyWith({
    String? id,
    String? name,
    String? icon,
    int? playersToday,
    double? rating,
    bool? isSelected,
  }) {
    return TrendingActivity(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      playersToday: playersToday ?? this.playersToday,
      rating: rating ?? this.rating,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
