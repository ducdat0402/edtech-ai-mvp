import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Local **Noto Emoji** Lottie JSON (`assets/onboarding/noto/{hex}.json`).
/// Source: fonts.gstatic.com/s/e/notoemoji/ — see Google Noto Emoji license.
/// [fallbackEmoji] when asset missing or decode fails.
class OnboardingNotoLottie extends StatelessWidget {
  final String notoHex;
  final double size;
  final String fallbackEmoji;
  final bool repeat;

  const OnboardingNotoLottie({
    super.key,
    required this.notoHex,
    required this.size,
    required this.fallbackEmoji,
    this.repeat = true,
  });

  static String assetPath(String hex) => 'assets/onboarding/noto/$hex.json';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        assetPath(notoHex),
        fit: BoxFit.contain,
        repeat: repeat,
        errorBuilder: (_, __, ___) => Center(
          child: Text(
            fallbackEmoji,
            style: TextStyle(fontSize: size * 0.52),
          ),
        ),
      ),
    );
  }
}
