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
  static const String _tooltipHowToRead =
      'Các con số lấy từ thống kê môn trên máy chủ.\n'
      '• Tổng quan môn: so với toàn bộ bài trong môn.\n'
      '• Phần của bạn: trong các bài đã ghi nhận đóng góp, bao nhiêu bài có tên bạn.';

  static const String _tooltipTongQuanMon =
      'Đếm trên toàn bộ bài học của môn: có bao nhiêu bài đã gắn ít nhất một người đóng góp cộng đồng (không chỉ riêng bạn). '
      'Phần trăm là tỷ lệ số bài đó so với tổng số bài trong môn.';

  static const String _tooltipPhanBan =
      'Trong các bài đã được ghi nhận đóng góp ở môn này (nhóm “tổng quan” phía trên), đếm bao nhiêu bài ghi tên bạn. '
      'Phần trăm (nếu có) là phần của bạn trong nhóm bài đó.';

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
                          _buildHowToReadBox(),
                          const SizedBox(height: 12),
                          for (var i = 0; i < _items.length; i++) ...[
                            if (i > 0) const SizedBox(height: 10),
                            _buildSubjectTile(_items[i]),
                          ],
                        ],
                      ),
      ),
    );
  }

  /// Giải thích ngắn — tránh từ viết tắt, tránh “%” khó nếu chưa đọc dòng dưới.
  Widget _buildHowToReadBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.contributorBgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textTertiary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              'Mỗi dòng là một môn cộng đồng. Hai câu bên dưới tên môn: '
              '(1) trong tất cả bài học của môn, có bao nhiêu bài đã được ghi nhận người đóng góp; '
              '(2) trong số các bài đã ghi nhận đó, có bao nhiêu bài ghi tên bạn.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Tooltip(
            message: _tooltipHowToRead,
            showDuration: const Duration(seconds: 8),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 2, 4),
                child: Icon(
                  Icons.help_outline_rounded,
                  size: 20,
                  color: AppColors.contributorBlue.withValues(alpha: 0.85),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Icon “?”: giữ tap để không kích hoạt thẻ môn; nhấn giữ để xem Tooltip.
  Widget _tooltipHintIcon(String message) {
    return Tooltip(
      message: message,
      showDuration: const Duration(seconds: 8),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.fromLTRB(2, 0, 0, 2),
          child: Icon(
            Icons.info_outline_rounded,
            size: 17,
            color: AppColors.contributorBlue.withValues(alpha: 0.75),
          ),
        ),
      ),
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
                  _tooltipHintIcon(_tooltipTongQuanMon),
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
                  _tooltipHintIcon(_tooltipPhanBan),
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
            ],
          ),
        ),
      ),
    );
  }
}
