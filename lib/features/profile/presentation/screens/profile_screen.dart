import 'dart:async';
import 'dart:io';

import 'package:amazing_icons/bulk.dart';
import 'package:amazing_icons/outlined.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/mixins/refresh_rate_mixin.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_error_state.dart';
import 'package:tiermetry/features/home/presentation/widgets/home_backdrop.dart';
import 'package:tiermetry/features/home/presentation/widgets/scroll_gradient_overlay.dart';
import 'package:tiermetry/features/wallet/presentation/screens/reward_store_screen.dart';
import 'package:tiermetry/features/wallet/presentation/widgets/wallet_flip_card.dart';

import '../../../../features/booking/presentation/screens/booking_screen.dart';
import '../../../../features/event/presentation/screens/my_events_screen.dart';
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

    final topPad = MediaQuery.of(context).padding.top;
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
              topPad + TiermetrySpacing.topBarHeight + TiermetrySpacing.sectionGap,
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
                  title: 'Bookings',
                  subtitle: 'Active',
                  value: '12',
                  iconBuilder: (size, color) => AmazingIconBulk.bookmark(size: size, color: color),
                  onTap: () => _openRoute(const BookingScreen()),
                ),
                _QuickAction(
                  title: 'Events',
                  subtitle: 'Active',
                  value: '4',
                  iconBuilder: (size, color) => AmazingIconBulk.ticket(size: size, color: color),
                  onTap: () => _openRoute(const MyEventsScreen()),
                ),
                _QuickAction(
                  title: 'Transactions',
                  subtitle: 'Active',
                  value: '28',
                  iconBuilder: (size, color) => AmazingIconBulk.wallet(size: size, color: color),
                  onTap: () => _openRoute(const TransactionsScreen()),
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
              onRedeemPressed: () => _openRoute(const RewardStoreScreen()),
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
                Text(('Settings').toUpperCase(),
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
        borderRadius: BorderRadius.circular(TiermetryRadii.md),
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
                          child: Text((profile.name).toUpperCase(),
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
                          iconBuilder: (size, color) => Icon(AmazingIconOutlined.star, size: size, color: color),
                          label: profile.level,
                          isPrimary: true,
                        ),
                        if (profile.age != null)
                          _MetaPill(
                            iconBuilder: (size, color) => Icon(AmazingIconOutlined.profile, size: size, color: color),
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
          const Row(
            children: [
              Expanded(
                child: _ProfileStat(value: '12th', label: 'Leaderboard'),
              ),
              SizedBox(width: TiermetrySpacing.sm),
              Expanded(
                child: _ProfileStat(value: '24', label: 'Favourites'),
              ),
              SizedBox(width: TiermetrySpacing.sm),
              Expanded(
                child: _ProfileStat(value: '38', label: 'Check-ins'),
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
            alignment: Alignment.center,
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
                    ? AmazingIconBulk.profile(
                        size: 42,
                        color: Colors.white54,
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
                AmazingIconOutlined.camera,
                size: 15,
                color: Colors.black,
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
  final Widget Function(double, Color) iconBuilder;
  final String label;
  final bool isPrimary;

  const _MetaPill({
    required this.iconBuilder,
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
          iconBuilder(
            13.0,
            color.withValues(alpha: isPrimary ? 1 : 0.62),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text((value).toUpperCase(),
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
        height: 140, // Increased height for the image layout
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
              Text(
                action.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TiermetryTypography.title(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ).copyWith(letterSpacing: -0.3),
              ),
              
              const Spacer(),
              
              // Bottom Section
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Glass Circle Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: TiermetryColors.accentNeonGreen,
                    ),
                    child: Center(
                      child: action.iconBuilder(24.0, Colors.black.withAlpha(220)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Active + Value
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          action.subtitle,
                          style: TiermetryTypography.caption(
                            color: Colors.white.withValues(alpha: 0.52),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          action.value,
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
