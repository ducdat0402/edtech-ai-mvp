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
  Map<String, dynamic>? _diamondBalance;
  Map<String, dynamic>? _currentPayment;
  Map<String, dynamic>? _selectedPackage;
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

      final results = await Future.wait([
        apiService.getPaymentPackages(),
        apiService.getDiamondBalance(),
      ]);

      setState(() {
        final packagesData = results[0];
        _packages =
            List<Map<String, dynamic>>.from(packagesData['packages'] ?? []);
        _bankInfo = packagesData['bankInfo'];
        _diamondBalance = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createPayment(Map<String, dynamic> pkg) async {
    setState(() => _isLoading = true);

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.createPayment(pkg['id'] as String);

      setState(() {
        _currentPayment = result['payment'] as Map<String, dynamic>?;
        _selectedPackage = pkg;
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
        title: const Text('Mua Kim Cương', style: AppTextStyles.h3),
        backgroundColor: AppColors.bgPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.purpleNeon))
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
            const Icon(Icons.error_outline,
                size: 64, color: AppColors.errorNeon),
            const SizedBox(height: 16),
            const Text('Có lỗi xảy ra', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(_error!,
                style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
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
    final diamonds = _diamondBalance?['diamonds'] as int? ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current diamond balance
          _buildDiamondBalanceCard(diamonds),
          const SizedBox(height: 24),

          // Section title
          const Text(
            'Chọn gói kim cương',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mua kim cương để mở khóa nội dung và tính năng',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 20),

          // Package cards
          ...List.generate(
              _packages.length, (i) => _buildPackageCard(_packages[i], i)),

          const SizedBox(height: 24),

          // Info section
          _buildInfoSection(),
        ],
      ),
    );
  }

  Widget _buildDiamondBalanceCard(int diamonds) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cyanNeon.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyanNeon.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Diamond icon
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00BCD4), Color(0xFF00838F)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.cyanNeon.withOpacity(0.3),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(Icons.diamond, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          // Balance info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Số dư kim cương',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatNumber(diamonds),
                  style: const TextStyle(
                    color: AppColors.cyanNeon,
                    fontSize: 32,
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

  Widget _buildPackageCard(Map<String, dynamic> pkg, int index) {
    final name = pkg['name'] as String? ?? '';
    final price = (pkg['price'] as num?)?.toInt() ?? 0;
    final totalDiamonds = (pkg['totalDiamonds'] as num?)?.toInt() ?? 0;
    final diamonds = (pkg['diamonds'] as num?)?.toInt() ?? 0;
    final bonusDiamonds = (pkg['bonusDiamonds'] as num?)?.toInt() ?? 0;
    final bonusPercent = (pkg['bonusPercent'] as num?)?.toInt() ?? 0;
    final pricePerDiamond = (pkg['pricePerDiamond'] as num?)?.toInt() ?? 0;
    final discount = pkg['discount'] as String? ?? '';
    final badge = pkg['badge'] as String? ?? '';
    final isPopular = pkg['isPopular'] == true;

    // Colors based on package tier
    final tierColors = [
      [AppColors.textSecondary, AppColors.bgTertiary], // Starter
      [AppColors.purpleNeon, AppColors.purpleNeon.withOpacity(0.08)], // Popular
      [AppColors.orangeNeon, AppColors.orangeNeon.withOpacity(0.08)], // Pro
      [AppColors.cyanNeon, AppColors.cyanNeon.withOpacity(0.08)], // Premium
    ];
    final accentColor = tierColors[index][0];
    final bgColor = tierColors[index][1];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _createPayment(pkg),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isPopular ? accentColor : AppColors.borderPrimary,
                width: isPopular ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Diamond icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.diamond, color: accentColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    // Package info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (badge.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    badge,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Diamond amount
                          Row(
                            children: [
                              Text(
                                '$totalDiamonds',
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(' kim cương',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13)),
                              if (bonusDiamonds > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.successNeon.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '+$bonusPercent% Bonus',
                                    style: const TextStyle(
                                        color: AppColors.successNeon,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (bonusDiamonds > 0)
                            Text(
                              '($diamonds + $bonusDiamonds bonus)',
                              style: const TextStyle(
                                  color: AppColors.textTertiary, fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                    // Price column
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_formatCurrency(price)}đ',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_formatCurrency(pricePerDiamond)}đ/',
                              style: const TextStyle(
                                  color: AppColors.textTertiary, fontSize: 11),
                            ),
                            const Icon(Icons.diamond,
                                size: 10, color: AppColors.textTertiary),
                            if (discount.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Text(
                                discount,
                                style: const TextStyle(
                                    color: AppColors.successNeon,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ],
                        ),
                      ],
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

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.cyanNeon, size: 18),
              SizedBox(width: 8),
              Text(
                'Kim cương dùng để làm gì?',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
              Icons.lock_open, 'Mở khóa bài học và nội dung cao cấp'),
          _buildInfoItem(Icons.auto_awesome, 'Sử dụng tính năng AI nâng cao'),
          _buildInfoItem(Icons.stars, 'Mua vật phẩm đặc biệt và badge'),
          _buildInfoItem(Icons.speed, 'Tăng tốc tiến trình học tập'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.successNeon),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ==================== Payment Details ====================

  Widget _buildPaymentDetails() {
    final payment = _currentPayment!;
    final paymentCode = payment['paymentCode'] as String;
    final amount = (payment['amount'] as num).toInt();
    final diamondAmount = (payment['diamondAmount'] as num?)?.toInt() ?? 0;
    final packageName = _selectedPackage?['name'] as String? ??
        payment['packageName'] as String? ??
        '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Package summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cyanNeon.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.diamond, color: AppColors.cyanNeon, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gói $packageName',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(
                        '$diamondAmount kim cương',
                        style: const TextStyle(
                            color: AppColors.cyanNeon,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_formatCurrency(amount)}đ',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // QR Code
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Quét mã QR để thanh toán',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
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
                                child:
                                    Center(child: CircularProgressIndicator()),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const SizedBox(
                                width: 250,
                                height: 250,
                                child: Center(
                                    child: Icon(Icons.error,
                                        size: 48, color: Colors.red)),
                              );
                            },
                          )
                        : const SizedBox(
                            width: 250,
                            height: 250,
                            child: Center(child: Text('Không thể tải QR')),
                          ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Hoặc chuyển khoản thủ công',
                      style: TextStyle(
                          color: AppColors.textTertiary, fontSize: 13)),
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
                  const Text('Thông tin chuyển khoản',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                      'Ngân hàng', _bankInfo?['bankName'] ?? 'MB Bank',
                      copyable: false),
                  _buildInfoRow(
                      'Số tài khoản', _bankInfo?['accountNumber'] ?? '',
                      copyable: true),
                  _buildInfoRow(
                      'Chủ tài khoản', _bankInfo?['accountName'] ?? '',
                      copyable: false),
                  _buildInfoRow('Số tiền', '${_formatCurrency(amount)} VNĐ',
                      copyable: true,
                      copyValue: amount.toString(),
                      highlight: true),
                  _buildInfoRow('Nội dung CK', paymentCode,
                      copyable: true, highlight: true, important: true),
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
                    style: const TextStyle(
                        color: AppColors.warningNeon, fontSize: 13),
                  ),
                ),
              ],
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
                      _selectedPackage = null;
                      _qrUrl = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.borderPrimary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Chọn gói khác',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GamingButton(
                  text: 'Kiểm tra',
                  onPressed: () async {
                    try {
                      final apiService =
                          Provider.of<ApiService>(context, listen: false);
                      final balance = await apiService.getDiamondBalance();
                      final newDiamonds = balance['diamonds'] as int? ?? 0;
                      final oldDiamonds =
                          _diamondBalance?['diamonds'] as int? ?? 0;

                      if (newDiamonds > oldDiamonds) {
                        if (mounted) {
                          setState(() => _diamondBalance = balance);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Đã nhận ${newDiamonds - oldDiamonds} kim cương!'),
                              backgroundColor: AppColors.successNeon,
                            ),
                          );
                          // Go back to package selection to show updated balance
                          setState(() {
                            _currentPayment = null;
                            _selectedPackage = null;
                            _qrUrl = null;
                          });
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Chưa nhận được thanh toán. Vui lòng đợi 1-2 phút sau khi chuyển khoản.'),
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
                              backgroundColor: AppColors.errorNeon),
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
          const Text(
            'Sau khi chuyển khoản, hệ thống sẽ tự động cộng kim cương trong 1-2 phút',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
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
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: important
                    ? AppColors.cyanNeon
                    : highlight
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                fontSize: highlight ? 16 : 14,
                fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              ),
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

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
