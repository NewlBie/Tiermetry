import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/mixins/refresh_rate_mixin.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/features/home/presentation/widgets/home_backdrop.dart';
import 'package:tiermetry/features/home/presentation/widgets/scroll_gradient_overlay.dart';
import 'package:tiermetry/features/wallet/presentation/widgets/wallet_flip_card.dart';

import '../../domain/entities/profile_entity.dart';
import '../widgets/profile_settings_section.dart';
import '../widgets/tier_and_badge_card.dart';
import 'account_privacy_screen.dart';
import 'refer_and_earn_screen.dart';
import 'transactions_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with RefreshRateMixin {
  final _profileCtrl = locator.profileCtrl;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    Future.microtask(() {
      if (_profileCtrl.profile == null) {
        _profileCtrl.loadProfile();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshProfile() => _profileCtrl.loadProfile();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TiermetryColors.background,
      body: Stack(
        children: [
          const HomeBackdrop(),
          SafeArea(
            bottom: false,
            child: ListenableBuilder(
              listenable: _profileCtrl,
              builder: (context, child) {
                if (_profileCtrl.isLoading && _profileCtrl.profile == null) {
                  return const _ProfileShimmerPlaceholder();
                }

                if (_profileCtrl.profile == null) {
                  return _ProfileErrorState(
                    message:
                        _profileCtrl.errorMessage ?? 'Profile is unavailable.',
                    onRetry: _refreshProfile,
                  );
                }

                return RefreshIndicator(
                  backgroundColor: TiermetryColors.surface,
                  color: TiermetryColors.accentNeonGreen,
                  onRefresh: _refreshProfile,
                  child: _ProfileContentView(
                    controller: _scrollController,
                    profile: _profileCtrl.profile!,
                  ),
                );
              },
            ),
          ),
          ScrollGradientOverlay(scrollController: _scrollController),
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
  File? _selectedImage;
  String _animatedBalanceText = '';
  Timer? _balanceTimer;

  @override
  void initState() {
    super.initState();
    _startBalanceAnimation();
  }

  @override
  void didUpdateWidget(covariant _ProfileContentView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.tiergies != widget.profile.tiergies) {
      _startBalanceAnimation();
    }
  }

  @override
  void dispose() {
    _balanceTimer?.cancel();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (pickedFile == null || !mounted) return;
    setState(() => _selectedImage = File(pickedFile.path));
  }

  void _startBalanceAnimation() {
    const frameDuration = Duration(milliseconds: 33);
    const totalDuration = Duration(milliseconds: 500);
    const scrambleChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final target = widget.profile.tiergies.toInt().toString();
    final startedAt = DateTime.now();

    _balanceTimer?.cancel();
    _animatedBalanceText = target;

    _balanceTimer = Timer.periodic(frameDuration, (timer) {
      final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
      final percent = elapsedMs / totalDuration.inMilliseconds;
      final revealCount =
          (target.length * percent).clamp(0, target.length).floor();

      final scrambled =
          List.generate(target.length, (index) {
            if (index < revealCount) return target[index];
            final charIndex =
                (DateTime.now().microsecondsSinceEpoch + index * 17) %
                scrambleChars.length;
            return scrambleChars[charIndex];
          }).join();

      if (mounted) setState(() => _animatedBalanceText = scrambled);

      if (revealCount >= target.length) {
        timer.cancel();
        if (mounted) setState(() => _animatedBalanceText = target);
      }
    });
  }

  void _openRoute(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final animatedWallet = profile.wallet.copyWith(
      balance:
          _animatedBalanceText.isEmpty
              ? profile.tiergies.toInt().toString()
              : _animatedBalanceText,
    );

    return CustomScrollView(
      controller: widget.controller,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              TiermetrySpacing.screenPadding,
              92,
              TiermetrySpacing.screenPadding,
              TiermetrySpacing.lg,
            ),
            child: _ProfileHeaderCard(
              profile: profile,
              selectedImage: _selectedImage,
              onImageTap: _pickImage,
              onEditTap: () => _openRoute(const AccountPrivacyScreen()),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: TiermetrySpacing.pagePadding,
            child: _QuickActionsRow(
              actions: [
                _QuickAction(
                  title: 'Wallet',
                  subtitle: '${profile.tiergies.toInt()} pts',
                  icon: Icons.account_balance_wallet_rounded,
                  onTap: () => _openRoute(const TransactionsScreen()),
                ),
                _QuickAction(
                  title: 'Rewards',
                  subtitle:
                      '${profile.openedBadges}/${profile.totalBadges} badges',
                  icon: Icons.emoji_events_rounded,
                  onTap: () => _openRoute(const ReferAndEarnScreen()),
                ),
                _QuickAction(
                  title: 'Account',
                  subtitle: 'Privacy',
                  icon: Icons.verified_user_rounded,
                  onTap: () => _openRoute(const AccountPrivacyScreen()),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              TiermetrySpacing.screenPadding,
              TiermetrySpacing.sectionGap,
              TiermetrySpacing.screenPadding,
              0,
            ),
            child: WalletFlipCard(
              walletData: animatedWallet,
              onEarnPressed: () => _openRoute(const ReferAndEarnScreen()),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              TiermetrySpacing.screenPadding,
              TiermetrySpacing.xl,
              TiermetrySpacing.screenPadding,
              0,
            ),
            child: TierAndBadgeCard(
              tierName: profile.tierName,
              tierProgress: profile.tierProgress.clamp(0, 1),
              openedBadges: profile.openedBadges,
              totalBadges: profile.totalBadges,
              totalUniqueBadges: profile.totalBadges,
              badgeTitles: profile.badges.map((badge) => badge.title).toList(),
              badgeColors: profile.badges.map((badge) => badge.color).toList(),
            ),
          ),
        ),
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
                  'Settings',
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

class _ProfileHeaderCard extends StatelessWidget {
  final ProfileEntity profile;
  final File? selectedImage;
  final VoidCallback onImageTap;
  final VoidCallback onEditTap;

  const _ProfileHeaderCard({
    required this.profile,
    required this.selectedImage,
    required this.onImageTap,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TiermetryColors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileAvatar(
                imagePath: profile.image ?? '',
                selectedImage: selectedImage,
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
                            profile.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TiermetryTypography.display(
                              color: Colors.white,
                              fontSize: 28,
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
                              Icons.edit_rounded,
                              color: Colors.white70,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
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
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: TiermetrySpacing.sm,
                      runSpacing: TiermetrySpacing.sm,
                      children: [
                        _MetaPill(
                          icon: Icons.military_tech_rounded,
                          label: profile.level,
                          isPrimary: true,
                        ),
                        if (profile.age != null)
                          _MetaPill(
                            icon: Icons.cake_outlined,
                            label: '${profile.age}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: TiermetrySpacing.lg),
          Row(
            children: [
              Expanded(
                child: _ProfileStat(value: profile.tierName, label: 'Tier'),
              ),
              const SizedBox(width: TiermetrySpacing.sm),
              Expanded(
                child: _ProfileStat(
                  value: profile.tiergies.toInt().toString(),
                  label: 'Tiergies',
                ),
              ),
              const SizedBox(width: TiermetrySpacing.sm),
              Expanded(
                child: _ProfileStat(
                  value: '${profile.openedBadges}',
                  label: 'Badges',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String imagePath;
  final File? selectedImage;
  final VoidCallback onTap;

  const _ProfileAvatar({
    required this.imagePath,
    required this.selectedImage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageProvider = _resolveImageProvider();

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: TiermetryColors.surfaceElement,
              borderRadius: BorderRadius.circular(24),
              image:
                  imageProvider == null
                      ? null
                      : DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                      ),
            ),
            child:
                imageProvider == null
                    ? const Icon(
                      Icons.person_rounded,
                      color: Colors.white54,
                      size: 42,
                    )
                    : null,
          ),
          Positioned(
            right: 6,
            bottom: 6,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: TiermetryColors.accentNeonGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.black,
                size: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider? _resolveImageProvider() {
    if (selectedImage != null) {
      return FileImage(selectedImage!);
    }

    final trimmedPath = imagePath.trim();
    if (trimmedPath.isEmpty) return null;

    if (trimmedPath.startsWith('http://') ||
        trimmedPath.startsWith('https://')) {
      return NetworkImage(trimmedPath);
    }

    return AssetImage(trimmedPath);
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;

  const _MetaPill({
    required this.icon,
    required this.label,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPrimary ? TiermetryColors.accentNeonGreen : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:
            isPrimary
                ? color.withValues(alpha: 0.15)
                : TiermetryColors.surfaceElement,
        borderRadius: BorderRadius.circular(TiermetryRadii.pill),
        border: Border.all(
          color:
              isPrimary
                  ? color.withValues(alpha: 0.28)
                  : Colors.white.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color.withValues(alpha: isPrimary ? 1 : 0.62),
            size: 13,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TiermetryTypography.caption(
              color: color.withValues(alpha: isPrimary ? 1 : 0.74),
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

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
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TiermetryTypography.title(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TiermetryTypography.caption(
              color: Colors.white.withValues(alpha: 0.48),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  final List<_QuickAction> actions;

  const _QuickActionsRow({required this.actions});

  @override
  Widget build(BuildContext context) {
    return Row(
      children:
          actions
              .map(
                (action) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: action == actions.last ? 0 : TiermetrySpacing.sm,
                    ),
                    child: _QuickActionTile(action: action),
                  ),
                ),
              )
              .toList(),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final _QuickAction action;

  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        height: 112,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TiermetryColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.24),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: TiermetryColors.accentNeonGreen,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                action.icon,
                color: Colors.black.withAlpha(220),
                size: 19,
              ),
            ),
            const Spacer(),
            Text(
              action.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TiermetryTypography.title(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              action.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TiermetryTypography.caption(
                color: Colors.white.withValues(alpha: 0.52),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}

class _ProfileErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ProfileErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: TiermetrySpacing.pagePadding,
        child: Container(
          padding: const EdgeInsets.all(TiermetrySpacing.xl),
          decoration: BoxDecoration(
            color: TiermetryColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: Colors.white38,
                size: 40,
              ),
              const SizedBox(height: TiermetrySpacing.md),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TiermetryTypography.title(
                  color: Colors.white,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: TiermetrySpacing.lg),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TiermetryColors.accentNeonGreen,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileShimmerPlaceholder extends StatelessWidget {
  const _ProfileShimmerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[900]!,
      highlightColor: Colors.grey[800]!,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          TiermetrySpacing.screenPadding,
          92,
          TiermetrySpacing.screenPadding,
          TiermetrySpacing.bottomSafeArea,
        ),
        children: [
          Container(
            height: 216,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          const SizedBox(height: TiermetrySpacing.lg),
          Row(
            children: List.generate(
              3,
              (index) => Expanded(
                child: Container(
                  height: 112,
                  margin: EdgeInsets.only(
                    right: index == 2 ? 0 : TiermetrySpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(22),
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
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
          const SizedBox(height: TiermetrySpacing.xl),
          Container(
            height: 280,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(32),
            ),
          ),
        ],
      ),
    );
  }
}
