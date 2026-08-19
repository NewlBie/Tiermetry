import 'package:flutter_test/flutter_test.dart';
import 'package:tiermetry/features/booking/data/models/booking_model.dart';

void main() {
  test(
    'booking model exposes reassigned service-unit details and recovery event',
    () {
      final booking = BookingModel.fromJson({
        'id': 'booking-1',
        'user_id': 'user-1',
        'venue_id': 'venue-1',
        'status': 'confirmed',
        'total_amount': 600,
        'start_time': '2026-08-20T12:00:00Z',
        'end_time': '2026-08-20T14:00:00Z',
        'venues': {'name': 'Nexus', 'short_address': 'Test lane'},
        'booking_items': [
          {
            'id': 'item-1',
            'service_unit_id': 'replacement-12',
            'price_at_booking': 600,
            'service_units': {'id': 'replacement-12', 'name': 'PC #12'},
          },
        ],
        'sessions': const <dynamic>[],
        'payments': const <dynamic>[],
        'booking_events': [
          {
            'id': 'event-1',
            'event_type': 'BOOKING_ASSET_REASSIGNED',
            'actor_type': 'system',
            'metadata': {'replacement_asset_id': 'replacement-12'},
            'created_at': '2026-08-19T12:00:00Z',
          },
        ],
      });

      expect(booking.assignedAssetName, 'PC #12');
      expect(booking.events.single.eventType, 'BOOKING_ASSET_REASSIGNED');
    },
  );
}
