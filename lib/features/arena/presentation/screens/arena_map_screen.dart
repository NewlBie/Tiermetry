import 'dart:ui';

import 'package:amazing_icons/bulk.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tiermetry/core/mixins/refresh_rate_mixin.dart';
import 'package:tiermetry/core/theme/typography.dart';

import '../../domain/entities/arena_entity.dart';

class ArenaMapScreen extends StatefulWidget {
  final ArenaEntity arena;

  const ArenaMapScreen({required this.arena, super.key});

  @override
  State<ArenaMapScreen> createState() => _ArenaMapScreenState();
}

class _ArenaMapScreenState extends State<ArenaMapScreen>
    with SingleTickerProviderStateMixin, RefreshRateMixin {
  late final LatLng _arenaLocation;
  GoogleMapController? _mapController;

  late AnimationController _animationController;
  late Animation<double> _bottomSheetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _arenaLocation = LatLng(widget.arena.latitude, widget.arena.longitude);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _bottomSheetAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.15, 1.0, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _recenterMap() {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _arenaLocation,
          zoom: 17.5,
          tilt: 58.0,
          bearing: 28.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ─────────────────────────────────────
          // MAP
          // ─────────────────────────────────────
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: _arenaLocation,
              zoom: 17.5,
              tilt: 58.0, // Strong 3D buildings
              bearing: 28.0,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('user'),
                position: LatLng(_arenaLocation.latitude - 0.003, _arenaLocation.longitude - 0.003),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                zIndexInt: 5,
              ),
              Marker(
                markerId: const MarkerId('arena'),
                position: _arenaLocation,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueCyan, // Clean modern cyan
                ),
                // Optional: make it slightly larger feel
                zIndexInt: 10,
              ),
            },
            polylines: {
              Polyline(
                polylineId: const PolylineId('route'),
                color: const Color(0xFFEB441A),
                width: 2, // Sleek, elegant line
                points: [
                  LatLng(_arenaLocation.latitude - 0.003, _arenaLocation.longitude - 0.003),
                  LatLng(_arenaLocation.latitude - 0.003, _arenaLocation.longitude - 0.002),
                  LatLng(_arenaLocation.latitude - 0.001, _arenaLocation.longitude - 0.002),
                  LatLng(_arenaLocation.latitude - 0.001, _arenaLocation.longitude),
                  _arenaLocation,
                ],
              ),
            },
            style: _modernDarkMapStyle,
            buildingsEnabled: true,
            indoorViewEnabled: false,
            trafficEnabled: false,
            myLocationButtonEnabled: false,
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),

          // Artistic Vignette Overlay (fades edges to map background color)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2, // Expanded radius to push darkness to the edges
                    colors: [
                      Colors.transparent,
                      const Color(0xFF080808).withValues(alpha: 0.3),
                      const Color(0xFF080808).withValues(alpha: 0.8),
                      const Color(0xFF080808),
                    ],
                    stops: const [0.6, 0.85, 0.95, 1.0], // Pushed stops outward
                  ),
                ),
              ),
            ),
          ),

          // ─────────────────────────────────────
          // TOP CONTROLS
          // ─────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button
                    _GlassButton(
                      onTap: () => Navigator.pop(context),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 2.0),
                        child: AmazingIconBulk.arrowLeft2(
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),

                    // Recenter button
                    _GlassButton(
                      onTap: _recenterMap,
                      child: AmazingIconBulk.location(
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─────────────────────────────────────
          // BOTTOM SHEET
          // ─────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ScaleTransition(
              scale: _bottomSheetAnimation,
              alignment: Alignment.bottomCenter,
              child: FadeTransition(
                opacity: _bottomSheetAnimation,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFEB441A),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Drag handle
                        const SizedBox(height: 12),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Title
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.center,
                                child: Text(
                                  widget.arena.name.toUpperCase(),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  style: TiermetryTypography.displayLarge(
                                    fontSize: 42,
                                    color: Colors.white,
                                    letterSpacing: -1.0,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Bottom Row: Temperature & Distance
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Temperature
                                    Row(
                                      children: [
                                        AmazingIconBulk.cloudSunny(
                                          color: Colors.white,
                                          size: 44,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '24°C', // Fake temp
                                          style: TiermetryTypography.title(
                                            color: Colors.white,
                                            fontSize: 32,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 48),
                                    // Distance
                                    Row(
                                      children: [
                                        AmazingIconBulk.location(
                                          color: Colors.white,
                                          size: 44,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '${widget.arena.distance} km',
                                          style: TiermetryTypography.title(
                                            color: Colors.white,
                                            fontSize: 32,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
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

  // ─────────────────────────────────────
  // Modern Dark Map Style (Clean + Cinematic)
  // ─────────────────────────────────────
  static const String _modernDarkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#080705"}] // Deep darkened surface
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#f9f1e6"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#080705"}] // Match surface
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "poi",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#8c8a83"}] // ~50% white, warm tinted
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#080705"}] // Match surface
  },
  {
    "featureType": "landscape.man_made",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#2c2a21"}] // Buildings slightly dialed down so contrast isn't insane
  },
  {
    "featureType": "landscape.man_made",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#3b382d"}]
  },
  {
    "featureType": "landscape.natural",
    "elementType": "geometry",
    "stylers": [{"color": "#0a0907"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#18435E"}]
  }
]
''';
}

// ─────────────────────────────────────
// Reusable glass button
// ─────────────────────────────────────
class _GlassButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _GlassButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
