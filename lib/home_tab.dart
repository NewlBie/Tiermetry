import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gradient_borders/gradient_borders.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:tiermetry/skill_browser_page.dart';
import 'package:tiermetry/event_browser_page.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}
class _HomeTabState extends State<HomeTab> {
  // These should be fetched from your backend (e.g. Firebase, Supabase, etc.)
  final List<Map<String, String>> sponsoredSkills = [
    {
      'title': "YouTube Masterclass",
      'subtitle': "Learn from MKBHD",
      'badge': "Sponsored",
      'image': 'assets/skills_side.png',
      'time': "1h 30m",
      'level': "Intermediate",
      'price': "\$80",
      'oldPrice': "\$100",
    },
  ];

  final List<Map<String, String>> weeklyEvents = [
    {
      'title': "Flutter Hackathon 2025",
      'date': "12 July 2025",
      'time': "10:00 AM",
      'location': "Bhubaneswar Tech Park",
      'image': 'assets/Hackathon.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 70),
              // 👋 Welcome Header
              Text(
                "Hello Neal 👋",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),

              // 🧠 Metric Cards Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    AppleBlurMetricCard(
                      label: "Score Today",
                      value: "96",
                      unit: "pts",
                      backgroundImage: 'assets/grad1.png',
                    ),
                    const SizedBox(width: 10),
                    AppleBlurMetricCard(
                      label: "Skills Gained",
                      value: "4h",
                      unit: "total",
                      backgroundImage: 'assets/grad3.png',
                    ),
                    const SizedBox(width: 10),
                    AppleBlurMetricCard(
                      label: "Time Enjoyed",
                      value: "4h",
                      unit: "total",
                      backgroundImage: 'assets/grad12.png',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 🎁 Promo Card
              const GlassPromoCard(),
              const SizedBox(height: 32),

              // 🌍 Explore
              Text(
                'Explore',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              AppleStyleExploreCard(
                title: "Step Into Greatness",
                subtitle: "You deserve a better arena",
                caption: "Discover curated spaces around you...",
                image: 'assets/arena color.png',
              ),
              const SizedBox(height: 16),
              AppleStyleExploreCard(
                title: "Level Up Instantly",
                subtitle: "Gain some skills",
                caption: "Learn essential skills to grow...",
                image: 'assets/Skills color.png',
              ),
              const SizedBox(height: 32),

              // 🌟 Featured Skills
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Featured Skills',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const SkillBrowserPage())),
                    child: Text("View More", style: GoogleFonts.inter(color: Colors.white60)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 260,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: sponsoredSkills.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, index) {
                    final s = sponsoredSkills[index];
                    return SizedBox(
                      width: 260,
                      child: FeaturedSkillMorphCard(
                        title: s['title']!,
                        subtitle: s['subtitle']!,
                        badge: s['badge']!,
                        image: s['image']!,
                        time: s['time']!,
                        level: s['level']!,
                        price: s['price']!,
                        oldPrice: s['oldPrice']!,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),

              // 📅 Upcoming Events
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Upcoming Events',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const EventBrowserPage())),
                    child: Text("View More", style: GoogleFonts.inter(color: Colors.white60)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 210,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: weeklyEvents.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, index) {
                    final e = weeklyEvents[index];
                    return SizedBox(
                      width: 300,
                      child: GlassUpcomingEventsCard(
                        title: e['title']!,
                        date: e['date']!,
                        time: e['time']!,
                        location: e['location']!,
                        image: e['image']!,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }
}



// ---------- Metric Card ----------//

class AppleBlurMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String backgroundImage;

  const AppleBlurMetricCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.backgroundImage,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Stack(
        children: [
          // Glowing blurred background
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(backgroundImage),
                fit: BoxFit.cover,

              ),
            ),
          ),

          // Glass blur overlay
          Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.urbanist(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: value,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        TextSpan(
                          text: " $unit",
                          style: GoogleFonts.urbanist(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.6),
                            fontWeight: FontWeight.w400,
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
    );
  }
}
// ---------- Premium Promotion ----------


class GlassPromoCard extends StatelessWidget {
  const GlassPromoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 40,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // 🌫️ Glass Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1B1E32).withOpacity(0.7),
                    const Color(0xFF0D0F1B).withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
            ),

            // ✨ Shine Overlay (static)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.4,
                    colors: [
                      Colors.white.withOpacity(0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // 📷 Image & Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              child: Row(
                children: [
                  // Promo Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/money.png',
                      height: 120,
                      width: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Feel the Power of Play',
                          style: GoogleFonts.urbanist(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Subscribe to unlock rewards and pro-level perks.',
                          style: GoogleFonts.urbanist(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.7),
                            height: 1.4,
                          ),
                        ),
                        const Spacer(),

                        // CTA Button
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white,
                                Colors.white.withOpacity(0.85),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Get Premium',
                                style: GoogleFonts.urbanist(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_ios_rounded,
                                  size: 14, color: Colors.black),
                            ],
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
    );
  }
}

// ---------- Featured Skills ---------



class FeaturedSkillMorphCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String badge;
  final String image;
  final String time;
  final String level;
  final String price;
  final String oldPrice;

  const FeaturedSkillMorphCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.image,
    required this.time,
    required this.level,
    required this.price,
    required this.oldPrice,
    Key? key,
  }) : super(key: key);

  @override
  State<FeaturedSkillMorphCard> createState() =>
      _FeaturedSkillMorphCardState();
}
class _FeaturedSkillMorphCardState extends State<FeaturedSkillMorphCard> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => expanded = !expanded);
      },
      child: AnimatedScale(
        scale: expanded ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutExpo,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: expanded ? 1 : 0.95,
          child: Container(
            width: 260,
            height: 260,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: expanded ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background image with darken effect
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      expanded
                          ? Colors.black.withOpacity(0.3)
                          : Colors.transparent,
                      BlendMode.darken,
                    ),
                    child: Image.asset(
                      widget.image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
                if (!expanded)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 100, // adjust height to match your text zone
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                    ),
                  ),

                // Foreground content
                Padding(
                  padding: const EdgeInsets.all(10),
                  child:

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row with Category and Enroll Button
                      if (expanded)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Content Creation",
                              style: GoogleFonts.urbanist(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                            AnimatedSlide(
                              duration: const Duration(milliseconds: 500),
                              offset: expanded
                                  ? Offset.zero
                                  : const Offset(0.5, 0),
                              curve: Curves.easeOutBack,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 500),
                                opacity: expanded ? 1.0 : 0.0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "Enroll",
                                    style: GoogleFonts.urbanist(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 8),

                      // Title
                      Text(
                        widget.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.urbanist(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: expanded ? Colors.white : Colors.white,
                          shadows: !expanded
                              ? [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            )
                          ]
                              : [],
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Subtitle
                      Text(
                        widget.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.urbanist(
                          fontSize: 12.5,
                          color: expanded ? Colors.white70 : Colors.white70,
                          shadows: !expanded
                              ? [
                            Shadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            )
                          ]
                              : [],
                        ),
                      ),

                      const Spacer(),

                      // Animated Stats Row
                      if (expanded)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AnimatedStat(title: "4.9 ★", label: "RAT NG", index: 0),
                            AnimatedStat(title: widget.level, label: "LEVEL", index: 1),
                            AnimatedStat(title: widget.time, label: "TIME", index: 2),
                            AnimatedStat(title: "EN", label: "LANG", index: 3),
                          ],
                        ),

                      // Badge (collapsed only)
                      if (!expanded)
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.badge,
                              style: GoogleFonts.urbanist(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- Animated Stat Widget ----------

class AnimatedStat extends StatelessWidget {
  final String title;
  final String label;
  final int index;

  const AnimatedStat({
    required this.title,
    required this.label,
    required this.index,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 20.0, end: 0.0),
      duration: Duration(milliseconds: 300 + (index * 70)),
      curve: Curves.easeOutExpo,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, value),
          child: Opacity(
            opacity: (20.0 - value) / 20.0,
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.urbanist(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.urbanist(
              fontSize: 9.5,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}
// Small info box




class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.urbanist(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.urbanist(
            fontSize: 9.5,
            fontWeight: FontWeight.w400,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}
// ---------- Explore Card ----------




class AppleStyleExploreCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String caption;
  final String image;
  final String buttonText;
  final VoidCallback? onTap;

  const AppleStyleExploreCard({
    required this.title,
    required this.subtitle,
    required this.caption,
    required this.image,
    this.buttonText = "Explore",
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
            padding: const EdgeInsets.all(10),
            height: 160,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              children: [
                // LEFT IMAGE
                Container(
                  height: double.infinity,
                  width: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    image: DecorationImage(
                      image: AssetImage(image),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // RIGHT TEXT + BUTTON
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: GoogleFonts.lexend(
                          fontSize: 20,
                          fontWeight: FontWeight.normal,
                          color: Colors.white,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: GoogleFonts.urbanist(
                          fontSize: 12.5,
                          color: Colors.white.withOpacity(0.75),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        caption,
                        style: GoogleFonts.urbanist(
                          fontSize: 11.5,
                          color: Colors.white.withOpacity(0.45),
                        ),
                      ),
                      const Spacer(),

                      // BUTTON
                      TextButton(
                        onPressed: onTap,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2), // ↓ thinner
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          minimumSize: const Size(0, 28), // Optional: set a smaller min height
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Optional: removes extra touch padding
                        ),
                        child: Text(
                          buttonText,
                          style: GoogleFonts.urbanist(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ),
    );
  }
}
// ---------- Navbar ----------//




class GlassUpcomingEventsCard extends StatelessWidget {
  final String title;
  final String date;
  final String time;
  final String location;
  final String image;

  const GlassUpcomingEventsCard({
    required this.title,
    required this.date,
    required this.time,
    required this.location,
    required this.image,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
          width: double.infinity,
          height: 200,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.05),
                Colors.white.withOpacity(0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          child: Stack(
            children: [
              // Background image on the right
              Positioned(
                right: 0,
                bottom: 0,
                top: 0,
                child: Opacity(
                  opacity: 0.15,
                  child: Image.asset(
                    image,
                    width: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Event info
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Neon dot + label
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.deepOrangeAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepOrangeAccent.withOpacity(0.6),
                              blurRadius: 6,
                              spreadRadius: 1,
                            )
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Live Soon",
                        style: GoogleFonts.urbanist(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: GoogleFonts.urbanist(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: Colors.white54),
                      const SizedBox(width: 5),
                      Text(
                        date,
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.access_time, size: 12, color: Colors.white54),
                      const SizedBox(width: 5),
                      Text(
                        time,
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 12, color: Colors.white54),
                      const SizedBox(width: 5),
                      Text(
                        location,
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      backgroundColor: Colors.white.withOpacity(0.08),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      "Notify Me",
                      style: GoogleFonts.urbanist(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
    );
  }
}