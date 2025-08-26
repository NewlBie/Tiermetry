import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shimmer/shimmer.dart';

// --- Placeholder Pages (for navigation) ---
class SkillBrowserPage extends StatelessWidget {
  const SkillBrowserPage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text("Skill Browser")));
}
class EventBrowserPage extends StatelessWidget {
  const EventBrowserPage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text("Event Browser")));
}


// --- 1. DATA MODELS ---
// Represents the structure for a skill.
class Skill {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String badge;
  final String image;
  final String time;
  final String level;
  final String price;
  final String oldPrice;
  final double rating;

  Skill({
    required this.id,
    required this.title,
    required this.subtitle,
    this.category = "Content Creation",
    required this.badge,
    required this.image,
    required this.time,
    required this.level,
    required this.price,
    required this.oldPrice,
    this.rating = 4.9,
  });
}

// Represents the structure for an event.
class Event {
  final String id;
  final String title;
  final String date;
  final String time;
  final String location;
  final String image;

  Event({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.location,
    required this.image,
  });
}

// --- 2. MOCK API SERVICE ---
// Simulates fetching data from a backend server.
class ApiService {
  Future<List<Skill>> getFeaturedSkills() async {
    // Simulate a network delay
    await Future.delayed(const Duration(seconds: 2));
    return [
      Skill(
        id: '1',
        title: "YouTube Masterclass",
        subtitle: "Learn from MKBHD",
        badge: "Sponsored",
        image: 'assets/skills_side.png',
        time: "1h 30m",
        level: "Intermediate",
        price: "\$80",
        oldPrice: "\$100",
      ),
      Skill(
        id: '2',
        title: "Viral Video Editing",
        subtitle: "with Adobe Premiere Pro",
        badge: "New",
        image: 'assets/Hackathon.jpg', // Replace with relevant image
        time: "2h 45m",
        level: "Beginner",
        price: "\$60",
        oldPrice: "\$90",
      ),
    ];
  }

  Future<List<Event>> getUpcomingEvents() async {
    await Future.delayed(const Duration(seconds: 2));
    return [
      Event(
        id: '1',
        title: "Flutter Hackathon 2025",
        date: "12 July 2025",
        time: "10:00 AM",
        location: "Bhubaneswar Tech Park",
        image: 'assets/Hackathon.jpg',
      ),
      Event(
        id: '2',
        title: "Tech Innovators Meetup",
        date: "18 Aug 2025",
        time: "6:00 PM",
        location: "Online",
        image: 'assets/arena color.png', // Replace with relevant image
      ),
    ];
  }
}

// --- 3. MAIN HOME TAB WIDGET ---
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final ApiService _apiService = ApiService();
  late Future<List<Skill>> _featuredSkillsFuture;
  late Future<List<Event>> _upcomingEventsFuture;

  @override
  void initState() {
    super.initState();
    _featuredSkillsFuture = _apiService.getFeaturedSkills();
    _upcomingEventsFuture = _apiService.getUpcomingEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF0A0A0A),
            pinned: true,
            expandedHeight: 120.0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              title: Text(
                "Hello Neal 👋",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              centerTitle: false,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  const _MetricCardsSection(),
                  const SizedBox(height: 24),
                  const GlassPromoCard(),
                  const SizedBox(height: 32),
                  const _ExploreSection(),
                  const SizedBox(height: 32),
                  _SectionHeader(
                    title: 'Featured Skills',
                    onViewMore: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SkillBrowserPage())),
                  ),
                  const SizedBox(height: 12),
                  _FeaturedSkillsList(skillsFuture: _featuredSkillsFuture),
                  const SizedBox(height: 32),
                  _SectionHeader(
                    title: 'Upcoming Events',
                    onViewMore: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventBrowserPage())),
                  ),
                  const SizedBox(height: 12),
                  _UpcomingEventsList(eventsFuture: _upcomingEventsFuture),
                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- UI SECTIONS (Refactored) ---

class _MetricCardsSection extends StatelessWidget {
  const _MetricCardsSection();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: ListView(
        scrollDirection: Axis.horizontal,
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
    );
  }
}

class _ExploreSection extends StatelessWidget {
  const _ExploreSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Explore',
          style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
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
      ],
    );
  }
}

class _FeaturedSkillsList extends StatelessWidget {
  final Future<List<Skill>> skillsFuture;
  const _FeaturedSkillsList({required this.skillsFuture});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: FutureBuilder<List<Skill>>(
        future: skillsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _ShimmerLoadingList(itemWidth: 260, itemCount: 2);
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No skills found.", style: TextStyle(color: Colors.white70)));
          }
          final skills = snapshot.data!;
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: skills.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, index) {
              return _AnimatedListItem(
                index: index,
                child: SizedBox(
                  width: 260,
                  child: FeaturedSkillMorphCard(skill: skills[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _UpcomingEventsList extends StatelessWidget {
  final Future<List<Event>> eventsFuture;
  const _UpcomingEventsList({required this.eventsFuture});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: FutureBuilder<List<Event>>(
        future: eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _ShimmerLoadingList(itemWidth: 300, itemCount: 1);
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No events found.", style: TextStyle(color: Colors.white70)));
          }
          final events = snapshot.data!;
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, index) {
              return _AnimatedListItem(
                index: index,
                child: SizedBox(
                  width: 300,
                  child: GlassUpcomingEventsCard(event: events[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}


// --- ENHANCED & REFACTORED WIDGETS ---

class AppleBlurMetricCard extends StatefulWidget {
  final String label;
  final String value;
  final String unit;
  final String backgroundImage;

  const AppleBlurMetricCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.backgroundImage,
    super.key,
  });

  @override
  State<AppleBlurMetricCard> createState() => _AppleBlurMetricCardState();
}

class _AppleBlurMetricCardState extends State<AppleBlurMetricCard> {
  double _dx = 0;
  double _dy = 0;
  StreamSubscription? _gyroscopeSubscription;

  @override
  void initState() {
    super.initState();
    _gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      setState(() {
        _dx += event.y * 0.4; // Sensitivity factor
        _dy -= event.x * 0.4;
        _dx = _dx.clamp(-20, 20); // Clamp values to avoid excessive tilt
        _dy = _dy.clamp(-20, 20);
      });
    });
  }

  @override
  void dispose() {
    _gyroscopeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _dx += details.delta.dx * 0.5;
          _dy += details.delta.dy * 0.5;
          _dx = _dx.clamp(-20, 20);
          _dy = _dy.clamp(-20, 20);
        });
      },
      onPanEnd: (_) {
        setState(() {
          _dx = 0;
          _dy = 0;
        });
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(0.01 * _dy * value)
              ..rotateY(-0.01 * _dx * value),
            alignment: FractionalOffset.center,
            child: child,
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 130,
            height: 130,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(widget.backgroundImage),
                fit: BoxFit.cover,
              ),
              color: Colors.black.withOpacity(0.25),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  widget.label,
                  style: GoogleFonts.urbanist(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(children: [
                    TextSpan(
                      text: widget.value,
                      style: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    TextSpan(
                      text: " ${widget.unit}",
                      style: GoogleFonts.urbanist(fontSize: 14, color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.w400),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GlassPromoCard extends StatelessWidget {
  const GlassPromoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
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
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.4,
                    colors: [Colors.white.withOpacity(0.06), Colors.transparent],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              child: Row(
                children: [
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Feel the Power of Play',
                          style: GoogleFonts.urbanist(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Subscribe to unlock rewards and pro-level perks.',
                          style: GoogleFonts.urbanist(fontSize: 13, color: Colors.white.withOpacity(0.7), height: 1.4),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.white, Colors.white.withOpacity(0.85)],
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
                                style: GoogleFonts.urbanist(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 13.5),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.black),
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

class FeaturedSkillMorphCard extends StatefulWidget {
  final Skill skill;

  const FeaturedSkillMorphCard({
    required this.skill,
    super.key,
  });

  @override
  State<FeaturedSkillMorphCard> createState() => _FeaturedSkillMorphCardState();
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
        child: Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned.fill(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutExpo,
                      decoration: BoxDecoration(
                        color: expanded ? const Color(0xFF1A1A1A) : Colors.white,
                      ),
                    )
                ),
                Positioned.fill(
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      expanded ? Colors.black.withOpacity(0.3) : Colors.transparent,
                      BlendMode.darken,
                    ),
                    child: Image.asset(
                      widget.skill.image,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (!expanded)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                          begin: Alignment.topCenter,
                          end: const Alignment(0, -0.2),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (expanded)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.skill.category.toUpperCase(),
                              style: GoogleFonts.urbanist(fontSize: 11, color: Colors.white70, letterSpacing: 0.5),
                            ),
                            AnimatedSlide(
                              duration: const Duration(milliseconds: 500),
                              offset: expanded ? Offset.zero : const Offset(0.5, 0),
                              curve: Curves.easeOutBack,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 500),
                                opacity: expanded ? 1.0 : 0.0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                                  child: Text("Enroll", style: GoogleFonts.urbanist(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      Text(
                        widget.skill.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.urbanist(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          shadows: !expanded
                              ? [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4, offset: const Offset(0, 1))]
                              : [],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.skill.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.urbanist(
                          fontSize: 12.5,
                          color: Colors.white70,
                          shadows: !expanded
                              ? [Shadow(color: Colors.black.withOpacity(0.4), blurRadius: 3, offset: const Offset(0, 1))]
                              : [],
                        ),
                      ),
                      const Spacer(),
                      if (expanded)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _AnimatedStat(title: "${widget.skill.rating} ★", label: "RATING", index: 0),
                            _AnimatedStat(title: widget.skill.level, label: "LEVEL", index: 1),
                            _AnimatedStat(title: widget.skill.time, label: "TIME", index: 2),
                            _AnimatedStat(title: "EN", label: "LANG", index: 3),
                          ],
                        ),
                      if (!expanded)
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
                            child: Text(
                              widget.skill.badge,
                              style: GoogleFonts.urbanist(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w500),
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

class _AnimatedStat extends StatelessWidget {
  final String title;
  final String label;
  final int index;
  const _AnimatedStat({required this.title, required this.label, required this.index});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 20.0, end: 0.0),
      duration: Duration(milliseconds: 300 + (index * 70)),
      curve: Curves.easeOutExpo,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, value),
          child: Opacity(opacity: (20.0 - value) / 20.0, child: child),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.urbanist(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white)),
          Text(label, style: GoogleFonts.urbanist(fontSize: 9.5, color: Colors.white54, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

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
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                height: double.infinity,
                width: 140,
                child: Image.asset(image, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(title, style: GoogleFonts.lexend(fontSize: 20, fontWeight: FontWeight.normal, color: Colors.white, height: 1.25)),
                  const SizedBox(height: 6),
                  Text(subtitle, style: GoogleFonts.urbanist(fontSize: 12.5, color: Colors.white.withOpacity(0.75))),
                  const SizedBox(height: 6),
                  Text(caption, style: GoogleFonts.urbanist(fontSize: 11.5, color: Colors.white.withOpacity(0.45))),
                  const Spacer(),
                  TextButton(
                    onPressed: onTap,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      minimumSize: const Size(0, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      buttonText,
                      style: GoogleFonts.urbanist(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GlassUpcomingEventsCard extends StatelessWidget {
  final Event event;

  const GlassUpcomingEventsCard({required this.event, super.key});

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
            colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              bottom: 0,
              top: 0,
              child: Opacity(
                opacity: 0.15,
                child: Image.asset(event.image, width: 120, fit: BoxFit.cover),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: Colors.deepOrangeAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.deepOrangeAccent.withOpacity(0.6), blurRadius: 6, spreadRadius: 1)
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text("Live Soon", style: GoogleFonts.urbanist(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.7))),
                  ],
                ),
                const SizedBox(height: 10),
                Text(event.title, style: GoogleFonts.urbanist(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 12, color: Colors.white54),
                    const SizedBox(width: 5),
                    Text(event.date, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(width: 10),
                    const Icon(Icons.access_time, size: 12, color: Colors.white54),
                    const SizedBox(width: 5),
                    Text(event.time, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 12, color: Colors.white54),
                    const SizedBox(width: 5),
                    Text(event.location, style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
                  child: Text("Notify Me", style: GoogleFonts.urbanist(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


// --- UTILITY WIDGETS ---

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onViewMore;
  const _SectionHeader({required this.title, required this.onViewMore});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
        TextButton(
          onPressed: onViewMore,
          child: Text("View More", style: GoogleFonts.inter(color: Colors.white60)),
        ),
      ],
    );
  }
}

class _AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  const _AnimatedListItem({required this.child, required this.index});

  @override
  State<_AnimatedListItem> createState() => __AnimatedListItemState();
}

class __AnimatedListItemState extends State<_AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.decelerate,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.2, 0.0),
      end: Offset.zero,
    ).animate(curve);
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(curve);

    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if(mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _offsetAnimation,
        child: widget.child,
      ),
    );
  }
}


class _ShimmerLoadingList extends StatelessWidget {
  final double itemWidth;
  final int itemCount;
  const _ShimmerLoadingList({required this.itemWidth, this.itemCount = 1});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[900]!,
      highlightColor: Colors.grey[800]!,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => Container(
          width: itemWidth,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }
}