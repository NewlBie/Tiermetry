import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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
import 'package:tiermetry/features/arena/domain/entities/arena_entity.dart';
import 'package:tiermetry/features/arena/presentation/screens/arena_details_screen.dart';
import 'package:tiermetry/features/event/presentation/widgets/rolling_counter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/event_entity.dart';
import 'event_registration_screen.dart';

/// Showdown & Competition Details Screen — High-Energy Tournament Battlefield UI
///
/// Styled in the app's official dark surface (#151515), brand orange (#EC441A),
/// and pure white (#FFFFFF), with zero borders, zero glows, and zero harsh shadows.
class ShowdownDetailsScreen extends StatefulWidget {
  final EventEntity event;

  const ShowdownDetailsScreen({required this.event, super.key});

  @override
  State<ShowdownDetailsScreen> createState() => _ShowdownDetailsScreenState();
}

class _ShowdownDetailsScreenState extends State<ShowdownDetailsScreen>
    with RefreshRateMixin {
  static const bool _launchSupportsPaidRegistrations = false;
  final MapController _mapController = MapController();

  // Official Design System Colors — ZERO borders, ZERO glows
  static const Color _primaryOrange =
      TiermetryColors.primary; // #EC441A Brand Orange Accent
  static const Color _slotsGreen = Color(0xFF22C55E); // Emerald slots badge
  static const Color _prizeGold = Color(0xFFF59E0B); // Trophy amber gold
  static const Color _sheetBackground =
      TiermetryColors.surface; // #151515 App dark surface
  static const Color _subCardBackground =
      TiermetryColors.surfaceElement; // #212121 Elevated surface
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
  int activeTab =
      0; // 0: Rules & Overview, 1: Schedule & Brackets, 2: Prize Pool

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

  LatLng get _battlegroundCoordinates {
    final lat = widget.event.venueLatitude;
    final lng = widget.event.venueLongitude;
    if (lat != null && lng != null && lat != 0 && lng != 0) {
      return LatLng(lat, lng);
    }
    // Balewadi High Street / Arena fallback
    return const LatLng(18.5789, 73.7707);
  }

  void _recenterMap() {
    _mapController.move(_battlegroundCoordinates, 16.0);
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
            'Paid competition entries will open when live payments are enabled. Only free entries are available right now.',
          ),
        ),
      );
      return;
    }

    if (!widget.event.isRegistrationOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tournament registration is currently closed.'),
        ),
      );
      return;
    }

    if (widget.event.isFull) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This tournament is already full.')),
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
      'Compete in ${event.title} on HOMIES!\n$when\nBattleground: ${event.location}',
      subject: event.title,
    );
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite ? 'Tournament saved.' : 'Tournament removed from saved.',
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
                  'Report Competition',
                  style: TiermetryTypography.titleSmall(color: _textHeading),
                ),
                const SizedBox(height: TiermetrySpacing.sm),
                Text(
                  'Let the tournament administration team know if something violates guidelines.',
                  style: TiermetryTypography.bodySmall(color: _textSecondary),
                ),
                const SizedBox(height: TiermetrySpacing.lg),
                ...[
                  'Incorrect tournament rules',
                  'Suspicious or fraudulent entry',
                  'Inappropriate match content',
                  'Bracket or schedule dispute',
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

  bool _isPaidEvent(EventEntity event) =>
      event.cost.trim().toLowerCase() != 'free';

  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    return Scaffold(
      backgroundColor: _sheetBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Live Interactive Battleground Map Layer
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

          // 3. Floating Draggable Content Sheet (App Dark Surface, Zero Borders, Zero Glows)
          _buildDraggableSheet(context, event),

          // 4. Top Floating Navigation Header (Back, Battleground Location, Like, Flag, Share)
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
        initialCenter: _battlegroundCoordinates,
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
              point: _battlegroundCoordinates,
              width: 190,
              height: 75,
              alignment: Alignment.center,
              child: _buildBattlegroundMarker(event),
            ),
          ],
        ),
        const RichAttributionWidget(
          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
        ),
      ],
    );
  }

  Widget _buildBattlegroundMarker(EventEntity event) {
    return GestureDetector(
      onTap: _recenterMap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Translucent pill with trophy + contender avatars — NO border, NO glow
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: _primaryOrange,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 58,
                      height: 24,
                      child: _buildContenderAvatarStack(diameter: 24),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          // Clean orange title underneath — NO background, NO border, NO glow
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
            ? 'BATTLEGROUND: ${event.venueDisplayName.toUpperCase()}'
            : (event.location.isNotEmpty
                ? 'BATTLEGROUND: ${event.location.toUpperCase()}'
                : 'BATTLEGROUND: HIGH STREET ARENA');

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
                      'https://images.unsplash.com/photo-1566492031773-4f4e44671857?w=100&auto=format&fit=crop&q=80',
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
                        color: _textHeading,
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
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
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
              tooltip: 'Save',
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
          // App's dark color surface (#151515) — NO borders, NO glow
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
                110, // Clearance for sticky bottom CTA
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

                  // 1. Hero Tournament Poster with Badges
                  _buildHeroTournamentPoster(event),
                  const SizedBox(height: 18),

                  // 2. Title in Vibrant Orange — Bold Competitive Geist
                  Text(
                    event.title.toUpperCase(),
                    style: GoogleFonts.geist(
                      color: _primaryOrange,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // 3. Tournament Type, Date & Time with Bullet Separator
                  _buildTournamentDateRow(event),
                  const SizedBox(height: 16),

                  // 4. Tournament Metric Chips Row (Prize Pool, Format, Entry, Check-in)
                  _buildTournamentChipsRow(event),
                  const SizedBox(height: 18),

                  // 5. "Registered Contenders" Roster Row
                  _buildContendersRow(event),
                  const SizedBox(height: 18),

                  // 6. Host Battleground Arena Card
                  if (event.hasVenue)
                    _buildHostArenaCard(event)
                  else
                    _buildLocationCard(context, event),
                  const SizedBox(height: 18),

                  // 7. Tournament Countdown & Quick Stats
                  _buildTournamentStatsGrid(event),
                  const SizedBox(height: 18),

                  // 8. Tabbed Tournament Specifications (Overview/Rules, Schedule/Brackets, Prize Distribution)
                  _buildTournamentTabsHeader(),
                  const SizedBox(height: 14),

                  // 9. Tab Content
                  _buildTournamentTabContent(context, event),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroTournamentPoster(EventEntity event) {
    // Dynamic slots remaining badge text
    String slotsText = '16 SQUADS REMAINING';
    if (_isRegistered) {
      slotsText = 'REGISTERED & READY';
    } else if (event.isFull) {
      slotsText = 'SHOWDOWN FULL';
    } else if (event.maxParticipants != null) {
      final remaining = event.maxParticipants! - event.enrollments;
      slotsText =
          remaining > 0 ? '$remaining SLOTS AVAILABLE' : 'SHOWDOWN FULL';
    }

    // Dynamic tournament category badge
    String categoryLabel = 'TOURNAMENT';
    if (event.game != null && event.game!.isNotEmpty) {
      categoryLabel = '${event.game!.toUpperCase()} SHOWDOWN';
    } else if (event.format != null && event.format!.isNotEmpty) {
      categoryLabel = event.format!.toUpperCase();
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
              tag: 'showdown-${event.id}',
              child:
                  event.image != null && !event.image!.startsWith('assets/')
                      ? Image.network(
                        event.image!,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => Container(
                              color: _subCardBackground,
                              child: const Icon(
                                Icons.sports_esports_rounded,
                                color: _iconMuted,
                                size: 44,
                              ),
                            ),
                      )
                      : Image.asset(
                        event.image ?? 'assets/Hackathon.jpg',
                        fit: BoxFit.cover,
                      ),
            ),

            // Top-Left: Green Emerald Slots Badge — NO border, NO glow
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _slotsGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      slotsText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Top-Right: Cream White Tournament Badge — NO border, NO glow
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _textHeading,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      size: 13,
                      color: _primaryOrange,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      categoryLabel,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
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

  Widget _buildTournamentDateRow(EventEntity event) {
    final dateStr =
        DateFormat('d MMM yyyy').format(event.startTime).toUpperCase();
    final timeStr =
        '${DateFormat('hh:mm a').format(event.startTime)} TO ${DateFormat('hh:mm a').format(event.endTime)}'
            .toUpperCase();

    return Row(
      children: [
        const Icon(
          Icons.workspace_premium_rounded,
          color: _primaryOrange,
          size: 15,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '$dateStr • $timeStr',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTournamentChipsRow(EventEntity event) {
    final prizeText =
        FeatureFlags.disableFinancialRewards
            ? (event.cost.trim().isEmpty ? 'Entry open' : event.cost)
            : event.points > 0
            ? '${NumberFormat('#,###').format(event.points)} PTS'
            : (event.rewards.isNotEmpty ? event.rewards.first : '50,000 PTS');

    final formatText = event.format ?? '5v5 Knockout';
    final costText =
        event.cost.trim().toLowerCase() == 'free' ||
                event.cost.trim().toLowerCase() == '0' ||
                event.cost.isEmpty
            ? 'Free Entry'
            : '${event.cost} Entry';

    final platformText = event.platform ?? 'Open Arena';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          // 1. Prize Pool Chip (Gold Trophy)
          _buildMetricChip(
            icon: Icons.emoji_events_rounded,
            iconColor: _prizeGold,
            label: prizeText,
            labelColor: _prizeGold,
          ),
          const SizedBox(width: 8),

          // 2. Tournament Format Chip (Crossed Swords / Swords)
          _buildMetricChip(
            icon: Icons.sports_martial_arts_rounded,
            iconColor: _primaryOrange,
            label: formatText,
            labelColor: _textHeading,
          ),
          const SizedBox(width: 8),

          // 3. Entry Cost Chip
          _buildMetricChip(
            icon: Icons.confirmation_number_outlined,
            iconColor: _slotsGreen,
            label: costText,
            labelColor: _slotsGreen,
          ),
          const SizedBox(width: 8),

          // 4. Platform / Division Chip
          _buildMetricChip(
            icon: Icons.shield_outlined,
            iconColor: _textSecondary,
            label: platformText,
            labelColor: _textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color labelColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _chipBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContendersRow(EventEntity event) {
    String contendersSummary = '18 competing squads checked in';
    if (event.userParticipants.isNotEmpty) {
      final firstTwo = event.userParticipants.take(2).join(', ');
      final remaining = event.userParticipants.length - 2;
      contendersSummary =
          remaining > 0
              ? '$firstTwo & $remaining contenders checked in'
              : firstTwo;
    } else if (event.enrollments > 0) {
      if (event.enrollments >= 3) {
        contendersSummary =
            'Team Alpha, Viper Squad & ${event.enrollments - 2} contenders ready';
      } else {
        contendersSummary =
            '${event.enrollments} contender${event.enrollments == 1 ? '' : 's'} registered';
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
          // Overlapping Contender Avatar Stack
          SizedBox(
            width: 74,
            height: 36,
            child: _buildContenderAvatarStack(diameter: 36),
          ),
          const SizedBox(width: 12),

          // Titles Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Registered Contenders',
                  style: GoogleFonts.geist(
                    color: _textHeading,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  contendersSummary,
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

  Widget _buildContenderAvatarStack({double diameter = 32}) {
    final avatarUrls = [
      'https://images.unsplash.com/photo-1566492031773-4f4e44671857?w=100&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=100&auto=format&fit=crop&q=80',
    ];
    final fallbackColors = [
      const Color(0xFFEF4444),
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
    ];
    final fallbackInitials = ['A', 'V', 'T'];

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

  Widget _buildHostArenaCard(EventEntity event) {
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
                    'BATTLEGROUND ARENA',
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
                    'Tournament Venue',
                    style: TextStyle(color: _textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.location,
                    style: const TextStyle(
                      color: _textHeading,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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

  Widget _buildTournamentStatsGrid(EventEntity event) {
    return Column(
      children: [
        Row(
          children: [
            // Kickoff Countdown Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _subCardBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MATCH KICKOFF',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    CountdownTimerCompact(eventDate: event.startTime),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Contenders Joined Rolling Counter Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _subCardBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CONTENDERS',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        RollingCounter(
                          number: event.enrollments,
                          digitHeight: 24,
                          digitWidth: 16,
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          event.maxParticipants != null
                              ? '/ ${event.maxParticipants}'
                              : 'JOINED',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTournamentTabsHeader() {
    final tabs = ['RULES & OVERVIEW', 'SCHEDULE', 'PRIZE POOL'];

    return Container(
      decoration: BoxDecoration(
        color: _subCardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = activeTab == index;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => activeTab = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? _primaryOrange : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    tabs[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : _textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTournamentTabContent(BuildContext context, EventEntity event) {
    switch (activeTab) {
      case 0:
        return _buildRulesTab(event);
      case 1:
        return _buildScheduleTab(event);
      case 2:
        return _buildPrizePoolTab(event);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRulesTab(EventEntity event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description / Overview
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _subCardBackground,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ABOUT THE SHOWDOWN',
                style: GoogleFonts.geist(
                  color: _textHeading,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                event.description ??
                    'Prepare for the ultimate competitive showdown. Register now to secure your spot on the leaderboard and battle for the grand championship.',
                maxLines: isDescExpanded ? null : 3,
                overflow: isDescExpanded ? null : TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _textSecondary,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => setState(() => isDescExpanded = !isDescExpanded),
                child: Text(
                  isDescExpanded ? 'Read Less' : 'Read More',
                  style: const TextStyle(
                    color: _primaryOrange,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Tournament Rules Spec Sheet
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _subCardBackground,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COMPETITIVE SPECIFICATIONS',
                style: GoogleFonts.geist(
                  color: _textHeading,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 14),
              _buildSpecItem('Organizer', event.organizer),
              _buildSpecItem(
                'Game / Discipline',
                event.game ?? 'Multi-Discipline',
              ),
              _buildSpecItem(
                'Format',
                event.format ?? '5v5 Double Elimination',
              ),
              _buildSpecItem(
                'Platform / Arena',
                event.platform ?? 'Open Arena',
              ),
              _buildSpecItem(
                'Match Rules',
                event.rules ?? 'Standard Competitive Rules Apply',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleTab(EventEntity event) {
    final stages = [
      {
        'phase': 'CHECK-IN WINDOW',
        'time': '30 MINUTES BEFORE KICKOFF',
        'desc': 'All contenders must check in at the battleground reception.',
      },
      {
        'phase': 'QUALIFIERS / ROUND 1',
        'time': DateFormat('h:mm a').format(event.startTime),
        'desc': 'Seeded bracket knockout stages commence.',
      },
      {
        'phase': 'SEMI-FINALS',
        'time': DateFormat(
          'h:mm a',
        ).format(event.startTime.add(const Duration(hours: 2))),
        'desc': 'Top 4 squads battle for grand final qualification.',
      },
      {
        'phase': 'GRAND FINALS & CEREMONY',
        'time': DateFormat('h:mm a').format(event.endTime),
        'desc': 'Championship showdown and trophy presentation.',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _subCardBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOURNAMENT TIMELINE',
                style: GoogleFonts.geist(
                  color: _textHeading,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              if (event.bracketUrl != null && event.bracketUrl!.isNotEmpty)
                GestureDetector(
                  onTap: () async {
                    final uri = Uri.tryParse(event.bracketUrl!);
                    if (uri != null && await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  child: const Text(
                    'VIEW BRACKET ↗',
                    style: TextStyle(
                      color: _primaryOrange,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          ...stages.map(
            (stage) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _primaryOrange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                stage['phase']!,
                                style: const TextStyle(
                                  color: _textHeading,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              stage['time']!,
                              style: const TextStyle(
                                color: _primaryOrange,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          stage['desc']!,
                          style: const TextStyle(
                            color: _textSecondary,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrizePoolTab(EventEntity event) {
    final prizePoolList = [
      {
        'place': '1ST PLACE (CHAMPIONS)',
        'reward':
            FeatureFlags.disableFinancialRewards
                ? 'Winner recognition'
                : '₹30,000 + 30,000 PTS',
        'perk': 'Gold Championship Trophy & Verified Winner Badge',
        'icon': Icons.emoji_events_rounded,
        'color': _prizeGold,
      },
      {
        'place': '2ND PLACE (RUNNER-UP)',
        'reward':
            FeatureFlags.disableFinancialRewards
                ? 'Finalist recognition'
                : '₹15,000 + 15,000 PTS',
        'perk': 'Silver Finalist Plaque & 500 Vibe XP',
        'icon': Icons.military_tech_rounded,
        'color': const Color(0xFF94A3B8),
      },
      {
        'place': '3RD PLACE',
        'reward':
            FeatureFlags.disableFinancialRewards
                ? 'Podium recognition'
                : '₹5,000 + 5,000 PTS',
        'perk': 'Bronze Podiums Medal & 250 Vibe XP',
        'icon': Icons.military_tech_outlined,
        'color': const Color(0xFFD97706),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _subCardBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PRIZE DISTRIBUTION',
            style: GoogleFonts.geist(
              color: _textHeading,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          ...prizePoolList.map(
            (prize) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _chipBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: (prize['color'] as Color).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      prize['icon'] as IconData,
                      color: prize['color'] as Color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prize['place'] as String,
                          style: const TextStyle(
                            color: _textSecondary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          prize['reward'] as String,
                          style: TextStyle(
                            color: prize['color'] as Color,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          prize['perk'] as String,
                          style: const TextStyle(
                            color: _textSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: const TextStyle(color: _textSecondary, fontSize: 12.5),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _textHeading,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
          'Already Entered Showdown',
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

    String label = 'ENTER TOURNAMENT';
    if (paidBlocked) {
      label = 'Free Launch Only';
    } else if (!isOpen) {
      final now = DateTime.now();
      if (now.isBefore(event.registrationStart)) {
        label =
            'Registration Opens ${DateFormat('MMM d').format(event.registrationStart)}';
      } else {
        label = 'Registration Closed';
      }
    } else if (isFull) {
      label = 'Tournament Full';
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
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color:
                      isOpen && !isFull && !paidBlocked
                          ? Colors.white
                          : _iconMuted,
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
