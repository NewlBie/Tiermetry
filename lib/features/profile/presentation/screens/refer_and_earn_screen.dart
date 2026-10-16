import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_island_notice.dart';
import 'package:tiermetry/core/widgets/app_surface.dart';
import 'package:tiermetry/features/wallet/domain/entities/social_connection_entity.dart';
import 'package:tiermetry/features/wallet/presentation/widgets/friends_card.dart';

/// The referral surface only renders values supplied by the trusted referral
/// RPC. It never estimates a reward or invents an invite history on device.
class ReferAndEarnScreen extends StatefulWidget {
  final ReferralCardEntity? previewReferralCard;
  final List<FriendProfileEntity>? previewFriends;

  const ReferAndEarnScreen({
    super.key,
    this.previewReferralCard,
    this.previewFriends,
  });

  @override
  State<ReferAndEarnScreen> createState() => _ReferAndEarnScreenState();
}

class _ReferAndEarnScreenState extends State<ReferAndEarnScreen> {
  bool _loading = false;
  String? _error;

  bool get _isPreview => widget.previewReferralCard != null;

  @override
  void initState() {
    super.initState();
    if (!_isPreview) unawaited(_load());
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      await Future.wait([
        locator.loyaltyCtrl.loadReferralCard(),
        locator.loyaltyCtrl.loadFriends(),
      ]);
    } catch (_) {
      _error = 'Could not load your referral details.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _copy(String value, String confirmation) async {
    await Clipboard.setData(ClipboardData(text: value));
    await HapticFeedback.lightImpact();
    if (!mounted) return;
    AppIslandNotice.show(
      context,
      title: confirmation,
      tone: AppIslandNoticeTone.success,
    );
  }

  Future<void> _share(ReferralCardEntity referral) {
    return Share.share(
      'Join me on HOMIES. Use code ${referral.code}: ${referral.link}',
      subject: 'Join my HOMIES crew',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isPreview) {
      return _ReferralContent(
        referral: widget.previewReferralCard!,
        friends: widget.previewFriends ?? const [],
        onCopy: _copy,
        onShare: _share,
        onSearch: (_) async => const [],
        onRequestFriend: (_) async {},
      );
    }

    return ListenableBuilder(
      listenable: locator.loyaltyCtrl,
      builder: (context, _) {
        final referral = locator.loyaltyCtrl.referralCard;
        if (_loading && referral == null) return const _ReferralLoading();
        if (referral == null) {
          return _ReferralUnavailable(error: _error, onRetry: _load);
        }
        return _ReferralContent(
          referral: referral,
          friends: locator.loyaltyCtrl.friends,
          onCopy: _copy,
          onShare: _share,
          onSearch: locator.loyaltyCtrl.searchFriendProfiles,
          onRequestFriend: locator.loyaltyCtrl.requestFriendship,
          onAcceptFriend: locator.loyaltyCtrl.acceptFriendship,
          onDeclineFriend: locator.loyaltyCtrl.declineFriendship,
          onRemoveFriend: locator.loyaltyCtrl.removeFriendship,
        );
      },
    );
  }
}

class _ReferralContent extends StatelessWidget {
  final ReferralCardEntity referral;
  final List<FriendProfileEntity> friends;
  final Future<void> Function(String value, String confirmation) onCopy;
  final Future<void> Function(ReferralCardEntity referral) onShare;
  final Future<List<FriendProfileEntity>> Function(String query) onSearch;
  final Future<void> Function(String userId) onRequestFriend;
  final Future<void> Function(String friendshipId)? onAcceptFriend;
  final Future<void> Function(String friendshipId)? onDeclineFriend;
  final Future<void> Function(String friendshipId)? onRemoveFriend;

  const _ReferralContent({
    required this.referral,
    required this.friends,
    required this.onCopy,
    required this.onShare,
    required this.onSearch,
    required this.onRequestFriend,
    this.onAcceptFriend,
    this.onDeclineFriend,
    this.onRemoveFriend,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TiermetryColors.background,
      appBar: AppBar(
        title: const Text('Invite friends'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          TiermetrySpacing.screenPadding,
          TiermetrySpacing.md,
          TiermetrySpacing.screenPadding,
          TiermetrySpacing.bottomSafeArea,
        ),
        children: [
          Text(
            'Bring your crew',
            style: TiermetryTypography.title(color: Colors.white),
          ),
          const SizedBox(height: TiermetrySpacing.xs),
          Text(
            'Share your personal code with friends who are not on HOMIES yet.',
            style: TiermetryTypography.bodySmall(
              color: TiermetryColors.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: TiermetrySpacing.xl),
          AppSurface(
            padding: const EdgeInsets.all(TiermetrySpacing.lg),
            color: TiermetryColors.surfaceUnderlay,
            borderRadius: TiermetryRadii.lg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR REFERRAL CODE',
                  style: TiermetryTypography.label(
                    color: TiermetryColors.textMuted,
                  ),
                ),
                const SizedBox(height: TiermetrySpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        referral.code,
                        style: TiermetryTypography.display(
                          color: Colors.white,
                          fontSize: 28,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy referral code',
                      onPressed:
                          () => onCopy(referral.code, 'Referral code copied.'),
                      icon: const Icon(Icons.copy_rounded),
                    ),
                    IconButton(
                      tooltip: 'Share invite',
                      onPressed: () => onShare(referral),
                      icon: const Icon(Icons.ios_share_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: TiermetrySpacing.md),
                _CopyRow(
                  value: referral.link,
                  onCopy: () => onCopy(referral.link, 'Invite link copied.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: TiermetrySpacing.md),
          _MetricRow(
            invited: referral.invitedCount,
            completed: referral.completedCount,
          ),
          const SizedBox(height: TiermetrySpacing.md),
          AppSurface(
            padding: const EdgeInsets.all(TiermetrySpacing.lg),
            color: TiermetryColors.surfaceUnderlay,
            borderRadius: TiermetryRadii.lg,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  color: TiermetryColors.accentNeonGreen,
                ),
                const SizedBox(width: TiermetrySpacing.md),
                Expanded(
                  child: Text(
                    referral.rewardPolicy,
                    style: TiermetryTypography.bodySmall(
                      color: TiermetryColors.textMuted,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TiermetrySpacing.xl),
          FriendsCard(
            friends: friends,
            referralCode: referral.code,
            referralLink: referral.link,
            onSearch: onSearch,
            onRequestFriend: onRequestFriend,
            onAcceptFriend: onAcceptFriend,
            onDeclineFriend: onDeclineFriend,
            onRemoveFriend: onRemoveFriend,
          ),
        ],
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  final String value;
  final VoidCallback onCopy;

  const _CopyRow({required this.value, required this.onCopy});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(left: 12),
    decoration: BoxDecoration(
      color: TiermetryColors.surfaceElement,
      borderRadius: BorderRadius.circular(TiermetryRadii.md),
    ),
    child: Row(
      children: [
        const Icon(Icons.link_rounded, size: 18, color: Colors.white70),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TiermetryTypography.bodySmall(color: Colors.white70),
          ),
        ),
        IconButton(
          tooltip: 'Copy invite link',
          onPressed: onCopy,
          icon: const Icon(Icons.copy_rounded, size: 18),
        ),
      ],
    ),
  );
}

class _MetricRow extends StatelessWidget {
  final int invited;
  final int completed;

  const _MetricRow({required this.invited, required this.completed});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: _metric('$invited', 'INVITED')),
      const SizedBox(width: TiermetrySpacing.sm),
      Expanded(child: _metric('$completed', 'COMPLETED')),
    ],
  );

  Widget _metric(String value, String label) => AppSurface(
    padding: const EdgeInsets.all(TiermetrySpacing.md),
    color: TiermetryColors.surfaceUnderlay,
    borderRadius: TiermetryRadii.md,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: TiermetryTypography.title(color: Colors.white)),
        const SizedBox(height: 2),
        Text(
          label,
          style: TiermetryTypography.label(color: TiermetryColors.textMuted),
        ),
      ],
    ),
  );
}

class _ReferralLoading extends StatelessWidget {
  const _ReferralLoading();

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: TiermetryColors.background,
    body: Center(child: CircularProgressIndicator()),
  );
}

class _ReferralUnavailable extends StatelessWidget {
  final String? error;
  final Future<void> Function() onRetry;

  const _ReferralUnavailable({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: TiermetryColors.background,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(TiermetrySpacing.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              error ?? 'Your referral details are unavailable.',
              textAlign: TextAlign.center,
              style: TiermetryTypography.bodySmall(
                color: TiermetryColors.textMuted,
              ),
            ),
            const SizedBox(height: TiermetrySpacing.md),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    ),
  );
}
