import 'package:flutter/material.dart';
import 'package:tiermetry/core/theme/typography.dart';

class QuestCard extends StatelessWidget {
  final String title;
  final Color backgroundColor;
  final int rating;
  final String illustrationEmoji;
  final bool hasActionButton;
  final VoidCallback? onActionTap;

  const QuestCard({
    required this.illustrationEmoji,
    required this.backgroundColor,
    required this.title,
    super.key,
    this.rating = 4,
    this.hasActionButton = false,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(32),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // Illustration (Bottom Right)
            Positioned(
              right: -30,
              bottom: -20,
              child: Text(
                illustrationEmoji,
                style: const TextStyle(fontSize: 160),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Star Rating
                  Row(
                    children: List.generate(5, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: index < rating
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  
                  // Title
                  Text(
                    title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TiermetryTypography.title(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.0,
                      height: 1.1,
                      color: Colors.white,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Action Button
                  if (hasActionButton)
                    GestureDetector(
                      onTap: onActionTap,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
