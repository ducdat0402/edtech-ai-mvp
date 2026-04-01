import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/theme/theme.dart';

class CompetenciesScreen extends StatefulWidget {
  const CompetenciesScreen({super.key, this.initialFocus});

  /// `learning` | `human` — cuộn tới khối tương ứng sau khi tải xong.
  final String? initialFocus;

  @override
  State<CompetenciesScreen> createState() => _CompetenciesScreenState();
}

class _CompetenciesScreenState extends State<CompetenciesScreen> {
  bool _loading = true;
  String? _error;
  late _CompetencySectionData _learning;
  late _CompetencySectionData _human;
  final GlobalKey _learningSectionKey = GlobalKey();
  final GlobalKey _humanSectionKey = GlobalKey();
  bool _didScrollToInitialFocus = false;
  String? _memoryTooltip;
  String? _logicalTooltip;
  String? _processingTooltip;
  String? _practicalTooltip;
  String? _metacognitionTooltip;
  String? _persistenceTooltip;
  String? _knowledgeTooltip;
  String? _systemsThinkingTooltip;
  String? _creativityTooltip;
  String? _communicationTooltip;
  String? _selfLeadershipTooltip;
  String? _disciplineTooltip;
  String? _growthMindsetTooltip;
  String? _criticalThinkingTooltip;
  String? _collaborationTooltip;

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
      _metacognitionTooltip = null;
      _persistenceTooltip = null;
      _knowledgeTooltip = null;
      _systemsThinkingTooltip = null;
      _creativityTooltip = null;
      _communicationTooltip = null;
      _selfLeadershipTooltip = null;
      _disciplineTooltip = null;
      _growthMindsetTooltip = null;
      _criticalThinkingTooltip = null;
      _collaborationTooltip = null;
    });

    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final data = await api.getUserCompetencies();

      final learningValues = _extractMetricValues(data['learningMetrics']);
      final humanValues = _extractMetricValues(data['humanMetrics']);
      _memoryTooltip = _buildMemoryTooltip(
        formula:
            data['formulaInfo'] is Map ? data['formulaInfo']['memory'] : null,
      );
      _logicalTooltip = _buildLogicalTooltip(
        formula: data['formulaInfo'] is Map
            ? data['formulaInfo']['logicalThinking']
            : null,
      );
      _processingTooltip = _buildProcessingTooltip(
        formula: data['formulaInfo'] is Map
            ? data['formulaInfo']['processingSpeed']
            : null,
      );
      _practicalTooltip = _buildPracticalTooltip(
        formula: data['formulaInfo'] is Map
            ? data['formulaInfo']['practicalApplication']
            : null,
      );
      _metacognitionTooltip = _buildMetacognitionTooltip(
        formula: data['formulaInfo'] is Map
            ? data['formulaInfo']['metacognition']
            : null,
      );
      _persistenceTooltip = _buildPersistenceTooltip(
        formula: data['formulaInfo'] is Map
            ? data['formulaInfo']['learningPersistence']
            : null,
      );
      _knowledgeTooltip = _buildKnowledgeTooltip(
        formula: data['formulaInfo'] is Map
            ? data['formulaInfo']['knowledgeAbsorption']
            : null,
      );
      _systemsThinkingTooltip = _buildSystemsThinkingTooltip(
        formula: data['formulaInfo'] is Map
            ? data['formulaInfo']['systemsThinking']
            : null,
      );
      _creativityTooltip = _buildCreativityTooltip(
        formula:
            data['formulaInfo'] is Map ? data['formulaInfo']['creativity'] : null,
      );
      _communicationTooltip = _buildCommunicationTooltip(
        formula:
            data['formulaInfo'] is Map ? data['formulaInfo']['communication'] : null,
      );
      _selfLeadershipTooltip = _buildSelfLeadershipTooltip(
        formula:
            data['formulaInfo'] is Map ? data['formulaInfo']['selfLeadership'] : null,
      );
      _disciplineTooltip = _buildDisciplineTooltip(
        formula:
            data['formulaInfo'] is Map ? data['formulaInfo']['discipline'] : null,
      );
      _growthMindsetTooltip = _buildGrowthMindsetTooltip(
        formula:
            data['formulaInfo'] is Map ? data['formulaInfo']['growthMindset'] : null,
      );
      _criticalThinkingTooltip = _buildCriticalThinkingTooltip(
        formula: data['formulaInfo'] is Map
            ? data['formulaInfo']['criticalThinking']
            : null,
      );
      _collaborationTooltip = _buildCollaborationTooltip(
        formula:
            data['formulaInfo'] is Map ? data['formulaInfo']['collaboration'] : null,
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
          metacognitionTooltip: _metacognitionTooltip,
          persistenceTooltip: _persistenceTooltip,
          knowledgeTooltip: _knowledgeTooltip,
        );
        _human = _buildSection(
          title: 'Năng lực con người',
          subtitle: 'Đo qua pattern & đánh giá',
          color: AppColors.orangeNeon,
          template: _humanTemplate,
          values: humanValues,
          systemsThinkingTooltip: _systemsThinkingTooltip,
          creativityTooltip: _creativityTooltip,
          communicationTooltip: _communicationTooltip,
          selfLeadershipTooltip: _selfLeadershipTooltip,
          disciplineTooltip: _disciplineTooltip,
          growthMindsetTooltip: _growthMindsetTooltip,
          criticalThinkingTooltip: _criticalThinkingTooltip,
          collaborationTooltip: _collaborationTooltip,
        );
        _loading = false;
      });
      _scheduleScrollToInitialFocus();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _scheduleScrollToInitialFocus() {
    final focus = widget.initialFocus?.toLowerCase();
    if (focus != 'learning' && focus != 'human') return;
    if (_didScrollToInitialFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didScrollToInitialFocus) return;
      final ctx = focus == 'human'
          ? _humanSectionKey.currentContext
          : _learningSectionKey.currentContext;
      if (ctx != null) {
        _didScrollToInitialFocus = true;
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          alignment: 0.08,
        );
      }
    });
  }

  Map<String, double> _extractMetricValues(dynamic raw) {
    final out = <String, double>{};
    if (raw is! List) return out;
    for (final e in raw) {
      if (e is! Map) continue;
      final key = e['key']?.toString();
      final valueRaw = e['value'];
      if (key == null || key.isEmpty) continue;
      final value = valueRaw is num
          ? valueRaw.toDouble()
          : double.tryParse('$valueRaw') ?? 0;
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
    String? metacognitionTooltip,
    String? persistenceTooltip,
    String? knowledgeTooltip,
    String? systemsThinkingTooltip,
    String? creativityTooltip,
    String? communicationTooltip,
    String? selfLeadershipTooltip,
    String? disciplineTooltip,
    String? growthMindsetTooltip,
    String? criticalThinkingTooltip,
    String? collaborationTooltip,
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
      metacognitionTooltip: metacognitionTooltip,
      persistenceTooltip: persistenceTooltip,
      knowledgeTooltip: knowledgeTooltip,
      systemsThinkingTooltip: systemsThinkingTooltip,
      creativityTooltip: creativityTooltip,
      communicationTooltip: communicationTooltip,
      selfLeadershipTooltip: selfLeadershipTooltip,
      disciplineTooltip: disciplineTooltip,
      growthMindsetTooltip: growthMindsetTooltip,
      criticalThinkingTooltip: criticalThinkingTooltip,
      collaborationTooltip: collaborationTooltip,
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
    final provisional =
        formula is Map ? (formula['provisional'] ?? false) as bool : false;
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
    if (provisional) {
      lines.add('• Điểm đang tạm thời do chưa đủ dữ liệu đo.');
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
      lines.add('• Điểm đang tạm thời do chưa đủ dữ liệu đo.');
    }

    return lines.join('\n');
  }

  String? _buildMetacognitionTooltip({dynamic formula}) {
    if (formula is! Map) return null;

    final validSamples =
        (formula['validSamples'] ?? 0) as num;
    final minSamples =
        (formula['minSamples'] ?? 20) as num;
    final provisional = (formula['provisional'] ?? false) as bool;

    final lines = <String>[
      'Cách tăng điểm Siêu nhận thức:',
      '• Ước lượng tự tin sát với xác suất đúng của bạn (đừng quá cao/đừng quá thấp).',
      '• Làm xong bài, xem kết quả để điều chỉnh cách đánh giá “mình biết đến đâu”.',
      '• Khi gặp câu tương tự lần sau, áp dụng đúng mức tự tin bạn vừa calibrate.',
      '• Tránh đoán bừa: đoán chỉ nên đi kèm tự tin thấp.',
    ];

    if (provisional || validSamples < minSamples) {
      lines.add('• Cần thêm dữ liệu quiz có confidence để điểm ổn định.');
      lines.add('• Điểm đang tạm thời do chưa đủ dữ liệu đo.');
    }

    return lines.join('\n');
  }

  String? _buildPersistenceTooltip({dynamic formula}) {
    final activeDays =
        formula is Map ? ((formula['activeDays'] ?? 0) as num).toInt() : 0;
    final weeklyConsistency =
        formula is Map ? ((formula['weeklyConsistency'] ?? 0) as num).toInt() : 0;
    final lines = <String>[
      'Cách tăng điểm Bền bỉ học tập:',
      '• Học đều nhiều ngày trong tuần, tránh dồn bài vào một ngày.',
      '• Giữ streak liên tục để tạo nhịp học ổn định.',
      '• Mỗi tuần cố gắng có ít nhất 3 ngày học.',
      '• Duy trì nhịp này qua nhiều tuần liên tiếp.',
    ];
    if (activeDays < 10 || weeklyConsistency < 2) {
      lines.add('• Bạn cần tăng tần suất học theo tuần để điểm lên rõ hơn.');
    }
    return lines.join('\n');
  }

  String? _buildKnowledgeTooltip({dynamic formula}) {
    final gainGroups =
        formula is Map ? ((formula['gainGroupCount'] ?? 0) as num).toInt() : 0;
    final provisional =
        formula is Map ? (formula['provisional'] ?? false) as bool : false;
    final lines = <String>[
      'Cách tăng điểm Tiếp thu kiến thức:',
      '• Sau khi làm quiz, xem kỹ câu sai và phần giải thích.',
      '• Làm lại quiz cùng bài sau khi ôn để tăng điểm so với lần đầu.',
      '• Tập trung cải thiện các phần bạn hay sai, không chỉ làm cho đủ lượt.',
      '• Theo dõi tiến bộ qua nhiều lần làm để tăng learning gain.',
    ];
    if (gainGroups < 2 || provisional) {
      lines.add('• Cần thêm các lần làm lại cùng bài để hệ thống đo mức tiến bộ rõ hơn.');
      lines.add('• Điểm đang tạm thời do chưa đủ dữ liệu đo.');
    }
    return lines.join('\n');
  }

  String? _buildSystemsThinkingTooltip({dynamic formula}) {
    if (formula is! Map) return null;

    final weightedTotal =
        (formula['weightedTotal'] ?? 0) as num; // sum of systems weights
    final minWeightedTotal =
        (formula['minWeightedTotal'] ?? 8) as num; // stability threshold
    final provisional = (formula['provisional'] ?? false) as bool;

    final lines = <String>[
      'Cách tăng điểm Tư duy hệ thống:',
      '• Khi gặp vấn đề, xác định yếu tố và mối quan hệ giữa chúng.',
      '• Dự đoán tác động dây chuyền khi thay đổi 1 phần trong hệ.',
      '• So sánh trade-off: tăng 1 mục có thể làm giảm mục khác.',
      '• Trả lời theo logic “nguyên nhân -> kết quả”, không theo cảm tính.',
    ];

    if (provisional || weightedTotal < minWeightedTotal) {
      lines.add('• Cần thêm dữ liệu câu có trọng số “systems_thinking” để điểm ổn định.');
      lines.add('• Điểm đang tạm thời do chưa đủ dữ liệu đo.');
    }

    return lines.join('\n');
  }

  String? _buildCreativityTooltip({dynamic formula}) {
    if (formula is! Map) return null;

    final weightedTotal = (formula['weightedTotal'] ?? 0) as num;
    final minWeightedTotal = (formula['minWeightedTotal'] ?? 8) as num;
    final provisional = (formula['provisional'] ?? false) as bool;

    final lines = <String>[
      'Cách tăng điểm Sáng tạo:',
      '• Trước khi trả lời, nghĩ tối thiểu 2 hướng giải khác nhau.',
      '• Ưu tiên phương án có liên hệ chéo giữa nhiều ý tưởng.',
      '• Nêu rõ lý do chọn hướng giải để tránh trả lời theo quán tính.',
      '• Sau khi xem đáp án, rút ra một cách tiếp cận mới cho câu tương tự.',
    ];

    if (provisional || weightedTotal < minWeightedTotal) {
      lines.add('• Cần thêm dữ liệu câu có trọng số “creativity” để điểm ổn định.');
      lines.add('• Điểm đang tạm thời do chưa đủ dữ liệu đo.');
    }

    return lines.join('\n');
  }

  String? _buildCommunicationTooltip({dynamic formula}) {
    if (formula is! Map) return null;

    final sampleCount = ((formula['sampleCount'] ?? 0) as num).toInt();
    final minSamples = ((formula['minSamples'] ?? 3) as num).toInt();
    final provisional = (formula['provisional'] ?? false) as bool;

    final lines = <String>[
      'Cách tăng điểm Giao tiếp & diễn đạt:',
      '• Giải thích lại kiến thức theo thứ tự: khái niệm -> ví dụ -> ứng dụng.',
      '• Viết ngắn gọn, tránh câu dài và từ mơ hồ.',
      '• Ưu tiên cách nói để người mới học cũng hiểu được.',
      '• Sau feedback, viết lại và cải thiện điểm ở lần sau.',
    ];

    if (provisional || sampleCount < minSamples) {
      lines.add('• Cần thêm bài "giảng lại kiến thức" để điểm ổn định.');
      lines.add('• Điểm đang tạm thời do chưa đủ dữ liệu đo.');
    }

    return lines.join('\n');
  }

  String? _buildSelfLeadershipTooltip({dynamic formula}) {
    if (formula is! Map) return null;
    final weekCount = ((formula['weekCount'] ?? 0) as num).toInt();
    final minWeeks = ((formula['minWeeks'] ?? 2) as num).toInt();
    final provisional = (formula['provisional'] ?? false) as bool;
    final lines = <String>[
      'Cách tăng điểm Lãnh đạo bản thân:',
      '• Đặt cam kết tuần rõ ràng, vừa sức và đo được.',
      '• Học đúng các ngày đã cam kết để tạo nhịp ổn định.',
      '• Khi lệch kế hoạch, ghi lại 1 hành động điều chỉnh cho phiên sau.',
      '• Cuối tuần review mục tiêu và tăng dần độ thử thách.',
    ];
    if (provisional || weekCount < minWeeks) {
      lines.add('• Cần thêm dữ liệu ít nhất 2 tuần để điểm ổn định.');
      lines.add('• Điểm đang tạm thời do chưa đủ dữ liệu đo.');
    }
    return lines.join('\n');
  }

  String? _buildDisciplineTooltip({dynamic formula}) {
    if (formula is! Map) return null;
    final activeDays = ((formula['activeDays'] ?? 0) as num).toInt();
    final weeklyRhythmWeeks = ((formula['weeklyRhythmWeeks'] ?? 0) as num).toInt();
    final provisional = (formula['provisional'] ?? false) as bool;
    final lines = <String>[
      'Cách tăng điểm Kỷ luật & thói quen:',
      '• Học đều nhiều ngày trong tuần, không dồn bài vào một hôm.',
      '• Duy trì tối thiểu 3 ngày học mỗi tuần để giữ nhịp ổn định.',
      '• Cố gắng học vào khung giờ quen thuộc để tạo thói quen bền.',
      '• Khi bỏ lỡ 1 buổi, quay lại ngay buổi kế tiếp thay vì bỏ luôn cả tuần.',
    ];
    if (provisional || activeDays < 10 || weeklyRhythmWeeks < 2) {
      lines.add('• Cần thêm dữ liệu học đều theo tuần để điểm ổn định.');
      lines.add('• Điểm đang tạm thời do chưa đủ dữ liệu đo.');
    }
    return lines.join('\n');
  }

  String? _buildGrowthMindsetTooltip({dynamic formula}) {
    if (formula is! Map) return null;
    final failGroups = ((formula['failGroups'] ?? 0) as num).toInt();
    final provisional = (formula['provisional'] ?? false) as bool;
    final lines = <String>[
      'Cách tăng điểm Mindset tăng trưởng:',
      '• Sau khi sai, quay lại làm lại sớm thay vì bỏ qua.',
      '• Xem kỹ lý do sai và đổi chiến lược trước lần thử tiếp theo.',
      '• So sánh điểm trước/sau mỗi lần thử để thấy tiến bộ thật.',
      '• Ưu tiên cải thiện ở các bài từng làm chưa tốt.',
    ];
    if (provisional || failGroups < 3) {
      lines.add('• Cần thêm dữ liệu fail -> retry để điểm ổn định.');
      lines.add('• Điểm đang tạm thời do chưa đủ dữ liệu đo.');
    }
    return lines.join('\n');
  }

  String? _buildCriticalThinkingTooltip({dynamic formula}) {
    if (formula is! Map) return null;
    final failGroups = ((formula['failGroups'] ?? 0) as num).toInt();
    final provisional = (formula['provisional'] ?? false) as bool;
    final lines = <String>[
      'Cách tăng điểm Tư duy phản biện:',
      '• Trước khi chọn đáp án, so sánh ít nhất 2 phương án theo bằng chứng.',
      '• Tìm giả định ẩn và điểm yếu trong từng lập luận.',
      '• Ưu tiên kết luận có dữ liệu hỗ trợ, tránh chọn theo cảm tính.',
      '• Sau câu sai, đổi cách lập luận và thử lại để cải thiện.',
    ];
    if (provisional || failGroups < 3) {
      lines.add('• Cần thêm dữ liệu câu phản biện và chu kỳ fail -> retry để điểm ổn định.');
      lines.add('• Điểm đang tạm thời do chưa đủ dữ liệu đo.');
    }
    return lines.join('\n');
  }

  String? _buildCollaborationTooltip({dynamic formula}) {
    if (formula is! Map) return null;
    final peerCount = ((formula['uniquePeerCount'] ?? 0) as num).toInt();
    final interactions =
        ((formula['publicMessageCount'] ?? 0) as num).toInt() +
        ((formula['dmSentCount'] ?? 0) as num).toInt();
    final provisional = (formula['provisional'] ?? false) as bool;
    final lines = <String>[
      'Cách tăng điểm Cộng tác & chia sẻ:',
      '• Chủ động chia sẻ cách giải hoặc ghi chú hữu ích cho người khác.',
      '• Tham gia thảo luận với nhiều bạn khác nhau, không chỉ một nhóm cố định.',
      '• Tạo trao đổi hai chiều: hỏi, phản hồi, và follow-up sau khi nhận góp ý.',
      '• Duy trì nhịp tương tác đều đặn theo tuần thay vì chỉ hoạt động ngắt quãng.',
    ];
    if (provisional || interactions < 8 || peerCount < 2) {
      lines.add('• Cần thêm dữ liệu tương tác xã hội để điểm ổn định.');
      lines.add('• Điểm đang tạm thời do chưa đủ dữ liệu đo.');
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
                      _CompetencySection(
                        key: _learningSectionKey,
                        section: _learning,
                      ),
                      _CompetencySection(
                        key: _humanSectionKey,
                        section: _human,
                      ),
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
  final String? metacognitionTooltip;
  final String? persistenceTooltip;
  final String? knowledgeTooltip;
  final String? systemsThinkingTooltip;
  final String? creativityTooltip;
  final String? communicationTooltip;
  final String? selfLeadershipTooltip;
  final String? disciplineTooltip;
  final String? growthMindsetTooltip;
  final String? criticalThinkingTooltip;
  final String? collaborationTooltip;
  const _CompetencySectionData({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.items,
    this.memoryTooltip,
    this.logicalTooltip,
    this.processingTooltip,
    this.practicalTooltip,
    this.metacognitionTooltip,
    this.persistenceTooltip,
    this.knowledgeTooltip,
    this.systemsThinkingTooltip,
    this.creativityTooltip,
    this.communicationTooltip,
    this.selfLeadershipTooltip,
    this.disciplineTooltip,
    this.growthMindsetTooltip,
    this.criticalThinkingTooltip,
    this.collaborationTooltip,
  });

  double get average => items.isEmpty
      ? 0
      : items.map((e) => e.value).reduce((a, b) => a + b) / items.length;
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
  const _CompetencySection({super.key, required this.section});

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
                            metacognitionTooltip: section.metacognitionTooltip,
                            persistenceTooltip: section.persistenceTooltip,
                            knowledgeTooltip: section.knowledgeTooltip,
                            systemsThinkingTooltip:
                                section.systemsThinkingTooltip,
                            creativityTooltip: section.creativityTooltip,
                            communicationTooltip: section.communicationTooltip,
                            selfLeadershipTooltip: section.selfLeadershipTooltip,
                            disciplineTooltip: section.disciplineTooltip,
                            growthMindsetTooltip: section.growthMindsetTooltip,
                            criticalThinkingTooltip:
                                section.criticalThinkingTooltip,
                            collaborationTooltip: section.collaborationTooltip,
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
                                  practicalTooltip: section.practicalTooltip,
                                  metacognitionTooltip:
                                      section.metacognitionTooltip,
                                  persistenceTooltip:
                                      section.persistenceTooltip,
                                  knowledgeTooltip: section.knowledgeTooltip,
                                  systemsThinkingTooltip:
                                      section.systemsThinkingTooltip,
                                  creativityTooltip:
                                      section.creativityTooltip,
                                  communicationTooltip:
                                      section.communicationTooltip,
                                  selfLeadershipTooltip:
                                      section.selfLeadershipTooltip,
                                  disciplineTooltip:
                                      section.disciplineTooltip,
                                  growthMindsetTooltip:
                                      section.growthMindsetTooltip,
                                  criticalThinkingTooltip:
                                      section.criticalThinkingTooltip,
                                  collaborationTooltip:
                                      section.collaborationTooltip)),
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
  final String? metacognitionTooltip;
  final String? persistenceTooltip;
  final String? knowledgeTooltip;
  final String? systemsThinkingTooltip;
  final String? creativityTooltip;
  final String? communicationTooltip;
  final String? selfLeadershipTooltip;
  final String? disciplineTooltip;
  final String? growthMindsetTooltip;
  final String? criticalThinkingTooltip;
  final String? collaborationTooltip;
  const _MetricList({
    required this.color,
    required this.items,
    this.memoryTooltip,
    this.logicalTooltip,
    this.processingTooltip,
    this.practicalTooltip,
    this.metacognitionTooltip,
    this.persistenceTooltip,
    this.knowledgeTooltip,
    this.systemsThinkingTooltip,
    this.creativityTooltip,
    this.communicationTooltip,
    this.selfLeadershipTooltip,
    this.disciplineTooltip,
    this.growthMindsetTooltip,
    this.criticalThinkingTooltip,
    this.collaborationTooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map((e) => _MetricRow(
                color: color,
                item: e,
                memoryTooltip: memoryTooltip,
                logicalTooltip: logicalTooltip,
                processingTooltip: processingTooltip,
                practicalTooltip: practicalTooltip,
                metacognitionTooltip: metacognitionTooltip,
                persistenceTooltip: persistenceTooltip,
                knowledgeTooltip: knowledgeTooltip,
                systemsThinkingTooltip: systemsThinkingTooltip,
                creativityTooltip: creativityTooltip,
                communicationTooltip: communicationTooltip,
                selfLeadershipTooltip: selfLeadershipTooltip,
                disciplineTooltip: disciplineTooltip,
                growthMindsetTooltip: growthMindsetTooltip,
                criticalThinkingTooltip: criticalThinkingTooltip,
                collaborationTooltip: collaborationTooltip,
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
  final String? metacognitionTooltip;
  final String? persistenceTooltip;
  final String? knowledgeTooltip;
  final String? systemsThinkingTooltip;
  final String? creativityTooltip;
  final String? communicationTooltip;
  final String? selfLeadershipTooltip;
  final String? disciplineTooltip;
  final String? growthMindsetTooltip;
  final String? criticalThinkingTooltip;
  final String? collaborationTooltip;
  const _MetricRow({
    required this.color,
    required this.item,
    this.memoryTooltip,
    this.logicalTooltip,
    this.processingTooltip,
    this.practicalTooltip,
    this.metacognitionTooltip,
    this.persistenceTooltip,
    this.knowledgeTooltip,
    this.systemsThinkingTooltip,
    this.creativityTooltip,
    this.communicationTooltip,
    this.selfLeadershipTooltip,
    this.disciplineTooltip,
    this.growthMindsetTooltip,
    this.criticalThinkingTooltip,
    this.collaborationTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final v = item.value.clamp(0, 100).toDouble();
    final showMemoryTooltip = item.key == 'memory' && memoryTooltip != null;
    final showSystemsThinkingTooltip =
        item.key == 'systems_thinking' && systemsThinkingTooltip != null;
    final showCreativityTooltip =
        item.key == 'creativity' && creativityTooltip != null;
    final showCommunicationTooltip =
        item.key == 'communication' && communicationTooltip != null;
    final showSelfLeadershipTooltip =
        item.key == 'self_leadership' && selfLeadershipTooltip != null;
    final showDisciplineTooltip =
        item.key == 'discipline' && disciplineTooltip != null;
    final showGrowthMindsetTooltip =
        item.key == 'growth_mindset' && growthMindsetTooltip != null;
    final showCriticalThinkingTooltip =
        item.key == 'critical_thinking' && criticalThinkingTooltip != null;
    final showCollaborationTooltip =
        item.key == 'collaboration' && collaborationTooltip != null;
    final showLogicalTooltip =
        item.key == 'logical_thinking' && logicalTooltip != null;
    final showProcessingTooltip =
        item.key == 'processing_speed' && processingTooltip != null;
    final showPracticalTooltip =
        item.key == 'practical_application' && practicalTooltip != null;
    final showMetacognitionTooltip =
        item.key == 'metacognition' && metacognitionTooltip != null;
    final showPersistenceTooltip =
        item.key == 'learning_persistence' && persistenceTooltip != null;
    final showKnowledgeTooltip =
        item.key == 'knowledge_absorption' && knowledgeTooltip != null;
    final tooltipMessage = showSystemsThinkingTooltip
        ? systemsThinkingTooltip!
        : (showCreativityTooltip
            ? creativityTooltip!
            : (showCommunicationTooltip
                ? communicationTooltip!
                : (showSelfLeadershipTooltip
                    ? selfLeadershipTooltip!
                    : (showDisciplineTooltip
                        ? disciplineTooltip!
                        : (showGrowthMindsetTooltip
                            ? growthMindsetTooltip!
                            : (showCriticalThinkingTooltip
                                ? criticalThinkingTooltip!
                                : (showCollaborationTooltip
                                    ? collaborationTooltip!
            : (showMemoryTooltip
            ? memoryTooltip!
            : (showLogicalTooltip
                ? logicalTooltip!
                : (showProcessingTooltip
                    ? processingTooltip!
                    : (showPracticalTooltip
                        ? practicalTooltip!
                        : (showMetacognitionTooltip
                            ? metacognitionTooltip!
                            : (showPersistenceTooltip
                                ? persistenceTooltip!
                                : (showKnowledgeTooltip
                                    ? knowledgeTooltip!
                                    : null))))))))))))));
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
                        child: const Padding(
                          padding: EdgeInsets.only(left: 8),
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
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 6),
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
        radarBorderData: const BorderSide(color: AppColors.borderPrimary),
        tickBorderData:
            BorderSide(color: AppColors.borderPrimary.withValues(alpha: 0.7)),
        gridBorderData:
            BorderSide(color: AppColors.borderPrimary.withValues(alpha: 0.4)),
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
