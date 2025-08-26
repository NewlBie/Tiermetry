import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

// Assuming these files exist in your project structure
import 'package:tiermetry/models/arena.dart'; // Your existing Arena model
import 'arena_map_page.dart';
import 'package:tiermetry/services/api_service.dart'; // New file for mock data

// The main details page widget, now driven by an Arena object
class ArenaDetailsPage extends StatefulWidget {
  // Instead of individual properties, we pass the entire Arena object.
  // This makes the widget reusable and data-driven.
  final Arena arena;

  const ArenaDetailsPage({
    super.key,
    required this.arena,
  });

  @override
  State<ArenaDetailsPage> createState() => _ArenaDetailsPageState();
}

class _ArenaDetailsPageState extends State<ArenaDetailsPage> {
  // State to hold the detailed arena data, which would be fetched from a backend.
  late Future<FullArenaDetails?> _arenaDetailsFuture;
  final Set<String> selectedDevices = {};

  @override
  void initState() {
    super.initState();
    // In a real app, this would be an API call. We simulate it with a mock service.
    _arenaDetailsFuture = ApiService().getArenaDetails(widget.arena.id);
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
    const scaffoldColor = Color(0xFF101010);
    const accentColor = Color(0xFF0A84FF);

    return Scaffold(
      backgroundColor: scaffoldColor,
      body: FutureBuilder<FullArenaDetails?>(
        future: _arenaDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show a loading indicator while fetching data
            return const Center(child: CupertinoActivityIndicator(radius: 15, color: Colors.white));
          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            // Show an error message if data fetching fails
            return const Center(child: Text("Failed to load arena details.", style: TextStyle(color: Colors.white)));
          }

          final arenaDetails = snapshot.data!;

          // Once data is loaded, build the main UI
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(context, arenaDetails),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: _buildDetailsContent(context, arenaDetails, accentColor),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomBookingBar(context, accentColor),
    );
  }

  // UI building methods now take the `FullArenaDetails` object to populate data

  Widget _buildSliverAppBar(BuildContext context, FullArenaDetails arena) {
    return SliverAppBar(
      expandedHeight: 320.0,
      backgroundColor: const Color(0xFF101010),
      pinned: true,
      stretch: true,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: arena.image, // Use image from the model
              child: Image.asset(arena.image, fit: BoxFit.cover),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                    const Color(0xFF101010).withOpacity(1),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            if (arena.isVerified)
              Positioned(
                bottom: 16,
                left: 20,
                child: Row(
                  children: [
                    SvgPicture.asset('assets/verified.svg', height: 22, width: 22, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                    const SizedBox(width: 8),
                    Text("Verified Partner", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                  ],
                ),
              ),
          ],
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 16.0, top: 12.0),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsContent(BuildContext context, FullArenaDetails arena, Color accentColor) {
    const textColorPrimary = Colors.white;
    const textColorSecondary = Color(0xFF8E8E93);
    const cardBackgroundColor = Color(0xFF1C1C1E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(arena.name, style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: textColorPrimary)),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
            const SizedBox(width: 4),
            Text("${arena.rating} (${arena.reviewCount} reviews)", style: TextStyle(color: textColorSecondary, fontSize: 14)),
            const SizedBox(width: 16),
            const Icon(Icons.people_alt_rounded, size: 18, color: Colors.blueAccent),
            const SizedBox(width: 4),
            Text("${arena.capacity} units total", style: TextStyle(color: textColorSecondary, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: arena.tags.map((tag) => _categoryBadge(tag, accentColor)).toList(),
        ),
        const SizedBox(height: 28),
        Text(arena.description, style: GoogleFonts.inter(fontSize: 15, height: 1.6, color: textColorSecondary)),
        const SizedBox(height: 32),
        _infoTitle("Overview"),
        const SizedBox(height: 16),
        _buildOverviewGrid(arena, textColorSecondary, cardBackgroundColor),
        const SizedBox(height: 32),
        _infoTitle("Specifications"),
        const SizedBox(height: 16),
        _buildSpecificationsGrid(arena, textColorSecondary, cardBackgroundColor),
        const SizedBox(height: 32),
        _infoTitle("Reserve Your Experience"),
        const SizedBox(height: 16),
        // Dynamically build the list of gaming devices from the model
        ...arena.devices.map((deviceGroup) => _unitRow(
          deviceGroup.categoryName,
          deviceGroup.units.map((unit) => _unitCard(
            unit,
            accentColor,
            cardBackgroundColor,
          )).toList(),
        )).toList(),
        const SizedBox(height: 36),
        TextButton.icon(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ArenaMapPage())),
          icon: Icon(Icons.map_rounded, color: accentColor),
          label: Text("View on Map", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: accentColor)),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildOverviewGrid(FullArenaDetails arena, Color textColorSecondary, Color cardBackgroundColor) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.8,
      children: [
        _specChip(Icons.access_time_filled_rounded, "Hours", arena.hours, textColorSecondary, cardBackgroundColor),
        _specChip(Icons.shield_rounded, "Tiermetry Score", "${arena.tiermetryScore}/10", textColorSecondary, cardBackgroundColor),
        _specChip(Icons.wifi_rounded, "Internet", arena.internetType, textColorSecondary, cardBackgroundColor),
        _specChip(Icons.chair_rounded, "Amenities", arena.mainAmenity, textColorSecondary, cardBackgroundColor),
      ],
    );
  }

  Widget _buildSpecificationsGrid(FullArenaDetails arena, Color textColorSecondary, Color cardBackgroundColor) {
    List<Widget> specs;
    switch (arena.mainActivity) {
      case MainActivity.gaming:
      case MainActivity.arcade:
        final gamingSpecs = arena.specifications as GamingSpecifications;
        specs = [
          _specChip(Icons.fullscreen_rounded, "Resolution", gamingSpecs.resolution, textColorSecondary, cardBackgroundColor),
          _specChip(Icons.refresh_rounded, "Refresh Rate", gamingSpecs.refreshRate, textColorSecondary, cardBackgroundColor),
          _specChip(Icons.memory_rounded, "Processors", gamingSpecs.processor, textColorSecondary, cardBackgroundColor),
          _specChip(Icons.gamepad_rounded, "Peripherals", gamingSpecs.peripherals, textColorSecondary, cardBackgroundColor),
        ];
        break;
      case MainActivity.recreational: // Example for another activity type
        final turfSpecs = arena.specifications as TurfSpecifications;
        specs = [
          _specChip(Icons.grass_rounded, "Surface", turfSpecs.surfaceType, textColorSecondary, cardBackgroundColor),
          _specChip(Icons.square_foot_rounded, "Field Size", turfSpecs.fieldSize, textColorSecondary, cardBackgroundColor),
          _specChip(Icons.lightbulb_rounded, "Lighting", turfSpecs.lighting, textColorSecondary, cardBackgroundColor),
          _specChip(Icons.shower_rounded, "Facilities", turfSpecs.facilities, textColorSecondary, cardBackgroundColor),
        ];
        break;
      default:
        specs = [];
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.8,
      children: specs,
    );
  }

  Widget _unitRow(String label, List<Widget> units) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: const Color(0xFF8E8E93))),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.none,
          child: Row(children: units),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _unitCard(GamingDevice unit, Color accentColor, Color cardBackgroundColor) {
    bool isSelected = selectedDevices.contains(unit.id);

    return GestureDetector(
      onTap: () {
        if (!unit.isOccupied) toggleSelection(unit.id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 170,
        height: 220,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: isSelected ? accentColor : Colors.transparent, width: 2.5),
          boxShadow: isSelected ? [BoxShadow(color: accentColor.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)] : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(unit.imagePath, fit: BoxFit.cover, color: unit.isOccupied ? Colors.black.withOpacity(0.5) : null, colorBlendMode: unit.isOccupied ? BlendMode.darken : BlendMode.dst),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.black.withOpacity(0.2)],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(unit.name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(unit.description, style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                      const SizedBox(height: 8),
                      Text("₹${unit.pricePerHour}/hr", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                    ],
                  ),
                ),
              ),
              if (unit.isOccupied)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(12)),
                    child: Text("IN USE", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.redAccent)),
                  ),
                ),
              if (isSelected)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    decoration: BoxDecoration(shape: BoxShape.circle, color: accentColor),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.check, color: Colors.white, size: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBookingBar(BuildContext context, Color accentColor) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12).copyWith(bottom: MediaQuery.of(context).padding.bottom + 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E).withOpacity(0.8),
            border: const Border(top: BorderSide(color: Color(0xFF38383A), width: 0.5)),
          ),
          child: ElevatedButton(
            onPressed: selectedDevices.isEmpty ? null : () => _showBookingSheet(context, accentColor),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              disabledBackgroundColor: const Color(0xFF555555),
              disabledForegroundColor: Colors.grey,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 5,
              shadowColor: accentColor.withOpacity(0.4),
            ),
            child: Text("Book Selected (${selectedDevices.length})", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  void _showBookingSheet(BuildContext context, Color accentColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TiermetryBookingSheet(
        selectedDevices: selectedDevices.toList(),
        accentColor: accentColor,
        onConfirm: ({required int duration, required TimeOfDay startTime, required int players, required List<String> addOns}) {
          Navigator.pop(context);
          final formattedTime = startTime.format(context);
          final endTime = TimeOfDay(hour: (startTime.hour + duration) % 24, minute: startTime.minute).format(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("✅ Booked ${selectedDevices.length} device(s) from $formattedTime to $endTime."),
              backgroundColor: accentColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        },
      ),
    );
  }

  Widget _infoTitle(String label) => Text(label, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.9)));

  Widget _categoryBadge(String label, Color accentColor) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    decoration: BoxDecoration(color: accentColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: accentColor)),
  );

  Widget _specChip(IconData icon, String label, String value, Color textColorSecondary, Color cardBackgroundColor) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: cardBackgroundColor, borderRadius: BorderRadius.circular(16)),
    child: Row(
      children: [
        Icon(icon, color: textColorSecondary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 11, color: textColorSecondary), overflow: TextOverflow.ellipsis),
              Text(value, style: GoogleFonts.inter(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
            ],
          ),
        )
      ],
    ),
  );
}

// The booking sheet remains largely the same as it's a UI component,
// but it's good practice to keep it separate.
class TiermetryBookingSheet extends StatefulWidget {
  final List<String> selectedDevices;
  final Color accentColor;
  final void Function({
  required int duration,
  required TimeOfDay startTime,
  required int players,
  required List<String> addOns,
  }) onConfirm;

  const TiermetryBookingSheet({
    super.key,
    required this.selectedDevices,
    required this.accentColor,
    required this.onConfirm,
  });

  @override
  State<TiermetryBookingSheet> createState() => _TiermetryBookingSheetState();
}

class _TiermetryBookingSheetState extends State<TiermetryBookingSheet> {
  int _duration = 1;
  TimeOfDay _startTime = TimeOfDay.now();
  int _players = 1;
  final Set<String> _addOns = {};

  double get baseRate => 120;
  double get totalCost => (baseRate * widget.selectedDevices.length * _duration) + (_addOns.length * 30 * _duration);

  void _pickStartTime() async {
    final picked = await showTimePicker(context: context, initialTime: _startTime);
    if (picked != null) setState(() => _startTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    final endTime = TimeOfDay(hour: (_startTime.hour + _duration) % 24, minute: _startTime.minute);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(color: Color(0xFF1C1C1E), borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        padding: const EdgeInsets.symmetric(horizontal: 24).copyWith(bottom: MediaQuery.of(context).padding.bottom),
        child: Column(
          children: [
            Container(width: 40, height: 5, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(20))),
            Text("Confirm Your Session", style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader("Selected Rigs"),
                    ...widget.selectedDevices.map((device) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(device, style: GoogleFonts.inter(color: Colors.white, fontSize: 16)),
                          Text("₹$baseRate/hr", style: GoogleFonts.inter(color: Colors.grey, fontSize: 15)),
                        ],
                      ),
                    )),
                    const SizedBox(height: 24),
                    _buildSectionHeader("Duration & Time Slot"),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: GestureDetector(
                            onTap: _pickStartTime,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: const Color(0xFF333336), borderRadius: BorderRadius.circular(16)),
                              child: Text("⏰ Start: ${_startTime.format(context)}", style: GoogleFonts.inter(color: Colors.white)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 4,
                          child: CupertinoSlidingSegmentedControl<int>(
                            groupValue: _duration,
                            onValueChanged: (val) => setState(() => _duration = val ?? 1),
                            thumbColor: widget.accentColor,
                            backgroundColor: const Color(0xFF333336),
                            children: { for(var i = 1; i <= 5; i++) i: Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Text("${i}h", style: GoogleFonts.inter(color: Colors.white))) },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Padding(padding: const EdgeInsets.only(left: 8.0), child: Text("Ends at: ${endTime.format(context)}", style: GoogleFonts.inter(color: Colors.grey, fontSize: 13))),
                    const SizedBox(height: 24),
                    _buildSectionHeader("Players & Add-ons"),
                    Row(
                      children: [
                        Text("👥 Players:", style: GoogleFonts.inter(color: Colors.white, fontSize: 14)),
                        const Spacer(),
                        CupertinoButton(onPressed: () => setState(() => _players = (_players - 1).clamp(1, 8)), child: const Icon(Icons.remove_circle_outline, color: Colors.white70, size: 24)),
                        Text("$_players", style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        CupertinoButton(onPressed: () => setState(() => _players = (_players + 1).clamp(1, 8)), child: Icon(Icons.add_circle_outline, color: widget.accentColor, size: 24)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(spacing: 10, runSpacing: 10, children: [_addonChip("🎧 Headset"), _addonChip("🎮 Pro Controller"), _addonChip("⚡ FPS Boost")]),
                  ],
                ),
              ),
            ),
            _buildBookingFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          Divider(color: Colors.grey.shade800, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white)),
              Text("₹${totalCost.toInt()}", style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: widget.accentColor)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              onPressed: () => widget.onConfirm(duration: _duration, startTime: _startTime, players: _players, addOns: _addOns.toList()),
              padding: const EdgeInsets.symmetric(vertical: 18),
              color: widget.accentColor,
              borderRadius: BorderRadius.circular(18),
              child: Text("Confirm Booking", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Padding(padding: const EdgeInsets.only(bottom: 12.0), child: Text(title, style: GoogleFonts.inter(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500)));

  Widget _addonChip(String label) {
    final isSelected = _addOns.contains(label);
    return ChoiceChip(
      label: Text(label),
      labelStyle: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
      selected: isSelected,
      selectedColor: widget.accentColor,
      backgroundColor: const Color(0xFF333336),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide.none,
      onSelected: (val) => setState(() => val ? _addOns.add(label) : _addOns.remove(label)),
    );
  }
}
