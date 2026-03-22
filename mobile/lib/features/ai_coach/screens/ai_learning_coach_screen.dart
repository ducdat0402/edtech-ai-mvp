import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/services/ai_user_preferences.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/features/learning_nodes/widgets/ai_learning_insight_card.dart';
import 'package:edtech_mobile/theme/theme.dart';

/// Phase 4–5: LangChain roadmap + ITS analytics; Phase 5 privacy toggles.
class AiLearningCoachScreen extends StatefulWidget {
  final String subjectId;
  final String? subjectName;

  const AiLearningCoachScreen({
    super.key,
    required this.subjectId,
    this.subjectName,
  });

  @override
  State<AiLearningCoachScreen> createState() => _AiLearningCoachScreenState();
}

class _AiLearningCoachScreenState extends State<AiLearningCoachScreen> {
  final TextEditingController _queryController = TextEditingController();

  bool _loadingProfile = true;
  String? _profileError;

  Map<String, dynamic>? _recommendations;
  Map<String, dynamic>? _errorPatterns;
  Map<String, dynamic>? _strengthsWeaknesses;

  bool _generatingRoadmap = false;
  String? _roadmapError;
  List<Map<String, dynamic>> _roadmap = [];
  String _roadmapSummary = '';
  double? _roadmapConfidence;
  int _planDays = 14;

  @override
  void initState() {
    super.initState();
    _queryController.text =
        'Ưu tiên các bài trên lộ trình của tôi: học đều, ôn phần yếu, chuẩn bị kiểm tra.';
    _loadInsightData();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _loadInsightData() async {
    setState(() {
      _loadingProfile = true;
      _profileError = null;
    });
    if (!AiUserPreferences.instance.cloudAiEnabled) {
      if (!mounted) return;
      setState(() {
        _loadingProfile = false;
        _recommendations = null;
        _errorPatterns = null;
        _strengthsWeaknesses = null;
      });
      return;
    }
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final results = await Future.wait([
        api.getAiItsRecommendations(),
        api.getAiErrorPatterns(),
        api.getAiStrengthsWeaknesses(),
      ]);
      if (!mounted) return;
      setState(() {
        _loadingProfile = false;
        _recommendations = results[0];
        _errorPatterns = results[1];
        _strengthsWeaknesses = results[2];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingProfile = false;
        _profileError = e.toString();
      });
    }
  }

  Future<void> _generateRoadmap() async {
    final q = _queryController.text.trim();
    if (q.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nhập mục tiêu (ưu tiên trong phạm vi lộ trình đã tạo)',
          ),
        ),
      );
      return;
    }
    if (!AiUserPreferences.instance.cloudAiEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã tắt gợi ý AI trên cloud — bật trong Hồ sơ → AI & quyền riêng tư.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _generatingRoadmap = true;
      _roadmapError = null;
      _roadmap = [];
      _roadmapSummary = '';
      _roadmapConfidence = null;
    });

    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final res = await api.generateAiLangchainRoadmap(
        query: q,
        subjectId: widget.subjectId,
        days: _planDays,
      );
      if (!mounted) return;

      final raw = res['roadmap'];
      final list = <Map<String, dynamic>>[];
      if (raw is List) {
        for (final item in raw) {
          if (item is Map) {
            list.add(Map<String, dynamic>.from(item));
          }
        }
      }

      setState(() {
        _generatingRoadmap = false;
        _roadmap = list;
        _roadmapSummary = res['summary']?.toString() ?? '';
        _roadmapConfidence = (res['confidence'] as num?)?.toDouble();
      });

      if (list.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Chưa tạo được bước nào — có thể chưa có lộ trình cá nhân (chat/placement) hoặc thử giảm số ngày.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _generatingRoadmap = false;
        _roadmapError = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tạo kế hoạch: $e'),
          backgroundColor: AppColors.errorNeon,
        ),
      );
    }
  }

  String _fmtMinutesFromSeconds(num? sec) {
    if (sec == null) return '—';
    final m = (sec / 60).round();
    return m < 1 ? '<1 phút' : '$m phút';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        title: Text(
          'Coach AI — ${widget.subjectName ?? 'Môn học'}',
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListenableBuilder(
        listenable: AiUserPreferences.instance,
        builder: (context, _) {
          final cloud = AiUserPreferences.instance.cloudAiEnabled;
          return RefreshIndicator(
            onRefresh: _loadInsightData,
            color: AppColors.purpleNeon,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theo dõi tiến độ & gợi ý trên lộ trình cá nhân (chat/placement). '
                    'Không tạo lộ trình chủ đề mới — chỉ sắp xếp/ôn trong các bài đã có trên map.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textTertiary, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  if (!cloud) ...[
                    _buildCloudDisabledBanner(),
                    const SizedBox(height: 16),
                    Text(
                      'Bật lại «Gợi ý AI trên cloud» trong Hồ sơ, sau đó kéo xuống để làm mới.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ] else ...[
                    _buildProfileSection(),
                    const SizedBox(height: 24),
                    _buildRoadmapSection(),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCloudDisabledBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.orangeNeon.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.orangeNeon.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cloud_off_outlined, color: AppColors.orangeNeon),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Gợi ý AI trên cloud đang tắt (Phase 5 — quyền riêng tư). '
              'Không gọi phân tích / OpenAI cho đến khi bạn bật lại.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    if (_loadingProfile) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: AppColors.purpleNeon),
        ),
      );
    }
    if (_profileError != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.errorNeon.withValues(alpha: 0.4)),
        ),
        child: Text(
          'Không tải được phân tích: $_profileError',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.errorNeon),
        ),
      );
    }

    final paceSec = (_recommendations?['learningPace'] as num?)?.toDouble();
    final suggestions = (_recommendations?['suggestions'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final strengths =
        (_strengthsWeaknesses?['strengths'] as List<dynamic>?) ?? [];
    final weaknesses =
        (_strengthsWeaknesses?['weaknesses'] as List<dynamic>?) ?? [];
    final errRate = (_errorPatterns?['errorRate'] as num?)?.toDouble();
    final consec = (_errorPatterns?['consecutiveErrors'] as num?)?.toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phân tích nhanh',
          style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        _infoTile(
          Icons.speed_rounded,
          'Nhịp học ước lượng',
          '${_fmtMinutesFromSeconds(paceSec)} / bài (7 ngày gần đây)',
          AppColors.cyanNeon,
        ),
        if (errRate != null)
          _infoTile(
            Icons.warning_amber_rounded,
            'Tỷ lệ lỗi (quiz)',
            '${(errRate * 100).toStringAsFixed(0)}% • Chuỗi lỗi tối đa: ${consec ?? 0}',
            AppColors.orangeNeon,
          ),
        _infoTile(
          Icons.trending_up_rounded,
          'Điểm mạnh / cần cải thiện',
          '${strengths.length} bài mạnh • ${weaknesses.length} bài yếu (theo hành vi)',
          AppColors.successNeon,
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Gợi ý ITS',
            style: AppTextStyles.labelLarge
                .copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          ...suggestions.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 18, color: AppColors.purpleNeon),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _infoTile(
      IconData icon, String title, String subtitle, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoadmapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kế hoạch ôn trong N ngày (trên lộ trình của bạn)',
          style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          'Chỉ các bài đã nằm trên personal mind map (sau chat/placement). '
            'DRL + ITS theo ngày; 30 ngày có thể rất chậm.',
          style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _queryController,
          maxLines: 4,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Mô tả mục tiêu học (tiếng Việt được)...',
            hintStyle:
                TextStyle(color: AppColors.textTertiary.withValues(alpha: 0.8)),
            filled: true,
            fillColor: AppColors.bgSecondary,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Độ dài kế hoạch',
          style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [7, 14, 30].map((d) {
            final selected = _planDays == d;
            return ChoiceChip(
              label: Text('$d ngày'),
              selected: selected,
              onSelected: _generatingRoadmap
                  ? null
                  : (v) {
                      if (v) setState(() => _planDays = d);
                    },
              selectedColor: AppColors.purpleNeon.withValues(alpha: 0.35),
              labelStyle: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        GamingButton(
          text: _generatingRoadmap
              ? 'Đang tạo kế hoạch… (có thể 30–90s)'
              : 'Tạo kế hoạch ôn (AI)',
          onPressed: _generatingRoadmap ? null : _generateRoadmap,
          icon: Icons.auto_graph_rounded,
        ),
        if (_roadmapError != null) ...[
          const SizedBox(height: 10),
          Text(
            _roadmapError!,
            style: AppTextStyles.caption.copyWith(color: AppColors.errorNeon),
          ),
        ],
        if (_roadmapSummary.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'Tóm tắt',
            style: AppTextStyles.labelLarge
                .copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            _roadmapSummary,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary, height: 1.45),
          ),
          if (_roadmapConfidence != null) ...[
            const SizedBox(height: 8),
            Text(
              'Độ tin cậy ước lượng: ${(_roadmapConfidence!.clamp(0.0, 1.0) * 100).round()}%',
              style: AppTextStyles.caption.copyWith(color: AppColors.cyanNeon),
            ),
          ],
        ],
        if (_roadmap.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'Các bước đề xuất',
            style: AppTextStyles.labelLarge
                .copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          ..._roadmap.map((step) {
            final day = step['day'];
            final nodeId = step['nodeId']?.toString() ?? '';
            final name = step['nodeName']?.toString() ?? 'Bài học';
            final diff = step['difficulty']?.toString() ?? 'medium';
            final est = (step['estimatedTime'] as num?)?.toInt();
            final reason = step['reason']?.toString() ?? '';
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.purpleNeon.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ngày $day',
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.purpleNeon),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Độ khó gợi ý: ${AiLearningInsightCard.difficultyLabelVi(diff)} • '
                    'Ước lượng: ${_fmtMinutesFromSeconds(est)}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textTertiary),
                  ),
                  if (reason.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      reason,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                  if (nodeId.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    GamingButtonOutlined(
                      text: 'Mở bài',
                      onPressed: () => context.push('/nodes/$nodeId'),
                      icon: Icons.open_in_new_rounded,
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}
