import '../../domain/entities/booking_entity.dart';

class BookingModel extends BookingEntity {
  final String userId;
  final String venueId;

  BookingModel({
    required super.id,
    required this.userId,
    required this.venueId,
    required super.status,
    required super.totalAmount,
    required super.title,
    required super.location,
    required super.dateTime,
    required super.endTime,
    required super.imageUrl,
    required super.source,
    required super.sessions,
    required super.events,
    required super.payments,
    required super.items,
    required super.refundAmount,
    required super.refundPercentage,
    required super.paidAmount,
    required super.outstandingAmount,
    required super.paymentState,
    super.checkInCode,
    super.sessionStatus,
    super.bookingCode,
    super.cancelReason,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final venue = json['venues'] as Map<String, dynamic>? ?? {};

    final statusStr = json['status'] as String? ?? 'pending';
    final status = _mapBookingStatus(statusStr);

    final sessions = _parseSessions(json['sessions']);
    final sessionStatus = sessions.isNotEmpty ? sessions.first.status : null;
    final events = _parseEvents(json['booking_events']);
    final payments = _parsePayments(json['payments']);
    final items = _parseItems(json['booking_items']);
    final cancellationEvent = events
        .where((e) => e.eventType == 'BOOKING_CANCELLED')
        .fold<BookingEventEntity?>(
          null,
          (latest, event) =>
              latest == null || event.createdAt.isAfter(latest.createdAt)
                  ? event
                  : latest,
        );
    final refundAmount = _readNumeric(
      cancellationEvent?.metadata['refund_amount'],
    );
    final refundPercentage = _readNumeric(
      cancellationEvent?.metadata['refund_percentage'],
    );
    final paidAmount = payments
        .where((payment) => payment.status == 'paid')
        .fold<double>(0, (sum, payment) => sum + payment.amount);
    final totalAmount = (json['total_amount'] as num? ?? 0.0).toDouble();
    final paymentState = _resolvePaymentState(
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      refundAmount: refundAmount,
      payments: payments,
      bookingStatus: status,
    );

    final startTime =
        json['start_time'] != null
            ? DateTime.parse(json['start_time'] as String).toLocal()
            : DateTime.now();
    final endTime =
        json['end_time'] != null
            ? DateTime.parse(json['end_time'] as String).toLocal()
            : startTime;

    return BookingModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      venueId: json['venue_id'] as String? ?? '',
      status: status,
      totalAmount: totalAmount,
      title: venue['name'] as String? ?? 'Booking',
      location: venue['short_address'] as String? ?? '',
      dateTime: startTime,
      endTime: endTime,
      imageUrl: venue['cover_image'] as String? ?? '',
      checkInCode: json['check_in_code'] as String?,
      sessionStatus: sessionStatus,
      bookingCode: json['booking_code'] as String?,
      cancelReason: json['cancel_reason'] as String?,
      source: json['source'] as String? ?? 'online',
      sessions: sessions,
      events: events,
      payments: payments,
      items: items,
      refundAmount: refundAmount,
      refundPercentage: refundPercentage,
      paidAmount: paidAmount,
      outstandingAmount:
          (totalAmount - paidAmount + refundAmount) < 0
              ? 0
              : (totalAmount - paidAmount + refundAmount),
      paymentState: paymentState,
    );
  }

  static BookingStatus _mapBookingStatus(String raw) {
    switch (raw) {
      case 'checked_in':
        return BookingStatus.checkedIn;
      case 'active':
        return BookingStatus.active;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'completed':
        return BookingStatus.completed;
      case 'expired':
        return BookingStatus.expired;
      case 'no_show':
        return BookingStatus.noShow;
      case 'confirmed':
      case 'awaiting_check_in':
        return BookingStatus.confirmed;
      case 'pending':
      default:
        return BookingStatus.pending;
    }
  }

  static List<BookingSessionEntity> _parseSessions(dynamic raw) {
    if (raw is! List) return const [];
    final sessions =
        raw
            .whereType<Map<String, dynamic>>()
            .map(
              (session) => BookingSessionEntity(
                id: session['id'] as String? ?? '',
                status: session['status'] as String? ?? 'not_started',
                serviceUnitId: session['service_unit_id'] as String?,
                scheduledStartAt:
                    DateTime.parse(
                      session['scheduled_start_at'] as String,
                    ).toLocal(),
                scheduledEndAt:
                    DateTime.parse(
                      session['scheduled_end_at'] as String,
                    ).toLocal(),
                checkedInAt: _parseDateTime(session['checked_in_at']),
                startedAt: _parseDateTime(session['started_at']),
                endedAt: _parseDateTime(session['ended_at']),
                checkInMethod: session['check_in_method'] as String?,
              ),
            )
            .toList();
    return sessions
      ..sort((a, b) => a.scheduledStartAt.compareTo(b.scheduledStartAt));
  }

  static List<BookingEventEntity> _parseEvents(dynamic raw) {
    if (raw is! List) return const [];
    final events =
        raw
            .whereType<Map<String, dynamic>>()
            .map(
              (event) => BookingEventEntity(
                id: event['id'] as String? ?? '',
                eventType: event['event_type'] as String? ?? 'UNKNOWN',
                actorType: event['actor_type'] as String? ?? 'system',
                metadata: Map<String, dynamic>.from(
                  event['metadata'] as Map? ?? const {},
                ),
                createdAt:
                    DateTime.parse(event['created_at'] as String).toLocal(),
              ),
            )
            .toList();
    return events..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static List<BookingPaymentEntity> _parsePayments(dynamic raw) {
    if (raw is! List) return const [];
    final payments =
        raw
            .whereType<Map<String, dynamic>>()
            .map(
              (payment) => BookingPaymentEntity(
                id: payment['id'] as String? ?? '',
                amount: (payment['amount'] as num? ?? 0).toDouble(),
                status: payment['status'] as String? ?? 'created',
                method: payment['method'] as String?,
                createdAt:
                    DateTime.parse(payment['created_at'] as String).toLocal(),
                updatedAt:
                    DateTime.parse(payment['updated_at'] as String).toLocal(),
              ),
            )
            .toList();
    return payments..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static List<BookingItemEntity> _parseItems(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().map((item) {
      final unit = item['service_units'] as Map<String, dynamic>? ?? const {};
      return BookingItemEntity(
        id: item['id'] as String? ?? '',
        serviceUnitId: item['service_unit_id'] as String? ?? '',
        serviceUnitName: unit['name'] as String? ?? 'Assigned station',
        priceAtBooking: (item['price_at_booking'] as num? ?? 0).toDouble(),
      );
    }).toList();
  }

  static BookingPaymentState _resolvePaymentState({
    required double totalAmount,
    required double paidAmount,
    required double refundAmount,
    required List<BookingPaymentEntity> payments,
    required BookingStatus bookingStatus,
  }) {
    final latestStatus = payments.isEmpty ? null : payments.first.status;
    if (refundAmount > 0) {
      return refundAmount >= paidAmount && paidAmount > 0
          ? BookingPaymentState.refunded
          : BookingPaymentState.partiallyRefunded;
    }
    switch (latestStatus) {
      case 'paid':
        return BookingPaymentState.paid;
      case 'pending':
      case 'created':
        return BookingPaymentState.pending;
      case 'failed':
        return BookingPaymentState.failed;
      case 'cancelled':
        return BookingPaymentState.cancelled;
    }
    if (paidAmount >= totalAmount && totalAmount > 0) {
      return BookingPaymentState.paid;
    }
    if (bookingStatus == BookingStatus.cancelled) {
      return BookingPaymentState.cancelled;
    }
    if (totalAmount <= 0) {
      return BookingPaymentState.unknown;
    }
    return paidAmount > 0
        ? BookingPaymentState.pending
        : BookingPaymentState.unpaid;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.parse(value).toLocal();
  }

  static double _readNumeric(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
