import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/features/booking/domain/entities/booking_entity.dart';

class CheckInSheet extends StatefulWidget {
  final BookingEntity booking;

  const CheckInSheet({required this.booking, super.key});

  static Future<void> show(BuildContext context, BookingEntity booking) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Material(
            type: MaterialType.transparency,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: CheckInSheet(booking: booking),
              ),
            ),
          ),
    );
  }

  @override
  State<CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends State<CheckInSheet> {
  int _segmentedControlGroupValue = 0;
  final _bookingCtrl = locator.bookingCtrl;
  final _pinController = TextEditingController();
  Timer? _dismissTimer;
  bool _isSubmitting = false;
  bool _checkInComplete = false;

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submitCode(String code) async {
    if (code.isEmpty || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      await _bookingCtrl.checkInBooking(widget.booking.id, code);
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _checkInComplete = true;
      });
      _dismissTimer = Timer(const Duration(milliseconds: 1600), () {
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkInComplete) {
      return _buildCheckInSuccess(context);
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: TiermetryColors.surface.withValues(alpha: 0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            top: 12,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(('Self Check-In').toUpperCase(),
                style: TiermetryTypography.title(
                  fontSize: 22,
                  color: TiermetryColors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the PIN or scan the QR code provided by the venue. '
                'Check-in opens at ${DateFormat('h:mm a').format(widget.booking.dateTime)} unless early check-in is enabled by the venue.',
                textAlign: TextAlign.center,
                style: TiermetryTypography.bodySmall(
                  color: TiermetryColors.textMuted,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<int>(
                  backgroundColor: Colors.black.withValues(alpha: 0.2),
                  thumbColor: TiermetryColors.surfaceElement,
                  groupValue: _segmentedControlGroupValue,
                  children: {
                    0: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Text(
                        'Enter PIN',
                        style: TiermetryTypography.label(
                          color: TiermetryColors.white,
                        ),
                      ),
                    ),
                    1: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Text(
                        'Scan QR',
                        style: TiermetryTypography.label(
                          color: TiermetryColors.white,
                        ),
                      ),
                    ),
                  },
                  onValueChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _segmentedControlGroupValue = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 32),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child:
                    _segmentedControlGroupValue == 0
                        ? _buildPinView()
                        : _buildQrView(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinView() {
    return Column(
      key: const ValueKey('pin'),
      children: [
        TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 4,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: TiermetryColors.accentNeonGreen,
            letterSpacing: 16,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '0000',
            hintStyle: TextStyle(
              color: TiermetryColors.textMuted.withValues(alpha: 0.3),
            ),
            filled: true,
            fillColor: TiermetryColors.surfaceElement,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TiermetryRadii.md),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TiermetryRadii.md),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TiermetryRadii.md),
              borderSide: const BorderSide(
                color: TiermetryColors.accentNeonGreen,
              ),
            ),
          ),
          onChanged: (val) {
            if (val.length == 4) {
              _submitCode(val);
            }
          },
        ),
        const SizedBox(height: 24),
        Text(
          _isSubmitting
              ? 'Verifying your check-in...'
              : 'Check-in happens automatically after 4 digits.',
          style: TiermetryTypography.bodySmall(
            color: TiermetryColors.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildQrView() {
    return Column(
      key: const ValueKey('qr'),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 250,
            width: double.infinity,
            child: Stack(
              children: [
                MobileScanner(
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty &&
                        barcodes.first.rawValue != null) {
                      _submitCode(barcodes.first.rawValue!);
                    }
                  },
                ),
                if (_isSubmitting)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: TiermetryColors.accentNeonGreen,
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: TiermetryColors.accentNeonGreen.withValues(
                          alpha: 0.5,
                        ),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Point your camera at the owner\'s QR code',
          style: TiermetryTypography.bodySmall(
            color: TiermetryColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckInSuccess(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            top: 32,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).padding.bottom + 32,
          ),
          decoration: BoxDecoration(
            color: TiermetryColors.surface.withValues(alpha: 0.94),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            ),
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.65, end: 1),
            duration: const Duration(milliseconds: 450),
            curve: Curves.elasticOut,
            builder:
                (context, value, child) => Transform.scale(
                  scale: value,
                  child: Opacity(opacity: value.clamp(0, 1), child: child),
                ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: TiermetryColors.accentNeonGreen.withValues(
                      alpha: 0.16,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 48,
                    color: TiermetryColors.accentNeonGreen,
                  ),
                ),
                const SizedBox(height: 20),
                Text(('You’re checked in!').toUpperCase(),
                  style: TiermetryTypography.title(
                    fontSize: 24,
                    color: TiermetryColors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your arrival has been verified. Enjoy your session.',
                  textAlign: TextAlign.center,
                  style: TiermetryTypography.bodySmall(
                    color: TiermetryColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
