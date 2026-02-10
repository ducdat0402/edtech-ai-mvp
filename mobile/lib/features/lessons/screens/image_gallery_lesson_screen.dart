import 'package:flutter/material.dart';
import 'package:edtech_mobile/theme/colors.dart';
import 'end_quiz_screen.dart';
import 'fullscreen_image_viewer.dart';

class ImageGalleryLessonScreen extends StatefulWidget {
  final String nodeId;
  final Map<String, dynamic> lessonData;
  final String title;
  final Map<String, dynamic>? endQuiz;
  final String? lessonType;

  const ImageGalleryLessonScreen({
    super.key,
    required this.nodeId,
    required this.lessonData,
    required this.title,
    this.endQuiz,
    this.lessonType,
  });

  @override
  State<ImageGalleryLessonScreen> createState() =>
      _ImageGalleryLessonScreenState();
}

class _ImageGalleryLessonScreenState extends State<ImageGalleryLessonScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  List<Map<String, dynamic>> get _images {
    final raw = widget.lessonData['images'] ?? widget.lessonData['gallery'] ?? [];
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

  void _showFullscreenImage(int tappedIndex) {
    // Collect all image URLs and captions
    final allUrls = <String>[];
    final allCaptions = <String>[];
    for (final img in _images) {
      final url = (img['imageUrl'] ?? img['url'] ?? img['image'] ?? '').toString();
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Counter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.photo_library, color: AppColors.purpleNeon, size: 18),
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
                      color: isActive ? AppColors.purpleNeon : AppColors.bgTertiary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

          // Bottom button
          Padding(
            padding: const EdgeInsets.all(16),
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
                        questions: (widget.endQuiz?['questions'] as List?)?.cast<dynamic>(),
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
                  'Lam bai test',
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
    final imageUrl = imageData['imageUrl'] ?? imageData['url'] ?? imageData['image'] ?? '';
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
                            errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                          )
                        : _buildImagePlaceholder(),
                  ),

                  // Gradient overlay at bottom with description
                  if (description.toString().isNotEmpty || title.toString().isNotEmpty)
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
                              Colors.black.withOpacity(0.8),
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
                                  color: Colors.white.withOpacity(0.9),
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
                  border: Border.all(color: AppColors.borderPrimary),
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
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, color: AppColors.textTertiary, size: 64),
          SizedBox(height: 8),
          Text(
            'Khong co hinh anh',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
