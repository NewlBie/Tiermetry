import 'package:flutter/material.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/features/arena/presentation/screens/arena_screen.dart';
import 'package:tiermetry/features/event/presentation/screens/event_browser_screen.dart';
import 'package:tiermetry/features/quest/presentation/screens/quest_screen.dart';

import 'bento_tile.dart';
import 'promotion_tile.dart';

class MetricsSection extends StatelessWidget {
  const MetricsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Row - Two tiles
        Row(
          children: [
            // Arenas tile
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const ArenaScreen(),
                    ),
                  );
                },
                child: const BentoTile(
                  title: 'Discover Arenas',
                  imagePath: 'assets/arena.png',
                  imageRight: -30,
                  imageBottom: -50,
                  imageScale: 2.0,
                ),
              ),
            ),
            const SizedBox(width: TiermetrySpacing.gridGap),
            // Explore tile
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const EventBrowserScreen(),
                    ),
                  );
                },
                child: const BentoTile(
                  title: 'Explore Events',
                  imagePath: 'assets/sticks/starbucks.png',
                  imageRight: -30,
                  imageBottom: -30,
                  imageScale: 1.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: TiermetrySpacing.gridGap),
        const PromotionTile(),
        const SizedBox(height: TiermetrySpacing.gridGap),
        // Third Row - Points & Referrals
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const QuestsScreen(),
                    ),
                  );
                },
                child: const BentoTile(
                  title: '4,200 Tiergies',
                  imagePath: 'assets/sticks/starbucks.png', // Temporary generic asset
                  imageRight: -20,
                  imageBottom: -20,
                  imageScale: 1.2,
                ),
              ),
            ),
            const SizedBox(width: TiermetrySpacing.gridGap),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // Handle Referral tap
                },
                child: const BentoTile(
                  title: 'Refer & Earn',
                  imagePath: 'assets/arena.png', // Temporary generic asset
                  imageRight: -30,
                  imageBottom: -30,
                  imageScale: 1.5,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
