import 'package:flutter/material.dart';

import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/features/event/domain/entities/event_entity.dart';
import 'package:tiermetry/features/event/presentation/widgets/upcoming_event_card.dart';
import 'package:tiermetry/core/widgets/animated_list_item.dart';
import 'package:tiermetry/core/widgets/shimmer_loading.dart';

class UpcomingEventsSection extends StatefulWidget {
  final List<EventEntity> events;
  final bool isLoading;

  const UpcomingEventsSection({
    required this.events,
    required this.isLoading,
    super.key,
  });

  @override
  State<UpcomingEventsSection> createState() => _UpcomingEventsSectionState();
}

class _UpcomingEventsSectionState extends State<UpcomingEventsSection> {
  late ScrollController _scrollController;
  double _maxScroll = 0;
  double _leftFadeOpacity = 0;
  double _rightFadeOpacity = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_updateFadeOpacity);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (!_scrollController.hasClients) return;
        setState(() => _maxScroll = _scrollController.position.maxScrollExtent);
        _updateFadeOpacity();
      }
    });
  }

  void _updateFadeOpacity() {
    if (!_scrollController.hasClients) return;
    if (_maxScroll == 0) return;

    double offset = _scrollController.offset;
    double remaining = _maxScroll - offset;

    double leftOp = (offset / 50).clamp(0, 1);
    double rightOp = (remaining / 50).clamp(0, 1);

    if (mounted &&
        ((_leftFadeOpacity - leftOp).abs() > 0.03 ||
            (_rightFadeOpacity - rightOp).abs() > 0.03)) {
      setState(() {
        _leftFadeOpacity = leftOp;
        _rightFadeOpacity = rightOp;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 236,
      child:
          widget.isLoading
              ? const ShimmerLoadingList(itemWidth: 300, itemCount: 1)
              : widget.events.isEmpty
              ? const Center(
                child: Text(
                  "No events found.",
                  style: TextStyle(color: Colors.white70),
                ),
              )
              : Stack(
                children: [
                  ListView.separated(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    padding: TiermetrySpacing.listPadding,
                    itemCount: widget.events.length,
                    separatorBuilder: (_, __) => const SizedBox(width: TiermetrySpacing.gridGap),
                    itemBuilder: (_, index) {
                      return AnimatedListItem(
                        index: index,
                        child: SizedBox(
                          width: 300,
                          child: UpcomingEventCard(event: widget.events[index]),
                        ),
                      );
                    },
                  ),
                  // RIGHT FADE (scroll indicator)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: 28,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.transparent,
                              TiermetryColors.background.withValues(
                                alpha: _rightFadeOpacity * 0.3,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
