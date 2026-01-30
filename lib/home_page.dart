import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// Pages
import 'package:tiermetry/pages/arena_page.dart';
import 'package:tiermetry/pages/profile_page.dart';
import 'package:tiermetry/pages/transactions_page.dart';
import 'package:tiermetry/pages/bookings_page.dart';

// Tabs
import 'package:tiermetry/tabs/home_tab.dart';
import 'package:tiermetry/tabs/events_marketplace_tab.dart';

// Components
import 'apple_bottom_nav_bar.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedIndex = 0;
  final bool _hasNotification = true;

  late final AnimationController _menuAnimationController;

  final List<AppleBottomNavBarItem> navItems = const [
    AppleBottomNavBarItem(icon: Icons.home_rounded),
    AppleBottomNavBarItem(icon: Icons.sports_esports_rounded),
    AppleBottomNavBarItem(icon: Icons.explore_rounded),
    AppleBottomNavBarItem(icon: Icons.person_rounded),
  ];

  final List<Widget> _pages = const [
    HomeTab(userName: "Neal"),
    ArenaPage(),
    EventsMarketplaceTab(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _menuAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _menuAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildSideDrawer(),
      onDrawerChanged: (isOpened) {
        if (isOpened) {
          _menuAnimationController.forward();
        } else {
          _menuAnimationController.reverse();
        }
      },
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 10, left: 16, right: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.12),
                            Colors.white.withValues(alpha: 0.03),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            height: 34,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 450),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              transitionBuilder: (child, animation) {
                                final offsetAnimation = Tween<Offset>(
                                  begin: const Offset(0, 0.5),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
                                return ClipRect(
                                  child: SlideTransition(
                                    position: offsetAnimation,
                                    child: FadeTransition(opacity: animation, child: child),
                                  ),
                                );
                              },
                              child: _buildAppBarTitle(_selectedIndex),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              _scaffoldKey.currentState?.openDrawer();
                            },
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                AnimatedIcon(
                                  icon: AnimatedIcons.menu_close,
                                  progress: _menuAnimationController,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                if (_hasNotification)
                                  Positioned(
                                    right: -2,
                                    top: -2,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(color: Colors.red.withValues(alpha: 0.4), blurRadius: 4)
                                        ],
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
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AppleBottomNavBar(
                currentIndex: _selectedIndex,
                onTap: (index) {
                  HapticFeedback.lightImpact();
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

  Widget _buildAppBarTitle(int index) {
    switch (index) {
      case 0:
        return Image.asset('assets/logo.png', key: const ValueKey('logo'), height: 34);
      case 1:
        return Text('Arenas', key: const ValueKey('arenas'), style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600));
      case 2:
        return Text('Events', key: const ValueKey('events'), style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600));
      case 3:
        return Text('Profile', key: const ValueKey('profile'), style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    Color? color,
    VoidCallback? onTap,
  }) {
    final itemColor = color ?? Colors.white;
    return ListTile(
      leading: Icon(icon, color: itemColor.withValues(alpha: 0.8)),
      title: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          color: itemColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildSideDrawer() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.75,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border(
              right: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          child: Drawer(
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: <Widget>[
                SizedBox(
                  height: 140,
                  child: DrawerHeader(
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide.none)),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=a042581f4e29026704d'),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Neal',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '@neal_adams',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                _buildDrawerItem(icon: Icons.settings_outlined, text: 'Settings', onTap: () => Navigator.pop(context)),
                _buildDrawerItem(icon: Icons.notifications_outlined, text: 'Notifications', onTap: () => Navigator.pop(context)),
                _buildDrawerItem(
                  icon: Icons.receipt_long_rounded,
                  text: 'My Transactions',
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionsPage()));
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.bookmark_added_outlined,
                  text: 'My Bookings',
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const BookingsPage()));
                  },
                ),
                _buildDrawerItem(icon: Icons.help_outline, text: 'Help & Support', onTap: () => Navigator.pop(context)),
                _buildDrawerItem(icon: Icons.info_outline, text: 'About', onTap: () => Navigator.pop(context)),
                const Divider(color: Colors.white24, indent: 16, endIndent: 16, height: 30),
                _buildDrawerItem(
                  icon: Icons.logout_rounded,
                  text: 'Logout',
                  color: Colors.redAccent,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
