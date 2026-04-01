import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/widgets/app_bar_leading_back_home.dart';
import 'package:edtech_mobile/core/widgets/bottom_nav_bar.dart';
import 'package:edtech_mobile/theme/colors.dart';

class SubjectsHubScreen extends StatefulWidget {
  const SubjectsHubScreen({super.key});

  @override
  State<SubjectsHubScreen> createState() => _SubjectsHubScreenState();
}

class _SubjectsHubScreenState extends State<SubjectsHubScreen> {
  bool _loading = true;
  String? _error;
  bool _isContributor = false;
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
      final role = (profile['role'] ?? 'user').toString();
      setState(() {
        _subjects = rawSubjects.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _isContributor = role == 'contributor' || role == 'admin';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
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
        leading: const AppBarLeadingBackAndHome(),
        leadingWidth: 112,
        automaticallyImplyLeading: false,
        title: const Text(
          'Môn học',
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
          ? const Center(child: CircularProgressIndicator(color: AppColors.purpleNeon))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.errorNeon, size: 44),
                        const SizedBox(height: 8),
                        Text(
                          'Không tải được danh sách môn học.\n$_error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSecondary),
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
                            _buildHeroCard(),
                            const SizedBox(height: 14),
                            _buildContributorBanner(),
                            const SizedBox(height: 14),
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
        hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.85), fontSize: 14),
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 22),
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
          borderSide: BorderSide(color: AppColors.borderPrimary),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColors.borderPrimary),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColors.purpleNeon, width: 1.2),
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
                  AppColors.orangeNeon.withValues(alpha: 0.14),
                  AppColors.orangeNeon.withValues(alpha: 0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isContributor
              ? AppColors.successNeon.withValues(alpha: 0.4)
              : AppColors.orangeNeon.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isContributor ? Icons.verified : Icons.info_outline,
            color: _isContributor ? AppColors.successNeon : AppColors.orangeNeon,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
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
                child: const Icon(Icons.menu_book_rounded, color: AppColors.purpleNeon),
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
      0xFF8B5CF6,
      0xFF06B6D4,
      0xFF10B981,
      0xFFF59E0B,
      0xFFEC4899,
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

  Widget _subjectIconWatermark(Map<String, dynamic> subject, String name, Color accent) {
    final meta = _metadata(subject);
    final iconRaw = meta?['icon']?.toString().trim();
    if (iconRaw != null && iconRaw.isNotEmpty) {
      final hasPicto = RegExp(r'\p{Extended_Pictographic}', unicode: true).hasMatch(iconRaw);
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

  Widget _iconBackdrop(Map<String, dynamic> subject, String name, Color accent) {
    final base = Color.lerp(accent, const Color(0xFF0A0A0F), 0.72) ?? AppColors.bgSecondary;
    final deep = Color.lerp(accent, Colors.black, 0.55) ?? AppColors.bgSecondary;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            base,
            AppColors.bgSecondary,
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

  static const double _tileActionBarHeight = 52;

  Widget _buildSubjectTile(Map<String, dynamic> subject) {
    final subjectType = (subject['subjectType'] ?? 'community').toString();
    final id = (subject['id'] ?? '').toString();
    final name = (subject['name'] ?? 'Môn học').toString();
    final description = (subject['description'] ?? '').toString();
    final coverUrl = _customCoverUrl(subject);
    final accent = _accentFromSubject(subject, name);

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
              errorBuilder: (_, __, ___) => _iconBackdrop(subject, name, accent),
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
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: _tileActionBarHeight,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push('/subjects/$id/intro'),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: _tileActionBarHeight,
            child: IgnorePointer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      height: 1.15,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.9),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 10,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.95),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 2, 6, 7),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.9),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.push('/subjects/$id/intro'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
                        minimumSize: const Size(0, 34),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.45)),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Học', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: subjectType == 'community'
                          ? (_isContributor
                              ? () => context.push(
                                    '/contributor/mind-map?subjectId=$id&subjectName=${Uri.encodeComponent(name)}',
                                  )
                              : () => context.go('/profile'))
                          : (subjectType == 'private'
                              ? () => _showPromotionDialog(subjectId: id, subjectName: name)
                              : null),
                      style: ElevatedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
                        minimumSize: const Size(0, 34),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: AppColors.purpleNeon,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          subjectType == 'community'
                              ? (_isContributor ? 'Đóng góp' : 'Contributor')
                              : (subjectType == 'private' ? 'Nâng hạng' : '---'),
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ),
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
      await api.requestSubjectPromotion(subjectId: subjectId, targetType: target);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi yêu cầu nâng hạng, chờ admin phê duyệt')),
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
        border: Border.all(color: AppColors.borderPrimary),
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
                child: const Icon(Icons.info_outline, color: AppColors.textSecondary, size: 18),
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
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
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
                crossAxisCount: _gridCrossAxisCount(MediaQuery.sizeOf(context).width - 28),
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
      onSubmit: (api, name, desc) => api.createPrivateSubject(name: name, description: desc),
      successMessage: 'Đã tạo môn private thành công',
    );
  }

  Future<void> _showCreateCommunityDialog() async {
    await _showCreateDialog(
      title: 'Đề xuất môn cộng đồng',
      onSubmit: (api, name, desc) => api.createSubjectContribution(name: name, description: desc),
      successMessage: 'Đã gửi đề xuất môn cộng đồng, chờ admin duyệt',
    );
  }

  Future<void> _showCreateExpertDialog() async {
    await _showCreateDialog(
      title: 'Tạo môn rồi gửi duyệt chuyên gia',
      onSubmit: (api, name, desc) async {
        final created = await api.createPrivateSubject(name: name, description: desc);
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
    required Future<Map<String, dynamic>> Function(ApiService api, String name, String description) onSubmit,
    required String successMessage,
  }) async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Tạo')),
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
