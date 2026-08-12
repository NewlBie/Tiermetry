import 'package:flutter/material.dart';
import 'package:tiermetry/core/theme/typography.dart';

/// Section header with title and "View More" button
/// Used consistently across all tabs and pages
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewMore;
  final String viewMoreText;

  const SectionHeader({
    required this.title,
    this.onViewMore,
    this.viewMoreText = 'View More',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TiermetryTypography.title(color: Colors.white),
        ),
        if (onViewMore != null)
          TextButton(
            onPressed: onViewMore,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              viewMoreText,
              style: TiermetryTypography.caption(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
      ],
    );
  }
}
