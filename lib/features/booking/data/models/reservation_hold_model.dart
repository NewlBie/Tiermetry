import '../../domain/entities/booking_accessory.dart';
import '../../domain/entities/reservation_hold_entity.dart';

class ReservationHoldModel extends ReservationHoldEntity {
  ReservationHoldModel({
    required super.id,
    required super.userId,
    required super.venueId,
    required super.startTime,
    required super.endTime,
    required super.totalAmount,
    required super.status,
    required super.expiresAt,
    super.convertedBookingId,
    super.paymentOrderId,
    super.paymentStatus,
    super.venueName,
    super.serviceUnitNames,
    super.accessories,
  });

  factory ReservationHoldModel.fromJson(Map<String, dynamic> json) {
    final venue = json['venues'] as Map<String, dynamic>? ?? const {};
    final rawItems = json['reservation_hold_items'];
    final unitNames =
        rawItems is List
            ? rawItems.whereType<Map<String, dynamic>>().map((item) {
              final unit =
                  item['service_units'] as Map<String, dynamic>? ?? const {};
              return unit['name'] as String? ?? 'Assigned station';
            }).toList()
            : <String>[];
    final rawAccessories = json['reservation_hold_accessories'];
    final rawPayments = json['payments'];
    final openPayment =
        rawPayments is List
            ? rawPayments.whereType<Map<String, dynamic>>().firstWhere(
              (payment) =>
                  payment['status'] == 'created' ||
                  payment['status'] == 'pending',
              orElse: () => const <String, dynamic>{},
            )
            : const <String, dynamic>{};
    final accessories =
        rawAccessories is List
            ? rawAccessories.whereType<Map<String, dynamic>>().map((item) {
              final unit =
                  item['service_units'] as Map<String, dynamic>? ?? const {};
              return BookingAccessoryLine(
                serviceUnitId: item['service_unit_id'] as String? ?? '',
                serviceUnitName: unit['name'] as String? ?? 'Booked asset',
                name: item['name_at_hold'] as String? ?? 'Accessory',
                quantity: (item['quantity'] as num? ?? 0).toInt(),
                includedQuantity:
                    (item['included_quantity'] as num? ?? 0).toInt(),
                billingType: item['billing_type'] as String? ?? 'fixed',
                billingIntervalMinutes:
                    (item['billing_interval_minutes'] as num? ?? 60).toInt(),
                unitPrice: (item['unit_price'] as num? ?? 0).toDouble(),
                amount: (item['amount'] as num? ?? 0).toDouble(),
              );
            }).toList()
            : <BookingAccessoryLine>[];
    return ReservationHoldModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      venueId: json['venue_id'] as String,
      startTime: DateTime.parse(json['start_time'] as String).toLocal(),
      endTime: DateTime.parse(json['end_time'] as String).toLocal(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: ReservationHoldStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String),
        orElse: () => ReservationHoldStatus.active,
      ),
      expiresAt: DateTime.parse(json['expires_at'] as String).toLocal(),
      convertedBookingId: json['converted_booking_id'] as String?,
      paymentOrderId: openPayment['order_id'] as String?,
      paymentStatus: openPayment['status'] as String?,
      venueName: venue['name'] as String? ?? 'Arena',
      serviceUnitNames: unitNames,
      accessories: accessories,
    );
  }
}

class ReservationHoldStatusSnapshotModel extends ReservationHoldStatusSnapshot {
  const ReservationHoldStatusSnapshotModel({
    required super.holdId,
    required super.status,
    required super.expiresAt,
    required super.serverNow,
    required super.remainingSeconds,
    required super.warningSeconds,
    required super.paymentMinRemainingSeconds,
    super.convertedBookingId,
    super.paymentOrderId,
    super.paymentStatus,
    super.paymentOrderExpiresAt,
    super.paymentReconcileUntil,
  });

  factory ReservationHoldStatusSnapshotModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ReservationHoldStatusSnapshotModel(
      holdId: json['hold_id'] as String,
      status: ReservationHoldStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => ReservationHoldStatus.expired,
      ),
      expiresAt: DateTime.parse(json['expires_at'] as String).toLocal(),
      serverNow: DateTime.parse(json['server_now'] as String).toLocal(),
      remainingSeconds: (json['remaining_seconds'] as num).toInt(),
      warningSeconds: (json['warning_seconds'] as num).toInt(),
      paymentMinRemainingSeconds:
          (json['payment_min_remaining_seconds'] as num).toInt(),
      convertedBookingId: json['converted_booking_id'] as String?,
      paymentOrderId: json['payment_order_id'] as String?,
      paymentStatus: json['payment_status'] as String?,
      paymentOrderExpiresAt:
          json['payment_order_expires_at'] == null
              ? null
              : DateTime.parse(
                json['payment_order_expires_at'] as String,
              ).toLocal(),
      paymentReconcileUntil:
          json['payment_reconcile_until'] == null
              ? null
              : DateTime.parse(
                json['payment_reconcile_until'] as String,
              ).toLocal(),
    );
  }
}
