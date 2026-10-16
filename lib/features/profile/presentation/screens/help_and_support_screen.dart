import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_island_notice.dart';
import 'package:tiermetry/core/widgets/app_surface.dart';
import 'package:tiermetry/features/profile/domain/entities/profile_entity.dart';

import 'legal_policies_screen.dart';

class HelpAndSupportScreen extends StatefulWidget {
  final String? contextBookingId;
  final String? contextBookingTitle;
  final String? contextOrderId;

  const HelpAndSupportScreen({
    super.key,
    this.contextBookingId,
    this.contextBookingTitle,
    this.contextOrderId,
  });

  @override
  State<HelpAndSupportScreen> createState() => _HelpAndSupportScreenState();
}

class _HelpAndSupportScreenState extends State<HelpAndSupportScreen> {
  static const _categories = <String, String>{
    'booking': 'Booking',
    'payment': 'Payment',
    'account': 'Account',
    'profile': 'Profile',
    'technical': 'Technical',
    'other': 'Other',
  };

  final _messageController = TextEditingController();
  List<SupportRequestEntity> _requests = const [];
  late String _category;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _category =
        widget.contextOrderId != null
            ? 'payment'
            : widget.contextBookingId != null
            ? 'booking'
            : 'other';
    _load();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final requests = await locator.profileCtrl.getSupportRequests();
      if (mounted) setState(() => _requests = requests);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final message = _messageController.text.trim();
    if (message.length < 10) {
      AppIslandNotice.show(
        context,
        title: 'Add a few more details',
        message: 'Describe the issue in at least 10 characters.',
        tone: AppIslandNoticeTone.warning,
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final request = await locator.profileCtrl.submitSupportRequest(
        category: _category,
        message: message,
        bookingId: widget.contextBookingId,
        paymentOrderId: widget.contextOrderId,
      );
      _messageController.clear();
      await _load();
      if (!mounted) return;
      AppIslandNotice.show(
        context,
        title:
            request.alreadyOpen
                ? 'Request already open'
                : 'Support request submitted',
        message: 'Reference ${_shortId(request.id)}',
        tone: AppIslandNoticeTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      AppIslandNotice.show(
        context,
        title: 'Could not submit request',
        message: error.toString().replaceFirst('Exception: ', ''),
        tone: AppIslandNoticeTone.error,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _shortId(String value) =>
      value.length <= 12 ? value : value.substring(0, 12).toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TiermetryColors.background,
      appBar: AppBar(
        title: const Text('Help & support'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        color: TiermetryColors.accentNeonGreen,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(
            TiermetrySpacing.screenPadding,
            TiermetrySpacing.md,
            TiermetrySpacing.screenPadding,
            TiermetrySpacing.bottomSafeArea,
          ),
          children: [
            Text(
              'How can we help?',
              style: TiermetryTypography.title(color: Colors.white),
            ),
            const SizedBox(height: TiermetrySpacing.xs),
            Text(
              'Send a secure in-app request. Booking and payment references are verified against your account.',
              style: TiermetryTypography.bodySmall(
                color: TiermetryColors.textMuted,
                height: 1.4,
              ),
            ),
            if (widget.contextBookingId != null ||
                widget.contextOrderId != null) ...[
              const SizedBox(height: TiermetrySpacing.md),
              _contextCard(),
            ],
            const SizedBox(height: TiermetrySpacing.lg),
            AppSurface(
              padding: const EdgeInsets.all(TiermetrySpacing.lg),
              color: TiermetryColors.surfaceUnderlay,
              borderRadius: TiermetryRadii.lg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REQUEST TYPE',
                    style: TiermetryTypography.label(
                      color: TiermetryColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: TiermetrySpacing.sm),
                  Wrap(
                    spacing: TiermetrySpacing.sm,
                    runSpacing: TiermetrySpacing.sm,
                    children: _categories.entries
                        .map((entry) {
                          final selected = _category == entry.key;
                          return FilterChip(
                            label: Text(entry.value),
                            selected: selected,
                            showCheckmark: false,
                            onSelected:
                                (_) => setState(() => _category = entry.key),
                            selectedColor: TiermetryColors.accentNeonGreen,
                            backgroundColor: TiermetryColors.surfaceElement,
                            labelStyle: TiermetryTypography.bodySmall(
                              color: selected ? Colors.black : Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        })
                        .toList(growable: false),
                  ),
                  const SizedBox(height: TiermetrySpacing.md),
                  TextField(
                    controller: _messageController,
                    minLines: 4,
                    maxLines: 7,
                    maxLength: 2000,
                    style: TiermetryTypography.bodySmall(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Describe what happened and what you expected',
                      filled: true,
                      fillColor: TiermetryColors.surfaceElement,
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(TiermetryRadii.md),
                      ),
                    ),
                  ),
                  const SizedBox(height: TiermetrySpacing.sm),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: TiermetryColors.accentNeonGreen,
                      foregroundColor: Colors.black,
                    ),
                    icon:
                        _submitting
                            ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                            : const Icon(Icons.send_rounded),
                    label: Text(_submitting ? 'Sending' : 'Send request'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TiermetrySpacing.md),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: const Icon(Icons.policy_outlined),
              title: const Text('Policies and account rights'),
              subtitle: const Text('Refunds, privacy, and account deletion'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap:
                  () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const LegalPoliciesScreen(),
                    ),
                  ),
            ),
            const SizedBox(height: TiermetrySpacing.xl),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'RECENT REQUESTS',
                    style: TiermetryTypography.label(
                      color: TiermetryColors.textMuted,
                    ),
                  ),
                ),
                if (_loading)
                  const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: TiermetrySpacing.sm),
            if (_error != null)
              _messageCard(_error!, onRetry: _load)
            else if (!_loading && _requests.isEmpty)
              _messageCard('No support requests yet.')
            else
              ..._requests.map(_requestCard),
          ],
        ),
      ),
    );
  }

  Widget _contextCard() {
    final value =
        widget.contextOrderId ??
        widget.contextBookingTitle ??
        widget.contextBookingId!;
    return AppSurface(
      padding: const EdgeInsets.all(TiermetrySpacing.md),
      color: TiermetryColors.surfaceUnderlay,
      borderRadius: TiermetryRadii.md,
      child: Row(
        children: [
          const Icon(Icons.link_rounded, color: Colors.white70),
          const SizedBox(width: TiermetrySpacing.sm),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TiermetryTypography.bodySmall(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _requestCard(SupportRequestEntity request) {
    final resolved = request.status == 'resolved' || request.status == 'closed';
    return Padding(
      padding: const EdgeInsets.only(bottom: TiermetrySpacing.sm),
      child: AppSurface(
        padding: const EdgeInsets.all(TiermetrySpacing.md),
        color: TiermetryColors.surfaceUnderlay,
        borderRadius: TiermetryRadii.md,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    (_categories[request.category] ?? request.category)
                        .toUpperCase(),
                    style: TiermetryTypography.label(color: Colors.white),
                  ),
                ),
                Text(
                  request.status.replaceAll('_', ' ').toUpperCase(),
                  style: TiermetryTypography.label(
                    color:
                        resolved
                            ? TiermetryColors.positive
                            : TiermetryColors.accentAppleBlue,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              request.message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TiermetryTypography.bodySmall(
                color: TiermetryColors.textMuted,
              ),
            ),
            if (request.resolutionNote?.isNotEmpty == true) ...[
              const SizedBox(height: TiermetrySpacing.sm),
              Text(
                request.resolutionNote!,
                style: TiermetryTypography.bodySmall(color: Colors.white70),
              ),
            ],
            const SizedBox(height: TiermetrySpacing.sm),
            Text(
              '${_shortId(request.id)} · ${DateFormat.yMMMd().format(request.createdAt)}',
              style: TiermetryTypography.caption(
                color: TiermetryColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageCard(String message, {Future<void> Function()? onRetry}) {
    return AppSurface(
      padding: const EdgeInsets.all(TiermetrySpacing.md),
      color: TiermetryColors.surfaceUnderlay,
      borderRadius: TiermetryRadii.md,
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TiermetryTypography.bodySmall(
                color: TiermetryColors.textMuted,
              ),
            ),
          ),
          if (onRetry != null)
            IconButton(
              onPressed: onRetry,
              tooltip: 'Retry',
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
    );
  }
}
