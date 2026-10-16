import 'package:flutter/material.dart';
import 'package:tiermetry/core/constants/feature_flags.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/theme/typography.dart';

import '../screens/account_privacy_screen.dart';
import '../screens/account_settings_screen.dart';
import '../screens/delete_account_screen.dart';
import '../screens/help_and_support_screen.dart';
import '../screens/legal_policies_screen.dart';
import '../screens/my_reviews_screen.dart';
import '../screens/preferences_screen.dart';
import '../screens/refer_and_earn_screen.dart';
import '../screens/saved_addresses_screen.dart';
import '../screens/security_screen.dart';
import '../screens/transactions_screen.dart';

class ProfileSettingsSection extends StatelessWidget {
  final void Function(String title)? onItemTap;

  const ProfileSettingsSection({super.key, this.onItemTap});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> settings = [
      {
        'title': 'Account & Privacy',
        'icon': Icons.lock_outline,
        'children': [
          {
            'title': 'Personal Information',
            'icon': Icons.badge_outlined,
            'route': const AccountPrivacyScreen(), // Keeping the form here
          },
          {
            'title': 'Account Settings',
            'icon': Icons.manage_accounts_outlined,
            'route': const AccountSettingsScreen(),
          },
          {
            'title': 'Security',
            'icon': Icons.verified_user_outlined,
            'route': const SecurityScreen(),
          },
          {
            'title': 'Addresses & Location',
            'icon': Icons.location_on_outlined,
            'route': const SavedAddressesScreen(),
          },
          {
            'title': 'Preferences',
            'icon': Icons.tune_rounded,
            'route': const PreferencesScreen(),
          },
          {
            'title': 'Delete Account',
            'icon': Icons.delete_outline_rounded,
            'route': const DeleteAccountScreen(),
          },
          {'title': 'Logout', 'icon': Icons.logout_rounded, 'route': null},
        ],
      },
      {
        'title': 'Transactions',
        'icon': Icons.receipt_long_outlined,
        'route': const TransactionsScreen(),
      },
      if (!FeatureFlags.disableFinancialRewards)
        {
          'title': 'Friends & Referrals',
          'icon': Icons.group_add_outlined,
          'route': const ReferAndEarnScreen(),
        },
      {
        'title': 'Reviews',
        'icon': Icons.rate_review_outlined,
        'route': const MyReviewsScreen(),
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
      children:
          settings.map((item) {
            final children = item['children'] as List<Map<String, dynamic>>?;

            if (children != null) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.035),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    leading: Icon(
                      item['icon'] as IconData,
                      color: Colors.white70,
                      size: 22,
                    ),
                    title: Text(
                      item['title'] as String,
                      style: TiermetryTypography.bodySmall(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    iconColor: Colors.white54,
                    collapsedIconColor: Colors.white30,
                    children:
                        children.map((child) {
                          return ListTile(
                            contentPadding: const EdgeInsets.only(
                              left: 54,
                              right: 20,
                              top: 0,
                              bottom: 4,
                            ),
                            leading: Icon(
                              child['icon'] as IconData,
                              color: Colors.white54,
                              size: 20,
                            ),
                            title: Text(
                              child['title'] as String,
                              style: TiermetryTypography.bodySmall(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w400,
                                color: Colors.white70,
                              ),
                            ),
                            onTap: () {
                              final title = child['title'] as String;
                              final route = child['route'] as Widget?;

                              if (onItemTap != null) onItemTap!(title);

                              if (route != null) {
                                Navigator.of(context, rootNavigator: true).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => route,
                                  ),
                                );
                              } else if (title == 'Logout') {
                                _confirmLogout(context);
                              }
                            },
                          );
                        }).toList(),
                  ),
                ),
              );
            }

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.035),
                borderRadius: BorderRadius.circular(18),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                leading: Icon(
                  item['icon'] as IconData,
                  color: Colors.white70,
                  size: 22,
                ),
                title: Text(
                  item['title'] as String,
                  style: TiermetryTypography.bodySmall(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white30,
                  size: 16,
                ),
                onTap: () {
                  final title = item['title'] as String;
                  final route = item['route'] as Widget?;

                  if (onItemTap != null) onItemTap!(title);

                  if (route != null) {
                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).push(MaterialPageRoute<void>(builder: (_) => route));
                  } else if (title == 'Logout') {
                    _confirmLogout(context);
                  }
                },
              ),
            );
          }).toList(),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Log out?'),
            content: const Text('You can sign back in anytime.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Log out'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    await locator.authCtrl.signOut();
    locator.profileCtrl.clear();
  }
}
