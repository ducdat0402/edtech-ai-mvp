import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/theme/theme.dart';

/// Screen for creating a lesson node (metadata only: name, desc, difficulty, order, exp, coin).
/// The lesson content (dạng bài học) is added separately after this is approved.
class CreateLessonScreen extends StatefulWidget {
  final String subjectId;
  final String domainId;
  final String topicId;
  final String? topicName;

  const CreateLessonScreen({
    super.key,
    required this.subjectId,
    required this.domainId,
    required this.topicId,
    this.topicName,
  });

  @override
  State<CreateLessonScreen> createState() => _CreateLessonScreenState();
}

class _CreateLessonScreenState extends State<CreateLessonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _expController = TextEditingController(text: '30');
  final _coinController = TextEditingController(text: '15');
  bool _isSubmitting = false;
  bool _isLoading = true;

  String _difficulty = 'medium';
  String? _afterEntityId;
  List<Map<String, dynamic>> _existingLessons = [];

  @override
  void initState() {
    super.initState();
    _loadExistingLessons();
  }

  Future<void> _loadExistingLessons() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final lessons = await apiService.getNodesByTopic(widget.topicId);
      setState(() {
        _existingLessons = List<Map<String, dynamic>>.from(lessons);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _expController.dispose();
    _coinController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      // Submit as a lesson contribution WITHOUT lessonType/lessonData
      await apiService.createLessonContribution({
        'title': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'subjectId': widget.subjectId,
        'domainId': widget.domainId,
        'topicId': widget.topicId,
        'topicName': widget.topicName ?? '',
        'difficulty': _difficulty,
        if (_afterEntityId != null) 'afterEntityId': _afterEntityId,
        'expReward': int.tryParse(_expController.text) ?? 30,
        'coinReward': int.tryParse(_coinController.text) ?? 15,
      });

      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Lỗi: $e'), backgroundColor: AppColors.errorNeon),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.contributorBgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.orangeNeon.withAlpha(38),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline,
                  color: AppColors.orangeNeon, size: 48),
            ),
            const SizedBox(height: 16),
            Text('Đã gửi yêu cầu!',
                style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(
              'Bài học "${_nameController.text.trim()}" đang chờ Admin duyệt.\n\nSau khi được duyệt, bạn có thể thêm các dạng bài học (hình ảnh, video, văn bản...).',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.pop(true);
            },
            child: const Text('OK',
                style: TextStyle(color: AppColors.contributorBlue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.contributorBgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Tạo Bài Học Mới',
            style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.orangeNeon.withAlpha(25),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.orangeNeon.withAlpha(76)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.article_outlined,
                              color: AppColors.orangeNeon, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tạo bài học cho: ${widget.topicName ?? 'topic'}',
                                  style: AppTextStyles.labelMedium.copyWith(
                                      color: AppColors.orangeNeon,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tạo bài học trước, sau khi được duyệt bạn có thể thêm các dạng nội dung (hình ảnh, video, văn bản...).',
                                  style: AppTextStyles.bodySmall
                                      .copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Name
                    _buildLabel('Tên bài học *'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _nameController,
                      hint: 'VD: Giới thiệu Excel, Hàm VLOOKUP cơ bản...',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Vui lòng nhập tên bài học';
                        if (v.trim().length < 2) return 'Tên quá ngắn';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Description
                    _buildLabel('Mô tả'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _descriptionController,
                      hint: 'Mô tả ngắn gọn nội dung bài học...',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),

                    // Difficulty
                    _buildLabel('Độ khó *'),
                    const SizedBox(height: 8),
                    _buildDifficultySelector(),
                    const SizedBox(height: 20),

                    // Order after
                    _buildLabel('Thứ tự sau bài'),
                    const SizedBox(height: 8),
                    _buildOrderAfterSelector(),
                    const SizedBox(height: 20),

                    // EXP & Coin
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('EXP nhận được'),
                              const SizedBox(height: 8),
                              _buildNumberField(
                                  controller: _expController,
                                  icon: Icons.star,
                                  iconColor: Colors.amber),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Coin nhận được'),
                              const SizedBox(height: 8),
                              _buildNumberField(
                                  controller: _coinController,
                                  icon: Icons.monetization_on,
                                  iconColor: Colors.orangeAccent),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.contributorBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          disabledBackgroundColor:
                              AppColors.contributorBlue.withAlpha(127),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.send, size: 20),
                                  const SizedBox(width: 8),
                                  Text('Gửi yêu cầu duyệt',
                                      style: AppTextStyles.labelLarge.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.textPrimary, fontWeight: FontWeight.w600));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
        filled: true,
        fillColor: AppColors.contributorBgSecondary,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.contributorBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.contributorBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.contributorBlue, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.errorNeon)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDifficultySelector() {
    final options = [
      {
        'value': 'easy',
        'label': 'Dễ',
        'icon': Icons.sentiment_satisfied,
        'color': Colors.green
      },
      {
        'value': 'medium',
        'label': 'Trung bình',
        'icon': Icons.sentiment_neutral,
        'color': Colors.orange
      },
      {
        'value': 'hard',
        'label': 'Khó',
        'icon': Icons.sentiment_very_dissatisfied,
        'color': Colors.red
      },
    ];

    return Row(
      children: options.map((opt) {
        final isSelected = _difficulty == opt['value'];
        final color = opt['color'] as Color;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _difficulty = opt['value'] as String),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withAlpha(30)
                    : AppColors.contributorBgSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : AppColors.contributorBorder,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(opt['icon'] as IconData,
                      color: isSelected ? color : AppColors.textTertiary,
                      size: 24),
                  const SizedBox(height: 4),
                  Text(
                    opt['label'] as String,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isSelected ? color : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOrderAfterSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.contributorBgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.contributorBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _afterEntityId,
          isExpanded: true,
          dropdownColor: AppColors.contributorBgSecondary,
          style:
              AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
          icon:
              const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Row(
                children: [
                  const Icon(Icons.first_page,
                      size: 18, color: AppColors.contributorBlue),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _existingLessons.isEmpty
                          ? 'Đây là bài học đầu tiên'
                          : 'Đặt ở vị trí đầu tiên',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontStyle: _existingLessons.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            ..._existingLessons.asMap().entries.map((entry) {
              final item = entry.value;
              final idx = entry.key;
              return DropdownMenuItem<String?>(
                value: item['id'] as String?,
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.contributorBlue.withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${idx + 1}',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.contributorBlue,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Sau: ${item['title'] ?? ''}',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          onChanged: (id) => setState(() => _afterEntityId = id),
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required IconData icon,
    required Color iconColor,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: iconColor, size: 20),
        filled: true,
        fillColor: AppColors.contributorBgSecondary,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.contributorBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.contributorBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.contributorBlue, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
