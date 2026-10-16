import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiermetry/core/constants/feature_flags.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/features/auth/presentation/screens/auth_wrapper.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  double _dx = 0;
  double _dy = 0;

  @override
  void initState() {
    super.initState();
    _accelSubscription = accelerometerEventStream().listen((
      AccelerometerEvent event,
    ) {
      if (mounted && _currentPage == 0) {
        setState(() {
          // Use accelerometer for tilt angle instead of gyro rotation rate
          // event.x: + is tilt left, - is tilt right
          // event.y: + is tilt upright, - is tilt flat/upside down
          _dx = -(event.x * 4.0).clamp(-40.0, 40.0);
          _dy = (event.y * 4.0).clamp(-40.0, 40.0);
        });
      }
    });
  }

  @override
  void dispose() {
    _accelSubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _pages {
    final pages = [
      {
        'title': 'WHAT IS UP HOMIES',
        'description':
            'The ultimate recreational booking app for real-world activities, gaming arenas, and events.',
        'image': 'assets/Homies (2).png',
      },
      {
        'title': 'SECURE THE SPOT',
        'description':
            'Pull up to the most fire gaming venues and esports arenas. Top-tier setups only, no cap.',
        'image': 'assets/sec_spot.png',
      },
      {
        'title': 'DROP INTO TOURNIES',
        'description':
            'Sweaty lobbies await. Pop off in local and online tournaments to climb the ranks and secure those dubs.',
        'image': 'assets/tournies.png',
      },
    ];

    if (!FeatureFlags.disableFinancialRewards) {
      pages.add({
        'title': 'STACK TIERGIES',
        'description':
            'Grind side quests, farm massive rewards, and cop exclusive loot from the store. Big Ws only.',
        'image': 'assets/tiergies.png',
      });
    }

    return pages;
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (mounted) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(builder: (context) => const AuthWrapper()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    Expanded(
                      child: SizedBox(
                        width: double.infinity,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned.fill(
                              child: ShaderMask(
                                shaderCallback: (rect) {
                                  return const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.black, Colors.transparent],
                                    stops: [0.6, 1.0],
                                  ).createShader(rect);
                                },
                                blendMode: BlendMode.dstIn,
                                child: Image.asset(
                                  _pages[index]['image']!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  alignment: Alignment.topCenter,
                                ),
                              ),
                            ),
                            if (index == 0)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                curve: Curves.easeOut,
                                transform: Matrix4.translationValues(
                                  _dx,
                                  _dy,
                                  0,
                                ),
                                child: SvgPicture.asset(
                                  'assets/HomiesText.svg',
                                  width: screenWidth * 0.65,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.08,
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: screenHeight * 0.03),
                          Text(
                            _pages[index]['title']!,
                            style: GoogleFonts.geist(
                              fontSize:
                                  screenWidth * 0.11, // Large, responsive title
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 0.9, // Very tight line spacing
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Text(
                            _pages[index]['description']!,
                            style: GoogleFonts.geist(
                              fontSize:
                                  screenWidth * 0.04, // Responsive body text
                              color: Colors.white70,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: screenHeight * 0.05),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.06),
              child: GestureDetector(
                onTap: () {
                  if (_currentPage < _pages.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.fastOutSlowIn,
                    );
                  } else {
                    _completeOnboarding();
                  }
                },
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutExpo,
                    height: 64,
                    width: _currentPage == _pages.length - 1 ? screenWidth * 0.8 : 220,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Frosted glass blur (blurs the image behind the button)
                          BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(color: Colors.transparent),
                          ),
                          // Solid color fill (paints OVER the blur)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutExpo,
                            decoration: BoxDecoration(
                              color: _currentPage == _pages.length - 1 
                                  ? TiermetryColors.primary 
                                  : Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                            // Dots (visible when not on last page)
                            AnimatedOpacity(
                              opacity: _currentPage == _pages.length - 1 ? 0.0 : 1.0,
                              duration: const Duration(milliseconds: 250),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 20, right: 64),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    _pages.length,
                                    (index) => AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      height: 6,
                                      width: _currentPage == index ? 24 : 6,
                                      decoration: BoxDecoration(
                                        color: _currentPage == index
                                            ? TiermetryColors.primary
                                            : Colors.white30,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Next Arrow Icon
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 450),
                              curve: Curves.fastOutSlowIn,
                              right: _currentPage == _pages.length - 1 ? (screenWidth * 0.8) / 2 - 24 : 8,
                              child: AnimatedOpacity(
                                opacity: _currentPage == _pages.length - 1 ? 0.0 : 1.0,
                                duration: const Duration(milliseconds: 250),
                                child: Container(
                                  height: 48,
                                  width: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                            // Get Started Text (visible on last page)
                            AnimatedOpacity(
                              opacity: _currentPage == _pages.length - 1 ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 400),
                              child: Text(
                                'Get Started',
                                style: GoogleFonts.geist(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  fontSize: screenWidth * 0.045,
                                  letterSpacing: 1.0,
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
            ),
          ],
        ),
      );
  }
}
