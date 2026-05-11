import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/widgets/app_bar_leading_back_home.dart';
import 'package:edtech_mobile/theme/theme.dart';

/// "Hành trình của tôi" — tab Đóng góp (mockup MT-02).
///
/// Hai tab ở header (Đang học / Đóng góp). Tab "Đang học" mở
/// `/profile/journey`. Tab "Đóng góp" hiển thị các môn cộng đồng kèm
/// progress gold + lịch sử đóng góp.
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
      '• Tổng đóng góp: tổng số bài bạn đã được ghi nhận trong tất cả môn.\n'
      '• Tỉ lệ duyệt: phần trăm bài bạn gửi mà đã được duyệt.\n\n'
      'Nhấn vào từng môn để xem chi tiết các bài bạn đã đóng góp.';

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  int _totalContributions = 0;
  int _approvalPercent = 0;

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

      var total = 0;
      for (final s in filtered) {
        final st = s['contributorStats'];
        if (st is Map) {
          total += (st['myCreditedNodes'] as num?)?.toInt() ?? 0;
        }
      }

      var approval = 0;
      var totalSubjectNodes = 0;
      var totalCreditedNodes = 0;
      for (final s in filtered) {
        final st = s['contributorStats'];
        if (st is Map) {
          totalSubjectNodes += (st['nodesWithContributor'] as num?)?.toInt() ?? 0;
          totalCreditedNodes += (st['myCreditedNodes'] as num?)?.toInt() ?? 0;
        }
      }
      if (totalSubjectNodes > 0) {
        approval = ((totalCreditedNodes * 100) ~/ totalSubjectNodes).clamp(0, 100);
      }

      if (!mounted) return;
      setState(() {
        _items = filtered;
        _totalContributions = total;
        _approvalPercent = approval;
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
    final tokens = context.colors;
    return Scaffold(
      backgroundColor: tokens.bg,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerScrolled) => [
          SliverAppBar(
            pinned: true,
            stretch: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leadingWidth: 112,
            leading: const AppBarLeadingBackAndHome(),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                tooltip: 'Cách đọc số liệu',
                onPressed: _showHowToReadDialog,
                icon: const Icon(Icons.help_outline_rounded),
                color: tokens.textOnBrand,
              ),
              const SizedBox(width: 4),
            ],
            expandedHeight: 220,
            flexibleSpace: FlexibleSpaceBar(
              background: BrandHeader(
                bottomCornerRadius: 32,
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hành trình của tôi',
                      style: AppTextStyles.h2.copyWith(
                        color: tokens.textOnBrand,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SectionTabSwitcher(
                      tabs: const [
                        SectionTabItem(
                          label: 'Đang học',
                          icon: Icons.school_rounded,
                        ),
                        SectionTabItem(
                          label: 'Đóng góp',
                          icon: Icons.volunteer_activism_rounded,
                        ),
                      ],
                      selectedIndex: 1,
                      onChanged: (i) {
                        if (i == 0) {
                          context.push('/profile/journey');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: RefreshIndicator(
          color: tokens.brand,
          onRefresh: _load,
          child: _buildBody(tokens),
        ),
      ),
    );
  }

  Widget _buildBody(SemanticColors tokens) {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Center(child: CircularProgressIndicator(color: tokens.brand)),
        ],
      );
    }
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            _error!,
            style: AppTextStyles.bodyMedium.copyWith(color: tokens.textSecondary),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _load,
            child: const Text('Thử lại'),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryStatCard(
                icon: Icons.menu_book_rounded,
                label: 'Tổng đóng góp',
                value: '$_totalContributions',
                color: tokens.brand,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryStatCard(
                icon: Icons.verified_rounded,
                label: 'Tỉ lệ duyệt',
                value: '$_approvalPercent%',
                color: tokens.gold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Đóng góp theo môn',
          style: AppTextStyles.h3.copyWith(
            color: tokens.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        if (_items.isEmpty)
          _EmptySubjectsCard(tokens: tokens)
        else
          for (var i = 0; i < _items.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _buildSubjectTile(_items[i]),
          ],
      ],
    );
  }

  Widget _buildSubjectTile(Map<String, dynamic> s) {
    final id = (s['id'] ?? '').toString();
    final name = (s['name'] ?? 'Môn học').toString();
    final st = s['contributorStats'];
    final Map<String, dynamic> m =
        st is Map ? Map<String, dynamic>.from(st) : {};
    final total = (m['totalNodes'] as num?)?.toInt() ?? 0;
    final withCc = (m['nodesWithContributor'] as num?)?.toInt() ?? 0;
    final mine = (m['myCreditedNodes'] as num?)?.toInt() ?? 0;
    final myPct = m['mySharePercent'] as int?;
    final mySharePercent =
        (myPct ?? (withCc == 0 ? 0 : ((mine * 100) ~/ withCc))).clamp(0, 100);
    final accent = _accentForSubject(name);

    final ratio = total == 0 ? 0.0 : (mine / total).clamp(0.0, 1.0);
    final progressLabel =
        total == 0 ? '$mine bài' : '$mine/$total bài';

    return SubjectListTile(
      name: name,
      subtitle: 'Đóng góp đã ghi: $mine bài • Tỷ lệ trong nhóm: $mySharePercent%',
      leadingIcon: _iconForSubject(name),
      leadingColor: accent,
      actionLabel: 'Tiếp tục',
      progressValue: ratio,
      progressLabel: progressLabel,
      onTap: id.isEmpty
          ? () {}
          : () => context.push('/library'),
    );
  }

  Future<void> _showHowToReadDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cách đọc số liệu'),
          content: const Text(_helpText),
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
    return const Color(0xFF6B46C1);
  }
}

class _SummaryStatCard extends StatelessWidget {
  const _SummaryStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.border),
        boxShadow: [
          BoxShadow(
            color: tokens.shadowColor,
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: tokens.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.h2.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySubjectsCard extends StatelessWidget {
  const _EmptySubjectsCard({required this.tokens});
  final SemanticColors tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.volunteer_activism_outlined,
            size: 48,
            color: tokens.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            'Chưa có môn cộng đồng nào ghi nhận đóng góp của bạn',
            textAlign: TextAlign.center,
            style: AppTextStyles.h4.copyWith(color: tokens.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Khi bài bạn gửi được duyệt và hệ thống gắn tên bạn là người đóng góp, môn tương ứng sẽ hiện ở đây.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: tokens.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
