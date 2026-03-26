import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/theme/theme.dart';

class CompetenciesScreen extends StatefulWidget {
  const CompetenciesScreen({super.key});

  @override
  State<CompetenciesScreen> createState() => _CompetenciesScreenState();
}

class _CompetenciesScreenState extends State<CompetenciesScreen> {
  bool _loading = true;
  String? _error;
  late _CompetencySectionData _learning;
  late _CompetencySectionData _human;
  String? _memoryTooltip;

  static const List<_CompetencyItem> _learningTemplate = [
    _CompetencyItem(
      key: 'memory',
      label: 'Ghi nhớ',
      description: 'Recall test sau 3–7 ngày (spaced repetition)',
      value: 0,
    ),
    _CompetencyItem(
      key: 'logical_thinking',
      label: 'Tư duy logic',
      description: 'Quiz suy luận đa bước, bài toán chuỗi',
      value: 0,
    ),
    _CompetencyItem(
      key: 'processing_speed',
      label: 'Tốc độ xử lý',
      description: 'Điểm + độ chính xác + thời gian trả lời',
      value: 0,
    ),
    _CompetencyItem(
      key: 'practical_application',
      label: 'Ứng dụng thực tế',
      description: 'Bài tình huống mới, transfer test',
      value: 0,
    ),
    _CompetencyItem(
      key: 'metacognition',
      label: 'Siêu nhận thức',
      description: 'Calibration: tự tin trước vs đúng/sai sau',
      value: 0,
    ),
    _CompetencyItem(
      key: 'learning_persistence',
      label: 'Bền bỉ học tập',
      description: 'Chuỗi ngày, tỷ lệ hoàn thành, không bỏ giữa chừng',
      value: 0,
    ),
    _CompetencyItem(
      key: 'knowledge_absorption',
      label: 'Tiếp thu kiến thức',
      description: 'Điểm trước vs sau bài học (gain score)',
      value: 0,
    ),
  ];

  static const List<_CompetencyItem> _humanTemplate = [
    _CompetencyItem(
      key: 'systems_thinking',
      label: 'Tư duy hệ thống',
      description: 'Bài đánh giá nhìn toàn cục, kết nối ý tưởng',
      value: 0,
    ),
    _CompetencyItem(
      key: 'creativity',
      label: 'Sáng tạo',
      description: 'Bài mở, liên kết khái niệm từ nhiều lĩnh vực',
      value: 0,
    ),
    _CompetencyItem(
      key: 'communication',
      label: 'Giao tiếp & diễn đạt',
      description: 'Giải thích lại cho người khác (peer teaching)',
      value: 0,
    ),
    _CompetencyItem(
      key: 'self_leadership',
      label: 'Lãnh đạo bản thân',
      description: 'Tự đặt mục tiêu, tự theo dõi tiến độ',
      value: 0,
    ),
    _CompetencyItem(
      key: 'discipline',
      label: 'Kỷ luật & thói quen',
      description: 'Tần suất học, giờ học cố định, không trì hoãn',
      value: 0,
    ),
    _CompetencyItem(
      key: 'growth_mindset',
      label: 'Mindset tăng trưởng',
      description: 'Tỷ lệ thử lại sau sai, học từ lỗi',
      value: 0,
    ),
    _CompetencyItem(
      key: 'critical_thinking',
      label: 'Tư duy phản biện',
      description: 'Đánh giá độ tin cậy nguồn, phản biện luận điểm',
      value: 0,
    ),
    _CompetencyItem(
      key: 'collaboration',
      label: 'Cộng tác & chia sẻ',
      description: 'Đóng góp nhóm, thảo luận, giải thích cho bạn',
      value: 0,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _learning = _buildSection(
      title: 'Năng lực học tập',
      subtitle: 'Đo qua hành vi trong ứng dụng',
      color: AppColors.cyanNeon,
      template: _learningTemplate,
      values: const {},
    );
    _human = _buildSection(
      title: 'Năng lực con người',
      subtitle: 'Đo qua pattern & đánh giá',
      color: AppColors.orangeNeon,
      template: _humanTemplate,
      values: const {},
    );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _memoryTooltip = null;
    });

    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final data = await api.getUserCompetencies();

      final learningValues = _extractMetricValues(data['learningMetrics']);
      final humanValues = _extractMetricValues(data['humanMetrics']);
      _memoryTooltip = _buildMemoryTooltip(
        formula: data['formulaInfo'] is Map ? data['formulaInfo']['memory'] : null,
        memoryScore: learningValues['memory'] ?? 0,
      );

      if (!mounted) return;
      setState(() {
        _learning = _buildSection(
          title: 'Năng lực học tập',
          subtitle: 'Đo qua hành vi trong ứng dụng',
          color: AppColors.cyanNeon,
          template: _learningTemplate,
          values: learningValues,
          memoryTooltip: _memoryTooltip,
        );
        _human = _buildSection(
          title: 'Năng lực con người',
          subtitle: 'Đo qua pattern & đánh giá',
          color: AppColors.orangeNeon,
          template: _humanTemplate,
          values: humanValues,
        );
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Map<String, double> _extractMetricValues(dynamic raw) {
    final out = <String, double>{};
    if (raw is! List) return out;
    for (final e in raw) {
      if (e is! Map) continue;
      final key = e['key']?.toString();
      final valueRaw = e['value'];
      if (key == null || key.isEmpty) continue;
      final value = valueRaw is num ? valueRaw.toDouble() : double.tryParse('$valueRaw') ?? 0;
      out[key] = value.clamp(0, 100).toDouble();
    }
    return out;
  }

  _CompetencySectionData _buildSection({
    required String title,
    required String subtitle,
    required Color color,
    required List<_CompetencyItem> template,
    required Map<String, double> values,
    String? memoryTooltip,
  }) {
    final items = template
        .map((t) => _CompetencyItem(
              key: t.key,
              label: t.label,
              description: t.description,
              value: values[t.key] ?? 0,
            ))
        .toList();
    return _CompetencySectionData(
      title: title,
      subtitle: subtitle,
      color: color,
      items: items,
      memoryTooltip: memoryTooltip,
    );
  }

  String? _buildMemoryTooltip({dynamic formula, required double memoryScore}) {
    if (formula is! Map) return null;

    final completedNodes = (formula['completedNodes'] ?? 0) as num;
    final currentStreak = (formula['currentStreak'] ?? 0) as num;
    final completedLast7Days = (formula['completedLast7Days'] ?? 0) as num;

    final completedNorm = math.min(1.0, completedNodes.toDouble() / 80.0);
    final streakNorm = math.min(1.0, currentStreak.toDouble() / 14.0);
    final weeklyNorm = math.min(1.0, completedLast7Days.toDouble() / 12.0);

    final calc = (completedNorm * 0.55 + streakNorm * 0.30 + weeklyNorm * 0.15) *
        100.0;
    final rounded = calc.round();

    final increaseHints = [
      'Hoàn thành nhiều bài học (completedNodes)',
      'Duy trì chuỗi ngày (currentStreak)',
      'Hoàn thành bài trong 7 ngày gần nhất (completedLast7Days)',
    ].join('\n- ');

    return 'Ghi nhớ đang tính từ:\n'
        '- completedNodes = $completedNodes (trọng số 55%)\n'
        '- currentStreak = $currentStreak (trọng số 30%)\n'
        '- completedLast7Days = $completedLast7Days (trọng số 15%)\n\n'
        'Cách tính:\n'
        'completedNorm=min(1, completedNodes/80)\n'
        'streakNorm=min(1, currentStreak/14)\n'
        'weeklyNorm=min(1, completedLast7Days/12)\n'
        'MemoryScore=round((completedNorm*0.55 + streakNorm*0.30 + weeklyNorm*0.15)*100)\n\n'
        'Kết quả hệ thống ≈ $rounded (bên UI: ${memoryScore.toStringAsFixed(0)})\n\n'
        'Cách để tăng điểm:\n- $increaseHints';
  }

  @override
  Widget build(BuildContext context) {
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
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.purpleNeon),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Không tải được chỉ số',
                          style: AppTextStyles.bodyLarge
                              .copyWith(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _error!,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textTertiary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, c) {
                    final wide = c.maxWidth >= 900;
                    final children = [
                      _CompetencySection(section: _learning),
                      _CompetencySection(section: _human),
                    ];

                    return RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.purpleNeon,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
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
  final String? memoryTooltip;
  const _CompetencySectionData({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.items,
    this.memoryTooltip,
  });

  double get average =>
      items.isEmpty ? 0 : items.map((e) => e.value).reduce((a, b) => a + b) / items.length;
}

class _CompetencyItem {
  final String key;
  final String label;
  final String description;
  final double value; // 0..100
  const _CompetencyItem({
    required this.key,
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
                          _MetricList(
                            color: section.color,
                            items: section.items,
                            memoryTooltip: section.memoryTooltip,
                          ),
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
                                  color: section.color,
                                  items: section.items,
                                  memoryTooltip: section.memoryTooltip)),
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
  final String? memoryTooltip;
  const _MetricList({
    required this.color,
    required this.items,
    this.memoryTooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map((e) =>
              _MetricRow(color: color, item: e, memoryTooltip: memoryTooltip))
          .toList(),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final Color color;
  final _CompetencyItem item;
  final String? memoryTooltip;
  const _MetricRow({
    required this.color,
    required this.item,
    this.memoryTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final v = item.value.clamp(0, 100).toDouble();
    final showMemoryTooltip = item.key == 'memory' && memoryTooltip != null;
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.label,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (showMemoryTooltip)
                      Tooltip(
                        message: memoryTooltip!,
                        triggerMode: TooltipTriggerMode.tap,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                  ],
                ),
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

