import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/shadows.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_surface.dart';
import '../../domain/entities/skill_entity.dart';

class FeaturedSkillMorphCard extends StatelessWidget {
  final SkillEntity skill;

  const FeaturedSkillMorphCard({required this.skill, super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AppSurface(
        width: 280,
        borderRadius: TiermetryRadii.md,
        shadows: TiermetryShadows.featuredSkill,
        border: const Border(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// IMAGE SECTION
            Expanded(
              flex: 55,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(skill.image, fit: BoxFit.cover),
                      ),
                    ),
                  ),

                  /// Subtle gradient for top tags
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    height: 80,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.7),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  /// TAGS
                  Positioned(
                    top: 24,
                    left: 24,
                    right: 24,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            skill.badge.toUpperCase(),
                            style: TiermetryTypography.label(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        // Rating
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                CupertinoIcons.star_fill,
                                size: 13,
                                color: Colors.black,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                skill.rating.toString(),
                                style: TiermetryTypography.label(
                                  fontSize: 11,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            /// DETAILS SECTION
            Expanded(
              flex: 45,
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text(
                      skill.category.toUpperCase(),
                      style: TiermetryTypography.label(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: TiermetryColors.accentNeonGreen,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text((skill.title).toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TiermetryTypography.title(
                        fontSize: 19,
                        height: 1.2,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// Meta & Action Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        /// Meta info (Time & Level)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _buildInfoItem(
                                CupertinoIcons.time,
                                skill.time,
                              ),
                              const SizedBox(height: 6),
                              _buildInfoItem(
                                CupertinoIcons.chart_bar_alt_fill,
                                skill.level,
                              ),
                            ],
                          ),
                        ),

                        /// CTA Button
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            'Enroll',
                            style: TiermetryTypography.action(
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.6)),
        const SizedBox(width: 6),
        Text(
          text,
          style: TiermetryTypography.caption(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
