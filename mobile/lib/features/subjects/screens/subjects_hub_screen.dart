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
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildHeroCard(),
                      const SizedBox(height: 14),
                      _buildContributorBanner(),
                      const SizedBox(height: 14),
                      ..._subjects.map(_buildSubjectCard),
                      if (_subjects.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 36),
                          child: Center(
                            child: Text(
                              'Chưa có môn học nào',
                              style: TextStyle(color: AppColors.textSecondary),
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

  Widget _buildSubjectCard(Map<String, dynamic> subject) {
    final id = (subject['id'] ?? '').toString();
    final name = (subject['name'] ?? 'Môn học').toString();
    final description = (subject['description'] ?? '').toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderPrimary),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Color(_subjectColor(name)).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Color(_subjectColor(name)).withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                  style: TextStyle(
                    color: Color(_subjectColor(name)),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Môn học',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (description.isNotEmpty)
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push('/subjects/$id/intro'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.cyanNeon, width: 1),
                    foregroundColor: AppColors.cyanNeon,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Vào học'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isContributor
                      ? () => context.push(
                            '/contributor/mind-map?subjectId=$id&subjectName=${Uri.encodeComponent(name)}',
                          )
                      : () => context.go('/profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purpleNeon,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(_isContributor ? 'Đóng góp bài học' : 'Bật Contributor'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
