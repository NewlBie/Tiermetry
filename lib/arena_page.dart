// lib/pages/arena_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Import for animations
import 'package:tiermetry/models/discount.dart';
import '../services/api_service.dart';
import '../models/arena.dart';
import 'all_arenas_page.dart';
import '../widget/arena_card.dart'; // Ensure this path is correct and points to the enhanced ArenaCard

class ArenaPage extends StatefulWidget {
  const ArenaPage({super.key});

  @override
  State<ArenaPage> createState() => _ArenaPageState();
}

class _ArenaPageState extends State<ArenaPage> {
  final ApiService _apiService = ApiService();
  late Future<List<Arena>> _arenasFuture;
  late Future<List<Discount>> _discountsFuture;

  @override
  void initState() {
    super.initState();
    _arenasFuture = _apiService.getArenas();
    _discountsFuture = _apiService.getDiscounts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1015),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          _buildSectionTitle("Featured", hasViewMore: true),
          _buildFeaturedArenas(),
          _buildSectionTitle("Discounts And Offers"),
          _buildDiscounts(),
          _buildSectionTitle("Trending Activities"),
          _buildTrendingActivities(),
          const SliverToBoxAdapter(child: SizedBox(height: 40)), // Bottom padding
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      backgroundColor: const Color(0xFF0D1015).withOpacity(0.8),
      expandedHeight: 120.0,
      pinned: true,
      elevation: 0,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            title: Text(
              'Discover',
              style: GoogleFonts.urbanist(
                fontWeight: FontWeight.w800,
                fontSize: 28,
                color: Colors.white,
              ),
            ),
            centerTitle: false,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool hasViewMore = false}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 12, top: 36, bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: GoogleFonts.urbanist(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.94),
              ),
            ),
            if (hasViewMore)
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AllArenasPage()),
                  );
                },
                child: Text(
                  "View more",
                  style: GoogleFonts.urbanist(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
          ],
        ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.1),
      ),
    );
  }

  Widget _buildFeaturedArenas() {
    return FutureBuilder<List<Arena>>(
      future: _arenasFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasError) {
          return SliverToBoxAdapter(child: Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.white))));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverToBoxAdapter(child: Center(child: Text("No arenas found.", style: TextStyle(color: Colors.white))));
        }

        final allArenas = snapshot.data!;
        return SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0, left: 20, right: 20),
                child: ArenaCard(arena: allArenas[index]),
              ).animate().fadeIn(delay: (100 * index).ms, duration: 500.ms).slideY(begin: 0.2);
            },
            childCount: allArenas.length,
          ),
        );
      },
    );
  }

  Widget _buildDiscounts() {
    return FutureBuilder<List<Discount>>(
      future: _discountsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        final discounts = snapshot.data!;
        final double itemWidth = MediaQuery.of(context).size.width * 0.75;
        final double itemHeight = itemWidth * (9 / 16);

        return SliverToBoxAdapter(
          child: SizedBox(
            height: itemHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: discounts.length,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemBuilder: (context, index) {
                final discount = discounts[index];
                return Container(
                  width: itemWidth,
                  margin: const EdgeInsets.only(right: 16.0),
                  child: DiscountBanner(
                    discount: discount,
                    onTap: () => debugPrint("Tapped on discount: ${discount.id}"),
                  ),
                ).animate().fadeIn(delay: (100 * index).ms, duration: 500.ms).slideX(begin: 0.2);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrendingActivities() {
    final trendingActivities = {
      "Mortal Kombat": Colors.orangeAccent,
      "Fifa": Colors.greenAccent,
      "Valorant": Colors.deepOrangeAccent,
      "Watchdogs L": Colors.lightBlueAccent,
      "Tekken": Colors.tealAccent,
      "Pubg": Colors.yellowAccent,
    };

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final title = trendingActivities.keys.elementAt(index);
            final color = trendingActivities.values.elementAt(index);
            return TrendingBar(
              rank: index + 1,
              title: title,
              color: color,
            ).animate().fadeIn(delay: (100 * index).ms, duration: 500.ms).slideY(begin: 0.3);
          },
          childCount: trendingActivities.length,
        ),
      ),
    );
  }
}

class DiscountBanner extends StatelessWidget {
  final Discount discount;
  final VoidCallback? onTap;

  const DiscountBanner({super.key, required this.discount, this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedTapFeedback( // Using the animated feedback widget
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.0),
          child: Image.network(
            discount.imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: progress == null ? child : Container(color: const Color(0xFF1C1C1E)),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: const Color(0xFF1C1C1E),
                child: const Center(child: Icon(Icons.broken_image_outlined, color: Colors.white38, size: 40)),
              );
            },
          ),
        ),
      ),
    );
  }
}

class TrendingBar extends StatelessWidget {
  final int rank;
  final String title;
  final Color color;

  const TrendingBar({
    super.key,
    required this.rank,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              "$rank.",
              style: GoogleFonts.urbanist(
                color: Colors.white54,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.urbanist(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.3), Colors.transparent],
                  stops: const [0.0, 0.7, 1.0],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}