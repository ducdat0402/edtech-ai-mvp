import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
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
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
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
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Kết quả phân tích', style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary)),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderPrimary),
            ),
            child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
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
              colors: const [
                AppColors.purpleNeon,
                AppColors.pinkNeon,
                AppColors.cyanNeon,
                AppColors.successNeon,
                AppColors.xpGold,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.purpleNeon.withOpacity(0.4),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const CircularProgressIndicator(color: Colors.white),
          ),
          const SizedBox(height: 24),
          Text(
            'Đang phân tích kết quả...',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.errorNeon.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.errorNeon),
            ),
            const SizedBox(height: 24),
            Text('Có lỗi xảy ra', style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GamingButton(text: 'Thử lại', onPressed: _loadAnalysis, icon: Icons.refresh_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataState() {
    return Center(
      child: Text(
        'Không có dữ liệu phân tích',
        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildContent() {
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
              _buildSectionTitle('Điểm mạnh', Icons.check_circle_rounded, AppColors.successNeon),
              const SizedBox(height: 12),
              ...strengths.map((s) => _buildItemCard(s.toString(), AppColors.successNeon, Icons.check_rounded)),
              const SizedBox(height: 24),
            ],

            // Weaknesses
            if (weaknesses.isNotEmpty) ...[
              _buildSectionTitle('Cần cải thiện', Icons.warning_rounded, AppColors.warningNeon),
              const SizedBox(height: 12),
              ...weaknesses.map((w) => _buildItemCard(w.toString(), AppColors.warningNeon, Icons.priority_high_rounded)),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.purpleNeon.withOpacity(0.2), AppColors.pinkNeon.withOpacity(0.15)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.purpleNeon.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Trophy icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.purpleNeon.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 20),

          Text('Điểm của bạn', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),

          // Score
          ShaderMask(
            shaderCallback: (bounds) => AppGradients.primary.createShader(bounds),
            child: Text(
              '$score%',
              style: AppTextStyles.numberXLarge.copyWith(
                fontSize: 64,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: AppGradients.success,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.successNeon.withOpacity(0.4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Text(
              'Trình độ: $level',
              style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(title, style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildItemCard(String text, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
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
            text: subjectId != null && subjectId.isNotEmpty ? 'Xem Skill Tree' : 'Chọn môn học',
            onPressed: () {
              if (subjectId != null && subjectId.isNotEmpty) {
                context.go('/skill-tree?subjectId=$subjectId');
              } else {
                context.go('/subjects');
              }
            },
            icon: Icons.account_tree_rounded,
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
