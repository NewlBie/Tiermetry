enum BookingStatus {
  pending,
  confirmed,
  checkedIn,
  active,
  cancelled,
  completed,
  expired,
  noShow,
}

enum BookingPaymentState {
  unknown,
  unpaid,
  pending,
  paid,
  failed,
  cancelled,
  refunded,
  partiallyRefunded,
}

class BookingSessionEntity {
  final String id;
  final String status;
  final String? serviceUnitId;
  final DateTime scheduledStartAt;
  final DateTime scheduledEndAt;
  final DateTime? checkedInAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? checkInMethod;

  const BookingSessionEntity({
    required this.id,
    required this.status,
    required this.scheduledStartAt,
    required this.scheduledEndAt,
    this.serviceUnitId,
    this.checkedInAt,
    this.startedAt,
    this.endedAt,
    this.checkInMethod,
  });

  Duration get scheduledDuration => scheduledEndAt.difference(scheduledStartAt);
  Duration? get actualDuration =>
      startedAt != null && endedAt != null
          ? endedAt!.difference(startedAt!)
          : null;
}

class BookingEventEntity {
  final String id;
  final String eventType;
  final String actorType;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const BookingEventEntity({
    required this.id,
    required this.eventType,
    required this.actorType,
    required this.metadata,
    required this.createdAt,
  });
}

class BookingPaymentEntity {
  final String id;
  final double amount;
  final String status;
  final String? method;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BookingPaymentEntity({
    required this.id,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.method,
  });
}

class BookingItemEntity {
  final String id;
  final String serviceUnitId;
  final String serviceUnitName;
  final double priceAtBooking;

  const BookingItemEntity({
    required this.id,
    required this.serviceUnitId,
    required this.serviceUnitName,
    required this.priceAtBooking,
  });
}

class BookingEntity {
  final String id;
  final String title;
  final String location;
  final DateTime dateTime;
  final DateTime endTime;
  final String imageUrl;
  final BookingStatus status;
  final double totalAmount;
  final String? checkInCode;
  final String?
  sessionStatus; // 'not_started', 'checked_in', 'active', 'ended', 'force_ended'
  final String? bookingCode;
  final String? cancelReason;
  final String source;
  final List<BookingSessionEntity> sessions;
  final List<BookingEventEntity> events;
  final List<BookingPaymentEntity> payments;
  final List<BookingItemEntity> items;
  final double refundAmount;
  final double refundPercentage;
  final double paidAmount;
  final double outstandingAmount;
  final BookingPaymentState paymentState;

  BookingEntity({
    required this.id,
    required this.title,
    required this.location,
    required this.dateTime,
    required this.endTime,
    required this.imageUrl,
    required this.status,
    required this.totalAmount,
    this.checkInCode,
    this.sessionStatus,
    this.bookingCode,
    this.cancelReason,
    this.source = 'online',
    this.sessions = const [],
    this.events = const [],
    this.payments = const [],
    this.items = const [],
    this.refundAmount = 0,
    this.refundPercentage = 0,
    this.paidAmount = 0,
    this.outstandingAmount = 0,
    this.paymentState = BookingPaymentState.unknown,
  });

  bool get isUpcoming =>
      dateTime.isAfter(DateTime.now()) &&
      (status == BookingStatus.confirmed ||
          status == BookingStatus.pending ||
          status == BookingStatus.checkedIn);

  BookingSessionEntity? get primarySession =>
      sessions.isEmpty ? null : sessions.first;
  String? get assignedAssetName =>
      items.isEmpty ? null : items.first.serviceUnitName;

  DateTime get effectiveEndTime => primarySession?.scheduledEndAt ?? endTime;

  Duration get scheduledDuration => effectiveEndTime.difference(dateTime);

  Duration? get actualUsageDuration => primarySession?.actualDuration;

  double get scheduledHours => scheduledDuration.inMinutes / 60;

  double get actualUsageHours =>
      (actualUsageDuration ?? scheduledDuration).inMinutes / 60;
}
