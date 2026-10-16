import 'package:flutter/material.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/widgets/scroll_fade_overlay.dart';
import 'package:tiermetry/core/widgets/shimmer_loading.dart';
import 'package:tiermetry/features/event/domain/entities/event_entity.dart';
import 'package:tiermetry/features/event/presentation/widgets/upcoming_event_card.dart';

class UpcomingEventsSection extends StatefulWidget {
  final List<EventEntity> events;
  final bool isLoading;
  final double cardWidth;
  final double sectionHeight;
  final Widget Function(BuildContext, EventEntity)? cardBuilder;

  const UpcomingEventsSection({
    required this.events,
    required this.isLoading,
    this.cardWidth = 225,
    this.sectionHeight = 300,
    this.cardBuilder,
    super.key,
  });

  @override
  State<UpcomingEventsSection> createState() => _UpcomingEventsSectionState();
}

class _UpcomingEventsSectionState extends State<UpcomingEventsSection> {
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
  void didUpdateWidget(covariant UpcomingEventsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.events.length != widget.events.length ||
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
      height: widget.sectionHeight,
      child:
          widget.isLoading
              ? ShimmerLoadingList(
                itemWidth: widget.cardWidth,
                itemCount: 1,
                animate: false,
              )
              : widget.events.isEmpty
              ? const Center(
                child: Text(
                  'No events found.',
                  style: TextStyle(color: Colors.white70),
                ),
              )
              : Stack(
                children: [
                  ListView.separated(
                    addRepaintBoundaries: false,
                    cacheExtent: 220,
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    padding: TiermetrySpacing.listPadding,
                    itemCount: widget.events.length,
                    separatorBuilder:
                        (_, __) =>
                            const SizedBox(width: TiermetrySpacing.cardGap),
                    itemBuilder: (_, index) {
                      return SizedBox(
                        width: widget.cardWidth,
                        child:
                            widget.cardBuilder != null
                                ? widget.cardBuilder!(
                                  context,
                                  widget.events[index],
                                )
                                : UpcomingEventCard(
                                  event: widget.events[index],
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
  }
}
