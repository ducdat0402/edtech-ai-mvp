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
                            'Khi bài bạn đóng góp được duyệt và gắn ghi công, môn tương ứng sẽ xuất hiện ở đây cùng tỉ lệ cộng đồng và phần của bạn.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textSecondary, height: 1.4),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final s = _items[i];
                          final id = (s['id'] ?? '').toString();
                          final name = (s['name'] ?? 'Môn học').toString();
                          final st = s['contributorStats'];
                          final Map<String, dynamic> m = st is Map
                              ? Map<String, dynamic>.from(st)
                              : {};
                          final total =
                              (m['totalNodes'] as num?)?.toInt() ?? 0;
                          final withCc =
                              (m['nodesWithContributor'] as num?)?.toInt() ?? 0;
                          final ccPct =
                              (m['communityPercent'] as num?)?.toInt() ?? 0;
                          final mine =
                              (m['myCreditedNodes'] as num?)?.toInt() ?? 0;
                          final myPct = m['mySharePercent'] as int?;

                          final lineA = total > 0
                              ? 'Cộng đồng: $ccPct% ($withCc/$total bài có ghi công)'
                              : 'Cộng đồng: —';
                          final lineB = withCc > 0 && myPct != null
                              ? 'Bạn: $myPct% ($mine/$withCc bài CC)'
                              : 'Bạn: $mine bài được ghi công';

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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: AppTextStyles.labelLarge
                                                .copyWith(
                                                    color: AppColors.textPrimary),
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          color: AppColors.textTertiary,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      lineA,
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.contributorBlue,
                                        height: 1.35,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      lineB,
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textSecondary,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
