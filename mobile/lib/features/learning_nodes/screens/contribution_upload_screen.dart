import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:edtech_mobile/core/services/api_service.dart';
import 'package:edtech_mobile/theme/theme.dart';

class ContributionUploadScreen extends StatefulWidget {
  final String contentId;
  final String format; // 'video' or 'image'
  final String? title;
  final Map<String, dynamic>? contributionGuide;
  final String? nodeId; // Node ID for new contributions
  final bool isNewContribution; // true if creating new content

  const ContributionUploadScreen({
    super.key,
    required this.contentId,
    required this.format,
    this.title,
    this.contributionGuide,
    this.nodeId,
    this.isNewContribution = false,
  });

  @override
  State<ContributionUploadScreen> createState() =>
      _ContributionUploadScreenState();
}

class _ContributionUploadScreenState extends State<ContributionUploadScreen> {
  File? _selectedFile;
  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _error;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _captionController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  bool get _isVideo => widget.format == 'video';
  
  Color get _accentColor => _isVideo ? AppColors.purpleNeon : AppColors.cyanNeon;

  @override
  void dispose() {
    _descriptionController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isVideo ? 'Đóng góp Video' : 'Đóng góp Hình ảnh',
          style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderPrimary),
            ),
            child: const Icon(Icons.close, color: AppColors.textPrimary, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderInfo(),
            const SizedBox(height: 24),
            if (widget.contributionGuide != null) ...[
              _buildContributionGuide(),
              const SizedBox(height: 24),
            ],
            _buildFilePicker(),
            const SizedBox(height: 24),
            if (_selectedFile != null) ...[
              _buildPreview(),
              const SizedBox(height: 24),
            ],
            _buildDescriptionFields(),
            const SizedBox(height: 24),
            if (_error != null) ...[
              _buildErrorMessage(),
              const SizedBox(height: 24),
            ],
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _isVideo ? Icons.videocam_rounded : Icons.image_rounded,
              color: _accentColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title ?? (_isVideo ? 'Video cần đóng góp' : 'Hình ảnh cần đóng góp'),
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppGradients.xpBar,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Phần thưởng: +50 XP, +30 Coin',
                    style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContributionGuide() {
    final guide = widget.contributionGuide!;
    final suggestedContent = guide['suggestedContent'] as String?;
    final rawRequirements = guide['requirements'];
    final requirements = rawRequirements is List 
        ? rawRequirements 
        : rawRequirements is String 
            ? [rawRequirements] 
            : null;
    final difficulty = guide['difficulty'] as String?;
    final estimatedTime = guide['estimatedTime'] as String?;

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.xpGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.lightbulb_rounded, color: AppColors.xpGold, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Hướng dẫn đóng góp', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          if (suggestedContent != null) ...[
            Text(suggestedContent, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 16),
          ],
          if (requirements != null && requirements.isNotEmpty) ...[
            Text('Yêu cầu:', style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            ...requirements.map((req) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.successNeon, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(req.toString(), style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary))),
                ],
              ),
            )),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              if (difficulty != null)
                Expanded(child: _buildInfoChip(Icons.signal_cellular_alt_rounded, _getDifficultyText(difficulty), AppColors.cyanNeon)),
              if (difficulty != null && estimatedTime != null) const SizedBox(width: 12),
              if (estimatedTime != null)
                Expanded(child: _buildInfoChip(Icons.schedule_rounded, estimatedTime, AppColors.successNeon)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Flexible(child: Text(text, style: AppTextStyles.labelSmall.copyWith(color: color))),
        ],
      ),
    );
  }

  Widget _buildFilePicker() {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _accentColor.withOpacity(0.3), width: 2),
        ),
        child: _selectedFile == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _accentColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isVideo ? Icons.video_library_rounded : Icons.add_photo_alternate_rounded,
                      color: _accentColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isVideo ? 'Chọn video từ thư viện' : 'Chọn hình ảnh từ thư viện',
                    style: AppTextStyles.labelLarge.copyWith(color: _accentColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isVideo ? 'Hỗ trợ: MP4, MOV, AVI (tối đa 100MB)' : 'Hỗ trợ: JPG, PNG, GIF (tối đa 10MB)',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              )
            : Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgTertiary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Icon(_isVideo ? Icons.movie_rounded : Icons.image_rounded, size: 64, color: AppColors.textTertiary),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFile = null),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: AppColors.errorNeon, shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPreview() {
    final fileName = _selectedFile!.path.split('/').last;
    final fileSize = _selectedFile!.lengthSync();
    final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.successNeon.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.successNeon.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.successNeon.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_isVideo ? Icons.video_file_rounded : Icons.image_rounded, color: AppColors.successNeon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fileName, style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('$fileSizeMB MB', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, color: AppColors.successNeon),
        ],
      ),
    );
  }

  Widget _buildDescriptionFields() {
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
          Row(
            children: [
              Icon(Icons.edit_note_rounded, color: _accentColor, size: 24),
              const SizedBox(width: 8),
              Text('Thông tin đóng góp', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(_descriptionController, 'Mô tả', 'Mô tả ngắn về nội dung đóng góp của bạn...', 3),
          const SizedBox(height: 12),
          _buildTextField(_captionController, 'Chú thích', _isVideo ? 'VD: Video hướng dẫn chi tiết...' : 'VD: Hình ảnh minh họa khái niệm...', 2),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cyanNeon.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cyanNeon.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.cyanNeon, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Đóng góp sẽ được lưu lịch sử và có thể so sánh phiên bản khi admin duyệt.', style: AppTextStyles.caption.copyWith(color: AppColors.cyanNeon))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, int maxLines) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
        hintText: hint,
        hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderPrimary)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderPrimary)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _accentColor, width: 2)),
        filled: true,
        fillColor: AppColors.bgTertiary,
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorNeon.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.errorNeon.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_rounded, color: AppColors.errorNeon),
          const SizedBox(width: 8),
          Expanded(child: Text(_error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.errorNeon))),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: GamingButton(
        text: _isUploading 
            ? (_uploadProgress > 0 ? 'Đang tải lên... ${(_uploadProgress * 100).toInt()}%' : 'Đang xử lý...')
            : (_isVideo ? 'Gửi Video' : 'Gửi Hình ảnh'),
        onPressed: _selectedFile != null && !_isUploading ? _submitContribution : null,
        isLoading: _isUploading,
        gradient: _isVideo ? AppGradients.primary : LinearGradient(colors: [AppColors.cyanNeon, AppColors.successNeon]),
        glowColor: _accentColor,
        icon: Icons.cloud_upload_rounded,
      ),
    );
  }

  String _getDifficultyText(String difficulty) {
    switch (difficulty) {
      case 'easy': return 'Dễ';
      case 'medium': return 'Trung bình';
      case 'hard': return 'Khó';
      default: return difficulty;
    }
  }

  Future<void> _pickFile() async {
    try {
      if (_isVideo) {
        final XFile? video = await _picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 10));
        if (video != null) {
          setState(() { _selectedFile = File(video.path); _error = null; });
        }
      } else {
        final XFile? image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1920, maxHeight: 1080, imageQuality: 85);
        if (image != null) {
          setState(() { _selectedFile = File(image.path); _error = null; });
        }
      }
    } catch (e) {
      setState(() { _error = 'Không thể chọn file: $e'; });
    }
  }

  Future<void> _submitContribution() async {
    if (_selectedFile == null) return;

    setState(() { _isUploading = true; _uploadProgress = 0; _error = null; });

    try {
      final apiService = context.read<ApiService>();
      final description = _descriptionController.text.trim();
      final caption = _captionController.text.trim();

      setState(() => _uploadProgress = 0.3);

      // Upload file using new uploads endpoint
      if (_isVideo) {
        await apiService.uploadVideo(_selectedFile!.path);
      } else {
        await apiService.uploadImage(_selectedFile!.path);
      }

      setState(() => _uploadProgress = 1.0);

      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.bgSecondary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(color: AppColors.successNeon.withOpacity(0.15), shape: BoxShape.circle),
                  child: Icon(Icons.check_circle_rounded, color: AppColors.successNeon, size: 48),
                ),
                const SizedBox(height: 16),
                Text('Gửi thành công!', style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Text('Đóng góp của bạn đang được xem xét.\nBạn sẽ nhận phần thưởng khi được duyệt.', textAlign: TextAlign.center, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: GamingButton(
                    text: 'Hoàn tất',
                    onPressed: () { Navigator.pop(context); Navigator.pop(context, true); },
                    gradient: AppGradients.success,
                    glowColor: AppColors.successNeon,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      setState(() { _error = 'Không thể gửi đóng góp: $e'; _isUploading = false; _uploadProgress = 0; });
    }
  }
}
