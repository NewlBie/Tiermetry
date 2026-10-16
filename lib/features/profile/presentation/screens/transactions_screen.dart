import 'dart:ui';

import 'package:amazing_icons/bulk.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/mixins/refresh_rate_mixin.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_island_notice.dart';
import 'package:tiermetry/core/widgets/shimmer_loading.dart';
import 'package:tiermetry/core/widgets/sliding_segmented_tabs.dart';
import 'package:tiermetry/features/payment/domain/entities/payment_entity.dart';
import 'package:tiermetry/features/payment/domain/entities/payment_status.dart';
import 'package:tiermetry/features/profile/presentation/screens/help_and_support_screen.dart';

enum _PaymentFilter { all, successful, pending, failed, cancelled, refunds }

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsError extends StatelessWidget {
  const _TransactionsError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TiermetrySpacing.lg),
      decoration: BoxDecoration(
        color: TiermetryColors.surfaceUnderlay,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            color: TiermetryColors.accentAppleBlue,
          ),
          const SizedBox(height: TiermetrySpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TiermetryTypography.bodySmall(
              color: TiermetryColors.textMuted,
            ),
          ),
          const SizedBox(height: TiermetrySpacing.md),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with RefreshRateMixin {
  bool _isLoading = true;
  String? _error;
  List<PaymentEntity> _payments = [];
  List<_CreditEntry> _credits = [];
  List<_RefundEntry> _refunds = [];
  RealtimeChannel? _paymentChannel;
  RealtimeChannel? _creditChannel;
  RealtimeChannel? _refundChannel;
  _PaymentFilter _filter = _PaymentFilter.all;

  @override
  void initState() {
    super.initState();
    _loadTransactions();

    final userId = locator.supabase.auth.currentUser?.id;
    if (userId != null) {
      _paymentChannel =
          locator.supabase
              .channel('payments-$userId')
              .onPostgresChanges(
                event: PostgresChangeEvent.all,
                schema: 'public',
                table: 'payments',
                callback: (_) => _loadTransactions(),
              )
              .subscribe();
      _creditChannel =
          locator.supabase
              .channel('tiermetry-credit-ledger-$userId')
              .onPostgresChanges(
                event: PostgresChangeEvent.all,
                schema: 'public',
                table: 'tiermetry_credit_ledger',
                filter: PostgresChangeFilter(
                  type: PostgresChangeFilterType.eq,
                  column: 'user_id',
                  value: userId,
                ),
                callback: (_) => _loadTransactions(),
              )
              .subscribe();
      _refundChannel =
          locator.supabase
              .channel('booking-refunds-$userId')
              .onPostgresChanges(
                event: PostgresChangeEvent.all,
                schema: 'public',
                table: 'booking_refunds',
                filter: PostgresChangeFilter(
                  type: PostgresChangeFilterType.eq,
                  column: 'user_id',
                  value: userId,
                ),
                callback: (_) => _loadTransactions(),
              )
              .subscribe();
    }
  }

  Future<void> _loadTransactions() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final userId = locator.supabase.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'Sign in to view your transactions.';
          });
        }
        return;
      }

      final paymentsResponse = await locator.supabase
          .from('payments')
          .select(
            'id, order_id, booking_id, hold_id, amount, status, method, created_at, updated_at',
          )
          .or('booking_id.not.is.null,hold_id.not.is.null')
          .order('created_at', ascending: false);

      final credits = await locator.supabase
          .from('tiermetry_credit_ledger')
          .select('id, amount, reason, created_at, booking_id')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final refunds = await locator.supabase
          .from('booking_refunds')
          .select(
            'id, booking_id, requested_amount, status, provider, refund_arn, provider_reference, status_description, failure_message, requested_at, processed_at',
          )
          .eq('user_id', userId)
          .order('requested_at', ascending: false);

      final userBookings = await locator.supabase
          .from('bookings')
          .select('id')
          .eq('user_id', userId);
      final userHolds = await locator.supabase
          .from('reservation_holds')
          .select('id')
          .eq('user_id', userId);

      final validBookingIds =
          (userBookings as List).map((b) => b['id'] as String).toSet();
      final validHoldIds =
          (userHolds as List).map((h) => h['id'] as String).toSet();

      if (!mounted) return;
      setState(() {
        _payments =
            (paymentsResponse as List)
                .whereType<Map<String, dynamic>>()
                .where((json) {
                  final bId = json['booking_id'] as String?;
                  final hId = json['hold_id'] as String?;
                  return (bId != null && validBookingIds.contains(bId)) ||
                      (hId != null && validHoldIds.contains(hId));
                })
                .map(
                  (json) => PaymentEntity(
                    id: json['id'] as String,
                    amount: (json['amount'] as num).toDouble(),
                    status: PaymentStatus.values.firstWhere(
                      (e) => e.name == json['status'],
                      orElse: () => PaymentStatus.created,
                    ),
                    createdAt:
                        DateTime.parse(json['created_at'] as String).toLocal(),
                    updatedAt:
                        DateTime.parse(json['updated_at'] as String).toLocal(),
                    bookingId: json['booking_id'] as String?,
                    holdId: json['hold_id'] as String?,
                    orderId: json['order_id'] as String?,
                    method: json['method'] as String?,
                  ),
                )
                .toList();
        _credits =
            (credits as List)
                .whereType<Map<String, dynamic>>()
                .map(
                  (json) => _CreditEntry(
                    id: json['id'] as String,
                    amount: (json['amount'] as num).toDouble(),
                    reason: json['reason'] as String? ?? 'service recovery',
                    bookingId: json['booking_id'] as String?,
                    createdAt:
                        DateTime.parse(json['created_at'] as String).toLocal(),
                  ),
                )
                .toList();
        _refunds =
            (refunds as List)
                .whereType<Map<String, dynamic>>()
                .map(_RefundEntry.fromJson)
                .toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Could not load your transactions. Pull to try again.';
        });
      }
    }
  }

  List<_PaymentActivity> get _allActivities {
    final payments = _payments.map(_PaymentActivity.payment);
    final credits = _credits.map(_PaymentActivity.credit);
    final refunds = _refunds.map(_PaymentActivity.refund);
    final list = [...payments, ...credits, ...refunds]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<_PaymentActivity> get _activities =>
      _allActivities.where(_matchesFilter).toList();

  bool _matchesFilter(_PaymentActivity activity) {
    return switch (_filter) {
      _PaymentFilter.all => true,
      _PaymentFilter.successful => activity.statusLabel == 'Successful',
      _PaymentFilter.pending => activity.statusLabel == 'Pending',
      _PaymentFilter.failed => activity.statusLabel == 'Failed',
      _PaymentFilter.cancelled =>
        activity.statusLabel == 'Cancelled' || activity.isRefundLike,
      _PaymentFilter.refunds => activity.isRefund,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TiermetryColors.background,
      body: Stack(
        children: [
          RefreshIndicator(
            color: TiermetryColors.accentAppleBlue,
            onRefresh: _loadTransactions,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(child: _buildTabs()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    TiermetrySpacing.screenPadding,
                    TiermetrySpacing.lg,
                    TiermetrySpacing.screenPadding,
                    140,
                  ),
                  sliver:
                      _isLoading
                          ? const SliverToBoxAdapter(
                            child: ShimmerLoadingVerticalList(
                              itemHeight: 84,
                              itemCount: 6,
                              spacing: 12,
                            ),
                          )
                          : _error != null
                          ? SliverToBoxAdapter(
                            child: _TransactionsError(
                              message: _error!,
                              onRetry: _loadTransactions,
                            ),
                          )
                          : SliverList(
                            delegate: SliverChildListDelegate([
                              _activitySection(),
                            ]),
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
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
              'Transactions'.toUpperCase(),
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
    const tabs = ['All', 'Successful', 'Pending', 'Refunds'];
    final selectedIndex = switch (_filter) {
      _PaymentFilter.all => 0,
      _PaymentFilter.successful => 1,
      _PaymentFilter.pending => 2,
      _PaymentFilter.refunds || _PaymentFilter.cancelled => 3,
      _PaymentFilter.failed => 0,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TiermetrySpacing.screenPadding,
      ),
      child: SlidingSegmentedTabs(
        tabs: tabs,
        selectedIndex: selectedIndex,
        onTabSelected: (index) {
          setState(() {
            _filter = switch (index) {
              0 => _PaymentFilter.all,
              1 => _PaymentFilter.successful,
              2 => _PaymentFilter.pending,
              3 => _PaymentFilter.refunds,
              _ => _PaymentFilter.all,
            };
          });
        },
      ),
    );
  }

  Widget _activitySection() {
    final activities = _activities;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAppleCardHero(_allActivities),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'LATEST ACTIVITY',
              style: TiermetryTypography.label(
                color: TiermetryColors.textMuted,
                fontSize: 11,
                letterSpacing: 1.1,
              ),
            ),
            _countChip(activities.length),
          ],
        ),
        const SizedBox(height: TiermetrySpacing.md),
        if (activities.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(TiermetrySpacing.xl),
            decoration: BoxDecoration(
              color: TiermetryColors.surfaceUnderlay,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              'No transactions in this state yet.',
              textAlign: TextAlign.center,
              style: TiermetryTypography.bodySmall(
                color: TiermetryColors.textMuted,
              ),
            ),
          )
        else
          ...activities.map(_activityTile),
      ],
    );
  }

  Widget _buildAppleCardHero(List<_PaymentActivity> activities) {
    final totalSpent = activities
        .where((a) => !a.isCredit && a.statusLabel == 'Successful')
        .fold<double>(0.0, (sum, a) => sum + a.amount.abs());
    final totalRefunded = activities
        .where((a) => a.isRefund && a.statusLabel == 'Refunded')
        .fold<double>(0.0, (sum, a) => sum + a.amount.abs());

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: TiermetrySpacing.lg),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF20222A), Color(0xFF141519)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: TiermetryColors.accentAppleBlue.withValues(
                        alpha: 0.20,
                      ),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 16,
                        color: TiermetryColors.accentAppleBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'HOMIES PAY',
                    style: TiermetryTypography.label(
                      color: TiermetryColors.white,
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: TiermetryColors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${activities.length} TRANSACTIONS',
                  style: TiermetryTypography.label(
                    color: TiermetryColors.textMuted,
                    fontSize: 9,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'TOTAL OUTFLOW',
            style: TiermetryTypography.label(
              color: TiermetryColors.textMuted,
              fontSize: 10,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${totalSpent.toStringAsFixed(2)}',
            style: TiermetryTypography.title(
              color: TiermetryColors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ).copyWith(letterSpacing: 0),
          ),
          if (totalRefunded > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.arrow_downward_rounded,
                  size: 14,
                  color: Color(0xFF34C759),
                ),
                const SizedBox(width: 4),
                Text(
                  '+₹${totalRefunded.toStringAsFixed(2)} CREDITED / REFUNDED',
                  style: TiermetryTypography.label(
                    color: const Color(0xFF34C759),
                    fontSize: 10,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _activityTile(_PaymentActivity activity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _showTransactionDetails(activity),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF191A20), Color(0xFF131417)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Apple Pay Activity Glyph
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          activity.color.withValues(alpha: 0.20),
                          activity.color.withValues(alpha: 0.06),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: activity.directionIcon(
                        color:
                            activity.isCredit
                                ? const Color(0xFF34C759)
                                : (activity.color == TiermetryColors.positive
                                    ? const Color(0xFF34C759)
                                    : activity.color),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: activity.color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF191A20),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              // Merchant & Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.feedTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TiermetryTypography.bodySmall(
                        color: TiermetryColors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _relativeTime(activity.createdAt),
                          style: TiermetryTypography.bodySmall(
                            color: TiermetryColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '•',
                          style: TextStyle(
                            color: TiermetryColors.textMuted.withValues(
                              alpha: 0.6,
                            ),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: TiermetryColors.white.withValues(
                              alpha: 0.06,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            activity.methodLabel,
                            style: TiermetryTypography.label(
                              color: TiermetryColors.textMuted,
                              fontSize: 9,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Amount & Chevron
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    activity.amountLabel,
                    style: TiermetryTypography.titleSmall(
                      color:
                          activity.isCredit
                              ? const Color(0xFF34C759)
                              : TiermetryColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ).copyWith(letterSpacing: 0),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: TiermetryColors.textMuted.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label.toUpperCase(),
        style: TiermetryTypography.label(color: color).copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _countChip(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: TiermetryColors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        '$count TOTAL',
        style: TiermetryTypography.label(
          color: TiermetryColors.textMuted,
          fontSize: 9,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  void _showTransactionDetails(_PaymentActivity activity) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.80,
            minChildSize: 0.5,
            maxChildSize: 0.94,
            builder:
                (context, controller) => Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF131418),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(
                      TiermetrySpacing.screenPadding,
                      12,
                      TiermetrySpacing.screenPadding,
                      32,
                    ),
                    children: [
                      Center(
                        child: Container(
                          width: 38,
                          height: 5,
                          decoration: BoxDecoration(
                            color: TiermetryColors.white.withValues(
                              alpha: 0.22,
                            ),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Apple Pay Hero Receipt Center
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: activity.color.withValues(alpha: 0.14),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  activity.isCredit
                                      ? Icons.arrow_downward_rounded
                                      : (activity.statusLabel == 'Successful'
                                          ? Icons.check_circle_rounded
                                          : Icons.schedule_rounded),
                                  size: 32,
                                  color: activity.color,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              activity.amountLabel,
                              style: TiermetryTypography.title(
                                color:
                                    activity.isCredit
                                        ? const Color(0xFF34C759)
                                        : TiermetryColors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                              ).copyWith(letterSpacing: 0),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              activity.feedTitle,
                              style: TiermetryTypography.titleSmall(
                                color: TiermetryColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat(
                                'EEE, d MMM yyyy • h:mm a',
                              ).format(activity.createdAt),
                              style: TiermetryTypography.bodySmall(
                                color: TiermetryColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _statusPill(activity.statusLabel, activity.color),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      _detailCard([
                        _detailRow('Transaction ID', activity.id),
                        _detailRow('Type', activity.typeLabel),
                        _detailRow('Payment Method', activity.methodLabel),
                        _detailRow(
                          'Linked Reference',
                          activity.relatedId ?? 'Not linked',
                        ),
                      ], title: 'TRANSACTION DETAILS'),
                      const SizedBox(height: 16),
                      _invoiceCard(activity),
                      const SizedBox(height: 16),
                      _refundCard(activity),
                      const SizedBox(height: 16),
                      _supportCard(activity),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _invoiceCard(_PaymentActivity activity) {
    return _detailCard([
      _detailRow(
        'Recorded amount',
        '₹${activity.amount.abs().toStringAsFixed(2)}',
      ),
      _detailRow('Method', activity.methodLabel),
      _detailRow('Status', activity.statusLabel),
      _detailRow('Provider order', activity.orderId ?? 'Not available'),
    ], title: 'PAYMENT RECORD');
  }

  Widget _refundCard(_PaymentActivity activity) {
    final refund = activity.refund;
    final text =
        refund != null
            ? refund.status == 'retry_required'
                ? 'Your booking is cancelled and the refund is safely queued for another attempt.'
                : refund.statusDescription ??
                    (refund.status == 'success'
                        ? 'Cashfree confirmed this refund.'
                        : refund.status == 'failed'
                        ? 'The refund needs attention. Contact support with this transaction ID.'
                        : 'The payment provider is processing this refund.')
            : activity.isCredit
            ? 'Refund/service credit settled directly to your wallet ledger.'
            : activity.statusLabel == 'Cancelled'
            ? 'Payment was cancelled. No captured amount is pending refund.'
            : activity.statusLabel == 'Failed'
            ? 'Payment failed before capture. No refund is required.'
            : 'No refund linked to this transaction.';

    return _detailCard([
      _detailRow(
        'Refund Status',
        refund != null
            ? activity.statusLabel
            : activity.isCredit
            ? 'Settled'
            : 'Not applicable',
      ),
      if (refund?.reference != null)
        _detailRow('Provider Reference', refund!.reference!),
      _detailRow('Note', text),
    ], title: 'REFUND INFORMATION');
  }

  Widget _supportCard(_PaymentActivity activity) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1B20), Color(0xFF141518)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('PAYMENT SUPPORT'),
          const SizedBox(height: 8),
          Text(
            'Need help with this transaction? Share your Transaction ID with our support team.',
            style: TiermetryTypography.bodySmall(
              color: TiermetryColors.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await Clipboard.setData(
                      ClipboardData(text: activity.orderId ?? activity.id),
                    );
                    if (!mounted) return;
                    AppIslandNotice.show(
                      context,
                      title: 'Reference copied',
                      tone: AppIslandNoticeTone.success,
                    );
                  },
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: TiermetryColors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Copy Reference',
                      style: TiermetryTypography.label(
                        color: TiermetryColors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    final navigator = Navigator.of(
                      context,
                      rootNavigator: true,
                    );
                    Navigator.pop(context);
                    navigator.push(
                      MaterialPageRoute<void>(
                        builder:
                            (_) => HelpAndSupportScreen(
                              contextBookingId:
                                  activity.isRefund || activity.isCredit
                                      ? activity.relatedId
                                      : null,
                              contextOrderId: activity.orderId,
                            ),
                      ),
                    );
                  },
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: TiermetryColors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Contact Support',
                      style: TiermetryTypography.label(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailCard(List<Widget> rows, {String? title}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF191A20), Color(0xFF131417)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            _sectionTitle(title),
            const SizedBox(height: 12),
          ],
          ...rows,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TiermetryTypography.bodySmall(
                color: TiermetryColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TiermetryTypography.bodySmall(
                color: TiermetryColors.white,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String label) {
    return Text(
      label.toUpperCase(),
      style: TiermetryTypography.label(
        color: TiermetryColors.white,
        letterSpacing: 1.1,
      ),
    );
  }

  String _relativeTime(DateTime timestamp) {
    final elapsed = DateTime.now().difference(timestamp);
    if (elapsed.inMinutes < 1) return 'Just now';
    if (elapsed.inHours < 1) return '${elapsed.inMinutes} min ago';
    if (elapsed.inDays < 1) return '${elapsed.inHours} h ago';
    if (elapsed.inDays < 7) return '${elapsed.inDays} d ago';
    return DateFormat('d MMM').format(timestamp);
  }

  @override
  void dispose() {
    _paymentChannel?.unsubscribe();
    _creditChannel?.unsubscribe();
    _refundChannel?.unsubscribe();
    super.dispose();
  }
}

class _PaymentActivity {
  final String id;
  final double amount;
  final DateTime createdAt;
  final String? relatedId;
  final String? orderId;
  final String? method;
  final PaymentStatus? paymentStatus;
  final _CreditEntry? credit;
  final _RefundEntry? refund;

  const _PaymentActivity._({
    required this.id,
    required this.amount,
    required this.createdAt,
    this.relatedId,
    this.orderId,
    this.method,
    this.paymentStatus,
    this.credit,
    this.refund,
  });

  factory _PaymentActivity.payment(PaymentEntity payment) {
    return _PaymentActivity._(
      id: payment.id,
      amount: payment.amount,
      createdAt: payment.createdAt,
      relatedId: payment.bookingId ?? payment.holdId,
      orderId: payment.orderId,
      method: payment.method,
      paymentStatus: payment.status,
    );
  }

  factory _PaymentActivity.credit(_CreditEntry credit) {
    return _PaymentActivity._(
      id: credit.id,
      amount: credit.amount,
      createdAt: credit.createdAt,
      relatedId: credit.bookingId,
      credit: credit,
    );
  }

  factory _PaymentActivity.refund(_RefundEntry refund) {
    return _PaymentActivity._(
      id: refund.id,
      amount: refund.amount,
      createdAt: refund.createdAt,
      relatedId: refund.bookingId,
      method: refund.provider,
      refund: refund,
    );
  }

  bool get isCredit => credit != null;
  bool get isRefund => refund != null;
  bool get isRefundLike => isCredit || isRefund;

  String get feedTitle =>
      isRefund
          ? 'Refund from $counterparty'
          : isCredit
          ? 'Received from $counterparty'
          : 'Sent to $counterparty';

  String get counterparty {
    final reference = relatedId;
    if (reference == null || reference.isEmpty) {
      return isRefundLike ? 'HOMIES' : 'payment provider';
    }
    if (reference.length <= 12) return reference;
    return '${reference.substring(0, 6)}…${reference.substring(reference.length - 4)}';
  }

  String get typeLabel =>
      isRefund
          ? 'Payment refund'
          : isCredit
          ? 'Wallet credit'
          : 'Payment';

  String get statusLabel {
    if (isCredit) return 'Credited';
    if (isRefund) {
      return switch (refund!.status) {
        'success' => 'Refunded',
        'failed' || 'cancelled' => 'Failed',
        'not_required' => 'Not applicable',
        _ => 'Pending',
      };
    }
    return switch (paymentStatus) {
      PaymentStatus.created => 'Initiated',
      PaymentStatus.pending => 'Pending',
      PaymentStatus.paid => 'Successful',
      PaymentStatus.failed => 'Failed',
      PaymentStatus.cancelled => 'Cancelled',
      null => 'Pending',
    };
  }

  String get methodLabel =>
      method?.toUpperCase() ?? (isCredit ? 'Wallet' : 'Provider');

  String get amountLabel {
    final prefix = isRefundLike ? '+₹' : '₹';
    return '$prefix${amount.toStringAsFixed(2)}';
  }

  Color get color {
    if (isCredit || refund?.status == 'success') {
      return TiermetryColors.positive;
    }
    if (isRefund) {
      return const {'failed', 'cancelled'}.contains(refund!.status)
          ? TiermetryColors.negative
          : TiermetryColors.accentAppleBlue;
    }
    return switch (paymentStatus) {
      PaymentStatus.paid => TiermetryColors.positive,
      PaymentStatus.failed => TiermetryColors.negative,
      PaymentStatus.cancelled => Colors.amber,
      PaymentStatus.pending ||
      PaymentStatus.created ||
      null => TiermetryColors.accentAppleBlue,
    };
  }

  Widget directionIcon({required Color color}) =>
      isRefundLike
          ? AmazingIconBulk.arrowDown(size: 25, color: color)
          : AmazingIconBulk.arrowUp(size: 25, color: color);
}

class _CreditEntry {
  final String id;
  final double amount;
  final String reason;
  final String? bookingId;
  final DateTime createdAt;

  const _CreditEntry({
    required this.id,
    required this.amount,
    required this.reason,
    required this.createdAt,
    this.bookingId,
  });
}

class _RefundEntry {
  const _RefundEntry({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.status,
    required this.provider,
    required this.createdAt,
    this.reference,
    this.statusDescription,
  });

  factory _RefundEntry.fromJson(Map<String, dynamic> json) {
    return _RefundEntry(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      amount: (json['requested_amount'] as num? ?? 0).toDouble(),
      status: json['status'] as String? ?? 'pending',
      provider: json['provider'] as String? ?? 'provider',
      reference:
          json['refund_arn'] as String? ??
          json['provider_reference'] as String?,
      statusDescription:
          json['failure_message'] as String? ??
          json['status_description'] as String?,
      createdAt: DateTime.parse(json['requested_at'] as String).toLocal(),
    );
  }

  final String id;
  final String bookingId;
  final double amount;
  final String status;
  final String provider;
  final String? reference;
  final String? statusDescription;
  final DateTime createdAt;
}
