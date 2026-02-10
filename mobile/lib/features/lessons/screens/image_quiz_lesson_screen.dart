import 'package:flutter/material.dart';
import 'package:edtech_mobile/theme/colors.dart';
import 'end_quiz_screen.dart';
import 'fullscreen_image_viewer.dart';

class ImageQuizLessonScreen extends StatefulWidget {
  final String nodeId;
  final Map<String, dynamic> lessonData;
  final String title;
  final Map<String, dynamic>? endQuiz;
  final String? lessonType;

  const ImageQuizLessonScreen({
    super.key,
    required this.nodeId,
    required this.lessonData,
    required this.title,
    this.endQuiz,
    this.lessonType,
  });

  @override
  State<ImageQuizLessonScreen> createState() => _ImageQuizLessonScreenState();
}

class _ImageQuizLessonScreenState extends State<ImageQuizLessonScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  final Map<int, int?> _selectedAnswers = {};
  final Map<int, bool> _revealedAnswers = {};

  List<Map<String, dynamic>> get _slides {
    final raw = widget.lessonData['slides'] ?? widget.lessonData['questions'] ?? [];
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

  void _selectAnswer(int slideIndex, int optionIndex) {
    if (_revealedAnswers[slideIndex] == true) return;
    setState(() {
      _selectedAnswers[slideIndex] = optionIndex;
      _revealedAnswers[slideIndex] = true;
    });
  }

  int _getCorrectAnswer(Map<String, dynamic> slide) {
    final correct = slide['correctAnswer'] ?? slide['correct'] ?? 0;
    return correct is int ? correct : int.tryParse(correct.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final totalSlides = _slides.length;

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
          // Progress indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Slide ${_currentPage + 1}/$totalSlides',
                      style: const TextStyle(
                        color: AppColors.purpleNeon,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${((_currentPage + 1) / totalSlides * 100).toInt()}%',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: totalSlides > 0 ? (_currentPage + 1) / totalSlides : 0,
                    backgroundColor: AppColors.bgSecondary,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purpleNeon),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),

          // Slides PageView
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: totalSlides,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) {
                if (index >= _slides.length) return const SizedBox.shrink();
                return _buildSlide(index, _slides[index]);
              },
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
                        lessonType: widget.lessonType ?? 'image_quiz',
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

  Widget _buildSlide(int index, Map<String, dynamic> slide) {
    final imageUrl = slide['imageUrl'] ?? slide['image'] ?? '';
    final question = slide['question'] ?? '';
    final options = List<Map<String, dynamic>>.from(slide['options'] ?? []);
    final hint = slide['hint'] ?? '';
    final correctIndex = _getCorrectAnswer(slide);
    final selected = _selectedAnswers[index];
    final revealed = _revealedAnswers[index] == true;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image (tap to view fullscreen with zoom)
          if (imageUrl.toString().isNotEmpty)
            GestureDetector(
              onTap: () {
                // Collect all slide images for gallery swipe
                final allImages = <String>[];
                final allCaptions = <String>[];
                for (final s in _slides) {
                  final url = (s['imageUrl'] ?? s['image'] ?? '').toString();
                  if (url.isNotEmpty) {
                    allImages.add(url);
                    allCaptions.add((s['question'] ?? '').toString());
                  }
                }
                final currentIdx = allImages.indexOf(imageUrl.toString());
                FullscreenImageViewer.show(
                  context: context,
                  imageUrls: allImages,
                  initialIndex: currentIdx >= 0 ? currentIdx : 0,
                  captions: allCaptions,
                );
              },
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      imageUrl.toString(),
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 250,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.bgSecondary,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderPrimary),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported, color: AppColors.textTertiary, size: 48),
                            SizedBox(height: 8),
                            Text('Không thể tải hình ảnh', style: TextStyle(color: AppColors.textTertiary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Zoom hint icon
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.zoom_in,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Question
          Text(
            question.toString(),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Hint section (before answering)
          if (!revealed && hint.toString().isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.purpleNeon.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.purpleNeon.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline, color: AppColors.purpleNeon, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Goi y',
                          style: TextStyle(
                            color: AppColors.purpleNeon,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hint.toString(),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // ABCD Options
          ...List.generate(options.length.clamp(0, 4), (optIdx) {
            final option = options[optIdx];
            final label = String.fromCharCode(65 + optIdx); // A, B, C, D
            final optionText = option['text'] ?? option['content'] ?? '';
            final explanation = option['explanation'] ?? '';
            final isCorrect = optIdx == correctIndex;
            final isSelected = selected == optIdx;

            Color borderColor = AppColors.borderPrimary;
            Color bgColor = AppColors.bgSecondary;
            Color labelColor = AppColors.textSecondary;

            if (revealed) {
              if (isCorrect) {
                borderColor = AppColors.successNeon;
                bgColor = AppColors.successNeon.withOpacity(0.1);
                labelColor = AppColors.successNeon;
              } else if (isSelected && !isCorrect) {
                borderColor = AppColors.errorNeon;
                bgColor = AppColors.errorNeon.withOpacity(0.1);
                labelColor = AppColors.errorNeon;
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  // Option button
                  GestureDetector(
                    onTap: () => _selectAnswer(index, optIdx),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: revealed && isCorrect
                                  ? AppColors.successNeon.withOpacity(0.2)
                                  : revealed && isSelected
                                      ? AppColors.errorNeon.withOpacity(0.2)
                                      : AppColors.bgTertiary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              label,
                              style: TextStyle(
                                color: labelColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              optionText.toString(),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (revealed && isCorrect)
                            const Icon(Icons.check_circle, color: AppColors.successNeon, size: 22),
                          if (revealed && isSelected && !isCorrect)
                            const Icon(Icons.cancel, color: AppColors.errorNeon, size: 22),
                        ],
                      ),
                    ),
                  ),

                  // Explanation (slide-down animation)
                  if (revealed && explanation.toString().isNotEmpty)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.only(top: 4),
                      padding: revealed
                          ? const EdgeInsets.all(10)
                          : EdgeInsets.zero,
                      constraints: BoxConstraints(
                        maxHeight: revealed ? 200 : 0,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgTertiary.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isCorrect ? Icons.info_outline : Icons.info_outline,
                            color: isCorrect
                                ? AppColors.successNeon
                                : AppColors.textTertiary,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              explanation.toString(),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
