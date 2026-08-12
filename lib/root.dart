import 'package:flutter/material.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/mixins/refresh_rate_mixin.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/bottom_nav.dart';
import 'package:tiermetry/core/widgets/drawer.dart';
import 'package:tiermetry/core/widgets/top_bar.dart';

import 'features/arena/presentation/screens/arena_screen.dart';
import 'features/booking/presentation/screens/booking_screen.dart';
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

class _RootState extends State<Root> with TickerProviderStateMixin, RefreshRateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _authCtrl = locator.authCtrl;

  int _selectedIndex = 0;
  final bool _hasNotification = true;

  late final AnimationController _menuAnimationController;

  final List<BottomNavItem> navItems = const [
    BottomNavItem(icon: Icons.home_filled, label: 'Home'),
    BottomNavItem(icon: Icons.sports_esports_rounded, label: 'Arenas'),
    BottomNavItem(icon: Icons.explore_rounded, label: 'Explore'),
    BottomNavItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _menuAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _pages = [
      HomeScreen(userName: _authCtrl.user?.name ?? 'Gamer'),
      const ArenaScreen(),
      const EventBrowserScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  void dispose() {
    _menuAnimationController.dispose();
    super.dispose();
  }

  List<DrawerItem> _buildDrawerItems() {
    return [
      DrawerItem(
        icon: Icons.person_outline_rounded,
        text: 'Account & Privacy',
        subtitle: 'Profile, phone, email',
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => const AccountPrivacyScreen(),
            ),
          );
        },
      ),
      DrawerItem(
        icon: Icons.receipt_long_rounded,
        text: 'My Transactions',
        subtitle: 'Wallet activity',
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => const TransactionsScreen(),
            ),
          );
        },
      ),
      DrawerItem(
        icon: Icons.bookmark_added_outlined,
        text: 'My Bookings',
        subtitle: 'Arena reservations',
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (context) => const BookingScreen()),
          );
        },
      ),
      DrawerItem(
        icon: Icons.confirmation_number_outlined,
        text: 'My Events',
        subtitle: 'Tickets and registrations',
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => const MyEventsScreen(),
            ),
          );
        },
      ),
      DrawerItem(
        icon: Icons.help_outline,
        text: 'Help & Support',
        subtitle: 'FAQs and contact',
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => const HelpAndSupportScreen(),
            ),
          );
        },
      ),
      DrawerItem(
        icon: Icons.description_outlined,
        text: 'Legal & Policies',
        subtitle: 'Terms and privacy',
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => const LegalPoliciesScreen(),
            ),
          );
        },
      ),
      DrawerItem(
        icon: Icons.logout_rounded,
        text: 'Logout',
        subtitle: 'Sign out of this device',
        color: Colors.redAccent,
        onTap: _showLogoutSheet,
      ),
    ];
  }

  void _showLogoutSheet() {
    Navigator.pop(context);
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
            border: Border.all(color: TiermetryColors.white.withValues(alpha: 0.08)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Log out?',
                  style: TiermetryTypography.title(color: TiermetryColors.white),
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

  Widget _getCurrentTitle() {
    switch (_selectedIndex) {
      case 0:
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'TIERMETRY',
              style: TiermetryTypography.title(
                color: TiermetryColors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'JUST KNOCK IT OUT',
              style: TiermetryTypography.caption(
                color: TiermetryColors.white.withValues(alpha: 0.62),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.9,
              ),
            ),
          ],
        );
      case 1:
        return Text(
          'Arenas',
          key: const ValueKey('arenas'),
          style: TiermetryTypography.title(color: TiermetryColors.white),
        );
      case 2:
        return Text(
          'Events',
          key: const ValueKey('events'),
          style: TiermetryTypography.title(color: TiermetryColors.white),
        );
      case 3:
        return Text(
          'Profile',
          key: const ValueKey('profile'),
          style: TiermetryTypography.title(color: TiermetryColors.white),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(
        userName: _authCtrl.user?.name ?? 'Gamer',
        userHandle: '@${(_authCtrl.user?.name ?? 'gamer').toLowerCase().replaceAll(' ', '_')}',
        userAvatarAsset: 'assets/Seller.png',
        items: _buildDrawerItems(),
      ),
      onDrawerChanged: (isOpened) {
        if (isOpened) {
          _menuAnimationController.forward();
        } else {
          _menuAnimationController.reverse();
        }
      },
      backgroundColor: TiermetryColors.black,
      body: Stack(
        children: [
          IndexedStack(index: _selectedIndex, children: _pages),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: TopBar(
              title: _getCurrentTitle(),
              menuAnimationProgress: _menuAnimationController,
              hasNotification: _hasNotification,
              onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: TiermetrySpacing.screenPadding),
              child: BottomNav(
                currentIndex: _selectedIndex,
                onTap: (index) {
                  setState(() => _selectedIndex = index);
                },
                items: navItems,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
