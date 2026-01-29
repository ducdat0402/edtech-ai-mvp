import 'package:flutter/material.dart';
import '../colors.dart';
import '../gradients.dart';
import '../text_styles.dart';

/// Coin display with animated number
class CoinDisplay extends StatelessWidget {
  final int coins;
  final bool compact;
  final bool showLabel;
  final VoidCallback? onTap;

  const CoinDisplay({
    super.key,
    required this.coins,
    this.compact = false,
    this.showLabel = false,
    this.onTap,
  });

  String get formattedCoins {
    if (coins >= 1000000) {
      return '${(coins / 1000000).toStringAsFixed(1)}M';
    } else if (coins >= 1000) {
      return '${(coins / 1000).toStringAsFixed(1)}K';
    }
    return coins.toString();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Coin icon with glow
          Container(
            width: compact ? 20 : 28,
            height: compact ? 20 : 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.coin,
              boxShadow: [
                BoxShadow(
                  color: AppColors.coinGold.withOpacity(0.5),
                  blurRadius: compact ? 4 : 8,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '₵',
                style: TextStyle(
                  fontSize: compact ? 10 : 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.bgPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formattedCoins,
                style: compact
                    ? AppTextStyles.numberSmall.copyWith(color: AppColors.coinGold)
                    : AppTextStyles.coinDisplay,
              ),
              if (showLabel && !compact)
                Text(
                  'Coins',
                  style: AppTextStyles.labelSmall,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Large coin display for shop/rewards
class CoinDisplayLarge extends StatelessWidget {
  final int coins;
  final String? label;

  const CoinDisplayLarge({
    super.key,
    required this.coins,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.coinGold.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Large coin icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.coin,
              boxShadow: [
                BoxShadow(
                  color: AppColors.coinGold.withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '₵',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.bgPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                coins.toString().replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                      (match) => '${match[1]},',
                    ),
                style: AppTextStyles.numberLarge,
              ),
              if (label != null)
                Text(
                  label!,
                  style: AppTextStyles.labelMedium,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Animated coin gain indicator (floating +10)
class CoinGainIndicator extends StatefulWidget {
  final int amount;
  final VoidCallback? onComplete;

  const CoinGainIndicator({
    super.key,
    required this.amount,
    this.onComplete,
  });

  @override
  State<CoinGainIndicator> createState() => _CoinGainIndicatorState();
}

class _CoinGainIndicatorState extends State<CoinGainIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🪙', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(
              '+${widget.amount}',
              style: AppTextStyles.numberSmall.copyWith(
                color: AppColors.coinGold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
