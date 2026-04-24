import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edtech_mobile/core/constants/currency_labels.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/widgets/app_bar_leading_back_home.dart';
import 'package:edtech_mobile/core/widgets/bottom_nav_bar.dart';
import 'package:edtech_mobile/theme/colors.dart';
import 'package:edtech_mobile/theme/text_styles.dart';

class SubjectsHubScreen extends StatefulWidget {
  const SubjectsHubScreen({super.key});

  @override
  State<SubjectsHubScreen> createState() => _SubjectsHubScreenState();
}

class _SubjectsHubScreenState extends State<SubjectsHubScreen> {
  static const String _kPrefSubjectTypesExplained =
      'library_subject_types_explained_v1';

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _profileData;
  bool _isSwitchingRole = false;
  bool _viewAsContributor = false;
  String _subjectFilter = 'all'; // all | private | community | expert
  List<Map<String, dynamic>> _subjects = [];
  bool _showSearchField = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredSubjects {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _subjects;
    return _subjects.where((s) {
      final name = (s['name'] ?? '').toString().toLowerCase();
      final desc = (s['description'] ?? '').toString().toLowerCase();
      return name.contains(q) || desc.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> _subjectsByType(String type) {
    return _filteredSubjects
        .where((s) => (s['subjectType'] ?? 'community').toString() == type)
        .toList();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final results = await Future.wait([
        api.getDashboard(),
        api.getUserProfile(),
      ]);
      final dashboard = results[0];
      final profile = results[1];
      final rawSubjects = dashboard['subjects'] as List? ?? const [];
      setState(() {
        _subjects = rawSubjects
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _profileData = Map<String, dynamic>.from(profile as Map);
        _viewAsContributor = _hasContributorRole;
        _loading = false;
      });
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _maybeShowSubjectTypesIntroSheet();
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // === Role helpers ===
  String get _currentRole => _profileData?['role']?.toString() ?? 'user';
  bool get _hasContributorRole =>
      _currentRole == 'contributor' || _currentRole == 'admin';
  bool get _isContributor => _hasContributorRole && _viewAsContributor;

  Color get _bgPrimary =>
      _isContributor ? AppColors.contributorBgPrimary : AppColors.bgPrimary;
  Color get _bgSecondary =>
      _isContributor ? AppColors.contributorBgSecondary : AppColors.bgSecondary;
  Color get _borderColor =>
      _isContributor ? AppColors.contributorBorder : const Color(0x332D363D);

  Future<void> _handleSwitchRole() async {
    if (_isSwitchingRole) return;

    // Admin: backend không cho đổi role qua endpoint switch-role (sẽ trả 400).
    // Vì vậy ta chỉ toggle "view mode" trong UI.
    if (_currentRole == 'admin') {
      setState(() {
        _isSwitchingRole = true;
        _viewAsContributor = !_viewAsContributor;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _viewAsContributor
                  ? 'Đang xem dưới chế độ Contributor (Admin)'
                  : 'Đang xem dưới chế độ Learner (Admin)',
            ),
            backgroundColor: _viewAsContributor
                ? AppColors.contributorBlue
                : AppColors.successNeon,
          ),
        );
      }
      if (mounted) setState(() => _isSwitchingRole = false);
      return;
    }

    final targetRole = _isContributor ? 'user' : 'contributor';
    setState(() => _isSwitchingRole = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final raw = await apiService.switchRole(targetRole);
      final updated = Map<String, dynamic>.from(raw as Map);
      if (!mounted) return;
      setState(() {
        _profileData = {...?_profileData, ...updated};
        _viewAsContributor = targetRole == 'contributor';
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(targetRole == 'contributor'
                ? 'Đã chuyển sang chế độ Contributor'
                : 'Đã chuyển sang chế độ Learner'),
            backgroundColor: targetRole == 'contributor'
                ? AppColors.contributorBlue
                : AppColors.successNeon,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.errorNeon,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSwitchingRole = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const AppBarLeadingBackAndHome(),
        leadingWidth: 112,
        automaticallyImplyLeading: false,
        title: const Text(
          'Thư viện',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!_loading && _error == null)
            IconButton(
              tooltip: _showSearchField ? 'Đóng tìm kiếm' : 'Tìm kiếm môn học',
              onPressed: () {
                setState(() {
                  _showSearchField = !_showSearchField;
                  if (!_showSearchField) {
                    _searchController.clear();
                    _searchFocusNode.unfocus();
                  }
                });
                if (_showSearchField) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _searchFocusNode.requestFocus();
                  });
                }
              },
              icon: Icon(
                _showSearchField ? Icons.close : Icons.search,
                color: AppColors.textPrimary,
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.purpleNeon))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.errorNeon, size: 44),
                        const SizedBox(height: 8),
                        Text(
                          'Không tải được danh sách môn học.\n$_error',
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    RefreshIndicator(
                      onRefresh: _loadData,
                      color: AppColors.purpleNeon,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            if (_showSearchField) ...[
                              _buildSearchField(),
                              const SizedBox(height: 12),
                            ],
                            _buildRoleSwitcher(),
                            const SizedBox(height: 12),
                            if (_isContributor) ...[
                              _buildContributorBanner(),
                              const SizedBox(height: 14),
                            ] else ...[
                              _buildLearnerFilterChips(),
                              const SizedBox(height: 14),
                            ],
                          ]),
                        ),
                      ),
                      if (_subjects.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Text(
                              'Chưa có môn học nào',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        )
                      else if (_filteredSubjects.isEmpty)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(24, 32, 24, 48),
                            child: Center(
                              child: Text(
                                'Không tìm thấy môn học phù hợp.\nThử từ khóa khác hoặc xóa ô tìm kiếm.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 48),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              if (_isContributor) ...[
                                _buildTypeSection(
                                  title: 'Môn học cá nhân',
                                  sectionIcon: Icons.lock_rounded,
                                  sectionTint: AppColors.primaryLight,
                                  summary:
                                      'Môn riêng — chỉ bạn thấy; bài học private miễn phí cho bạn.',
                                  detail:
                                      'Chỉ bạn nhìn thấy môn học này. Bài học private miễn phí cho chính bạn. Muốn nâng lên cộng đồng/chuyên gia cần admin phê duyệt.',
                                  items: _subjectsByType('private'),
                                  onCreate: _showCreatePrivateDialog,
                                ),
                                const SizedBox(height: 12),
                                _buildTypeSection(
                                  title: 'Môn học cộng đồng',
                                  sectionIcon: Icons.groups_rounded,
                                  sectionTint: AppColors.orangeNeon,
                                  summary:
                                      'Đóng góp bài được duyệt có thể mang lại thưởng hàng tháng.',
                                  detail:
                                      'Mở khóa bằng 50 ${CurrencyLabels.gtuCoin} hoặc 50 kim cương mỗi bài. Môn có đóng góp của bạn sẽ được chia lợi nhuận theo tháng tùy số lượng và dạng bài đã đóng góp thành công.',
                                  items: _subjectsByType('community'),
                                  onCreate: _showCreateCommunityDialog,
                                ),
                                const SizedBox(height: 12),
                                _buildTypeSection(
                                  title: 'Môn học chuyên gia',
                                  sectionIcon: Icons.workspace_premium_rounded,
                                  sectionTint: AppColors.purpleNeon,
                                  summary:
                                      'Nội dung chuyên sâu — mỗi bài mở bằng 50 kim cương; cần admin duyệt.',
                                  detail:
                                      'Mỗi bài học mở khóa bằng 50 kim cương. Nội dung ở mức chuyên sâu, cần phê duyệt admin.',
                                  items: _subjectsByType('expert'),
                                  onCreate: _showCreateExpertDialog,
                                ),
                              ] else ...[
                                _buildLearnerSection(),
                              ],
                            ]),
                          ),
                        ),
                        ],
                      ),
                    ),
                    IgnorePointer(
                      child: Container(
                        height: 56,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _bgPrimary.withValues(alpha: 0),
                              _bgPrimary.withValues(alpha: 0.94),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      cursorColor: AppColors.purpleNeon,
      decoration: InputDecoration(
        hintText: 'Tìm theo tên hoặc mô tả môn học…',
        hintStyle: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.85),
            fontSize: 14),
        prefixIcon:
            const Icon(Icons.search, color: AppColors.textSecondary, size: 22),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Xóa',
                icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
              ),
        filled: true,
        fillColor: _bgSecondary,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0x332D363D)),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0x332D363D)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(
            color: AppColors.purpleNeon.withValues(alpha: 0.45),
            width: 1,
          ),
        ),
      ),
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _searchFocusNode.unfocus(),
    );
  }

  Widget _buildContributorBanner() {
    final text = _isContributor
        ? 'Bạn đang ở chế độ Contributor: có thể đóng góp bài học theo từng môn.'
        : 'Đổi sang chế độ Contributor ở Hồ sơ để mở quyền đóng góp bài học.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isContributor
              ? [
                  AppColors.successNeon.withValues(alpha: 0.12),
                  AppColors.successNeon.withValues(alpha: 0.04),
                ]
              : [
                  AppColors.purpleNeon.withValues(alpha: 0.14),
                  AppColors.primaryLight.withValues(alpha: 0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isContributor
              ? AppColors.successNeon.withValues(alpha: 0.4)
              : AppColors.purpleNeon.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isContributor ? Icons.verified : Icons.info_outline,
            color:
                _isContributor ? AppColors.successNeon : AppColors.primaryLight,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearnerFilterChips() {
    ChipThemeData chipTheme(Color accent) {
      return ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: accent.withValues(alpha: 0.35),
          ),
        ),
        showCheckmark: false,
        labelStyle: AppTextStyles.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Theme(
            data: Theme.of(context).copyWith(
              chipTheme: chipTheme(AppColors.purpleNeon),
            ),
            child: ChoiceChip(
              label: const Text('Tất cả'),
              selected: _subjectFilter == 'all',
              onSelected: (_) => setState(() => _subjectFilter = 'all'),
              selectedColor: AppColors.purpleNeon.withValues(alpha: 0.22),
              backgroundColor: _bgSecondary,
            ),
          ),
          const SizedBox(width: 10),
          Theme(
            data: Theme.of(context).copyWith(
              chipTheme: chipTheme(AppColors.primaryLight),
            ),
            child: ChoiceChip(
              label: const Text('Cá nhân'),
              selected: _subjectFilter == 'private',
              onSelected: (_) => setState(() => _subjectFilter = 'private'),
              selectedColor: AppColors.primaryLight.withValues(alpha: 0.2),
              backgroundColor: _bgSecondary,
            ),
          ),
          const SizedBox(width: 10),
          Theme(
            data: Theme.of(context).copyWith(
              chipTheme: chipTheme(AppColors.orangeNeon),
            ),
            child: ChoiceChip(
              label: const Text('Cộng đồng'),
              selected: _subjectFilter == 'community',
              onSelected: (_) => setState(() => _subjectFilter = 'community'),
              selectedColor: AppColors.orangeNeon.withValues(alpha: 0.22),
              backgroundColor: _bgSecondary,
            ),
          ),
          const SizedBox(width: 10),
          Theme(
            data: Theme.of(context).copyWith(
              chipTheme: chipTheme(AppColors.purpleNeon),
            ),
            child: ChoiceChip(
              label: const Text('Chuyên gia'),
              selected: _subjectFilter == 'expert',
              onSelected: (_) => setState(() => _subjectFilter = 'expert'),
              selectedColor: AppColors.purpleNeon.withValues(alpha: 0.24),
              backgroundColor: _bgSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          // Learner tab
          Expanded(
            child: GestureDetector(
              onTap: _isSwitchingRole || !_isContributor
                  ? null
                  : () => _handleSwitchRole(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isContributor
                      ? AppColors.purpleNeon.withValues(alpha: 0.32)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: !_isContributor
                      ? Border.all(
                          color: AppColors.purpleNeon.withValues(alpha: 0.55),
                        )
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.school_rounded,
                      size: 18,
                      color: !_isContributor
                          ? AppColors.purpleNeon
                          : AppColors.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Learner',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: !_isContributor
                            ? AppColors.purpleNeon
                            : AppColors.textTertiary,
                        fontWeight: !_isContributor
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Contributor tab
          Expanded(
            child: GestureDetector(
              onTap: _isSwitchingRole || _isContributor
                  ? null
                  : () => _handleSwitchRole(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isContributor
                      ? AppColors.contributorBlue.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: _isContributor
                      ? Border.all(
                          color:
                              AppColors.contributorBlue.withValues(alpha: 0.5),
                        )
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isSwitchingRole && !_isContributor)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.contributorBlue,
                        ),
                      )
                    else
                      Icon(
                        Icons.edit_note_rounded,
                        size: 18,
                        color: _isContributor
                            ? AppColors.contributorBlue
                            : AppColors.textTertiary,
                      ),
                    const SizedBox(width: 6),
                    Text(
                      'Contributor',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: _isContributor
                            ? AppColors.contributorBlue
                            : AppColors.textTertiary,
                        fontWeight: _isContributor
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearnerSection() {
    final selectedType = _subjectFilter;
    final items = selectedType == 'all'
        ? _filteredSubjects
        : _filteredSubjects
            .where((s) =>
                (s['subjectType'] ?? 'community').toString() == selectedType)
            .toList();

    final title = selectedType == 'all'
        ? 'Tất cả các môn'
        : selectedType == 'private'
            ? 'Môn học cá nhân'
            : selectedType == 'community'
                ? 'Môn học cộng đồng'
                : 'Môn học chuyên gia';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.purpleNeon.withValues(alpha: 0.16),
                _bgSecondary,
              ],
            ),
            border: Border.all(
              color: AppColors.purpleNeon.withValues(alpha: 0.28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                offset: const Offset(0, 4),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.purpleNeon.withValues(alpha: 0.45),
                      AppColors.purpleNeon.withValues(alpha: 0.1),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purpleNeon.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.primaryLight,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.h4.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${items.length} môn học',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Không có môn phù hợp với bộ lọc hiện tại.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: _librarySubjectsGridDelegate(
              MediaQuery.sizeOf(context).width - 28,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) => _buildSubjectTile(items[index]),
          ),
      ],
    );
  }

  /// Nội dung giải thích 3 loại môn — dùng trong bottom sheet lần đầu (5A).
  Widget _buildSubjectTypesExplainerBody() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.purpleNeon.withValues(alpha: 0.22),
            AppColors.bgSecondary,
          ],
        ),
        border: Border.all(color: AppColors.purpleNeon.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.purpleNeon.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.menu_book_rounded,
                    color: AppColors.primaryLight),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Khám phá 3 loại môn học',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Private: chỉ bạn thấy. Community: mở bằng 50 ${CurrencyLabels.gtuCoin} hoặc 50 kim cương mỗi bài. Expert: mở bằng 50 kim cương mỗi bài.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _maybeShowSubjectTypesIntroSheet() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kPrefSubjectTypesExplained) == true) return;
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.textTertiary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSubjectTypesExplainerBody(),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Đã hiểu'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    await prefs.setBool(_kPrefSubjectTypesExplained, true);
  }

  int _subjectColor(String name) {
    var hash = 0;
    for (var i = 0; i < name.length; i++) {
      hash = (hash * 31 + name.codeUnitAt(i)) & 0xFFFFFF;
    }
    final palette = <int>[
      0xFF7354F5,
      0xFF8B9CFF,
      0xFF41E184,
      0xFFFFD647,
      0xFFCABEFF,
    ];
    return palette[hash % palette.length];
  }

  Map<String, dynamic>? _metadata(Map<String, dynamic> subject) {
    final m = subject['metadata'];
    if (m is Map<String, dynamic>) return m;
    if (m is Map) return Map<String, dynamic>.from(m);
    return null;
  }

  Color _accentFromSubject(Map<String, dynamic> subject, String name) {
    final meta = _metadata(subject);
    final c = meta?['color']?.toString();
    if (c != null && c.startsWith('#') && c.length >= 7) {
      try {
        return Color(int.parse(c.substring(1, 7), radix: 16) + 0xFF000000);
      } catch (_) {}
    }
    return Color(_subjectColor(name));
  }

  /// Lưới môn học dày — ưu tiên nhiều cột, icon tròn (không còn thẻ vuông lớn).
  int _libraryTileCrossAxisCount(double width) {
    if (width >= 560) return 6;
    if (width >= 440) return 5;
    if (width >= 320) return 4;
    return 3;
  }

  SliverGridDelegate _librarySubjectsGridDelegate(double gridWidth) {
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: _libraryTileCrossAxisCount(gridWidth),
      mainAxisSpacing: 10,
      crossAxisSpacing: 8,
      childAspectRatio: 0.74,
    );
  }

  /// Optional admin cover; otherwise tiles use icon watermark + gradient (no remote image).
  String? _customCoverUrl(Map<String, dynamic> subject) {
    final meta = _metadata(subject);
    final custom = meta?['coverImageUrl']?.toString().trim();
    if (custom == null || custom.isEmpty) return null;
    return custom;
  }

  Widget _subjectCircleGlyph(
    Map<String, dynamic> subject,
    String name,
    double diameter,
  ) {
    final meta = _metadata(subject);
    final iconRaw = meta?['icon']?.toString().trim();
    final emojiSize = diameter * 0.44;
    final letterSize = diameter * 0.38;
    if (iconRaw != null && iconRaw.isNotEmpty) {
      final hasPicto =
          RegExp(r'\p{Extended_Pictographic}', unicode: true).hasMatch(iconRaw);
      if (hasPicto) {
        return Text(
          iconRaw,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: emojiSize,
            height: 1,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.45),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        );
      }
      if (iconRaw.length == 1) {
        return Text(
          iconRaw.toUpperCase(),
          style: TextStyle(
            fontSize: letterSize,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.55),
                offset: const Offset(0, 1),
                blurRadius: 3,
              ),
            ],
          ),
        );
      }
    }
    final letter = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
    return Text(
      letter,
      style: TextStyle(
        fontSize: letterSize,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        height: 1,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCircleAvatar({
    required Map<String, dynamic> subject,
    required String name,
    required Color accent,
    required String? coverUrl,
    double diameter = 56,
  }) {
    final hasCover = coverUrl != null && coverUrl.isNotEmpty;
    final deep = Color.lerp(accent, Colors.black, 0.52) ?? _bgSecondary;
    final mid = Color.lerp(accent, const Color(0xFF12121A), 0.45) ?? _bgSecondary;

    Widget baseGradient() {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.4, -0.45),
            radius: 1.05,
            colors: [
              Color.lerp(accent, Colors.white, 0.22)!,
              mid,
              deep,
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
      );
    }

    Widget gloss() {
      return Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: diameter * 0.42,
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.32),
                  Colors.white.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
          BoxShadow(
            color: accent.withValues(alpha: 0.38),
            offset: const Offset(0, 2),
            blurRadius: 12,
          ),
        ],
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            baseGradient(),
            if (hasCover)
              Image.network(
                coverUrl,
                fit: BoxFit.cover,
                width: diameter,
                height: diameter,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: diameter * 0.32,
                      height: diameter * 0.32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: accent.withValues(alpha: 0.85),
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Center(
                  child: _subjectCircleGlyph(subject, name, diameter),
                ),
              ),
            if (!hasCover)
              Center(
                child: _subjectCircleGlyph(subject, name, diameter),
              ),
            gloss(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectTile(Map<String, dynamic> subject) {
    final id = (subject['id'] ?? '').toString();
    final name = (subject['name'] ?? 'Môn học').toString();
    final totalNodes = (subject['totalNodesCount'] as num?)?.toInt();
    final coverUrl = _customCoverUrl(subject);
    final accent = _accentFromSubject(subject, name);

    const double d = 54;

    void onTap() {
      if (_isContributor) {
        context.push(
          '/contributor/mind-map?subjectId=$id&subjectName=${Uri.encodeComponent(name)}',
        );
      } else {
        context.push('/subjects/$id/intro');
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: accent.withValues(alpha: 0.18),
        highlightColor: accent.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildSubjectCircleAvatar(
                subject: subject,
                name: name,
                accent: accent,
                coverUrl: coverUrl,
                diameter: d,
              ),
              const SizedBox(height: 8),
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                  height: 1.25,
                ),
              ),
              if (totalNodes != null) ...[
                const SizedBox(height: 3),
                Text(
                  '$totalNodes bài',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ],
              if (_isContributor) ..._contributorStatsWidgets(subject),
            ],
          ),
        ),
      ),
    );
  }

  /// A: % bài có ghi công cộng đồng; B: % bài CC do bạn ghi công (trên tổng bài CC trong môn).
  List<Widget> _contributorStatsWidgets(Map<String, dynamic> subject) {
    final raw = subject['contributorStats'];
    if (raw is! Map) return const [];
    final m = Map<String, dynamic>.from(raw);
    final total = (m['totalNodes'] as num?)?.toInt() ?? 0;
    final withCc = (m['nodesWithContributor'] as num?)?.toInt() ?? 0;
    final ccPct = (m['communityPercent'] as num?)?.toInt() ?? 0;
    final mine = (m['myCreditedNodes'] as num?)?.toInt() ?? 0;
    final myPct = m['mySharePercent'] as int?;

    return [
      const SizedBox(height: 5),
      Text(
        total > 0
            ? 'Cộng đồng: $ccPct% ($withCc/$total bài)'
            : 'Cộng đồng: — (chưa có bài)',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.contributorBlue.withValues(alpha: 0.95),
          fontWeight: FontWeight.w600,
          fontSize: 9,
          height: 1.2,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        withCc > 0
            ? (myPct != null
                ? 'Bạn: $myPct% ($mine/$withCc bài CC)'
                : 'Bạn: $mine/$withCc bài CC')
            : (mine > 0
                ? 'Bạn: $mine bài ghi công (môn chưa có bài CC)'
                : 'Bạn: 0 bài ghi công'),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.textTertiary,
          fontWeight: FontWeight.w500,
          fontSize: 8.5,
          height: 1.2,
        ),
      ),
    ];
  }

  // ignore: unused_element
  Future<void> _showPromotionDialog({
    required String subjectId,
    required String subjectName,
  }) async {
    final target = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        title: const Text(
          'Yêu cầu nâng hạng môn',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Môn "$subjectName" đang là private. Bạn muốn gửi duyệt lên loại nào?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Để sau'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, 'community'),
            child: const Text('Lên cộng đồng'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'expert'),
            child: const Text('Lên chuyên gia'),
          ),
        ],
      ),
    );
    if (target == null) return;
    if (!mounted) return;
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      await api.requestSubjectPromotion(
          subjectId: subjectId, targetType: target);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Đã gửi yêu cầu nâng hạng, chờ admin phê duyệt')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.errorNeon),
      );
    }
  }

  void _showContributorSectionDetail(String title, String detail) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final maxH = MediaQuery.sizeOf(ctx).height * 0.45;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: AppTextStyles.h4),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxH),
                  child: SingleChildScrollView(
                    child: Text(
                      detail,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeSection({
    required String title,
    required String summary,
    required String detail,
    required List<Map<String, dynamic>> items,
    required Future<void> Function() onCreate,
    IconData sectionIcon = Icons.folder_rounded,
    Color sectionTint = AppColors.primaryLight,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            sectionTint.withValues(alpha: 0.14),
            _bgSecondary,
            _bgSecondary,
          ],
        ),
        border: Border.all(
          color: sectionTint.withValues(alpha: 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            offset: const Offset(0, 6),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      sectionTint.withValues(alpha: 0.45),
                      sectionTint.withValues(alpha: 0.12),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: sectionTint.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Icon(sectionIcon, color: sectionTint, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Chi tiết loại môn',
                onPressed: () =>
                    _showContributorSectionDetail(title, detail),
                icon: const Icon(Icons.info_outline_rounded,
                    color: AppColors.textSecondary, size: 22),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              const SizedBox(width: 2),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  backgroundColor: sectionTint.withValues(alpha: 0.2),
                  foregroundColor: sectionTint,
                ),
                onPressed: onCreate,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Tạo'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            summary,
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.95),
              fontSize: 12.5,
              height: 1.38,
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Chưa có môn học',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: _librarySubjectsGridDelegate(
                MediaQuery.sizeOf(context).width - 48,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) => _buildSubjectTile(items[index]),
            ),
        ],
      ),
    );
  }

  Future<void> _showCreatePrivateDialog() async {
    await _showCreateDialog(
      title: 'Tạo môn học cá nhân',
      onSubmit: (api, name, desc) =>
          api.createPrivateSubject(name: name, description: desc),
      successMessage: 'Đã tạo môn private thành công',
    );
  }

  Future<void> _showCreateCommunityDialog() async {
    await _showCreateDialog(
      title: 'Đề xuất môn cộng đồng',
      onSubmit: (api, name, desc) =>
          api.createSubjectContribution(name: name, description: desc),
      successMessage: 'Đã gửi đề xuất môn cộng đồng, chờ admin duyệt',
    );
  }

  Future<void> _showCreateExpertDialog() async {
    await _showCreateDialog(
      title: 'Tạo môn rồi gửi duyệt chuyên gia',
      onSubmit: (api, name, desc) async {
        final created =
            await api.createPrivateSubject(name: name, description: desc);
        final subjectId = (created['id'] ?? '').toString();
        if (subjectId.isNotEmpty) {
          await api.requestSubjectPromotion(
            subjectId: subjectId,
            targetType: 'expert',
            reason: 'Yêu cầu nâng cấp lên môn chuyên gia',
          );
        }
        return created;
      },
      successMessage: 'Đã tạo môn private và gửi yêu cầu nâng cấp chuyên gia',
    );
  }

  Future<void> _showCreateDialog({
    required String title,
    required Future<Map<String, dynamic>> Function(
            ApiService api, String name, String description)
        onSubmit,
    required String successMessage,
  }) async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        title:
            Text(title, style: const TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Tên môn học'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Mô tả (tuỳ chọn)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Tạo')),
        ],
      ),
    );
    if (ok != true) return;
    final name = nameCtrl.text.trim();
    final desc = descCtrl.text.trim();
    if (name.isEmpty) return;
    if (!mounted) return;
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      await onSubmit(api, name, desc);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.errorNeon),
      );
    }
  }
}
