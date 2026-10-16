import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_empty_state.dart';
import 'package:tiermetry/core/widgets/app_error_state.dart';
import 'package:tiermetry/core/widgets/app_pill.dart';
import 'package:tiermetry/core/widgets/app_surface.dart';
import 'package:tiermetry/core/widgets/shimmer_loading.dart';
import 'package:tiermetry/core/widgets/sliding_segmented_tabs.dart';

import '../../domain/entities/event_entity.dart';
import '../widgets/event_check_in_sheet.dart';
import 'event_details_screen.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  final _eventCtrl = locator.eventCtrl;
  final Set<String> _checkedInEventIds = {};
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _eventCtrl.loadMyRegistrations());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TiermetryColors.background,
      body: RefreshIndicator(
        onRefresh: _eventCtrl.loadMyRegistrations,
        backgroundColor: TiermetryColors.surface,
        color: TiermetryColors.accentAppleBlue,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(child: _buildTabs()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                TiermetrySpacing.screenPadding,
                TiermetrySpacing.lg,
                TiermetrySpacing.screenPadding,
                TiermetrySpacing.bottomSafeArea,
              ),
              sliver: ListenableBuilder(
                listenable: _eventCtrl,
                builder: (context, _) {
                  if (_eventCtrl.isLoading &&
                      _eventCtrl.myRegistrations.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: ShimmerLoadingVerticalList(
                        itemHeight: 280,
                        itemCount: 3,
                        spacing: TiermetrySpacing.lg,
                      ),
                    );
                  }

                  if (_eventCtrl.error != null &&
                      _eventCtrl.myRegistrations.isEmpty) {
                    return SliverToBoxAdapter(
                      child: AppErrorState(
                        message: _eventCtrl.error!,
                        onRetry: _eventCtrl.loadMyRegistrations,
                      ),
                    );
                  }

                  final registrations = _filteredRegistrations();

                  if (registrations.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppEmptyState(
                        message: _emptyMessage,
                        actionLabel: 'Explore Events',
                        onAction: () => Navigator.pop(context),
                      ),
                    );
                  }

                  return SliverList.builder(
                    itemCount: registrations.length,
                    itemBuilder: (context, index) {
                      final event = registrations[index];
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: TiermetrySpacing.lg,
                        ),
                        child: _RegistrationCard(
                          event: event,
                          isCheckedIn: _checkedInEventIds.contains(event.id),
                          onOpen: () => _openEvent(event),
                          onCheckIn: () => _checkInEvent(event),
                          onTeam: () => _showTeamSheet(event),
                          onNotifications:
                              () => _showSnack('Event reminders enabled.'),
                          onRules: () => _showRulesSheet(event),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _emptyMessage {
    switch (_activeTab) {
      case 1:
        return 'No live registrations right now.';
      case 2:
        return 'No completed registered events yet.';
      default:
        return 'No upcoming registered events found.';
    }
  }

  List<EventEntity> _filteredRegistrations() {
    final registrations = List<EventEntity>.from(_eventCtrl.myRegistrations);
    switch (_activeTab) {
      case 1:
        return registrations.where((event) => event.isOngoing).toList();
      case 2:
        return registrations.where((event) => event.isCompleted).toList();
      default:
        return registrations.where((event) => event.isUpcoming).toList();
    }
  }

  void _openEvent(EventEntity event) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(builder: (_) => EventDetailsScreen(event: event)),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _checkInEvent(EventEntity event) async {
    await EventCheckInSheet.show(context, event);
    if (!mounted) return;
    setState(() {
      _checkedInEventIds.add(event.id);
    });
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 92,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: FlexibleSpaceBar(
            titlePadding: const EdgeInsetsDirectional.only(
              start: TiermetrySpacing.screenPadding,
              bottom: 16,
            ),
            title: Text(
              'My Events'.toUpperCase(),
              style: TiermetryTypography.title(
                color: TiermetryColors.white,
                fontSize: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TiermetrySpacing.screenPadding,
      ),
      child: SlidingSegmentedTabs(
        tabs: const ['Upcoming', 'Ongoing', 'Completed'],
        selectedIndex: _activeTab,
        onTabSelected: (index) => setState(() => _activeTab = index),
      ),
    );
  }

  void _showTeamSheet(EventEntity event) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: TiermetryColors.surface,
      builder:
          (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(TiermetrySpacing.screenPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.userRegistrationKind == 'team'
                        ? 'Team registration'
                        : event.isStandardEvent
                        ? 'Event pass'
                        : 'Participant registration',
                    style: TiermetryTypography.titleSmall(
                      color: TiermetryColors.white,
                    ),
                  ),
                  const SizedBox(height: TiermetrySpacing.md),
                  _sheetRow(
                    FontAwesomeIcons.circleCheck,
                    'Registration confirmed',
                    event.userRegistrationId == null
                        ? 'Your pass is active for this ${event.kindLabel.toLowerCase()}.'
                        : 'ID: ${event.userRegistrationId}',
                  ),
                  const SizedBox(height: TiermetrySpacing.md),
                  _sheetRow(
                    FontAwesomeIcons.users,
                    event.userRegistrationKind == 'team'
                        ? 'Team status'
                        : event.isStandardEvent
                        ? 'Attendee status'
                        : 'Participant status',
                    event.userRegistrationKind == 'team'
                        ? '${event.userTeamName ?? 'Team'} confirmed${event.userParticipants.isEmpty ? '' : ' with ${event.userParticipants.length} listed participant(s)'}.'
                        : event.isStandardEvent
                        ? 'Attendee pass confirmed.'
                        : 'Individual participant confirmed.',
                  ),
                  const SizedBox(height: TiermetrySpacing.md),
                  _sheetRow(
                    FontAwesomeIcons.creditCard,
                    'Payment',
                    '${event.userPaymentStatus ?? 'not_required'} via ${event.userPaymentMethod ?? 'not_required'}',
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showRulesSheet(EventEntity event) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: TiermetryColors.surface,
      builder:
          (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(TiermetrySpacing.screenPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${event.kindLabel} rules',
                    style: TiermetryTypography.titleSmall(
                      color: TiermetryColors.white,
                    ),
                  ),
                  const SizedBox(height: TiermetrySpacing.md),
                  Text(
                    event.rules?.isNotEmpty == true
                        ? event.rules!
                        : 'Arrive on time, keep your registration confirmation ready, and follow organizer instructions at the venue.',
                    style: TiermetryTypography.bodySmall(
                      color: TiermetryColors.textMuted,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _sheetRow(FaIconData icon, String title, String body) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FaIcon(icon, color: TiermetryColors.accentAppleBlue, size: 18),
        const SizedBox(width: TiermetrySpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TiermetryTypography.bodySmall(
                  color: TiermetryColors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: TiermetryTypography.bodySmall(
                  color: TiermetryColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RegistrationCard extends StatelessWidget {
  final EventEntity event;
  final bool isCheckedIn;
  final VoidCallback onOpen;
  final VoidCallback onCheckIn;
  final VoidCallback onTeam;
  final VoidCallback onNotifications;
  final VoidCallback onRules;

  const _RegistrationCard({
    required this.event,
    required this.isCheckedIn,
    required this.onOpen,
    required this.onCheckIn,
    required this.onTeam,
    required this.onNotifications,
    required this.onRules,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: EdgeInsets.zero,
      borderRadius: TiermetryRadii.lg,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageHeader(),
          Padding(
            padding: const EdgeInsets.all(TiermetrySpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitleBlock(),
                const SizedBox(height: TiermetrySpacing.lg),
                _buildStatusGrid(),
                const SizedBox(height: TiermetrySpacing.lg),
                _buildAnnouncements(),
                const SizedBox(height: TiermetrySpacing.lg),
                _buildActions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageHeader() {
    return Stack(
      children: [
        Hero(
          tag: event.id,
          child:
              event.image != null && !event.image!.startsWith('assets/')
                  ? Image.network(
                    event.image!,
                    fit: BoxFit.cover,
                    height: 150,
                    width: double.infinity,
                    errorBuilder:
                        (_, __, ___) => Container(
                          height: 150,
                          color: TiermetryColors.surfaceUnderlay,
                        ),
                  )
                  : Image.asset(
                    event.image ?? 'assets/Hackathon.jpg',
                    fit: BoxFit.cover,
                    height: 150,
                    width: double.infinity,
                  ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  TiermetryColors.black.withValues(alpha: 0.78),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 12,
          bottom: 12,
          child: AppPill(
            text: event.kindLabel.toUpperCase(),
            color:
                event.isStandardEvent
                    ? TiermetryColors.accentAppleBlue
                    : TiermetryColors.accentNeonGreen,
            textColor:
                event.isStandardEvent ? TiermetryColors.white : Colors.black,
          ),
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: AppPill(
            text: isCheckedIn ? 'CHECKED IN' : 'CONFIRMED',
            color:
                isCheckedIn
                    ? TiermetryColors.positive
                    : TiermetryColors.surfaceUnderlay,
            textColor: isCheckedIn ? Colors.black : TiermetryColors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildTitleBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          event.title.toUpperCase(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TiermetryTypography.title(
            color: TiermetryColors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(
              Icons.location_on_rounded,
              size: 14,
              color: TiermetryColors.textMuted,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                event.location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TiermetryTypography.bodySmall(
                  color: TiermetryColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusGrid() {
    return GridView.count(
      padding: EdgeInsets.zero,
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.7,
      children: [
        _statusChip(
          FontAwesomeIcons.calendarDay,
          'When',
          DateFormat('MMM d • h:mm a').format(event.startTime),
        ),
        _statusChip(
          FontAwesomeIcons.idBadge,
          'Registration',
          event.userRegistrationStatus ?? 'Confirmed',
          valueColor: TiermetryColors.positive,
        ),
        _statusChip(
          FontAwesomeIcons.userGroup,
          event.userRegistrationKind == 'team' ? 'Team' : 'Entry',
          event.userRegistrationKind == 'team'
              ? event.userTeamName ?? 'Team pass'
              : event.isStandardEvent
              ? 'Event pass'
              : 'Individual',
        ),
        _statusChip(
          FontAwesomeIcons.creditCard,
          'Payment',
          event.userPaymentStatus ?? 'not required',
          valueColor:
              (event.userPaymentStatus ?? '').contains('paid')
                  ? TiermetryColors.positive
                  : TiermetryColors.white,
        ),
      ],
    );
  }

  Widget _statusChip(
    FaIconData icon,
    String label,
    String value, {
    Color valueColor = TiermetryColors.white,
  }) {
    return AppSurface(
      height: 64,
      padding: const EdgeInsets.symmetric(
        horizontal: TiermetrySpacing.md,
        vertical: TiermetrySpacing.sm,
      ),
      color: TiermetryColors.surfaceUnderlay,
      borderRadius: TiermetryRadii.sm,
      border: Border.all(color: Colors.transparent),
      shadows: const [],
      child: Row(
        children: [
          FaIcon(icon, color: TiermetryColors.textMuted, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TiermetryTypography.label(
                    color: TiermetryColors.textMuted,
                  ).copyWith(fontSize: 10),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TiermetryTypography.bodySmall(
                    color: valueColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncements() {
    return AppSurface(
      width: double.infinity,
      padding: const EdgeInsets.all(TiermetrySpacing.md),
      color: TiermetryColors.surfaceUnderlay,
      borderRadius: TiermetryRadii.sm,
      border: Border.all(color: Colors.transparent),
      shadows: const [],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FaIcon(
            FontAwesomeIcons.bullhorn,
            color: TiermetryColors.accentAppleBlue,
            size: 16,
          ),
          const SizedBox(width: TiermetrySpacing.md),
          Expanded(
            child: Text(
              event.isStandardEvent
                  ? 'You are on the attendee list. Carry your confirmation at entry.'
                  : 'Registration is confirmed. Competitive match tools will arrive in a later update.',
              style: TiermetryTypography.bodySmall(
                color: TiermetryColors.textMuted,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            icon: FontAwesomeIcons.eye,
            label: 'Details',
            onTap: onOpen,
          ),
        ),
        const SizedBox(width: TiermetrySpacing.sm),
        Expanded(
          child: _actionButton(
            icon: FontAwesomeIcons.users,
            label: event.userRegistrationKind == 'team' ? 'Team' : 'Pass',
            onTap: onTeam,
          ),
        ),
        const SizedBox(width: TiermetrySpacing.sm),
        Expanded(
          child: _actionButton(
            icon: FontAwesomeIcons.bell,
            label: 'Notify',
            onTap: onNotifications,
          ),
        ),
        const SizedBox(width: TiermetrySpacing.sm),
        Expanded(
          child: _actionButton(
            icon:
                isCheckedIn
                    ? FontAwesomeIcons.circleCheck
                    : FontAwesomeIcons.qrcode,
            label: isCheckedIn ? 'Done' : 'Check-in',
            onTap: isCheckedIn ? () {} : onCheckIn,
          ),
        ),
        const SizedBox(width: TiermetrySpacing.sm),
        Expanded(
          child: _actionButton(
            icon: FontAwesomeIcons.scroll,
            label: 'Rules',
            onTap: onRules,
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required FaIconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AppSurface(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        color: TiermetryColors.surfaceUnderlay,
        borderRadius: TiermetryRadii.sm,
        border: Border.all(color: TiermetryColors.borderSubtle),
        shadows: const [],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, size: 14, color: TiermetryColors.white),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TiermetryTypography.label(
                color: TiermetryColors.textMuted,
              ).copyWith(fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}
