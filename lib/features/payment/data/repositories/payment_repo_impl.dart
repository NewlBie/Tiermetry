import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/entities/payment_order.dart';
import '../../domain/entities/payment_status.dart';
import '../../domain/repositories/payment_provider.dart';
import '../../domain/repositories/payment_repo.dart';
import '../models/payment_model.dart';

class PaymentRepoImpl implements PaymentRepo {
  final SupabaseClient _supabase;
  final PaymentProvider _provider;

  PaymentRepoImpl(this._supabase, this._provider);

  @override
  Future<PaymentOrder> initiatePayment({
    required String holdId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // 0. Fetch authoritative amount from hold
    final holdResponse = await _supabase
        .from('reservation_holds')
        .select('total_amount')
        .eq('id', holdId)
        .single();
    final authoritativeAmount = (holdResponse['total_amount'] as num).toDouble();

    // 1. Create order via provider
    final order = await _provider.createOrder(
      bookingId: holdId, // Provider still expects a 'bookingId' string, we pass holdId
      amount: authoritativeAmount,
      userEmail: user.email ?? '',
      userPhone: user.phone ?? '',
    );

    // 2. Persist order to Supabase
    await _supabase.from('payments').insert({
      'hold_id': holdId,
      'order_id': order.orderId,
      'amount': authoritativeAmount,
      'status': 'created',
      'provider': _provider.name,
    });

    return order;
  }

  @override
  Future<PaymentEntity> verifyAndSyncPayment(String orderId) async {
    // 1. Verify status with provider
    final status = await _provider.verifyPayment(orderId);

    // 2. If status is paid, trigger the Supabase process
    if (status == PaymentStatus.paid) {
      await _supabase.rpc<void>('process_successful_payment', params: {
        'p_order_id': orderId,
      });
    } else {
      // Just update the payment status locally
      await _supabase.from('payments').update({
        'status': status.name,
      }).eq('order_id', orderId);
    }

    // 3. Fetch and return updated payment entity
    final response = await _supabase
        .from('payments')
        .select()
        .eq('order_id', orderId)
        .single();
    
    return PaymentModel.fromJson(response);
  }

  @override
  Future<List<PaymentEntity>> getPaymentsForBooking(String bookingId) async {
    final response = await _supabase
        .from('payments')
        .select()
        .eq('booking_id', bookingId)
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => PaymentModel.fromJson(json as Map<String, dynamic>)).toList();
  }
}
