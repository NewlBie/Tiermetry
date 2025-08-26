// lib/widgets/arena_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import the SVG package
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../models/arena.dart';
import 'package:tiermetry/arena_details_page.dart';

// AnimatedTapFeedback widget remains the same...
class AnimatedTapFeedback extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const AnimatedTapFeedback({super.key, required this.child, this.onTap});
  @override
  State<AnimatedTapFeedback> createState() => _AnimatedTapFeedbackState();
}

class _AnimatedTapFeedbackState extends State<AnimatedTapFeedback>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 150),
        reverseDuration: const Duration(milliseconds: 75));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();
  void _onTapUp(TapUpDetails details) {
    Future.delayed(
        const Duration(milliseconds: 100), () => _controller.reverse());
  }

  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}


class ArenaCard extends StatelessWidget {
  final Arena arena;

  const ArenaCard({super.key, required this.arena});

  @override
  Widget build(BuildContext context) {
    return AnimatedTapFeedback(
      // --- MODIFIED SECTION ---
      // The onTap handler now passes the entire `arena` object to ArenaDetailsPage.
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (context, animation, secondaryAnimation) =>
                ArenaDetailsPage(
                  arena: arena, // Pass the entire arena object
                ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      },
      // --- END MODIFIED SECTION ---
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF2E2E32), Color(0xFF1C1C1E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(),
            _buildInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    // This Hero tag should be unique for each card. Using arena.id is a good practice.
    return Hero(
      tag: arena.image, // Using the image path as the tag, matching the details page
      flightShuttleBuilder: (flightContext, animation, flightDirection,
          fromHeroContext, toHeroContext) {
        return FadeTransition(
          opacity: animation.drive(
            Tween<double>(begin: 0.5, end: 1.0)
                .chain(CurveTween(curve: Curves.easeInOut)),
          ),
          child: toHeroContext.widget,
        );
      },
      child: AspectRatio(
        aspectRatio: 16 / 9.5,
        child: Image.asset(arena.image, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildInfo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopRow(),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                arena.name,
                style: GoogleFonts.urbanist(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              if (arena.isVerified) ...[
                const SizedBox(width: 8),
                SvgPicture.asset(
                  'assets/verified.svg',
                  height: 20,
                  width: 20,
                ),
              ]
            ],
          ),
          const SizedBox(height: 12),
          _buildStatusAndAddress(),
        ],
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _buildIconText(
                Icons.star_rounded, arena.rating.toString(), Colors.amber),
            const SizedBox(width: 16),
            _buildIconText(Icons.people_alt_rounded, arena.capacity.toString(),
                Colors.white60),
            const SizedBox(width: 16),
            _buildIconText(Icons.monitor_rounded, arena.screenCount.toString(),
                Colors.white60),
          ],
        ),
        _buildMainActivityBadge(),
      ],
    );
  }

  Widget _buildStatusAndAddress() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          arena.shortAddress,
          style: GoogleFonts.urbanist(fontSize: 14, color: Colors.white70),
        ),
        Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: arena.isOpen ? Colors.greenAccent : Colors.redAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (arena.isOpen ? Colors.greenAccent : Colors.redAccent)
                        .withOpacity(0.5),
                    blurRadius: 8.0,
                    spreadRadius: 1.0,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              arena.hours,
              style: GoogleFonts.urbanist(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIconText(IconData icon, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.urbanist(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildMainActivityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        arena.mainActivityDisplay,
        style: GoogleFonts.urbanist(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
