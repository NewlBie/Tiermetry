import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tiermetry/core/constants/app_avatars.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/mixins/refresh_rate_mixin.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/features/profile/domain/entities/profile_entity.dart';
import 'package:tiermetry/features/profile/presentation/screens/refer_and_earn_screen.dart';
import '../../domain/entities/loyalty_account_entity.dart';
import '../widgets/choose_next_scene_widget.dart';
import '../widgets/earned_invites_section.dart';
import '../widgets/friends_card.dart';
import '../widgets/second_scene_key_card.dart';
import '../widgets/vibe_xp_status_card.dart';

class RewardStoreScreen extends StatefulWidget {
  const RewardStoreScreen({super.key});

  @override
  State<RewardStoreScreen> createState() => _RewardStoreScreenState();
}

class _RewardStoreScreenState extends State<RewardStoreScreen>
    with RefreshRateMixin {
  @override
  void initState() {
    super.initState();
    locator.loyaltyCtrl.refreshAll();
    if (locator.profileCtrl.profile == null) {
      locator.profileCtrl.loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([locator.loyaltyCtrl, locator.profileCtrl]),
      builder: (context, _) {
        final ctrl = locator.loyaltyCtrl;
        final account = ctrl.account;
        final profile = locator.profileCtrl.profile;

        if (account == null || profile == null) {
          return Scaffold(
            backgroundColor: TiermetryColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'HOMIES LOOP & REWARDS',
                style: TiermetryTypography.label(
                  color: Colors.white,
                  letterSpacing: 1.2,
                ).copyWith(fontSize: 12),
              ),
              centerTitle: true,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(TiermetrySpacing.screenPadding),
                child:
                    ctrl.isLoading || locator.profileCtrl.isLoading
                        ? const CircularProgressIndicator(
                          color: TiermetryColors.accentNeonGreen,
                        )
                        : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              ctrl.errorMessage ??
                                  locator.profileCtrl.errorMessage ??
                                  'Your rewards are unavailable right now.',
                              textAlign: TextAlign.center,
                              style: TiermetryTypography.bodySmall(
                                color: TiermetryColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: TiermetrySpacing.md),
                            OutlinedButton(
                              onPressed: () async {
                                await Future.wait([
                                  ctrl.refreshAll(),
                                  locator.profileCtrl.loadProfile(),
                                ]);
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
              ),
            ),
          );
        }

        final topInset = math.max(MediaQuery.paddingOf(context).top, 24.0);

        return Scaffold(
          backgroundColor: TiermetryColors.background,
          body: Stack(
            children: [
              // Scrollable rewards content
              RefreshIndicator(
                onRefresh: ctrl.refreshAll,
                color: TiermetryColors.accentNeonGreen,
                edgeOffset: 80,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    TiermetrySpacing.screenPadding,
                    topInset + 64,
                    TiermetrySpacing.screenPadding,
                    140,
                  ),
                  children: [
                    // Top Hero: Enlarged Circular Avatar, Name, Username, Date Joined, Location, Quick Overview
                    _UserProfileHeroSection(profile: profile, account: account),
                    const SizedBox(height: TiermetrySpacing.xl),

                    // Homie status horizontal scroll level progress (transparent, no redundant headers, full scrollable rail)
                    VibeXpStatusCard(
                      account: account,
                      transparent: true,
                      hideHeader: true,
                      showAllTiers: true,
                    ),
                    const SizedBox(height: TiermetrySpacing.lg),

                    // Second Scene Key Card (if active)
                    if (account.activeKey != null &&
                        account.activeKey!.status == 'active') ...[
                      SecondSceneKeyCard(keyEntity: account.activeKey),
                      const SizedBox(height: TiermetrySpacing.lg),
                    ],

                    // Choose Your Next Scene (Post-Scene 2)
                    if (account.currentScene >= 2) ...[
                      ChooseNextSceneWidget(
                        currentScene: account.currentScene,
                        activeChoice: account.nextSceneChoice,
                        onChoiceUpdated: ctrl.refreshAll,
                      ),
                      const SizedBox(height: TiermetrySpacing.lg),
                    ],

                    // Earned Invites Card
                    EarnedInvitesSection(
                      isUnlocked: account.earnedInvitesUnlocked,
                      invites: account.invites,
                      referralCard: ctrl.referralCard,
                      onInviteSent: ctrl.refreshAll,
                      onReferralTap:
                          () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ReferAndEarnScreen(),
                            ),
                          ),
                    ),
                    const SizedBox(height: TiermetrySpacing.lg),

                    // Friends Card
                    FriendsCard(
                      friends: ctrl.friends,
                      referralCode: ctrl.referralCard?.code,
                      referralLink: ctrl.referralCard?.link,
                      onSearch: ctrl.searchFriendProfiles,
                      onRequestFriend: ctrl.requestFriendship,
                      onAcceptFriend: ctrl.acceptFriendship,
                      onDeclineFriend: ctrl.declineFriendship,
                      onRemoveFriend: ctrl.removeFriendship,
                    ),
                  ],
                ),
              ),

              // Floating dark blurred circular back button
              Positioned(
                top: topInset + 8,
                left: TiermetrySpacing.screenPadding,
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                          },
                          child: const Center(
                            child: Padding(
                              padding: EdgeInsets.only(right: 2),
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
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
      },
    );
  }
}

class _UserProfileHeroSection extends StatelessWidget {
  final ProfileEntity profile;
  final LoyaltyAccountEntity account;

  const _UserProfileHeroSection({required this.profile, required this.account});

  @override
  Widget build(BuildContext context) {
    final name = profile.name;
    final username = profile.username?.toUpperCase() ?? '';
    final joined = profile.joinedDate;
    final location = profile.location;
    final avatarAsset = AppAvatar.assetForId(profile.avatarId);

    return Column(
      children: [
        // Enlarged circular avatar
        Container(
          width: 116,
          height: 116,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFC084FC).withValues(alpha: 0.5),
              width: 3,
            ),
          ),
          child: ClipOval(child: Image.asset(avatarAsset, fit: BoxFit.cover)),
        ),
        const SizedBox(height: 16),

        // User full name
        Text(
          name.toUpperCase(),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TiermetryTypography.display(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 6),

        // @username · JOINED <date>
        Text(
          '@$username · JOINED $joined',
          textAlign: TextAlign.center,
          style: TiermetryTypography.label(
            color: Colors.white60,
            fontSize: 12,
            letterSpacing: 0.8,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),

        // Location centered
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 15,
              color: TiermetryColors.accentNeonGreen,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TiermetryTypography.caption(color: Colors.white70),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Apple-style Opaque Metrics Card (Status on left stacked, Vibe XP metric on right)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          decoration: BoxDecoration(
            color: TiermetryColors.surface,
            borderRadius: BorderRadius.circular(TiermetryRadii.lg),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left side: Status stacked in two lines
              Text(
                account.status.name.replaceAll(' ', '\n'),
                style: GoogleFonts.geist(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                  letterSpacing: 0,
                ),
              ),

              // Right side: Vibe XP metric
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${account.vibeXp}',
                    style: GoogleFonts.geist(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'VIBE XP',
                    style: GoogleFonts.geist(
                      color: TiermetryColors.textMuted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
