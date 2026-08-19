import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

class _TransactionsScreenState extends State<TransactionsScreen>
    with RefreshRateMixin {
  bool _isLoading = true;
  List<PaymentEntity> _payments = [];
  List<_CreditEntry> _credits = [];
  RealtimeChannel? _creditChannel;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _creditChannel =
        locator.supabase
            .channel('tiermetry-credit-ledger')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'tiermetry_credit_ledger',
              callback: (_) => _loadTransactions(),
            )
            .subscribe();
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

        final credits = await locator.supabase
            .from('tiermetry_credit_ledger')
            .select('id, amount, reason, created_at, booking_id')
            .order('created_at', ascending: false);
        if (mounted) {
          setState(() {
            _payments =
                (response as List)
                    .map(
                      (json) => PaymentEntity(
                        id: json['id'] as String,
                        amount: (json['amount'] as num).toDouble(),
                        status: PaymentStatus.values.firstWhere(
                          (e) => e.name == json['status'],
                        ),
                        createdAt: DateTime.parse(json['created_at'] as String),
                        updatedAt: DateTime.parse(json['updated_at'] as String),
                        bookingId: json['booking_id'] as String?,
                        holdId: json['hold_id'] as String?,
                        method: json['method'] as String?,
                      ),
                    )
                    .toList();
            _credits =
                (credits as List)
                    .map(
                      (json) => _CreditEntry(
                        id: json['id'] as String,
                        amount: (json['amount'] as num).toDouble(),
                        reason: json['reason'] as String? ?? 'service recovery',
                        createdAt: DateTime.parse(json['created_at'] as String),
                      ),
                    )
                    .toList();
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
                  title: Text(('My Transactions').toUpperCase(),
                    style: TiermetryTypography.title(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver:
                _isLoading
                    ? const SliverToBoxAdapter(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: TiermetryColors.accentNeonGreen,
                        ),
                      ),
                    )
                    : _payments.isEmpty && _credits.isEmpty
                    ? const SliverToBoxAdapter(
                      child: Center(
                        child: Text(
                          'No transactions yet.',
                          style: TextStyle(color: Colors.white38),
                        ),
                      ),
                    )
                    : SliverList(
                      delegate: SliverChildListDelegate([
                        if (_credits.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: Text(
                              'TIERMETRY CREDITS',
                              style: TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ..._credits.map(
                            (credit) => _buildCreditItem(context, credit),
                          ),
                          const SizedBox(height: 14),
                        ],
                        ..._payments.map(
                          (payment) => _buildTransactionItem(context, payment),
                        ),
                      ]),
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
            payment.bookingId != null
                ? Icons.sports_esports_rounded
                : Icons.local_activity_rounded,
            color: isSuccess ? TiermetryColors.accentNeonGreen : Colors.white38,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((payment.bookingId != null ? 'Arena Booking' : 'Event Ticket').toUpperCase(),
                  style: TiermetryTypography.title(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${DateFormat('MMM d, yyyy').format(payment.createdAt)} • ${payment.status.name.toUpperCase()}',
                  style: TiermetryTypography.bodySmall(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(('₹${payment.amount.toInt()}').toUpperCase(),
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

  Widget _buildCreditItem(BuildContext context, _CreditEntry credit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_rounded, color: Colors.amber),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(('Service recovery credit').toUpperCase(),
                  style: TiermetryTypography.title(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  DateFormat('MMM d, yyyy').format(credit.createdAt),
                  style: TiermetryTypography.bodySmall(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(('+₹${credit.amount.toStringAsFixed(0)}').toUpperCase(),
            style: TiermetryTypography.title(
              color: Colors.amber,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _creditChannel?.unsubscribe();
    super.dispose();
  }
}

class _CreditEntry {
  final String id;
  final double amount;
  final String reason;
  final DateTime createdAt;
  const _CreditEntry({
    required this.id,
    required this.amount,
    required this.reason,
    required this.createdAt,
  });
}
