import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:edtech_mobile/theme/colors.dart';
import 'package:edtech_mobile/theme/text_styles.dart';

/// GTU coin — mặc định vẽ vector (vàng + tím + chữ G) để đồng bộ với icon Material
/// (kim cương, lửa) trên thanh strip, không bị nền trắng của PNG.
///
/// [useRasterAsset] — chỉ bật khi cần đúng artwork PNG (vd. màn lớn); strip luôn dùng vector.
class GtuCoinIcon extends StatelessWidget {
  const GtuCoinIcon({
    super.key,
    required this.size,
    this.useRasterAsset = false,
  });

  final double size;
  final bool useRasterAsset;

  static const String _asset = 'assets/currency/gtu_coin.png';

  @override
  Widget build(BuildContext context) {
    final s = size.clamp(8.0, 256.0);
    if (useRasterAsset) {
      return Image.asset(
        _asset,
        width: s,
        height: s,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => _GtuCoinVector(size: s),
      );
    }
    return _GtuCoinVector(size: s);
  }
}

class _GtuCoinVector extends StatelessWidget {
  const _GtuCoinVector({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size(size, size),
        painter: _GtuCoinVectorPainter(),
      ),
    );
  }
}

class _GtuCoinVectorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.shortestSide;
    final c = Offset(w / 2, w / 2);
    final r = w / 2;

    // Viền trắng mảnh (giống gem Duolingo — tách khỏi nền tối)
    final rimWhite = math.max(0.8, w * 0.06);
    final paintWhiteRim = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = rimWhite;
    canvas.drawCircle(c, r - rimWhite / 2, paintWhiteRim);

    // Vành vàng (gradient nhẹ)
    final goldOuter = r * 0.92;
    const sweepColors = [
      Color(0xFFFFE08A),
      AppColors.coinGold,
      Color(0xFFE8A020),
      AppColors.coinShadow,
      Color(0xFFFFE08A),
    ];
    final goldShader = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: 1.5 * math.pi,
      colors: sweepColors,
      stops: const [0.0, 0.22, 0.45, 0.72, 1.0],
    ).createShader(Rect.fromCircle(center: c, radius: goldOuter));
    final goldFill = Paint()..shader = goldShader;
    canvas.drawCircle(c, goldOuter, goldFill);

    // Lõi tím
    final purpleR = r * 0.72;
    const purpleColors = [
      Color(0xFF9B6BFF),
      Color(0xFF5B21B6),
      Color(0xFF4C1D95),
    ];
    final purpleShader = RadialGradient(
      colors: purpleColors,
      stops: const [0.0, 0.55, 1.0],
    ).createShader(Rect.fromCircle(center: c, radius: purpleR));
    canvas.drawCircle(c, purpleR, Paint()..shader = purpleShader);

    final gSize = math.max(5.0, w * 0.44);
    final gStyleBase = TextStyle(
      fontFamily: AppTextStyles.fontUI,
      fontSize: gSize,
      fontWeight: FontWeight.w900,
      height: 1.0,
    );
    final tpShadow = TextPainter(
      text: TextSpan(
        text: 'G',
        style: gStyleBase.copyWith(
          color: const Color(0xFF3B0764).withValues(alpha: 0.55),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final gTop = Offset(c.dx - tpShadow.width / 2, c.dy - tpShadow.height / 2);
    tpShadow.paint(canvas, gTop + Offset(w * 0.025, w * 0.03));

    final tp = TextPainter(
      text: TextSpan(
        text: 'G',
        style: gStyleBase.copyWith(color: Colors.white),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, gTop);

    // Highlight góc (kim loại)
    final hiR = r * 0.25;
    final hiPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c.dx - r * 0.35, c.dy - r * 0.38),
        width: hiR * 1.4,
        height: hiR * 0.9,
      ),
      hiPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
