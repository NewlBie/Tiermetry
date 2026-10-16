import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:tiermetry/core/constants/map_tile_config.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/arena_entity.dart';

class ArenaMapScreen extends StatefulWidget {
  final ArenaEntity arena;

  const ArenaMapScreen({required this.arena, super.key});

  @override
  State<ArenaMapScreen> createState() => _ArenaMapScreenState();
}

class _ArenaMapScreenState extends State<ArenaMapScreen> {
  static const _darkMapFilter = ColorFilter.matrix(<double>[
    -0.42,
    -0.18,
    -0.08,
    0,
    168,
    -0.16,
    -0.38,
    -0.08,
    0,
    164,
    -0.12,
    -0.18,
    -0.32,
    0,
    166,
    0,
    0,
    0,
    1,
    0,
  ]);

  late final LatLng _arenaLocation;
  final MapController _mapController = MapController();
  bool _isOpeningMaps = false;

  @override
  void initState() {
    super.initState();
    assert(
      widget.arena.hasValidCoordinates,
      'ArenaMapScreen requires a valid venue coordinate pair.',
    );
    _arenaLocation = LatLng(widget.arena.latitude, widget.arena.longitude);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _recenterMap() {
    _mapController.move(_arenaLocation, 17.5);
  }

  Future<void> _openInMaps() async {
    if (_isOpeningMaps) return;
    setState(() => _isOpeningMaps = true);

    final query = '${_arenaLocation.latitude},${_arenaLocation.longitude}';
    final mapsUri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': query,
    });

    try {
      final opened = await launchUrl(
        mapsUri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        _showMapLaunchError();
      }
    } catch (_) {
      if (mounted) _showMapLaunchError();
    } finally {
      if (mounted) setState(() => _isOpeningMaps = false);
    }
  }

  void _showMapLaunchError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open this location in Maps.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final address =
        widget.arena.location.trim().isNotEmpty
            ? widget.arena.location.trim()
            : widget.arena.shortAddress.trim();

    return Scaffold(
      backgroundColor: TiermetryColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _arenaLocation,
                initialZoom: 17.5,
                minZoom: 4,
                maxZoom: MapTileConfig.maxZoom,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                ColorFiltered(
                  colorFilter:
                      MapTileConfig.applyDarkTreatment
                          ? _darkMapFilter
                          : const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.dst,
                          ),
                  child: TileLayer(
                    urlTemplate: MapTileConfig.urlTemplate,
                    userAgentPackageName: MapTileConfig.userAgentPackageName,
                    maxZoom: MapTileConfig.maxZoom,
                  ),
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _arenaLocation,
                      width: 56,
                      height: 64,
                      alignment: Alignment.topCenter,
                      child: Semantics(
                        label: '${widget.arena.name} exact location',
                        child: const _ArenaMapMarker(),
                      ),
                    ),
                  ],
                ),
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(MapTileConfig.attribution),
                  ],
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.5),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.4),
                    ],
                    stops: const [0, 0.18, 0.68, 1],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                TiermetrySpacing.lg,
                TiermetrySpacing.md,
                TiermetrySpacing.lg,
                0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _MapActionButton(
                    tooltip: 'Back',
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  _MapActionButton(
                    tooltip: 'Recenter on arena',
                    icon: Icons.my_location_rounded,
                    onPressed: _recenterMap,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  TiermetrySpacing.md,
                  0,
                  TiermetrySpacing.md,
                  TiermetrySpacing.md,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(TiermetrySpacing.screenPadding),
                  decoration: BoxDecoration(
                    color: TiermetryColors.surface.withValues(alpha: 0.97),
                    borderRadius: BorderRadius.circular(TiermetryRadii.lg),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.32),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EXACT VENUE PIN',
                        style: TiermetryTypography.bodySmall(
                          color: TiermetryColors.primary,
                        ).copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.arena.name.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TiermetryTypography.title(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                      if (address.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          address,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TiermetryTypography.bodySmall(
                            color: Colors.white70,
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        '${_arenaLocation.latitude.toStringAsFixed(6)}, '
                        '${_arenaLocation.longitude.toStringAsFixed(6)}',
                        style: TiermetryTypography.bodySmall(
                          color: Colors.white38,
                        ).copyWith(fontSize: 11),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isOpeningMaps ? null : _openInMaps,
                          icon:
                              _isOpeningMaps
                                  ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.directions_rounded),
                          label: const Text('OPEN IN MAPS'),
                          style: FilledButton.styleFrom(
                            backgroundColor: TiermetryColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(
                              0xFFEC441A,
                            ).withValues(alpha: 0.45),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                TiermetryRadii.sm,
                              ),
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
        ],
      ),
    );
  }
}

class _MapActionButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  const _MapActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TiermetryColors.surface.withValues(alpha: 0.96),
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black54,
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _ArenaMapMarker extends StatelessWidget {
  const _ArenaMapMarker();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          top: 43,
          child: Container(
            width: 4,
            height: 13,
            decoration: BoxDecoration(
              color: TiermetryColors.primary,
              borderRadius: BorderRadius.circular(TiermetryRadii.pill),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 7),
              ],
            ),
          ),
        ),
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: TiermetryColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.sports_tennis_rounded,
            color: Colors.white,
            size: 23,
          ),
        ),
      ],
    );
  }
}
