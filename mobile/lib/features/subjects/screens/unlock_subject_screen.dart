import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/widgets/app_bar_leading_back_home.dart';
import 'package:edtech_mobile/theme/theme.dart';

class UnlockSubjectScreen extends StatefulWidget {
  final String subjectId;

  const UnlockSubjectScreen({super.key, required this.subjectId});

  @override
  State<UnlockSubjectScreen> createState() => _UnlockSubjectScreenState();
}

class _UnlockSubjectScreenState extends State<UnlockSubjectScreen> {
  Map<String, dynamic>? _pricing;
  bool _isLoading = true;
  String? _error;
  bool _isUnlocking = false;

  @override
  void initState() {
    super.initState();
    _loadPricing();
  }

  Future<void> _loadPricing() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final data = await apiService.getUnlockPricing(widget.subjectId);
      if (mounted) {
        setState(() {
          _pricing = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _unlockSubject() async {
    final confirmed = await _showConfirmDialog(
      'Mở khóa toàn bộ môn',
      'Bạn sẽ mở khóa tất cả ${_pricing!['totalLessons']} bài học với giá ${_pricing!['subject']['price']} 💎 (giảm 30%).',
      _pricing!['subject']['price'] as int,
    );
    if (confirmed != true) return;
    await _doUnlock(() async {
      final api = Provider.of<ApiService>(context, listen: false);
      return api.unlockSubject(widget.subjectId);
    });
  }

  Future<void> _unlockDomain(Map<String, dynamic> domain) async {
    final confirmed = await _showConfirmDialog(
      'Mở khóa chương "${domain['name']}"',
      'Bạn sẽ mở khóa ${domain['lessonsCount']} bài học với giá ${domain['price']} 💎 (giảm 15%).',
      domain['price'] as int,
    );
    if (confirmed != true) return;
    await _doUnlock(() async {
      final api = Provider.of<ApiService>(context, listen: false);
      return api.unlockDomain(domain['domainId']);
    });
  }

  Future<void> _unlockTopic(Map<String, dynamic> topic) async {
    final confirmed = await _showConfirmDialog(
      'Mở khóa chủ đề "${topic['name']}"',
      'Bạn sẽ mở khóa ${topic['lessonsCount']} bài học với giá ${topic['price']} 💎.',
      topic['price'] as int,
    );
    if (confirmed != true) return;
    await _doUnlock(() async {
      final api = Provider.of<ApiService>(context, listen: false);
      return api.unlockTopic(topic['topicId']);
    });
  }

  Future<bool?> _showConfirmDialog(String title, String message, int cost) {
    final balance = _pricing!['userBalance'] as int? ?? 0;
    final canAfford = balance >= cost;

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Số dư:',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                  Text('$balance 💎',
                      style: TextStyle(
                        color: canAfford
                            ? AppColors.successNeon
                            : AppColors.errorNeon,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      )),
                ],
              ),
            ),
            if (!canAfford) ...[
              const SizedBox(height: 8),
              Text(
                'Bạn cần thêm ${cost - balance} 💎. Hãy mua thêm kim cương.',
                style:
                    const TextStyle(color: AppColors.errorNeon, fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          if (canAfford)
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purpleNeon,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Mở khóa ($cost 💎)',
                  style: const TextStyle(color: Colors.white)),
            )
          else
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx, false);
                context.push('/payment');
              },
              icon: const Text('💎', style: TextStyle(fontSize: 16)),
              label: const Text('Mua kim cương'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _doUnlock(Future<Map<String, dynamic>> Function() action) async {
    setState(() => _isUnlocking = true);
    try {
      final result = await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Mở khóa thành công!'),
            backgroundColor: AppColors.successNeon,
          ),
        );
        _loadPricing(); // Reload
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi: $e'), backgroundColor: AppColors.errorNeon),
        );
      }
    } finally {
      if (mounted) setState(() => _isUnlocking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Mở khóa bài học',
            style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary)),
        leading: const AppBarLeadingBackAndHome(),
        leadingWidth: 112,
        automaticallyImplyLeading: false,
        actions: [
          if (_pricing != null)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x332D363D)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('💎', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(
                    '${_pricing!['userBalance'] ?? 0}',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.primaryLight),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryLight))
          : _error != null
              ? Center(
                  child: Text('Lỗi: $_error',
                      style: const TextStyle(color: AppColors.textSecondary)))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_pricing == null) return const SizedBox.shrink();

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSubjectUnlock(),
              const SizedBox(height: 24),
              _buildDomainUnlocks(),
              const SizedBox(height: 24),
              _buildTopicUnlocks(),
              const SizedBox(height: 80),
            ],
          ),
        ),
        if (_isUnlocking)
          Container(
            color: Colors.black54,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  // ── Section 1: Unlock whole subject ──
  Widget _buildSubjectUnlock() {
    final subject = _pricing!['subject'] as Map<String, dynamic>;
    final isUnlocked = subject['isUnlocked'] == true;
    final price = subject['price'] as int;
    final totalLessons = _pricing!['totalLessons'] as int;
    final savings = subject['savingsVsTopics'] as int;
    final totalIfTopics = _pricing!['totalIfBuyTopics'] as int;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isUnlocked
            ? LinearGradient(colors: [
                AppColors.successNeon.withValues(alpha: 0.15),
                AppColors.successNeon.withValues(alpha: 0.05)
              ])
            : LinearGradient(colors: [
                AppColors.purpleNeon.withValues(alpha: 0.15),
                AppColors.pinkNeon.withValues(alpha: 0.1)
              ]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isUnlocked
                ? AppColors.successNeon.withValues(alpha: 0.3)
                : AppColors.purpleNeon.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? AppColors.successNeon.withValues(alpha: 0.2)
                      : AppColors.purpleNeon.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isUnlocked ? Icons.lock_open_rounded : Icons.star_rounded,
                  color:
                      isUnlocked ? AppColors.successNeon : AppColors.purpleNeon,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isUnlocked ? 'Đã mở khóa toàn bộ' : 'Mở khóa toàn bộ môn',
                      style: AppTextStyles.h4
                          .copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_pricing!['subjectName']} ($totalLessons bài)',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (!isUnlocked)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.errorNeon.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('-30%',
                      style: TextStyle(
                          color: AppColors.errorNeon,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
            ],
          ),
          if (!isUnlocked) ...[
            const SizedBox(height: 16),
            // Price breakdown
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$totalLessons bài × 50 💎 × 0.7',
                          style: const TextStyle(
                              color: AppColors.textTertiary, fontSize: 12)),
                      Text('$price 💎',
                          style: const TextStyle(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Giá gốc (mua lẻ):',
                          style: TextStyle(
                              color: AppColors.textTertiary, fontSize: 11)),
                      Text('$totalIfTopics 💎',
                          style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 11,
                              decoration: TextDecoration.lineThrough)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tiết kiệm:',
                          style: TextStyle(
                              color: AppColors.successNeon, fontSize: 12)),
                      Text('$savings 💎',
                          style: const TextStyle(
                              color: AppColors.successNeon,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _unlockSubject,
                icon: const Icon(Icons.lock_open_rounded, size: 20),
                label: Text('Mở khóa cả môn — $price 💎',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purpleNeon,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Section 2: Unlock by domain ──
  Widget _buildDomainUnlocks() {
    final domains = _pricing!['domains'] as List? ?? [];
    if (domains.isEmpty) return const SizedBox.shrink();

    final isSubjectUnlocked = _pricing!['isSubjectUnlocked'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Mua theo chương',
                style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('-15%',
                  style: TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...domains.map<Widget>((domain) {
          final d = domain as Map<String, dynamic>;
          final isUnlocked = d['isUnlocked'] == true || isSubjectUnlocked;
          final name = d['name'] as String? ?? '';
          final icon = d['icon'] as String? ?? '📖';
          final lessonsCount = d['lessonsCount'] as int? ?? 0;
          final price = d['price'] as int? ?? 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? AppColors.successNeon.withValues(alpha: 0.06)
                  : AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: isUnlocked
                      ? AppColors.successNeon.withValues(alpha: 0.2)
                      : const Color(0x332D363D)),
            ),
            child: Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: AppTextStyles.labelLarge
                              .copyWith(color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text('$lessonsCount bài học',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textTertiary)),
                      if (!isUnlocked) ...[
                        const SizedBox(height: 2),
                        Text('$lessonsCount x 50 x 0.85 = $price 💎',
                            style: TextStyle(
                                color: AppColors.primaryLight
                                    .withValues(alpha: 0.8),
                                fontSize: 11)),
                      ],
                    ],
                  ),
                ),
                if (isUnlocked)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.successNeon.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Đã mở',
                        style: TextStyle(
                            color: AppColors.successNeon,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  )
                else
                  ElevatedButton(
                    onPressed: () => _unlockDomain(d),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      minimumSize: Size.zero,
                    ),
                    child: Text('$price 💎',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          );
        }),
        // Total
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.bgTertiary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng nếu mua tất cả chương:',
                  style:
                      TextStyle(color: AppColors.textTertiary, fontSize: 12)),
              Text('${_pricing!['totalIfBuyDomains']} 💎',
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Section 3: Unlock by topic ──
  Widget _buildTopicUnlocks() {
    final domains = _pricing!['domains'] as List? ?? [];
    if (domains.isEmpty) return const SizedBox.shrink();

    final isSubjectUnlocked = _pricing!['isSubjectUnlocked'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mua theo chủ đề',
            style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text('Giá gốc — không giảm giá',
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
        const SizedBox(height: 12),
        ...domains.map<Widget>((domain) {
          final d = domain as Map<String, dynamic>;
          final domainName = d['name'] as String? ?? '';
          final domainIcon = d['icon'] as String? ?? '📖';
          final domainUnlocked = d['isUnlocked'] == true || isSubjectUnlocked;
          final topics = d['topics'] as List? ?? [];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x332D363D)),
            ),
            child: Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                leading: Text(domainIcon, style: const TextStyle(fontSize: 24)),
                title: Text(domainName,
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.textPrimary)),
                subtitle: Text('${topics.length} chủ đề',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textTertiary)),
                iconColor: AppColors.textSecondary,
                collapsedIconColor: AppColors.textTertiary,
                children: topics.map<Widget>((topic) {
                  final t = topic as Map<String, dynamic>;
                  final topicName = t['name'] as String? ?? '';
                  final lessonsCount = t['lessonsCount'] as int? ?? 0;
                  final price = t['price'] as int? ?? 0;
                  final isUnlocked = t['isUnlocked'] == true || domainUnlocked;

                  return Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? AppColors.successNeon.withValues(alpha: 0.05)
                          : AppColors.bgTertiary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isUnlocked
                              ? Icons.check_circle_rounded
                              : Icons.lock_rounded,
                          color: isUnlocked
                              ? AppColors.successNeon
                              : AppColors.textTertiary,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(topicName,
                                  style: TextStyle(
                                    color: isUnlocked
                                        ? AppColors.textSecondary
                                        : AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  )),
                              Text('$lessonsCount bài',
                                  style: const TextStyle(
                                      color: AppColors.textTertiary,
                                      fontSize: 11)),
                            ],
                          ),
                        ),
                        if (isUnlocked)
                          const Text('Đã mở',
                              style: TextStyle(
                                  color: AppColors.successNeon,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold))
                        else
                          InkWell(
                            onTap: () => _unlockTopic(t),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.orangeNeon
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppColors.orangeNeon
                                        .withValues(alpha: 0.3)),
                              ),
                              child: Text('$price 💎',
                                  style: const TextStyle(
                                      color: AppColors.orangeNeon,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        }),
        // Total
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.bgTertiary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng nếu mua lẻ từng chủ đề:',
                  style:
                      TextStyle(color: AppColors.textTertiary, fontSize: 12)),
              Text('${_pricing!['totalIfBuyTopics']} 💎',
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}
