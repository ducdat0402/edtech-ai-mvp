import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edtech_mobile/core/constants/currency_labels.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/widgets/app_bar_leading_back_home.dart';
import 'package:edtech_mobile/core/widgets/bottom_nav_bar.dart';
import 'package:edtech_mobile/core/services/role_preview_service.dart';
import 'package:edtech_mobile/theme/semantic_colors.dart';
import 'package:edtech_mobile/theme/text_styles.dart';
import 'package:edtech_mobile/features/subjects/widgets/library_featured_podium.dart';
import 'package:edtech_mobile/features/subjects/widgets/library_page_sliver_body.dart';
import 'package:edtech_mobile/features/subjects/widgets/library_ui_constants.dart';

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
  /// Lọc nhóm môn (mock "Nhóm môn học"); `all` = không lọc theo loại.
  String _subjectTypeGroup = 'all';
  String _libraryCategoryFilter = kLibraryCategoryAll;
  LibraryFeaturedSort _featuredSort = LibraryFeaturedSort.byLearners;
  List<Map<String, dynamic>> _subjects = [];
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

  Set<String> get _presentLibraryCategorySlugs {
    final out = <String>{};
    for (final s in _subjects) {
      out.add((s['libraryCategory'] ?? 'other').toString());
    }
    return out;
  }

  Map<String, int> get _subjectCountsByType {
    int c(String t) => _subjects
        .where((s) => (s['subjectType'] ?? 'community').toString() == t)
        .length;
    return {
      'private': c('private'),
      'community': c('community'),
      'expert': c('expert'),
    };
  }

  /// Thư viện learner mới: tìm kiếm + category + nhóm loại môn.
  List<Map<String, dynamic>> get _hubFilteredSubjects {
    var list = _filteredSubjects;
    if (_libraryCategoryFilter != kLibraryCategoryAll) {
      list = list
          .where(
            (s) =>
                (s['libraryCategory'] ?? 'other').toString() ==
                _libraryCategoryFilter,
          )
          .toList();
    }
    if (_subjectTypeGroup != 'all') {
      list = list
          .where(
            (s) =>
                (s['subjectType'] ?? 'community').toString() ==
                _subjectTypeGroup,
          )
          .toList();
    }
    return list;
  }

  void _navigateToSubject(Map<String, dynamic> subject) {
    final id = (subject['id'] ?? '').toString();
    if (id.isEmpty) return;
    context.push('/subjects/$id/intro');
  }

  Future<void> _onLibraryContributeTab() async {
    if (!_canUseLibraryRoleSwitch) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Tài khoản hiện tại chưa hỗ trợ chuyển chế độ đóng góp.',
          ),
          backgroundColor: context.colors.info,
        ),
      );
      return;
    }
    await _handleSwitchRole();
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
      final profileMap = Map<String, dynamic>.from(profile as Map);
      final role = profileMap['role']?.toString() ?? 'user';
      final actualRole = profileMap['actualRole']?.toString() ?? role;
      final canContribute = actualRole == 'contributor' || actualRole == 'admin';
      final viewAsContributor = actualRole == 'admin'
          ? !RolePreviewService.adminPreviewLearnerEnabled
          : role == 'contributor';
      setState(() {
        _subjects = rawSubjects
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _profileData = profileMap;
        _viewAsContributor = canContribute ? viewAsContributor : false;
        _loading = false;
      });
      if (mounted && !_isContributor) {
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
  String get _actualRole =>
      _profileData?['actualRole']?.toString() ?? _currentRole;
  bool get _hasContributorRole =>
      _actualRole == 'contributor' || _actualRole == 'admin';
  bool get _canUseLibraryRoleSwitch =>
      _actualRole == 'admin' ||
      _currentRole == 'user' ||
      _currentRole == 'contributor';
  bool get _isContributor => _hasContributorRole && _viewAsContributor;

  /// Surface tokens — contributor luôn palette dark semantic (kể cả app theme sáng).
  Color get _bgPrimary {
    if (_isContributor) return SemanticColors.dark.bg;
    return context.colors.bg;
  }

  Color get _bgSecondary {
    if (_isContributor) return SemanticColors.dark.card;
    return context.colors.card;
  }

  Color get _borderColor {
    if (_isContributor) return SemanticColors.dark.border;
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0x332D363D)
        : context.colors.border;
  }

  /// Chữ & accent đọc được trên nền hiện tại (contributor luôn nền tối).
  SemanticColors get _screenTokens {
    if (_isContributor) return SemanticColors.dark;
    return Theme.of(context).brightness == Brightness.dark
        ? SemanticColors.dark
        : SemanticColors.light;
  }

  Future<void> _handleSwitchRole() async {
    if (_isSwitchingRole) return;

    // Admin: backend không cho đổi role qua endpoint switch-role (sẽ trả 400).
    // Vì vậy ta chỉ toggle "view mode" trong UI.
    if (_actualRole == 'admin') {
      final nextViewAsContributor = !_viewAsContributor;
      setState(() => _isSwitchingRole = true);
      await RolePreviewService.setAdminPreviewLearnerEnabled(
        !nextViewAsContributor,
      );
      if (!mounted) return;
      setState(() {
        _viewAsContributor = nextViewAsContributor;
        _profileData = {
          ...?_profileData,
          'actualRole': 'admin',
          'role': nextViewAsContributor ? 'admin' : 'user',
          'rolePreview': nextViewAsContributor ? null : 'learner',
        };
      });
      if (!mounted) return;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _viewAsContributor
                  ? 'Đang xem dưới chế độ Contributor (Admin)'
                  : 'Đang xem dưới chế độ Learner (Admin)',
            ),
            backgroundColor: _viewAsContributor
                ? context.colors.info
                : context.colors.success,
          ),
        );
      }
      setState(() => _isSwitchingRole = false);
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
                ? context.colors.info
                : context.colors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: context.colors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSwitchingRole = false);
    }
  }

  Widget _buildLearnerLibraryGridSection(SemanticColors t) {
    final sem = context.colors;
    final items = _hubFilteredSubjects;
    if (_subjects.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'Chưa có môn học nào',
            style: TextStyle(color: t.textSecondary),
          ),
        ),
      );
    }
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'Không có môn phù hợp với bộ lọc hoặc từ khóa.',
            textAlign: TextAlign.center,
            style: TextStyle(color: t.textSecondary, height: 1.35),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tất cả môn học',
          style: AppTextStyles.h4.copyWith(
            color: sem.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: _librarySubjectsGridDelegate(
            MediaQuery.sizeOf(context).width - 52,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => _buildSubjectTile(items[index]),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final sem = context.colors;
    final t = _screenTokens;
    final scaffoldBg = _isContributor ? _bgPrimary : sem.bg;

    if (_loading) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        body: Center(child: CircularProgressIndicator(color: t.brand)),
        bottomNavigationBar: const BottomNavBar(currentIndex: 1),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        appBar: _isContributor
            ? AppBar(
                backgroundColor: _bgPrimary,
                elevation: 0,
                automaticallyImplyLeading: false,
                leading: AppBarLeadingBackAndHome(iconColor: t.textPrimary),
                leadingWidth: 112,
                title: Text(
                  'Thư viện',
                  style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : AppBar(
                backgroundColor: sem.card,
                title: const Text('Thư viện'),
              ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: t.error, size: 44),
                const SizedBox(height: 8),
                Text(
                  'Không tải được danh sách môn học.\n$_error',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: t.textSecondary),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const BottomNavBar(currentIndex: 1),
      );
    }

    final libraryMode =
        _isContributor ? LibraryPageMode.contributor : LibraryPageMode.learner;

    final scrollSlivers = libraryMode == LibraryPageMode.contributor
        ? LibraryPageSlivers.contributor(
            screenTokens: t,
            searchController: _searchController,
            searchFocusNode: _searchFocusNode,
            onStudyTab: () {
              if (_isContributor) {
                _handleSwitchRole();
              }
            },
            contributorBanner: _buildContributorBanner(),
            subjects: _subjects,
            filteredSubjects: _filteredSubjects,
            typeSectionChildren: [
              _buildTypeSection(
                title: 'Môn học cá nhân',
                sectionIcon: Icons.lock_rounded,
                sectionTint: t.info,
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
                sectionTint: t.gold,
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
                sectionTint: t.brand,
                summary:
                    'Nội dung chuyên sâu — mỗi bài mở bằng 50 kim cương; cần admin duyệt.',
                detail:
                    'Mỗi bài học mở khóa bằng 50 kim cương. Nội dung ở mức chuyên sâu, cần phê duyệt admin.',
                items: _subjectsByType('expert'),
                onCreate: _showCreateExpertDialog,
              ),
            ],
          )
        : LibraryPageSlivers.learner(
            appSemantic: sem,
            searchController: _searchController,
            searchFocusNode: _searchFocusNode,
            onContributeTab: _onLibraryContributeTab,
            canSwitchToContribute: _canUseLibraryRoleSwitch,
            presentLibraryCategorySlugs: _presentLibraryCategorySlugs,
            libraryCategoryFilter: _libraryCategoryFilter,
            onLibraryCategorySelected: (v) =>
                setState(() => _libraryCategoryFilter = v),
            hubFilteredSubjects: _hubFilteredSubjects,
            featuredSort: _featuredSort,
            onFeaturedSortChanged: (s) => setState(() => _featuredSort = s),
            onSubjectTap: _navigateToSubject,
            subjectTypeGroup: _subjectTypeGroup,
            subjectCountsByType: _subjectCountsByType,
            onSubjectTypeGroupSelect: (type) {
              setState(() {
                _subjectTypeGroup =
                    _subjectTypeGroup == type ? 'all' : type;
              });
            },
            learnerGridSection: _buildLearnerLibraryGridSection(t),
          );

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: t.brand,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: scrollSlivers,
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildContributorBanner() {
    final t = _screenTokens;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: _bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: t.info.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights_rounded,
                color: t.info,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Xem đóng góp của tôi',
                  style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Chỉ liệt kê môn cộng đồng mà đã có bài ghi tên bạn; mỗi môn hiện hai câu giải thích rõ (tổng quan môn và phần của bạn).',
            style: TextStyle(
              color: t.textSecondary,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => context.push('/library/my-contributions'),
            icon: const Icon(Icons.arrow_forward_rounded, size: 20),
            label: const Text('Mở bảng đóng góp'),
            style: FilledButton.styleFrom(
              backgroundColor: t.info,
              foregroundColor: t.textOnBrand,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Nội dung giải thích 3 loại môn — dùng trong bottom sheet lần đầu (5A).
  Widget _buildSubjectTypesExplainerBody() {
    final t = _screenTokens;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            t.brand.withValues(alpha: 0.22),
            t.card,
          ],
        ),
        border: Border.all(color: t.brand.withValues(alpha: 0.28)),
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
                  color: t.brand.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.menu_book_rounded,
                    color: t.onBrand),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Khám phá 3 loại môn học',
                  style: TextStyle(
                    color: t.textPrimary,
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
            style: TextStyle(
              color: t.textSecondary,
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
            decoration: BoxDecoration(
              color: ctx.colors.card,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                          color: ctx.colors.textTertiary,
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
    final on = _screenTokens.textOnBrand;
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
            color: on,
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
        color: on,
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
    final tokens = _screenTokens;
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
              Color.lerp(accent, tokens.textOnBrand, 0.22)!,
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
                  tokens.textOnBrand.withValues(alpha: 0.32),
                  tokens.textOnBrand.withValues(alpha: 0.0),
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
    final t = _screenTokens;
    final name = (subject['name'] ?? 'Môn học').toString();
    final totalNodes = (subject['totalNodesCount'] as num?)?.toInt();
    final coverUrl = _customCoverUrl(subject);
    final accent = _accentFromSubject(subject, name);

    const double d = 54;

    void onTap() => _navigateToSubject(subject);

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
                  color: t.textPrimary,
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
                    color: t.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
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
      builder: (ctx) {
        final d = ctx.colors;
        return AlertDialog(
        backgroundColor: d.card,
        title: Text(
          'Yêu cầu nâng hạng môn',
          style: TextStyle(color: d.textPrimary),
        ),
        content: Text(
          'Môn "$subjectName" đang là private. Bạn muốn gửi duyệt lên loại nào?',
          style: TextStyle(color: d.textSecondary),
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
      );
      },
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
        SnackBar(content: Text('$e'), backgroundColor: context.colors.error),
      );
    }
  }

  void _showContributorSectionDetail(String title, String detail) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.card,
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
                        color: context.colors.textSecondary,
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
    required Color sectionTint,
  }) {
    final st = _screenTokens;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _bgSecondary,
        border: Border.all(
          color: Color.lerp(_borderColor, sectionTint, 0.35)!,
        ),
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
                    color: st.textOnBrand.withValues(alpha: 0.12),
                  ),
                ),
                child: Icon(sectionIcon, color: sectionTint, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: st.textPrimary,
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
                icon: Icon(Icons.info_outline_rounded,
                    color: st.textSecondary, size: 22),
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
              color: st.textSecondary.withValues(alpha: 0.95),
              fontSize: 12.5,
              height: 1.38,
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Chưa có môn học',
                style: TextStyle(color: st.textSecondary),
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
      builder: (ctx) {
        final d = ctx.colors;
        return AlertDialog(
        backgroundColor: d.card,
        title:
            Text(title, style: TextStyle(color: d.textPrimary)),
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
      );
      },
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
        SnackBar(content: Text('$e'), backgroundColor: context.colors.error),
      );
    }
  }
}
