import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tiermetry/core/mixins/refresh_rate_mixin.dart';
import 'package:tiermetry/core/theme/blurs.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_surface.dart';

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
            initialCameraPosition: CameraPosition(
              target: _arenaLocation,
              zoom: 17.5,
              tilt: 58.0, // Strong 3D buildings
              bearing: 28.0,
            ),
            markers: {
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

          // Subtle top vignette for depth
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 140,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.transparent,
                    ],
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
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),

                    // Recenter button
                    _GlassButton(
                      onTap: _recenterMap,
                      child: const Icon(
                        Icons.my_location_rounded,
                        color: Colors.white,
                        size: 20,
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
                child: AppSurface(
                  borderRadius: 0,
                  color: Colors.transparent,
                  border: Border.all(color: Colors.transparent),
                  shadows: const [],
                  clipBehavior: Clip.antiAlias,
                  child: BackdropFilter(
                    filter: TiermetryBlur.filter(TiermetryBlur.md),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
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
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Name + verified
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text((widget.arena.name).toUpperCase(),
                                        style: TiermetryTypography.title(
                                          fontSize: 22,
                                          color: Colors.white,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                    ),
                                    if (widget.arena.isVerified) ...[
                                      const SizedBox(width: 10),
                                      SvgPicture.asset(
                                        'assets/verified.svg',
                                        height: 22,
                                        width: 22,
                                        colorFilter: const ColorFilter.mode(
                                          Colors.white,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),

                                const SizedBox(height: 10),

                                // Location row
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_rounded,
                                      size: 17,
                                      color: TiermetryColors.positive,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        widget.arena.shortAddress,
                                        style: TiermetryTypography.bodySmall(
                                          fontSize: 14,
                                          color: Colors.white.withValues(
                                            alpha: 0.72,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                // Book button
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // TODO: navigate to booking
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: TiermetryColors.positive,
                                      foregroundColor: Colors.black,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      'Book Arena',
                                      style: TiermetryTypography.action(
                                        fontSize: 17,
                                        color: Colors.black,
                                      ),
                                    ),
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
    "stylers": [{"color": "#0f1419"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#8b9cb3"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#0f1419"}]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#c5d0de"}]
  },
  {
    "featureType": "poi",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [{"color": "#1a2a22"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#1c2530"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#0f1419"}]
  },
  {
    "featureType": "road",
    "elementType": "labels",
    "stylers": [{"visibility": "simplified"}]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#6b7c93"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#2a3544"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#0f1419"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "transit",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#0a1628"}]
  },
  {
    "featureType": "water",
    "elementType": "labels",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "landscape",
    "elementType": "geometry",
    "stylers": [{"color": "#121820"}]
  },
  {
    "featureType": "landscape.man_made",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#151c26"}]
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
