import 'package:flutter/material.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/scroll_fade_overlay.dart';
import 'package:tiermetry/core/widgets/section_header.dart';
import 'package:tiermetry/features/community/domain/entities/community_entity.dart';
import 'package:tiermetry/features/community/presentation/screens/community_details_screen.dart';
import 'package:tiermetry/features/community/presentation/screens/community_hub_screen.dart';
import 'package:tiermetry/features/community/presentation/widgets/community_card.dart';

/// Nearby user-created communities. The previous hardcoded activity shelf has
/// intentionally been replaced with server-backed community discovery.
class LiveAroundYouSection extends StatefulWidget {
  const LiveAroundYouSection({super.key});

  @override
  State<LiveAroundYouSection> createState() => _LiveAroundYouSectionState();
}

class _LiveAroundYouSectionState extends State<LiveAroundYouSection> {
  final _scrollController = ScrollController();
  final _rightFadeOpacity = ValueNotifier<double>(1);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateFade);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_updateFade)
      ..dispose();
    _rightFadeOpacity.dispose();
    super.dispose();
  }

  void _updateFade() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final remaining = position.maxScrollExtent - position.pixels;
    final opacity = (remaining / 50).clamp(0, 1).toDouble();
    if ((_rightFadeOpacity.value - opacity).abs() > 0.03) {
      _rightFadeOpacity.value = opacity;
    }
  }

  Future<void> _openHub() async {
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(builder: (_) => const CommunityHubScreen()),
    );
    await locator.communityCtrl.loadCommunities(
      city: locator.locationCtrl.selectedCity,
    );
  }

  Future<void> _openCommunity(CommunityEntity community) async {
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CommunityDetailsScreen(community: community),
      ),
    );
    await locator.communityCtrl.loadCommunities(
      city: locator.locationCtrl.selectedCity,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: TiermetrySpacing.pagePadding,
          child: SectionHeader(
            title: 'Live around you',
            viewMoreText: 'See all',
            onViewMore: _openHub,
          ),
        ),
        const SizedBox(height: TiermetrySpacing.headerToContent),
        ListenableBuilder(
          listenable: locator.communityCtrl,
          builder: (context, _) {
            final ctrl = locator.communityCtrl;
            if (ctrl.isLoading && ctrl.communities.isEmpty) {
              return const _CommunityShelfLoading();
            }
            if (ctrl.communities.isEmpty) {
              return _CommunityStartCard(
                hasError: ctrl.error != null,
                onPressed: _openHub,
              );
            }
            final communities = ctrl.communities
                .take(8)
                .toList(growable: false);
            return SizedBox(
              height: 216,
              child: Stack(
                children: [
                  ListView.separated(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: TiermetrySpacing.pagePadding,
                    itemCount: communities.length,
                    separatorBuilder:
                        (_, __) =>
                            const SizedBox(width: TiermetrySpacing.cardGap),
                    itemBuilder: (context, index) {
                      final community = communities[index];
                      return RepaintBoundary(
                        child: CommunityCard(
                          community: community,
                          width: 164,
                          onTap: () => _openCommunity(community),
                        ),
                      );
                    },
                  ),
                  ValueListenableBuilder<double>(
                    valueListenable: _rightFadeOpacity,
                    builder:
                        (_, opacity, __) => ScrollFadeOverlay(opacity: opacity),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CommunityStartCard extends StatelessWidget {
  final bool hasError;
  final VoidCallback onPressed;

  const _CommunityStartCard({required this.hasError, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: TiermetrySpacing.pagePadding,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(TiermetryRadii.md),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: TiermetryColors.surfaceElement,
            borderRadius: BorderRadius.circular(TiermetryRadii.md),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: TiermetryColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasError
                      ? Icons.cloud_off_rounded
                      : Icons.diversity_3_rounded,
                  color: TiermetryColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasError
                          ? 'COULDN’T LOAD NEARBY COMMUNITIES'
                          : 'YOUR NEXT CREW COULD BE HERE',
                      style: TiermetryTypography.titleSmall(
                        color: TiermetryColors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasError
                          ? 'Check your connection, then tap to try again.'
                          : 'Find local groups—or start one for free.',
                      style: TiermetryTypography.bodySmall(
                        color: TiermetryColors.textMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: TiermetryColors.textMuted,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommunityShelfLoading extends StatelessWidget {
  const _CommunityShelfLoading();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 216,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: TiermetrySpacing.pagePadding,
        itemCount: 2,
        separatorBuilder:
            (_, __) => const SizedBox(width: TiermetrySpacing.cardGap),
        itemBuilder:
            (_, __) => Container(
              width: 164,
              decoration: BoxDecoration(
                color: TiermetryColors.surface,
                borderRadius: BorderRadius.circular(TiermetryRadii.md),
              ),
            ),
      ),
    );
  }
}
