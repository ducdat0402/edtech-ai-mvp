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
  static const _totalSlides = 11;

  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSaving = false;

  final TextEditingController _nicknameController = TextEditingController();

  final List<Map<String, String>> _featureIntroSlides = const [
    {
      'title': 'Tạo lộ trình cá nhân',
      'subtitle':
          'Hệ thống giúp bạn xây lộ trình học theo mục tiêu và thời gian của riêng bạn.',
      'icon': '🧭',
      'hero': '🚀',
    },
    {
      'title': 'Học từ cộng đồng',
      'subtitle':
          'Bạn có thể học từ các bài học do cộng đồng đóng góp và được kiểm duyệt.',
      'icon': '🤝',
      'hero': '🌍',
    },
    {
      'title': 'Có bản đồ năng lực',
      'subtitle':
          'Theo dõi tiến bộ năng lực học tập và năng lực con người trực quan theo thời gian.',
      'icon': '📊',
      'hero': '🧠',
    },
    {
      'title': 'Chia sẻ kiến thức và kiếm tiền',
      'subtitle':
          'Nhận 30% doanh thu khi tạo khóa học bổ ích được cộng đồng học và đánh giá tốt.',
      'icon': '💸',
      'hero': '🏆',
    },
    {
      'title': 'Bạn không học một mình',
      'subtitle':
          'Luôn có cộng đồng đồng hành để trao đổi, học nhóm và giữ động lực học tập.',
      'icon': '👥',
      'hero': '🔥',
    },
  ];

  // Slide 2: Acquisition
  String? _selectedAcquisition;
  final List<Map<String, String>> _acquisitionOptions = [
    {'id': 'friend', 'label': 'Bạn bè giới thiệu', 'icon': '👥'},
    {'id': 'social', 'label': 'Mạng xã hội (TikTok, FB...)', 'icon': '📱'},
    {'id': 'search', 'label': 'Tìm kiếm trên Google', 'icon': '🔍'},
    {'id': 'school', 'label': 'Trường học / Giáo viên', 'icon': '🏫'},
    {'id': 'ad', 'label': 'Quảng cáo', 'icon': '📢'},
    {'id': 'other', 'label': 'Khác', 'icon': '💡'},
  ];

  // Slide 3: User segment
  String? _selectedSegment;
  final List<Map<String, String>> _segmentOptions = [
    {
      'id': 'student_hs',
      'label': 'Học sinh (cấp 2, cấp 3)',
      'icon': '🎒',
      'desc': 'Đang đi học phổ thông'
    },
    {
      'id': 'student_uni',
      'label': 'Sinh viên đại học',
      'icon': '🎓',
      'desc': 'Đang học đại học / cao đẳng'
    },
    {
      'id': 'worker',
      'label': 'Người đi làm',
      'icon': '💼',
      'desc': 'Đã đi làm, muốn nâng cao'
    },
    {
      'id': 'self_learner',
      'label': 'Tự học',
      'icon': '📚',
      'desc': 'Học vì đam mê cá nhân'
    },
    {
      'id': 'parent',
      'label': 'Phụ huynh',
      'icon': '👨‍👩‍👧',
      'desc': 'Tìm hiểu cho con em'
    },
    {'id': 'other', 'label': 'Khác', 'icon': '🌟', 'desc': ''},
  ];

  // Slide 4: Learning goal
  final List<String> _selectedGoals = [];
  final List<Map<String, String>> _goalOptions = [
    {'id': 'exam', 'label': 'Thi cử', 'icon': '📝'},
    {'id': 'work', 'label': 'Phục vụ công việc', 'icon': '💻'},
    {'id': 'hobby', 'label': 'Sở thích cá nhân', 'icon': '🎯'},
    {'id': 'skill_up', 'label': 'Nâng cao kỹ năng', 'icon': '📈'},
    {'id': 'career', 'label': 'Chuẩn bị phỏng vấn / chuyển nghề', 'icon': '🚀'},
    {'id': 'explore', 'label': 'Khám phá kiến thức mới', 'icon': '🔬'},
  ];

  // Slide 5: Engagement expectation
  String? _selectedEngagement;
  final List<Map<String, String>> _engagementOptions = [
    {'id': '5min', 'label': '5 phút / ngày', 'tag': 'Đơn giản', 'icon': '⚡'},
    {
      'id': '10min',
      'label': '10 phút / ngày',
      'tag': 'Bình thường',
      'icon': '🕐'
    },
    {
      'id': '15min',
      'label': '15 phút / ngày',
      'tag': 'Có cố gắng',
      'icon': '💪'
    },
    {'id': '20min', 'label': '20 phút / ngày', 'tag': 'Kỷ luật', 'icon': '🔥'},
    {
      'id': '30min_plus',
      'label': '> 30 phút / ngày',
      'tag': 'Nghiêm túc',
      'icon': '🏆'
    },
  ];

  // Slide 6: Notification preference
  String? _selectedNotification;
  final List<Map<String, String>> _notificationOptions = [
    {
      'id': 'yes_daily',
      'label': 'Có, nhắc tôi mỗi ngày',
      'icon': '🔔',
      'desc': 'Nhận thông báo nhắc học kèm câu nói truyền cảm hứng'
    },
    {
      'id': 'yes_sometimes',
      'label': 'Thỉnh thoảng thôi',
      'icon': '🔕',
      'desc': 'Chỉ nhắc khi tôi lâu không vào học'
    },
    {
      'id': 'no',
      'label': 'Không, cảm ơn',
      'icon': '❌',
      'desc': 'Tôi sẽ tự nhớ'
    },
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
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nicknameController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  bool get _canProceed {
    if (_currentPage >= 1 && _currentPage <= 5) return true;
    switch (_currentPage) {
      case 0:
        return _nicknameController.text.trim().isNotEmpty;
      case 6:
        return _selectedAcquisition != null;
      case 7:
        return _selectedSegment != null;
      case 8:
        return _selectedGoals.isNotEmpty;
      case 9:
        return _selectedEngagement != null;
      case 10:
        return _selectedNotification != null;
      default:
        return false;
    }
  }

  void _nextPage() {
    if (_currentPage < _totalSlides - 1) {
      HapticFeedback.lightImpact();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else if (_currentPage == _totalSlides - 1) {
      _saveOnboardingAndShowChoice();
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

  Future<void> _saveOnboardingAndShowChoice() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final data = {
        'nickname': _nicknameController.text.trim(),
        'acquisition': _selectedAcquisition,
        'userSegment': _selectedSegment,
        'goals': _selectedGoals,
        'targetGoal': _selectedGoals.join(', '),
        'engagementLevel': _selectedEngagement,
        'notificationPreference': _selectedNotification,
      };
      await apiService.completeOnboarding(data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Lưu thông tin bị lỗi, nhưng bạn vẫn có thể tiếp tục.'),
            backgroundColor: AppColors.orangeNeon,
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    await _showOnboardingChoiceSheet();
  }

  Future<void> _showOnboardingChoiceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          decoration: const BoxDecoration(
            color: AppColors.bgPrimary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.bgTertiary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Text('Bắt đầu như thế nào?',
                    style: AppTextStyles.h4
                        .copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Text(
                  'Chọn cách bạn muốn bắt đầu, sau đó chọn môn học.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                _buildChoiceCard(
                  icon: Icons.play_circle_filled_rounded,
                  title: 'Học thử 1 bài',
                  subtitle: 'Trải nghiệm nhanh một bài học để làm quen',
                  gradient: [AppColors.cyanNeon, AppColors.purpleNeon],
                  onTap: () {
                    Navigator.pop(ctx);
                    _showSubjectPicker('try_lesson');
                  },
                ),
                const SizedBox(height: 12),
                _buildChoiceCard(
                  icon: Icons.route_rounded,
                  title: 'Tạo lộ trình cá nhân',
                  subtitle:
                      'Thiết kế lộ trình thông qua câu hỏi hoặc chat với AI',
                  gradient: [AppColors.pinkNeon, AppColors.orangeNeon],
                  onTap: () {
                    Navigator.pop(ctx);
                    _showSubjectPicker('personalized_path');
                  },
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.go('/dashboard');
                    },
                    child: Text('Vào trang chính',
                        style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.textTertiary,
                            decoration: TextDecoration.underline)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showSubjectPicker(String mode) async {
    List<Map<String, dynamic>> subjects = [];
    bool loading = true;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            if (loading) {
              _loadSubjectsForPicker().then((loaded) {
                if (ctx.mounted) {
                  setSheetState(() {
                    subjects = loaded;
                    loading = false;
                  });
                }
              });
            }

            return Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.7,
              ),
              decoration: const BoxDecoration(
                color: AppColors.bgPrimary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                            color: AppColors.bgTertiary,
                            borderRadius: BorderRadius.circular(999)),
                      ),
                    ),
                    Text(
                      mode == 'try_lesson'
                          ? 'Chọn môn học để thử'
                          : 'Chọn môn học để tạo lộ trình',
                      style: AppTextStyles.h4
                          .copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text('Chọn 1 môn bạn muốn bắt đầu',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    if (loading)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.cyanNeon)),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: subjects.length,
                          itemBuilder: (_, index) {
                            final s = subjects[index];
                            final name = s['name'] as String? ?? '';
                            final metadata =
                                s['metadata'] as Map<String, dynamic>?;
                            final icon = metadata?['icon'] as String? ?? '📖';
                            final desc = s['description'] as String? ?? '';

                            return GestureDetector(
                              onTap: () {
                                Navigator.pop(ctx);
                                _navigateAfterChoice(
                                    mode, s['id'] as String, name);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.bgSecondary,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: AppColors.borderPrimary),
                                ),
                                child: Row(
                                  children: [
                                    Text(icon,
                                        style: const TextStyle(fontSize: 28)),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(name,
                                              style: AppTextStyles.bodyBold
                                                  .copyWith(
                                                      color: AppColors
                                                          .textPrimary)),
                                          if (desc.isNotEmpty)
                                            Text(desc,
                                                style: AppTextStyles.caption
                                                    .copyWith(
                                                        color: AppColors
                                                            .textTertiary),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios_rounded,
                                        color: AppColors.textTertiary,
                                        size: 16),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _loadSubjectsForPicker() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final explorer = await apiService.getExplorerSubjects();
      final scholar = await apiService.getScholarSubjects();
      return [...explorer, ...scholar].cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  void _navigateAfterChoice(String mode, String subjectId, String subjectName) {
    HapticFeedback.mediumImpact();
    if (mode == 'try_lesson') {
      context.go('/subjects/$subjectId/all-lessons?openFirst=1');
    } else {
      context.go(
        '/subjects/$subjectId/learning-path-choice?name=${Uri.encodeComponent(subjectName)}&force=true',
      );
    }
  }

  // ─── Build ───

  Future<bool> _onWillPop() async {
    if (_currentPage > 0) {
      _previousPage();
      return false;
    }
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        title: const Text('Thoát giới thiệu?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Thông tin bạn đã nhập sẽ không được lưu. Bạn có chắc muốn thoát?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ở lại'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Thoát', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return shouldLeave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          context.go('/login');
        }
      },
      child: Scaffold(
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
                    onPageChanged: (page) =>
                        setState(() => _currentPage = page),
                    children: [
                      _buildNicknameSlide(),
                      ..._featureIntroSlides.map(_buildFeatureIntroSlide),
                      _buildAcquisitionSlide(),
                      _buildSegmentSlide(),
                      _buildGoalsSlide(),
                      _buildEngagementSlide(),
                      _buildNotificationSlide(),
                    ],
                  ),
                ),
                _buildBottomButtons(),
              ],
            ),
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
            '${_currentPage + 1} / $_totalSlides',
            style: AppTextStyles.labelMedium
                .copyWith(color: AppColors.textTertiary),
          ),
          const Spacer(),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(_totalSlides, (index) {
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
    final isLastPage = _currentPage == _totalSlides - 1;
    return Container(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        child: GamingButton(
          text: isLastPage ? 'Hoàn thành' : 'Tiếp tục',
          onPressed: _canProceed ? _nextPage : null,
          gradient: _canProceed
              ? (isLastPage ? AppGradients.success : AppGradients.primary)
              : null,
          glowColor: _canProceed
              ? (isLastPage ? AppColors.successNeon : AppColors.pinkNeon)
              : null,
          icon: isLastPage
              ? Icons.check_circle_rounded
              : Icons.arrow_forward_rounded,
          isLoading: _isSaving,
        ),
      ),
    );
  }

  // ─── Slide 1: Nickname ───

  Widget _buildNicknameSlide() {
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
                    spreadRadius: 5)
              ],
            ),
            child: const Icon(Icons.waving_hand_rounded,
                size: 50, color: Colors.white),
          ),
          const SizedBox(height: 32),
          AppTextStyles.gradientText(
              'Chào mừng bạn!', AppTextStyles.h2, AppGradients.primary),
          const SizedBox(height: 12),
          Text(
            'Mình sẽ giúp bạn cá nhân hóa trải nghiệm học tập.\nHãy cho mình biết tên bạn nhé!',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
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
              style: AppTextStyles.bodyLarge
                  .copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Nhập tên của bạn',
                hintStyle: AppTextStyles.bodyLarge
                    .copyWith(color: AppColors.textTertiary),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Slide 2: Acquisition ───

  Widget _buildFeatureIntroSlide(Map<String, String> slide) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 36),
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              gradient: AppGradients.purplePink,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purpleNeon.withOpacity(0.35),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                slide['hero'] ?? '✨',
                style: const TextStyle(fontSize: 52),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(slide['icon'] ?? '✨', style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Flexible(
                child: AppTextStyles.gradientText(
                  slide['title'] ?? '',
                  AppTextStyles.h3,
                  AppGradients.purplePink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderPrimary),
            ),
            child: Text(
              slide['subtitle'] ?? '',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary, height: 1.5),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.cyanNeon.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cyanNeon.withOpacity(0.25)),
            ),
            child: Text(
              'Vuốt tiếp để khám phá thêm',
              style: AppTextStyles.caption.copyWith(color: AppColors.cyanNeon),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcquisitionSlide() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.campaign_rounded,
              size: 48, color: AppColors.cyanNeon),
          const SizedBox(height: 16),
          AppTextStyles.gradientText(
              'Bạn biết đến app từ đâu?', AppTextStyles.h3, AppGradients.cyan),
          const SizedBox(height: 8),
          Text('Giúp mình cải thiện để tiếp cận nhiều người hơn',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          ..._acquisitionOptions.map((opt) {
            final isSelected = _selectedAcquisition == opt['id'];
            return _buildSingleSelectOption(
              icon: opt['icon']!,
              label: opt['label']!,
              isSelected: isSelected,
              onTap: () => setState(() => _selectedAcquisition = opt['id']),
              gradient: AppGradients.cyan,
              activeColor: AppColors.cyanNeon,
            );
          }),
        ],
      ),
    );
  }

  // ─── Slide 3: User Segment ───

  Widget _buildSegmentSlide() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.people_rounded,
              size: 48, color: AppColors.purpleNeon),
          const SizedBox(height: 16),
          AppTextStyles.gradientText(
              'Bạn là ai?', AppTextStyles.h3, AppGradients.purplePink),
          const SizedBox(height: 8),
          Text('Để mình cá nhân hóa nội dung phù hợp nhất',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          ..._segmentOptions.map((opt) {
            final isSelected = _selectedSegment == opt['id'];
            return _buildDetailedOption(
              icon: opt['icon']!,
              label: opt['label']!,
              desc: opt['desc']!,
              isSelected: isSelected,
              onTap: () => setState(() => _selectedSegment = opt['id']),
              gradient: AppGradients.purplePink,
              activeColor: AppColors.purpleNeon,
            );
          }),
        ],
      ),
    );
  }

  // ─── Slide 4: Learning Goals ───

  Widget _buildGoalsSlide() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.flag_rounded,
              size: 48, color: AppColors.successNeon),
          const SizedBox(height: 16),
          AppTextStyles.gradientText(
              'Bạn học để làm gì?', AppTextStyles.h3, AppGradients.success),
          const SizedBox(height: 8),
          Text('Chọn một hoặc nhiều mục tiêu của bạn',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _goalOptions.map((opt) {
              final isSelected = _selectedGoals.contains(opt['id']);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (isSelected) {
                      _selectedGoals.remove(opt['id']);
                    } else {
                      _selectedGoals.add(opt['id']!);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppGradients.success : null,
                    color: isSelected ? null : AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.successNeon
                          : AppColors.borderPrimary,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                                color: AppColors.successNeon.withOpacity(0.3),
                                blurRadius: 12)
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(opt['icon']!, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        opt['label']!,
                        style: AppTextStyles.bodyBold.copyWith(
                          color:
                              isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.white, size: 18),
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

  // ─── Slide 5: Engagement Expectation ───

  Widget _buildEngagementSlide() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.schedule_rounded,
              size: 48, color: AppColors.orangeNeon),
          const SizedBox(height: 16),
          AppTextStyles.gradientText('Bạn muốn học mỗi ngày bao lâu?',
              AppTextStyles.h3, AppGradients.pinkOrange),
          const SizedBox(height: 8),
          Text('Mình sẽ điều chỉnh bài học phù hợp',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          ..._engagementOptions.map((opt) {
            final isSelected = _selectedEngagement == opt['id'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedEngagement = opt['id']);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppGradients.pinkOrange : null,
                    color: isSelected ? null : AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.orangeNeon
                          : AppColors.borderPrimary,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                                color: AppColors.orangeNeon.withOpacity(0.3),
                                blurRadius: 16)
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Text(opt['icon']!, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(opt['label']!,
                                style: AppTextStyles.bodyBold.copyWith(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                    fontSize: 15)),
                            Text(opt['tag']!,
                                style: TextStyle(
                                    color: isSelected
                                        ? Colors.white70
                                        : AppColors.textTertiary,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.white, size: 24),
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

  // ─── Slide 6: Notification Preference ───

  Widget _buildNotificationSlide() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.notifications_active_rounded,
              size: 48, color: AppColors.coinGold),
          const SizedBox(height: 16),
          AppTextStyles.gradientText(
              'Nhắc học mỗi ngày?', AppTextStyles.h3, AppGradients.streak),
          const SizedBox(height: 8),
          Text(
            'Mỗi thông báo sẽ kèm một câu nói truyền cảm hứng\ngiúp bạn duy trì động lực học tập.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          ..._notificationOptions.map((opt) {
            final isSelected = _selectedNotification == opt['id'];
            return _buildDetailedOption(
              icon: opt['icon']!,
              label: opt['label']!,
              desc: opt['desc']!,
              isSelected: isSelected,
              onTap: () => setState(() => _selectedNotification = opt['id']),
              gradient: AppGradients.streak,
              activeColor: AppColors.coinGold,
            );
          }),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.coinGold.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.coinGold.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Text('💬', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '"Kỷ luật là cầu nối giữa mục tiêu và thành tựu." – Jim Rohn',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared Widgets ───

  Widget _buildSingleSelectOption({
    required String icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Gradient gradient,
    required Color activeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: isSelected ? gradient : null,
            color: isSelected ? null : AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isSelected ? activeColor : AppColors.borderPrimary,
                width: isSelected ? 2 : 1),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: activeColor.withOpacity(0.3), blurRadius: 12)
                  ]
                : null,
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label,
                    style: AppTextStyles.bodyBold.copyWith(
                        color:
                            isSelected ? Colors.white : AppColors.textPrimary)),
              ),
              if (isSelected)
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedOption({
    required String icon,
    required String label,
    required String desc,
    required bool isSelected,
    required VoidCallback onTap,
    required Gradient gradient,
    required Color activeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: isSelected ? gradient : null,
            color: isSelected ? null : AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isSelected ? activeColor : AppColors.borderPrimary,
                width: isSelected ? 2 : 1),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: activeColor.withOpacity(0.3), blurRadius: 16)
                  ]
                : null,
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: AppTextStyles.bodyBold.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontSize: 15)),
                    if (desc.isNotEmpty)
                      Text(desc,
                          style: TextStyle(
                              color: isSelected
                                  ? Colors.white70
                                  : AppColors.textTertiary,
                              fontSize: 13)),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: gradient[0].withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
                color: gradient[0].withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.bodyBold.copyWith(
                          color: AppColors.textPrimary, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded, color: gradient[0], size: 18),
          ],
        ),
      ),
    );
  }
}
