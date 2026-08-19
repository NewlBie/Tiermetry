import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/colors.dart';

class AppImage extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const AppImage({
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isNetwork = imagePath.startsWith('http');

    Widget image;
    if (isNetwork) {
      image = CachedNetworkImage(
        imageUrl: imagePath,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => _buildShimmer(),
        errorWidget: (context, url, error) => _buildError(),
        // Optimization: limit image size in memory
        maxWidthDiskCache: 1000,
        maxHeightDiskCache: 1000,
      );
    } else {
      image = Image.asset(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildError(),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: TiermetryColors.surfaceUnderlay,
      highlightColor: TiermetryColors.surfaceElement,
      child: Container(width: width, height: height, color: Colors.white),
    );
  }

  Widget _buildError() {
    return Container(
      width: width,
      height: height,
      color: TiermetryColors.surfaceUnderlay,
      child: const Icon(Icons.broken_image, color: Colors.white24, size: 24),
    );
  }
}
