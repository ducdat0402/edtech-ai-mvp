import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/theme/theme.dart';

class OnboardingChatScreen extends StatefulWidget {
  const OnboardingChatScreen({super.key});

  @override
  State<OnboardingChatScreen> createState() => _OnboardingChatScreenState();
}

class _OnboardingChatScreenState extends State<OnboardingChatScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSaving = false;

  final TextEditingController _nicknameController = TextEditingController();

  List<Map<String, dynamic>> _subjects = [];
  final Set<String> _selectedSubjectIds = {};
  bool _loadingSubjects = false;

  String? _selectedLevel;
  final List<String> _selectedGoals = [];
  String? _selectedDailyTime;

  final List<Map<String, String>> _levels = [
    {'id': 'beginner', 'label': 'Mới bắt đầu', 'icon': '🌱', 'desc': 'Chưa biết gì về môn này'},
    {'id': 'intermediate', 'label': 'Biết chút ít', 'icon': '📚', 'desc': 'Đã học cơ bản'},
    {'id': 'advanced', 'label': 'Khá vững', 'icon': '🚀', 'desc': 'Nắm tốt kiến thức'},
  ];

  final List<String> _goalOptions = [
    'Ôn thi',
    'Nâng cao kiến thức',
    'Học từ đầu',
    'Luyện tập thêm',
    'Chuẩn bị phỏng vấn',
    'Đam mê cá nhân',
  ];

  final List<Map<String, String>> _timeOptions = [
    {'id': 'under_15', 'label': '< 15 phút', 'icon': '⚡'},
    {'id': '15_30', 'label': '15 - 30 phút', 'icon': '⏰'},
    {'id': '30_60', 'label': '30 - 60 phút', 'icon': '🔥'},
    {'id': 'over_60', 'label': '> 60 phút', 'icon': '💪'},
  ];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
    _loadSubjects();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nicknameController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    setState(() => _loadingSubjects = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final explorer = await apiService.getExplorerSubjects();
      final scholar = await apiService.getScholarSubjects();
      setState(() {
        _subjects = [...explorer, ...scholar].cast<Map<String, dynamic>>();
        _loadingSubjects = false;
      });
    } catch (e) {
      setState(() => _loadingSubjects = false);
    }
  }

  bool get _canProceed {
    switch (_currentPage) {
      case 0:
        return _nicknameController.text.trim().isNotEmpty;
      case 1:
        return _selectedSubjectIds.isNotEmpty;
      case 2:
        return _selectedLevel != null;
      case 3:
        return _selectedGoals.isNotEmpty;
      case 4:
        return _selectedDailyTime != null;
      default:
        return false;
    }
  }

  void _nextPage() {
    if (_currentPage < 4) {
      HapticFeedback.lightImpact();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      final selectedSubjectNames = _subjects
          .where((s) => _selectedSubjectIds.contains(s['id']))
          .map((s) => s['name'] as String)
          .toList();

      final data = {
        'nickname': _nicknameController.text.trim(),
        'subjects': selectedSubjectNames,
        'subjectIds': _selectedSubjectIds.toList(),
        'currentLevel': _selectedLevel,
        'targetGoal': _selectedGoals.join(', '),
        'goals': _selectedGoals,
        'dailyTime': _selectedDailyTime,
      };

      await apiService.completeOnboarding(data);

      if (mounted) {
        // Redirect to first selected subject to try first lesson
        final firstSubjectId = _selectedSubjectIds.isNotEmpty
            ? _selectedSubjectIds.first
            : null;
        if (firstSubjectId != null) {
          context.go('/subjects/$firstSubjectId/all-lessons?openFirst=1');
        } else {
          context.go('/dashboard');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Có lỗi xảy ra: $e'),
            backgroundColor: AppColors.errorGlow,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildHeader(),
              _buildProgressBar(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  children: [
                    _buildWelcomeSlide(),
                    _buildSubjectsSlide(),
                    _buildLevelSlide(),
                    _buildGoalsSlide(),
                    _buildDailyTimeSlide(),
                  ],
                ),
              ),
              _buildBottomButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          if (_currentPage > 0)
            GestureDetector(
              onTap: _previousPage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderPrimary),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.textSecondary, size: 20),
              ),
            )
          else
            const SizedBox(width: 36),
          const Spacer(),
          Text(
            '${_currentPage + 1} / 5',
            style: AppTextStyles.labelMedium.copyWith(color: AppColors.textTertiary),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.go('/dashboard'),
            child: Text(
              'Bỏ qua',
              style: AppTextStyles.labelMedium.copyWith(color: AppColors.textTertiary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(5, (index) {
          final isActive = index <= _currentPage;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                gradient: isActive ? AppGradients.primary : null,
                color: isActive ? null : AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomButtons() {
    final isLastPage = _currentPage == 4;
    return Container(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        child: GamingButton(
          text: isLastPage ? 'Bắt đầu học' : 'Tiếp tục',
          onPressed: _canProceed ? _nextPage : null,
          gradient: _canProceed ? (isLastPage ? AppGradients.success : AppGradients.primary) : null,
          glowColor: _canProceed ? (isLastPage ? AppColors.successNeon : AppColors.pinkNeon) : null,
          icon: isLastPage ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
          isLoading: _isSaving,
        ),
      ),
    );
  }

  // ─── Slide 1: Welcome ───

  Widget _buildWelcomeSlide() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purpleNeon.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(Icons.waving_hand_rounded, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 32),
          AppTextStyles.gradientText(
            'Chào mừng bạn!',
            AppTextStyles.h2,
            AppGradients.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Mình sẽ giúp bạn cá nhân hóa trải nghiệm học tập.\nHãy cho mình biết tên bạn nhé!',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 40),
          Container(
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderPrimary),
            ),
            child: TextField(
              controller: _nicknameController,
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Nhập tên của bạn',
                hintStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.textTertiary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Slide 2: Subjects ───

  Widget _buildSubjectsSlide() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.school_rounded, size: 48, color: AppColors.cyanNeon),
          const SizedBox(height: 16),
          AppTextStyles.gradientText(
            'Bạn muốn học gì?',
            AppTextStyles.h3,
            AppGradients.cyan,
          ),
          const SizedBox(height: 8),
          Text(
            'Chọn một hoặc nhiều môn học bạn quan tâm',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          if (_loadingSubjects)
            const Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: AppColors.cyanNeon),
            )
          else if (_subjects.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Text(
                'Chưa có môn học nào',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _subjects.map((subject) {
                final id = subject['id'] as String;
                final name = subject['name'] as String? ?? 'Unknown';
                final isSelected = _selectedSubjectIds.contains(id);
                final metadata = subject['metadata'] as Map<String, dynamic>?;
                final icon = metadata?['icon'] as String?;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (isSelected) {
                        _selectedSubjectIds.remove(id);
                      } else {
                        _selectedSubjectIds.add(id);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppGradients.purplePink : null,
                      color: isSelected ? null : AppColors.bgSecondary,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.purpleNeon : AppColors.borderPrimary,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: AppColors.purpleNeon.withOpacity(0.3), blurRadius: 12)]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Text(icon, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          name,
                          style: AppTextStyles.bodyBold.copyWith(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ─── Slide 3: Level ───

  Widget _buildLevelSlide() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.trending_up_rounded, size: 48, color: AppColors.orangeNeon),
          const SizedBox(height: 16),
          AppTextStyles.gradientText(
            'Trình độ hiện tại?',
            AppTextStyles.h3,
            AppGradients.pinkOrange,
          ),
          const SizedBox(height: 8),
          Text(
            'Giúp mình hiểu bạn đang ở đâu nhé',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          ...List.generate(_levels.length, (index) {
            final level = _levels[index];
            final isSelected = _selectedLevel == level['id'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedLevel = level['id']);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppGradients.pinkOrange : null,
                    color: isSelected ? null : AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.orangeNeon : AppColors.borderPrimary,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: AppColors.orangeNeon.withOpacity(0.3), blurRadius: 16)]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Text(level['icon']!, style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              level['label']!,
                              style: AppTextStyles.bodyBold.copyWith(
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              level['desc']!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isSelected ? Colors.white70 : AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Slide 4: Goals ───

  Widget _buildGoalsSlide() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.flag_rounded, size: 48, color: AppColors.successNeon),
          const SizedBox(height: 16),
          AppTextStyles.gradientText(
            'Mục tiêu học tập?',
            AppTextStyles.h3,
            AppGradients.success,
          ),
          const SizedBox(height: 8),
          Text(
            'Chọn một hoặc nhiều mục tiêu của bạn',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _goalOptions.map((goal) {
              final isSelected = _selectedGoals.contains(goal);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (isSelected) {
                      _selectedGoals.remove(goal);
                    } else {
                      _selectedGoals.add(goal);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppGradients.success : null,
                    color: isSelected ? null : AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSelected ? AppColors.successNeon : AppColors.borderPrimary,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: AppColors.successNeon.withOpacity(0.3), blurRadius: 12)]
                        : null,
                  ),
                  child: Text(
                    goal,
                    style: AppTextStyles.bodyBold.copyWith(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Slide 5: Daily Time ───

  Widget _buildDailyTimeSlide() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.schedule_rounded, size: 48, color: AppColors.warningNeon),
          const SizedBox(height: 16),
          AppTextStyles.gradientText(
            'Thời gian học mỗi ngày?',
            AppTextStyles.h3,
            AppGradients.warning,
          ),
          const SizedBox(height: 8),
          Text(
            'Mình sẽ điều chỉnh bài học phù hợp với bạn',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          ...List.generate(_timeOptions.length, (index) {
            final option = _timeOptions[index];
            final isSelected = _selectedDailyTime == option['id'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedDailyTime = option['id']);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppGradients.streak : null,
                    color: isSelected ? null : AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.warningNeon : AppColors.borderPrimary,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: AppColors.warningNeon.withOpacity(0.3), blurRadius: 16)]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Text(option['icon']!, style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          option['label']!,
                          style: AppTextStyles.bodyBold.copyWith(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
