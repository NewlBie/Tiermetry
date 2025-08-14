import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widget/modern_event_card.dart'; // Update path if needed
import '../widget/event_model.dart';

class EventBrowserPage extends StatefulWidget {
  const EventBrowserPage({super.key});

  @override
  State<EventBrowserPage> createState() => _EventBrowserPageState();
}

class _EventBrowserPageState extends State<EventBrowserPage> {
  String query = '';
  String selectedFilter = 'All';

  final filters = ['All', 'Tech', 'Gaming', 'IRL', 'Paid', 'Free', 'Design'];

  final events = [
    EventModel(
      title: 'Flutter Hackathon 2025',
      subtitle: 'Bring your Flutter A-game',
      time: '12 July, 10:00 AM',
      date: '12 July 2025',
      cost: 'Free',
      description: 'Join the ultimate Flutter hackathon and showcase your skills with other talented developers.',
      points: 50,
      tags: ['Tech', 'Free'],
      image: 'assets/Hackathon.jpg',
      enrollments: 3568,
      dateTime: DateTime(2025, 8, 10, 17, 30),
    ),
    EventModel(
      title: 'Design Marathon',
      subtitle: 'From UI to motion — learn how pros think',
      time: '13 July, 4:00 PM',
      date: '13 July 2025',
      cost: '₹499',
      description: 'A full-day design bootcamp packed with talks, hands-on workshops, and panel discussions.',
      points: 70,
      tags: ['Design', 'Paid'],
      image: 'assets/Skills color.png',
      enrollments: 4568,
      dateTime: DateTime(2025, 8, 10, 17, 30),
    ),
    EventModel(
      title: 'Gaming Arena 2.0',
      subtitle: 'Battle it out in the most intense round yet',
      time: '14 July, 8:00 PM',
      date: '14 July 2025',
      cost: '₹299',
      description: 'Enter the Arena for a night of adrenaline, prizes, and the best multiplayer games.',
      points: 40,
      tags: ['Gaming', 'IRL'],
      image: 'assets/arena color.png',
      enrollments: 1968,
      dateTime: DateTime(2025, 8, 10, 17, 30),
    ),
  ];


  @override
  Widget build(BuildContext context) {
    final filteredEvents = events.where((EventModel event) {
      final title = event.title;
      final tags = event.tags;
      final matchesQuery = query.isEmpty || title.toLowerCase().contains(query.toLowerCase());
      final matchesFilter = selectedFilter == 'All' || tags.contains(selectedFilter);
      return matchesQuery && matchesFilter;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Explore Events",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // Search Bar
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                onChanged: (val) => setState(() => query = val),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search amazing events',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Filter Chips
            SizedBox(
              height: 42,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                itemBuilder: (_, index) {
                  final f = filters[index];
                  final selected = f == selectedFilter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => setState(() => selectedFilter = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? Colors.white : Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: selected
                              ? [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ]
                              : [],
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            color: selected ? Colors.black : Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Event Cards
            Expanded(
              child: filteredEvents.isEmpty
                  ? const Center(
                child: Text(
                  "No matching events found.",
                  style: TextStyle(color: Colors.white38),
                ),
              )
                  : ListView.separated(
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: filteredEvents.length,
                separatorBuilder: (_, __) => const SizedBox(height: 18),
                itemBuilder: (_, index) {
                  final e = filteredEvents[index] as EventModel;

                  return ModernEventCard(
                    title: e.title,
                    subtitle: e.subtitle,
                    time: e.time,
                    image: e.image,
                    tags: e.tags,
                    onAddToCalendar: () {
                      // TODO: Add to calendar
                      print('Added "${e.title}" to calendar.');
                    },
                    event: e, // 🔥 THIS FIXES YOUR ERROR
                  );
                },

              ),
            ),
          ],
        ),
      ),
    );
  }
}
