import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/constants/currency_labels.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/core/widgets/app_bar_leading_back_home.dart';
import 'package:edtech_mobile/features/shop/widgets/shop_avatar_frames_tab.dart';
import 'package:edtech_mobile/theme/theme.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _coins = 0;
  List<dynamic> _shopItems = [];
  List<dynamic> _inventory = [];
  Map<String, dynamic> _activeEffects = {};
  List<Map<String, dynamic>> _avatarFrames = [];
  String? _equippedAvatarFrameId;
  int _frameUserLevel = 1;
  int _diamondsBalance = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final results = await Future.wait([
        apiService.getShopItems(),
        apiService.getShopInventory(),
        apiService.getAvatarFramesCatalog(),
      ]);

      final shopData = results[0];
      final inventoryData = results[1];
      final afData = Map<String, dynamic>.from(results[2] as Map);

      if (mounted) {
        setState(() {
          _coins = shopData['coins'] as int? ?? 0;
          _shopItems = shopData['items'] as List<dynamic>? ?? [];
          _inventory = inventoryData['inventory'] as List<dynamic>? ?? [];
          _activeEffects =
              inventoryData['activeEffects'] as Map<String, dynamic>? ?? {};
          _diamondsBalance = afData['diamonds'] as int? ?? 0;
          _frameUserLevel = afData['level'] as int? ?? 1;
          _equippedAvatarFrameId = afData['equippedId'] as String?;
          _avatarFrames = (afData['frames'] as List<dynamic>? ?? const [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
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

  Future<void> _purchaseItem(Map<String, dynamic> item) async {
    final itemId = item['id'] as String;
    final itemName = item['name'] as String;
    final price = item['price'] as int;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Xác nhận mua',
            style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(_getItemIcon(item['icon'] as String? ?? ''),
                      color: AppColors.purpleNeon, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(itemName,
                            style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold)),
                        Text(item['description'] as String? ?? '',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const GtuCoinIcon(size: 22),
                const SizedBox(width: 6),
                Text('$price',
                    style:
                        AppTextStyles.h3.copyWith(color: AppColors.coinGold)),
                const SizedBox(width: 16),
                Text('Số dư: $_coins',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: _coins >= price ? () => Navigator.pop(ctx, true) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _coins >= price ? AppColors.coinGold : AppColors.bgTertiary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
                _coins >= price ? 'Mua ngay' : 'Không đủ ${CurrencyLabels.gtuCoin}'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      HapticFeedback.mediumImpact();
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.purchaseShopItem(itemId);
      final newBalance = result['newBalance'] as int? ?? _coins;

      if (mounted) {
        setState(() => _coins = newBalance);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã mua $itemName thành công! 🎉'),
            backgroundColor: AppColors.successNeon,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${_extractError(e)}'),
            backgroundColor: AppColors.errorNeon,
          ),
        );
      }
    }
  }

  Future<void> _useItem(Map<String, dynamic> inventoryEntry) async {
    final item = inventoryEntry['item'] as Map<String, dynamic>? ?? {};
    final itemId = item['id'] as String;
    final itemName = item['name'] as String;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sử dụng $itemName?',
            style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary)),
        content: Text(item['description'] as String? ?? '',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Sử dụng'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      HapticFeedback.mediumImpact();
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.useShopItem(itemId);

      if (mounted) {
        _showRewardDialog(result, itemName);
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi: ${_extractError(e)}'),
              backgroundColor: AppColors.errorNeon),
        );
      }
    }
  }

  void _showRewardDialog(Map<String, dynamic> result, String itemName) {
    final message = result['message'] as String? ?? '';
    final reward = result['reward'] as Map<String, dynamic>?;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.successNeon, size: 28),
            const SizedBox(width: 8),
            Expanded(
                child: Text(itemName,
                    style: AppTextStyles.h4
                        .copyWith(color: AppColors.textPrimary))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 15)),
            if (reward != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.coinGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.coinGold.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if ((reward['xp'] as int? ?? 0) > 0) ...[
                      const Icon(Icons.star_rounded,
                          color: AppColors.xpGold, size: 20),
                      const SizedBox(width: 4),
                      Text('+${reward['xp']} XP',
                          style: const TextStyle(
                              color: AppColors.xpGold,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                    ],
                    if ((reward['coins'] as int? ?? 0) > 0) ...[
                      const GtuCoinIcon(size: 20),
                      const SizedBox(width: 4),
                      Text(
                          CurrencyLabels.rewardShort(
                              reward['coins'] as int? ?? 0),
                          style: const TextStyle(
                              color: AppColors.coinGold,
                              fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _purchaseAvatarFrame(
    Map<String, dynamic> frame, {
    String? currency,
  }) async {
    final api = Provider.of<ApiService>(context, listen: false);
    final id = frame['id'] as String? ?? '';
    if (id.isEmpty) return;
    await api.purchaseAvatarFrame(id, currency: currency);
    if (!mounted) return;
    await _loadData();
  }

  Future<void> _equipAvatarFrame(String? frameId) async {
    final api = Provider.of<ApiService>(context, listen: false);
    await api.equipAvatarFrame(frameId);
    if (!mounted) return;
    await _loadData();
  }

  String _extractError(dynamic e) {
    final str = e.toString();
    final match = RegExp(r'"message":"([^"]+)"').firstMatch(str);
    if (match != null) return match.group(1)!;
    if (str.contains('Không đủ')) {
      return str.split('Không đủ').last.split('"').first;
    }
    return 'Có lỗi xảy ra';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Cửa hàng',
            style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary)),
        leading: const AppBarLeadingBackAndHome(),
        leadingWidth: 112,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Mua kim cương',
            icon: const Icon(Icons.diamond_rounded,
                color: AppColors.primaryLight, size: 26),
            onPressed: () => context.push('/payment'),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.coinGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.coinGold.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const GtuCoinIcon(size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '$_coins',
                      style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.coinGold,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.primaryLight.withValues(alpha: 0.28)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.diamond_rounded,
                        color: AppColors.primaryLight, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '$_diamondsBalance',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryLight,
          labelColor: AppColors.primaryLight,
          unselectedLabelColor: AppColors.textTertiary,
          tabs: const [
            Tab(
                text: 'Cửa hàng',
                icon: Icon(Icons.storefront_rounded, size: 20)),
            Tab(
                text: 'Khung avatar',
                icon: Icon(Icons.shutter_speed_rounded, size: 20)),
            Tab(
                text: 'Kho đồ',
                icon: Icon(Icons.inventory_2_rounded, size: 20)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryLight))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Lỗi tải dữ liệu',
                          style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.purpleNeon,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildShopTab(),
                    ShopAvatarFramesTab(
                      frames: _avatarFrames,
                      coins: _coins,
                      diamonds: _diamondsBalance,
                      userLevel: _frameUserLevel,
                      equippedId: _equippedAvatarFrameId,
                      onRefresh: _loadData,
                      onPurchase: _purchaseAvatarFrame,
                      onEquip: _equipAvatarFrame,
                    ),
                    _buildInventoryTab(),
                  ],
                ),
    );
  }

  Widget _buildShopTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCoinInfoBanner(),
          const SizedBox(height: 20),
          Text('Vật phẩm',
              style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          ..._shopItems
              .map((item) => _buildShopItemCard(item as Map<String, dynamic>)),
        ],
      ),
    );
  }

  Widget _buildCoinInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.coinGold.withValues(alpha: 0.12),
            AppColors.orangeNeon.withValues(alpha: 0.06)
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.coinGold.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppColors.coinGold, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${CurrencyLabels.gtuShort} kiếm được qua học tập. Hoàn thành bài học, nhiệm vụ và thành tựu để nhận thêm!',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => context.push('/payment'),
            icon: const Icon(Icons.diamond_rounded, size: 20),
            label: const Text('Mua kim cương'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.22),
              foregroundColor: AppColors.primaryLight,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: AppColors.primaryLight.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopItemCard(Map<String, dynamic> item) {
    final name = item['name'] as String? ?? '';
    final desc = item['description'] as String? ?? '';
    final price = item['price'] as int? ?? 0;
    final canAfford = (item['canAfford'] as bool?) ?? (_coins >= price);
    final iconName = item['icon'] as String? ?? '';
    final category = item['category'] as String? ?? '';

    final categoryColor = _getCategoryColor(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x332D363D)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: canAfford ? () => _purchaseItem(item) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_getItemIcon(iconName),
                      color: categoryColor, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(desc,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: canAfford ? () => _purchaseItem(item) : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color:
                          canAfford ? AppColors.coinGold : AppColors.bgTertiary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Opacity(
                          opacity: canAfford ? 1 : 0.45,
                          child: const GtuCoinIcon(size: 16),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$price',
                          style: TextStyle(
                            color: canAfford
                                ? Colors.black87
                                : AppColors.textTertiary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _inventory.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 100),
                Center(
                  child: Column(
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 64, color: AppColors.textTertiary),
                      const SizedBox(height: 16),
                      Text('Kho đồ trống',
                          style: AppTextStyles.h4
                              .copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Text('Mua vật phẩm từ cửa hàng để thấy ở đây',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textTertiary)),
                    ],
                  ),
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_activeEffects['xpBoost'] == true)
                  _buildActiveEffectBanner('Boost XP x2 đang hoạt động!',
                      Icons.auto_awesome_rounded, AppColors.orangeNeon),
                const SizedBox(height: 8),
                ..._inventory.map((entry) =>
                    _buildInventoryItemCard(entry as Map<String, dynamic>)),
              ],
            ),
    );
  }

  Widget _buildActiveEffectBanner(String text, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildInventoryItemCard(Map<String, dynamic> entry) {
    final item = entry['item'] as Map<String, dynamic>? ?? {};
    final quantity = entry['quantity'] as int? ?? 0;
    final isActive = entry['isActive'] as bool? ?? false;
    final name = item['name'] as String? ?? '';
    final desc = item['description'] as String? ?? '';
    final iconName = item['icon'] as String? ?? '';
    final category = item['category'] as String? ?? '';
    final categoryColor = _getCategoryColor(category);

    if (quantity <= 0 && !isActive) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isActive
                ? categoryColor.withValues(alpha: 0.5)
                : const Color(0x332D363D)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  Icon(_getItemIcon(iconName), color: categoryColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(name,
                          style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600)),
                      if (isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: categoryColor,
                              borderRadius: BorderRadius.circular(10)),
                          child: const Text('Active',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(desc,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                Text('x$quantity',
                    style: AppTextStyles.numberMedium
                        .copyWith(color: AppColors.textPrimary)),
                if (quantity > 0)
                  GestureDetector(
                    onTap: () => _useItem(entry),
                    child: Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Dùng',
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getItemIcon(String iconName) {
    switch (iconName) {
      case 'auto_awesome':
        return Icons.auto_awesome_rounded;
      case 'shield':
        return Icons.shield_rounded;
      case 'tips_and_updates':
        return Icons.tips_and_updates_rounded;
      case 'card_giftcard':
        return Icons.card_giftcard_rounded;
      case 'palette':
        return Icons.palette_rounded;
      default:
        return Icons.shopping_bag_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'boost':
        return AppColors.orangeNeon;
      case 'protection':
        return AppColors.primaryLight;
      case 'consumable':
        return AppColors.purpleNeon;
      case 'mystery':
        return AppColors.pinkNeon;
      case 'cosmetic':
        return AppColors.coinGold;
      default:
        return AppColors.textSecondary;
    }
  }
}
