import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'account_privacy_page.dart';
import 'refer_earn_page.dart';
import 'help_support_page.dart';
import 'legal_policies_page.dart';// <-- Make sure this file exists

class ProfileSettingsSection extends StatelessWidget {
  final void Function(String title)? onItemTap;

  const ProfileSettingsSection({super.key, this.onItemTap});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> settings = [
      {
        "title": "Account & Privacy",
        "icon": Icons.lock_outline,
        "route": const AccountPrivacyPage(),
      },
      {
        "title": "Refer & Earn Tiergies",
        "icon": Icons.card_giftcard,
        "route": const ReferEarnPage(),
      },
      {
        "title": "Help & Support",
        "icon": Icons.help_outline,
        "route": const HelpSupportPage(),
      },
      {
        "title": "Legal & Policies",
        "icon": Icons.description_outlined,
        "route": const LegalPoliciesPage(),
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
            leading: Icon(item['icon'], color: Colors.white70, size: 22),
            title: Text(
              item['title'],
              style: GoogleFonts.inter(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 16),
            onTap: () {
              if (onItemTap != null) onItemTap!(item['title']);

              if (item['route'] != null) {
                Navigator.of(context).push(CupertinoPageRoute(
                  builder: (_) => item['route'],
                ));
              }
            },
          ),
        );
      }).toList(),
    );
  }
}

