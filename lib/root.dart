import 'package:amazing_icons/bulk.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tiermetry/core/constants/app_avatars.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/mixins/refresh_rate_mixin.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/bottom_nav.dart';
import 'package:tiermetry/core/widgets/deferred_page.dart';
import 'package:tiermetry/core/widgets/fullscreen_dropdown_menu.dart';
import 'package:tiermetry/core/widgets/top_bar.dart';

import 'features/arena/presentation/screens/arena_screen.dart';
import 'features/booking/presentation/screens/booking_screen.dart';
import 'features/booking/presentation/widgets/floating_booking_pill.dart';
import 'features/event/presentation/screens/event_browser_screen.dart';
import 'features/event/presentation/screens/my_events_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/profile/presentation/screens/account_privacy_screen.dart';
import 'features/profile/presentation/screens/help_and_support_screen.dart';
import 'features/profile/presentation/screens/legal_policies_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/profile/presentation/screens/transactions_screen.dart';

class Root extends StatefulWidget {
  const Root({super.key});

  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root>
    with TickerProviderStateMixin, RefreshRateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _authCtrl = locator.authCtrl;
  final _profileCtrl = locator.profileCtrl;

  int _selectedIndex = 0;
  bool _isMenuOpen = false;

  late final AnimationController _menuAnimationController;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  final List<BottomNavItem> navItems = [
    BottomNavItem(
      iconBuilder:
          (size, color) => AmazingIconBulk.home(size: size, color: color),
      label: 'Home',
    ),
    BottomNavItem(
      iconBuilder:
          (size, color) => AmazingIconBulk.game(size: size, color: color),
      label: 'Arenas',
    ),
    BottomNavItem(
      iconBuilder:
          (size, color) => AmazingIconBulk.discover(size: size, color: color),
      label: 'Explore',
    ),
    BottomNavItem(
      iconBuilder:
          (size, color) => AmazingIconBulk.profile(size: size, color: color),
      label: 'Profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _menuAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _menuAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed ||
          status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {});
        }
      }
    });

    final savedLocation = _profileCtrl.profile?.location.trim();
    if (savedLocation != null && savedLocation.isNotEmpty) {
      locator.locationCtrl.selectCity(savedLocation);
    }
  }

  @override
  void dispose() {
    _menuAnimationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (_isMenuOpen) {
      _menuAnimationController.reverse();
    } else {
      _menuAnimationController.forward();
    }
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  void _handleMenuRoute(String route) {
    // We navigate to existing screens
    Widget? target;
    switch (route) {
      case 'booking':
        target = const BookingScreen();
        break;
      case 'my_events':
        target = const MyEventsScreen();
        break;
      case 'wallet':
        target = const TransactionsScreen();
        break;
      case 'account':
        target = const AccountPrivacyScreen();
        break;
      case 'support':
        target = const HelpAndSupportScreen();
        break;
      case 'legal':
        target = const LegalPoliciesScreen();
        break;
    }

    if (target != null) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (context) => target!),
      );
    }
  }

  void _showLogoutSheet() {
    // If the menu was open, the overlay will disappear because _isMenuOpen is toggled false inside FullscreenDropdownMenu.
    // Wait, the menu calls onClose before onLogout.
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: TiermetryColors.surface,
            borderRadius: BorderRadius.circular(TiermetryRadii.lg),
            border: Border.all(
              color: TiermetryColors.white.withValues(alpha: 0.08),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ('Log out?').toUpperCase(),
                  style: TiermetryTypography.title(
                    color: TiermetryColors.white,
                  ),
                ),
                const SizedBox(height: TiermetrySpacing.sm),
                Text(
                  'You can sign back in anytime.',
                  style: TiermetryTypography.caption(
                    color: TiermetryColors.white.withValues(alpha: 0.62),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _authCtrl.signOut();
                          locator.profileCtrl.clear();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Logout'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_isMenuOpen) {
          _toggleMenu();
          return;
        }
        final innerNav = _navigatorKeys[_selectedIndex].currentState;
        if (innerNav != null && innerNav.canPop()) {
          innerNav.pop();
        } else if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
        } else {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: TiermetryColors.black,
        body: Stack(
          children: [
            IndexedStack(
              index: _selectedIndex,
              children: [
                DeferredPage(
                  index: 0,
                  currentIndex: _selectedIndex,
                  child: Navigator(
                    key: _navigatorKeys[0],
                    onGenerateRoute:
                        (settings) => MaterialPageRoute<void>(
                          builder:
                              (context) => HomeScreen(
                                userName: _authCtrl.user?.name ?? 'Gamer',
                              ),
                        ),
                  ),
                ),
                DeferredPage(
                  index: 1,
                  currentIndex: _selectedIndex,
                  child: Navigator(
                    key: _navigatorKeys[1],
                    onGenerateRoute:
                        (settings) => MaterialPageRoute<void>(
                          builder: (context) => const ArenaScreen(),
                        ),
                  ),
                ),
                DeferredPage(
                  index: 2,
                  currentIndex: _selectedIndex,
                  child: Navigator(
                    key: _navigatorKeys[2],
                    onGenerateRoute:
                        (settings) => MaterialPageRoute<void>(
                          builder: (context) => const EventBrowserScreen(),
                        ),
                  ),
                ),
                DeferredPage(
                  index: 3,
                  currentIndex: _selectedIndex,
                  child: Navigator(
                    key: _navigatorKeys[3],
                    onGenerateRoute:
                        (settings) => MaterialPageRoute<void>(
                          builder: (context) => const ProfileScreen(),
                        ),
                  ),
                ),
              ],
            ),

            // BottomNav
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TiermetrySpacing.screenPadding,
                  ),
                  child: BottomNav(
                    currentIndex: _selectedIndex,
                    onTap: (index) {
                      setState(() => _selectedIndex = index);
                    },
                    items: navItems,
                  ),
                ),
              ),
            ),

            // Floating Booking Pill (above BottomNav)
            const Positioned(
              left: TiermetrySpacing.screenPadding,
              right: TiermetrySpacing.screenPadding,
              bottom: 0,
              child: SafeArea(
                top: false,
                minimum: EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: EdgeInsets.only(bottom: 78),
                  child: FloatingBookingPill(),
                ),
              ),
            ),

            // Overlay Fullscreen Menu
            if (_isMenuOpen || !_menuAnimationController.isDismissed)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: !_isMenuOpen,
                  child: ListenableBuilder(
                    listenable: _profileCtrl,
                    builder: (context, _) {
                      final profile = _profileCtrl.profile;
                      final userName =
                          profile?.name.isNotEmpty == true
                              ? profile!.name
                              : (_authCtrl.user?.name ?? 'Gamer');
                      final userHandle =
                          profile?.username?.isNotEmpty == true
                              ? '@${profile!.username}'
                              : '@${userName.toLowerCase().replaceAll(' ', '_')}';
                      final avatarAsset = AppAvatar.assetForId(
                        profile?.avatarId ??
                            AppAvatar.idFromAssetOrString(profile?.image) ??
                            AppAvatar.defaultAvatarId,
                      );

                      return FullscreenDropdownMenu(
                        animation: _menuAnimationController,
                        onClose: _toggleMenu,
                        onNavigateIndex: (index) {
                          setState(() => _selectedIndex = index);
                        },
                        onPushRoute: _handleMenuRoute,
                        onLogout: _showLogoutSheet,
                        userName: userName,
                        userHandle: userHandle,
                        userAvatarAsset: avatarAsset,
                        isOpen: _isMenuOpen,
                      );
                    },
                  ),
                ),
              ),

            // TopBar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: TopBar(
                menuAnimationProgress: _menuAnimationController,
                onMenuTap: _toggleMenu,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
