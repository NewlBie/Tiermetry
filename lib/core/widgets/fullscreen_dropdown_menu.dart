import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/spacing.dart';

class FullscreenDropdownMenu extends StatelessWidget {
  final Animation<double> animation;
  final VoidCallback onClose;
  final void Function(int) onNavigateIndex;
  final void Function(String routeName) onPushRoute;
  final VoidCallback onLogout;
  final String userName;
  final String userHandle;
  final String userAvatarAsset;
  final bool isOpen;

  const FullscreenDropdownMenu({
    required this.animation, required this.onClose, required this.onNavigateIndex, required this.onPushRoute, required this.onLogout, required this.userName, required this.userHandle, required this.userAvatarAsset, required this.isOpen, super.key,
  });

  @override
  Widget build(BuildContext context) {
    // A slight fade along with the slide down
    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: animation, curve: Curves.easeIn),
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -1), // Slide down from the top
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.fastOutSlowIn, // Smooth snapping
      )),
      child: FadeTransition(
        opacity: fadeAnimation,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.98), // Very dark solid background
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top spacer so it doesn't overlap the TopBar
                const SizedBox(height: TiermetrySpacing.topBarHeight + 20),
                
                // Profile Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: TiermetryColors.accentNeonGreen.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: TiermetryColors.accentNeonGreen.withValues(alpha: 0.15),
                          ),
                          child: Center(
                            child: CircleAvatar(
                              radius: 24,
                              backgroundImage: AssetImage(userAvatarAsset),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName.toUpperCase(),
                                style: GoogleFonts.geist(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: TiermetryColors.accentNeonGreen.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  userHandle,
                                  style: GoogleFonts.geist(
                                    color: TiermetryColors.accentNeonGreen,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white54),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Central Word Cloud
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildMenuText('BOOKINGS', () { onClose(); onPushRoute('booking'); }, 0),
                          _buildMenuText('EVENTS', () { onClose(); onPushRoute('my_events'); }, 1),
                          _buildMenuText('TRANSACTIONS', () { onClose(); onPushRoute('wallet'); }, 2),
                          _buildMenuText('ACCOUNT', () { onClose(); onPushRoute('account'); }, 3),
                          _buildMenuText('HELP', () { onClose(); onPushRoute('support'); }, 4),
                          _buildMenuText('TERMS', () { onClose(); onPushRoute('legal'); }, 5),
                        ],
                      ),
                    ),
                  ),
                ),

                // Logout Card
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24).copyWith(bottom: 24),
                    child: GestureDetector(
                      onTap: () { onClose(); onLogout(); },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: Icon(Icons.power_settings_new_rounded, color: Colors.redAccent),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Logout',
                                    style: GoogleFonts.geist(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Sign out of this device',
                                    style: GoogleFonts.geist(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.redAccent.withValues(alpha: 0.6),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuText(String title, VoidCallback onTap, int index) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.geist(
            fontSize: 48, // Slightly smaller to fit long names like ACCOUNT & PRIVACY
            fontWeight: FontWeight.w900,
            letterSpacing: -2.0,
            height: 0.9, 
            color: TiermetryColors.accentNeonGreen,
          ),
        ),
      ),
    )
    .animate(target: isOpen ? 1 : 0)
    .fade(duration: 500.ms, delay: (60 * index).ms)
    .slideY(begin: 0.4, end: 0, duration: 600.ms, curve: Curves.easeOutBack)
    .scaleXY(begin: 0.7, end: 1.0, duration: 600.ms, curve: Curves.easeOutBack)
    .shimmer(delay: (300 + (60 * index)).ms, duration: 900.ms, color: Colors.white, angle: 1.0);
  }
}
