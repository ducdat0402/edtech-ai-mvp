import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/theme/colors.dart';
import 'package:edtech_mobile/theme/text_styles.dart';
import 'package:edtech_mobile/theme/widgets/gaming_button.dart';
import 'package:edtech_mobile/theme/widgets/glass_card.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _packages = [];
  Map<String, dynamic>? _bankInfo;
  Map<String, dynamic>? _premiumStatus;
  Map<String, dynamic>? _currentPayment;
  String? _qrUrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      // Load packages and premium status in parallel
      final results = await Future.wait([
        apiService.getPaymentPackages(),
        apiService.getPremiumStatus(),
      ]);

      setState(() {
        final packagesData = results[0];
        _packages = List<Map<String, dynamic>>.from(packagesData['packages'] ?? []);
        _bankInfo = packagesData['bankInfo'];
        _premiumStatus = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createPayment(String packageId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.createPayment(packageId);

      setState(() {
        _currentPayment = result['payment'] as Map<String, dynamic>?;
        _qrUrl = result['qrUrl'] as String?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.errorNeon,
          ),
        );
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $label'),
        backgroundColor: AppColors.successNeon,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: Text('Thanh toán Premium', style: AppTextStyles.h3),
        backgroundColor: AppColors.bgPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.purpleNeon))
          : _error != null
              ? _buildError()
              : _currentPayment != null
                  ? _buildPaymentDetails()
                  : _buildPackageSelection(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.errorNeon),
            const SizedBox(height: 16),
            Text('Có lỗi xảy ra', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(_error!, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            GamingButton(
              text: 'Thử lại',
              onPressed: _loadData,
              icon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageSelection() {
    final isPremium = _premiumStatus?['isPremium'] == true;
    final daysRemaining = _premiumStatus?['daysRemaining'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium status card
          if (isPremium)
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.coinGold, AppColors.orangeNeon],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Premium đang hoạt động', style: AppTextStyles.labelLarge.copyWith(color: AppColors.coinGold)),
                          const SizedBox(height: 4),
                          Text('Còn $daysRemaining ngày', style: AppTextStyles.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          if (isPremium) const SizedBox(height: 24),

          Text(
            isPremium ? 'Gia hạn Premium' : 'Chọn gói Premium',
            style: AppTextStyles.h2,
          ),
          const SizedBox(height: 8),
          Text(
            'Mở khóa tất cả tính năng, học không giới hạn',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 24),

          // Package cards
          ..._packages.map((pkg) => _buildPackageCard(pkg)),

          const SizedBox(height: 24),

          // Features list
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tính năng Premium', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 12),
                  _buildFeatureItem(Icons.quiz, 'Không giới hạn quiz và bài học'),
                  _buildFeatureItem(Icons.block, 'Không quảng cáo'),
                  _buildFeatureItem(Icons.support_agent, 'Hỗ trợ ưu tiên'),
                  _buildFeatureItem(Icons.stars, 'Badge độc quyền'),
                  _buildFeatureItem(Icons.new_releases, 'Truy cập tính năng mới sớm'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(Map<String, dynamic> pkg) {
    final id = pkg['id'] as String;
    final name = pkg['name'] as String;
    final price = (pkg['price'] as num).toInt();
    final description = pkg['description'] as String? ?? '';
    final isPopular = id == 'premium_3months';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        borderColor: isPopular ? AppColors.purpleNeon : null,
        child: InkWell(
          onTap: () => _createPayment(id),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(name, style: AppTextStyles.labelLarge),
                          if (isPopular) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.purpleNeon, AppColors.pinkNeon],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('HOT', style: AppTextStyles.caption.copyWith(color: Colors.white)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(description, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_formatCurrency(price)}đ',
                      style: AppTextStyles.numberLarge.copyWith(color: AppColors.coinGold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.successNeon),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildPaymentDetails() {
    final payment = _currentPayment!;
    final paymentCode = payment['paymentCode'] as String;
    final amount = (payment['amount'] as num).toInt();
    final packageName = payment['packageName'] as String;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // QR Code
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('Quét mã QR để thanh toán', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _qrUrl != null
                        ? Image.network(
                            _qrUrl!,
                            width: 250,
                            height: 250,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const SizedBox(
                                width: 250,
                                height: 250,
                                child: Center(child: CircularProgressIndicator()),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const SizedBox(
                                width: 250,
                                height: 250,
                                child: Center(
                                  child: Icon(Icons.error, size: 48, color: Colors.red),
                                ),
                              );
                            },
                          )
                        : const SizedBox(
                            width: 250,
                            height: 250,
                            child: Center(child: Text('Không thể tải QR')),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hoặc chuyển khoản thủ công',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Bank info
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Thông tin chuyển khoản', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 16),
                  
                  _buildInfoRow(
                    'Ngân hàng',
                    _bankInfo?['bankName'] ?? 'MB Bank',
                    copyable: false,
                  ),
                  _buildInfoRow(
                    'Số tài khoản',
                    _bankInfo?['accountNumber'] ?? '',
                    copyable: true,
                  ),
                  _buildInfoRow(
                    'Chủ tài khoản',
                    _bankInfo?['accountName'] ?? '',
                    copyable: false,
                  ),
                  _buildInfoRow(
                    'Số tiền',
                    '${_formatCurrency(amount)} VNĐ',
                    copyable: true,
                    copyValue: amount.toString(),
                    highlight: true,
                  ),
                  _buildInfoRow(
                    'Nội dung CK',
                    paymentCode,
                    copyable: true,
                    highlight: true,
                    important: true,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Warning
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warningNeon.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warningNeon.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: AppColors.warningNeon),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Vui lòng nhập đúng nội dung chuyển khoản "$paymentCode" để hệ thống tự động xác nhận.',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.warningNeon),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Package info
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.shopping_bag, color: AppColors.purpleNeon),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gói đã chọn', style: AppTextStyles.caption),
                        Text(packageName, style: AppTextStyles.labelLarge),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _currentPayment = null;
                      _qrUrl = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.borderPrimary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('Chọn gói khác', style: AppTextStyles.labelMedium),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GamingButton(
                  text: 'Kiểm tra trạng thái',
                  onPressed: () async {
                    // Refresh premium status (auto-activated by webhook)
                    try {
                      final apiService = Provider.of<ApiService>(context, listen: false);
                      final status = await apiService.getPremiumStatus();
                      
                      final isPremium = status['isPremium'] as bool? ?? false;
                      
                      if (isPremium) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Premium đã được kích hoạt! 🎉'),
                              backgroundColor: AppColors.successNeon,
                            ),
                          );
                          Navigator.pop(context, true);
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Chưa nhận được thanh toán. Vui lòng đợi 1-2 phút sau khi chuyển khoản.'),
                              backgroundColor: AppColors.warningNeon,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Lỗi: $e'),
                            backgroundColor: AppColors.errorNeon,
                          ),
                        );
                      }
                    }
                  },
                  icon: Icons.refresh,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            'Sau khi chuyển khoản, hệ thống sẽ tự động kích hoạt trong 1-2 phút',
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool copyable = false,
    String? copyValue,
    bool highlight = false,
    bool important = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: AppTextStyles.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              style: highlight
                  ? AppTextStyles.labelLarge.copyWith(
                      color: important ? AppColors.cyanNeon : AppColors.textPrimary,
                    )
                  : AppTextStyles.bodyMedium,
            ),
          ),
          if (copyable)
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              color: AppColors.textTertiary,
              onPressed: () => _copyToClipboard(copyValue ?? value, label),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
