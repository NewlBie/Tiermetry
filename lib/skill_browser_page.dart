import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widget/featured_skill_card.dart'; // Make sure this is updated too!

class SkillBrowserPage extends StatefulWidget {
  const SkillBrowserPage({super.key});

  @override
  State<SkillBrowserPage> createState() => _SkillBrowserPageState();
}

class _SkillBrowserPageState extends State<SkillBrowserPage> {
  String query = "";
  String selectedFilter = "All";

  final filters = ["All", "Beginner", "Intermediate", "Advanced", "Free"];

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
    {
      'title': "Figma Animation Tricks",
      'subtitle': "Turn static UIs into life",
      'badge': "Pro Pick",
      'image': 'assets/grad1.png',
      'time': "2h",
      'level': "Advanced",
      'price': "\$99",
      'oldPrice': "\$120",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = skills.where((skill) {
      final matchesQuery = query.isEmpty || skill['title']!.toLowerCase().contains(query.toLowerCase());
      final matchesFilter = selectedFilter == "All" || skill['level'] == selectedFilter || (selectedFilter == "Free" && skill['price'] == "Free");
      return matchesQuery && matchesFilter;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Explore Skills",
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
            // Search Field
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
                  hintText: 'Search amazing skills',
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

            // Skill Cards List
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                child: Text(
                  "No matching skills found.",
                  style: TextStyle(color: Colors.white38),
                ),
              )
                  : ListView.separated(
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 20),
                itemBuilder: (_, index) {
                  final s = filtered[index];
                  return FeaturedSkillMorphCard(
                    title: s['title']!,
                    subtitle: s['subtitle']!,
                    badge: s['badge']!,
                    image: s['image']!,
                    time: s['time']!,
                    level: s['level']!,
                    price: s['price']!,
                    oldPrice: s['oldPrice']!,
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
