import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:edtech_mobile/core/config/api_config.dart';
import '../colors.dart';
import '../gradients.dart';
import '../text_styles.dart';

/// Level badge with gradient based on level
class LevelBadge extends StatelessWidget {
  final int level;
  final double size;
  final bool showLabel;

  const LevelBadge({
    super.key,
    required this.level,
    this.size = 48,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.forLevelMuted(level),
            boxShadow: [
              BoxShadow(
                color: AppColors.tierAccentMuted(AppColors.getLevelColor(level))
                    .withValues(alpha: 0.35),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$level',
              style: TextStyle(
                fontFamily: AppTextStyles.fontUI,
                fontSize: size * 0.45,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 4),
          Text(
            'LEVEL',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.tierAccentMuted(AppColors.getLevelColor(level)),
            ),
          ),
        ],
      ],
    );
  }
}

/// Level card with title and progress (compact dashboard strip).
class LevelCard extends StatelessWidget {
  final int level;
  final String title;
  final int currentXP;
  final int xpForNextLevel;
  final int totalXP;
  final String displayName;
  final String? avatarUrl;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onShowTitles;

  /// Khi true: không vẽ nền/bóng (dùng trong thanh top cố định — gradient do cha bọc).
  final bool topBarStrip;

  /// Hiển thị xu / kim cương / chuỗi ngày bên phải thanh strip (thu nhỏ thanh EXP).
  final int? stripCoins;
  final int? stripDiamonds;
  final int? stripStreak;
  final VoidCallback? onStripCoinsTap;
  final VoidCallback? onStripDiamondsTap;
  final VoidCallback? onStripStreakTap;
  final Key? stripResourcesKey;

  const LevelCard({
    super.key,
    required this.level,
    required this.title,
    required this.currentXP,
    required this.xpForNextLevel,
    required this.totalXP,
    this.displayName = 'Bạn học',
    this.avatarUrl,
    this.onAvatarTap,
    this.onShowTitles,
    this.topBarStrip = false,
    this.stripCoins,
    this.stripDiamonds,
    this.stripStreak,
    this.onStripCoinsTap,
    this.onStripDiamondsTap,
    this.onStripStreakTap,
    this.stripResourcesKey,
  });

  double get progress =>
      xpForNextLevel > 0 ? (currentXP / xpForNextLevel).clamp(0.0, 1.0) : 0.0;
  Color get levelColor =>
      AppColors.tierAccentMuted(AppColors.getLevelColor(level));

  bool get _showStripResources =>
      topBarStrip &&
      stripCoins != null &&
      stripDiamonds != null &&
      stripStreak != null;

  @override
  Widget build(BuildContext context) {
    final strip = topBarStrip;
    final resolvedAvatar = ApiConfig.absoluteMediaUrl(avatarUrl);
    final hasPhoto = resolvedAvatar.isNotEmpty;
    final outer = strip ? 44.0 : 52.0;
    final inner = strip ? 40.0 : 48.0;
    final borderW = strip ? 1.5 : 2.0;

    Widget avatar = SizedBox(
      width: outer,
      height: outer,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: inner,
            height: inner,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.95), width: borderW),
              boxShadow: strip
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: ClipOval(
              child: hasPhoto
                  ? CachedNetworkImage(
                      imageUrl: resolvedAvatar,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: Colors.white.withValues(alpha: 0.15),
                        child: Center(
                          child: SizedBox(
                            width: strip ? 14 : 18,
                            height: strip ? 14 : 18,
                            child:
                                const CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) =>
                          _levelNumberFallback(strip ? 14 : 18),
                    )
                  : _levelNumberFallback(strip ? 14 : 18),
            ),
          ),
          Positioned(
            left: strip ? -1.5 : -2,
            bottom: strip ? -1.5 : -2,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: strip ? 4 : 5,
                vertical: strip ? 1 : 2,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFB91C1C),
                borderRadius: BorderRadius.circular(strip ? 5 : 6),
                border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
              ),
              child: Text(
                'Lv.$level',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: strip ? 8.0 : 9.0,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (onAvatarTap != null) {
      avatar = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onAvatarTap,
          customBorder: const CircleBorder(),
          child: avatar,
        ),
      );
    }

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        avatar,
        SizedBox(width: strip ? 8 : 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyBold.copyWith(
                  color: Colors.white,
                  fontSize: strip ? 13.5 : 15,
                ),
              ),
              if (!strip) ...[
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
              SizedBox(height: strip ? 6 : 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: _showStripResources ? 2 : 1,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight:
                                  strip ? (_showStripResources ? 3 : 4) : 6,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.22),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          ),
                        ),
                        if (!strip) ...[
                          const SizedBox(width: 6),
                          Text(
                            '$totalXP XP',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                        if (onShowTitles != null)
                          IconButton(
                            onPressed: onShowTitles,
                            tooltip: strip ? 'Chi tiết XP' : 'Danh hiệu',
                            icon: Icon(
                              Icons.info_outline_rounded,
                              size: strip ? 16 : 20,
                              color: Colors.white.withValues(alpha: 0.92),
                            ),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(
                              minWidth: strip ? 26 : 32,
                              minHeight: strip ? 26 : 32,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ),
                  if (_showStripResources) ...[
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 3,
                      child: KeyedSubtree(
                        key: stripResourcesKey,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _stripResourceChip(
                                  icon: Icons.diamond_rounded,
                                  color: AppColors.cyanNeon,
                                  value: stripDiamonds!,
                                  onTap: onStripDiamondsTap,
                                ),
                                _stripResourceDivider(),
                                _stripResourceChip(
                                  icon: Icons.monetization_on_rounded,
                                  color: AppColors.coinGold,
                                  value: stripCoins!,
                                  onTap: onStripCoinsTap,
                                ),
                                _stripResourceDivider(),
                                _stripResourceChip(
                                  icon: Icons.local_fire_department_rounded,
                                  color: AppColors.streakOrange,
                                  value: stripStreak!,
                                  suffix: '🔥',
                                  onTap: onStripStreakTap,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (!strip) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'Cấp tiếp: ${level + 1}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 10,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$currentXP / $xpForNextLevel · ${(progress * 100).toStringAsFixed(1)}%',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );

    if (strip) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(2, 0, 0, 0),
        child: content,
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        gradient: AppGradients.forLevel(level),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: levelColor.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: content,
    );
  }

  Widget _stripResourceDivider() {
    return Container(
      width: 1,
      height: 14,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      color: Colors.white.withValues(alpha: 0.35),
    );
  }

  Widget _stripResourceChip({
    required IconData icon,
    required Color color,
    required int value,
    String suffix = '',
    VoidCallback? onTap,
  }) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          '$value$suffix',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.95),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
    if (onTap == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: row,
      );
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: row,
        ),
      ),
    );
  }

  Widget _levelNumberFallback(double fontSize) {
    return Container(
      color: Colors.white.withValues(alpha: 0.2),
      alignment: Alignment.center,
      child: Text(
        '$level',
        style: TextStyle(
          fontFamily: AppTextStyles.fontUI,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Level title with color
class LevelTitle extends StatelessWidget {
  final int level;
  final String title;
  final bool showIcon;

  const LevelTitle({
    super.key,
    required this.level,
    required this.title,
    this.showIcon = true,
  });

  IconData get _icon {
    if (level <= 5) return Icons.emoji_people;
    if (level <= 10) return Icons.school;
    if (level <= 20) return Icons.menu_book;
    if (level <= 35) return Icons.psychology;
    if (level <= 50) return Icons.workspace_premium;
    if (level <= 75) return Icons.auto_awesome;
    return Icons.diamond;
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.tierAccentMuted(AppColors.getLevelColor(level));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: AppTextStyles.bodyBold.copyWith(color: color),
        ),
      ],
    );
  }
}
