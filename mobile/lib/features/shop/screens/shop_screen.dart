import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/theme/theme.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        title: Text(
          'Cửa hàng',
          style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/dashboard');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(),
            const SizedBox(height: 24),
            _buildComingSoonSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.coinGold.withOpacity(0.15),
            AppColors.orangeNeon.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.coinGold.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.coinGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.storefront_rounded,
                    color: AppColors.coinGold, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Số dư của bạn',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.monetization_on_rounded,
                            color: AppColors.coinGold, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          'Coins',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.coinGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 20),
                        const Icon(Icons.diamond_rounded,
                            color: AppColors.cyanNeon, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          'Kim cương',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.cyanNeon,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.textTertiary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Coins kiếm được qua học tập dùng để mua vật phẩm.\nKim cương dùng để mở khóa nội dung và tính năng AI.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
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

  Widget _buildComingSoonSection() {
    final items = [
      {
        'icon': Icons.palette_rounded,
        'title': 'Theme & Avatar',
        'desc': 'Đổi giao diện, avatar cho hồ sơ cá nhân',
        'price': '500',
      },
      {
        'icon': Icons.auto_awesome_rounded,
        'title': 'Boost XP x2',
        'desc': 'Nhân đôi XP nhận được trong 1 giờ',
        'price': '200',
      },
      {
        'icon': Icons.shield_rounded,
        'title': 'Streak Shield',
        'desc': 'Bảo vệ streak khi lỡ quên 1 ngày',
        'price': '300',
      },
      {
        'icon': Icons.tips_and_updates_rounded,
        'title': 'Hint Token',
        'desc': 'Gợi ý đáp án khi làm quiz',
        'price': '100',
      },
      {
        'icon': Icons.card_giftcard_rounded,
        'title': 'Hộp quà may mắn',
        'desc': 'Nhận ngẫu nhiên XP, Coins hoặc vật phẩm',
        'price': '150',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Vật phẩm',
              style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.orangeNeon.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Sắp ra mắt',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.orangeNeon,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...items.map((item) => _buildShopItemCard(
              icon: item['icon'] as IconData,
              title: item['title'] as String,
              desc: item['desc'] as String,
              price: item['price'] as String,
            )),
      ],
    );
  }

  Widget _buildShopItemCard({
    required IconData icon,
    required String title,
    required String desc,
    required String price,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.purpleNeon.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.purpleNeon, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on_rounded,
                    color: AppColors.coinGold, size: 16),
                const SizedBox(width: 4),
                Text(
                  price,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
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
