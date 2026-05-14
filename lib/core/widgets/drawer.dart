import 'package:flutter/material.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/widgets/dot_grid_background.dart';

class DrawerItem {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final Color? color;
  final String? subtitle;

  const DrawerItem({
    required this.icon,
    required this.text,
    required this.onTap,
    this.color,
    this.subtitle,
  });
}

class AppDrawer extends StatelessWidget {
  final String userName;
  final String userHandle;
  final String? userAvatarAsset;
  final List<DrawerItem> items;

  const AppDrawer({
    super.key,
    this.userName = 'User',
    this.userHandle = '@user',
    this.userAvatarAsset,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Drawer(
      width: (width * 0.82).clamp(300.0, 360.0),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: RepaintBoundary(
        child: Container(
          decoration: BoxDecoration(
            color: TiermetryColors.surface,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(32),
            ),
            border: Border(
              right: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
                width: 0.8,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.58),
                blurRadius: 36,
                offset: const Offset(18, 0),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(32),
            ),
            child: Stack(
              children: [
                const Positioned.fill(
                  child: DotGridBackground(
                    dotColor: Colors.white,
                    opacity: 0.035,
                    spacing: 20,
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      _DrawerProfileHeader(
                        userName: userName,
                        userHandle: userHandle,
                        avatarAsset: userAvatarAsset,
                      ),
                      const SizedBox(height: TiermetrySpacing.md),
                      Expanded(
                        child: ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                          itemCount: items.length,
                          separatorBuilder: (_, index) {
                            final isBeforeDanger =
                                items[index + 1].color != null;
                            return SizedBox(
                              height:
                                  isBeforeDanger
                                      ? TiermetrySpacing.lg
                                      : TiermetrySpacing.xs,
                            );
                          },
                          itemBuilder: (context, index) {
                            return _DrawerActionTile(item: items[index]);
                          },
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

class _DrawerProfileHeader extends StatelessWidget {
  final String userName;
  final String userHandle;
  final String? avatarAsset;

  const _DrawerProfileHeader({
    required this.userName,
    required this.userHandle,
    required this.avatarAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            _Avatar(userName: userName, avatarAsset: avatarAsset),
            const SizedBox(width: TiermetrySpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TiermetryTypography.title(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    userHandle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TiermetryTypography.caption(
                      color: Colors.white.withValues(alpha: 0.52),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: TiermetryColors.accentNeonGreen.withValues(
                        alpha: 0.14,
                      ),
                      borderRadius: BorderRadius.circular(TiermetryRadii.pill),
                    ),
                    child: Text(
                      'Predator member',
                      style: TiermetryTypography.caption(
                        color: TiermetryColors.accentNeonGreen,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String userName;
  final String? avatarAsset;

  const _Avatar({required this.userName, required this.avatarAsset});

  @override
  Widget build(BuildContext context) {
    final initials =
        userName.trim().isEmpty
            ? 'U'
            : userName
                .trim()
                .split(RegExp(r'\s+'))
                .take(2)
                .map((part) => part[0].toUpperCase())
                .join();

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: TiermetryColors.surfaceElement,
        borderRadius: BorderRadius.circular(20),
        image:
            avatarAsset == null
                ? null
                : DecorationImage(
                  image: AssetImage(avatarAsset!),
                  fit: BoxFit.cover,
                ),
      ),
      child:
          avatarAsset == null
              ? Center(
                child: Text(
                  initials,
                  style: TiermetryTypography.title(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              )
              : null,
    );
  }
}

class _DrawerActionTile extends StatelessWidget {
  final DrawerItem item;

  const _DrawerActionTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final baseColor = item.color ?? Colors.white;

    return Semantics(
      button: true,
      label: item.text,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: baseColor.withValues(alpha: 0.06),
        highlightColor: baseColor.withValues(alpha: 0.035),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color:
                item.color == null
                    ? Colors.transparent
                    : item.color!.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: baseColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  item.icon,
                  color: baseColor.withValues(
                    alpha: item.color == null ? 0.78 : 1,
                  ),
                  size: 20,
                ),
              ),
              const SizedBox(width: TiermetrySpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TiermetryTypography.caption(
                        color: baseColor.withValues(alpha: 0.9),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.05,
                      ),
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TiermetryTypography.caption(
                          color: Colors.white.withValues(alpha: 0.42),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: baseColor.withValues(alpha: 0.28),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
