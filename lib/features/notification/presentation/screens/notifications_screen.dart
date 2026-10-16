import 'package:amazing_icons/bulk.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tiermetry/core/mixins/refresh_rate_mixin.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';

// ─── Data Model ────────────────────────────────────────────────────────────

enum _NotifType { booking, event, reward, system }

class _NotifItem {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final _NotifType type;
  bool isRead;

  _NotifItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.type,
    this.isRead = false,
  });

  factory _NotifItem.fromJson(Map<String, dynamic> json) => _NotifItem(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
    createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    type: _NotifType.system,
    isRead: json['read_at'] != null,
  );

  String get timeAgo {
    final age = DateTime.now().difference(createdAt);
    if (age.inMinutes < 1) return 'Just now';
    if (age.inHours < 1) return '${age.inMinutes} min ago';
    if (age.inDays < 1) return '${age.inHours} hr ago';
    return '${age.inDays} day${age.inDays == 1 ? '' : 's'} ago';
  }
}

// ─── Screen ─────────────────────────────────────────────────────────────────

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with RefreshRateMixin {
  List<_NotifItem> _notifications = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await Supabase.instance.client.rpc<List<dynamic>>(
        'get_my_notification_inbox',
        params: {'p_app_scope': 'customer'},
      );
      if (mounted) {
        setState(() => _notifications = rows
            .map((row) => _NotifItem.fromJson(Map<String, dynamic>.from(row as Map)))
            .toList());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _markAllRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
        Supabase.instance.client.rpc<void>(
          'mark_notification_read',
          params: {'p_delivery_id': n.id},
        );
      }
    });
  }

  void _markRead(String id) {
    setState(() {
      _notifications.firstWhere((n) => n.id == id).isRead = true;
      Supabase.instance.client.rpc<void>(
        'mark_notification_read',
        params: {'p_delivery_id': id},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: TiermetryColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TiermetrySpacing.screenPadding,
                TiermetrySpacing.lg,
                TiermetrySpacing.screenPadding,
                TiermetrySpacing.md,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(TiermetryRadii.sm),
                      ),
                      child: Center(
                        child: AmazingIconBulk.arrowLeft2(
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: TiermetrySpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NOTIFICATIONS',
                          style: TiermetryTypography.title(color: Colors.white),
                        ),
                        if (unreadCount > 0)
                          Text(
                            '$unreadCount unread',
                            style: TiermetryTypography.caption(
                              color: TiermetryColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (unreadCount > 0)
                    GestureDetector(
                      onTap: _markAllRead,
                      child: Text(
                        'Mark all read',
                        style: TiermetryTypography.caption(
                          color: TiermetryColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Divider ─────────────────────────────────────
            Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),

            // ── List ────────────────────────────────────────
            Expanded(
              child:
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _notifications.isEmpty
                      ? _EmptyState()
                      : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: TiermetrySpacing.screenPadding,
                          vertical: TiermetrySpacing.md,
                        ),
                        itemCount: _notifications.length,
                        separatorBuilder:
                            (_, __) => Container(
                              height: 1,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                        itemBuilder: (context, index) {
                          final notif = _notifications[index];
                          return _NotifTile(
                            notif: notif,
                            onTap: () => _markRead(notif.id),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Notification Tile ───────────────────────────────────────────────────────

class _NotifTile extends StatelessWidget {
  final _NotifItem notif;
  final VoidCallback onTap;

  const _NotifTile({required this.notif, required this.onTap});

  Widget _buildIcon() {
    switch (notif.type) {
      case _NotifType.booking:
        return AmazingIconBulk.calendar(
          size: 20,
          color: TiermetryColors.primary,
        );
      case _NotifType.event:
        return AmazingIconBulk.flag(size: 20, color: const Color(0xFF7B61FF));
      case _NotifType.reward:
        return AmazingIconBulk.star1(size: 20, color: const Color(0xFFFFBD00));
      case _NotifType.system:
        return AmazingIconBulk.notification(size: 20, color: Colors.white60);
    }
  }

  Color get _iconBg {
    switch (notif.type) {
      case _NotifType.booking:
        return TiermetryColors.primary.withValues(alpha: 0.12);
      case _NotifType.event:
        return const Color(0xFF7B61FF).withValues(alpha: 0.12);
      case _NotifType.reward:
        return const Color(0xFFFFBD00).withValues(alpha: 0.12);
      case _NotifType.system:
        return Colors.white.withValues(alpha: 0.06);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:
              notif.isRead
                  ? Colors.transparent
                  : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(TiermetryRadii.sm),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: _buildIcon()),
            ),
            const SizedBox(width: 12),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TiermetryTypography.bodySmall(
                            color: Colors.white,
                            fontWeight:
                                notif.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: TiermetryColors.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TiermetryTypography.caption(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notif.timeAgo,
                    style: TiermetryTypography.caption(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
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

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AmazingIconBulk.notification(
            size: 56,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 16),
          Text(
            'All clear',
            style: TiermetryTypography.title(
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No notifications yet.',
            style: TiermetryTypography.caption(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
