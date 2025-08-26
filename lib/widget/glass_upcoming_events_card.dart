import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/event.dart';

class GlassUpcomingEventsCard extends StatelessWidget {
  final Event event;

  const GlassUpcomingEventsCard({required this.event, super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        height: 200,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white.withAlpha(12), Colors.white.withAlpha(5)], // Replaced withOpacity with withAlpha
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withAlpha(20)), // Replaced withOpacity with withAlpha
        ),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              bottom: 0,
              top: 0,
              child: Opacity(
                opacity: 0.15,
                child: Image.asset(event.image, width: 120, fit: BoxFit.cover),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: Colors.deepOrangeAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.deepOrangeAccent.withAlpha(153), blurRadius: 6, spreadRadius: 1) // Replaced withOpacity with withAlpha
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text("Live Soon", style: GoogleFonts.urbanist(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white.withAlpha(178))), // Replaced withOpacity with withAlpha
                  ],
                ),
                const SizedBox(height: 10),
                Text(event.title, style: GoogleFonts.urbanist(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 12, color: Colors.white54),
                    const SizedBox(width: 5),
                    Text(event.date, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(width: 10),
                    const Icon(Icons.access_time, size: 12, color: Colors.white54),
                    const SizedBox(width: 5),
                    Text(event.time, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 12, color: Colors.white54),
                    const SizedBox(width: 5),
                    Text(event.location, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    backgroundColor: Colors.white.withAlpha(20), // Replaced withOpacity with withAlpha
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("Notify Me", style: GoogleFonts.urbanist(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
