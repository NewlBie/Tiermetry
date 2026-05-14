import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:tiermetry/core/theme/colors.dart';

import '../../domain/entities/arena_entity.dart';

class ArenaMapScreen extends StatefulWidget {
  final ArenaEntity arena;

  const ArenaMapScreen({super.key, required this.arena});

  @override
  State<ArenaMapScreen> createState() => _ArenaMapScreenState();
}

class _ArenaMapScreenState extends State<ArenaMapScreen>
    with SingleTickerProviderStateMixin {
  late final LatLng _arenaLocation;

  late AnimationController _animationController;
  late Animation<double> _bottomSheetAnimation;

  @override
  void initState() {
    super.initState();
    _arenaLocation = LatLng(widget.arena.latitude, widget.arena.longitude);
    _animationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _bottomSheetAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TiermetryColors.background,
      body: Stack(
        children: [
          // Google map with 3D Perspective
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _arenaLocation,
              zoom: 18.0, // Closer zoom for better 3D building visibility
              tilt: 50.0,  // 3D tilt
              bearing: 30.0, // Slight rotation for depth
            ),
            markers: {
              Marker(
                markerId: const MarkerId('arena'),
                position: _arenaLocation,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure,
                ),
              ),
            },
            style: _darkMapStyle,
            buildingsEnabled: true,
            onMapCreated: (controller) {
              // Not using controller yet
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // Back button
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 10,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ),

          // Arena info panel (glassmorphism)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ScaleTransition(
              scale: _bottomSheetAnimation,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(32)),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Arena name + verified
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.arena.name,
                                style: GoogleFonts.urbanist(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            if (widget.arena.isVerified)
                            SvgPicture.asset(
                              'assets/verified.svg',
                              height: 20,
                              width: 20,
                              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Location
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                size: 18, color: Colors.greenAccent),
                            const SizedBox(width: 6),
                            Text(
                              widget.arena.shortAddress,
                              style: GoogleFonts.urbanist(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Book now button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              "Book Arena",
                              style: GoogleFonts.urbanist(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  final String _darkMapStyle = '''
  [
    {"elementType": "geometry","stylers": [{"color": "#1d2c4d"}]},
    {"elementType": "labels.text.fill","stylers": [{"color": "#8ec3b9"}]},
    {"elementType": "labels.text.stroke","stylers": [{"color": "#1a3646"}]},
    {"featureType": "poi","stylers": [{"visibility": "off"}]},
    {"featureType": "road","stylers": [{"color": "#304a7d"}]},
    {"featureType": "water","stylers": [{"color": "#0e1626"}]}
  ]
  ''';
}

