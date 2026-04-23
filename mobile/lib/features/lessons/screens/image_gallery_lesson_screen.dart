import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:edtech_mobile/core/widgets/app_bar_leading_back_home.dart';
import 'package:edtech_mobile/core/widgets/ai_generated_notice.dart';
import 'package:edtech_mobile/core/widgets/contributor_credit_button.dart';
import 'package:edtech_mobile/theme/colors.dart';
import 'end_quiz_screen.dart';
import 'fullscreen_image_viewer.dart';

class ImageGalleryLessonScreen extends StatefulWidget {
  final String nodeId;
  final Map<String, dynamic> lessonData;
  final String title;
  final Map<String, dynamic>? endQuiz;
  final String? lessonType;
  final Map<String, dynamic>? contributor;

  const ImageGalleryLessonScreen({
    super.key,
    required this.nodeId,
    required this.lessonData,
    required this.title,
    this.endQuiz,
    this.lessonType,
    this.contributor,
  });

  @override
  State<ImageGalleryLessonScreen> createState() =>
      _ImageGalleryLessonScreenState();
}

class _ImageGalleryLessonScreenState extends State<ImageGalleryLessonScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  List<Map<String, dynamic>> get _images {
    final raw =
        widget.lessonData['images'] ?? widget.lessonData['gallery'] ?? [];
    return List<Map<String, dynamic>>.from(raw);
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    if (index < 0 || index >= _images.length) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _showFullscreenImage(int tappedIndex) {
    // Collect all image URLs and captions
    final allUrls = <String>[];
    final allCaptions = <String>[];
    for (final img in _images) {
      final url =
          (img['imageUrl'] ?? img['url'] ?? img['image'] ?? '').toString();
      allUrls.add(url);
      allCaptions.add((img['description'] ?? img['caption'] ?? '').toString());
    }
    FullscreenImageViewer.show(
      context: context,
      imageUrls: allUrls,
      initialIndex: tappedIndex.clamp(0, allUrls.length - 1),
      captions: allCaptions,
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalImages = _images.length;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        leading: const AppBarLeadingBackAndHome(),
        leadingWidth: 112,
        automaticallyImplyLeading: false,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          ContributorCreditButton(contributor: widget.contributor),
        ],
      ),
      body: Column(
        children: [
          if (widget.contributor == null)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: AiGeneratedNotice(visible: true, compact: true),
            ),
          // Counter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.photo_library,
                        color: AppColors.purpleNeon, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Hinh ${_currentPage + 1}/$totalImages',
                      style: const TextStyle(
                        color: AppColors.purpleNeon,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (totalImages > 1) ...[
                  const SizedBox(height: 6),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        kIsWeb ? Icons.touch_app : Icons.swipe,
                        color: AppColors.textTertiary,
                        size: 14,
                      ),
                      SizedBox(width: 6),
                      Text(
                        kIsWeb
                            ? 'Dùng nút Trước/Sau để chuyển ảnh'
                            : 'Vuốt trái/phải để xem ảnh tiếp theo',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
                if (kIsWeb && totalImages > 1) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _currentPage > 0
                            ? () => _goToPage(_currentPage - 1)
                            : null,
                        icon: const Icon(Icons.chevron_left, size: 16),
                        label: const Text('Trước'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: Color(0x332D363D)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _currentPage < totalImages - 1
                            ? () => _goToPage(_currentPage + 1)
                            : null,
                        icon: const Icon(Icons.chevron_right, size: 16),
                        label: const Text('Sau'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.purpleNeon,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Image carousel
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: totalImages,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) {
                if (index >= _images.length) return const SizedBox.shrink();
                return _buildImagePage(index, _images[index]);
              },
            ),
          ),

          // Dots indicator
          if (totalImages > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(totalImages, (index) {
                  final isActive = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.purpleNeon
                          : AppColors.bgTertiary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

          LessonContributorCreditStrip(contributor: widget.contributor),

          // Bottom button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EndQuizScreen(
                        nodeId: widget.nodeId,
                        title: widget.title,
                        lessonType: widget.lessonType ?? 'image_gallery',
                        questions: (widget.endQuiz?['questions'] as List?)
                            ?.cast<dynamic>(),
                        contributor: widget.contributor,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purpleNeon,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Làm bài kiểm tra',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePage(int index, Map<String, dynamic> imageData) {
    final imageUrl =
        imageData['imageUrl'] ?? imageData['url'] ?? imageData['image'] ?? '';
    final description = imageData['description'] ?? imageData['caption'] ?? '';
    final title = imageData['title'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Image with gradient overlay
          Expanded(
            child: GestureDetector(
              onTap: () {
                _showFullscreenImage(index);
              },
              child: Stack(
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: imageUrl.toString().isNotEmpty
                        ? Image.network(
                            imageUrl.toString(),
                            height: 350,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildImagePlaceholder(),
                          )
                        : _buildImagePlaceholder(),
                  ),

                  // Gradient overlay at bottom with description
                  if (description.toString().isNotEmpty ||
                      title.toString().isNotEmpty)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (title.toString().isNotEmpty)
                              Text(
                                title.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (title.toString().isNotEmpty &&
                                description.toString().isNotEmpty)
                              const SizedBox(height: 4),
                            if (description.toString().isNotEmpty)
                              Text(
                                description.toString(),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 14,
                                ),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ),

                  // Fullscreen hint icon
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.fullscreen,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Description below image (if long)
          if (description.toString().length > 120)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x332D363D)),
                ),
                child: Text(
                  description.toString(),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 350,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x332D363D)),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, color: AppColors.textTertiary, size: 64),
          SizedBox(height: 8),
          Text(
            'Không có hình ảnh',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
