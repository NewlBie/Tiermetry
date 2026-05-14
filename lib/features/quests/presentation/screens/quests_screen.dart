import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/features/quests/presentation/widgets/quest_card.dart';

class QuestsScreen extends StatelessWidget {
  const QuestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TiermetryColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Choose\nyour quests",
                    style: GoogleFonts.inter(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -2.0,
                      height: 1.05,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: TiermetryColors.surfaceElement,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.grid_view_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Staggered Grid Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left Tall Column
                          const Expanded(
                            flex: 10,
                            child: QuestCard(
                              title: "Help Steve solve the mystery",
                              backgroundColor: Color(0xFF5C80FF),
                              rating: 4,
                              illustrationEmoji: "👾",
                              hasActionButton: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Right Two Stacked Column
                          Expanded(
                            flex: 11,
                            child: Column(
                              children: [
                                const Expanded(
                                  flex: 5,
                                  child: QuestCard(
                                    title: "Weasley is afraid of something",
                                    backgroundColor: Color(0xFFF460D6),
                                    rating: 3,
                                    illustrationEmoji: "👹",
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Expanded(
                                  flex: 6, // Slightly taller proportionally
                                  child: QuestCard(
                                    title: "Bully at school",
                                    backgroundColor: Color(0xFFA2CC5B),
                                    rating: 4,
                                    illustrationEmoji: "🧟",
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Bottom Wide Card
                    const SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: QuestCard(
                        title: "What happened to Stanley?",
                        backgroundColor: Color(0xFF43555D),
                        rating: 3,
                        illustrationEmoji: "🧌",
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
