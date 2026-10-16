import 'booking_accessory.dart';

enum ReservationHoldStatus { active, released, expired, converted }

class ReservationHoldStatusSnapshot {
  final String holdId;
  final ReservationHoldStatus status;
  final DateTime expiresAt;
  final DateTime serverNow;
  final int remainingSeconds;
  final int warningSeconds;
  final int paymentMinRemainingSeconds;
  final String? convertedBookingId;
  final String? paymentOrderId;
  final String? paymentStatus;
  final DateTime? paymentOrderExpiresAt;
  final DateTime? paymentReconcileUntil;

  const ReservationHoldStatusSnapshot({
    required this.holdId,
    required this.status,
    required this.expiresAt,
    required this.serverNow,
    required this.remainingSeconds,
    required this.warningSeconds,
    required this.paymentMinRemainingSeconds,
    this.convertedBookingId,
    this.paymentOrderId,
    this.paymentStatus,
    this.paymentOrderExpiresAt,
    this.paymentReconcileUntil,
  });

  bool get isActive =>
      status == ReservationHoldStatus.active && remainingSeconds > 0;
  bool get isWarning => isActive && remainingSeconds <= warningSeconds;
  bool get canStartPayment =>
      isActive &&
      !isPaymentConfirmationPending &&
      remainingSeconds >= paymentMinRemainingSeconds;
  bool get isConverted =>
      status == ReservationHoldStatus.converted || convertedBookingId != null;
  bool get isPaymentConfirmationPending =>
      paymentOrderId != null &&
      (paymentStatus == 'created' || paymentStatus == 'pending');
  bool get needsReselection =>
      !isConverted &&
      !isPaymentConfirmationPending &&
      (status == ReservationHoldStatus.expired ||
          status == ReservationHoldStatus.released);
  bool get shouldAutoRelease =>
      status == ReservationHoldStatus.active &&
      remainingSeconds <= 0 &&
      !isPaymentConfirmationPending;
}

class ReservationHoldEntity {
  final String id;
  final String userId;
  final String venueId;
  final DateTime startTime;
  final DateTime endTime;
  final double totalAmount;
  final ReservationHoldStatus status;
  final DateTime expiresAt;
  final String? convertedBookingId;
  final String? paymentOrderId;
  final String? paymentStatus;
  final String venueName;
  final List<String> serviceUnitNames;
  final List<BookingAccessoryLine> accessories;

  ReservationHoldEntity({
    required this.id,
    required this.userId,
    required this.venueId,
    required this.startTime,
    required this.endTime,
    required this.totalAmount,
    required this.status,
    required this.expiresAt,
    this.convertedBookingId,
    this.paymentOrderId,
    this.paymentStatus,
    this.venueName = 'Arena',
    this.serviceUnitNames = const [],
    this.accessories = const [],
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  Duration get remainingTime => expiresAt.difference(DateTime.now());
  bool get isPaymentConfirmationPending =>
      paymentOrderId != null &&
      (paymentStatus == 'created' || paymentStatus == 'pending');
}
