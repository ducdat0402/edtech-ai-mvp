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
            gradient: AppGradients.forLevel(level),
            boxShadow: [
              BoxShadow(
                color: AppColors.getLevelColor(level).withOpacity(0.5),
                blurRadius: 12,
                spreadRadius: 2,
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
              color: AppColors.getLevelColor(level),
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
  });

  double get progress =>
      xpForNextLevel > 0 ? (currentXP / xpForNextLevel).clamp(0.0, 1.0) : 0.0;
  Color get levelColor => AppColors.getLevelColor(level);

  @override
  Widget build(BuildContext context) {
    final resolvedAvatar = ApiConfig.absoluteMediaUrl(avatarUrl);
    final hasPhoto = resolvedAvatar.isNotEmpty;

    Widget avatar = SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.95), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
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
                        color: Colors.white.withOpacity(0.15),
                        child: const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => _levelNumberFallback(),
                    )
                  : _levelNumberFallback(),
            ),
          ),
          Positioned(
            left: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFB91C1C),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white.withOpacity(0.85)),
              ),
              child: Text(
                'Lv.$level',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
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

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        gradient: AppGradients.forLevel(level),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: levelColor.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          avatar,
          const SizedBox(width: 10),
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
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: Colors.white.withOpacity(0.22),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$totalXP XP',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    if (onShowTitles != null)
                      IconButton(
                        onPressed: onShowTitles,
                        tooltip: 'Danh hiệu',
                        icon: Icon(
                          Icons.info_outline_rounded,
                          size: 20,
                          color: Colors.white.withOpacity(0.92),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'Cấp tiếp: ${level + 1}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 10,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$currentXP / $xpForNextLevel · ${(progress * 100).toStringAsFixed(1)}%',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _levelNumberFallback() {
    return Container(
      color: Colors.white.withOpacity(0.2),
      alignment: Alignment.center,
      child: Text(
        '$level',
        style: TextStyle(
          fontFamily: AppTextStyles.fontUI,
          fontSize: 18,
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
    final color = AppColors.getLevelColor(level);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
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
