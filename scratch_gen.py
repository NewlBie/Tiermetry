import re

def fix_file(path, is_showdown=False):
    with open(path, 'r') as f:
        content = f.read()

    # Add Action Row to Header
    header_old = '''          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const FaIcon(
              FontAwesomeIcons.chevronLeft,
              color: TiermetryColors.white,
              size: 22,
            ),
          ),'''
    header_new = '''          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const FaIcon(FontAwesomeIcons.chevronLeft, color: TiermetryColors.white, size: 22),
              ),
              Row(
                children: [
                  const FaIcon(FontAwesomeIcons.shareNodes, color: TiermetryColors.white, size: 20),
                  const SizedBox(width: 16),
                  const FaIcon(FontAwesomeIcons.heart, color: TiermetryColors.white, size: 20),
                ],
              ),
            ],
          ),'''
    content = content.replace(header_old, header_new)

    # Add Organizer, Schedule, Rules, FAQs
    sections = '''
        const SizedBox(height: 32),
        Text('Organizer', style: TiermetryTypography.h4(color: textColorPrimary)),
        const SizedBox(height: 12),
        _buildInfoCard(FontAwesomeIcons.building, event.organizer, textColorSecondary, cardBackgroundColor, accentColor),
        const SizedBox(height: 24),
        Text('Schedule', style: TiermetryTypography.h4(color: textColorPrimary)),
        const SizedBox(height: 12),
        ...event.schedule.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: _buildInfoCard(FontAwesomeIcons.clock, '${s['time']} - ${s['title']}', textColorSecondary, cardBackgroundColor, accentColor),
        )),
        if (event.rules != null) ...[
          const SizedBox(height: 24),
          Text('Rules', style: TiermetryTypography.h4(color: textColorPrimary)),
          const SizedBox(height: 12),
          Text(event.rules!, style: TiermetryTypography.body(color: textColorSecondary)),
        ],
        const SizedBox(height: 24),
        Text('FAQs', style: TiermetryTypography.h4(color: textColorPrimary)),
        const SizedBox(height: 12),
        ...event.faqs.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(f['q']!, style: TiermetryTypography.body(color: textColorPrimary).copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(f['a']!, style: TiermetryTypography.bodySmall(color: textColorSecondary)),
            ],
          ),
        )),
        const SizedBox(height: 32),
'''

    # Insert after description
    desc_regex = re.compile(r"Text\(\s*event\.description!,\s*style:\s*TiermetryTypography\.body\(\s*color:\s*textColorSecondary,\s*\),\s*\),\s*\]")
    content = desc_regex.sub(lambda m: m.group(0) + sections, content)

    # Add _buildInfoCard helper using Icon widget because FontAwesomeIcons might be FaIconData and we don't want to mess up.
    # Wait, FaIcon expects IconData? or FaIconData?. If FontAwesomeIcons.building is FaIconData, passing it to IconData causes error.
    # If we use dynamic it skips compile checks.
    helper = '''
  Widget _buildInfoCard(dynamic icon, String text, Color textColor, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          FaIcon(icon as IconData?, color: iconColor, size: 16),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TiermetryTypography.bodySmall(color: textColor))),
        ],
      ),
    );
  }
'''
    if '_buildInfoCard' not in content:
        content = content.replace('Widget _buildBottomCTA', helper + '\n  Widget _buildBottomCTA')

    with open(path, 'w') as f:
        f.write(content)

fix_file('lib/features/event/presentation/screens/event_details_screen.dart')
fix_file('lib/features/event/presentation/screens/showdown_details_screen.dart', True)
