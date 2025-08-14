import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'arena_map_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class ArenaDetailsPage extends StatefulWidget {
  final String imageAsset;
  final String title;

  const ArenaDetailsPage({
    super.key,
    required this.imageAsset,
    required this.title,
  });

  @override
  State<ArenaDetailsPage> createState() => _ArenaDetailsPageState();
}

class _ArenaDetailsPageState extends State<ArenaDetailsPage> with TickerProviderStateMixin {
  final Set<String> selectedDevices = {};

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void toggleSelection(String deviceId) {
    setState(() {
      if (selectedDevices.contains(deviceId)) {
        selectedDevices.remove(deviceId);
      } else {
        selectedDevices.add(deviceId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1015),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼️ Banner Image
            Stack(
              children: [
                Hero(
                  tag: widget.imageAsset,
                  child: Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(widget.imageAsset),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                        Colors.black.withOpacity(0.5),
                      ],
                    ),
                  ),
                ),
                // ✅ Verified Badge (bottom-left)
                Positioned(
                  bottom: 16,
                  left: 20,
                  child: SvgPicture.asset(
                    'assets/verified.svg',
                    height: 20,
                    width: 20,
                    color: Colors.white,
                  ),
                ),
                // 🔙 Back Button
                Positioned(
                  top: 50,
                  left: 20,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),

            // 📦 Main Info Section
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF0D1015),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: _buildDetailsContent(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🏷️ Title
        Text(
          widget.title,
          style: GoogleFonts.urbanist(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),

        // ⭐ Ratings Row
        Row(
          children: const [
            Icon(Icons.star, size: 16, color: Colors.amber),
            SizedBox(width: 4),
            Text("4.5", style: TextStyle(color: Colors.white70, fontSize: 13)),
            SizedBox(width: 12),
            Icon(Icons.group, size: 16, color: Colors.greenAccent),
            SizedBox(width: 4),
            Text("10 users", style: TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),

        const SizedBox(height: 20),

        // 🎮 Tags (Devices + Categories)
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            _categoryBadge("Arcade"),
            _categoryBadge("PS5"),
            _categoryBadge("PC"),
            _categoryBadge("VR"),
          ],
        ),

        const SizedBox(height: 24),
        // 📝 Summary
        Text(
          "High-end gaming experience with next-gen consoles, VR, and performance-tuned PCs. Ideal for solo or group play.",
          style: GoogleFonts.urbanist(
            fontSize: 13,
            height: 1.6,
            color: Colors.white70,
          ),
        ),

        const SizedBox(height: 28),

        // 📋 At-a-glance Grid
        _infoTitle("Overview"),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _infoChip("Open: 10AM - 10PM"),
            _infoChip("Tiermetry: 8.9/10"),
            _infoChip("Resolution: 4K"),
            _infoChip("Refresh Rate: 120Hz"),
          ],
        ),

        const SizedBox(height: 28),

        // 🎮 FPS Performance Summary
        _infoTitle("Performance (FPS)"),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 10,
          children: [
            _fpsChip("FIFA", "120"),
            _fpsChip("COD", "100"),
            _fpsChip("Valorant", "144"),
            _fpsChip("Fortnite", "90"),
          ],
        ),

        const SizedBox(height: 28),

        // 🖥️ Unit Availability
        _infoTitle("Available Units"),
        const SizedBox(height: 10),

        // 🎮 PS5s
        _unitRow("🎮 PS5", [
          _unitCard("ps5_1", "PS5 - 1", "FIFA, UFC", "₹120/hr", 'assets/ps5_card.png', isOccupied: false),
          _unitCard("ps5_2", "PS5 - 2", "COD, Fortnite", "₹120/hr", 'assets/ps5_card.png', isOccupied: true),
        ]),
        const SizedBox(height: 28),

        _unitRow("🖥️ Gaming PCs", [
          _unitCard("pc_1", "PC - 1", "Valorant", "₹150/hr", 'assets/pc_card.png', isOccupied: false),
          _unitCard("pc_2", "PC - 2", "With VR headset", "₹160/hr", 'assets/pc_card.png', isOccupied: true),
        ]),

        const SizedBox(height: 28),

        _unitRow("🎮 Nintendo", [
          _unitCard("nin_1", "Nintendo - 1", "Valorant", "₹150/hr", 'assets/pc_card.png', isOccupied: false),
          _unitCard("nin_2", "Nintendo - 1", "With VR headset", "₹160/hr", 'assets/pc_card.png', isOccupied: true),
        ]),

        const SizedBox(height: 36),
        // 🗺️ View on Map Button
        TextButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ArenaMapPage()),
            );
          },
          icon: const Icon(Icons.map_rounded, color: Colors.greenAccent),
          label: Text(
            "View on Map",
            style: GoogleFonts.urbanist(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.greenAccent,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // 🔘 Book Now
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: selectedDevices.isEmpty
                ? null
                : () {
              print("Booking: $selectedDevices");
              _showBookingSheet(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              disabledBackgroundColor: Colors.grey.shade800,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              "Book Selected Devices",
              style: GoogleFonts.urbanist(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }


  Widget _infoTitle(String label) {
    return Text(
      label,
      style: GoogleFonts.urbanist(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white.withOpacity(0.9),
      ),
    );
  }

  Widget _infoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text,
          style: GoogleFonts.urbanist(fontSize: 12, color: Colors.white70)),
    );
  }

  Widget _fpsChip(String game, String fps) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text("$game: $fps fps",
          style: GoogleFonts.urbanist(fontSize: 12, color: Colors.white70)),
    );
  }

  Widget _unitRow(String label, List<Widget> units) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.urbanist(fontSize: 13, color: Colors.white60)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: units),
        )
      ],
    );
  }

  Widget _unitCard(
      String id,
      String name,
      String desc,
      String price,
      String imgPath, {
        bool isOccupied = false,
      }) {
    bool isSelected = selectedDevices.contains(id);

    // Default gradient for selected / available
    Gradient staticGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isSelected
          ? [const Color(0xFF1F1F1F), const Color(0xFF3A3A3A)]
          : [const Color(0xFFF4F4F4), const Color(0xFFEDEDED)],
    );

    Widget cardContent(Gradient gradient) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 160,
        height: 200,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(28),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28), // Same as container
          child: Stack(
            children: [
              // Image Behind - now properly clipped
              Positioned.fill(
                child: Opacity(
                  opacity: isOccupied ? 0.25 : 1.0,
                  child: Image.asset(
                    imgPath,
                    fit: BoxFit.cover, // Changed to cover to fill the space
                  ),
                ),
              ),

              // Text content aligned to bottom
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.urbanist(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isOccupied
                              ? Colors.white
                              : (isSelected ? Colors.white : Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        style: GoogleFonts.urbanist(
                          fontSize: 11,
                          color: isOccupied
                              ? Colors.white70
                              : (isSelected ? Colors.white60 : Colors.black54),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        price,
                        style: GoogleFonts.urbanist(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isOccupied
                              ? Colors.white
                              : (isSelected ? Colors.white : Colors.green.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isOccupied) {
      // 🔁 Animate black-red gradient for occupied
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final animationValue = _controller.value;
          final gradient = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(Colors.black, Colors.red.shade900, animationValue)!,
              Color.lerp(Colors.red.shade900, Colors.black, animationValue)!,
            ],
          );
          return cardContent(gradient);
        },
      );
    } else {
      return GestureDetector(
        onLongPress: () {
          if (!isOccupied) toggleSelection(id);
        },
        child: cardContent(staticGradient),
      );
    }
  }

  void _showBookingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return TiermetryBookingSheet(
          selectedDevices: selectedDevices.toList(),
          onConfirm: ({
            required int duration,
            required TimeOfDay startTime,
            required int players,
            required List<String> addOns,
          }) {
            Navigator.pop(context);

            final formattedTime = startTime.format(context);
            final endTime = TimeOfDay(
              hour: (startTime.hour + duration) % 24,
              minute: startTime.minute,
            ).format(context);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "📦 Booked ${selectedDevices.length} device(s) for $duration hr ($formattedTime - $endTime)\nPlayers: $players | Add-ons: ${addOns.join(", ")}",
                ),
                backgroundColor: Colors.greenAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        );
      },
    );
  }


  Widget _categoryBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.urbanist(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.greenAccent,
        ),
      ),
    );
  }
}


class TiermetryBookingSheet extends StatefulWidget {
  final List<String> selectedDevices;
  final void Function({
  required int duration,
  required TimeOfDay startTime,
  required int players,
  required List<String> addOns,
  }) onConfirm;

  const TiermetryBookingSheet({
    super.key,
    required this.selectedDevices,
    required this.onConfirm,
  });

  @override
  State<TiermetryBookingSheet> createState() => _TiermetryBookingSheetState();
}

class _TiermetryBookingSheetState extends State<TiermetryBookingSheet>
    with SingleTickerProviderStateMixin {
  int _duration = 1;
  TimeOfDay _startTime = TimeOfDay.now();
  int _players = 1;
  final Set<String> _addOns = {};
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get baseRate => 120;
  double get totalCost =>
      (baseRate * widget.selectedDevices.length * _duration) + (_addOns.length * 30 * _duration);

  void _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final endHour = (_startTime.hour + _duration) % 24;
    final endMinute = _startTime.minute;
    final endTime = TimeOfDay(hour: endHour, minute: endMinute);

    return FadeTransition(
      opacity: _fadeAnim,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 40,
              offset: const Offset(0, -6),
            )
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              Text(
                "Rig Loaded. Ready for Deployment",
                style: GoogleFonts.urbanist(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 28),

              // 📦 Selected Devices
              ...widget.selectedDevices.map((device) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(device,
                        style: GoogleFonts.urbanist(
                            color: Colors.white, fontSize: 16)),
                    Text("₹$baseRate/hr",
                        style: GoogleFonts.urbanist(
                            color: Colors.white54, fontSize: 15)),
                  ],
                ),
              )),

              const SizedBox(height: 30),
              Text("Duration & Time Slot",
                  style:
                  GoogleFonts.urbanist(color: Colors.white60, fontSize: 14)),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickStartTime,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          "⏰ Start: ${_startTime.format(context)}",
                          style: GoogleFonts.urbanist(color: Colors.white70),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: CupertinoSlidingSegmentedControl<int>(
                      groupValue: _duration,
                      onValueChanged: (val) => setState(() => _duration = val ?? 1),
                      thumbColor: Colors.white,
                      backgroundColor: Colors.white10,
                      children: {
                        1: Text("1h", style: TextStyle(color: Colors.black)),
                        2: Text("2h", style: TextStyle(color: Colors.black)),
                        3: Text("3h", style: TextStyle(color: Colors.black)),
                        4: Text("4h", style: TextStyle(color: Colors.black)),
                        5: Text("5h", style: TextStyle(color: Colors.black)),
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text("🕘 Ends at: ${endTime.format(context)}",
                  style:
                  GoogleFonts.urbanist(color: Colors.white38, fontSize: 12)),

              const SizedBox(height: 30),
              Text("Players & Add-ons",
                  style:
                  GoogleFonts.urbanist(color: Colors.white60, fontSize: 14)),
              const SizedBox(height: 12),

              Row(
                children: [
                  Text("👥 Players:",
                      style:
                      GoogleFonts.urbanist(color: Colors.white54, fontSize: 14)),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () => setState(() => _players = (_players - 1).clamp(1, 8)),
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.white60, size: 20),
                  ),
                  Text("$_players",
                      style: GoogleFonts.urbanist(color: Colors.white, fontSize: 16)),
                  IconButton(
                    onPressed: () => setState(() => _players = (_players + 1).clamp(1, 8)),
                    icon: const Icon(Icons.add_circle_outline,
                        color: Colors.white60, size: 20),
                  ),
                ],
              ),

              const SizedBox(height: 6),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _addonChip("🎧 Headset"),
                  _addonChip("🎮 Pro Controller"),
                  _addonChip("⚡ FPS Boost"),
                ],
              ),

              const SizedBox(height: 32),
              Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 12),

              Text("Confidence Before Confirmation",
                  style: GoogleFonts.urbanist(
                      fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 6),
              Text("📍 Arena: Tiermetry Arcade",
                  style: GoogleFonts.urbanist(color: Colors.white54, fontSize: 13)),
              Text("📆 Today, ${_startTime.format(context)} - ${endTime.format(context)}",
                  style: GoogleFonts.urbanist(color: Colors.white54, fontSize: 13)),
              Text("📱 Contact: +91 9876543210",
                  style: GoogleFonts.urbanist(color: Colors.white54, fontSize: 13)),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total",
                      style: GoogleFonts.urbanist(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: Colors.white)),
                  Text("₹${totalCost.toInt()}",
                      style: GoogleFonts.urbanist(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.greenAccent)),
                ],
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  onPressed: () {
                    widget.onConfirm(
                      duration: _duration,
                      startTime: _startTime,
                      players: _players,
                      addOns: _addOns.toList(),
                    );
                  },
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: Text("Confirm Booking",
                      style: GoogleFonts.urbanist(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addonChip(String label) {
    final isSelected = _addOns.contains(label);
    return ChoiceChip(
      label: Text(label,
          style: GoogleFonts.urbanist(
              color: isSelected ? Colors.black : Colors.black,
              fontSize: 13)),
      selected: isSelected,
      selectedColor: Colors.lightGreenAccent,
      backgroundColor: Colors.white12,
      onSelected: (val) {
        setState(() {
          if (val) {
            _addOns.add(label);
          } else {
            _addOns.remove(label);
          }
        });
      },
    );
  }
}
