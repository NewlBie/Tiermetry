import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer loading placeholder for horizontal lists
class ShimmerLoadingList extends StatelessWidget {
  final double itemWidth;
  final double itemHeight;
  final int itemCount;
  final double spacing;
  final double borderRadius;

  const ShimmerLoadingList({
    required this.itemWidth,
    this.itemHeight = 200,
    this.itemCount = 2,
    this.spacing = 12,
    this.borderRadius = 24,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[900]!,
      highlightColor: Colors.grey[800]!,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        separatorBuilder: (_, __) => SizedBox(width: spacing),
        itemBuilder:
            (_, __) => Container(
              width: itemWidth,
              height: itemHeight,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
      ),
    );
  }
}

/// Shimmer loading placeholder for a single card
class ShimmerCard extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const ShimmerCard({
    this.width,
    this.height = 200,
    this.borderRadius = 24,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[900]!,
      highlightColor: Colors.grey[800]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Shimmer loading placeholder for vertical lists
class ShimmerLoadingVerticalList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final double spacing;
  final double borderRadius;

  const ShimmerLoadingVerticalList({
    this.itemCount = 3,
    this.itemHeight = 100,
    this.spacing = 12,
    this.borderRadius = 16,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[900]!,
      highlightColor: Colors.grey[800]!,
      child: Column(
        children: List.generate(
          itemCount,
          (index) => Padding(
            padding: EdgeInsets.only(
              bottom: index < itemCount - 1 ? spacing : 0,
            ),
            child: Container(
              height: itemHeight,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
