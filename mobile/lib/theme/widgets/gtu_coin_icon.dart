import 'package:flutter/material.dart';

/// GTU coin artwork (purple center, gold rim, “G”) — replaces generic coin icon.
class GtuCoinIcon extends StatelessWidget {
  const GtuCoinIcon({
    super.key,
    required this.size,
  });

  final double size;

  static const String _asset = 'assets/currency/gtu_coin.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => Icon(
        Icons.monetization_on_rounded,
        size: size,
        color: const Color(0xFFE8B84A),
      ),
    );
  }
}
