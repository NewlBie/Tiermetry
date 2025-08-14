import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class FeaturedSkillMorphCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String badge;
  final String image;
  final String time;
  final String level;
  final String price;
  final String oldPrice;

  const FeaturedSkillMorphCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.image,
    required this.time,
    required this.level,
    required this.price,
    required this.oldPrice,
    super.key,
  });

  @override
  State<FeaturedSkillMorphCard> createState() => _FeaturedSkillMorphCardState();
}

class _FeaturedSkillMorphCardState extends State<FeaturedSkillMorphCard> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => expanded = !expanded);
      },
      child: AnimatedScale(
        scale: expanded ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutExpo,
        child: Container(
          width: double.infinity,
          height: 260,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: expanded ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background image
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    expanded
                        ? Colors.black.withOpacity(0.3)
                        : Colors.transparent,
                    BlendMode.darken,
                  ),
                  child: Image.asset(
                    widget.image,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),

              // Foreground content
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (expanded)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Content Creation",
                              style: GoogleFonts.urbanist(
                                  fontSize: 11, color: Colors.white70)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text("Enroll",
                                style: GoogleFonts.urbanist(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                )),
                          )
                        ],
                      ),
                    const SizedBox(height: 8),

                    Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.urbanist(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),

                    Text(
                      widget.subtitle,
                      style: GoogleFonts.urbanist(
                        fontSize: 12.5,
                        color: Colors.white70,
                      ),
                    ),
                    const Spacer(),

                    if (expanded)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _Stat(label: "RAT NG", value: "4.9 ★"),
                          _Stat(label: "LEVEL", value: widget.level),
                          _Stat(label: "TIME", value: widget.time),
                          _Stat(label: "LANG", value: "EN"),
                        ],
                      ),

                    if (!expanded)
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.badge,
                            style: GoogleFonts.urbanist(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.urbanist(
              fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        Text(
          label,
          style: GoogleFonts.urbanist(
              fontSize: 9.5, color: Colors.white54, letterSpacing: 0.4),
        ),
      ],
    );
  }
}
