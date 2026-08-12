import 'package:flutter/material.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/theme/colors.dart';
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
    
    // Simulate provider callback
    final provider = locator.paymentProvider as DevelopmentPaymentProvider;
    provider.simulatePaymentResult(widget.order.orderId, status);
    
    // Wait for the simulated callback to "propagate"
    await Future<void>.delayed(const Duration(seconds: 1));
    
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
        title: const Text('Development Payment Gateway'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: AppSurface(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.developer_mode, size: 64, color: TiermetryColors.accentAppleBlue),
                const SizedBox(height: 24),
                Text(
                  'Order: ${widget.order.orderId}',
                  style: TiermetryTypography.bodySmall(color: TiermetryColors.textMuted),
                ),
                const SizedBox(height: 8),
                Text(
                  'Amount: ₹${widget.order.amount}',
                  style: TiermetryTypography.title(fontSize: 24, color: TiermetryColors.white),
                ),
                const SizedBox(height: 32),
                if (_isProcessing)
                  const CircularProgressIndicator(color: TiermetryColors.accentAppleBlue)
                else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _handlePayment(PaymentStatus.paid),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TiermetryColors.positive,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('SIMULATE SUCCESS'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _handlePayment(PaymentStatus.failed),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TiermetryColors.negative,
                        side: const BorderSide(color: TiermetryColors.negative),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('SIMULATE FAILURE'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => _handlePayment(PaymentStatus.cancelled),
                      style: TextButton.styleFrom(
                        foregroundColor: TiermetryColors.textMuted,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('SIMULATE CANCEL'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
