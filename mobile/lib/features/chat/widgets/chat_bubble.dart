import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/theme/theme.dart';
import 'package:edtech_mobile/features/chat/screens/world_chat_screen.dart';

/// Đồng bộ với [WorldChatScreen] (đánh dấu đã xem chat thế giới).
const kWorldChatLastSeenPrefKey = 'edtech_world_chat_last_seen_iso';

/// Chấm đỏ góc trên-phải (badge thông báo).
class _CornerRedDot extends StatelessWidget {
  const _CornerRedDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: const Color(0xFFFF3B30),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.bgPrimary, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.errorNeon.withValues(alpha: 0.45),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}

class FloatingChatBubble extends StatefulWidget {
  const FloatingChatBubble({
    super.key,
    this.showQuestShopShortcuts = false,
    this.shortcutsTutorialKey,
    this.hasClaimableQuest = false,
  });

  /// Khi true (vd. Tổng quan): nút mở rộng phía trên chat → Nhiệm vụ, Cam kết tuần, Xếp hạng, Cửa hàng.
  final bool showQuestShopShortcuts;

  /// Gắn tutorial “Thao tác nhanh” lên cụm nút + chat.
  final Key? shortcutsTutorialKey;

  /// Nhiệm vụ đã xong, chờ nhận thưởng (từ dashboard `dailyQuests`).
  final bool hasClaimableQuest;

  @override
  State<FloatingChatBubble> createState() => _FloatingChatBubbleState();
}

class _FloatingChatBubbleState extends State<FloatingChatBubble>
    with SingleTickerProviderStateMixin {
  static const double _fabSize = 48;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _shortcutsOpen = false;

  bool _chatUnreadDot = false;
  Timer? _badgePollTimer;
  String? _cachedUserId;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshChatUnreadBadge();
      _badgePollTimer = Timer.periodic(
          const Duration(seconds: 25), (_) => _refreshChatUnreadBadge());
    });
  }

  @override
  void dispose() {
    _badgePollTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _refreshChatUnreadBadge() async {
    if (!mounted) return;
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      int dmUnread = 0;
      try {
        final conv = await api.getDmConversations();
        for (final c in conv) {
          if (c is Map) {
            dmUnread += (c['unreadCount'] as int?) ?? 0;
          }
        }
      } catch (_) {}

      bool worldUnread = false;
      try {
        final prefs = await SharedPreferences.getInstance();
        final lastSeenStr = prefs.getString(kWorldChatLastSeenPrefKey);
        final lastSeen = DateTime.tryParse(lastSeenStr ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);

        _cachedUserId ??= (await api.getUserProfile())['id'] as String?;

        final data = await api.getChatMessages(limit: 1);
        final msgs = data['messages'] as List<dynamic>? ?? [];
        if (msgs.isNotEmpty && _cachedUserId != null) {
          final newest = Map<String, dynamic>.from(msgs.last as Map);
          final uid = newest['userId'] as String?;
          final createdAt = DateTime.tryParse(
            newest['createdAt'] as String? ?? '',
          );
          if (uid != null &&
              uid != _cachedUserId &&
              createdAt != null &&
              createdAt.isAfter(lastSeen)) {
            worldUnread = true;
          }
        }
      } catch (_) {}

      final show = dmUnread > 0 || worldUnread;
      if (mounted && show != _chatUnreadDot) {
        setState(() => _chatUnreadDot = show);
      }
    } catch (_) {}
  }

  void _openChat() {
    _refreshChatUnreadBadge();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const WorldChatScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ).then((_) {
      if (mounted) _refreshChatUnreadBadge();
    });
  }

  void _toggleShortcuts() {
    HapticFeedback.lightImpact();
    setState(() => _shortcutsOpen = !_shortcutsOpen);
  }

  void _goQuests() {
    HapticFeedback.lightImpact();
    setState(() => _shortcutsOpen = false);
    context.push('/quests');
  }

  void _goShop() {
    HapticFeedback.lightImpact();
    setState(() => _shortcutsOpen = false);
    context.push('/shop');
  }

  void _goLeaderboard() {
    HapticFeedback.lightImpact();
    setState(() => _shortcutsOpen = false);
    context.push('/leaderboard');
  }

  void _goWeeklyCommitment() {
    HapticFeedback.lightImpact();
    setState(() => _shortcutsOpen = false);
    context.push('/self-leadership/weekly-plan');
  }

  Widget _circleButton({
    required Widget child,
    required VoidCallback onTap,
    required List<BoxShadow> shadows,
    Gradient? gradient,
    Color? color,
    bool showDot = false,
    BoxBorder? border,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: _fabSize,
          height: _fabSize,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: _fabSize,
                height: _fabSize,
                decoration: BoxDecoration(
                  gradient: gradient,
                  color: gradient == null ? color : null,
                  shape: BoxShape.circle,
                  boxShadow: shadows,
                  border: border,
                ),
                alignment: Alignment.center,
                child: child,
              ),
              if (showDot)
                const Positioned(
                  right: 2,
                  top: 2,
                  child: _CornerRedDot(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom + 80;

    final chatFab = AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: child,
        );
      },
      child: _circleButton(
        onTap: _openChat,
        showDot: _chatUnreadDot,
        gradient: const LinearGradient(
          colors: [AppColors.primaryLight, AppColors.purpleNeon],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shadows: [
          BoxShadow(
            color: AppColors.primaryLight.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        child: const Icon(Icons.chat_rounded, color: Colors.white, size: 22),
      ),
    );

    Widget column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (widget.showQuestShopShortcuts) ...[
          if (_shortcutsOpen) ...[
            _ShortcutPill(
              icon: Icons.task_alt_rounded,
              label: 'Nhiệm vụ',
              color: AppColors.primaryLight,
              onTap: _goQuests,
              showBadge: widget.hasClaimableQuest,
            ),
            const SizedBox(height: 8),
            _ShortcutPill(
              icon: Icons.flag_circle_rounded,
              label: 'Cam kết tuần',
              color: AppColors.orangeNeon,
              onTap: _goWeeklyCommitment,
            ),
            const SizedBox(height: 8),
            _ShortcutPill(
              icon: Icons.leaderboard_rounded,
              label: 'Xếp hạng',
              color: AppColors.purpleNeon,
              onTap: _goLeaderboard,
            ),
            const SizedBox(height: 8),
            _ShortcutPill(
              icon: Icons.storefront_rounded,
              label: 'Cửa hàng',
              color: AppColors.coinGold,
              onTap: _goShop,
            ),
            const SizedBox(height: 8),
          ],
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              _circleButton(
                onTap: _toggleShortcuts,
                color: AppColors.bgSecondary,
                border: Border.all(color: const Color(0x332D363D)),
                shadows: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                child: Icon(
                  _shortcutsOpen ? Icons.expand_more : Icons.apps_rounded,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
              ),
              if (widget.hasClaimableQuest && !_shortcutsOpen)
                const Positioned(
                  right: 2,
                  top: 2,
                  child: _CornerRedDot(),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        chatFab,
      ],
    );

    if (widget.shortcutsTutorialKey != null && widget.showQuestShopShortcuts) {
      column = KeyedSubtree(
        key: widget.shortcutsTutorialKey,
        child: column,
      );
    }

    return Positioned(
      right: 16,
      bottom: bottom,
      child: column,
    );
  }
}

class _ShortcutPill extends StatelessWidget {
  const _ShortcutPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.showBadge = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bgSecondary,
      elevation: 3,
      borderRadius: BorderRadius.circular(24),
      shadowColor: Colors.black54,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 20, color: color),
                  if (showBadge)
                    const Positioned(
                      right: -4,
                      top: -4,
                      child: _CornerRedDot(),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
