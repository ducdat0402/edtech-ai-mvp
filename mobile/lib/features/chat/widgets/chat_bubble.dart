import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/theme/theme.dart';
import 'package:edtech_mobile/features/chat/screens/world_chat_screen.dart';

class FloatingChatBubble extends StatefulWidget {
  const FloatingChatBubble({
    super.key,
    this.showQuestShopShortcuts = false,
    this.shortcutsTutorialKey,
  });

  /// Khi true (vd. Tổng quan): nút mở rộng phía trên chat → Nhiệm vụ & Cửa hàng.
  final bool showQuestShopShortcuts;

  /// Gắn tutorial “Thao tác nhanh” lên cụm nút + chat.
  final Key? shortcutsTutorialKey;

  @override
  State<FloatingChatBubble> createState() => _FloatingChatBubbleState();
}

class _FloatingChatBubbleState extends State<FloatingChatBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _shortcutsOpen = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _openChat() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const WorldChatScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
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
      child: GestureDetector(
        onTap: _openChat,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.cyanNeon, AppColors.purpleNeon],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.cyanNeon.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.chat_rounded, color: Colors.white, size: 26),
        ),
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
              color: AppColors.cyanNeon,
              onTap: _goQuests,
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
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleShortcuts,
              customBorder: const CircleBorder(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderPrimary),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _shortcutsOpen ? Icons.expand_more : Icons.apps_rounded,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        chatFab,
      ],
    );

    if (widget.shortcutsTutorialKey != null &&
        widget.showQuestShopShortcuts) {
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
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

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
              Icon(icon, size: 20, color: color),
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
