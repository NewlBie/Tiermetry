import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tiermetry/core/mixins/refresh_rate_mixin.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpAndSupportScreen extends StatefulWidget {
  const HelpAndSupportScreen({super.key});

  @override
  State<HelpAndSupportScreen> createState() => _HelpAndSupportScreenState();
}

class _HelpAndSupportScreenState extends State<HelpAndSupportScreen> with RefreshRateMixin {
  Future<void> _sendEmail() async {
    final Email email = Email(
      body: '',
      subject: 'Support Request - Tiermetry App',
      recipients: ['support@tiermetry.com'],
      isHTML: false,
    );

    await FlutterEmailSender.send(email);
  }

  Future<void> _launchFAQ() async {
    final Uri url = Uri.parse('https://tiermetry.com/faq');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch FAQ');
    }
  }

  Future<void> _openWhatsApp() async {
    final Uri url = Uri.parse('https://wa.me/919999999999?text=Hello%20Tiermetry%20Support');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch WhatsApp');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        middle: Text('Help & Support',
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
              Text("We're here to help!",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  )),
              const SizedBox(height: 12),
              Text('Find answers or get in touch with our support team.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white60,
                  )),
              const SizedBox(height: 30),
              _supportTile(
                context,
                icon: CupertinoIcons.doc_text_search,
                title: 'Visit FAQ',
                subtitle: 'Find quick answers to common questions',
                onTap: _launchFAQ,
              ),
              _supportTile(
                context,
                icon: CupertinoIcons.mail,
                title: 'Email Us',
                subtitle: 'Get support from our team via email',
                onTap: _sendEmail,
              ),
              _supportTile(
                context,
                icon: CupertinoIcons.chat_bubble_2,
                title: 'Chat on WhatsApp',
                subtitle: 'Talk to a human (Mon-Fri, 10AM-6PM)',
                onTap: _openWhatsApp,
              ),
              const Spacer(),
              Center(
                child: Text('Response time: under 24 hours',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white24,
                    )),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _supportTile(BuildContext context,
      {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
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
            Icon(icon, size: 26, color: Colors.white70),
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
            )
          ],
        ),
      ),
    );
  }
}
