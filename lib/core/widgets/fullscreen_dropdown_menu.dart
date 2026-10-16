import 'package:flutter/material.dart';
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
    required this.animation,
    required this.onClose,
    required this.onNavigateIndex,
    required this.onPushRoute,
    required this.onLogout,
    required this.userName,
    required this.userHandle,
    required this.userAvatarAsset,
    required this.isOpen,
    super.key,
  });

  void _openRoute(String route) {
    onClose();
    onPushRoute(route);
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final entries = [
      _MenuEntry(
        icon: Icons.calendar_month_rounded,
        title: 'Bookings',
        subtitle: 'Your upcoming scenes',
        onTap: () => _openRoute('booking'),
      ),
      _MenuEntry(
        icon: Icons.local_activity_rounded,
        title: 'My events',
        subtitle: 'Tickets and check-ins',
        onTap: () => _openRoute('my_events'),
      ),
      _MenuEntry(
        icon: Icons.receipt_long_rounded,
        title: 'Transactions',
        subtitle: 'Payments and refunds',
        onTap: () => _openRoute('wallet'),
      ),
      _MenuEntry(
        icon: Icons.manage_accounts_rounded,
        title: 'Account',
        subtitle: 'Privacy and security',
        onTap: () => _openRoute('account'),
      ),
      _MenuEntry(
        icon: Icons.support_agent_rounded,
        title: 'Help',
        subtitle: 'Support when needed',
        onTap: () => _openRoute('support'),
      ),
      _MenuEntry(
        icon: Icons.policy_rounded,
        title: 'Legal',
        subtitle: 'Terms and policies',
        onTap: () => _openRoute('legal'),
      ),
    ];

    return IgnorePointer(
      ignoring: !isOpen,
      child: FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.08),
            end: Offset.zero,
          ).animate(curved),
          child: ColoredBox(
            color: const Color(0xFF090909),
          child: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                TiermetrySpacing.screenPadding,
                TiermetrySpacing.topBarHeight + 22,
                TiermetrySpacing.screenPadding,
                24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MENU',
                    style: GoogleFonts.geist(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Everything you need, one tap away.',
                    style: GoogleFonts.geist(
                      color: Colors.white.withValues(alpha: 0.48),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _ProfileShortcut(
                    userName: userName,
                    userHandle: userHandle,
                    userAvatarAsset: userAvatarAsset,
                    onTap: () {
                      onClose();
                      onNavigateIndex(3);
                    },
                  ),
                  const SizedBox(height: 20),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: entries.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.72,
                        ),
                    itemBuilder:
                        (context, index) => _MenuTile(entry: entries[index]),
                  ),
                  const SizedBox(height: 20),
                  _LogoutButton(
                    onTap: () {
                      onClose();
                      onLogout();
                    },
                  ),
                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  }
}

class _ProfileShortcut extends StatelessWidget {
  final String userName;
  final String userHandle;
  final String userAvatarAsset;
  final VoidCallback onTap;

  const _ProfileShortcut({
    required this.userName,
    required this.userHandle,
    required this.userAvatarAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.055),
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 48,
                  height: 48,
                  color: Colors.white.withValues(alpha: 0.08),
                  child: Image.asset(
                    userAvatarAsset,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.geist(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userHandle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.geist(
                        color: TiermetryColors.accentNeonGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuEntry {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _MenuTile extends StatelessWidget {
  final _MenuEntry entry;

  const _MenuTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.045),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: entry.onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                entry.icon,
                color: TiermetryColors.accentNeonGreen,
                size: 21,
              ),
              const Spacer(),
              Text(
                entry.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.geist(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                entry.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.geist(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.redAccent.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          child: Row(
            children: [
              const Icon(
                Icons.logout_rounded,
                color: Colors.redAccent,
                size: 20,
              ),
              const SizedBox(width: 11),
              Text(
                'Log out',
                style: GoogleFonts.geist(
                  color: Colors.redAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                'This device',
                style: GoogleFonts.geist(
                  color: Colors.redAccent.withValues(alpha: 0.55),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
