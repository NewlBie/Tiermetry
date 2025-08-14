// Enhanced ArenaPage with square image clips, SafeAreas, and Apple-style visuals
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'arena_details_page.dart';

class ArenaPage extends StatefulWidget {
  const ArenaPage({super.key});

  @override
  State<ArenaPage> createState() => _ArenaPageState();
}

class _ArenaPageState extends State<ArenaPage> {

  final List<String> categories = [
    "All",
    "Gaming",
    "Arcade",
    "Sports",
    "Adventure",
    "Events",
    "Tech",
  ];

  String selectedCategory = "All";

  final List<Arena> allArenas = [
    Arena(
      id: 'arena1',
      title: 'Timezone Esplanade',
      imageAsset: 'assets/arena1.jpeg',
      tags: ['Gaming', 'Arcade'],
      rating: 4.5,
      people: 10,
      monitors: 10,
    ),
    Arena(
      id: 'arena2',
      title: 'Go Kart Mania',
      imageAsset: 'assets/kart_arena.png',
      tags: ['Adventure', 'Sports'],
      rating: 4.2,
      people: 8,
      monitors: 6,
    ),
    Arena(
      id: 'arena3',
      title: 'HackZone 24',
      imageAsset: 'assets/Hackathon.jpg',
      tags: ['Tech', 'Events'],
      rating: 4.8,
      people: 12,
      monitors: 15,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: true,
        bottom: true,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D1015), Color(0xFF0D1015)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 100),

                  // 🔍 Glass Search Bar
                  _GlassSearchBar(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 🟢 Dropdown (you’ll implement dropdown here later)
                      GestureDetector(
                        onTap: () async {
                          final selected = await showModalBottomSheet<String>(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const _CategorySelectorSheet(),
                          );

                          if (selected != null && selected != selectedCategory) {
                            setState(() {
                              selectedCategory = selected;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1C),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                selectedCategory,
                                style: GoogleFonts.urbanist(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.expand_more, color: Colors.white54, size: 20),
                            ],
                          ),
                        ),
                      ),


                      // 🟡 Filter Icon
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1C),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.tune, color: Colors.white),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (_) => const _FilterSheet(),
                            );
                          },
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),

                  _sectionTitle("Featured"),
                  const SizedBox(height: 16),
                  ...allArenas
                      .where((arena) =>
                  selectedCategory == "All" ||
                      arena.tags.contains(selectedCategory))
                      .map((arena) => ArenaCard(
                    arena: arena,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ArenaDetailsPage(
                          imageAsset: arena.imageAsset,
                          title: arena.title,
                        ),
                      ),
                    ),
                  ))
                      .toList(),

                  // In the ArenaPage class, replace the vertical offer cards with this:
                  const SizedBox(height: 36),
                  _sectionTitle("Discounts And Offers"),
                  const SizedBox(height: 14),
                  buildOfferCard(),

                  const SizedBox(height: 36),
                  _sectionTitle("Trending Activities"),
                  const SizedBox(height: 16),
                  _TrendingBar("Mortal Kombat", Colors.orangeAccent),
                  _TrendingBar("Fifa", Colors.greenAccent),
                  _TrendingBar("Valorant", Colors.deepOrangeAccent),
                  _TrendingBar("Watchdogs L", Colors.lightBlueAccent),
                  _TrendingBar("Tekken", Colors.tealAccent),
                  _TrendingBar("Pubg", Colors.yellowAccent),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.urbanist(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Colors.white.withOpacity(0.94),
        letterSpacing: -0.3,
      ),
    );
  }
}

Widget _distanceChips() {
  final distances = ['Nearby', '500m', '1km', '5km', '10km+'];
  return Wrap(
    spacing: 12,
    runSpacing: 12,
    children: distances.map((label) {
      final isSelected = false; // Replace with actual state logic
      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.greenAccent
                : Colors.white.withOpacity(0.1),
            width: 1.4,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.greenAccent.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.urbanist(
            color: isSelected ? Colors.black : Colors.white.withOpacity(0.85),
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
      );
    }).toList(),
  );
}


Widget _priceTiers() {
  final tiers = ['₹', '₹₹', '₹₹₹', '₹₹₹₹'];
  return Wrap(
    spacing: 12,
    runSpacing: 12,
    children: tiers.map((label) {
      final isSelected = false; // Replace with state logic
      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.greenAccent
                : Colors.white.withOpacity(0.1),
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.greenAccent.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.urbanist(
            color: isSelected ? Colors.black : Colors.white.withOpacity(0.85),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      );
    }).toList(),
  );
}


Widget _timeOptions() {
  final times = ['Now', 'Morning', 'Afternoon', 'Evening', 'Night'];
  return Wrap(
    spacing: 12,
    runSpacing: 12,
    children: times.map((label) {
      final isSelected = false; // Replace with state logic
      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.greenAccent
                : Colors.white.withOpacity(0.1),
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.greenAccent.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.urbanist(
            color: isSelected ? Colors.black : Colors.white.withOpacity(0.85),
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
      );
    }).toList(),
  );
}


Widget _typeChips() {
  final types = ['Gaming', 'Recreational', 'Arcade'];
  return Wrap(
    spacing: 12,
    runSpacing: 12,
    children: types.map((label) {
      final isSelected = false; // Replace with state logic
      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.greenAccent
                : Colors.white.withOpacity(0.1),
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.greenAccent.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.urbanist(
            color: isSelected ? Colors.black : Colors.white.withOpacity(0.85),
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
      );
    }).toList(),
  );
}


Widget _sortOptions() {
  final sorts = ['Popularity', 'Ratings', 'Lowest Price', 'Fastest'];
  return Wrap(
    spacing: 12,
    runSpacing: 12,
    children: sorts.map((label) {
      final isSelected = false; // Replace with state logic
      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.greenAccent
                : Colors.white.withOpacity(0.1),
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.greenAccent.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.urbanist(
            color: isSelected ? Colors.black : Colors.white.withOpacity(0.85),
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
      );
    }).toList(),
  );
}

class _CategorySelectorSheet extends StatelessWidget {
  const _CategorySelectorSheet({super.key});

  final List<String> options = const [
    'Your Vibe',
    'Gaming',
    'Recreational',
    'Arcade',
    'Trending',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 4,
            width: 40,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          ...options.map((label) {
            return ListTile(
              title: Text(
                label,
                style: GoogleFonts.urbanist(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () => Navigator.pop(context, label),
            );
          }).toList(),
        ],
      ),
    );
  }
}



class _FilterSheet extends StatelessWidget {
  const _FilterSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, controller) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 40,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              _filterTitle("Distance"),
              _distanceChips(),

              _filterTitle("Price"),
              _priceTiers(),

              _filterTitle("Time"),
              _timeOptions(),

              _filterTitle("Type"),
              _typeChips(),

              _filterTitle("Sort By"),
              _sortOptions(),

              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Apply Filters"),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _filterTitle(String text) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 10),
    child: Text(
      text,
      style: GoogleFonts.urbanist(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
  );
}


class Arena {
  final String id;
  final String title;
  final String imageAsset;
  final List<String> tags;
  final double rating;
  final int people;
  final int monitors;

  Arena({
    required this.id,
    required this.title,
    required this.imageAsset,
    required this.tags,
    required this.rating,
    required this.people,
    required this.monitors,
  });

  factory Arena.fromMap(Map<String, dynamic> data, String documentId) {
    return Arena(
      id: documentId,
      title: data['title'] ?? '',
      imageAsset: data['imageAsset'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      rating: (data['rating'] ?? 0).toDouble(),
      people: data['people'] ?? 0,
      monitors: data['monitors'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'imageAsset': imageAsset,
    'tags': tags,
    'rating': rating,
    'people': people,
    'monitors': monitors,
  };
}

class CategoryChipsBar extends StatefulWidget {
  final List<String> categories;
  final String selected;
  final Function(String) onSelect;

  const CategoryChipsBar({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  @override
  State<CategoryChipsBar> createState() => _CategoryChipsBarState();
}

class _CategoryChipsBarState extends State<CategoryChipsBar> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          final tag = widget.categories[index];
          final isSelected = tag == widget.selected;
          return GestureDetector(
            onTap: () => widget.onSelect(tag),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.white12,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tag,
                style: GoogleFonts.urbanist(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// 🔍 Glassy Search Bar
class _GlassSearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.white54),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white38,
                  decoration: InputDecoration(
                    hintText: "Search arenas, activities...",
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🧊 Arena Card
class ArenaCard extends StatelessWidget {
  final Arena arena;
  final VoidCallback? onTap;

  const ArenaCard({
    super.key,
    required this.arena,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 135,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.035),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // 🎯 Image
            Padding(
              padding: const EdgeInsets.all(12),
              child: Stack(
                children: [
                  Hero(
                    tag: arena.imageAsset,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        arena.imageAsset,
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "Ad",
                        style: GoogleFonts.urbanist(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 📋 Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 14, right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + Verified
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 5,
                      children: [
                        Text(
                          arena.title,
                          style: GoogleFonts.urbanist(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SvgPicture.asset(
                          'assets/verified.svg',
                          height: 16,
                          width: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Rating, People, Monitors, Tag
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text("4.5", style: _infoTextStyle()),

                        const SizedBox(width: 10),
                        const Icon(Icons.group, size: 14, color: Colors.greenAccent),
                        const SizedBox(width: 4),
                        Text("10", style: _infoTextStyle()),

                        const SizedBox(width: 10),
                        const Icon(Icons.monitor, size: 14, color: Colors.cyanAccent),
                        const SizedBox(width: 4),
                        Text("10", style: _infoTextStyle()),

                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            arena.tags.first,
                            style: GoogleFonts.urbanist(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.greenAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Games
                    Text(
                      "PS5, Fifa 23, Gaming PC, VR, Valorant, Dota 2, Pubg",
                      style: GoogleFonts.urbanist(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),

                    // Location + Time
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: "Shaheed Nagar · ",
                            style: _locationTextStyle(),
                          ),
                          TextSpan(
                            text: "Open",
                            style: _locationTextStyle().copyWith(color: Colors.greenAccent),
                          ),
                          TextSpan(
                            text: " · Closes at 10pm",
                            style: _locationTextStyle(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  TextStyle _infoTextStyle() => const TextStyle(color: Colors.white70, fontSize: 12);

  TextStyle _locationTextStyle() => const TextStyle(color: Colors.white54, fontSize: 11);
}



Widget buildOfferCard() {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF1C1C1E),
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 30,
          offset: const Offset(0, 10),
        ),
      ],
      gradient: const LinearGradient(
        colors: [Color(0xFF2C2C2E), Color(0xFF0A0A0A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.local_offer_rounded,
                size: 22, color: Colors.greenAccent),
            const SizedBox(width: 8),
            Text(
              "Special Arena Discount",
              style: GoogleFonts.urbanist(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          "Get 15% off on all weekday bookings before 5PM.",
          style: GoogleFonts.urbanist(
            color: Colors.white.withOpacity(0.9),
            fontSize: 15,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "USE CODE:",
                style: GoogleFonts.urbanist(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: Colors.black54),
              ),
              const SizedBox(width: 8),
              Text(
                "WEEKDAY15",
                style: GoogleFonts.urbanist(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          "T&Cs apply. Valid till end of month.",
          style: GoogleFonts.urbanist(
            color: Colors.white38,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}




// 📈 Trending Bar
Widget _TrendingBar(String title, Color color) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        const Icon(Icons.circle, size: 10, color: Colors.orange),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            title,
            style: GoogleFonts.urbanist(color: Colors.white, fontSize: 13),
          ),
        ),
        Expanded(
          flex: 5,
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, Colors.blueAccent]),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    ),
  );
}
