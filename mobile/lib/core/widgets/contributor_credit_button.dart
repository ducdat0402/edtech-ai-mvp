import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:edtech_mobile/core/config/api_config.dart';
import 'package:edtech_mobile/theme/theme.dart';

bool lessonContributorVisible(Map<String, dynamic>? contributor) {
  if (contributor == null) return false;
  final id = contributor['id'];
  return id != null && id.toString().isNotEmpty;
}

String lessonContributorDisplayName(Map<String, dynamic> c) {
  final n = (c['fullName'] as String?)?.trim();
  if (n != null && n.isNotEmpty) return n;
  return 'Thành viên';
}

Map<String, dynamic>? _contributorMapFromEntry(Object? raw) {
  if (raw == null) return null;
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return null;
}

/// Có ít nhất một thông tin ghi công / phiên bản để hiển thị sheet.
bool lessonCreditSheetVisible(
  Map<String, dynamic>? contributor,
  List<Map<String, dynamic>>? contentVersionHistory,
) {
  if (lessonContributorVisible(contributor)) return true;
  final h = contentVersionHistory;
  if (h == null || h.isEmpty) return false;
  for (final e in h) {
    if (lessonContributorVisible(_contributorMapFromEntry(e['contributor']))) {
      return true;
    }
  }
  return false;
}

Map<String, dynamic>? primaryContributorForCreditIcon(
  Map<String, dynamic>? contributor,
  List<Map<String, dynamic>>? contentVersionHistory,
) {
  if (lessonContributorVisible(contributor)) return contributor;
  final h = contentVersionHistory;
  if (h == null) return null;
  for (final e in h) {
    final c = _contributorMapFromEntry(e['contributor']);
    if (lessonContributorVisible(c)) return c;
  }
  return null;
}

String _formatVersionDate(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  try {
    final d = DateTime.parse(iso).toLocal();
    return DateFormat('dd/MM/yyyy HH:mm').format(d);
  } catch (_) {
    return iso;
  }
}

String _versionEntryLabel(Map<String, dynamic> e) {
  if (e['isCurrent'] == true) return 'Phiên bản đang học';
  final v = e['version'];
  if (v is num) return 'Bản lưu #${v.toInt()}';
  return 'Phiên bản';
}

/// Sheet: ghi công + lịch sử phiên bản (nhiều người qua các lần cập nhật đã duyệt).
void showLessonContributorCreditSheet(
  BuildContext context, {
  Map<String, dynamic>? contributor,
  List<Map<String, dynamic>>? contentVersionHistory,
}) {
  if (!lessonCreditSheetVisible(contributor, contentVersionHistory)) {
    return;
  }

  final history = [...?contentVersionHistory];
  final hero = lessonContributorVisible(contributor)
      ? contributor!
      : primaryContributorForCreditIcon(contributor, history);

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bgSecondary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final bottomInset = MediaQuery.paddingOf(ctx).bottom;
      final maxH = MediaQuery.sizeOf(ctx).height * 0.88;

      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottomInset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Icon(Icons.volunteer_activism_rounded,
                    size: 32, color: AppColors.contributorBlue),
                const SizedBox(height: 10),
                Text(
                  'Cảm ơn cộng đồng!',
                  style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Nội dung được thêm hoặc cập nhật sau khi duyệt. Dưới đây là phiên bản đang học và các bản đã lưu trước khi có chỉnh sửa.',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                if (hero != null && history.isEmpty) ...[
                  const SizedBox(height: 18),
                  _ContributorHeroRow(contributor: hero),
                ],
                if (history.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Lịch sử phiên bản',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  for (var i = 0; i < history.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    _VersionHistoryTile(entry: history[i]),
                  ],
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _ContributorHeroRow extends StatelessWidget {
  final Map<String, dynamic> contributor;

  const _ContributorHeroRow({required this.contributor});

  @override
  Widget build(BuildContext context) {
    final name = lessonContributorDisplayName(contributor);
    final avatarUrl =
        ApiConfig.absoluteMediaUrl(contributor['avatarUrl'] as String?);

    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.contributorBlue.withValues(alpha: 0.2),
          backgroundImage: avatarUrl.isNotEmpty
              ? CachedNetworkImageProvider(avatarUrl)
              : null,
          child: avatarUrl.isEmpty
              ? const Icon(Icons.person_rounded,
                  size: 30, color: AppColors.contributorBlue)
              : null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Ghi nhận trên bài học',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.contributorBlue),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VersionHistoryTile extends StatelessWidget {
  final Map<String, dynamic> entry;

  const _VersionHistoryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final contrib = _contributorMapFromEntry(entry['contributor']);
    final hasContributor = lessonContributorVisible(contrib);
    final name = hasContributor
        ? lessonContributorDisplayName(contrib!)
        : '—';
    final avatarUrl = hasContributor
        ? ApiConfig.absoluteMediaUrl(contrib!['avatarUrl'] as String?)
        : '';
    final date = _formatVersionDate(entry['createdAt'] as String?);
    final note = (entry['note'] as String?)?.trim();
    final label = _versionEntryLabel(entry);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textTertiary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.contributorBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.contributorBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.textTertiary.withValues(alpha: 0.2),
            backgroundImage:
                avatarUrl.isNotEmpty ? CachedNetworkImageProvider(avatarUrl) : null,
            child: avatarUrl.isEmpty
                ? const Icon(
                    Icons.person_outline_rounded,
                    size: 20,
                    color: AppColors.textTertiary,
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textTertiary),
                  ),
                ],
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    note,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary, height: 1.25),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Nút góc AppBar — sheet gồm ghi công chính và lịch sử phiên bản (nếu có).
class ContributorCreditButton extends StatelessWidget {
  final Map<String, dynamic>? contributor;
  final List<Map<String, dynamic>>? contentVersionHistory;

  const ContributorCreditButton({
    super.key,
    this.contributor,
    this.contentVersionHistory,
  });

  @override
  Widget build(BuildContext context) {
    if (!lessonCreditSheetVisible(contributor, contentVersionHistory)) {
      return const SizedBox.shrink();
    }

    final c = primaryContributorForCreditIcon(
      contributor,
      contentVersionHistory,
    );
    if (c == null) return const SizedBox.shrink();

    final avatarUrl = ApiConfig.absoluteMediaUrl(c['avatarUrl'] as String?);
    final extraCount = _distinctContributorCount(contentVersionHistory) -
        (lessonContributorVisible(c) ? 1 : 0);

    return IconButton(
      tooltip: 'Đóng góp & lịch sử phiên bản',
      onPressed: () => showLessonContributorCreditSheet(
        context,
        contributor: contributor,
        contentVersionHistory: contentVersionHistory,
      ),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: AppColors.contributorBlue.withValues(alpha: 0.2),
            backgroundImage: avatarUrl.isNotEmpty
                ? CachedNetworkImageProvider(avatarUrl)
                : null,
            child: avatarUrl.isEmpty
                ? const Icon(Icons.volunteer_activism_rounded,
                    size: 16, color: AppColors.contributorBlue)
                : null,
          ),
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: AppColors.bgPrimary,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.favorite_rounded,
                  size: 11, color: Colors.pinkAccent.shade200),
            ),
          ),
          if (extraCount > 0)
            Positioned(
              left: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.contributorBlue,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.bgPrimary, width: 1),
                ),
                child: Text(
                  '+$extraCount',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

int _distinctContributorCount(List<Map<String, dynamic>>? history) {
  if (history == null || history.isEmpty) return 0;
  final ids = <String>{};
  for (final e in history) {
    final c = _contributorMapFromEntry(e['contributor']);
    if (lessonContributorVisible(c)) {
      ids.add(c!['id'].toString());
    }
  }
  return ids.length;
}
