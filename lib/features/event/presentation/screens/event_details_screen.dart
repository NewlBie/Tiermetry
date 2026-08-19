import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/mixins/refresh_rate_mixin.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_pill.dart';
import 'package:tiermetry/core/widgets/app_surface.dart';

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
    final event = widget.event;
    return Scaffold(
      backgroundColor: TiermetryColors.background,
      body: Stack(
        children: [
          // Background image
          Hero(
            tag: event.id,
            child:
                event.image != null && !event.image!.startsWith('assets/')
                    ? Image.network(
                      event.image!,
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            height: 300,
                            width: double.infinity,
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
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
          ),

          // Back button
          Positioned(
            top: 40,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.transparent,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: TiermetryColors.white,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Draggable Sheet
          DraggableScrollableSheet(
            initialChildSize: 0.685,
            minChildSize: 0.685,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(color: TiermetryColors.surface),
                child: Column(
                  children: [
                    // ✅ Top SVG
                    SvgPicture.asset(
                      'assets/ticket_cut.svg',
                      width: MediaQuery.of(context).size.width,
                      fit: BoxFit.fitWidth,
                      colorFilter: const ColorFilter.mode(
                        TiermetryColors.primary,
                        BlendMode.srcIn,
                      ),
                    ),

                    // ✅ Scrollable Content
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 18,
                        ),
                        children: [
                          Text((event.title).toUpperCase(),
                            style: TiermetryTypography.title(
                              fontSize: 26,
                              color: TiermetryColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            event.location,
                            style: TiermetryTypography.bodySmall(
                              fontSize: 15,
                              color: TiermetryColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Info rows
                          _buildInfoRow(
                            Icons.calendar_today,
                            'Date',
                            DateFormat(
                              'EEEE, MMM d, y',
                            ).format(event.startTime),
                          ),
                          _buildInfoRow(
                            Icons.access_time,
                            'Time',
                            '${DateFormat('hh:mm a').format(event.startTime)} - ${DateFormat('hh:mm a').format(event.endTime)}',
                          ),
                          _buildInfoRow(
                            Icons.location_on_outlined,
                            'Location',
                            event.location,
                          ),
                          _buildInfoRow(
                            Icons.monetization_on_outlined,
                            'Cost',
                            event.cost,
                          ),
                          _buildInfoRow(
                            Icons.stars,
                            'Points',
                            '${event.points} pts',
                          ),
                          const SizedBox(height: 20),

                          // 📊 Total Enrollments
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(('Total Enrollments').toUpperCase(),
                                style: TiermetryTypography.titleSmall(
                                  fontSize: 16,
                                  color: TiermetryColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  RollingCounter(number: event.enrollments),
                                  const SizedBox(width: 8),
                                  Text(
                                    'joined',
                                    style: TiermetryTypography.bodySmall(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                      color: TiermetryColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          Text(('Time Remaining').toUpperCase(),
                            style: TiermetryTypography.titleSmall(
                              fontSize: 16,
                              color: TiermetryColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CountdownTimer(eventDate: event.startTime),
                          const SizedBox(height: 30),

                          Text(('Event Perks').toUpperCase(),
                            style: TiermetryTypography.titleSmall(
                              fontSize: 16,
                              color: TiermetryColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          event.perks.isEmpty
                              ? Text(
                                'No specific perks listed for this event.',
                                style: TiermetryTypography.bodySmall(
                                  color: TiermetryColors.textSecondary,
                                ),
                              )
                              : Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children:
                                    event.perks
                                        .map(
                                          (perk) => _perkTile(
                                            _getIconData(perk.icon),
                                            perk.name,
                                          ),
                                        )
                                        .toList(),
                              ),
                          const SizedBox(height: 24),

                          Text(('Description').toUpperCase(),
                            style: TiermetryTypography.titleSmall(
                              fontSize: 16,
                              color: TiermetryColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            event.description ?? 'No description available.',
                            style: TiermetryTypography.bodySmall(
                              fontSize: 14,
                              height: 1.6,
                              color: TiermetryColors.textSecondary,
                            ),
                          ),

                          const SizedBox(height: 24),

                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children:
                                event.tags
                                    .map(
                                      (tag) => AppPill(
                                        text: tag,
                                        color: TiermetryColors.violet300,
                                        textColor: TiermetryColors.white,
                                      ),
                                    )
                                    .toList(),
                          ),

                          const SizedBox(height: 30),

                          // CTA BUTTON
                          _buildCTAButton(event),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCTAButton(EventEntity event) {
    if (_isLoadingStatus) {
      return const Center(
        child: CircularProgressIndicator(color: TiermetryColors.primary),
      );
    }

    if (_isRegistered) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: TiermetryColors.surfaceElement,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TiermetryRadii.sm),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          minimumSize: const Size.fromHeight(50),
        ),
        child: Text(
          'Already Registered',
          style: TiermetryTypography.action(
            fontSize: 15,
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
        label =
            'Registration Opens ${DateFormat('MMM d').format(event.registrationStart)}';
      } else {
        label = 'Registration Closed';
      }
    } else if (isFull) {
      label = 'Event Full';
    }

    return ElevatedButton(
      onPressed:
          (isOpen && !isFull && !_isRegistering) ? _handleRegister : null,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isOpen && !isFull
                ? TiermetryColors.primary
                : TiermetryColors.surfaceElement,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TiermetryRadii.sm),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        minimumSize: const Size.fromHeight(50),
      ),
      child:
          _isRegistering
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
                  fontSize: 15,
                  color:
                      isOpen && !isFull
                          ? TiermetryColors.white
                          : TiermetryColors.white.withValues(alpha: 0.5),
                ),
              ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: TiermetryColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Text(
            '$title: ',
            style: TiermetryTypography.bodySmall(
              fontWeight: FontWeight.w600,
              color: TiermetryColors.textPrimary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TiermetryTypography.bodySmall(
                color: TiermetryColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _perkTile(IconData icon, String label) {
    return AppSurface(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: TiermetryColors.violet300.withValues(alpha: 0.2),
      borderRadius: 12,
      border: Border.all(color: Colors.transparent),
      shadows: const [],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: TiermetryColors.positive),
          const SizedBox(width: 6),
          Text(
            label,
            style: TiermetryTypography.bodySmall(
              fontSize: 13,
              color: TiermetryColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'fastfood':
        return Icons.fastfood;
      case 'stars':
        return Icons.stars;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'verified_user':
        return Icons.verified_user;
      case 'chair':
        return Icons.chair;
      case 'people':
        return Icons.people;
      case 'wifi':
        return Icons.wifi;
      case 'notifications':
        return Icons.notifications;
      default:
        return Icons.star_border_rounded;
    }
  }
}

class CountdownTimer extends StatefulWidget {
  final DateTime eventDate;

  const CountdownTimer({required this.eventDate, super.key});

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
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

    return Text(('$days Days : $hours Hrs : $minutes Min').toUpperCase(),
      style: TiermetryTypography.titleSmall(
        fontSize: 20,
        color: TiermetryColors.textSecondary,
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

    // Delay the animation slightly so user sees it after page loads
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        animatedValue = widget.digit.toDouble();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 10, end: animatedValue),
      duration: const Duration(milliseconds: 1200), // Slower scroll
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return ClipRect(
          child: SizedBox(
            height: 40,
            width: 24,
            child: Stack(
              alignment: Alignment.center,
              children: List.generate(10, (i) {
                return Positioned(
                  top: (i - value) * 40,
                  child: Text(('$i').toUpperCase(),
                    style: TiermetryTypography.title(
                      fontSize: 30,
                      color: TiermetryColors.positive,
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
      mainAxisAlignment: MainAxisAlignment.start,
      children:
          digits.map((digit) {
            return RollingDigit(digit: digit);
          }).toList(),
    );
  }
}
