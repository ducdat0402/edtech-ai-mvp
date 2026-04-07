import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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
              : RefreshIndicator(
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
                            _buildHeroCard(),
                            const SizedBox(height: 14),
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
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              if (_isContributor) ...[
                                _buildTypeSection(
                                  title: 'Môn học cá nhân',
                                  type: 'private',
                                  tooltip:
                                      'Chỉ bạn nhìn thấy môn học này. Bài học private miễn phí cho chính bạn. Muốn nâng lên cộng đồng/chuyên gia cần admin phê duyệt.',
                                  items: _subjectsByType('private'),
                                  onCreate: _showCreatePrivateDialog,
                                ),
                                const SizedBox(height: 12),
                                _buildTypeSection(
                                  title: 'Môn học cộng đồng',
                                  type: 'community',
                                  tooltip:
                                      'Mở khóa bằng 50 xu hoặc 50 kim cương mỗi bài. Môn có đóng góp của bạn sẽ được chia lợi nhuận theo tháng tùy số lượng và dạng bài đã đóng góp thành công.',
                                  items: _subjectsByType('community'),
                                  onCreate: _showCreateCommunityDialog,
                                ),
                                const SizedBox(height: 12),
                                _buildTypeSection(
                                  title: 'Môn học chuyên gia',
                                  type: 'expert',
                                  tooltip:
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
        fillColor: AppColors.bgSecondary,
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
    const pad = EdgeInsets.only(top: 0);
    return Padding(
      padding: pad,
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          ChoiceChip(
            label: const Text('Tất cả'),
            selected: _subjectFilter == 'all',
            onSelected: (_) => setState(() => _subjectFilter = 'all'),
            selectedColor: AppColors.purpleNeon.withValues(alpha: 0.18),
            backgroundColor: _bgSecondary,
          ),
          ChoiceChip(
            label: const Text('Cá nhân'),
            selected: _subjectFilter == 'private',
            onSelected: (_) => setState(() => _subjectFilter = 'private'),
            selectedColor: AppColors.primaryLight.withValues(alpha: 0.16),
            backgroundColor: _bgSecondary,
          ),
          ChoiceChip(
            label: const Text('Cộng đồng'),
            selected: _subjectFilter == 'community',
            onSelected: (_) => setState(() => _subjectFilter = 'community'),
            selectedColor: AppColors.orangeNeon.withValues(alpha: 0.18),
            backgroundColor: _bgSecondary,
          ),
          ChoiceChip(
            label: const Text('Chuyên gia'),
            selected: _subjectFilter == 'expert',
            onSelected: (_) => setState(() => _subjectFilter = 'expert'),
            selectedColor: AppColors.purpleNeon.withValues(alpha: 0.2),
            backgroundColor: _bgSecondary,
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
                      ? AppColors.purpleNeon.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: !_isContributor
                      ? Border.all(
                          color: AppColors.purpleNeon.withValues(alpha: 0.5),
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
        Text(title, style: AppTextStyles.h3.copyWith(fontSize: 18)),
        const SizedBox(height: 10),
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
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:
                  _gridCrossAxisCount(MediaQuery.sizeOf(context).width - 28),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.92,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) => _buildSubjectTile(items[index]),
          ),
      ],
    );
  }

  Widget _buildHeroCard() {
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
          const Text(
            'Private: chỉ bạn thấy. Community: mở bằng 50 xu hoặc 50 kim cương mỗi bài. Expert: mở bằng 50 kim cương mỗi bài.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
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

  int _gridCrossAxisCount(double width) {
    if (width >= 520) return 4;
    if (width >= 340) return 3;
    return 2;
  }

  /// Optional admin cover; otherwise tiles use icon watermark + gradient (no remote image).
  String? _customCoverUrl(Map<String, dynamic> subject) {
    final meta = _metadata(subject);
    final custom = meta?['coverImageUrl']?.toString().trim();
    if (custom == null || custom.isEmpty) return null;
    return custom;
  }

  Widget _subjectIconWatermark(
      Map<String, dynamic> subject, String name, Color accent) {
    final meta = _metadata(subject);
    final iconRaw = meta?['icon']?.toString().trim();
    if (iconRaw != null && iconRaw.isNotEmpty) {
      final hasPicto =
          RegExp(r'\p{Extended_Pictographic}', unicode: true).hasMatch(iconRaw);
      if (hasPicto) {
        return Text(
          iconRaw,
          style: TextStyle(
            fontSize: 88,
            height: 1,
            color: Colors.white.withValues(alpha: 0.2),
            shadows: [
              Shadow(color: accent.withValues(alpha: 0.35), blurRadius: 24),
            ],
          ),
        );
      }
      if (iconRaw.length == 1) {
        return Text(
          iconRaw.toUpperCase(),
          style: TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.w900,
            color: accent.withValues(alpha: 0.22),
            height: 1,
          ),
        );
      }
    }
    final letter = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
    return Text(
      letter,
      style: TextStyle(
        fontSize: 80,
        fontWeight: FontWeight.w900,
        color: Colors.white.withValues(alpha: 0.14),
        height: 1,
      ),
    );
  }

  Widget _iconBackdrop(
      Map<String, dynamic> subject, String name, Color accent) {
    final base =
        Color.lerp(accent, const Color(0xFF0A0A0F), 0.72) ?? _bgSecondary;
    final deep = Color.lerp(accent, Colors.black, 0.55) ?? _bgSecondary;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            base,
            _bgSecondary,
            deep,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: const Alignment(0, -0.25),
                child: FractionallySizedBox(
                  widthFactor: 0.95,
                  heightFactor: 0.55,
                  child: Transform.rotate(
                    angle: -0.1,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: _subjectIconWatermark(subject, name, accent),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectTile(Map<String, dynamic> subject) {
    final id = (subject['id'] ?? '').toString();
    final name = (subject['name'] ?? 'Môn học').toString();
    final coverUrl = _customCoverUrl(subject);
    final accent = _accentFromSubject(subject, name);

    final meta = _metadata(subject);
    final iconRaw = meta?['icon']?.toString().trim();
    final iconText = iconRaw != null && iconRaw.isNotEmpty
        ? iconRaw
        : (name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?');

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (coverUrl != null)
            Image.network(
              coverUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return _iconBackdrop(subject, name, accent);
              },
              errorBuilder: (_, __, ___) =>
                  _iconBackdrop(subject, name, accent),
            )
          else
            _iconBackdrop(subject, name, accent),

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.02),
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.82),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),

          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (_isContributor) {
                    context.push(
                      '/contributor/mind-map?subjectId=$id&subjectName=${Uri.encodeComponent(name)}',
                    );
                  } else {
                    context.push('/subjects/$id/intro');
                  }
                },
                child: const SizedBox.expand(),
              ),
            ),
          ),

          // Icon-only layout (ẩn mô tả / nút bên dưới).
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _bgSecondary.withValues(
                          alpha: _isContributor ? 0.35 : 0.25),
                      border: Border.all(color: accent.withValues(alpha: 0.55)),
                    ),
                    child: Center(
                      child: Text(
                        iconText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      height: 1.1,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.9),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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

  Widget _buildTypeSection({
    required String title,
    required String type,
    required String tooltip,
    required List<Map<String, dynamic>> items,
    required Future<void> Function() onCreate,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x332D363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              Tooltip(
                message: tooltip,
                child: const Icon(Icons.info_outline,
                    color: AppColors.textSecondary, size: 18),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tạo'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            tooltip,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
          ),
          const SizedBox(height: 10),
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
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    _gridCrossAxisCount(MediaQuery.sizeOf(context).width - 28),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.92,
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
