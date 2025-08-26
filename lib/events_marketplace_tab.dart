import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/skill.dart';
import '../models/event.dart';
import '../services/api_service.dart';
import '../event_carousel.dart';
import '../skill_browser_page.dart';
import '../event_browser_page.dart';
import '../widget/featured_skill_morph_card.dart';
import '../widget/glass_upcoming_events_card.dart';
import '../widget/utility_widgets.dart';

class EventsMarketplaceTab extends StatefulWidget {
  const EventsMarketplaceTab({super.key});

  @override
  State<EventsMarketplaceTab> createState() => _EventsMarketplaceTabState();
}

class _EventsMarketplaceTabState extends State<EventsMarketplaceTab> {
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
              centerTitle: false,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Hello, Explorer 👋", style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.white70)),
                  Text("Balance Fun & Growth", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            ),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 20.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white10,
                  radius: 20,
                  child: Icon(Icons.person, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  const SizedBox(height: 16),

                  // This is the corrected implementation
                  FutureBuilder<List<Event>>(
                    future: _upcomingEventsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const ShimmerCarouselPlaceholder();
                      }
                      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                        return const SizedBox(height: 200, child: Center(child: Text("Could not load events.")));
                      }
                      return EventCarousel(events: snapshot.data!);
                    },
                  ),

                  const SizedBox(height: 32),
                  SectionHeader(
                    title: 'Featured Skills',
                    onViewMore: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SkillBrowserPage())),
                  ),
                  const SizedBox(height: 12),
                  _FeaturedSkillsList(skillsFuture: _featuredSkillsFuture),
                  const SizedBox(height: 32),
                  SectionHeader(
                    title: 'Upcoming Events',
                    onViewMore: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventBrowserPage())),
                  ),
                  const SizedBox(height: 12),
                  _UpcomingEventsList(eventsFuture: _upcomingEventsFuture),
                  const SizedBox(height: 32),
                  const _LeaderboardPreviewCard(),
                  const SizedBox(height: 32),
                  _buildInsightCard(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Insight of the Day", style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF3A3A3A), Color(0xFF1E1E1E)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            "Gaming enhances strategic thinking and stress management. Channel it wisely for your growth.",
            style: GoogleFonts.inter(color: Colors.white70, height: 1.5),
          ),
        ),
      ],
    );
  }
}

class _LeaderboardPreviewCard extends StatelessWidget {
  const _LeaderboardPreviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("TODAY'S XP", style: GoogleFonts.urbanist(fontSize: 11, letterSpacing: 0.5, color: Colors.white60, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text("+12", style: GoogleFonts.spaceGrotesk(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                children: [
                  Text("Leaderboard", style: GoogleFonts.urbanist(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white70),
                ],
              )),
        ],
      ),
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
            return const ShimmerLoadingList(itemWidth: 260, itemCount: 2);
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
              return AnimatedListItem(
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
            return const ShimmerLoadingList(itemWidth: 300, itemCount: 1);
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
              return AnimatedListItem(
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