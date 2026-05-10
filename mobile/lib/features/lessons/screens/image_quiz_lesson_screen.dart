import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:edtech_mobile/core/widgets/app_bar_leading_back_home.dart';
import 'package:edtech_mobile/core/widgets/ai_generated_notice.dart';
import 'package:edtech_mobile/core/widgets/contributor_credit_button.dart';
import 'package:edtech_mobile/theme/theme.dart';
import 'end_quiz_screen.dart';
import 'fullscreen_image_viewer.dart';

class ImageQuizLessonScreen extends StatefulWidget {
  final String nodeId;
  final Map<String, dynamic> lessonData;
  final String title;
  final Map<String, dynamic>? endQuiz;
  final String? lessonType;
  final Map<String, dynamic>? contributor;
  final List<Map<String, dynamic>>? contentVersionHistory;

  const ImageQuizLessonScreen({
    super.key,
    required this.nodeId,
    required this.lessonData,
    required this.title,
    this.endQuiz,
    this.lessonType,
    this.contributor,
    this.contentVersionHistory,
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
    final raw =
        widget.lessonData['slides'] ?? widget.lessonData['questions'] ?? [];
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
    if (index < 0 || index >= _slides.length) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
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
    final t = context.colors;
    final totalSlides = _slides.length;
    final answeredCount = _selectedAnswers.values.whereType<int>().length;
    final hasAnsweredAllSlides =
        totalSlides > 0 && answeredCount >= totalSlides;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: const AppBarLeadingBackAndHome(),
        leadingWidth: 112,
        automaticallyImplyLeading: false,
        title: Text(
          widget.title,
          style: TextStyle(
            color: t.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          ContributorCreditButton(
            contributor: widget.contributor,
            contentVersionHistory: widget.contentVersionHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.contributor == null)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: AiGeneratedNotice(visible: true, compact: true),
            ),
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
                      style: TextStyle(
                        color: t.brand,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${((_currentPage + 1) / totalSlides * 100).toInt()}%',
                      style: TextStyle(
                        color: t.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value:
                        totalSlides > 0 ? (_currentPage + 1) / totalSlides : 0,
                    backgroundColor: t.card,
                    valueColor: AlwaysStoppedAnimation<Color>(t.brand),
                    minHeight: 6,
                  ),
                ),
                if (totalSlides > 1) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        kIsWeb ? Icons.touch_app : Icons.swipe,
                        color: t.textTertiary,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        kIsWeb
                            ? 'Dùng nút Trước/Sau để chuyển câu'
                            : 'Vuốt trái/phải để sang câu tiếp theo',
                        style: TextStyle(
                          color: t.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
                if (kIsWeb && totalSlides > 1) ...[
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
                          foregroundColor: t.textSecondary,
                          side: BorderSide(color: t.border),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _currentPage < totalSlides - 1
                            ? () => _goToPage(_currentPage + 1)
                            : null,
                        icon: const Icon(Icons.chevron_right, size: 16),
                        label: const Text('Sau'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: t.brand,
                          foregroundColor: t.textOnBrand,
                        ),
                      ),
                    ],
                  ),
                ],
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

          // Bottom section: only show test button when all slides answered
          Padding(
            padding: const EdgeInsets.all(16),
            child: hasAnsweredAllSlides
                ? SizedBox(
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
                              questions: (widget.endQuiz?['questions'] as List?)
                                  ?.cast<dynamic>(),
                              contributor: widget.contributor,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: t.brand,
                        foregroundColor: t.textOnBrand,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Làm bài kiểm tra',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: t.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: t.border),
                    ),
                    child: Text(
                      'Hãy trả lời hết tất cả slide trước khi làm bài kiểm tra '
                      '($answeredCount/$totalSlides).',
                      style: TextStyle(
                        color: t.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(int index, Map<String, dynamic> slide) {
    final t = context.colors;
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
                          color: t.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: t.border),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported,
                                color: t.textTertiary, size: 48),
                            const SizedBox(height: 8),
                            Text('Không thể tải hình ảnh',
                                style: TextStyle(color: t.textTertiary)),
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
                      child: Icon(
                        Icons.zoom_in,
                        color: t.textOnBrand,
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
            style: TextStyle(
              color: t.textPrimary,
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
                color: t.brand.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.brand.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, color: t.brand, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gợi ý',
                          style: TextStyle(
                            color: t.brand,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hint.toString(),
                          style: TextStyle(
                            color: t.textSecondary,
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

            Color borderColor = const Color(0x332D363D);
            Color bgColor = t.card;
            Color labelColor = t.textSecondary;

            if (revealed) {
              if (isCorrect) {
                borderColor = t.success;
                bgColor = t.success.withValues(alpha: 0.1);
                labelColor = t.success;
              } else if (isSelected && !isCorrect) {
                borderColor = t.error;
                bgColor = t.error.withValues(alpha: 0.1);
                labelColor = t.error;
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
                                  ? t.success.withValues(alpha: 0.2)
                                  : revealed && isSelected
                                      ? t.error.withValues(alpha: 0.2)
                                      : t.cardMuted,
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
                              style: TextStyle(
                                color: t.textPrimary,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (revealed && isCorrect)
                            Icon(Icons.check_circle, color: t.success, size: 22),
                          if (revealed && isSelected && !isCorrect)
                            Icon(Icons.cancel, color: t.error, size: 22),
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
                      padding:
                          revealed ? const EdgeInsets.all(10) : EdgeInsets.zero,
                      constraints: BoxConstraints(
                        maxHeight: revealed ? 200 : 0,
                      ),
                      decoration: BoxDecoration(
                        color: t.cardMuted.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isCorrect ? Icons.info_outline : Icons.info_outline,
                            color: isCorrect
                                ? t.success
                                : t.textTertiary,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              explanation.toString(),
                              style: TextStyle(
                                color: t.textSecondary,
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
