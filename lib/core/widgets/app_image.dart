import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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
    if (imagePath.trim().isEmpty) return _buildError();
    final isNetwork = imagePath.startsWith('http');
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = _cacheDimension(width, pixelRatio);
    final cacheHeight = _cacheDimension(height, pixelRatio);
    // Decode to one bounding dimension only. Supplying both dimensions can
    // rasterize a non-16:9 source directly into a card-sized bitmap before
    // BoxFit.cover has a chance to crop it.
    final useWidthCache =
        cacheWidth != null &&
        (cacheHeight == null || cacheWidth >= cacheHeight);
    final imageCacheWidth = useWidthCache ? cacheWidth : null;
    final imageCacheHeight = useWidthCache ? null : cacheHeight;

    Widget image;
    if (isNetwork) {
      image = CachedNetworkImage(
        imageUrl: imagePath,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildError(),
        // Optimization: limit image size in memory
        maxWidthDiskCache: imageCacheWidth,
        maxHeightDiskCache: imageCacheHeight,
        memCacheWidth: imageCacheWidth,
        memCacheHeight: imageCacheHeight,
      );
    } else {
      image = Image.asset(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: imageCacheWidth,
        cacheHeight: imageCacheHeight,
        errorBuilder: (context, error, stackTrace) => _buildError(),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }

  int? _cacheDimension(double? logicalPixels, double pixelRatio) {
    if (logicalPixels == null ||
        !logicalPixels.isFinite ||
        logicalPixels <= 0) {
      return null;
    }
    return (logicalPixels * pixelRatio).round().clamp(1, 4096).toInt();
  }

  Widget _buildPlaceholder() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TiermetryColors.surfaceUnderlay,
            TiermetryColors.surfaceElement,
          ],
        ),
      ),
      child: SizedBox(width: width, height: height),
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
