import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Entities
import '../../domain/entities/booking_entity.dart';
import 'package:tiermetry/core/locator.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _bookingCtrl = locator.bookingCtrl;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _bookingCtrl.loadBookings());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120.0,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    'My Bookings',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: ListenableBuilder(
              listenable: _bookingCtrl,
              builder: (context, child) {
                if (_bookingCtrl.isLoading) {
                  return const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (_bookingCtrl.bookings.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Text(
                        "No bookings found.",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final booking = _bookingCtrl.bookings[index];
                    return _buildBookingItem(context, booking);
                  }, childCount: _bookingCtrl.bookings.length),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingItem(BuildContext context, BookingEntity booking) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          Image.network(
            booking.imageUrl,
            fit: BoxFit.cover,
            height: 180,
            width: double.infinity,
            errorBuilder:
                (context, error, stackTrace) => const Icon(Icons.error),
          ),
          Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.title,
                  style: GoogleFonts.bricolageGrotesque(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      booking.location,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
