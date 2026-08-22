import 'dart:async';

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/mixins/refresh_rate_mixin.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_pill.dart';
import 'package:tiermetry/core/widgets/app_surface.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/event_entity.dart';

class EventDetailsScreen extends StatefulWidget {
  final EventEntity event;

  const EventDetailsScreen({required this.event, super.key});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen>
    with RefreshRateMixin {
  final _eventCtrl = locator.eventCtrl;
  bool _isRegistered = false;
  bool _isLoadingStatus = true;
  bool _isRegistering = false;
  bool isDescExpanded = false;

  @override
  void initState() {
    super.initState();
    _checkRegistration();
  }

  Future<void> _checkRegistration() async {
    try {
      final status = await _eventCtrl.checkRegistrationStatus(widget.event.id);
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
    try {
      await _eventCtrl.registerForEvent(widget.event.id);
      if (mounted) {
        setState(() {
          _isRegistered = true;
          _isRegistering = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRegistering = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const scaffoldColor = TiermetryColors.background;
    const accentColor = TiermetryColors.primary;
    final event = widget.event;

    return Scaffold(
      backgroundColor: scaffoldColor,
      extendBody: true,
      body: Stack(
        children: [
          // Ambient blurred background glow
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.network(
                event.image ?? '',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),
          // Main content
          CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildCoverImage(context, event),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TiermetrySpacing.screenPadding,
                    vertical: TiermetrySpacing.xl,
                  ),
                  child: _buildDetailsContent(context, event, accentColor),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomCTA(context, event),
    );
  }

  Widget _buildCoverImage(BuildContext context, EventEntity event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: TiermetrySpacing.lg,
            right: TiermetrySpacing.lg,
            top: 60, // Padding for status bar
            bottom: TiermetrySpacing.sm,
          ),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const FaIcon(
              FontAwesomeIcons.chevronLeft,
              color: TiermetryColors.white,
              size: 22,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TiermetrySpacing.screenPadding,
          ),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: event.id,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(TiermetryRadii.lg),
                    child: event.image != null && !event.image!.startsWith('assets/')
                        ? Image.network(
                            event.image!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: TiermetryColors.surfaceUnderlay,
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.white24,
                                size: 50,
                              ),
                            ),
                          )
                        : Image.asset(
                            event.image ?? 'assets/Hackathon.jpg',
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: AppSurface(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    color: TiermetryColors.primary,
                    borderRadius: TiermetryRadii.pill,
                    shadows: const [],
                    child: Text(
                      event.status.toUpperCase(),
                      style: TiermetryTypography.label(
                        color: TiermetryColors.white,
                      ).copyWith(fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                if (event.points > 0)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: AppSurface(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      color: TiermetryColors.surfaceUnderlay,
                      borderRadius: TiermetryRadii.pill,
                      shadows: const [],
                      child: Row(
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.solidStar,
                            size: 12,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${event.points} PTS',
                            style: TiermetryTypography.label(
                              color: Colors.amber,
                            ).copyWith(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsContent(
    BuildContext context,
    EventEntity event,
    Color accentColor,
  ) {
    const textColorPrimary = TiermetryColors.white;
    const textColorSecondary = TiermetryColors.textMuted;
    const cardBackgroundColor = TiermetryColors.surfaceUnderlay;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Massive Title
        Text(
          event.title.toUpperCase(),
          style: TiermetryTypography.displayLarge(
            color: textColorPrimary,
          ).copyWith(
            height: 1.1,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        
        // Tags
        if (event.tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: event.tags.map((tag) => AppPill(
              text: tag,
              color: cardBackgroundColor,
              textColor: TiermetryColors.white,
            )).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Unified Info Dashboard
        AppSurface(
          padding: const EdgeInsets.all(TiermetrySpacing.lg),
          color: cardBackgroundColor,
          borderRadius: TiermetryRadii.lg,
          child: Column(
            children: [
              _infoRow(
                FontAwesomeIcons.calendarDay,
                DateFormat('EEEE, MMM d, y').format(event.startTime),
                textColorSecondary,
              ),
              const SizedBox(height: 16),
              _infoRow(
                FontAwesomeIcons.clock,
                '${DateFormat('hh:mm a').format(event.startTime)} - ${DateFormat('hh:mm a').format(event.endTime)}',
                textColorSecondary,
              ),
              const SizedBox(height: 16),
              _buildLocationCard(
                context,
                event,
                textColorSecondary,
                cardBackgroundColor,
                accentColor,
              ),
              const SizedBox(height: 16),
              _infoRow(
                FontAwesomeIcons.ticket,
                event.cost,
                TiermetryColors.positive,
                isBold: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Event Status / Stats Card
        Row(
          children: [
            Expanded(
              child: AppSurface(
                padding: const EdgeInsets.all(TiermetrySpacing.lg),
                color: cardBackgroundColor,
                borderRadius: TiermetryRadii.lg,

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL JOINED',
                      style: TiermetryTypography.label(
                        color: textColorSecondary,
                      ).copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        RollingCounter(number: event.enrollments),
                        const SizedBox(width: 8),
                        Text(
                          'users',
                          style: TiermetryTypography.bodySmall(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColorSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppSurface(
                padding: const EdgeInsets.all(TiermetrySpacing.lg),
                color: cardBackgroundColor,
                borderRadius: TiermetryRadii.lg,

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STARTS IN',
                      style: TiermetryTypography.label(
                        color: textColorSecondary,
                      ).copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    CountdownTimerCompact(eventDate: event.startTime),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: TiermetrySpacing.xl),

        // Quick Perks
        if (event.perks.isNotEmpty) ...[
          Wrap(
            spacing: TiermetrySpacing.lg,
            runSpacing: TiermetrySpacing.md,
            children: event.perks.map((perk) => _featureIcon(
              _getFaIconData(perk.icon),
              perk.name,
              textColorSecondary,
            )).toList(),
          ),
          const SizedBox(height: TiermetrySpacing.xl),
        ],

        // Description
        Text(
          event.description ?? 'No description available.',
          maxLines: isDescExpanded ? null : 4,
          overflow: isDescExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: TiermetryTypography.bodySmall(
            height: 1.5,
            fontSize: 14,
            color: textColorSecondary,
          ),
        ),
        GestureDetector(
          onTap: () => setState(() => isDescExpanded = !isDescExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: TiermetrySpacing.sm),
            child: Text(
              isDescExpanded ? 'Read Less' : 'Read More',
              style: TiermetryTypography.bodySmall(
                color: TiermetryColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 120), // Bottom padding for CTA
      ],
    );
  }

  Widget _buildLocationCard(
    BuildContext context,
    EventEntity event,
    Color textColorSecondary,
    Color cardBackgroundColor,
    Color accentColor,
  ) {
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
      child: AppSurface(
        padding: const EdgeInsets.all(TiermetrySpacing.md),
        color: TiermetryColors.background, // contrast against card background
        borderRadius: TiermetryRadii.md,
        child: Row(
          children: [
            AppSurface(
              padding: const EdgeInsets.all(TiermetrySpacing.md),
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: TiermetryRadii.pill,
              child: Icon(
                Icons.location_on_rounded,
                size: 20,
                color: accentColor,
              ),
            ),
            const SizedBox(width: TiermetrySpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location',
                    style: TiermetryTypography.bodySmall(
                      color: textColorSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    event.location,
                    style: TiermetryTypography.bodySmall(
                      color: TiermetryColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: textColorSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(FaIconData icon, String text, Color color, {bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FaIcon(icon, size: 16, color: TiermetryColors.white.withValues(alpha: 0.5)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: TiermetryTypography.bodySmall(
              fontSize: 15,
              color: color,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _featureIcon(FaIconData icon, String label, Color textColor) {
    return Column(
      children: [
        AppSurface(
          padding: const EdgeInsets.all(TiermetrySpacing.md),
          color: TiermetryColors.surfaceUnderlay,
          borderRadius: 16,
          child: FaIcon(icon, color: TiermetryColors.white, size: 20),
        ),
        const SizedBox(height: TiermetrySpacing.xs),
        Text(
          label,
          style: TiermetryTypography.label(color: textColor).copyWith(fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildBottomCTA(BuildContext context, EventEntity event) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.only(
            left: TiermetrySpacing.screenPadding,
            right: TiermetrySpacing.screenPadding,
            top: TiermetrySpacing.md,
            bottom: 32,
          ),
          decoration: BoxDecoration(
            color: TiermetryColors.background.withValues(alpha: 0.75),
          ),
          child: _buildCTAButton(event),
        ),
      ),
    );
  }

  Widget _buildCTAButton(EventEntity event) {
    if (_isLoadingStatus) {
      return const SizedBox(
        height: 56,
        child: Center(
          child: CircularProgressIndicator(color: TiermetryColors.primary),
        ),
      );
    }

    if (_isRegistered) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: TiermetryColors.surfaceElement,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TiermetryRadii.md),
          ),
          minimumSize: const Size.fromHeight(56),
        ),
        child: Text(
          'Already Registered',
          style: TiermetryTypography.action(
            fontSize: 16,
            color: TiermetryColors.white.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    final bool isOpen = event.isRegistrationOpen;
    final bool isFull = event.isFull;

    String label = 'Join This Event';
    if (!isOpen) {
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
      onPressed: (isOpen && !isFull && !_isRegistering) ? _handleRegister : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: isOpen && !isFull ? TiermetryColors.primary : TiermetryColors.surfaceElement,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TiermetryRadii.md),
        ),
        minimumSize: const Size.fromHeight(56),
      ),
      child: _isRegistering
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: TiermetryColors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              label,
              style: TiermetryTypography.action(
                fontSize: 16,
                color: isOpen && !isFull ? TiermetryColors.white : TiermetryColors.white.withValues(alpha: 0.5),
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
      return Text('STARTED',
        style: TiermetryTypography.title(
          fontSize: 18,
          color: TiermetryColors.primary,
        ),
      );
    }

    return Text(
      '${days}D : ${hours}H : ${minutes}M',
      style: TiermetryTypography.title(
        fontSize: 18,
        color: TiermetryColors.white,
      ),
    );
  }
}

class RollingDigit extends StatefulWidget {
  final int digit;

  const RollingDigit({required this.digit, super.key});

  @override
  State<RollingDigit> createState() => _RollingDigitState();
}

class _RollingDigitState extends State<RollingDigit> {
  late double animatedValue = 10;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          animatedValue = widget.digit.toDouble();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 10, end: animatedValue),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return ClipRect(
          child: SizedBox(
            height: 24,
            width: 14,
            child: Stack(
              alignment: Alignment.center,
              children: List.generate(10, (i) {
                return Positioned(
                  top: (i - value) * 24,
                  child: Text(
                    '$i',
                    style: TiermetryTypography.title(
                      fontSize: 20,
                      color: TiermetryColors.white,
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

class RollingCounter extends StatelessWidget {
  final int number;

  const RollingCounter({required this.number, super.key});

  @override
  Widget build(BuildContext context) {
    final digits = number.toString().split('').map(int.parse).toList();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: digits.map((digit) => RollingDigit(digit: digit)).toList(),
    );
  }
}
