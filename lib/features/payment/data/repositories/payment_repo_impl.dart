import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/entities/payment_order.dart';
import '../../domain/entities/payment_status.dart';
import '../../domain/repositories/payment_provider.dart';
import '../../domain/repositories/payment_repo.dart';
import '../models/payment_model.dart';

/// Default timeout for payment-related network calls.
const _kPaymentTimeout = Duration(seconds: 30);
const _customerPaymentColumns =
    'id, booking_id, hold_id, amount, status, method, created_at, updated_at';

class PaymentRepoImpl implements PaymentRepo {
  final SupabaseClient _supabase;
  final PaymentProvider _provider;

  PaymentRepoImpl(this._supabase, this._provider);

  @override
  Future<PaymentOrder> initiatePayment({
    required String holdId,
    String? method,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    if (_provider.name == 'cashfree') {
      // The Edge Function owns pricing, duplicate prevention, and persistence.
      // The app supplies only the authenticated user's hold identifier.
      final result = await _supabase.functions
          .invoke(
            'create-cashfree-order',
            body: {
              'hold_id': holdId,
              'method': method,
              'expected_environment': _provider.checkoutEnvironment,
            },
          )
          .timeout(_kPaymentTimeout);

      if (result.status != 200) {
        final error =
            result.data is Map
                ? (result.data as Map)['error'] as String?
                : null;
        throw Exception(
          error ?? 'Failed to create payment order (${result.status})',
        );
      }

      final data = result.data as Map<String, dynamic>;
      final expectedEnvironment = _provider.checkoutEnvironment;
      final returnedEnvironment = data['cashfree_environment'] as String?;
      if (expectedEnvironment == null ||
          returnedEnvironment != expectedEnvironment) {
        throw StateError(
          'Cashfree environment mismatch. The checkout was not opened.',
        );
      }
      return PaymentOrder(
        orderId: data['order_id'] as String,
        sessionId: data['payment_session_id'] as String?,
        amount: (data['amount'] as num).toDouble(),
      );
    }

    // Development payments use the same platform fee RPC, but do not leave
    // the device or participate in the production payment contract.
    final holdResponse = await _supabase
        .from('reservation_holds')
        .select('total_amount')
        .eq('id', holdId)
        .single()
        .timeout(_kPaymentTimeout);
    final totalPaise =
        ((holdResponse['total_amount'] as num).toDouble() * 100).round();
    final reservations = await _supabase
        .from('loyalty_reservations')
        .select('discount_paise')
        .eq('hold_id', holdId)
        .eq('status', 'active')
        .limit(1)
        .timeout(_kPaymentTimeout);
    final discountPaise =
        reservations.isEmpty
            ? 0
            : (reservations.first['discount_paise'] as num?)?.toInt() ?? 0;
    final promotionReservations = await _supabase
        .from('checkout_promotion_reservations')
        .select('discount_paise')
        .eq('hold_id', holdId)
        .eq('status', 'active')
        .limit(1)
        .timeout(_kPaymentTimeout);
    final promotionDiscountPaise =
        promotionReservations.isEmpty
            ? 0
            : (promotionReservations.first['discount_paise'] as num?)
                    ?.toInt() ??
                0;
    final basePaise = (totalPaise - discountPaise - promotionDiscountPaise)
        .clamp(0, totalPaise);
    final customerFeePaise = await _supabase
        .rpc<dynamic>(
          'platform_customer_fee_paise',
          params: {'p_base_paise': basePaise},
        )
        .timeout(_kPaymentTimeout);
    final authoritativeAmount =
        (basePaise + ((customerFeePaise as num?)?.toInt() ?? 0)) / 100.0;

    // 1. Prevent duplicate active payment attempts for the same hold.
    final activePayments = await _supabase
        .from('payments')
        .select('order_id, status')
        .eq('hold_id', holdId)
        .or('status.eq.created,status.eq.pending,status.eq.paid')
        .order('created_at', ascending: false)
        .limit(1)
        .timeout(_kPaymentTimeout);

    if (activePayments.isNotEmpty) {
      final payment = activePayments.first;
      final status = payment['status'] as String? ?? 'pending';
      if (status == 'paid') {
        throw Exception('This reservation has already been paid.');
      }
      throw Exception('A payment is already in progress for this reservation.');
    }

    final order = await _provider.createOrder(
      bookingId: holdId,
      amount: authoritativeAmount,
      userEmail: user.email ?? '',
      userPhone: user.phone ?? '',
    );

    await _supabase
        .from('payments')
        .insert({
          'hold_id': holdId,
          'order_id': order.orderId,
          'amount': authoritativeAmount,
          'status': 'created',
          'provider': _provider.name,
          'method': method,
        })
        .timeout(_kPaymentTimeout);

    return order;
  }

  @override
  Future<PaymentOrder?> getPendingCashfreeOrder(String orderId) async {
    final response = await _supabase
        .from('payments')
        .select('order_id, amount, status, raw_response')
        .eq('order_id', orderId)
        .inFilter('status', ['created', 'pending'])
        .maybeSingle()
        .timeout(_kPaymentTimeout);
    if (response == null) return null;
    final raw = Map<String, dynamic>.from(
      response['raw_response'] as Map? ?? const <String, dynamic>{},
    );
    final sessionId = raw['payment_session_id'] as String?;
    if (sessionId == null || sessionId.isEmpty) return null;
    return PaymentOrder(
      orderId: response['order_id'] as String,
      sessionId: sessionId,
      amount: (response['amount'] as num).toDouble(),
    );
  }

  @override
  Future<PaymentEntity> completeTiergiesCheckout(String holdId) async {
    final result = await _supabase.functions
        .invoke('complete-tiergies-checkout', body: {'hold_id': holdId})
        .timeout(_kPaymentTimeout);
    final data = Map<String, dynamic>.from(
      result.data as Map? ?? const <String, dynamic>{},
    );
    if (result.status < 200 || result.status >= 300) {
      throw Exception(
        data['error'] as String? ?? 'Unable to complete the Tiergies checkout.',
      );
    }

    final payment = Map<String, dynamic>.from(
      data['payment'] as Map? ?? const <String, dynamic>{},
    );
    return PaymentModel.fromJson(payment);
  }

  @override
  Future<PaymentEntity> verifyAndSyncPayment(String orderId) async {
    if (_provider.name == 'cashfree') {
      final result = await _supabase.functions
          .invoke('verify-cashfree-order', body: {'order_id': orderId})
          .timeout(_kPaymentTimeout);
      if (result.status != 200) {
        throw Exception(
          'Unable to verify the Cashfree payment (${result.status})',
        );
      }
    } else {
      final status = await _provider
          .verifyPayment(orderId)
          .timeout(_kPaymentTimeout);
      if (status == PaymentStatus.paid) {
        await _supabase
            .rpc<void>(
              'process_development_payment',
              params: {'p_order_id': orderId},
            )
            .timeout(_kPaymentTimeout);
      }
    }

    // 3. Fetch and return the updated payment entity.
    final response = await _supabase
        .from('payments')
        .select(_customerPaymentColumns)
        .eq('order_id', orderId)
        .single()
        .timeout(_kPaymentTimeout);

    return PaymentModel.fromJson(response);
  }

  @override
  Future<List<PaymentEntity>> getPaymentsForBooking(String bookingId) async {
    final response = await _supabase
        .from('payments')
        .select(_customerPaymentColumns)
        .eq('booking_id', bookingId)
        .order('created_at', ascending: false)
        .timeout(_kPaymentTimeout);

    return (response as List)
        .map((json) => PaymentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
