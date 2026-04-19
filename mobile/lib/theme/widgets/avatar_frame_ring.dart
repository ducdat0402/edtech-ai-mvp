import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../colors.dart';

/// Tier 1–20 từ id `af_01` … `af_20` (đồng bộ backend catalog).
int? avatarFrameTier(String? frameId) {
  if (frameId == null || frameId.isEmpty) return null;
  if (!frameId.startsWith('af_')) return null;
  final n = int.tryParse(frameId.replaceFirst('af_', ''));
  if (n == null || n < 1 || n > 20) return null;
  return n;
}

/// Tùy chỉnh tỉ lệ “tràn viền” khi có file PNG (ảnh vuông, lỗ trong suốt ở giữa).
/// Ví dụ cánh / tai nhô ra: tăng scale cho khớp art.
const Map<String, double> kAvatarFramePngScale = {
  // 'af_20': 1.72,
};

/// Kích thước ô layout (avatar + khung), dùng khi căn header / list.
double avatarFrameOuterDiameter(double innerDiameter, String? frameId) {
  final tier = avatarFrameTier(frameId);
  if (tier == null) return innerDiameter;
  final id = frameId!;
  final g = _gradientFrameOuterDiameter(innerDiameter, id);
  final p = _pngSlotDiameter(innerDiameter, tier.clamp(1, 20), id);
  return math.max(g, p);
}

double _gradientFrameOuterDiameter(double inner, String frameId) {
  final t = avatarFrameTier(frameId)!.clamp(1, 20);
  final ring = 1.4 + (t / 20) * 3.2;
  return inner +
      ring * 2 +
      (t >= 12 ? 4.0 : 0) +
      (t >= 17 ? 4.0 : 0);
}

/// Ô dành cho PNG tràn viền (lớn hơn avatar — tier cao thường chi tiết nhiều hơn).
double _pngSlotDiameter(double inner, int tier, String frameId) {
  final scale = kAvatarFramePngScale[frameId] ?? (1.38 + tier * 0.017);
  return inner * scale.clamp(1.32, 1.88);
}

/// Viền avatar: ưu tiên **PNG** `assets/avatar_frames/{frameId}.png` (trong suốt giữa, chi tiết tràn viền);
/// nếu chưa có file thì dùng vẽ gradient (fallback).
class AvatarFrameRing extends StatefulWidget {
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
  State<AvatarFrameRing> createState() => _AvatarFrameRingState();
}

class _AvatarFrameRingState extends State<AvatarFrameRing> {
  static final Map<String, bool> _pngExists = {};

  bool? _usePng;

  @override
  void initState() {
    super.initState();
    _checkPng();
  }

  @override
  void didUpdateWidget(covariant AvatarFrameRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.frameId != widget.frameId) {
      _usePng = null;
      _checkPng();
    }
  }

  void _checkPng() {
    final id = widget.frameId;
    final tier = avatarFrameTier(id);
    if (id == null || tier == null) {
      _usePng = false;
      return;
    }
    if (_pngExists.containsKey(id)) {
      _usePng = _pngExists[id];
      return;
    }
    final path = 'assets/avatar_frames/$id.png';
    rootBundle.load(path).then((_) {
      _pngExists[id] = true;
      if (mounted) setState(() => _usePng = true);
    }).catchError((_) {
      _pngExists[id] = false;
      if (mounted) setState(() => _usePng = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.frameId;
    final tier = avatarFrameTier(id);
    if (tier == null) {
      return widget.child;
    }

    final inner = widget.diameter;
    final outer = avatarFrameOuterDiameter(inner, id);

    if (_usePng == null) {
      return SizedBox(
        width: outer,
        height: outer,
        child: Center(
          child: _GradientFrameBody(
            frameId: id!,
            diameter: inner,
            child: widget.child,
          ),
        ),
      );
    }

    if (_usePng == true) {
      return SizedBox(
        width: outer,
        height: outer,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Center(
              child: SizedBox(
                width: inner,
                height: inner,
                child: widget.child,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Image.asset(
                  'assets/avatar_frames/$id.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  alignment: Alignment.center,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: outer,
      height: outer,
      child: Center(
        child: _GradientFrameBody(
          frameId: id!,
          diameter: inner,
          child: widget.child,
        ),
      ),
    );
  }
}

class _GradientFrameBody extends StatelessWidget {
  final String frameId;
  final double diameter;
  final Widget child;

  const _GradientFrameBody({
    required this.frameId,
    required this.diameter,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final tier = avatarFrameTier(frameId)!.clamp(1, 20);
    final ring = 1.4 + (tier / 20) * 3.2;
    final glow = 3.0 + (tier / 20) * 14.0;
    final colors = _tierColors(tier);
    final outer = _gradientFrameOuterDiameter(diameter, frameId);

    return SizedBox(
      width: outer,
      height: outer,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (tier >= 15)
            Positioned.fill(
              child: CustomPaint(
                painter: _SparklePainter(
                  color: colors.accent.withValues(alpha: 0.35 + (tier / 80)),
                  count: 5 + tier ~/ 3,
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
                  spreadRadius: tier >= 10 ? 0.5 : 0,
                ),
                if (tier >= 8)
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
                    color: colors.accent.withValues(alpha: 0.55 + (tier / 60)),
                    width: tier >= 14 ? 1.8 : 1.0,
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
