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
  String? _logicalTooltip;
  String? _processingTooltip;
  String? _practicalTooltip;

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
      _logicalTooltip = null;
      _processingTooltip = null;
      _practicalTooltip = null;
    });

    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final data = await api.getUserCompetencies();

      final learningValues = _extractMetricValues(data['learningMetrics']);
      final humanValues = _extractMetricValues(data['humanMetrics']);
      _memoryTooltip = _buildMemoryTooltip(
        formula: data['formulaInfo'] is Map ? data['formulaInfo']['memory'] : null,
      );
      _logicalTooltip = _buildLogicalTooltip(
        formula:
            data['formulaInfo'] is Map ? data['formulaInfo']['logicalThinking'] : null,
      );
      _processingTooltip = _buildProcessingTooltip(
        formula:
            data['formulaInfo'] is Map ? data['formulaInfo']['processingSpeed'] : null,
      );
      _practicalTooltip = _buildPracticalTooltip(
        formula: data['formulaInfo'] is Map
            ? data['formulaInfo']['practicalApplication']
            : null,
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
          logicalTooltip: _logicalTooltip,
          processingTooltip: _processingTooltip,
          practicalTooltip: _practicalTooltip,
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
    String? logicalTooltip,
    String? processingTooltip,
    String? practicalTooltip,
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
      logicalTooltip: logicalTooltip,
      processingTooltip: processingTooltip,
      practicalTooltip: practicalTooltip,
    );
  }

  /// Tooltip chỉ hướng dẫn cách tăng điểm (không hiển thị công thức).
  String? _buildMemoryTooltip({dynamic formula}) {
    if (formula is! Map) return null;

    final version = formula['version'];
    if (version == 2) {
      return _memoryIncreaseHintsV2(formula);
    }

    return _memoryIncreaseHintsV1();
  }

  String _memoryIncreaseHintsV1() {
    return 'Cách tăng điểm Ghi nhớ:\n'
        '• Hoàn thành thêm bài học.\n'
        '• Giữ chuỗi ngày học liên tiếp.\n'
        '• Hoàn thành nhiều bài trong 7 ngày gần nhất.';
  }

  String _memoryIncreaseHintsV2(Map formula) {
    final qCount = (formula['quizAttemptCount'] ?? 0) as num;
    final lines = <String>[
      'Cách tăng điểm Ghi nhớ:',
      '• Học đều và giữ streak — hỗ trợ phần nền của chỉ số.',
      '• Làm end-quiz bài học; quay lại làm sau vài ngày (khoảng 3–14 ngày) để củng cố trí nhớ.',
      '• Ôn quiz: sau lần trước ít nhất khoảng 7 ngày, cố giữ hoặc cải thiện điểm.',
      '• Cố gắng đạt yêu cầu quiz ngay lần đầu làm.',
    ];
    if (qCount == 0) {
      lines.add(
        '• Bạn chưa có lịch sử nộp quiz — bắt đầu làm quiz để phần ghi nhớ được tính đầy đủ.',
      );
    }
    return lines.join('\n');
  }

  String? _buildLogicalTooltip({dynamic formula}) {
    final attemptCount =
        formula is Map ? ((formula['attemptCount'] ?? 0) as num).toInt() : 0;
    final lines = <String>[
      'Cách tăng điểm Tư duy logic:',
      '• Làm kỹ các câu suy luận đa bước (inference, sequence, compare, classification).',
      '• Tránh đoán nhanh; loại trừ đáp án sai theo từng bước lập luận.',
      '• Khi làm lại quiz, tập trung cải thiện các câu có tỷ lệ đóng góp cao vào logical_thinking.',
      '• Rà lại phần giải thích sau mỗi câu sai để sửa cách suy luận.',
    ];
    if (attemptCount == 0) {
      lines.add(
        '• Bạn chưa có dữ liệu quiz gần đây — làm end-quiz để bắt đầu có điểm logic.',
      );
    }
    return lines.join('\n');
  }

  String? _buildProcessingTooltip({dynamic formula}) {
    final validSamples =
        formula is Map ? ((formula['validSamples'] ?? 0) as num).toInt() : 0;
    final minSamples =
        formula is Map ? ((formula['minSamples'] ?? 20) as num).toInt() : 20;
    final lines = <String>[
      'Cách tăng điểm Tốc độ xử lý:',
      '• Ưu tiên trả lời đúng trước, rồi mới tối ưu tốc độ.',
      '• Luyện đều mỗi ngày để rút ngắn thời gian xử lý câu hỏi quen dạng.',
      '• Đọc đề theo từng ý chính, loại trừ nhanh đáp án sai rõ ràng.',
      '• Sau khi làm xong, xem lại câu sai để lần sau ra quyết định nhanh hơn.',
    ];
    if (validSamples < minSamples) {
      lines.add(
        '• Cần thêm dữ liệu trả lời (ít nhất $minSamples câu hợp lệ) để điểm ổn định.',
      );
    }
    return lines.join('\n');
  }

  String? _buildPracticalTooltip({dynamic formula}) {
    final weightedTotal =
        formula is Map ? (formula['weightedTotal'] ?? 0) as num : 0;
    final minWeightedTotal =
        formula is Map ? (formula['minWeightedTotal'] ?? 8) as num : 8;
    final provisional =
        formula is Map ? (formula['provisional'] ?? false) as bool : false;

    final lines = <String>[
      'Cách tăng điểm Ứng dụng thực tế:',
      '• Ưu tiên câu hỏi tình huống mới, có ngữ cảnh rõ ràng.',
      '• Trước khi chọn đáp án, xác định mục tiêu và ràng buộc của tình huống.',
      '• So sánh ưu/nhược từng phương án, tránh chọn theo cảm tính.',
      '• Sau câu sai, áp dụng lại ngay vào câu tương tự ở bài làm sau.',
    ];

    if (provisional || weightedTotal < minWeightedTotal) {
      lines.add('• Cần thêm dữ liệu câu có trọng số ứng dụng để điểm ổn định.');
    }

    return lines.join('\n');
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
  final String? logicalTooltip;
  final String? processingTooltip;
  final String? practicalTooltip;
  const _CompetencySectionData({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.items,
    this.memoryTooltip,
    this.logicalTooltip,
    this.processingTooltip,
    this.practicalTooltip,
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
                            logicalTooltip: section.logicalTooltip,
                            processingTooltip: section.processingTooltip,
                            practicalTooltip: section.practicalTooltip,
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
                                  memoryTooltip: section.memoryTooltip,
                                  logicalTooltip: section.logicalTooltip,
                                  processingTooltip: section.processingTooltip,
                                  practicalTooltip: section.practicalTooltip)),
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
  final String? logicalTooltip;
  final String? processingTooltip;
  final String? practicalTooltip;
  const _MetricList({
    required this.color,
    required this.items,
    this.memoryTooltip,
    this.logicalTooltip,
    this.processingTooltip,
    this.practicalTooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map((e) =>
              _MetricRow(
                color: color,
                item: e,
                memoryTooltip: memoryTooltip,
                logicalTooltip: logicalTooltip,
                processingTooltip: processingTooltip,
                practicalTooltip: practicalTooltip,
              ))
          .toList(),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final Color color;
  final _CompetencyItem item;
  final String? memoryTooltip;
  final String? logicalTooltip;
  final String? processingTooltip;
  final String? practicalTooltip;
  const _MetricRow({
    required this.color,
    required this.item,
    this.memoryTooltip,
    this.logicalTooltip,
    this.processingTooltip,
    this.practicalTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final v = item.value.clamp(0, 100).toDouble();
    final showMemoryTooltip = item.key == 'memory' && memoryTooltip != null;
    final showLogicalTooltip =
        item.key == 'logical_thinking' && logicalTooltip != null;
    final showProcessingTooltip =
        item.key == 'processing_speed' && processingTooltip != null;
    final showPracticalTooltip =
        item.key == 'practical_application' && practicalTooltip != null;
    final tooltipMessage = showMemoryTooltip
        ? memoryTooltip!
        : (showLogicalTooltip
            ? logicalTooltip!
            : (showProcessingTooltip
                ? processingTooltip!
                : (showPracticalTooltip ? practicalTooltip! : null)));
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
                    if (tooltipMessage != null)
                      Tooltip(
                        message: tooltipMessage,
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

