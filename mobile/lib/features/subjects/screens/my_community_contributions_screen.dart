import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/widgets/app_bar_leading_back_home.dart';
import 'package:edtech_mobile/theme/theme.dart';

/// Môn **cộng đồng** mà user đã có bài được ghi công + tỉ lệ A/B (dashboard.contributorStats).
class MyCommunityContributionsScreen extends StatefulWidget {
  const MyCommunityContributionsScreen({super.key});

  @override
  State<MyCommunityContributionsScreen> createState() =>
      _MyCommunityContributionsScreenState();
}

class _MyCommunityContributionsScreenState
    extends State<MyCommunityContributionsScreen> {
  static const String _helpText =
      'Cách đọc số liệu:\n\n'
      '• Tổng quan môn: trong toàn bộ bài học của môn, có bao nhiêu bài đã được ghi nhận người đóng góp cộng đồng.\n'
      '• Phần của bạn: trong nhóm bài đã ghi nhận đóng góp ở trên, có bao nhiêu bài ghi tên bạn.\n\n'
      'Bạn bấm vào từng môn để xem chi tiết dạng mind-map.';

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final dash = await api.getDashboard();
      final raw = dash['subjects'] as List? ?? const [];
      final all = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      final filtered = all.where((s) {
        if ((s['subjectType'] ?? '').toString() != 'community') return false;
        final st = s['contributorStats'];
        if (st is! Map) return false;
        final mine = (st['myCreditedNodes'] as num?)?.toInt() ?? 0;
        return mine > 0;
      }).toList();
      if (!mounted) return;
      setState(() {
        _items = filtered;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.contributorBgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const AppBarLeadingBackAndHome(),
        leadingWidth: 112,
        automaticallyImplyLeading: false,
        title: Text(
          'Đóng góp của tôi',
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            tooltip: 'Cách đọc số liệu',
            onPressed: _showHowToReadDialog,
            icon: const Icon(Icons.help_outline_rounded),
            color: AppColors.contributorBlue,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.contributorBlue,
        onRefresh: _load,
        child: _loading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: CircularProgressIndicator(color: AppColors.contributorBlue),
                  ),
                ],
              )
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(
                        _error!,
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _load,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  )
                : _items.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                        children: [
                          Icon(
                            Icons.volunteer_activism_outlined,
                            size: 56,
                            color: AppColors.textTertiary.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có môn cộng đồng nào ghi nhận đóng góp của bạn',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.h4
                                .copyWith(color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Khi bài bạn gửi được duyệt và hệ thống gắn tên bạn là người đóng góp trên bài đó, môn tương ứng sẽ hiện ở đây kèm số liệu dễ đọc.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textSecondary, height: 1.4),
                          ),
                        ],
                      )
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        children: [
                          for (var i = 0; i < _items.length; i++) ...[
                            if (i > 0) const SizedBox(height: 10),
                            _buildSubjectTile(_items[i]),
                          ],
                        ],
                      ),
      ),
    );
  }

  Future<void> _showHowToReadDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cách đọc số liệu'),
          content: Text(
            _helpText,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đã hiểu'),
            ),
          ],
        );
      },
    );
  }

  IconData _iconForSubject(String name) {
    final n = name.toLowerCase();
    if (n.contains('toán') || n.contains('math')) return Icons.calculate_rounded;
    if (n.contains('lý') || n.contains('physics')) return Icons.science_rounded;
    if (n.contains('hoá') || n.contains('hoa') || n.contains('chem')) {
      return Icons.biotech_rounded;
    }
    if (n.contains('sinh') || n.contains('bio')) return Icons.eco_rounded;
    if (n.contains('văn') || n.contains('ngu van')) return Icons.menu_book_rounded;
    if (n.contains('anh') || n.contains('english')) return Icons.translate_rounded;
    if (n.contains('sử') || n.contains('history')) return Icons.history_edu_rounded;
    if (n.contains('địa') || n.contains('dia') || n.contains('geo')) {
      return Icons.public_rounded;
    }
    if (n.contains('tin') || n.contains('it') || n.contains('lập trình')) {
      return Icons.computer_rounded;
    }
    if (n.contains('bóng') || n.contains('thể')) return Icons.sports_soccer_rounded;
    return Icons.auto_stories_rounded;
  }

  Color _accentForSubject(String name) {
    final n = name.toLowerCase();
    if (n.contains('toán') || n.contains('math')) return const Color(0xFF4F7CFF);
    if (n.contains('lý') || n.contains('physics')) return const Color(0xFF7B61FF);
    if (n.contains('hoá') || n.contains('hoa') || n.contains('chem')) {
      return const Color(0xFF26B3A0);
    }
    if (n.contains('sinh') || n.contains('bio')) return const Color(0xFF3CBF5E);
    if (n.contains('văn') || n.contains('ngu van')) return const Color(0xFFCF7C2D);
    if (n.contains('anh') || n.contains('english')) return const Color(0xFF2F9BFF);
    if (n.contains('sử') || n.contains('history')) return const Color(0xFFB05BD0);
    if (n.contains('địa') || n.contains('dia') || n.contains('geo')) {
      return const Color(0xFF1FA18A);
    }
    if (n.contains('tin') || n.contains('it') || n.contains('lập trình')) {
      return const Color(0xFF2E7BEA);
    }
    if (n.contains('bóng') || n.contains('thể')) return const Color(0xFF26A96D);
    return AppColors.contributorBlue;
  }

  Widget _buildProgressRow({
    required String label,
    required int percent,
    required Color color,
  }) {
    final clamped = percent.clamp(0, 100);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$clamped%',
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 7,
            value: clamped / 100,
            backgroundColor: AppColors.textTertiary.withValues(alpha: 0.22),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  String _sentenceToanMon(int total, int withCc, int ccPct) {
    if (total <= 0) {
      return 'Chưa có dữ liệu tổng số bài trong môn.';
    }
    if (withCc <= 0) {
      return 'Trong $total bài học của môn, hiện chưa có bài nào được ghi nhận người đóng góp cộng đồng.';
    }
    return 'Trong $total bài học của môn, có $withCc bài đã được ghi nhận do cộng đồng đóng góp '
        '(tương đương khoảng $ccPct% số bài trong môn).';
  }

  String _sentencePhanBan(int mine, int withCc, int? myPct) {
    if (withCc <= 0) {
      return 'Chưa có nhóm bài nào được ghi nhận đóng góp để so sánh phần của bạn.';
    }
    if (myPct != null) {
      return 'Trong $withCc bài đã ghi nhận đóng góp ở trên, có $mine bài ghi tên bạn '
          '(tương đương khoảng $myPct% trong nhóm bài đó).';
    }
    return 'Bạn được ghi nhận trên $mine bài trong môn này.';
  }

  Widget _buildSubjectTile(Map<String, dynamic> s) {
    final id = (s['id'] ?? '').toString();
    final name = (s['name'] ?? 'Môn học').toString();
    final st = s['contributorStats'];
    final Map<String, dynamic> m =
        st is Map ? Map<String, dynamic>.from(st) : {};
    final total = (m['totalNodes'] as num?)?.toInt() ?? 0;
    final withCc = (m['nodesWithContributor'] as num?)?.toInt() ?? 0;
    final ccPct = (m['communityPercent'] as num?)?.toInt() ?? 0;
    final mine = (m['myCreditedNodes'] as num?)?.toInt() ?? 0;
    final myPct = m['mySharePercent'] as int?;
    final accent = _accentForSubject(name);
    final mySharePercent = (myPct ?? (withCc == 0 ? 0 : ((mine * 100) ~/ withCc)))
        .clamp(0, 100);

    return Material(
      color: AppColors.contributorBgSecondary,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: id.isEmpty
            ? null
            : () => context.push(
                  '/contributor/mind-map?subjectId=$id&subjectName=${Uri.encodeComponent(name)}',
                ),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _iconForSubject(name),
                      size: 18,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      style: AppTextStyles.labelLarge
                          .copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Tổng quan môn',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.contributorBlue,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _sentenceToanMon(total, withCc, ccPct),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              _buildProgressRow(
                label: 'Mức ghi nhận cộng đồng',
                percent: ccPct,
                color: accent,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Phần của bạn',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.contributorBlue,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _sentencePhanBan(mine, withCc, myPct),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              _buildProgressRow(
                label: 'Tỷ lệ phần của bạn',
                percent: mySharePercent,
                color: AppColors.contributorBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
