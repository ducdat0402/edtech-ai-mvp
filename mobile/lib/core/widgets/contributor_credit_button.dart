import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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

/// Sheet chi tiết ghi công — dùng chung cho AppBar và thanh trong bài.
void showLessonContributorCreditSheet(
  BuildContext context,
  Map<String, dynamic> contributor,
) {
  final name = lessonContributorDisplayName(contributor);
  final avatarUrl =
      ApiConfig.absoluteMediaUrl(contributor['avatarUrl'] as String?);

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.bgSecondary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Icon(Icons.volunteer_activism_rounded,
              size: 36, color: AppColors.contributorBlue),
          const SizedBox(height: 12),
          Text(
            'Cảm ơn người đóng góp!',
            style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Nội dung bài học này được thêm vào khóa học nhờ đóng góp từ cộng đồng và đã được duyệt.',
            style:
                AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor:
                    AppColors.contributorBlue.withValues(alpha: 0.2),
                backgroundImage: avatarUrl.isNotEmpty
                    ? CachedNetworkImageProvider(avatarUrl)
                    : null,
                child: avatarUrl.isEmpty
                    ? const Icon(Icons.person_rounded,
                        size: 32, color: AppColors.contributorBlue)
                    : null,
              ),
              const SizedBox(width: 16),
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
                      'Người đóng góp',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.contributorBlue),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Nút góc AppBar — bấm để xem ai được ghi công đóng góp bài học (sau khi admin duyệt).
class ContributorCreditButton extends StatelessWidget {
  final Map<String, dynamic>? contributor;

  const ContributorCreditButton({super.key, this.contributor});

  @override
  Widget build(BuildContext context) {
    final c = contributor;
    if (!lessonContributorVisible(c)) {
      return const SizedBox.shrink();
    }

    final avatarUrl = ApiConfig.absoluteMediaUrl(c!['avatarUrl'] as String?);

    return IconButton(
      tooltip: 'Đóng góp bởi cộng đồng',
      onPressed: () => showLessonContributorCreditSheet(context, c),
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
        ],
      ),
    );
  }
}
