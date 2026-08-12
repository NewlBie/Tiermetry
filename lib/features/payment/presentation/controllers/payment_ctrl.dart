import 'package:flutter/foundation.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/repositories/payment_provider.dart';
import '../../domain/repositories/payment_repo.dart';

class PaymentCtrl extends ChangeNotifier {
  final PaymentRepo repo;
  final PaymentProvider provider;

  PaymentCtrl({required this.repo, required this.provider});

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  PaymentEntity? _currentPayment;
  PaymentEntity? get currentPayment => _currentPayment;

  Future<void> startPaymentFlow({
    required String holdId,
  }) async {
    _isProcessing = true;
    notifyListeners();

    try {
      // 1. Create order
      final order = await repo.initiatePayment(
        holdId: holdId,
      );

      // 2. Open provider workflow (mock UI in dev)
      await provider.openPaymentWorkflow(order);
      
      // In dev mode, we might need a manual trigger or polling.
      // For now, let's assume the UI will call verify.
    } catch (e) {
      debugPrint('Payment initiation failed: $e');
      rethrow;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<PaymentEntity> verifyPayment(String orderId) async {
    _isProcessing = true;
    notifyListeners();

    try {
      final payment = await repo.verifyAndSyncPayment(orderId);
      _currentPayment = payment;
      return payment;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
}
