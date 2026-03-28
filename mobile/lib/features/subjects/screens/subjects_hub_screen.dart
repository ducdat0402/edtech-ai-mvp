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

  @override
  void initState() {
    super.initState();
    _loadData();
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
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                          sliver: SliverGrid(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: _gridCrossAxisCount(MediaQuery.sizeOf(context).width),
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 0.92,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildSubjectTile(_subjects[index]),
                              childCount: _subjects.length,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
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
                  'Khám phá & đóng góp môn học',
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
            _isContributor
                ? 'Bạn có thể vào từng môn để học hoặc đóng góp bài học mới cho cộng đồng.'
                : 'Bạn có thể vào học ngay. Bật Contributor để mở thêm quyền đóng góp nội dung.',
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

  static const double _tileActionBarHeight = 46;

  Widget _buildSubjectTile(Map<String, dynamic> subject) {
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
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
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
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.45)),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Học', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isContributor
                          ? () => context.push(
                                '/contributor/mind-map?subjectId=$id&subjectName=${Uri.encodeComponent(name)}',
                              )
                          : () => context.go('/profile'),
                      style: ElevatedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: AppColors.purpleNeon,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _isContributor ? 'Đóng góp' : 'Contributor',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
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
}
