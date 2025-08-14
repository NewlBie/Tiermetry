import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EventCarousel extends StatefulWidget {
  const EventCarousel({super.key});

  @override
  State<EventCarousel> createState() => _EventCarouselState();
}

class _EventCarouselState extends State<EventCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;
  Timer? _timer;

  final List<Map<String, dynamic>> events = [
    {
      'image': 'assets/f00f6d5b.png',
      'title': 'Weekly All-hands',
      'subtitle': 'A supportive space to share, heal, and grow alongside others who understand',
      'time': 'Today, 13:45',
      'tags': ['Community', 'Growth']
    },
    {
      'image': 'assets/arena color.png',
      'title': 'Gaming Night 2.0',
      'subtitle': 'Let the arena decide the best player this weekend',
      'time': 'Friday, 8:00 PM',
      'tags': ['Gaming', 'Esports']
    },
    {
      'image': 'assets/Skills color.png',
      'title': 'Design Mastery',
      'subtitle': 'From UI to motion — learn how pros think',
      'time': 'Monday, 6:00 PM',
      'tags': ['Design', 'Tech']
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % events.length;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: PageView.builder(
        controller: _pageController,
        itemCount: events.length,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double scale = 1.0;
              if (_pageController.position.haveDimensions) {
                scale = (_pageController.page! - index).abs();
                scale = (1 - (scale * 0.15)).clamp(0.88, 1.0);
              }
              return Center(
                child: Transform.scale(
                  scale: scale,
                  child: child,
                ),
              );
            },
            child: _ModernEventCard(
              image: events[index]['image'],
              title: events[index]['title'],
              subtitle: events[index]['subtitle'],
              time: events[index]['time'],
              tags: events[index]['tags'],
              onAddToCalendar: () {
                print('Added to calendar: ${events[index]['title']}');
              },
            ),
          );
        },
      ),
    );
  }
}

class _ModernEventCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final List<String> tags;
  final String image;
  final VoidCallback onAddToCalendar;

  const _ModernEventCard({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.tags,
    required this.image,
    required this.onAddToCalendar,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          // Background image
          Image.asset(
            image,
            width: double.infinity,
            height: 260,
            fit: BoxFit.cover,
          ),

          // Gradient overlay
          Container(
            height: 260,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.55),
                  Colors.black.withOpacity(0.2),
                  Colors.transparent,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),

          // Content
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time pill + more icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          time,
                          style: GoogleFonts.urbanist(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Icon(Icons.more_horiz, color: Colors.white70),
                    ],
                  ),

                  const Spacer(),

                  // Tags
                  Row(
                    children: tags.map((tag) {
                      return Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tag,
                          style: GoogleFonts.urbanist(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 10),

                  // Title
                  Text(
                    title,
                    style: GoogleFonts.urbanist(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Subtitle
                  Text(
                    subtitle,
                    style: GoogleFonts.urbanist(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Add to calendar button
                  GestureDetector(
                    onTap: onAddToCalendar,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Center(
                        child: Text(
                          'Add to calendar',
                          style: GoogleFonts.urbanist(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
