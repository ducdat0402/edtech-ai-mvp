import 'package:flutter/material.dart';
import 'package:edtech_mobile/theme/theme.dart';

/// Chuỗi ngày học: lịch tuần (T2-CN), chuỗi hiện tại/cao nhất, tip, countdown đến hết ngày.
class StreakWeekCard extends StatelessWidget {
  final int currentStreak;
  final int maxStreak;
  final String? lastActiveDate; // ISO date "2025-01-27" or from API

  const StreakWeekCard({
    super.key,
    required this.currentStreak,
    this.maxStreak = 0,
    this.lastActiveDate,
  });

  /// Trả về [Mon, Tue, ..., Sun] = true nếu ngày đó có học trong chuỗi hoặc đã học.
  List<bool> _getWeekDays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Monday of current week (ISO: Monday = 1)
    int weekday = now.weekday;
    final monday = today.subtract(Duration(days: weekday - 1));
    final weekStart = DateTime(monday.year, monday.month, monday.day);

    final result = List<bool>.filled(7, false);

    if (lastActiveDate == null || lastActiveDate!.isEmpty) {
      // Chưa có hoạt động: chỉ có thể hôm nay chưa học
      return result;
    }

    DateTime lastActive;
    try {
      final parts = lastActiveDate!.split(RegExp(r'[T\s]'))[0].split('-');
      if (parts.length >= 3) {
        lastActive = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      } else {
        return result;
      }
    } catch (_) {
      return result;
    }

    // Các ngày có học: từ (lastActive - currentStreak + 1) đến lastActive
    for (int i = 0; i < currentStreak; i++) {
      final d = lastActive.subtract(Duration(days: i));
      final dayOnly = DateTime(d.year, d.month, d.day);
      final weekEnd = weekStart.add(const Duration(days: 6));
      if (!dayOnly.isBefore(weekStart) && !dayOnly.isAfter(weekEnd)) {
        final index = dayOnly.difference(weekStart).inDays;
        if (index >= 0 && index < 7) result[index] = true;
      }
    }

    return result;
  }

  String _getTimeLeftUntilMidnight() {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final diff = endOfDay.difference(now);
    if (diff.isNegative) return '0 giờ 0 phút';
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    return '$hours giờ $minutes phút';
  }

  @override
  Widget build(BuildContext context) {
    final weekDays = _getWeekDays();
    const dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.streakOrange.withOpacity(0.15),
            AppColors.streakYellow.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.streakOrange.withOpacity(0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('🔥', style: TextStyle(fontSize: 22, height: 1)),
              const SizedBox(width: 8),
              Text(
                'CHUỖI NGÀY HỌC',
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.streakOrange,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderPrimary.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (i) {
                final hasFire = weekDays[i];
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hasFire ? '🔥' : '📅',
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dayLabels[i],
                      style: AppTextStyles.caption.copyWith(
                        color: hasFire ? AppColors.streakOrange : AppColors.textTertiary,
                        fontWeight: hasFire ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.local_fire_department_rounded, color: AppColors.streakOrange, size: 20),
              const SizedBox(width: 8),
              Text(
                'Chuỗi hiện tại: $currentStreak ngày',
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: AppColors.streakYellow, size: 20),
              const SizedBox(width: 8),
              Text(
                'Chuỗi cao nhất: ${maxStreak > 0 ? maxStreak : currentStreak} ngày',
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.streakOrange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.streakOrange.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Text('💡', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Học hôm nay để giữ chuỗi!',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.schedule_rounded, color: AppColors.textSecondary, size: 18),
              const SizedBox(width: 6),
              Text(
                'Còn ${_getTimeLeftUntilMidnight()}',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
