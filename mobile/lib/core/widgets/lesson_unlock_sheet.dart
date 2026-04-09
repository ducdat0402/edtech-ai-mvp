import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LessonUnlockSheet {
  static Future<bool> show({
    required BuildContext context,
    required ApiService api,
    required String nodeId,
    required String title,
    String? subjectId,
    Future<void> Function()? onOpened,
  }) async {
    /// null = không tải được API (không được coi như "hết suất").
    int? remainingFree;
    var accessLoadFailed = false;
    String subjectType = 'expert';
    int coinCost = 50;
    int diamondCost = 50;
    int userCoins = 0;
    int userDiamonds = 0;
    try {
      final access = await api.checkNodeAccess(nodeId);
      subjectType = (access['subjectType'] ?? 'expert').toString();
      remainingFree =
          (access['remainingFreeLessonsToday'] as num?)?.toInt() ?? 0;
      coinCost = (access['coinCost'] as num?)?.toInt() ?? 50;
      diamondCost = (access['diamondCost'] as num?)?.toInt() ?? 50;
      userCoins = (access['userCoins'] as num?)?.toInt() ?? 0;
      userDiamonds = (access['userDiamonds'] as num?)?.toInt() ?? 0;
    } catch (e) {
      accessLoadFailed = true;
      remainingFree = null;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Không tải được trạng thái mở bài: $e',
            ),
            backgroundColor: AppColors.errorNeon,
          ),
        );
      }
    }

    if (!context.mounted) return false;

    final opened = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        var busy = false;
        return StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔒', style: TextStyle(fontSize: 46)),
                const SizedBox(height: 10),
                Text(
                  title,
                  style:
                      AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  subjectType == 'community'
                      ? 'Mỗi ngày bạn có 2 bài miễn phí trên toàn bộ môn. Hết suất: $coinCost xu hoặc $diamondCost 💎.'
                      : 'Mỗi ngày bạn có 2 bài miễn phí trên toàn bộ môn. Hết suất: $diamondCost 💎.',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  accessLoadFailed
                      ? 'Không xác định số suất còn lại. Bấm "Mở bài" — nếu còn suất, hệ thống sẽ mở miễn phí.'
                      : (remainingFree != null && remainingFree > 0)
                          ? 'Suất miễn phí hôm nay: còn $remainingFree.'
                          : 'Hôm nay đã dùng hết 2 suất miễn phí.',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.cyanNeon, fontSize: 12),
                ),
                if (subjectType == 'community')
                  Text(
                    'Xu hiện có: $userCoins',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textTertiary, fontSize: 11),
                  ),
                Text(
                  'Kim cương hiện có: $userDiamonds 💎',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textTertiary, fontSize: 11),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            busy ? null : () => Navigator.pop(ctx, false),
                        child: const Text('Đóng'),
                      ),
                    ),
                    if (subjectType == 'community') ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: busy
                              ? null
                              : () async {
                                  setModalState(() => busy = true);
                                  try {
                                    await api.openLearningNode(nodeId,
                                        currencyType: 'coins');
                                    if (onOpened != null) await onOpened();
                                    if (ctx.mounted) Navigator.pop(ctx, true);
                                  } catch (e) {
                                    setModalState(() => busy = false);
                                    if (ctx.mounted) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        SnackBar(
                                            content: Text('$e'),
                                            backgroundColor:
                                                AppColors.errorNeon),
                                      );
                                    }
                                  }
                                },
                          child: Text(
                            remainingFree == null
                                ? 'Mở bài (xu)'
                                : (remainingFree > 0
                                    ? 'Mở miễn phí (xu)'
                                    : '$coinCost xu'),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: busy
                            ? null
                            : () async {
                                setModalState(() => busy = true);
                                try {
                                  await api.openLearningNode(
                                    nodeId,
                                    currencyType: subjectType == 'community'
                                        ? 'diamonds'
                                        : null,
                                  );
                                  if (onOpened != null) await onOpened();
                                  if (ctx.mounted) Navigator.pop(ctx, true);
                                } catch (e) {
                                  setModalState(() => busy = false);
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                          content: Text('$e'),
                                          backgroundColor: AppColors.errorNeon),
                                    );
                                  }
                                }
                              },
                        child: Text(
                          remainingFree == null
                              ? 'Mở bài'
                              : (remainingFree > 0
                                  ? 'Mở miễn phí'
                                  : '$diamondCost 💎'),
                        ),
                      ),
                    ),
                  ],
                ),
                if (subjectId != null && subjectId.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () {
                            Navigator.pop(ctx, false);
                            context.push('/subjects/$subjectId/unlock');
                          },
                    child: const Text('Xem gói mở chủ đề / chương / môn'),
                  ),
                ],
                TextButton(
                  onPressed: busy
                      ? null
                      : () {
                          Navigator.pop(ctx, false);
                          context.push('/payment');
                        },
                  child: const Text('Mua kim cương'),
                ),
              ],
            ),
          ),
        );
      },
    );
    return opened == true;
  }
}
