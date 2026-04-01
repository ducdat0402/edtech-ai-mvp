import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/theme/theme.dart';

class CompetencyGrowthNotifier {
  static const _prefsKey = 'competency_snapshot_v1';

  static const Map<String, String> _labels = {
    'memory': 'Ghi nhớ',
    'logical_thinking': 'Tư duy logic',
    'processing_speed': 'Tốc độ xử lý',
    'practical_application': 'Ứng dụng thực tế',
    'metacognition': 'Siêu nhận thức',
    'learning_persistence': 'Bền bỉ học tập',
    'knowledge_absorption': 'Tiếp thu kiến thức',
    'systems_thinking': 'Tư duy hệ thống',
    'creativity': 'Sáng tạo',
    'communication': 'Giao tiếp',
    'self_leadership': 'Lãnh đạo bản thân',
    'discipline': 'Kỷ luật',
    'growth_mindset': 'Mindset tăng trưởng',
    'critical_thinking': 'Tư duy phản biện',
    'collaboration': 'Cộng tác',
  };

  static Future<void> checkAndShowIfGained(
    BuildContext context,
    ApiService api,
  ) async {
    try {
      final data = await api.getUserCompetencies();
      final current = _flatten(data);
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);

      if (raw == null || raw.isEmpty) {
        await prefs.setString(_prefsKey, jsonEncode(current));
        return;
      }

      final decoded = jsonDecode(raw);
      final prev = <String, double>{};
      if (decoded is Map) {
        for (final entry in decoded.entries) {
          prev[entry.key.toString()] =
              (entry.value is num) ? (entry.value as num).toDouble() : 0;
        }
      }

      final gains = <MapEntry<String, double>>[];
      for (final entry in current.entries) {
        final old = prev[entry.key] ?? entry.value;
        final delta = entry.value - old;
        if (delta > 0.49) {
          gains.add(MapEntry(entry.key, delta));
        }
      }

      await prefs.setString(_prefsKey, jsonEncode(current));
      if (gains.isEmpty || !context.mounted) return;

      gains.sort((a, b) => b.value.compareTo(a.value));
      final top = gains.take(4).toList();

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.bgSecondary,
          title: const Row(
            children: [
              Icon(Icons.trending_up_rounded, color: AppColors.successNeon),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Chỉ số năng lực tăng!',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bạn vừa được tăng chỉ số:',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              ...top.map(
                (g) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '• ${_labels[g.key] ?? g.key}: +${g.value.toStringAsFixed(0)}',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textPrimary),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tuyệt vời!'),
            ),
          ],
        ),
      );
    } catch (_) {
      // Ignore to avoid interrupting learning flow.
    }
  }

  static Map<String, double> _flatten(Map<String, dynamic> data) {
    final out = <String, double>{};
    void add(dynamic raw) {
      if (raw is! List) return;
      for (final item in raw) {
        if (item is! Map) continue;
        final key = item['key']?.toString();
        if (key == null || key.isEmpty) continue;
        final v = item['value'];
        final value =
            (v is num) ? v.toDouble() : double.tryParse(v.toString()) ?? 0;
        out[key] = value.clamp(0, 100).toDouble();
      }
    }

    add(data['learningMetrics']);
    add(data['humanMetrics']);
    return out;
  }
}

