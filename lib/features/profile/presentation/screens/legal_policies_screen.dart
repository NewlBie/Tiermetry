import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalPoliciesScreen extends StatelessWidget {
  const LegalPoliciesScreen({super.key});

  void _openWebLink(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not open $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        middle: Text("Legal & Policies",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            )),
        border: null,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Legal Documents",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  )),
              const SizedBox(height: 12),
              Text("These documents outline our policies and your rights.",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white60,
                  )),
              const SizedBox(height: 30),
              _legalTile(
                context,
                title: "Terms of Service",
                subtitle: "Rules and conditions for using Tiermetry",
                url: "https://tiermetry.com/terms",
              ),
              _legalTile(
                context,
                title: "Privacy Policy",
                subtitle: "How we handle your data and protect privacy",
                url: "https://tiermetry.com/privacy",
              ),
              _legalTile(
                context,
                title: "Community Guidelines",
                subtitle: "What behavior is acceptable on our platform",
                url: "https://tiermetry.com/guidelines",
              ),
              const Spacer(),
              Center(
                child: Text("Last updated: July 2025",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white30,
                    )),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _legalTile(BuildContext context,
      {required String title, required String subtitle, required String url}) {
    return GestureDetector(
      onTap: () => _openWebLink(url),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            const Icon(Icons.policy_outlined, color: Colors.white70, size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      )),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white54,
                      )),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white24)
          ],
        ),
      ),
    );
  }
}
