import 'package:amazing_icons/outlined.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tiermetry/core/constants/app_avatars.dart';
import 'package:tiermetry/core/constants/feature_flags.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/mixins/refresh_rate_mixin.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_error_state.dart';
import 'package:tiermetry/core/widgets/app_island_notice.dart';
import 'package:tiermetry/features/home/presentation/widgets/home_backdrop.dart';
import 'package:tiermetry/features/home/presentation/widgets/scroll_gradient_overlay.dart';
import 'package:tiermetry/features/wallet/domain/entities/loyalty_account_entity.dart';
import 'package:tiermetry/features/wallet/presentation/screens/reward_store_screen.dart';
import 'package:tiermetry/features/wallet/presentation/widgets/wallet_flip_card.dart';

import '../../domain/entities/profile_entity.dart';
import '../widgets/avatar_selection_sheet.dart';
import '../widgets/profile_settings_section.dart';
import '../widgets/tier_and_badge_card.dart';
import 'account_privacy_screen.dart';
import 'refer_and_earn_screen.dart';
import 'transactions_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ScrollController? controller;

  const ProfileScreen({super.key, this.controller});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with RefreshRateMixin {
  late final _profileCtrl = locator.profileCtrl;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _profileCtrl.profile == null) {
        _profileCtrl.loadProfile();
      }
      if (!FeatureFlags.disableFinancialRewards) {
        locator.loyaltyCtrl.refreshAll();
      }
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  Future<void> _refreshProfile() async {
    await Future.wait([
      _profileCtrl.loadProfile(),
      if (!FeatureFlags.disableFinancialRewards)
        locator.loyaltyCtrl.refreshAll(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: TiermetryColors.background,
      body: Stack(
        children: [
          const HomeBackdrop(),
          ListenableBuilder(
            listenable: _profileCtrl,
            builder: (context, child) {
              if (_profileCtrl.isLoading && _profileCtrl.profile == null) {
                return const _ProfileShimmerPlaceholder();
              }

              if (_profileCtrl.profile == null) {
                return AppErrorState(
                  message:
                      _profileCtrl.errorMessage ?? 'Profile is unavailable.',
                  onRetry: _refreshProfile,
                );
              }

              return RefreshIndicator(
                backgroundColor: TiermetryColors.surface,
                color: TiermetryColors.accentNeonGreen,
                edgeOffset: topPad + TiermetrySpacing.topBarHeight,
                onRefresh: _refreshProfile,
                child: _ProfileContentView(
                  controller: _scrollController,
                  profile: _profileCtrl.profile!,
                ),
              );
            },
          ),
          const ScrollGradientOverlay(),
        ],
      ),
    );
  }
}

class _ProfileContentView extends StatefulWidget {
  final ScrollController controller;
  final ProfileEntity profile;

  const _ProfileContentView({required this.controller, required this.profile});

  @override
  State<_ProfileContentView> createState() => _ProfileContentViewState();
}

class _ProfileContentViewState extends State<_ProfileContentView> {
  Future<void> _openAvatarPicker() async {
    final newId = await showAvatarSelectionSheet(
      context,
      currentAvatarId: widget.profile.avatarId,
    );
    if (newId == null || newId == widget.profile.avatarId || !mounted) return;

    try {
      await locator.profileCtrl.updateProfile(avatarId: newId);
      if (mounted) {
        AppIslandNotice.show(
          context,
          title: 'Avatar updated',
          tone: AppIslandNoticeTone.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppIslandNotice.show(
          context,
          title: 'Could not update avatar',
          message: e.toString().replaceFirst('Exception: ', ''),
          tone: AppIslandNoticeTone.error,
        );
      }
    }
  }

  void _openRoute(Widget screen) {
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final profile = locator.profileCtrl.profile ?? widget.profile;

    if (FeatureFlags.disableFinancialRewards) {
      return _buildContent(context, profile, null);
    }

    return ListenableBuilder(
      listenable: locator.loyaltyCtrl,
      builder: (context, _) {
        final loyaltyAccount = locator.loyaltyCtrl.account;
        if (loyaltyAccount == null) {
          return _buildContent(
            context,
            profile,
            null,
            loyaltyFallback: _LoyaltyUnavailableCard(
              isLoading: locator.loyaltyCtrl.isLoading,
              message: locator.loyaltyCtrl.errorMessage,
              onRetry: locator.loyaltyCtrl.refreshAll,
            ),
          );
        }
        final liveTiergies = loyaltyAccount.availableTiergies;
        final animatedWallet = profile.wallet.copyWith(
          balance: liveTiergies.toString(),
          earned: loyaltyAccount.totalEarnedTiergies.toString(),
        );

        return _buildContent(
          context,
          profile,
          loyaltyAccount,
          animatedWallet: animatedWallet,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ProfileEntity profile,
    LoyaltyAccountEntity? loyaltyAccount, {
    WalletEntity? animatedWallet,
    Widget? loyaltyFallback,
  }) {
    final topPad = MediaQuery.of(context).padding.top;
    const showRewards = !FeatureFlags.disableFinancialRewards;

    return CustomScrollView(
      controller: widget.controller,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              TiermetrySpacing.screenPadding,
              topPad +
                  TiermetrySpacing.topBarHeight +
                  TiermetrySpacing.sectionGap,
              TiermetrySpacing.screenPadding,
              TiermetrySpacing.lg,
            ),
            child: _ProfileHeaderCard(
              profile: profile,
              loyaltyAccount: loyaltyAccount,
              onImageTap: _openAvatarPicker,
              onEditTap: () => _openRoute(const AccountPrivacyScreen()),
            ),
          ),
        ),
        if (showRewards && loyaltyAccount == null && loyaltyFallback != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                TiermetrySpacing.screenPadding,
                TiermetrySpacing.sm,
                TiermetrySpacing.screenPadding,
                0,
              ),
              child: loyaltyFallback,
            ),
          ),
        if (showRewards &&
            loyaltyAccount != null &&
            animatedWallet != null) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                TiermetrySpacing.screenPadding,
                TiermetrySpacing.sm,
                TiermetrySpacing.screenPadding,
                0,
              ),
              child: WalletFlipCard(
                walletData: animatedWallet,
                pendingTiergies: loyaltyAccount.pendingTiergies,
                onEarnPressed: () => _openRoute(const ReferAndEarnScreen()),
                onRedeemPressed: () => _openRoute(const TransactionsScreen()),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                TiermetrySpacing.screenPadding,
                TiermetrySpacing.sm,
                TiermetrySpacing.screenPadding,
                0,
              ),
              child: TierAndBadgeCard(
                account: loyaltyAccount,
                onStatusTap: () => _openRoute(const RewardStoreScreen()),
              ),
            ),
          ),
        ],
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              TiermetrySpacing.screenPadding,
              TiermetrySpacing.xl,
              TiermetrySpacing.screenPadding,
              TiermetrySpacing.bottomSafeArea,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ('Settings').toUpperCase(),
                  style: TiermetryTypography.title(color: Colors.white),
                ),
                const SizedBox(height: TiermetrySpacing.headerToContent),
                const ProfileSettingsSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LoyaltyUnavailableCard extends StatelessWidget {
  const _LoyaltyUnavailableCard({
    required this.isLoading,
    required this.message,
    required this.onRetry,
  });

  final bool isLoading;
  final String? message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(TiermetrySpacing.lg),
      decoration: BoxDecoration(
        color: TiermetryColors.surfaceUnderlay,
        borderRadius: BorderRadius.circular(TiermetryRadii.lg),
      ),
      child:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  color: TiermetryColors.accentNeonGreen,
                ),
              )
              : Row(
                children: [
                  const Icon(
                    Icons.sync_problem_rounded,
                    color: TiermetryColors.accentNeonGreen,
                  ),
                  const SizedBox(width: TiermetrySpacing.md),
                  Expanded(
                    child: Text(
                      message ?? 'Your Tiergies and status are unavailable.',
                      style: TiermetryTypography.bodySmall(
                        color: TiermetryColors.textMuted,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onRetry,
                    tooltip: 'Retry rewards sync',
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  final ProfileEntity profile;
  final LoyaltyAccountEntity? loyaltyAccount;
  final VoidCallback onImageTap;
  final VoidCallback onEditTap;

  const _ProfileHeaderCard({
    required this.profile,
    required this.loyaltyAccount,
    required this.onImageTap,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final liveStatus = loyaltyAccount?.statusDisplayName ?? 'SYNCING STATUS';
    final rank =
        loyaltyAccount == null
            ? null
            : 'RANK ${loyaltyAccount!.status.rank + 1}';

    return Container(
      padding: const EdgeInsets.all(TiermetrySpacing.lg),
      decoration: BoxDecoration(
        color: TiermetryColors.surface,
        borderRadius: BorderRadius.circular(TiermetryRadii.lg),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileAvatar(
                avatarId: profile.avatarId,
                imagePath: profile.image ?? '',
                onTap: onImageTap,
              ),
              const SizedBox(width: TiermetrySpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            (profile.name).toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TiermetryTypography.display(
                              color: Colors.white,
                              fontSize: 26,
                              height: 1,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: onEditTap,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: TiermetryColors.surfaceElement,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              AmazingIconOutlined.edit,
                              size: 18,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      profile.username?.isNotEmpty == true
                          ? '@${profile.username}'
                          : 'Username not set',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TiermetryTypography.caption(
                        color: TiermetryColors.accentNeonGreen,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${profile.location} • Joined ${profile.joinedDate}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TiermetryTypography.caption(
                        color: Colors.white.withValues(alpha: 0.58),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: TiermetrySpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(TiermetrySpacing.md),
            decoration: BoxDecoration(
              color: TiermetryColors.surfaceUnderlay.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(TiermetryRadii.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: TiermetryColors.accentNeonGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        AmazingIconOutlined.crown,
                        size: 18,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: TiermetrySpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'YOUR STATUS',
                            style: TiermetryTypography.label(
                              color: TiermetryColors.textMuted,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            liveStatus,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TiermetryTypography.titleSmall(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (rank != null)
                      _MetaPill(
                        iconBuilder:
                            (size, color) => Icon(
                              AmazingIconOutlined.crown,
                              size: size,
                              color: color,
                            ),
                        label: rank,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final int avatarId;
  final String imagePath;
  final VoidCallback onTap;

  const _ProfileAvatar({
    required this.avatarId,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedId = AppAvatar.idFromAssetOrString(imagePath) ?? avatarId;
    final asset = AppAvatar.assetForId(resolvedId);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 92,
            height: 92,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: TiermetryColors.surfaceElement,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white12),
              image: DecorationImage(
                image: AssetImage(asset),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            right: 4,
            bottom: 4,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: TiermetryColors.accentNeonGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                AmazingIconOutlined.edit,
                size: 15,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final Widget Function(double, Color) iconBuilder;
  final String label;

  const _MetaPill({required this.iconBuilder, required this.label});

  @override
  Widget build(BuildContext context) {
    const color = Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: TiermetryColors.surfaceElement,
        borderRadius: BorderRadius.circular(TiermetryRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconBuilder(13.0, color.withValues(alpha: 0.62)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TiermetryTypography.caption(
              color: color.withValues(alpha: 0.74),
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// Kept as a shared private visual primitive for the profile shimmer transition.
// ignore: unused_element
class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;

  const _ProfileStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: TiermetryColors.surfaceElement,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              (value).toUpperCase(),
              style: TiermetryTypography.title(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TiermetryTypography.caption(
                color: Colors.white.withValues(alpha: 0.48),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Kept for when live account activity counts are added; it is intentionally
// hidden until its values come from the server rather than placeholder zeroes.
// ignore: unused_element
class _QuickActionsRow extends StatelessWidget {
  final List<_QuickAction> actions;

  const _QuickActionsRow({required this.actions});

  @override
  Widget build(BuildContext context) {
    final titleGroup = AutoSizeGroup();
    final subtitleGroup = AutoSizeGroup();
    final valueGroup = AutoSizeGroup();

    return Row(
      children:
          actions
              .map(
                (action) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: action == actions.last ? 0 : TiermetrySpacing.sm,
                    ),
                    child: _QuickActionTile(
                      action: action,
                      titleGroup: titleGroup,
                      subtitleGroup: subtitleGroup,
                      valueGroup: valueGroup,
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final _QuickAction action;
  final AutoSizeGroup titleGroup;
  final AutoSizeGroup subtitleGroup;
  final AutoSizeGroup valueGroup;

  const _QuickActionTile({
    required this.action,
    required this.titleGroup,
    required this.subtitleGroup,
    required this.valueGroup,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: TiermetryColors.surface,
          borderRadius: BorderRadius.circular(TiermetryRadii.md),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.24),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              AutoSizeText(
                action.title,
                maxLines: 1,
                group: titleGroup,
                minFontSize: 8,
                style: TiermetryTypography.title(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ).copyWith(letterSpacing: 0),
              ),

              const SizedBox(height: 16),

              // Bottom Section
              LayoutBuilder(
                builder: (context, constraints) {
                  final iconContainerSize = (constraints.maxWidth * 0.4).clamp(
                    24.0,
                    44.0,
                  );
                  final iconInnerSize = (iconContainerSize * 0.55).clamp(
                    14.0,
                    24.0,
                  );

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Glass Circle Icon
                      Container(
                        width: iconContainerSize,
                        height: iconContainerSize,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: TiermetryColors.accentNeonGreen,
                        ),
                        child: Center(
                          child: action.iconBuilder(
                            iconInnerSize,
                            Colors.black.withAlpha(220),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Active + Value
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AutoSizeText(
                              action.subtitle,
                              group: subtitleGroup,
                              maxLines: 1,
                              minFontSize: 6,
                              style: TiermetryTypography.caption(
                                color: Colors.white.withValues(alpha: 0.52),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            AutoSizeText(
                              action.value,
                              group: valueGroup,
                              maxLines: 1,
                              minFontSize: 10,
                              style: TiermetryTypography.title(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction {
  final String title;
  final String subtitle;
  final String value;
  final Widget Function(double, Color) iconBuilder;
  final VoidCallback onTap;

  const _QuickAction({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.iconBuilder,
    required this.onTap,
  });
}

class _ProfileShimmerPlaceholder extends StatelessWidget {
  const _ProfileShimmerPlaceholder();

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Shimmer.fromColors(
      baseColor: Colors.grey[900]!,
      highlightColor: Colors.grey[800]!,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          TiermetrySpacing.screenPadding,
          topPad + TiermetrySpacing.topBarHeight + TiermetrySpacing.sectionGap,
          TiermetrySpacing.screenPadding,
          TiermetrySpacing.bottomSafeArea,
        ),
        children: [
          Container(
            height: 216,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(TiermetryRadii.md),
            ),
          ),
          const SizedBox(height: TiermetrySpacing.lg),
          Row(
            children: List.generate(
              3,
              (index) => Expanded(
                child: Container(
                  height: 140, // Match the new QuickActionTile height
                  margin: EdgeInsets.only(
                    right: index == 2 ? 0 : TiermetrySpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(TiermetryRadii.md),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: TiermetrySpacing.sectionGap),
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(TiermetryRadii.md),
              ),
            ),
          ),
          const SizedBox(height: TiermetrySpacing.xl),
          Container(
            height: 280,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(TiermetryRadii.md),
            ),
          ),
        ],
      ),
    );
  }
}
