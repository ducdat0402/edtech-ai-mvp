import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:edtech_mobile/core/constants/currency_labels.dart';
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
  final String? avatarFrameId;
  final double size;
  final VoidCallback? onTap;

  const LeaderboardUserAvatar({
    super.key,
    this.displayName,
    this.imageUrl,
    this.avatarFrameId,
    this.size = 44,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sem = context.colors;
    final initials = leaderboardInitials(displayName);
    final url = ApiConfig.absoluteMediaUrl(imageUrl?.trim());
    final hasUrl = url.isNotEmpty;
    final inner = size * 0.88;
    final hasFrame = avatarFrameTier(avatarFrameId) != null;

    final Widget photoCore = ClipOval(
      child: SizedBox(
        width: inner,
        height: inner,
        child: hasUrl
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => ColoredBox(
                  color: sem.cardMuted,
                  child: Center(
                    child: Text(
                      initials,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: sem.brand,
                        fontWeight: FontWeight.bold,
                        fontSize: inner * 0.32,
                      ),
                    ),
                  ),
                ),
              )
            : ColoredBox(
                color: sem.cardMuted,
                child: Center(
                  child: Text(
                    initials,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: sem.brand,
                      fontWeight: FontWeight.bold,
                      fontSize: inner * 0.32,
                    ),
                  ),
                ),
              ),
      ),
    );

    Widget avatar = hasFrame
        ? SizedBox(
            width: avatarFrameOuterDiameter(inner, avatarFrameId),
            height: avatarFrameOuterDiameter(inner, avatarFrameId),
            child: Center(
              child: AvatarFrameRing(
                frameId: avatarFrameId,
                diameter: inner,
                child: photoCore,
              ),
            ),
          )
        : CircleAvatar(
            radius: size / 2,
            backgroundColor: sem.brand.withValues(alpha: 0.25),
            backgroundImage: hasUrl ? NetworkImage(url) : null,
            child: hasUrl
                ? null
                : Text(
                    initials,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: sem.brand,
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
  /// Khung từ bảng xếp hạng (hiện ngay; API vẫn là nguồn đúng sau khi tải).
  String? avatarFrameIdHint,
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
      avatarFrameIdHint: avatarFrameIdHint,
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
  final String? avatarFrameIdHint;

  const _LeaderboardUserProfileSheetBody({
    required this.api,
    required this.userId,
    this.nameHint,
    this.rankHint,
    this.sourceLabel,
    this.weeklyXpFromBoard,
    this.avatarFrameIdHint,
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
    final sem = context.colors;
    final brandHi = Color.lerp(sem.brand, Colors.white, 0.55)!;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      decoration: BoxDecoration(
        color: sem.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
            top: BorderSide(color: sem.border.withValues(alpha: 0.65))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: sem.textTertiary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              LeaderboardUserAvatar(
                displayName: _data?['fullName'] as String? ?? widget.nameHint,
                imageUrl: _data?['avatarUrl'] as String?,
                avatarFrameId: (_data?['avatarFrameId'] as String?) ??
                    widget.avatarFrameIdHint,
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
                          .copyWith(color: sem.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.rankHint != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Hạng #${widget.rankHint}',
                        style: AppTextStyles.labelMedium
                            .copyWith(color: sem.brand),
                      ),
                    ],
                    if (widget.sourceLabel != null &&
                        widget.sourceLabel!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.sourceLabel!,
                        style: AppTextStyles.caption
                            .copyWith(color: sem.textTertiary),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded, color: sem.textSecondary),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              'Không tải được hồ sơ',
              style:
                  AppTextStyles.bodySmall.copyWith(color: sem.error),
            ),
            TextButton(
              onPressed: _load,
              style: TextButton.styleFrom(foregroundColor: sem.brand),
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
            Center(
              child: CircularProgressIndicator(color: brandHi),
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
    final sem = context.colors;
    final brandHi = Color.lerp(sem.brand, Colors.white, 0.55)!;
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
            _chip(sem, Icons.star_rounded, sem.gold, 'Tổng XP', '$totalXP'),
            _chip(sem, null, sem.gold, CurrencyLabels.gtuCoin, '$coins',
                iconWidget: const GtuCoinIcon(size: 18)),
            _chip(sem, Icons.diamond_rounded, sem.info, 'Kim cương',
                '$diamonds'),
            _chip(sem, Icons.trending_up_rounded, brandHi, 'Cấp', '$level'),
            _chip(sem, Icons.local_fire_department_rounded, sem.warning,
                'Chuỗi', '$streak'),
            if (maxStreak > 0)
              _chip(sem, Icons.emoji_events_rounded, sem.warning,
                  'Chuỗi tối đa', '$maxStreak'),
            if (weekly > 0)
              _chip(sem, Icons.calendar_view_week_rounded, sem.brand,
                  'XP tuần này', '$weekly'),
          ],
        ),
        if (joined != null) ...[
          const SizedBox(height: 16),
          Text(
            'Tham gia: ${DateFormat.yMMMd().format(joined)}',
            style:
                AppTextStyles.caption.copyWith(color: sem.textTertiary),
          ),
        ],
        if (data['role'] == 'contributor' || data['role'] == 'admin') ...[
          const SizedBox(height: 8),
          Text(
            data['role'] == 'admin' ? 'Quản trị viên' : 'Cộng tác viên',
            style: AppTextStyles.labelSmall.copyWith(color: brandHi),
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

  Widget _chip(
    SemanticColors sem,
    IconData? icon,
    Color color,
    String label,
    String value, {
    Widget? iconWidget,
  }) {
    assert(icon != null || iconWidget != null);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: sem.cardMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sem.border.withValues(alpha: 0.65)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget ?? Icon(icon!, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.caption
                    .copyWith(color: sem.textTertiary, fontSize: 10),
              ),
              Text(
                value,
                style: AppTextStyles.labelLarge
                    .copyWith(color: sem.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
