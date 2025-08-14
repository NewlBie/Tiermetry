import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class ArenaMapPage extends StatefulWidget {
  const ArenaMapPage({super.key});

  @override
  State<ArenaMapPage> createState() => _ArenaMapPageState();
}

class _ArenaMapPageState extends State<ArenaMapPage> {
  late GoogleMapController _mapController;
  final LatLng _arenaLocation = const LatLng(20.2961, 85.8245); // Replace with your arena location
  BitmapDescriptor? _customPin;

  @override
  void initState() {
    super.initState();
    _loadMarker();
  }

  Future<void> _loadMarker() async {
    _customPin = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/arena_pin.png',
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1015),
      body: Stack(
        children: [
          // 🗺 Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _arenaLocation,
              zoom: 16.5,
            ),
            markers: _customPin == null
                ? {}
                : {
              Marker(
                markerId: const MarkerId('arena'),
                position: _arenaLocation,
                icon: _customPin!,
              ),
            },
            onMapCreated: (controller) {
              _mapController = controller;
              _mapController.setMapStyle(_darkMapStyle); // Apple/Uber style
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // 🔙 Back Button
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ),

          // 📦 Arena Info Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: const BoxDecoration(
                color: Color(0xFF0D1015),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🏷 Arena name + verified
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Timezone Esplanade",
                          style: GoogleFonts.urbanist(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SvgPicture.asset(
                        'assets/verified.svg',
                        height: 18,
                        width: 18,
                        color: Colors.white,
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // 📍 Location
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 16, color: Colors.greenAccent),
                      const SizedBox(width: 6),
                      Text(
                        "Shaheed Nagar, Bhubaneswar",
                        style: GoogleFonts.urbanist(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // 🟩 Book Now button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        "Book Arena",
                        style: GoogleFonts.urbanist(
                          fontSize: 16,
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
        ],
      ),
    );
  }

  final String _darkMapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [{"color": "#1d2c4d"}]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#8ec3b9"}]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#1a3646"}]
    },
    {
      "featureType": "administrative.country",
      "elementType": "geometry.stroke",
      "stylers": [{"color": "#4b6878"}]
    },
    {
      "featureType": "poi",
      "stylers": [{"visibility": "off"}]
    },
    {
      "featureType": "road",
      "stylers": [{"color": "#304a7d"}]
    },
    {
      "featureType": "water",
      "stylers": [{"color": "#0e1626"}]
    }
  ]
  ''';
}
