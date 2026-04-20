import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:edtech_mobile/core/constants/currency_labels.dart';
import 'package:edtech_mobile/theme/theme.dart';

const double _kAvatarFrameGridGap = 8;
/// Chiều cao nội dung thẻ ~mục tiêu — dùng để tính `childAspectRatio` theo bề ngang ô (tránh ô cao dư trên web).
const double _kAvatarFrameTargetMainExtent = 152;

/// Số cột: ước từ bề ngang tối thiểu mỗi thẻ (web rộng → nhiều cột hơn, ô không quá rộng).
int _avatarFrameGridColumns(double crossAxisExtent) {
  const minTile = 154.0;
  final n = ((crossAxisExtent + _kAvatarFrameGridGap) / (minTile + _kAvatarFrameGridGap))
      .floor();
  return n.clamp(2, 5);
}

/// `width/height` mỗi ô; height ≈ `_kAvatarFrameTargetMainExtent` khi đủ chỗ (bỏ khoảng trống dưới nút).
double _avatarFrameChildAspectRatio(double crossAxisExtent, int cols) {
  final cellW =
      (crossAxisExtent - (cols - 1) * _kAvatarFrameGridGap) / cols;
  final r = cellW / _kAvatarFrameTargetMainExtent;
  return r.clamp(0.78, 2.85);
}

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
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
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
                const SizedBox(height: 12),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.crossAxisExtent;
                final cols = _avatarFrameGridColumns(w);
                final aspect = _avatarFrameChildAspectRatio(w, cols);
                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: _kAvatarFrameGridGap,
                    mainAxisSpacing: _kAvatarFrameGridGap,
                    childAspectRatio: aspect,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _FrameCard(
                        frame: frames[index],
                        equippedId: equippedId,
                        userLevel: userLevel,
                        coins: coins,
                        diamonds: diamonds,
                        onPurchase: onPurchase,
                        onEquip: onEquip,
                      );
                    },
                    childCount: frames.length,
                  ),
                );
              },
            ),
          ),
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
    final minLevel = (frame['minLevel'] as num?)?.toInt() ?? 1;
    final mode = frame['paymentMode'] as String? ?? 'coins';
    final priceCoins = (frame['priceCoins'] as num?)?.toInt();
    final priceDiamonds = (frame['priceDiamonds'] as num?)?.toInt();
    final owned = frame['owned'] as bool? ?? false;
    final lockedByLevel = frame['lockedByLevel'] as bool? ?? false;
    final canPurchase = frame['canPurchase'] as bool? ?? false;
    final isEquipped = equippedId == id;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isEquipped
              ? AppColors.successNeon.withValues(alpha: 0.45)
              : const Color(0x332D363D),
        ),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            SizedBox(
              height: 48,
              child: Center(
                child: AvatarFrameRing(
                  frameId: id,
                  diameter: 32,
                  child: ClipOval(
                    child: Container(
                      color: AppColors.bgTertiary,
                      child: Icon(
                        Icons.person_rounded,
                        size: 18,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                height: 1.1,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            _PriceRow(
              mode: mode,
              priceCoins: priceCoins,
              priceDiamonds: priceDiamonds,
              compact: true,
            ),
            if (minLevel > 1) ...[
              const SizedBox(height: 1),
              Text(
                'Cấp $minLevel',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: lockedByLevel
                      ? AppColors.warningNeon
                      : AppColors.textTertiary,
                  fontSize: 8,
                  height: 1,
                ),
              ),
            ],
            const SizedBox(height: 4),
            if (owned && !isEquipped)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    await onEquip(id);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: AppColors.primaryLight,
                    side: BorderSide(
                      color: AppColors.primaryLight.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Text('Đeo', style: TextStyle(fontSize: 12)),
                ),
              ),
            if (isEquipped)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.successNeon.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  'Đang đeo',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.successNeon,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
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
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: canPurchase && !lockedByLevel
                        ? AppColors.purpleNeon
                        : AppColors.bgTertiary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    lockedByLevel ? 'Khóa cấp' : 'Mua',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            if (owned && isEquipped)
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 22),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await onEquip(null);
                },
                child: const Text(
                  'Gỡ khung',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
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
  final bool compact;

  const _PriceRow({
    required this.mode,
    required this.priceCoins,
    required this.priceDiamonds,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (mode == 'coins' && priceCoins != null) {
      final row = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          GtuCoinIcon(size: compact ? 14 : 16),
          const SizedBox(width: 4),
          Text(
            '$priceCoins ${CurrencyLabels.gtuShort}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.coinGold,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 10 : 12,
            ),
          ),
        ],
      );
      if (compact) {
        return Center(child: row);
      }
      return row;
    }
    if (mode == 'diamonds' && priceDiamonds != null) {
      final row = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.diamond_rounded,
              color: AppColors.primaryLight, size: compact ? 14 : 16),
          const SizedBox(width: 4),
          Text(
            compact ? '$priceDiamonds 💎' : '$priceDiamonds kim cương',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 10 : 12,
            ),
          ),
        ],
      );
      if (compact) {
        return Center(child: row);
      }
      return row;
    }
    if (mode == 'choice') {
      final col = Column(
        crossAxisAlignment: compact
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (priceCoins != null)
            Row(
              mainAxisAlignment: compact
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GtuCoinIcon(size: compact ? 12 : 14),
                const SizedBox(width: 3),
                Text(
                  '$priceCoins ${CurrencyLabels.gtuShort}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.coinGold,
                    fontSize: compact ? 10 : 11,
                  ),
                ),
              ],
            ),
          if (priceDiamonds != null) ...[
            SizedBox(height: compact ? 1 : 2),
            Row(
              mainAxisAlignment: compact
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.diamond_rounded,
                    color: AppColors.primaryLight, size: compact ? 12 : 14),
                const SizedBox(width: 3),
                Text(
                  '$priceDiamonds 💎',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryLight,
                    fontSize: compact ? 10 : 11,
                  ),
                ),
              ],
            ),
          ],
          if (!compact) ...[
            const SizedBox(height: 4),
            Text(
              'Chọn loại tiền khi bấm Mua',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textTertiary,
                fontSize: 10,
              ),
            ),
          ],
        ],
      );
      if (compact) {
        return Center(child: col);
      }
      return col;
    }
    return const SizedBox.shrink();
  }
}
