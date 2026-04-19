import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../colors.dart';

/// Tier 1–20 từ id `af_01` … `af_20` (đồng bộ backend catalog).
int? avatarFrameTier(String? frameId) {
  if (frameId == null || frameId.isEmpty) return null;
  if (!frameId.startsWith('af_')) return null;
  final n = int.tryParse(frameId.replaceFirst('af_', ''));
  if (n == null || n < 1 || n > 20) return null;
  return n;
}

/// Đường kính vùng chứa avatar + khung (để căn layout header).
double avatarFrameOuterDiameter(double innerDiameter, String? frameId) {
  final tier = avatarFrameTier(frameId);
  if (tier == null) return innerDiameter;
  final t = tier.clamp(1, 20);
  final ring = 1.4 + (t / 20) * 3.2;
  return innerDiameter +
      ring * 2 +
      (t >= 12 ? 4.0 : 0) +
      (t >= 17 ? 4.0 : 0);
}

/// Viền / glow quanh avatar — tier cao = nhiều lớp & glow hơn.
class AvatarFrameRing extends StatelessWidget {
  final String? frameId;
  final double diameter;
  final Widget child;

  const AvatarFrameRing({
    super.key,
    required this.frameId,
    required this.diameter,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final tier = avatarFrameTier(frameId);
    if (tier == null) {
      return child;
    }

    final t = tier.clamp(1, 20);
    final ring = 1.4 + (t / 20) * 3.2;
    final glow = 3.0 + (t / 20) * 14.0;

    final colors = _tierColors(t);
    final outer = avatarFrameOuterDiameter(diameter, frameId);

    return SizedBox(
      width: outer,
      height: outer,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (t >= 15)
            Positioned.fill(
              child: CustomPaint(
                painter: _SparklePainter(
                  color: colors.accent.withValues(alpha: 0.35 + (t / 80)),
                  count: 5 + t ~/ 3,
                ),
              ),
            ),
          Container(
            width: diameter + ring * 2,
            height: diameter + ring * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: colors.ring,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.glow.withValues(alpha: 0.45),
                  blurRadius: glow,
                  spreadRadius: t >= 10 ? 0.5 : 0,
                ),
                if (t >= 8)
                  BoxShadow(
                    color: colors.accent.withValues(alpha: 0.25),
                    blurRadius: glow * 0.6,
                    spreadRadius: -1,
                  ),
              ],
            ),
            padding: EdgeInsets.all(ring * 0.35),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    colors.inner,
                    colors.inner.withValues(alpha: 0.85),
                  ],
                ),
              ),
              padding: EdgeInsets.all(ring * 0.45),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.accent.withValues(alpha: 0.55 + (t / 60)),
                    width: t >= 14 ? 1.8 : 1.0,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(width: diameter, height: diameter, child: child),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TierColors {
  final List<Color> ring;
  final Color inner;
  final Color accent;
  final Color glow;

  _TierColors({
    required this.ring,
    required this.inner,
    required this.accent,
    required this.glow,
  });
}

_TierColors _tierColors(int t) {
  if (t <= 3) {
    return _TierColors(
      ring: [
        Colors.white.withValues(alpha: 0.95),
        AppColors.textTertiary.withValues(alpha: 0.5),
      ],
      inner: AppColors.bgSecondary,
      accent: Colors.white,
      glow: Colors.white,
    );
  }
  if (t <= 6) {
    return _TierColors(
      ring: [
        AppColors.primaryLight.withValues(alpha: 0.9),
        AppColors.purpleNeon.withValues(alpha: 0.85),
      ],
      inner: AppColors.surfaceContainerLow,
      accent: AppColors.primaryLight,
      glow: AppColors.purpleNeon,
    );
  }
  if (t <= 10) {
    return _TierColors(
      ring: [
        AppColors.successNeon.withValues(alpha: 0.95),
        AppColors.cyanNeon.withValues(alpha: 0.85),
      ],
      inner: AppColors.bgTertiary,
      accent: AppColors.successNeon,
      glow: AppColors.successNeon,
    );
  }
  if (t <= 14) {
    return _TierColors(
      ring: [
        AppColors.xpGold.withValues(alpha: 0.95),
        AppColors.orangeNeon.withValues(alpha: 0.88),
      ],
      inner: AppColors.surfaceContainerLow,
      accent: AppColors.xpGold,
      glow: AppColors.xpGold,
    );
  }
  if (t <= 17) {
    return _TierColors(
      ring: [
        AppColors.purpleNeon,
        AppColors.pinkNeon,
        AppColors.primaryLight,
      ],
      inner: AppColors.bgSecondary,
      accent: AppColors.pinkNeon,
      glow: AppColors.purpleNeon,
    );
  }
  return _TierColors(
    ring: [
      AppColors.xpGold,
      AppColors.rankGold,
      AppColors.purpleNeon,
      AppColors.primaryLight,
    ],
    inner: AppColors.surfaceContainerLow,
    accent: AppColors.rankGold,
    glow: AppColors.xpGold,
  );
}

class _SparklePainter extends CustomPainter {
  final Color color;
  final int count;

  _SparklePainter({required this.color, required this.count});

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(42);
    final paint = Paint()..color = color;
    for (var i = 0; i < count; i++) {
      final ox = rnd.nextDouble() * size.width;
      final oy = rnd.nextDouble() * size.height;
      final r = 0.6 + rnd.nextDouble() * 1.4;
      canvas.drawCircle(Offset(ox, oy), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
