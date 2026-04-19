import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:edtech_mobile/core/constants/currency_labels.dart';
import 'package:edtech_mobile/theme/theme.dart';
import 'package:edtech_mobile/theme/widgets/avatar_frame_ring.dart';
/// Tab cửa hàng — danh sách khung avatar (catalog từ backend).
class ShopAvatarFramesTab extends StatelessWidget {
  final List<Map<String, dynamic>> frames;
  final int coins;
  final int diamonds;
  final int userLevel;
  final String? equippedId;
  final Future<void> Function() onRefresh;
  final Future<void> Function(
    Map<String, dynamic> frame, {
    String? currency,
  }) onPurchase;
  final Future<void> Function(String? frameId) onEquip;

  const ShopAvatarFramesTab({
    super.key,
    required this.frames,
    required this.coins,
    required this.diamonds,
    required this.userLevel,
    required this.equippedId,
    required this.onRefresh,
    required this.onPurchase,
    required this.onEquip,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primaryLight,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _WalletBar(coins: coins, diamonds: diamonds, level: userLevel),
          const SizedBox(height: 16),
          Text(
            'Khung avatar',
            style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Tier càng cao càng chi tiết — giá theo GTU hoặc kim cương. Một số khung cần đủ cấp mới mua được.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ...frames.map((f) => _FrameCard(
                frame: f,
                equippedId: equippedId,
                userLevel: userLevel,
                coins: coins,
                diamonds: diamonds,
                onPurchase: onPurchase,
                onEquip: onEquip,
              )),
        ],
      ),
    );
  }
}

class _WalletBar extends StatelessWidget {
  final int coins;
  final int diamonds;
  final int level;

  const _WalletBar({
    required this.coins,
    required this.diamonds,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.purpleNeon.withValues(alpha: 0.12),
            AppColors.bgSecondary,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_rounded,
              color: AppColors.primaryLight, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const GtuCoinIcon(size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '$coins',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.coinGold,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.diamond_rounded,
                        color: AppColors.primaryLight, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '$diamonds',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.bgTertiary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Cấp $level',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FrameCard extends StatelessWidget {
  final Map<String, dynamic> frame;
  final String? equippedId;
  final int userLevel;
  final int coins;
  final int diamonds;
  final Future<void> Function(Map<String, dynamic> frame, {String? currency})
      onPurchase;
  final Future<void> Function(String? frameId) onEquip;

  const _FrameCard({
    required this.frame,
    required this.equippedId,
    required this.userLevel,
    required this.coins,
    required this.diamonds,
    required this.onPurchase,
    required this.onEquip,
  });

  @override
  Widget build(BuildContext context) {
    final id = frame['id'] as String? ?? '';
    final name = frame['name'] as String? ?? id;
    final desc = frame['description'] as String? ?? '';
    final tier = (frame['tier'] as num?)?.toInt() ?? 1;
    final minLevel = (frame['minLevel'] as num?)?.toInt() ?? 1;
    final mode = frame['paymentMode'] as String? ?? 'coins';
    final priceCoins = (frame['priceCoins'] as num?)?.toInt();
    final priceDiamonds = (frame['priceDiamonds'] as num?)?.toInt();
    final owned = frame['owned'] as bool? ?? false;
    final lockedByLevel = frame['lockedByLevel'] as bool? ?? false;
    final canPurchase = frame['canPurchase'] as bool? ?? false;
    final isEquipped = equippedId == id;

    final preview = SizedBox(
      width: 56,
      height: 56,
      child: Center(
        child: AvatarFrameRing(
          frameId: id,
          diameter: 40,
          child: ClipOval(
            child: Container(
              color: AppColors.bgTertiary,
              child: Icon(
                Icons.person_rounded,
                size: 22,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEquipped
              ? AppColors.successNeon.withValues(alpha: 0.45)
              : const Color(0x332D363D),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                preview,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.bgTertiary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'T$tier',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textTertiary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _PriceRow(
                        mode: mode,
                        priceCoins: priceCoins,
                        priceDiamonds: priceDiamonds,
                      ),
                      if (minLevel > 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Cần cấp $minLevel để mở khóa mua',
                            style: AppTextStyles.caption.copyWith(
                              color: lockedByLevel
                                  ? AppColors.warningNeon
                                  : AppColors.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (owned && !isEquipped)
                  OutlinedButton(
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      await onEquip(id);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryLight,
                      side: BorderSide(
                        color: AppColors.primaryLight.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Text('Đeo'),
                  ),
                if (isEquipped)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.successNeon.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Đang đeo',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.successNeon,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                if (!owned)
                  Tooltip(
                    message: lockedByLevel
                        ? 'Cần cấp $minLevel để mua (bạn đang cấp $userLevel)'
                        : (mode == 'choice'
                            ? 'Chọn GTU hoặc kim cương khi mua'
                            : 'Mua khung'),
                    child: FilledButton(
                      onPressed: (!canPurchase || lockedByLevel)
                          ? null
                          : () => _confirmPurchase(
                                context,
                                frame,
                                mode,
                                priceCoins,
                                priceDiamonds,
                              ),
                      style: FilledButton.styleFrom(
                        backgroundColor: canPurchase && !lockedByLevel
                            ? AppColors.purpleNeon
                            : AppColors.bgTertiary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        lockedByLevel ? 'Khóa cấp' : 'Mua',
                      ),
                    ),
                  ),
                if (owned && isEquipped)
                  TextButton(
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      await onEquip(null);
                    },
                    child: const Text(
                      'Gỡ khung',
                      style: TextStyle(color: AppColors.textTertiary),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmPurchase(
    BuildContext context,
    Map<String, dynamic> frame,
    String mode,
    int? priceCoins,
    int? priceDiamonds,
  ) async {
    String? currency;
    if (mode == 'choice') {
      currency = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.bgSecondary,
          title: Text(
            'Chọn loại tiền',
            style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const GtuCoinIcon(size: 24),
                title: Text(
                  '${CurrencyLabels.gtuShort} — $priceCoins',
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () => Navigator.pop(ctx, 'coins'),
              ),
              ListTile(
                leading: const Icon(Icons.diamond_rounded,
                    color: AppColors.primaryLight),
                title: Text(
                  'Kim cương — $priceDiamonds 💎',
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () => Navigator.pop(ctx, 'diamonds'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
          ],
        ),
      );
      if (currency == null) return;
      if (currency == 'coins' &&
          priceCoins != null &&
          coins < priceCoins) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không đủ GTU (cần $priceCoins).'),
            backgroundColor: AppColors.errorNeon,
          ),
        );
        return;
      }
      if (currency == 'diamonds' &&
          priceDiamonds != null &&
          diamonds < priceDiamonds) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không đủ kim cương (cần $priceDiamonds).'),
            backgroundColor: AppColors.errorNeon,
          ),
        );
        return;
      }
    } else {
      if (mode == 'coins' && priceCoins != null && coins < priceCoins) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không đủ GTU (cần $priceCoins).'),
            backgroundColor: AppColors.errorNeon,
          ),
        );
        return;
      }
      if (mode == 'diamonds' &&
          priceDiamonds != null &&
          diamonds < priceDiamonds) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không đủ kim cương (cần $priceDiamonds).'),
            backgroundColor: AppColors.errorNeon,
          ),
        );
        return;
      }
    }

    try {
      HapticFeedback.mediumImpact();
      await onPurchase(frame, currency: currency);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã mua khung! Có thể đeo ngay.'),
          backgroundColor: AppColors.successNeon,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: AppColors.errorNeon,
        ),
      );
    }
  }
}

class _PriceRow extends StatelessWidget {
  final String mode;
  final int? priceCoins;
  final int? priceDiamonds;

  const _PriceRow({
    required this.mode,
    required this.priceCoins,
    required this.priceDiamonds,
  });

  @override
  Widget build(BuildContext context) {
    if (mode == 'coins' && priceCoins != null) {
      return Row(
        children: [
          const GtuCoinIcon(size: 16),
          const SizedBox(width: 4),
          Text(
            '$priceCoins ${CurrencyLabels.gtuShort}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.coinGold,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }
    if (mode == 'diamonds' && priceDiamonds != null) {
      return Row(
        children: [
          const Icon(Icons.diamond_rounded,
              color: AppColors.primaryLight, size: 16),
          const SizedBox(width: 4),
          Text(
            '$priceDiamonds kim cương',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }
    if (mode == 'choice') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (priceCoins != null)
            Row(
              children: [
                const GtuCoinIcon(size: 16),
                const SizedBox(width: 4),
                Text(
                  '$priceCoins ${CurrencyLabels.gtuShort}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.coinGold,
                  ),
                ),
              ],
            ),
          if (priceDiamonds != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.diamond_rounded,
                    color: AppColors.primaryLight, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$priceDiamonds kim cương',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryLight,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Chọn loại tiền khi bấm Mua',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
              fontSize: 10,
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
