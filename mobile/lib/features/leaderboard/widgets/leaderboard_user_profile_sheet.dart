import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:edtech_mobile/core/config/api_config.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/theme/theme.dart';

/// Chữ viết tắt từ tên hiển thị trên avatar.
String leaderboardInitials(String? name) {
  if (name == null || name.trim().isEmpty) return '?';
  final parts =
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.length >= 2) {
    final a = parts[0][0];
    final b = parts[1][0];
    return '$a$b'.toUpperCase();
  }
  return parts[0][0].toUpperCase();
}

/// Avatar tròn (chữ hoặc ảnh). Chỉ vùng avatar nhận tap.
class LeaderboardUserAvatar extends StatelessWidget {
  final String? displayName;
  final String? imageUrl;
  final double size;
  final VoidCallback? onTap;

  const LeaderboardUserAvatar({
    super.key,
    this.displayName,
    this.imageUrl,
    this.size = 44,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = leaderboardInitials(displayName);
    final url = ApiConfig.absoluteMediaUrl(imageUrl?.trim());
    final hasUrl = url.isNotEmpty;

    Widget avatar = CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.purpleNeon.withValues(alpha: 0.25),
      backgroundImage: hasUrl ? NetworkImage(url) : null,
      child: hasUrl
          ? null
          : Text(
              initials,
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.purpleNeon,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.32,
              ),
            ),
    );

    if (onTap == null) return avatar;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: avatar,
      ),
    );
  }
}

void showLeaderboardUserProfileSheet(
  BuildContext context, {
  required ApiService api,
  required String userId,
  String? nameHint,
  int? rankHint,
  String? sourceLabel,
  int? weeklyXpFromBoard,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _LeaderboardUserProfileSheetBody(
      api: api,
      userId: userId,
      nameHint: nameHint,
      rankHint: rankHint,
      sourceLabel: sourceLabel,
      weeklyXpFromBoard: weeklyXpFromBoard,
    ),
  );
}

class _LeaderboardUserProfileSheetBody extends StatefulWidget {
  final ApiService api;
  final String userId;
  final String? nameHint;
  final int? rankHint;
  final String? sourceLabel;
  final int? weeklyXpFromBoard;

  const _LeaderboardUserProfileSheetBody({
    required this.api,
    required this.userId,
    this.nameHint,
    this.rankHint,
    this.sourceLabel,
    this.weeklyXpFromBoard,
  });

  @override
  State<_LeaderboardUserProfileSheetBody> createState() =>
      _LeaderboardUserProfileSheetBodyState();
}

class _LeaderboardUserProfileSheetBodyState
    extends State<_LeaderboardUserProfileSheetBody> {
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await widget.api.getUserPublicProfile(widget.userId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
        _error = null;
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
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0x332D363D))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              LeaderboardUserAvatar(
                displayName: _data?['fullName'] as String? ?? widget.nameHint,
                imageUrl: _data?['avatarUrl'] as String?,
                size: 64,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _loading
                          ? (widget.nameHint ?? 'Đang tải…')
                          : (_data?['fullName'] as String? ??
                              widget.nameHint ??
                              'Người chơi'),
                      style: AppTextStyles.h4
                          .copyWith(color: AppColors.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.rankHint != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Hạng #${widget.rankHint}',
                        style: AppTextStyles.labelMedium
                            .copyWith(color: AppColors.purpleNeon),
                      ),
                    ],
                    if (widget.sourceLabel != null &&
                        widget.sourceLabel!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.sourceLabel!,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textTertiary),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded,
                    color: AppColors.textSecondary),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              'Không tải được hồ sơ',
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.errorNeon),
            ),
            TextButton(
              onPressed: _load,
              style:
                  TextButton.styleFrom(foregroundColor: AppColors.purpleNeon),
              child: const Text('Thử lại'),
            ),
          ],
          if (!_loading && _error == null && _data != null) ...[
            const SizedBox(height: 20),
            _StatGrid(
              data: _data!,
              weeklyXpFromBoard: widget.weeklyXpFromBoard,
            ),
          ],
          if (_loading) ...[
            const SizedBox(height: 24),
            const Center(
              child: CircularProgressIndicator(color: AppColors.primaryLight),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  final Map<String, dynamic> data;
  final int? weeklyXpFromBoard;

  const _StatGrid({required this.data, this.weeklyXpFromBoard});

  @override
  Widget build(BuildContext context) {
    final totalXP = _asInt(data['totalXP']);
    final coins = _asInt(data['coins']);
    final diamonds = _asInt(data['diamonds']);
    final level = _asInt(data['level'], fallback: 1);
    final streak = _asInt(data['currentStreak']);
    final maxStreak = _asInt(data['maxStreak']);
    final weeklyApi = _asInt(data['weeklyXp']);
    final weekly = weeklyXpFromBoard != null && weeklyXpFromBoard! > 0
        ? weeklyXpFromBoard!
        : weeklyApi;

    final memberSince = data['memberSince'] as String?;
    DateTime? joined;
    if (memberSince != null) {
      joined = DateTime.tryParse(memberSince);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _chip(Icons.star_rounded, AppColors.xpGold, 'Tổng XP', '$totalXP'),
            _chip(Icons.monetization_on_rounded, AppColors.coinGold, 'Xu',
                '$coins'),
            _chip(Icons.diamond_rounded, AppColors.primaryLight, 'Kim cương',
                '$diamonds'),
            _chip(Icons.trending_up_rounded, AppColors.primaryLight, 'Cấp',
                '$level'),
            _chip(Icons.local_fire_department_rounded, AppColors.streakOrange,
                'Chuỗi', '$streak'),
            if (maxStreak > 0)
              _chip(Icons.emoji_events_rounded, AppColors.orangeNeon,
                  'Chuỗi tối đa', '$maxStreak'),
            if (weekly > 0)
              _chip(Icons.calendar_view_week_rounded, AppColors.purpleNeon,
                  'XP tuần này', '$weekly'),
          ],
        ),
        if (joined != null) ...[
          const SizedBox(height: 16),
          Text(
            'Tham gia: ${DateFormat.yMMMd().format(joined)}',
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
          ),
        ],
        if (data['role'] == 'contributor' || data['role'] == 'admin') ...[
          const SizedBox(height: 8),
          Text(
            data['role'] == 'admin' ? 'Quản trị viên' : 'Cộng tác viên',
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.primaryLight),
          ),
        ],
      ],
    );
  }

  static int _asInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? fallback;
  }

  Widget _chip(IconData icon, Color color, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x332D363D)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textTertiary, fontSize: 10),
              ),
              Text(
                value,
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
