import 'package:flutter/material.dart';

/// Widget to display EXP and Coin rewards
class RewardsDisplay extends StatelessWidget {
  final int? xp;
  final int? coin;
  final bool compact;

  const RewardsDisplay({
    super.key,
    this.xp,
    this.coin,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if ((xp == null || xp == 0) && (coin == null || coin == 0)) {
      return const SizedBox.shrink();
    }

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (xp != null && xp! > 0) ...[
            _buildCompactReward(Icons.star, xp!, Colors.amber),
            const SizedBox(width: 8),
          ],
          if (coin != null && coin! > 0)
            _buildCompactReward(Icons.monetization_on, coin!, Colors.orange),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (xp != null && xp! > 0) ...[
            Icon(Icons.star, color: Colors.amber.shade700, size: 20),
            const SizedBox(width: 6),
            Text(
              '$xp EXP',
              style: TextStyle(
                color: Colors.green.shade900,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (coin != null && coin! > 0) ...[
              const SizedBox(width: 16),
              Container(
                width: 1,
                height: 20,
                color: Colors.green.shade300,
              ),
              const SizedBox(width: 16),
            ],
          ],
          if (coin != null && coin! > 0) ...[
            Icon(Icons.monetization_on, color: Colors.orange.shade700, size: 20),
            const SizedBox(width: 6),
            Text(
              '$coin Coin',
              style: TextStyle(
                color: Colors.green.shade900,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactReward(IconData icon, int value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

