import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/widgets/app_bar_leading_back_home.dart';
import 'package:edtech_mobile/theme/theme.dart';

class AnalysisCompleteScreen extends StatefulWidget {
  final String testId;

  const AnalysisCompleteScreen({
    super.key,
    required this.testId,
  });

  @override
  State<AnalysisCompleteScreen> createState() => _AnalysisCompleteScreenState();
}

class _AnalysisCompleteScreenState extends State<AnalysisCompleteScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _analysisData;
  bool _isLoading = true;
  String? _error;

  late AnimationController _animController;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5));
    _loadAnalysis();
  }

  @override
  void dispose() {
    _animController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalysis() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final data = await apiService.getTestAnalysis(widget.testId);

      setState(() {
        _analysisData = data;
        _isLoading = false;
      });
      _animController.forward();
      // Celebrate completion
      HapticFeedback.heavyImpact();
      _confettiController.play();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.colors;
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Kết quả phân tích',
            style: AppTextStyles.h4.copyWith(color: t.textPrimary)),
        leading: AppBarLeadingBackAndHome(
          iconColor: t.textSecondary,
        ),
        leadingWidth: 112,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          _isLoading
              ? _buildLoadingState()
              : _error != null
                  ? _buildErrorState()
                  : _analysisData == null
                      ? _buildNoDataState()
                      : _buildContent(),
          // Confetti celebration
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              blastDirectionality: BlastDirectionality.explosive,
              maxBlastForce: 30,
              minBlastForce: 10,
              emissionFrequency: 0.03,
              numberOfParticles: 30,
              gravity: 0.2,
              colors: [
                t.brand,
                t.aiGradient.length > 1 ? t.aiGradient[1] : t.brandSoft,
                t.info,
                t.success,
                t.gold,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    final t = context.colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: t.heroGradient),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: t.brand.withValues(alpha: 0.4),
                  blurRadius: 20,
                ),
              ],
            ),
            child: CircularProgressIndicator(color: t.textOnBrand),
          ),
          const SizedBox(height: 24),
          Text(
            'Đang phân tích kết quả...',
            style: AppTextStyles.bodyLarge
                .copyWith(color: t.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final t = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: t.error.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded,
                  size: 48, color: t.error),
            ),
            const SizedBox(height: 24),
            Text('Có lỗi xảy ra',
                style: AppTextStyles.h3.copyWith(color: t.textPrimary)),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: t.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GamingButton(
                text: 'Thử lại',
                onPressed: _loadAnalysis,
                icon: Icons.refresh_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataState() {
    final t = context.colors;
    return Center(
      child: Text(
        'Không có dữ liệu phân tích',
        style: AppTextStyles.bodyLarge.copyWith(color: t.textSecondary),
      ),
    );
  }

  Widget _buildContent() {
    final t = context.colors;
    final score = _analysisData!['score'] ?? 0;
    final level = _analysisData!['level'] ?? 'N/A';
    final strengths = _analysisData!['strengths'] as List? ?? [];
    final weaknesses = _analysisData!['weaknesses'] as List? ?? [];
    final subjectId = _analysisData!['subjectId'] as String?;

    return FadeTransition(
      opacity: CurvedAnimation(parent: _animController, curve: Curves.easeOut),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score Card
            _buildScoreCard(score, level),
            const SizedBox(height: 24),

            // Strengths
            if (strengths.isNotEmpty) ...[
              _buildSectionTitle('Điểm mạnh', Icons.check_circle_rounded,
                  t.success),
              const SizedBox(height: 12),
              ...strengths.map((s) => _buildItemCard(
                  s.toString(), t.success, Icons.check_rounded)),
              const SizedBox(height: 24),
            ],

            // Weaknesses
            if (weaknesses.isNotEmpty) ...[
              _buildSectionTitle('Cần cải thiện', Icons.warning_rounded,
                  t.warning),
              const SizedBox(height: 12),
              ...weaknesses.map((w) => _buildItemCard(w.toString(),
                  t.warning, Icons.priority_high_rounded)),
              const SizedBox(height: 24),
            ],

            // Action Buttons
            _buildActionButtons(subjectId),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(dynamic score, String level) {
    final t = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            t.brand.withValues(alpha: 0.18),
            t.aiGradient.last.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: [
          // Trophy icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: t.heroGradient),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: t.brand.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(Icons.emoji_events_rounded,
                color: t.textOnBrand, size: 40),
          ),
          const SizedBox(height: 20),

          Text('Điểm của bạn',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: t.textSecondary)),
          const SizedBox(height: 8),

          // Score
          ShaderMask(
            shaderCallback: (bounds) =>
                LinearGradient(colors: t.heroGradient).createShader(bounds),
            child: Text(
              '$score%',
              style: AppTextStyles.numberXLarge.copyWith(
                fontSize: 64,
                color: t.textOnBrand,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [t.success, t.brand],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: t.success.withValues(alpha: 0.4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Text(
              'Trình độ: $level',
              style: AppTextStyles.labelLarge
                  .copyWith(color: t.textOnBrand),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    final t = context.colors;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(title, style: AppTextStyles.h4.copyWith(color: t.textPrimary)),
      ],
    );
  }

  Widget _buildItemCard(String text, Color color, IconData icon) {
    final t = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: t.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String? subjectId) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: GamingButton(
            text: subjectId != null && subjectId.isNotEmpty
                ? 'Tạo lộ trình học tập'
                : 'Chọn môn học',
            onPressed: () {
              if (subjectId != null && subjectId.isNotEmpty) {
                context.go('/subjects/$subjectId/learning-path-choice');
              } else {
                context.go('/dashboard');
              }
            },
            icon: Icons.route_rounded,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: GamingButtonOutlined(
            text: 'Về trang chủ',
            onPressed: () => context.go('/dashboard'),
            icon: Icons.home_rounded,
          ),
        ),
      ],
    );
  }
}
