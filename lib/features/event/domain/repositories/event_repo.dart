import '../entities/event_entity.dart';

abstract class EventRepo {
  Future<List<EventEntity>> getEvents({
    String? query,
    String? category,
    int page = 0,
    int pageSize = 20,
  });
  Future<List<EventEntity>> getMyRegistrations();
  Future<String> registerForEvent(EventRegistrationRequest request);
  Future<bool> isRegistered(String eventId);
  Future<void> checkInEventRegistration({
    required String registrationId,
    required String code,
  });
}

class EventRegistrationRequest {
  final String eventId;
  final String registrationKind;
  final String? attendeeName;
  final String? attendeeEmail;
  final String? attendeePhone;
  final String? teamName;
  final List<String> participants;
  final bool rulesAccepted;
  final String paymentMethod;
  final String paymentStatus;
  final String amountLabel;

  const EventRegistrationRequest({
    required this.eventId,
    required this.registrationKind,
    required this.rulesAccepted,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.amountLabel,
    this.attendeeName,
    this.attendeeEmail,
    this.attendeePhone,
    this.teamName,
    this.participants = const [],
  });
}
