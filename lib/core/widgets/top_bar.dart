import 'dart:async';

import 'package:amazing_icons/amazing_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/widgets/india_city_picker_sheet.dart';
import 'package:tiermetry/features/notification/presentation/screens/notifications_screen.dart';

class TopBar extends StatelessWidget {
  final Animation<double>? menuAnimationProgress;
  final VoidCallback onMenuTap;

  const TopBar({
    required this.onMenuTap,
    super.key,
    this.menuAnimationProgress,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TiermetrySpacing.screenPadding,
          vertical: TiermetrySpacing.sm,
        ),
        child: RepaintBoundary(
          child: _TopBarSurface(
            menuAnimationProgress: menuAnimationProgress,
            onMenuTap: onMenuTap,
          ),
        ),
      ),
    );
  }
}

class _TopBarSurface extends StatelessWidget {
  final Animation<double>? menuAnimationProgress;
  final VoidCallback onMenuTap;

  const _TopBarSurface({
    required this.menuAnimationProgress,
    required this.onMenuTap,
  });

  Future<void> _showLocationPicker(BuildContext context) async {
    final city = await showIndiaCityPicker(
      context,
      searchCities: locator.locationCtrl.searchCities,
      useCurrentLocation: locator.locationCtrl.resolveCurrentCity,
      selectedCity: locator.locationCtrl.selectedCity,
    );
    if (city == null) return;

    try {
      await locator.profileCtrl.updateLocation(city);
      locator.locationCtrl.selectCity(city);
      unawaited(locator.communityCtrl.loadCommunities(city: city));
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Location updated to $city.')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location could not be saved. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B1B1B), Color(0xFF121212)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: SizedBox(
        height: TiermetrySpacing.topBarHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SvgPicture.asset('assets/HomiesApha.svg', height: 38),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => _showLocationPicker(context),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.065),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AmazingIconBulk.location(
                            size: 14,
                            color: TiermetryColors.primary,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: ListenableBuilder(
                              listenable: locator.locationCtrl,
                              builder: (context, _) {
                                return Text(
                                  locator.locationCtrl.selectedCity,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TopBarButton(
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                    child: AmazingIconBulk.notification(
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _TopBarButton(
                    onTap: onMenuTap,
                    child: AnimatedIcon(
                      icon: AnimatedIcons.menu_close,
                      progress:
                          menuAnimationProgress ?? kAlwaysDismissedAnimation,
                      size: 20,
                      color: TiermetryColors.accentNeonGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBarButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _TopBarButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withValues(alpha: 0.055),
        ),
        child: Center(child: child),
      ),
    );
  }
}
