import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/theme/theme.dart';

/// Screen to choose between AI Chat and Placement Test for creating personal learning path
class LearningPathChoiceScreen extends StatefulWidget {
  final String subjectId;
  final String? subjectName;
  final bool
      forceShowChoice; // Force show choice screen even if mind map exists

  const LearningPathChoiceScreen({
    super.key,
    required this.subjectId,
    this.subjectName,
    this.forceShowChoice = false,
  });

  @override
  State<LearningPathChoiceScreen> createState() =>
      _LearningPathChoiceScreenState();
}

class _LearningPathChoiceScreenState extends State<LearningPathChoiceScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkExistingPath();
  }

  Future<void> _checkExistingPath() async {
    // Skip check if force showing choice
    if (widget.forceShowChoice) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.checkPersonalMindMap(widget.subjectId);

      final exists = result['exists'] as bool? ?? false;

      if (exists && mounted) {
        // If mind map exists, navigate directly to it
        // Use addPostFrameCallback to avoid navigation during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.pushReplacement(
                '/subjects/${widget.subjectId}/personal-mind-map');
          }
        });
        return;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      // If error checking, just show the choice screen
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.purpleNeon),
              const SizedBox(height: 16),
              Text(
                'Đang kiểm tra lộ trình...',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Tạo lộ trình học tập',
          style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderPrimary),
            ),
            child: const Icon(Icons.arrow_back,
                color: AppColors.textPrimary, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 32),

            // Option 1: AI Chat
            _buildOptionCard(
              context,
              title: 'Chat với AI',
              subtitle:
                  'Trò chuyện để xác định mục tiêu và tạo lộ trình phù hợp',
              description:
                  'AI sẽ hỏi về kinh nghiệm, mục tiêu học tập và sở thích của bạn để tạo ra lộ trình cá nhân hóa.',
              icon: Icons.chat_bubble_rounded,
              gradient: [AppColors.purpleNeon, AppColors.pinkNeon],
              duration: '5-10 phút',
              features: [
                'Trò chuyện tự nhiên',
                'Hiểu mục tiêu sâu hơn',
                'Linh hoạt theo yêu cầu',
              ],
              onTap: () {
                HapticFeedback.lightImpact();
                // Navigate to AI Chat (existing personal mind map screen)
                context.push('/subjects/${widget.subjectId}/personal-mind-map');
              },
            ),

            const SizedBox(height: 20),

            // Divider with "hoặc"
            Row(
              children: [
                const Expanded(child: Divider(color: AppColors.borderPrimary)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'hoặc',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textTertiary),
                  ),
                ),
                const Expanded(child: Divider(color: AppColors.borderPrimary)),
              ],
            ),

            const SizedBox(height: 20),

            // Option 2: Placement Test
            _buildOptionCard(
              context,
              title: 'Làm bài kiểm tra',
              subtitle: 'Đánh giá năng lực để xác định điểm xuất phát',
              description:
                  'Bài test thích ứng sẽ đánh giá kiến thức của bạn qua 15-30 câu hỏi và tạo lộ trình dựa trên kết quả.',
              icon: Icons.quiz_rounded,
              gradient: [AppColors.cyanNeon, AppColors.successNeon],
              duration: '15-25 phút',
              features: [
                'Đánh giá chính xác',
                'Thích ứng theo trình độ',
                'Xác định điểm yếu cụ thể',
              ],
              onTap: () {
                HapticFeedback.lightImpact();
                // Navigate to new Adaptive Placement Test
                context.push('/subjects/${widget.subjectId}/adaptive-test');
              },
            ),

            const SizedBox(height: 32),

            // Info note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderPrimary),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.warningNeon.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.info_outline_rounded,
                        color: AppColors.warningNeon, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bạn có thể thay đổi lộ trình sau bằng cách làm lại bài test hoặc chat với AI.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.purpleNeon, AppColors.cyanNeon],
          ).createShader(bounds),
          child: Text(
            'Chọn cách tạo lộ trình',
            style: AppTextStyles.h2.copyWith(color: Colors.white),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Hãy chọn phương pháp phù hợp với bạn để tạo lộ trình học tập cá nhân hóa.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required List<Color> gradient,
    required String duration,
    required List<String> features,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderPrimary),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon with gradient background
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: gradient[0].withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),

                // Title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.h4
                            .copyWith(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                // Arrow icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: gradient[0].withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.arrow_forward_rounded,
                      color: gradient[0], size: 20),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Description
            Text(
              description,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 16),
            const Divider(color: AppColors.borderPrimary),
            const SizedBox(height: 16),

            // Duration and features
            Row(
              children: [
                // Duration badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: gradient[0].withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined, color: gradient[0], size: 16),
                      const SizedBox(width: 6),
                      Text(
                        duration,
                        style: AppTextStyles.labelSmall
                            .copyWith(color: gradient[0]),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Features list
            ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            LinearGradient(colors: gradient)
                                .createShader(bounds),
                        child: const Icon(Icons.check_circle_rounded,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        feature,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
