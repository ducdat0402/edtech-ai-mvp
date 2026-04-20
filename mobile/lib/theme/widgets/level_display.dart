import 'dart:ui' show lerpDouble;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:edtech_mobile/core/config/api_config.dart';
import 'package:edtech_mobile/theme/widgets/gtu_coin_icon.dart';
import 'package:edtech_mobile/theme/widgets/avatar_frame_ring.dart';
import '../colors.dart';
import '../gradients.dart';
import '../text_styles.dart';

/// Phân loại viên nang tiền tệ trên thanh HUD (gradient / highlight khác nhau).
enum _HudResourceKind { diamond, coin, streak }

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
  /// Khung shop (`af_01` …) — null = không viền.
  final String? avatarFrameId;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onShowTitles;

  /// Khi true: không vẽ nền/bóng (dùng trong thanh top cố định — gradient do cha bọc).
  final bool topBarStrip;

  /// Hiển thị GTU coin / kim cương / chuỗi ngày bên phải thanh strip (thu nhỏ thanh EXP).
  final int? stripCoins;
  final int? stripDiamonds;
  final int? stripStreak;
  final VoidCallback? onStripCoinsTap;
  final VoidCallback? onStripDiamondsTap;
  final VoidCallback? onStripStreakTap;
  final Key? stripResourcesKey;

  /// 0 = strip mở rộng, 1 = thu gọn khi cuộn dashboard (giảm chiều cao header).
  final double stripCollapseT;

  const LevelCard({
    super.key,
    required this.level,
    required this.title,
    required this.currentXP,
    required this.xpForNextLevel,
    required this.totalXP,
    this.displayName = 'Bạn học',
    this.avatarUrl,
    this.avatarFrameId,
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
    this.stripCollapseT = 0,
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
    final tStrip = strip ? stripCollapseT.clamp(0.0, 1.0) : 0.0;
    final resolvedAvatar = ApiConfig.absoluteMediaUrl(avatarUrl);
    final hasPhoto = resolvedAvatar.isNotEmpty;
    final outer = strip ? lerpDouble(44, 36, tStrip)! : 52.0;
    final inner = strip ? lerpDouble(40, 32, tStrip)! : 48.0;
    final borderW = strip ? lerpDouble(1.5, 1.2, tStrip)! : 2.0;
    final stripNameSize = strip ? lerpDouble(13.5, 12, tStrip)! : 15.0;
    final stripGapTitleToBar = strip ? lerpDouble(6, 3, tStrip)! : 8.0;
    final stripProgressH =
        strip ? lerpDouble(_showStripResources ? 3 : 4, 2, tStrip)! : 6.0;
    final stripInfoIcon = strip ? lerpDouble(16, 14, tStrip)! : 20.0;
    final stripChipIcon = lerpDouble(13, 11, tStrip)!;
    final stripChipFont = lerpDouble(10, 9, tStrip)!;
    final stripDividerH = lerpDouble(14, 11, tStrip)!;

    final hasFrame = avatarFrameTier(avatarFrameId) != null;
    final slot = hasFrame
        ? avatarFrameOuterDiameter(inner, avatarFrameId)
        : outer;

    final photo = ClipOval(
      child: SizedBox(
        width: inner,
        height: inner,
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
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) =>
                    _levelNumberFallback(strip ? 14 : 18),
              )
            : _levelNumberFallback(strip ? 14 : 18),
      ),
    );

    final Widget coreAvatar;
    if (hasFrame) {
      coreAvatar = AvatarFrameRing(
        frameId: avatarFrameId,
        diameter: inner,
        child: photo,
      );
    } else {
      coreAvatar = Container(
        width: inner,
        height: inner,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.95),
            width: borderW,
          ),
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
        child: photo,
      );
    }

    Widget avatar = SizedBox(
      width: slot,
      height: slot,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Center(child: coreAvatar),
          Positioned(
            left: hasFrame ? 0 : (strip ? -1.5 : -2),
            bottom: hasFrame ? 0 : (strip ? -1.5 : -2),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: strip ? 4 : 5,
                vertical: strip ? 1 : 2,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFEF4444),
                    const Color(0xFF991B1B),
                  ],
                ),
                borderRadius: BorderRadius.circular(strip ? 5 : 6),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.55),
                  width: strip ? 0.8 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    offset: const Offset(0, 2),
                    blurRadius: 3,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.2),
                    offset: const Offset(0, -1),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Text(
                'Lv.$level',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: strip ? 8.0 : 9.0,
                  fontWeight: FontWeight.w800,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      offset: const Offset(0, 0.5),
                      blurRadius: 1,
                    ),
                  ],
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
                  fontSize: stripNameSize,
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
              SizedBox(height: stripGapTitleToBar),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: _showStripResources ? 2 : 1,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: strip
                              ? _buildStripHudXpBar(progress, stripProgressH)
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: stripProgressH,
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.22),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
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
                              size: stripInfoIcon,
                              color: Colors.white.withValues(alpha: 0.92),
                            ),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(
                              minWidth: strip ? lerpDouble(26, 22, tStrip)! : 32,
                              minHeight:
                                  strip ? lerpDouble(26, 22, tStrip)! : 32,
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
                                  hudKind: _HudResourceKind.diamond,
                                  icon: Icons.diamond_rounded,
                                  color: AppColors.cyanNeon,
                                  value: stripDiamonds!,
                                  valueColor: AppColors.cyanNeon,
                                  onTap: onStripDiamondsTap,
                                  iconSize: stripChipIcon,
                                  fontSize: stripChipFont,
                                ),
                                _stripResourceDivider(height: stripDividerH),
                                _stripResourceChip(
                                  hudKind: _HudResourceKind.coin,
                                  iconWidget: GtuCoinIcon(size: stripChipIcon),
                                  color: AppColors.coinGold,
                                  value: stripCoins!,
                                  valueColor: AppColors.coinGold,
                                  onTap: onStripCoinsTap,
                                  iconSize: stripChipIcon,
                                  fontSize: stripChipFont,
                                ),
                                _stripResourceDivider(height: stripDividerH),
                                _stripResourceChip(
                                  hudKind: _HudResourceKind.streak,
                                  icon: Icons.local_fire_department_rounded,
                                  color: AppColors.streakOrange,
                                  value: stripStreak!,
                                  valueColor: AppColors.streakOrange,
                                  suffix: '🔥',
                                  onTap: onStripStreakTap,
                                  iconSize: stripChipIcon,
                                  fontSize: stripChipFont,
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

  /// Thanh XP kiểu HUD: rãnh tối + vạch sáng nổi (skeuomorphic).
  Widget _buildStripHudXpBar(double value, double height) {
    final v = value.clamp(0.0, 1.0);
    final h = height.clamp(3.0, 10.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              offset: const Offset(0, 2),
              blurRadius: 3,
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.38),
                Colors.black.withValues(alpha: 0.16),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: h,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: v,
                      heightFactor: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.98),
                              Colors.white.withValues(alpha: 0.68),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.28),
                              blurRadius: 5,
                              spreadRadius: -1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stripResourceDivider({double height = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Container(
        width: 1,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(1),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.0),
              Colors.white.withValues(alpha: 0.22),
              Colors.white.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stripResourceChip({
    required _HudResourceKind hudKind,
    IconData? icon,
    Widget? iconWidget,
    required Color color,
    required int value,
    Color? valueColor,
    String suffix = '',
    VoidCallback? onTap,
    double iconSize = 13,
    double fontSize = 10,
  }) {
    assert(icon != null || iconWidget != null);
    return _SkeuHudResourceChip(
      kind: hudKind,
      icon: icon,
      iconWidget: iconWidget,
      accent: color,
      value: value,
      valueColor: valueColor,
      suffix: suffix,
      onTap: onTap,
      iconSize: iconSize,
      fontSize: fontSize,
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

/// Nút tiền tệ kiểu HUD: gradient nổi, viền highlight, bóng — trông như có thể bấm.
class _SkeuHudResourceChip extends StatelessWidget {
  final _HudResourceKind kind;
  final IconData? icon;
  final Widget? iconWidget;
  final Color accent;
  final int value;
  final Color? valueColor;
  final String suffix;
  final VoidCallback? onTap;
  final double iconSize;
  final double fontSize;

  const _SkeuHudResourceChip({
    required this.kind,
    this.icon,
    this.iconWidget,
    required this.accent,
    required this.value,
    this.valueColor,
    this.suffix = '',
    this.onTap,
    required this.iconSize,
    required this.fontSize,
  }) : assert(icon != null || iconWidget != null);

  (LinearGradient, List<BoxShadow>, Color) _shellStyle() {
    switch (kind) {
      case _HudResourceKind.diamond:
        return (
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              accent.withValues(alpha: 0.95),
              const Color(0xFF0A3D52),
              const Color(0xFF051F2A),
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
          [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              offset: const Offset(0, 3),
              blurRadius: 5,
            ),
            BoxShadow(
              color: accent.withValues(alpha: 0.35),
              offset: const Offset(0, -1),
              blurRadius: 0,
            ),
          ],
          Colors.white.withValues(alpha: 0.38),
        );
      case _HudResourceKind.coin:
        return (
          LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFFE8A8),
              accent,
              const Color(0xFF7A5200),
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
          [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              offset: const Offset(0, 3),
              blurRadius: 5,
            ),
            BoxShadow(
              color: const Color(0xFFFFF6D6).withValues(alpha: 0.45),
              offset: const Offset(0, -1.5),
              blurRadius: 0,
            ),
          ],
          const Color(0xFFFFF2C4).withValues(alpha: 0.65),
        );
      case _HudResourceKind.streak:
        return (
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFF9A6B),
              accent,
              const Color(0xFF6B1F0A),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
          [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.52),
              offset: const Offset(0, 3),
              blurRadius: 5,
            ),
            BoxShadow(
              color: const Color(0xFFFFD4B8).withValues(alpha: 0.4),
              offset: const Offset(0, -1),
              blurRadius: 0,
            ),
          ],
          Colors.white.withValues(alpha: 0.42),
        );
    }
  }

  BoxDecoration _iconBossDecoration() {
    switch (kind) {
      case _HudResourceKind.diamond:
        return BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.55),
              accent.withValues(alpha: 0.35),
              const Color(0xFF062530),
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              offset: const Offset(0, 2),
              blurRadius: 3,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.25),
              offset: const Offset(0, -1),
              blurRadius: 0,
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 0.8,
          ),
        );
      case _HudResourceKind.coin:
        return BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [
              Color(0xFFFFF6E0),
              Color(0xFFE8B84A),
              Color(0xFF5C3D00),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.42),
              offset: const Offset(0, 2),
              blurRadius: 3,
            ),
          ],
          border: Border.all(
            color: const Color(0xFFFFF0C8).withValues(alpha: 0.9),
            width: 0.9,
          ),
        );
      case _HudResourceKind.streak:
        return BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              const Color(0xFFFFE0C8),
              accent.withValues(alpha: 0.9),
              const Color(0xFF4A1508),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              offset: const Offset(0, 2),
              blurRadius: 3,
            ),
            BoxShadow(
              color: const Color(0xFFFFB899).withValues(alpha: 0.5),
              offset: const Offset(0, -1),
              blurRadius: 0,
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
            width: 0.8,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (gradient, outerShadows, borderHighlight) = _shellStyle();
    final boss = iconSize + 5;
    final radius = BorderRadius.circular(999);
    final textColor = valueColor ?? accent;

    final iconArea = Container(
      width: boss,
      height: boss,
      alignment: Alignment.center,
      decoration: _iconBossDecoration(),
      child: iconWidget ??
          Icon(
            icon,
            size: iconSize,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.55),
                offset: const Offset(0, 1),
                blurRadius: 1.5,
              ),
            ],
          ),
    );

    final label = Text(
      '$value$suffix',
      style: TextStyle(
        fontFamily: AppTextStyles.fontUI,
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
        color: textColor,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.55),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
          Shadow(
            color: Colors.white.withValues(alpha: 0.25),
            offset: const Offset(0, -0.5),
            blurRadius: 0,
          ),
        ],
      ),
    );

    final inner = Padding(
      padding: const EdgeInsets.fromLTRB(5, 4, 8, 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconArea,
          const SizedBox(width: 5),
          label,
        ],
      ),
    );

    final deco = BoxDecoration(
      borderRadius: radius,
      gradient: gradient,
      border: Border.all(color: borderHighlight, width: 1),
      boxShadow: outerShadows,
    );

    if (onTap == null) {
      return DecoratedBox(decoration: deco, child: inner);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(borderRadius: radius),
        splashColor: Colors.white.withValues(alpha: 0.22),
        highlightColor: Colors.white.withValues(alpha: 0.12),
        child: Ink(decoration: deco, child: inner),
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
