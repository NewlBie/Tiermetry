import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/skill.dart';

class FeaturedSkillMorphCard extends StatefulWidget {
  final Skill skill;

  const FeaturedSkillMorphCard({
    required this.skill,
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
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned.fill(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutExpo,
                      decoration: BoxDecoration(
                        color: expanded ? const Color(0xFF1A1A1A) : Colors.white,
                      ),
                    )
                ),
                Positioned.fill(
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      expanded ? Colors.black.withOpacity(0.3) : Colors.transparent,
                      BlendMode.darken,
                    ),
                    child: Image.asset(
                      widget.skill.image,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (!expanded)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                          begin: Alignment.topCenter,
                          end: const Alignment(0, -0.2),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (expanded)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.skill.category.toUpperCase(),
                              style: GoogleFonts.urbanist(fontSize: 11, color: Colors.white70, letterSpacing: 0.5),
                            ),
                            AnimatedSlide(
                              duration: const Duration(milliseconds: 500),
                              offset: expanded ? Offset.zero : const Offset(0.5, 0),
                              curve: Curves.easeOutBack,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 500),
                                opacity: expanded ? 1.0 : 0.0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                                  child: Text("Enroll", style: GoogleFonts.urbanist(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      Text(
                        widget.skill.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.urbanist(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          shadows: !expanded
                              ? [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4, offset: const Offset(0, 1))]
                              : [],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.skill.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.urbanist(
                          fontSize: 12.5,
                          color: Colors.white70,
                          shadows: !expanded
                              ? [Shadow(color: Colors.black.withOpacity(0.4), blurRadius: 3, offset: const Offset(0, 1))]
                              : [],
                        ),
                      ),
                      const Spacer(),
                      if (expanded)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _AnimatedStat(title: "${widget.skill.rating} ★", label: "RATING", index: 0),
                            _AnimatedStat(title: widget.skill.level, label: "LEVEL", index: 1),
                            _AnimatedStat(title: widget.skill.time, label: "TIME", index: 2),
                            _AnimatedStat(title: "EN", label: "LANG", index: 3),
                          ],
                        ),
                      if (!expanded)
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
                            child: Text(
                              widget.skill.badge,
                              style: GoogleFonts.urbanist(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedStat extends StatelessWidget {
  final String title;
  final String label;
  final int index;
  const _AnimatedStat({required this.title, required this.label, required this.index});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 20.0, end: 0.0),
      duration: Duration(milliseconds: 300 + (index * 70)),
      curve: Curves.easeOutExpo,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, value),
          child: Opacity(opacity: (20.0 - value) / 20.0, child: child),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.urbanist(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white)),
          Text(label, style: GoogleFonts.urbanist(fontSize: 9.5, color: Colors.white54, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}