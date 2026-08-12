import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/mixins/refresh_rate_mixin.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/features/payment/domain/entities/payment_entity.dart';
import 'package:tiermetry/features/payment/domain/entities/payment_status.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> with RefreshRateMixin {
  bool _isLoading = true;
  List<PaymentEntity> _payments = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final userId = locator.supabase.auth.currentUser?.id;
      if (userId != null) {
        final response = await locator.supabase
            .from('payments')
            .select()
            .order('created_at', ascending: false);
        
        if (mounted) {
          setState(() {
            _payments = (response as List).map((json) => PaymentEntity(
              id: json['id'] as String,
              amount: (json['amount'] as num).toDouble(),
              status: PaymentStatus.values.firstWhere((e) => e.name == json['status']),
              createdAt: DateTime.parse(json['created_at'] as String),
              updatedAt: DateTime.parse(json['updated_at'] as String),
              bookingId: json['booking_id'] as String?,
              holdId: json['hold_id'] as String?,
              method: json['method'] as String?,
            )).toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120.0,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    'My Transactions',
                    style: TiermetryTypography.title(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: _isLoading 
              ? const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: TiermetryColors.accentNeonGreen)))
              : _payments.isEmpty
                ? const SliverToBoxAdapter(child: Center(child: Text('No transactions yet.', style: TextStyle(color: Colors.white38))))
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final payment = _payments[index];
                        return _buildTransactionItem(context, payment);
                      },
                      childCount: _payments.length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, PaymentEntity payment) {
    final isSuccess = payment.status == PaymentStatus.paid;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            payment.bookingId != null ? Icons.sports_esports_rounded : Icons.local_activity_rounded, 
            color: isSuccess ? TiermetryColors.accentNeonGreen : Colors.white38
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.bookingId != null ? 'Arena Booking' : 'Event Ticket',
                  style: TiermetryTypography.title(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${DateFormat('MMM d, yyyy').format(payment.createdAt)} • ${payment.status.name.toUpperCase()}',
                  style: TiermetryTypography.bodySmall(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            '₹${payment.amount.toInt()}',
            style: TiermetryTypography.title(
              color: isSuccess ? Colors.white : Colors.white38,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
