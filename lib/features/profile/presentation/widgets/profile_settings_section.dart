import 'package:flutter/material.dart';
import 'package:tiermetry/core/theme/typography.dart';

import '../screens/account_privacy_screen.dart';
import '../screens/help_and_support_screen.dart';
import '../screens/legal_policies_screen.dart';
import '../screens/refer_and_earn_screen.dart';

class ProfileSettingsSection extends StatelessWidget {
  final void Function(String title)? onItemTap;

  const ProfileSettingsSection({super.key, this.onItemTap});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> settings = [
      {
        'title': 'Account & Privacy',
        'icon': Icons.lock_outline,
        'route': const AccountPrivacyScreen(),
      },
      {
        'title': 'Refer & Earn Tiergies',
        'icon': Icons.card_giftcard,
        'route': const ReferAndEarnScreen(),
      },
      {
        'title': 'Help & Support',
        'icon': Icons.help_outline,
        'route': const HelpAndSupportScreen(),
      },
      {
        'title': 'Legal & Policies',
        'icon': Icons.description_outlined,
        'route': const LegalPoliciesScreen(),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: settings.map((item) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.035),
            borderRadius: BorderRadius.circular(18),
          ),
          child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: Icon(item['icon'] as IconData, color: Colors.white70, size: 22),
            title: Text(
              item['title'] as String,
              style: TiermetryTypography.bodySmall(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 16),
            onTap: () {
              final title = item['title'] as String;
              final route = item['route'] as Widget?;
              
              if (onItemTap != null) onItemTap!(title);

              if (route != null) {
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => route,
                ));
              }
            },
          ),
        );
      }).toList(),
    );
  }
}
