import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tiermetry/core/constants/feature_flags.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/mixins/refresh_rate_mixin.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_pill.dart';
import 'package:tiermetry/features/arena/domain/entities/arena_entity.dart';
import 'package:tiermetry/features/arena/presentation/screens/arena_details_screen.dart';
import 'package:tiermetry/features/event/presentation/widgets/rolling_counter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/event_entity.dart';
import 'event_registration_screen.dart';

class EventDetailsScreen extends StatefulWidget {
  final EventEntity event;

  const EventDetailsScreen({required this.event, super.key});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen>
    with RefreshRateMixin {
  static const bool _launchSupportsPaidRegistrations = false;
  final MapController _mapController = MapController();

  // App's Design System Colors (#ec441a orange, white, #151515 dark surface)
  static const Color _primaryOrange =
      TiermetryColors.primary; // #EC441A Brand Orange Accent
  static const Color _seatsGreen = Color(0xFF22C55E); // Emerald seats badge
  static const Color _priceGreen = Color(0xFF10B981); // Emerald price green
  static const Color _sheetBackground =
      TiermetryColors.surface; // #151515 App dark surface (earlier color)
  static const Color _subCardBackground =
      TiermetryColors.surfaceElement; // #212121 App surface element
  static const Color _chipBackground = Color(0xFF262626); // Clean dark chip
  static const Color _textHeading =
      TiermetryColors.white; // App White (pure white)
  static const Color _textSecondary = Color(0xFF9CA3AF); // Muted grey text
  static const Color _iconMuted = Color(0xFF6B7280); // Muted icon grey

  bool _isRegistered = false;
  bool _isLoadingStatus = true;
  bool _isRegistering = false;
  bool _isFavorite = false;
  bool isDescExpanded = false;
  int activeTab = 0;

  @override
  void initState() {
    super.initState();
    _checkRegistration();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  LatLng get _eventCoordinates {
    final lat = widget.event.venueLatitude;
    final lng = widget.event.venueLongitude;
    if (lat != null && lng != null && lat != 0 && lng != 0) {
      return LatLng(lat, lng);
    }
    // High Street, Balewadi (matching reference UI)
    return const LatLng(18.5789, 73.7707);
  }

  void _recenterMap() {
    _mapController.move(_eventCoordinates, 16.0);
  }

  Future<void> _checkRegistration() async {
    try {
      final status = await locator.eventCtrl.checkRegistrationStatus(
        widget.event.id,
      );
      if (mounted) {
        setState(() {
          _isRegistered = status;
          _isLoadingStatus = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStatus = false);
      }
    }
  }

  Future<void> _handleRegister() async {
    if (!_launchSupportsPaidRegistrations && _isPaidEvent(widget.event)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Paid event registrations will open when live payments are enabled. Only free event passes are available right now.',
          ),
        ),
      );
      return;
    }

    if (!widget.event.isRegistrationOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration is currently closed.')),
      );
      return;
    }

    if (widget.event.isFull) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This event is already full.')),
      );
      return;
    }

    setState(() => _isRegistering = true);
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => EventRegistrationScreen(event: widget.event),
      ),
    );
    if (mounted) {
      setState(() => _isRegistering = false);
      await _checkRegistration();
    }
  }

  void _shareEvent() {
    final event = widget.event;
    final when = DateFormat('EEE, MMM d • h:mm a').format(event.startTime);
    Share.share(
      'Check out ${event.title} on HOMIES.\n$when\n${event.location}',
      subject: event.title,
    );
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite ? 'Event saved.' : 'Event removed from saved.',
        ),
      ),
    );
  }

  void _reportEvent() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _sheetBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(TiermetrySpacing.screenPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Report Event',
                  style: TiermetryTypography.titleSmall(color: _textHeading),
                ),
                const SizedBox(height: TiermetrySpacing.sm),
                Text(
                  'Tell the organizer support team what looks wrong with this event.',
                  style: TiermetryTypography.bodySmall(color: _textSecondary),
                ),
                const SizedBox(height: TiermetrySpacing.lg),
                ...[
                  'Incorrect event details',
                  'Suspicious listing',
                  'Inappropriate content',
                ].map(
                  (reason) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      reason,
                      style: TiermetryTypography.bodySmall(color: _textHeading),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: _iconMuted,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Report submitted: $reason')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    return Scaffold(
      backgroundColor: _sheetBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Full-Height Live Map Background Layer
          _buildMapLayer(event),

          // 2. Map Top Gradient for Top Bar Legibility
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.65),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 3. Floating Draggable Content Sheet (App's Dark Surface, Zero Borders, Zero Glows)
          _buildDraggableSheet(context, event),

          // 4. Top Floating Navigation Header (Back, Location, Like, Flag, Share)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(context, event),
          ),

          // 5. Clean Bottom CTA
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomCTA(context, event),
          ),
        ],
      ),
    );
  }

  Widget _buildMapLayer(EventEntity event) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _eventCoordinates,
        initialZoom: 16.0,
        minZoom: 3.5,
        maxZoom: 19.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.tiermetry',
          maxZoom: 19,
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: _eventCoordinates,
              width: 180,
              height: 75,
              alignment: Alignment.center,
              child: _buildMapPinMarker(event),
            ),
          ],
        ),
        const RichAttributionWidget(
          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
        ),
      ],
    );
  }

  Widget _buildMapPinMarker(EventEntity event) {
    return GestureDetector(
      onTap: _recenterMap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Translucent pill with overlapping avatars — NO border, NO glow
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: SizedBox(
                  width: 80,
                  height: 28,
                  child: _buildAvatarStack(diameter: 28),
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          // Clean purple title underneath — NO background, NO border, NO glow
          Text(
            event.title.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.geist(
              color: _primaryOrange,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, EventEntity event) {
    final locationText =
        event.venueDisplayName.isNotEmpty
            ? event.venueDisplayName
            : (event.location.isNotEmpty
                ? event.location
                : 'High Street, Balewadi');

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TiermetrySpacing.screenPadding,
          vertical: 10,
        ),
        child: Row(
          children: [
            // Left circular avatar / back button — NO border, NO glow
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop&q=80',
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => const Center(
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.black,
                              size: 20,
                            ),
                          ),
                    ),
                    Container(color: Colors.black.withValues(alpha: 0.1)),
                    const Center(
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Center dark translucent capsule pill — NO border, NO glow
            Expanded(
              child: GestureDetector(
                onTap: _recenterMap,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Center(
                        child: Text(
                          locationText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _textHeading,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Right action 1: Like / Save button — NO border, NO glow
            _buildTopIconButton(
              icon:
                  _isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
              color: _isFavorite ? _primaryOrange : _textHeading,
              tooltip: 'Like',
              onTap: _toggleFavorite,
            ),
            const SizedBox(width: 6),

            // Right action 2: Flag / Report button — NO border, NO glow
            _buildTopIconButton(
              icon: Icons.flag_outlined,
              tooltip: 'Report',
              onTap: _reportEvent,
            ),
            const SizedBox(width: 6),

            // Right action 3: Share button — NO border, NO glow
            _buildTopIconButton(
              icon: Icons.share_rounded,
              tooltip: 'Share',
              onTap: _shareEvent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopIconButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
    Color color = _textHeading,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip ?? '',
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.45),
          ),
          child: Center(child: Icon(icon, color: color, size: 18)),
        ),
      ),
    );
  }

  Widget _buildDraggableSheet(BuildContext context, EventEntity event) {
    return DraggableScrollableSheet(
      initialChildSize: 0.54,
      minChildSize: 0.44,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [0.54, 0.95],
      builder: (context, scrollController) {
        return Container(
          // App's dark color surface — NO borders, NO glow
          decoration: const BoxDecoration(
            color: _sheetBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(
                TiermetrySpacing.screenPadding,
                12,
                TiermetrySpacing.screenPadding,
                110, // Clearance for bottom CTA
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag indicator handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // 1. Hero Event Poster with Badges (Seats & Category)
                  _buildHeroPoster(event),
                  const SizedBox(height: 18),

                  // 2. Title in Vibrant Purple — Exactly like Reference Image (Geist font)
                  Text(
                    event.title.toUpperCase(),
                    style: GoogleFonts.geist(
                      color: _primaryOrange,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // 3. Date & Time with Bullet Dot Separator
                  _buildDateTimeRow(event),
                  const SizedBox(height: 16),

                  // 4. Metadata Chips Row (Price, Duration, Language, Points)
                  _buildMetadataChipsRow(event),
                  const SizedBox(height: 18),

                  // 5. "Booked by" Social Attendee Row
                  _buildBookedByRow(event),
                  const SizedBox(height: 18),

                  // 6. Host Arena Card (if venue exists) or Location Card
                  if (event.hasVenue)
                    _buildArenaHostCard(event)
                  else
                    _buildLocationCard(context, event),
                  const SizedBox(height: 18),

                  // 7. Stats Grid (Date, Time, Joined Rolling Counter, Entry)
                  _buildStatsGrid(event),
                  const SizedBox(height: 18),

                  // 8. Description (Expandable)
                  _buildDescription(event),
                  const SizedBox(height: 18),

                  // 9. Tabbed Specifications Header
                  _buildTabsHeader(),
                  const SizedBox(height: 14),

                  // 10. Tab Content (Details, Schedule, Support)
                  _buildTabContent(context, event),

                  // 11. Perks Grid (if perks exist)
                  if (event.perks.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    _infoTitle('Perks'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children:
                          event.perks
                              .map(
                                (perk) => _featureIcon(
                                  _getFaIconData(perk.icon),
                                  perk.name,
                                ),
                              )
                              .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroPoster(EventEntity event) {
    // Dynamic seats badge text
    String seatsText = '12 SEATS AVAILABLE';
    if (_isRegistered) {
      seatsText = 'REGISTERED';
    } else if (event.isFull) {
      seatsText = 'EVENT FULL';
    } else if (event.maxParticipants != null) {
      final remaining = event.maxParticipants! - event.enrollments;
      seatsText = remaining > 0 ? '$remaining SEATS AVAILABLE' : 'EVENT FULL';
    }

    // Dynamic category badge
    String categoryLabel = '${event.kindLabel} Event';
    FaIconData categoryIcon = FontAwesomeIcons.music;

    final lowerTitle = event.title.toLowerCase();
    final lowerTags = event.tags.map((t) => t.toLowerCase()).join(' ');
    if (lowerTitle.contains('music') ||
        lowerTitle.contains('summer') ||
        lowerTitle.contains('concert') ||
        lowerTags.contains('music')) {
      categoryLabel = 'Music Event';
      categoryIcon = FontAwesomeIcons.music;
    } else if (event.game != null && event.game!.isNotEmpty) {
      categoryLabel = '${event.game} Event';
      categoryIcon = FontAwesomeIcons.gamepad;
    } else if (event.isTournament) {
      categoryLabel = 'Tournament';
      categoryIcon = FontAwesomeIcons.trophy;
    } else if (lowerTags.contains('sports') || lowerTitle.contains('clash')) {
      categoryLabel = 'Sports Event';
      categoryIcon = FontAwesomeIcons.futbol;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Poster Image
            Hero(
              tag: event.id,
              child:
                  event.image != null && !event.image!.startsWith('assets/')
                      ? Image.network(
                        event.image!,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => Container(
                              color: _subCardBackground,
                              child: const Icon(
                                Icons.broken_image_rounded,
                                color: _iconMuted,
                                size: 40,
                              ),
                            ),
                      )
                      : Image.asset(
                        event.image ?? 'assets/Hackathon.jpg',
                        fit: BoxFit.cover,
                      ),
            ),

            // Top-Left: Green "12 SEATS AVAILABLE" Pill Badge — NO border, NO glow
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _seatsGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  seatsText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),

            // Top-Right: Pure White Category Pill Badge — NO border, NO glow
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(categoryIcon, size: 11, color: _primaryOrange),
                    const SizedBox(width: 5),
                    Text(
                      categoryLabel,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom-Right: PTS Badge (if points > 0) — NO glow
            if (!FeatureFlags.disableFinancialRewards && event.points > 0)
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.solidStar,
                        size: 10,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${event.points} PTS',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
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

  Widget _buildDateTimeRow(EventEntity event) {
    final dateStr = _formatEventDate(event.startTime);
    final startTimeStr = DateFormat('hh:mm a').format(event.startTime);
    final endTimeStr = DateFormat('hh:mm a').format(event.endTime);
    final displayTime = '$dateStr • $startTimeStr to $endTimeStr';

    return Text(
      displayTime,
      style: const TextStyle(
        color: _textSecondary,
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  String _formatEventDate(DateTime dt) {
    final day = dt.day;
    String suffix = 'th';
    if (day >= 11 && day <= 13) {
      suffix = 'th';
    } else {
      switch (day % 10) {
        case 1:
          suffix = 'st';
          break;
        case 2:
          suffix = 'nd';
          break;
        case 3:
          suffix = 'rd';
          break;
        default:
          suffix = 'th';
          break;
      }
    }
    return '$day$suffix ${DateFormat('MMM yyyy').format(dt)}';
  }

  Widget _buildMetadataChipsRow(EventEntity event) {
    // 1. Price
    final isFree = event.cost.trim().toLowerCase() == 'free';
    final rawCost = event.cost.replaceAll('₹', '').trim();
    final priceDisplay = isFree ? 'Free onwards' : '₹$rawCost onwards';

    // 2. Duration
    final diff = event.endTime.difference(event.startTime);
    final durationDisplay =
        diff.inHours > 0
            ? '${diff.inHours} Hrs'
            : '${diff.inMinutes > 0 ? diff.inMinutes : 120} Mins';

    // 3. Format / Language
    final languageDisplay = event.format ?? event.platform ?? 'Hindi & English';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          // Price Chip — Green Rupee Circle + Green Text (NO border, NO glow)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _chipBackground,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 15,
                  height: 15,
                  decoration: const BoxDecoration(
                    color: _priceGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '₹',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  priceDisplay,
                  style: const TextStyle(
                    color: _priceGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Duration Chip — Hourglass Icon + Light Grey Text (NO border, NO glow)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _chipBackground,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.hourglass_top_rounded,
                  size: 14,
                  color: _textSecondary,
                ),
                const SizedBox(width: 5),
                Text(
                  durationDisplay,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Language / Format Chip — Letter A in circle + Light Grey Text (NO border, NO glow)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _chipBackground,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 15,
                  height: 15,
                  decoration: const BoxDecoration(
                    color: _iconMuted,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'A',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  languageDisplay,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Points Chip (if applicable)
          if (!FeatureFlags.disableFinancialRewards && event.points > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _chipBackground,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    size: 14,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${event.points} PTS',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBookedByRow(EventEntity event) {
    // Dynamic attendee summary text
    String attendeeSummary = 'Reshma, Chaitali & 3 others';
    if (event.userParticipants.isNotEmpty) {
      final firstTwo = event.userParticipants.take(2).join(', ');
      final remaining = event.userParticipants.length - 2;
      attendeeSummary =
          remaining > 0 ? '$firstTwo & $remaining others' : firstTwo;
    } else if (event.enrollments > 0) {
      if (event.enrollments >= 3) {
        attendeeSummary = 'Reshma, Chaitali & ${event.enrollments - 2} others';
      } else {
        attendeeSummary =
            '${event.enrollments} participant${event.enrollments == 1 ? '' : 's'} registered';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _subCardBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Overlapping Avatar Stack
          SizedBox(
            width: 74,
            height: 36,
            child: _buildAvatarStack(diameter: 36),
          ),
          const SizedBox(width: 12),

          // Titles Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Booked by',
                  style: GoogleFonts.geist(
                    color: _textHeading,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  attendeeSummary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _textSecondary, fontSize: 12.5),
                ),
              ],
            ),
          ),

          // Trailing Chevron
          const Icon(Icons.chevron_right_rounded, color: _iconMuted, size: 22),
        ],
      ),
    );
  }

  Widget _buildAvatarStack({double diameter = 32}) {
    final avatarUrls = [
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&auto=format&fit=crop&q=80',
    ];
    final fallbackColors = [
      const Color(0xFF6366F1),
      const Color(0xFFEC4899),
      const Color(0xFF10B981),
    ];
    final fallbackInitials = ['R', 'C', 'A'];

    return Stack(
      children: [
        for (int i = 0; i < avatarUrls.length; i++)
          Positioned(
            left: i * (diameter * 0.55),
            child: Container(
              width: diameter,
              height: diameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fallbackColors[i % fallbackColors.length],
                border: Border.all(color: _subCardBackground, width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                avatarUrls[i],
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) => Center(
                      child: Text(
                        fallbackInitials[i % fallbackInitials.length],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: diameter * 0.38,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildArenaHostCard(EventEntity event) {
    return GestureDetector(
      onTap: () => _openArenaDetails(event),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TiermetrySpacing.md,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: _subCardBackground,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _primaryOrange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.stadium_rounded,
                color: _primaryOrange,
                size: 22,
              ),
            ),
            const SizedBox(width: TiermetrySpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'HOST ARENA',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _primaryOrange,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.venueDisplayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _textHeading,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.venueDisplayAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: TiermetrySpacing.sm),
            const Icon(
              Icons.chevron_right_rounded,
              color: _iconMuted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context, EventEntity event) {
    return GestureDetector(
      onTap: () async {
        final query = Uri.encodeComponent(event.location);
        final url = Uri.parse('https://maps.google.com/?q=$query');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open map.')),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(TiermetrySpacing.md),
        decoration: BoxDecoration(
          color: _subCardBackground,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _primaryOrange.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on_rounded,
                size: 20,
                color: _primaryOrange,
              ),
            ),
            const SizedBox(width: TiermetrySpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Location',
                    style: TextStyle(color: _textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.location,
                    style: const TextStyle(
                      color: _textHeading,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: _iconMuted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  void _openArenaDetails(EventEntity event) {
    if (!event.hasVenue) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ArenaDetailsScreen(arena: _arenaFromEvent(event)),
      ),
    );
  }

  ArenaEntity _arenaFromEvent(EventEntity event) {
    return ArenaEntity(
      id: event.venueId!,
      name: event.venueDisplayName,
      image: event.venueImage ?? '',
      rating: event.venueRating ?? 0,
      reviewCount: 0,
      capacity: event.venueCapacity ?? 0,
      location: event.venueDisplayAddress,
      screenCount: 0,
      activity: _arenaActivityFromEvent(event.venueActivity),
      shortAddress: event.location,
      hours: event.venueHours ?? '',
      isOpen: event.venueIsOpen ?? true,
      images: event.venueImage != null ? [event.venueImage!] : [],
      distance: 0,
      priceTier: event.venuePriceTier ?? 0,
      isVerified: event.venueIsVerified ?? false,
      latitude: event.venueLatitude ?? 0,
      longitude: event.venueLongitude ?? 0,
      tags: const [],
    );
  }

  ArenaActivity _arenaActivityFromEvent(String? activity) {
    return ArenaActivity.values.firstWhere(
      (item) => item.name == activity,
      orElse: () => ArenaActivity.gaming,
    );
  }

  Widget _buildStatsGrid(EventEntity event) {
    final stats = [
      _statChip(
        FontAwesomeIcons.calendarDay,
        'Date',
        DateFormat('MMM d, y').format(event.startTime),
      ),
      _statChip(
        FontAwesomeIcons.clock,
        'Time',
        DateFormat('h:mm a').format(event.startTime),
      ),
      _joinedStatChip(),
      _statChip(
        FontAwesomeIcons.ticket,
        'Entry',
        event.cost,
        valueColor: _priceGreen,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 380 ? 1 : 2;
        return GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 68,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) => stats[index],
        );
      },
    );
  }

  Widget _joinedStatChip() {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(
        horizontal: TiermetrySpacing.md,
        vertical: TiermetrySpacing.sm,
      ),
      decoration: BoxDecoration(
        color: _subCardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const FaIcon(FontAwesomeIcons.users, color: _iconMuted, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Joined',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _textSecondary, fontSize: 11),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      RollingCounter(
                        number: widget.event.enrollments,
                        digitHeight: 22,
                        digitWidth: 12,
                        textStyle: const TextStyle(
                          color: _textHeading,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '/ ${widget.event.maxParticipants ?? "∞"}',
                        style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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
    );
  }

  Widget _statChip(
    FaIconData icon,
    String label,
    String value, {
    Color valueColor = _textHeading,
  }) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(
        horizontal: TiermetrySpacing.md,
        vertical: TiermetrySpacing.sm,
      ),
      decoration: BoxDecoration(
        color: _subCardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          FaIcon(icon, color: _iconMuted, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _textSecondary, fontSize: 11),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(EventEntity event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          event.description ?? 'No description available.',
          maxLines: isDescExpanded ? null : 3,
          overflow:
              isDescExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: const TextStyle(
            height: 1.5,
            fontSize: 13.5,
            color: Color(0xFFD1D5DB),
          ),
        ),
        GestureDetector(
          onTap: () => setState(() => isDescExpanded = !isDescExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              isDescExpanded ? 'Read Less' : 'Read More',
              style: const TextStyle(
                color: _primaryOrange,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabsHeader() {
    return Wrap(
      spacing: 20,
      runSpacing: 10,
      children: [
        _tabItem(0, 'Details'),
        _tabItem(1, 'Schedule'),
        _tabItem(2, 'Support'),
      ],
    );
  }

  Widget _tabItem(int index, String label) {
    final isSelected = activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => activeTab = index),
      behavior: HitTestBehavior.opaque,
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? _textHeading : _textSecondary,
          fontSize: 17,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, EventEntity event) {
    switch (activeTab) {
      case 1:
        return _buildScheduleTab(context, event);
      case 2:
        return _buildSupportTab(context, event);
      default:
        return _buildDetailsTab(event);
    }
  }

  Widget _buildDetailsTab(EventEntity event) {
    final rows = <Widget>[
      _detailCard(FontAwesomeIcons.user, 'Organizer', event.organizer),
      if (!event.hasVenue)
        _detailCard(FontAwesomeIcons.locationDot, 'Venue', event.location),
      if (event.game != null && event.game!.isNotEmpty)
        _detailCard(FontAwesomeIcons.gamepad, 'Game', event.game!),
      if (event.platform != null && event.platform!.isNotEmpty)
        _detailCard(FontAwesomeIcons.display, 'Platform', event.platform!),
      if (event.format != null && event.format!.isNotEmpty)
        _detailCard(FontAwesomeIcons.barsStaggered, 'Format', event.format!),
      if (event.rules != null && event.rules!.isNotEmpty)
        _detailCard(FontAwesomeIcons.scroll, 'Rules', event.rules!),
      if (!FeatureFlags.disableFinancialRewards && event.points > 0)
        _detailCard(
          FontAwesomeIcons.trophy,
          'Prize pool',
          '${event.points} PTS',
        ),
      _detailCard(
        FontAwesomeIcons.hourglassHalf,
        'Registration closes',
        DateFormat('MMM d, y • h:mm a').format(event.registrationEnd),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _responsiveDetailGrid(rows),
        if (event.tags.isNotEmpty) ...[
          const SizedBox(height: 16),
          _infoTitle('Tags'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                event.tags
                    .map(
                      (tag) => AppPill(
                        text: tag,
                        color: _chipBackground,
                        textColor: _textHeading,
                      ),
                    )
                    .toList(),
          ),
        ],
      ],
    );
  }

  bool _isPaidEvent(EventEntity event) =>
      event.cost.trim().toLowerCase() != 'free';

  Widget _buildScheduleTab(BuildContext context, EventEntity event) {
    final hasSchedule = event.schedule.isNotEmpty;
    final rows =
        hasSchedule
            ? event.schedule.map((entry) {
              final date = entry['date'] ?? '';
              final time = entry['time'] ?? '';
              final title = entry['title'] ?? entry['label'] ?? 'Event item';
              final subtitle = [
                date,
                time,
              ].where((part) => part.isNotEmpty).join(' • ');
              return _detailCard(
                FontAwesomeIcons.calendarCheck,
                title,
                subtitle.isEmpty ? 'Schedule details pending' : subtitle,
              );
            }).toList()
            : [
              _detailCard(
                FontAwesomeIcons.calendarCheck,
                'Event window',
                '${DateFormat('MMM d, h:mm a').format(event.startTime)} - ${DateFormat('h:mm a').format(event.endTime)}',
              ),
            ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _responsiveDetailGrid(rows),
        if (event.bracketUrl != null && event.bracketUrl!.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final url = Uri.parse(event.bracketUrl!);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.inAppWebView);
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not open bracket link.'),
                    ),
                  );
                }
              },
              icon: const FaIcon(FontAwesomeIcons.diagramProject, size: 14),
              label: const Text('View bracket'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSupportTab(BuildContext context, EventEntity event) {
    final rows = <Widget>[
      if (event.contactEmail != null && event.contactEmail!.isNotEmpty)
        _detailCard(
          FontAwesomeIcons.envelope,
          'Contact organizer',
          event.contactEmail!,
        ),
      if (!FeatureFlags.disableFinancialRewards && event.rewards.isNotEmpty)
        _detailCard(FontAwesomeIcons.gift, 'Rewards', event.rewards.join('\n')),
      if (event.faqs.isNotEmpty)
        ...event.faqs.map((faq) {
          final question = faq['question'] ?? faq['q'] ?? 'Question';
          final answer = faq['answer'] ?? faq['a'] ?? 'Answer pending';
          return _detailCard(FontAwesomeIcons.circleQuestion, question, answer);
        }),
    ];

    if (rows.isEmpty) {
      rows.add(
        _detailCard(
          FontAwesomeIcons.circleInfo,
          'Support',
          'Organizer support details will appear here when available.',
        ),
      );
    }

    return Column(
      children: [
        _responsiveDetailGrid(rows),
        if (event.contactEmail != null && event.contactEmail!.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final uri = Uri(scheme: 'mailto', path: event.contactEmail);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not launch email client.'),
                    ),
                  );
                }
              },
              icon: const FaIcon(FontAwesomeIcons.envelope, size: 14),
              label: const Text('Email organizer'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _responsiveDetailGrid(List<Widget> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 640 ? 1 : 2;
        return GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 72,
          ),
          itemBuilder: (context, index) => items[index],
        );
      },
    );
  }

  Widget _detailCard(FaIconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _subCardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaIcon(icon, color: _primaryOrange, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textHeading,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _textSecondary, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureIcon(FaIconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _chipBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: FaIcon(icon, color: Colors.white, size: 18)),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: _textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _infoTitle(String label) => Text(
    label.toUpperCase(),
    style: GoogleFonts.geist(
      color: _textHeading,
      fontSize: 13,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.5,
    ),
  );

  Widget _buildBottomCTA(BuildContext context, EventEntity event) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.only(
            left: TiermetrySpacing.screenPadding,
            right: TiermetrySpacing.screenPadding,
            top: 10,
            bottom: 28,
          ),
          decoration: BoxDecoration(
            color: _sheetBackground.withValues(alpha: 0.94),
          ),
          child: _buildCTAButton(event),
        ),
      ),
    );
  }

  Widget _buildCTAButton(EventEntity event) {
    if (_isLoadingStatus) {
      return const SizedBox(
        height: 52,
        child: Center(child: CircularProgressIndicator(color: _primaryOrange)),
      );
    }

    if (_isRegistered) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _subCardBackground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          minimumSize: const Size.fromHeight(52),
        ),
        child: const Text(
          'Already Registered',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _iconMuted,
          ),
        ),
      );
    }

    final bool isOpen = event.isRegistrationOpen;
    final bool isFull = event.isFull;
    final bool paidBlocked =
        !_launchSupportsPaidRegistrations && _isPaidEvent(event);

    String label = 'Join This Event';
    if (paidBlocked) {
      label = 'Free Launch Only';
    } else if (!isOpen) {
      final now = DateTime.now();
      if (now.isBefore(event.registrationStart)) {
        label = 'Opens ${DateFormat('MMM d').format(event.registrationStart)}';
      } else {
        label = 'Registration Closed';
      }
    } else if (isFull) {
      label = 'Event Full';
    }

    return ElevatedButton(
      onPressed:
          (isOpen && !isFull && !_isRegistering && !paidBlocked)
              ? _handleRegister
              : null,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isOpen && !isFull && !paidBlocked
                ? _primaryOrange
                : _subCardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        minimumSize: const Size.fromHeight(52),
      ),
      child:
          _isRegistering
              ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
              : Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color:
                      isOpen && !isFull && !paidBlocked
                          ? Colors.white
                          : _iconMuted,
                ),
              ),
    );
  }

  FaIconData _getFaIconData(String iconName) {
    switch (iconName) {
      case 'fastfood':
        return FontAwesomeIcons.burger;
      case 'stars':
        return FontAwesomeIcons.solidStar;
      case 'emoji_events':
        return FontAwesomeIcons.trophy;
      case 'verified_user':
        return FontAwesomeIcons.shieldHalved;
      case 'chair':
        return FontAwesomeIcons.chair;
      case 'people':
        return FontAwesomeIcons.users;
      case 'wifi':
        return FontAwesomeIcons.wifi;
      case 'notifications':
        return FontAwesomeIcons.bell;
      default:
        return FontAwesomeIcons.circleCheck;
    }
  }
}

class CountdownTimerCompact extends StatefulWidget {
  final DateTime eventDate;

  const CountdownTimerCompact({required this.eventDate, super.key});

  @override
  State<CountdownTimerCompact> createState() => _CountdownTimerCompactState();
}

class _CountdownTimerCompactState extends State<CountdownTimerCompact> {
  late Duration _timeLeft;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _timeLeft = widget.eventDate.difference(now);
      if (_timeLeft.isNegative) {
        _timeLeft = Duration.zero;
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours % 24;
    final minutes = _timeLeft.inMinutes % 60;

    if (days == 0 && hours == 0 && minutes == 0) {
      return const Text(
        'STARTED',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: TiermetryColors.primary,
        ),
      );
    }

    return Text(
      '${days}D : ${hours}H : ${minutes}M',
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    );
  }
}
