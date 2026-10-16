import 'package:flutter/material.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/widgets/scroll_fade_overlay.dart';
import 'package:tiermetry/core/widgets/shimmer_loading.dart';
import 'package:tiermetry/features/skill/domain/entities/skill_entity.dart';
import 'package:tiermetry/features/skill/presentation/widgets/featured_skill_morph_card.dart';

class FeaturedSkillsSection extends StatefulWidget {
  final List<SkillEntity> skills;
  final bool isLoading;

  const FeaturedSkillsSection({
    required this.skills,
    required this.isLoading,
    super.key,
  });

  @override
  State<FeaturedSkillsSection> createState() => _FeaturedSkillsSectionState();
}

class _FeaturedSkillsSectionState extends State<FeaturedSkillsSection> {
  late ScrollController _scrollController;
  final ValueNotifier<double> _rightFadeOpacity = ValueNotifier<double>(1);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_updateFadeOpacity);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateFadeOpacity();
    });
  }

  @override
  void didUpdateWidget(covariant FeaturedSkillsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.skills.length != widget.skills.length ||
        oldWidget.isLoading != widget.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateFadeOpacity();
      });
    }
  }

  void _updateFadeOpacity() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final double remaining = position.maxScrollExtent - position.pixels;
    final double rightOp = (remaining / 50).clamp(0, 1);
    if ((_rightFadeOpacity.value - rightOp).abs() > 0.03) {
      _rightFadeOpacity.value = rightOp;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _rightFadeOpacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 340, // Increased slightly to ensure full text layout fits
      child:
          widget.isLoading
              ? const ShimmerLoadingList(
                itemWidth: 280,
                itemCount: 2,
                animate: false,
              )
              : widget.skills.isEmpty
              ? const Center(
                child: Text(
                  'No skills found.',
                  style: TextStyle(color: Colors.white70),
                ),
              )
              : Stack(
                clipBehavior: Clip.none,
                children: [
                  ListView.separated(
                    addRepaintBoundaries: false,
                    cacheExtent: 280,
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    padding: TiermetrySpacing.listPadding,
                    itemCount: widget.skills.length,
                    separatorBuilder:
                        (_, __) =>
                            const SizedBox(width: TiermetrySpacing.cardGap),
                    itemBuilder: (_, index) {
                      return FeaturedSkillMorphCard(
                        skill: widget.skills[index],
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
  }
}
