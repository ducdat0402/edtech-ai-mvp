import 'package:flutter/material.dart';

class StreakDisplay extends StatelessWidget {
  final int streak;
  final int consecutivePerfect;
  final Map<String, dynamic>? weeklyProgress;
  final bool compact;

  const StreakDisplay({
    super.key,
    required this.streak,
    this.consecutivePerfect = 0,
    this.weeklyProgress,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactView(context);
    }
    return _buildFullView(context);
  }

  Widget _buildFullView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.shade400,
            Colors.red.shade500,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Streak number with flame icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.local_fire_department,
                size: 48,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Text(
                '$streak',
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Day Streak',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (consecutivePerfect > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.yellow,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$consecutivePerfect Perfect Days',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (weeklyProgress != null) ...[
            const SizedBox(height: 24),
            _buildWeeklyCalendar(context),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.shade200,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_fire_department,
            color: Colors.orange.shade700,
            size: 32,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$streak Day Streak',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade900,
                ),
              ),
              if (consecutivePerfect > 0)
                Text(
                  '$consecutivePerfect perfect days',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCalendar(BuildContext context) {
    final now = DateTime.now();
    final weekDays = <Widget>[];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayName = _getDayName(date.weekday);
      final isWeekend =
          date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
      final isToday = date.day == now.day && date.month == now.month;

      // Check if this day has progress
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final hasProgress = weeklyProgress?[dateKey] == true;

      weekDays.add(
        Expanded(
          child: Column(
            children: [
              Text(
                dayName,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: hasProgress
                      ? (isWeekend
                          ? Colors.yellow.shade400
                          : Colors.blue.shade400)
                      : Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: isToday
                      ? Border.all(color: Colors.white, width: 2)
                      : null,
                ),
                child: hasProgress
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      )
                    : null,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'This Week',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: weekDays,
        ),
      ],
    );
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}
