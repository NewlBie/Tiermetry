import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_surface.dart';
import '../../data/datasources/development_payment_provider.dart';
import '../../domain/entities/payment_order.dart';
import '../../domain/entities/payment_status.dart';

class MockPaymentScreen extends StatefulWidget {
  final PaymentOrder order;

  const MockPaymentScreen({required this.order, super.key});

  @override
  State<MockPaymentScreen> createState() => _MockPaymentScreenState();
}

class _MockPaymentScreenState extends State<MockPaymentScreen> {
  bool _isProcessing = false;

  Future<void> _handlePayment(PaymentStatus status) async {
    setState(() => _isProcessing = true);

    if (locator.paymentProvider is DevelopmentPaymentProvider) {
      (locator.paymentProvider as DevelopmentPaymentProvider)
          .simulatePaymentResult(widget.order.orderId, status);
    }

    await Future<void>.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      Navigator.pop(context, status);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TiermetryColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Simulated Payment Gateway',
          style: TiermetryTypography.titleSmall(color: TiermetryColors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(TiermetrySpacing.screenPadding),
          child: Column(
            children: [
              // Simulation Notice Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(TiermetryRadii.pill),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.science_rounded, size: 16, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(
                      'SIMULATION MODE · DEV ENVIRONMENT',
                      style: TiermetryTypography.label(color: Colors.amber).copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TiermetrySpacing.xl),

              AppSurface(
                padding: const EdgeInsets.all(TiermetrySpacing.xl),
                color: TiermetryColors.surfaceUnderlay,
                borderRadius: TiermetryRadii.lg,
                border: Border.all(color: TiermetryColors.borderSubtle),
                shadows: const [],
                child: Column(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.shieldHalved,
                      size: 48,
                      color: TiermetryColors.accentNeonGreen,
                    ),
                    const SizedBox(height: TiermetrySpacing.lg),
                    Text(
                      'Order: ${widget.order.orderId}',
                      style: TiermetryTypography.bodySmall(
                        color: TiermetryColors.textMuted,
                      ).copyWith(fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${widget.order.amount.toStringAsFixed(2)}',
                      style: TiermetryTypography.displayLarge(
                        color: TiermetryColors.white,
                      ).copyWith(fontSize: 36, height: 1.1),
                    ),
                    const SizedBox(height: TiermetrySpacing.sm),
                    Text(
                      'Select a deterministic scenario to simulate provider response:',
                      textAlign: TextAlign.center,
                      style: TiermetryTypography.bodySmall(
                        color: TiermetryColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: TiermetrySpacing.xl),

                    if (_isProcessing)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(
                          color: TiermetryColors.accentNeonGreen,
                        ),
                      )
                    else ...[
                      // Scenario 1: Success
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _handlePayment(PaymentStatus.paid),
                          icon: const Icon(Icons.check_circle_rounded, size: 20),
                          label: const Text('SIMULATE SUCCESS (200 OK)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TiermetryColors.positive,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(height: TiermetrySpacing.md),

                      // Scenario 2: Failure
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _handlePayment(PaymentStatus.failed),
                          icon: const Icon(Icons.error_outline_rounded, size: 20),
                          label: const Text('SIMULATE GATEWAY FAILURE'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: TiermetryColors.negative,
                            side: const BorderSide(color: TiermetryColors.negative),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(height: TiermetrySpacing.md),

                      // Scenario 3: Cancel
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () => _handlePayment(PaymentStatus.cancelled),
                          icon: const Icon(Icons.cancel_rounded, size: 18),
                          label: const Text('SIMULATE USER CANCEL'),
                          style: TextButton.styleFrom(
                            foregroundColor: TiermetryColors.textMuted,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: TiermetrySpacing.xl),
              Text(
                'Simulated payments tag events with environment=simulation and do not settle real funds.',
                textAlign: TextAlign.center,
                style: TiermetryTypography.bodySmall(
                  color: TiermetryColors.textMuted,
                ).copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
