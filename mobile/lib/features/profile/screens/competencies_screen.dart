import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:edtech_mobile/theme/theme.dart';

class CompetenciesScreen extends StatelessWidget {
  const CompetenciesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for UI preview. Replace with API later.
    final learning = _CompetencySectionData(
      title: 'Năng lực học tập',
      subtitle: 'Đo qua hành vi trong ứng dụng',
      color: AppColors.cyanNeon,
      items: const [
        _CompetencyItem(
          label: 'Ghi nhớ',
          description: 'Recall test sau 3–7 ngày (spaced repetition)',
          value: 0,
        ),
        _CompetencyItem(
          label: 'Tư duy logic',
          description: 'Quiz suy luận đa bước, bài toán chuỗi',
          value: 0,
        ),
        _CompetencyItem(
          label: 'Tốc độ xử lý',
          description: 'Điểm + độ chính xác + thời gian trả lời',
          value: 0,
        ),
        _CompetencyItem(
          label: 'Ứng dụng thực tế',
          description: 'Bài tình huống mới, transfer test',
          value: 0,
        ),
        _CompetencyItem(
          label: 'Siêu nhận thức',
          description: 'Calibration: tự tin trước vs đúng/sai sau',
          value: 0,
        ),
        _CompetencyItem(
          label: 'Bền bỉ học tập',
          description: 'Chuỗi ngày, tỷ lệ hoàn thành, không bỏ giữa chừng',
          value: 0,
        ),
        _CompetencyItem(
          label: 'Tiếp thu kiến thức',
          description: 'Điểm trước vs sau bài học (gain score)',
          value: 0,
        ),
      ],
    );

    final human = _CompetencySectionData(
      title: 'Năng lực con người',
      subtitle: 'Đo qua pattern & đánh giá',
      color: AppColors.orangeNeon,
      items: const [
        _CompetencyItem(
          label: 'Tư duy hệ thống',
          description: 'Bài đánh giá nhìn toàn cục, kết nối ý tưởng',
          value: 0,
        ),
        _CompetencyItem(
          label: 'Sáng tạo',
          description: 'Bài mở, liên kết khái niệm từ nhiều lĩnh vực',
          value: 0,
        ),
        _CompetencyItem(
          label: 'Giao tiếp & diễn đạt',
          description: 'Giải thích lại cho người khác (peer teaching)',
          value: 0,
        ),
        _CompetencyItem(
          label: 'Lãnh đạo bản thân',
          description: 'Tự đặt mục tiêu, tự theo dõi tiến độ',
          value: 0,
        ),
        _CompetencyItem(
          label: 'Kỷ luật & thói quen',
          description: 'Tần suất học, giờ học cố định, không trì hoãn',
          value: 0,
        ),
        _CompetencyItem(
          label: 'Mindset tăng trưởng',
          description: 'Tỷ lệ thử lại sau sai, học từ lỗi',
          value: 0,
        ),
        _CompetencyItem(
          label: 'Tư duy phản biện',
          description: 'Đánh giá độ tin cậy nguồn, phản biện luận điểm',
          value: 0,
        ),
        _CompetencyItem(
          label: 'Cộng tác & chia sẻ',
          description: 'Đóng góp nhóm, thảo luận, giải thích cho bạn',
          value: 0,
        ),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Năng lực',
          style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 900;
          final children = [
            _CompetencySection(section: learning),
            _CompetencySection(section: human),
          ];

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: children[0]),
                      const SizedBox(width: 16),
                      Expanded(child: children[1]),
                    ],
                  )
                : Column(
                    children: [
                      children[0],
                      const SizedBox(height: 16),
                      children[1],
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _CompetencySectionData {
  final String title;
  final String subtitle;
  final Color color;
  final List<_CompetencyItem> items;
  const _CompetencySectionData({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.items,
  });

  double get average =>
      items.isEmpty ? 0 : items.map((e) => e.value).reduce((a, b) => a + b) / items.length;
}

class _CompetencyItem {
  final String label;
  final String description;
  final double value; // 0..100
  const _CompetencyItem({
    required this.label,
    required this.description,
    required this.value,
  });
}

class _CompetencySection extends StatelessWidget {
  final _CompetencySectionData section;
  const _CompetencySection({required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final compact = c.maxWidth < 620;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(section.title,
                    style: AppTextStyles.h4.copyWith(color: section.color)),
                const SizedBox(height: 4),
                Text(section.subtitle,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textTertiary)),
                const SizedBox(height: 14),
                compact
                    ? Column(
                        children: [
                          _RadarCard(
                            color: section.color,
                            items: section.items,
                            average: section.average,
                          ),
                          const SizedBox(height: 12),
                          _MetricList(color: section.color, items: section.items),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: math.min(260, c.maxWidth * 0.38),
                            child: _RadarCard(
                              color: section.color,
                              items: section.items,
                              average: section.average,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _MetricList(
                                  color: section.color, items: section.items)),
                        ],
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RadarCard extends StatelessWidget {
  final Color color;
  final List<_CompetencyItem> items;
  final double average;
  const _RadarCard({
    required this.color,
    required this.items,
    required this.average,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgTertiary.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: _RadarChart(
              color: color,
              items: items,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            average.toStringAsFixed(0),
            style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
          ),
          Text(
            'điểm trung bình',
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _MetricList extends StatelessWidget {
  final Color color;
  final List<_CompetencyItem> items;
  const _MetricList({required this.color, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((e) => _MetricRow(color: color, item: e)).toList(),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final Color color;
  final _CompetencyItem item;
  const _MetricRow({required this.color, required this.item});

  @override
  Widget build(BuildContext context) {
    final v = item.value.clamp(0, 100).toDouble();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgTertiary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.85),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label,
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(item.description,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textTertiary)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  v.toStringAsFixed(0),
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.textSecondary),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    inactiveTrackColor:
                        AppColors.borderPrimary.withValues(alpha: 0.8),
                    activeTrackColor: color.withValues(alpha: 0.9),
                    thumbColor: color,
                    overlayShape: SliderComponentShape.noOverlay,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  ),
                  child: Slider(
                    value: v / 100.0,
                    onChanged: null, // read-only
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarChart extends StatelessWidget {
  final Color color;
  final List<_CompetencyItem> items;
  const _RadarChart({required this.color, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final values = items.map((e) => (e.value.clamp(0, 100) / 100.0)).toList();

    return RadarChart(
      RadarChartData(
        radarBackgroundColor: Colors.transparent,
        borderData: FlBorderData(show: false),
        radarBorderData: BorderSide(color: AppColors.borderPrimary),
        tickBorderData: BorderSide(color: AppColors.borderPrimary.withValues(alpha: 0.7)),
        gridBorderData: BorderSide(color: AppColors.borderPrimary.withValues(alpha: 0.4)),
        ticksTextStyle: AppTextStyles.caption.copyWith(
          color: AppColors.textTertiary,
          fontSize: 10,
        ),
        titleTextStyle: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        getTitle: (index, angle) {
          final t = items[index].label;
          return RadarChartTitle(text: t, angle: angle);
        },
        tickCount: 4,
        dataSets: [
          RadarDataSet(
            fillColor: color.withValues(alpha: 0.18),
            borderColor: color.withValues(alpha: 0.9),
            borderWidth: 2,
            entryRadius: 2.5,
            dataEntries: values.map((v) => RadarEntry(value: v)).toList(),
          ),
        ],
      ),
    );
  }
}

