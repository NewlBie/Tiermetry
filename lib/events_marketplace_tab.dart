// 📦 Enhanced Events Marketplace Tab (Apple/Netflix Inspired)
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'event_carousel.dart';
import 'skill_browser_page.dart';
import 'event_browser_page.dart';
import 'home_tab.dart'; // for card widgets

class EventsMarketplaceTab extends StatefulWidget {
  const EventsMarketplaceTab({super.key});

  @override
  State<EventsMarketplaceTab> createState() => _EventsMarketplaceTabState();
}

class _EventsMarketplaceTabState extends State<EventsMarketplaceTab> {
  final List<Map<String, String>> eventCarouselItems = [
    {
      'image': 'assets/Hackathon.jpg',
      'title': 'Flutter Hackathon 2025',
      'subtitle': 'Build the future, today.',
    },
    {
      'image': 'assets/arena color.png',
      'title': 'Tech Summit 2025',
      'subtitle': 'Explore new innovations.',
    },
    {
      'image': 'assets/Skills color.png',
      'title': 'Design Marathon',
      'subtitle': 'Craft, Animate, Innovate.',
    },
  ];

  final skills = [
    {
      'title': "YouTube Masterclass",
      'subtitle': "Learn from MKBHD",
      'badge': "Top Rated",
      'image': 'assets/skills_side.png',
      'time': "1h 30m",
      'level': "Intermediate",
      'price': "\$80",
      'oldPrice': "\$100",
    },
    {
      'title': "Beginner Design Sprint",
      'subtitle': "Intro to UI thinking",
      'badge': "Starter Pack",
      'image': 'assets/Skills color.png',
      'time': "50 mins",
      'level': "Beginner",
      'price': "Free",
      'oldPrice': "",
    },
  ];

  final events = [
    {
      'title': "Flutter Hackathon 2025",
      'date': "12 July 2025",
      'time': "10:00 AM",
      'location': "Bhubaneswar Tech Park",
      'image': 'assets/Hackathon.jpg',
    },
    {
      'title': "Gaming Arena 2.0",
      'date': "14 July 2025",
      'time': "8:00 PM",
      'location': "Chennai Arcade Center",
      'image': 'assets/arena color.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 70),
              // 🎯 Welcome Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Hello, Explorer 👋", style: GoogleFonts.plusJakartaSans(fontSize: 18, color: Colors.white70)),
                      const SizedBox(height: 4),
                      Text("Balance Fun & Growth", style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white)),
                    ],
                  ),
                  const CircleAvatar(
                    backgroundColor: Colors.white10,
                    radius: 20,
                    child: Icon(Icons.person, color: Colors.white),
                  )
                ],
              ),
              const SizedBox(height: 28),

              // 🔥 Hero Carousel
              const EventCarousel(),
              const SizedBox(height: 32),

              // 🎓 Featured Skills Horizontal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Featured Skills", style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SkillBrowserPage())),
                    child: Text("View More", style: GoogleFonts.inter(color: Colors.white60)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 260,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: skills.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, index) {
                    final s = skills[index];
                    return SizedBox(
                        width: 260,
                        height: 260,
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

              // 📅 Upcoming Events Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Upcoming Events", style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventBrowserPage())),
                    child: Text("View More", style: GoogleFonts.inter(color: Colors.white60)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 210,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, index) {
                    final e = events[index];
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
              const SizedBox(height: 32),

              // 🏆 Tiermetry Score & Leaderboard Preview
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Today's XP", style: GoogleFonts.inter(color: Colors.white60)),
                        const SizedBox(height: 4),
                        Text("+12", style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white)),
                      ],
                    ),
                    Text("Leaderboard >", style: GoogleFonts.inter(color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 📈 Insight of the Day
              Text("Insight of the Day", style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF3A3A3A), Color(0xFF1E1E1E)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  "Gaming enhances strategic thinking and stress management. Channel it wisely for your growth.",
                  style: GoogleFonts.inter(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
