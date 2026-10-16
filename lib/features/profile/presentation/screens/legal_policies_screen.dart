import 'package:flutter/material.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/app_island_notice.dart';
import 'package:tiermetry/core/widgets/app_surface.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalPoliciesScreen extends StatelessWidget {
  const LegalPoliciesScreen({super.key});

  Future<void> _openWebLink(BuildContext context, String url) async {
    try {
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && context.mounted) {
        _showOpenError(context);
      }
    } catch (_) {
      if (context.mounted) {
        _showOpenError(context);
      }
    }
  }

  void _showOpenError(BuildContext context) {
    AppIslandNotice.show(
      context,
      title: 'Could not open this policy',
      message: 'Check your connection and try again.',
      tone: AppIslandNoticeTone.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TiermetryColors.background,
      appBar: AppBar(
        title: const Text('Legal & Policies'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          TiermetrySpacing.screenPadding,
          TiermetrySpacing.md,
          TiermetrySpacing.screenPadding,
          TiermetrySpacing.bottomSafeArea,
        ),
        children: [
          Text(
            'Legal documents',
            style: TiermetryTypography.title(color: Colors.white),
          ),
          const SizedBox(height: TiermetrySpacing.xs),
          Text(
            'These documents outline our policies and your rights.',
            style: TiermetryTypography.bodySmall(
              color: TiermetryColors.textMuted,
            ),
          ),
          const SizedBox(height: TiermetrySpacing.xl),
          _legalTile(
            context,
            title: 'Terms of Service',
            subtitle: 'Rules and conditions for using HOMIES',
            url: 'https://www.homieshubs.in/legal/terms',
          ),
          _legalTile(
            context,
            title: 'Privacy Policy',
            subtitle: 'How we handle your data and protect privacy',
            url: 'https://www.homieshubs.in/legal/privacy',
          ),
          _legalTile(
            context,
            title: 'Community Guidelines',
            subtitle: 'What behavior is acceptable on our platform',
            url: 'https://www.homieshubs.in/legal/community-guidelines',
          ),
          _legalTile(
            context,
            title: 'Refund Policy',
            subtitle: 'Booking cancellation, refunds, and payment issues',
            url: 'https://www.homieshubs.in/legal/booking-cancellation-refund',
          ),
          _legalTile(
            context,
            title: 'Account Deletion',
            subtitle: 'How to request deletion and data rights help',
            url: 'https://www.homieshubs.in/legal/account-deletion',
          ),
          const SizedBox(height: TiermetrySpacing.xl),
          Center(
            child: Text(
              'Last updated: September 2026',
              style: TiermetryTypography.caption(
                color: TiermetryColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legalTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String url,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TiermetrySpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(TiermetryRadii.lg),
          onTap: () => _openWebLink(context, url),
          child: AppSurface(
            padding: const EdgeInsets.all(TiermetrySpacing.lg),
            color: TiermetryColors.surfaceUnderlay,
            borderRadius: TiermetryRadii.lg,
            child: Row(
              children: [
                const Icon(Icons.policy_outlined, color: Colors.white70),
                const SizedBox(width: TiermetrySpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TiermetryTypography.bodySmall(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TiermetryTypography.caption(
                          color: TiermetryColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: TiermetrySpacing.sm),
                const Icon(Icons.chevron_right_rounded, color: Colors.white38),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
