import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:edtech_mobile/core/config/api_config.dart';
import 'package:edtech_mobile/features/content/widgets/web_video_player.dart';

class _ComparisonDialog extends StatefulWidget {
  final Map<String, dynamic> comparison;

  const _ComparisonDialog({required this.comparison});

  @override
  State<_ComparisonDialog> createState() => _ComparisonDialogState();
}

class _ComparisonDialogState extends State<_ComparisonDialog> {
  bool _showOriginal = true; // Toggle between original and proposed
  int _complexityIndex = 1; // 0=simple, 1=detailed, 2=comprehensive
  final List<String> _complexityLabels = ['Đơn giản', 'Chi tiết', 'Chuyên sâu'];

  String _getFullUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final baseUrl = ApiConfig.baseUrl.replaceAll('/api/v1', '');
    return '$baseUrl$url';
  }

  /// Get content for the selected complexity level
  dynamic _getContentForComplexity(Map<String, dynamic> data) {
    final textVariants = data['textVariants'] as Map<String, dynamic>?;

    // Fallback content: richContent -> content (plain text)
    dynamic fallbackContent = data['richContent'] ?? data['content'];

    switch (_complexityIndex) {
      case 0: // Simple
        if (textVariants?['simpleRichContent'] != null) {
          return textVariants!['simpleRichContent'];
        }
        if (textVariants?['simple'] != null) {
          return textVariants!['simple'];
        }
        return fallbackContent; // Fallback to default

      case 2: // Comprehensive
        if (textVariants?['comprehensiveRichContent'] != null) {
          return textVariants!['comprehensiveRichContent'];
        }
        if (textVariants?['comprehensive'] != null) {
          return textVariants!['comprehensive'];
        }
        return fallbackContent; // Fallback to default

      default: // Detailed (index 1)
        if (textVariants?['detailedRichContent'] != null) {
          return textVariants!['detailedRichContent'];
        }
        if (textVariants?['detailed'] != null) {
          return textVariants!['detailed'];
        }
        return fallbackContent;
    }
  }

  Widget _buildQuizPreview(Map<String, dynamic>? quizData) {
    if (quizData == null) {
      return const Text(
        '(Không có quiz)',
        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      );
    }

    final question = quizData['question'] as String? ?? '';
    final options = quizData['options'] as List<dynamic>? ?? [];
    final correctAnswer = quizData['correctAnswer'] as int?;
    final explanation = quizData['explanation'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.isEmpty ? '(Không có câu hỏi)' : question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(options.length, (index) {
            final isCorrect = index == correctAnswer;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.green.shade100 : Colors.white,
                  border: Border.all(
                    color: isCorrect ? Colors.green : Colors.grey.shade300,
                    width: isCorrect ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCorrect
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isCorrect ? Colors.green : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        options[index].toString(),
                        style: TextStyle(
                          fontWeight:
                              isCorrect ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isCorrect)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Đúng',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
          if (explanation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Giải thích:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(explanation),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRichContentPreview(dynamic richContent) {
    if (richContent == null) {
      return const Text(
        '(Không có nội dung)',
        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      );
    }

    try {
      quill.QuillController controller;
      if (richContent is List) {
        final delta = Delta.fromJson(richContent);
        controller = quill.QuillController(
          document: quill.Document.fromDelta(delta),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } else {
        controller = quill.QuillController.basic();
        controller.document = quill.Document()
          ..insert(0, richContent.toString());
      }

      return Container(
        constraints: const BoxConstraints(maxHeight: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SingleChildScrollView(
          child: IgnorePointer(
            child: quill.QuillEditor.basic(
              configurations: quill.QuillEditorConfigurations(
                controller: controller,
                sharedConfigurations: const quill.QuillSharedConfigurations(),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      return Text(
        richContent.toString(),
        style: const TextStyle(fontSize: 14),
      );
    }
  }

  Widget _buildMediaPreview(Map<String, dynamic>? media) {
    // Check if media has actual content (not just empty arrays)
    final hasImageUrls = media != null &&
        media['imageUrls'] != null &&
        (media['imageUrls'] as List).isNotEmpty;
    final hasImageUrl = media != null &&
        media['imageUrl'] != null &&
        (media['imageUrl'] as String).isNotEmpty;
    final hasVideoUrl = media != null &&
        media['videoUrl'] != null &&
        (media['videoUrl'] as String).isNotEmpty;

    final hasAnyImage = hasImageUrls || hasImageUrl;
    final hasAnyMedia = hasAnyImage || hasVideoUrl;

    if (!hasAnyMedia) {
      // Show placeholder when no media
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNoMediaPlaceholder(
            icon: Icons.image_not_supported_outlined,
            text: 'Chưa có hình ảnh',
          ),
          const SizedBox(height: 12),
          _buildNoMediaPlaceholder(
            icon: Icons.videocam_off_outlined,
            text: 'Chưa có video',
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Images section
        if (hasImageUrls) ...[
          const Text(
            'Hình ảnh:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: (media!['imageUrls'] as List).length,
              itemBuilder: (context, index) {
                final imageUrl = (media['imageUrls'] as List)[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: _getFullUrl(imageUrl),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey.shade200,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.error),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ] else if (hasImageUrl) ...[
          const Text(
            'Hình ảnh:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: _getFullUrl(media!['imageUrl']),
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 200,
                color: Colors.grey.shade200,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                height: 200,
                color: Colors.grey.shade200,
                child: const Icon(Icons.error),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ] else ...[
          // No image placeholder
          _buildNoMediaPlaceholder(
            icon: Icons.image_not_supported_outlined,
            text: 'Chưa có hình ảnh',
          ),
          const SizedBox(height: 12),
        ],

        // Video section
        if (hasVideoUrl) ...[
          const Text(
            'Video:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 200,
              child: WebVideoPlayer(
                url: _getFullUrl(media!['videoUrl']),
                height: 200,
              ),
            ),
          ),
        ] else ...[
          // No video placeholder
          _buildNoMediaPlaceholder(
            icon: Icons.videocam_off_outlined,
            text: 'Chưa có video',
          ),
        ],
      ],
    );
  }

  Widget _buildNoMediaPlaceholder(
      {required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade500, size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final original =
        widget.comparison['original'] as Map<String, dynamic>? ?? {};
    final proposed =
        widget.comparison['proposed'] as Map<String, dynamic>? ?? {};

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.compare_arrows, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'So sánh: Bản gốc vs Bản đề xuất',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Toggle buttons
            Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => _showOriginal = true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _showOriginal ? Colors.blue : Colors.grey.shade300,
                        foregroundColor:
                            _showOriginal ? Colors.white : Colors.black,
                      ),
                      child: const Text('Bản gốc'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => _showOriginal = false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !_showOriginal
                            ? Colors.green
                            : Colors.grey.shade300,
                        foregroundColor:
                            !_showOriginal ? Colors.white : Colors.black,
                      ),
                      child: const Text('Bản đề xuất'),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      'Tiêu đề:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _showOriginal ? Colors.blue : Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _showOriginal
                          ? (original['title'] as String? ??
                              '(Không có tiêu đề)')
                          : (proposed['title'] as String? ??
                              '(Không có tiêu đề)'),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    // Quiz or Rich Content
                    if ((_showOriginal
                            ? original['quizData']
                            : proposed['quizData']) !=
                        null) ...[
                      // Quiz preview
                      Text(
                        'Quiz:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _showOriginal ? Colors.blue : Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildQuizPreview(
                        _showOriginal
                            ? original['quizData']
                            : proposed['quizData'],
                      ),
                    ] else ...[
                      // Complexity tabs for text content
                      Text(
                        'Nội dung (3 dạng):',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _showOriginal ? Colors.blue : Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Complexity selector
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: List.generate(3, (index) {
                            final isSelected = _complexityIndex == index;
                            final colors = [
                              Colors.green,
                              Colors.blue,
                              Colors.orange
                            ];
                            return Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _complexityIndex = index),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colors[index]
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _complexityLabels[index],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey.shade700,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Rich Content based on selected complexity
                      _buildRichContentPreview(
                        _getContentForComplexity(
                            _showOriginal ? original : proposed),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Media
                    _buildMediaPreview(
                      _showOriginal ? original['media'] : proposed['media'],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Export the widget
class ComparisonDialog extends _ComparisonDialog {
  const ComparisonDialog({required super.comparison});
}
