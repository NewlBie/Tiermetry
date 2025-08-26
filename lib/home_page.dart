import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// Assuming all pages are in the /lib/pages or /lib/tabs directory
// and your custom nav bar is in /lib/widgets
import 'arena_page.dart';
import 'events_marketplace_tab.dart';
import 'home_tab.dart';
import 'apple_bottom_nav_bar.dart'; // Ensure this path is correct
import 'profile_page.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _menuOpened = false;
  bool _hasNotification = true;

  late final AnimationController _menuAnimationController;

  // ✨ 1. Define the list of navigation bar items
  final List<AppleBottomNavBarItem> navItems = const [
    AppleBottomNavBarItem(icon: Icons.home_rounded),
    AppleBottomNavBarItem(icon: Icons.sports_esports_rounded),
    AppleBottomNavBarItem(icon: Icons.explore_rounded),
    AppleBottomNavBarItem(icon: Icons.person_rounded),
  ];

  // The list of pages for the IndexedStack
  // This is now clean and uses the backend-ready pages
  final List<Widget> _pages = const [
    HomeTab(),
    ArenaPage(),
    EventsMarketplaceTab(),
    ProfilePage(), // No more hardcoded data!
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
      backgroundColor: Colors.black, // A solid background is better for performance
      body: Stack(
        children: [
          // Instantly switch tabs using IndexedStack
          IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),

          // Apple-Style AppBar with animated title
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
                            Colors.white.withOpacity(0.12),
                            Colors.white.withOpacity(0.03),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
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
                              setState(() => _menuOpened = !_menuOpened);
                              _menuOpened
                                  ? _menuAnimationController.forward()
                                  : _menuAnimationController.reverse();
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
                                          BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 4)
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

          // Bottom NavBar
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
                // ✨ 2. Pass the 'navItems' list to the widget
                items: navItems,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarTitle(int index) {
    // This widget provides the animated title based on the selected tab
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
}