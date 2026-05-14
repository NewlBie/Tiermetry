import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

// Entities
import '../../domain/entities/arena_entity.dart';
import '../../domain/entities/arena_details_entity.dart';
import 'package:tiermetry/core/locator.dart';

// Screens
import 'arena_map_screen.dart';

// Widgets
import '../widgets/booking_sheet.dart';
import '../widgets/booking_status_overlay.dart';
import 'package:tiermetry/core/theme/colors.dart';

class ArenaDetailsScreen extends StatefulWidget {
  final ArenaEntity arena;

  const ArenaDetailsScreen({
    super.key,
    required this.arena,
  });

  @override
  State<ArenaDetailsScreen> createState() => _ArenaDetailsScreenState();
}

class _ArenaDetailsScreenState extends State<ArenaDetailsScreen> {
  late Future<ArenaDetailsEntity?> _detailsFuture;
  final Set<String> _selectedDevices = {}; // Renamed from selectedDevices to match common patterns if needed, but keeping existing for now
  bool isDescExpanded = false;
  int activeTab = 0; // 0: Overview, 1: Specs & Games, 2: Rules
  bool _showSuccessOverlay = false;


  @override
  void initState() {
    super.initState();
    _detailsFuture = locator.arenaCtrl.loadArenaDetails(widget.arena.id);
  }

  void toggleSelection(String deviceId) {
    setState(() {
      if (_selectedDevices.contains(deviceId)) {
        _selectedDevices.remove(deviceId);
      } else {
        _selectedDevices.add(deviceId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const scaffoldColor = TiermetryColors.background;
    const accentColor = TiermetryColors.accentAppleBlue;

    return Scaffold(
      backgroundColor: scaffoldColor,
      body: FutureBuilder<ArenaDetailsEntity?>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CupertinoActivityIndicator(radius: 15, color: Colors.white));
          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Failed to load arena details.", style: TextStyle(color: Colors.white)));
          }

          final arenaDetails = snapshot.data!;

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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _showSuccessOverlay 
        ? BookingStatusOverlay(
            isSuccess: true,
            title: "Booking Confirmed!",
            message: "Your rig is ready at ${widget.arena.name}. We've sent the details to your email.",
            onAction: () => setState(() => _showSuccessOverlay = false),
          )
        : null,
    );
  }

  Widget _buildSliverAppBar(BuildContext context, ArenaDetailsEntity arena) {
    return SliverAppBar(
      expandedHeight: 320.0,
      backgroundColor: TiermetryColors.background,
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
              tag: arena.image,
              child: Image.asset(arena.image, fit: BoxFit.cover),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                    TiermetryColors.background,
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
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsContent(BuildContext context, ArenaDetailsEntity arena, Color accentColor) {
    const textColorPrimary = Colors.white;
    const textColorSecondary = TiermetryColors.textMuted;
    const cardBackgroundColor = TiermetryColors.surfaceUnderlay;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and Rating Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(arena.name, style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.bold, color: textColorPrimary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: Colors.greenAccent),
                      const SizedBox(width: 4),
                      Text(arena.shortAddress, style: TextStyle(color: textColorSecondary, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(arena.rating.toString(), style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Features Quick Grid (Compact)
        _buildFeaturesQuickRow(arena, textColorSecondary),
        const SizedBox(height: 24),

        // Description with Read More
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              arena.desc,
              maxLines: isDescExpanded ? null : 3,
              overflow: isDescExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: textColorSecondary),
            ),
            GestureDetector(
              onTap: () => setState(() => isDescExpanded = !isDescExpanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  isDescExpanded ? "Read Less" : "Read More",
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: accentColor),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Segmented Control Tabs
        _buildTabsHeader(accentColor),
        const SizedBox(height: 24),

        // Tab Content
        _buildTabContent(arena, textColorSecondary, cardBackgroundColor, accentColor),
        const SizedBox(height: 32),

        _infoTitle("Reserve Your Experience"),
        const SizedBox(height: 16),
        ...arena.devices.map((deviceGroup) => _unitRow(
          deviceGroup.name,
          deviceGroup.units.map((unit) => _unitCard(
            unit,
            accentColor,
            cardBackgroundColor,
          )).toList(),
        )),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildFeaturesQuickRow(ArenaDetailsEntity arena, Color textColorSecondary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _featureIcon(Icons.ac_unit_rounded, "AC", arena.hasAC),
        _featureIcon(Icons.bolt_rounded, "UPS", arena.hasPowerBackup),
        _featureIcon(Icons.wifi_rounded, "Fiber", true),
        _featureIcon(Icons.restaurant_rounded, "Food", arena.amenity.toLowerCase().contains('cafe')),
        _featureIcon(Icons.verified_user_rounded, "Safety", true),
      ],
    );
  }

  Widget _featureIcon(IconData icon, String label, bool active) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: active ? TiermetryColors.accentAppleBlue.withValues(alpha: 0.1) : TiermetryColors.surfaceUnderlay,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: active ? TiermetryColors.accentAppleBlue : Colors.grey),
        ),
        const SizedBox(height: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: active ? Colors.white70 : Colors.grey)),
      ],
    );
  }

  Widget _buildTabsHeader(Color accentColor) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: TiermetryColors.surfaceUnderlay, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          _tabItem(0, "Overview", accentColor),
          _tabItem(1, "Hardware", accentColor),
          _tabItem(2, "Policies", accentColor),
        ],
      ),
    );
  }

  Widget _tabItem(int index, String label, Color accentColor) {
    bool isSelected = activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => activeTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? TiermetryColors.surfaceElement : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : TiermetryColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(ArenaDetailsEntity arena, Color textColorSecondary, Color cardBackgroundColor, Color accentColor) {
    switch (activeTab) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewGrid(arena, textColorSecondary, cardBackgroundColor),
            const SizedBox(height: 24),
            _buildLocationCard(context, arena, textColorSecondary, cardBackgroundColor, accentColor),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSpecificationsGrid(arena, textColorSecondary, cardBackgroundColor),
            const SizedBox(height: 24),
            _infoTitle("Pre-installed Games"),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: arena.gameLibrary.map((game) => _gameBadge(game)).toList(),
            ),
          ],
        );
      case 2:
        return _buildPoliciesSection(arena, textColorSecondary, cardBackgroundColor);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _gameBadge(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: TiermetryColors.surfaceUnderlay, borderRadius: BorderRadius.circular(8), border: Border.all(color: TiermetryColors.borderSubtle, width: 0.5)),
    child: Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
  );

  Widget _buildOverviewGrid(ArenaDetailsEntity arena, Color textColorSecondary, Color cardBackgroundColor) {
    return GridView.count(
      padding: EdgeInsets.zero,
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.8,
      children: [
        _specChip(Icons.access_time_filled_rounded, "Hours", arena.hours, textColorSecondary, cardBackgroundColor),
        _specChip(Icons.speed_rounded, "Internet", arena.internet, textColorSecondary, cardBackgroundColor),
        _specChip(Icons.people_rounded, "Vibe", "Professional", textColorSecondary, cardBackgroundColor),
        _specChip(Icons.chair_rounded, "Amenities", arena.amenity, textColorSecondary, cardBackgroundColor),
      ],
    );
  }

  Widget _buildSpecificationsGrid(ArenaDetailsEntity arena, Color textColorSecondary, Color cardBackgroundColor) {
    List<Widget> specs;
    if (arena.specs is GamingSpecs) {
      final gs = arena.specs as GamingSpecs;
      specs = [
        _specChip(Icons.monitor_rounded, "Monitor", gs.refreshRate, textColorSecondary, cardBackgroundColor),
        _specChip(Icons.videogame_asset_rounded, "GPU", gs.graphicsCard, textColorSecondary, cardBackgroundColor),
        _specChip(Icons.memory_rounded, "Processor", gs.processor, textColorSecondary, cardBackgroundColor),
        _specChip(Icons.keyboard_rounded, "Peripherals", "Pro-grade", textColorSecondary, cardBackgroundColor),
      ];
    } else {
      final ts = arena.specs as TurfSpecs;
      specs = [
        _specChip(Icons.grass_rounded, "Surface", ts.surface, textColorSecondary, cardBackgroundColor),
        _specChip(Icons.lightbulb_rounded, "Lighting", ts.lighting, textColorSecondary, cardBackgroundColor),
      ];
    }

    return GridView.count(
      padding: EdgeInsets.zero,
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.8,
      children: specs,
    );
  }

  Widget _buildPoliciesSection(ArenaDetailsEntity arena, Color textColorSecondary, Color cardBackgroundColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _policyItem(Icons.cancel_rounded, "Cancellation", arena.cancellationPolicy, textColorSecondary),
        const SizedBox(height: 16),
        _policyItem(Icons.phone_rounded, "Contact", arena.contactPhone, textColorSecondary),
        const SizedBox(height: 16),
        ...arena.rules.map((rule) => _policyItem(Icons.gavel_rounded, "Rule", rule, textColorSecondary)),
      ],
    );
  }

  Widget _policyItem(IconData icon, String title, String value, Color textColorSecondary) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: TiermetryColors.accentAppleBlue, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 2),
              Text(value, style: GoogleFonts.inter(fontSize: 13, color: textColorSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard(BuildContext context, ArenaDetailsEntity arena, Color textColorSecondary, Color cardBackgroundColor, Color accentColor) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ArenaMapScreen(arena: arena))),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentColor.withValues(alpha: 0.2), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.map_rounded, color: accentColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Location", style: GoogleFonts.inter(fontSize: 12, color: textColorSecondary)),
                  Text(arena.shortAddress, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: textColorSecondary, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _unitRow(String label, List<Widget> units) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: TiermetryColors.textMuted)),
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

  Widget _unitCard(Device unit, Color accentColor, Color cardBackgroundColor) {
    bool isSelected = _selectedDevices.contains(unit.id);

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
          boxShadow: isSelected ? [BoxShadow(color: accentColor.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 2)] : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(unit.image, fit: BoxFit.cover, color: unit.isOccupied ? Colors.black.withValues(alpha: 0.5) : null, colorBlendMode: unit.isOccupied ? BlendMode.darken : BlendMode.dst),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withValues(alpha: 0.8), Colors.black.withValues(alpha: 0.2)],
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
                      Text(unit.desc, style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                      const SizedBox(height: 8),
                      Text("₹${unit.price}/hr", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                    ],
                  ),
                ),
              ),
              if (unit.isOccupied)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(12)),
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
            color: TiermetryColors.surfaceUnderlay.withValues(alpha: 0.8),
            border: const Border(top: BorderSide(color: TiermetryColors.borderSubtle, width: 0.5)),
          ),
          child: ElevatedButton(
            onPressed: _selectedDevices.isEmpty ? null : () => _showBookingSheet(context, accentColor),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              disabledBackgroundColor: TiermetryColors.surfaceElement,
              disabledForegroundColor: Colors.grey,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 5,
              shadowColor: accentColor.withValues(alpha: 0.4),
            ),
            child: Text("Book Selected (${_selectedDevices.length})", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
      builder: (context) => BookingSheet(
        selectedDevices: _selectedDevices.toList(),
        accentColor: accentColor,
        onConfirm: ({required int duration, required TimeOfDay startTime, required int players, required List<String> addOns}) {
          Navigator.pop(context);
          setState(() {
            _showSuccessOverlay = true;
            _selectedDevices.clear();
          });
        },
      ),
    );
  }

  Widget _infoTitle(String label) => Text(label, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.9), height: 1.2));


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
