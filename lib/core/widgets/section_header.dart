import 'package:flutter/material.dart';
import 'package:tiermetry/core/theme/typography.dart';

/// Section header with title and "View More" button
/// Used consistently across all tabs and pages
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewMore;
  final String viewMoreText;
  final String? tagLabel;

  const SectionHeader({
    required this.title,
    this.onViewMore,
    this.viewMoreText = 'View More',
    this.tagLabel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              (title).toUpperCase(),
              style: TiermetryTypography.title(color: Colors.white),
            ),
            if (tagLabel != null) ...[
              const SizedBox(width: 8), // TiermetrySpacing.sm
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2, // TiermetrySpacing.xs / 2
                ),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFD4FF00,
                  ).withValues(alpha: 0.15), // TiermetryColors.accentNeonGreen
                  border: Border.all(
                    color: const Color(0xFFD4FF00).withValues(alpha: 0.5),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tagLabel!,
                  style: TiermetryTypography.label(
                    color: const Color(0xFFD4FF00),
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
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
