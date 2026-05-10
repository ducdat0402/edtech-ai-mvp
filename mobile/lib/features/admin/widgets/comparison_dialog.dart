import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:edtech_mobile/core/config/api_config.dart';
import 'package:edtech_mobile/features/content/widgets/web_video_player.dart';
import 'package:edtech_mobile/theme/theme.dart';

class _ComparisonDialog extends StatefulWidget {
  final Map<String, dynamic> comparison;

  const _ComparisonDialog({super.key, required this.comparison});

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

  Widget _buildQuizPreview(
      BuildContext context, Map<String, dynamic>? quizData) {
    final sem = context.colors;
    final brandHi = Color.lerp(sem.brand, Colors.white, 0.55)!;
    if (quizData == null) {
      return Text(
        '(Không có quiz)',
        style: TextStyle(
            color: sem.textTertiary, fontStyle: FontStyle.italic),
      );
    }

    final question = quizData['question'] as String? ?? '';
    final options = quizData['options'] as List<dynamic>? ?? [];
    final correctAnswer = quizData['correctAnswer'] as int?;
    final explanation = quizData['explanation'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: sem.border.withValues(alpha: 0.65)),
        borderRadius: BorderRadius.circular(8),
        color: sem.cardMuted,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.isEmpty ? '(Không có câu hỏi)' : question,
            style: AppTextStyles.labelLarge.copyWith(
              color: sem.textPrimary,
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
                  color: isCorrect
                      ? sem.success.withValues(alpha: 0.12)
                      : sem.card,
                  border: Border.all(
                    color: isCorrect
                        ? sem.success
                        : sem.border.withValues(alpha: 0.65),
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
                      color: isCorrect
                          ? sem.success
                          : sem.textTertiary,
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
                          color: sem.success,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Đúng',
                          style: TextStyle(
                              color: sem.textOnBrand, fontSize: 12),
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
                color: brandHi.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: brandHi.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Giải thích:',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: sem.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(explanation,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: sem.textSecondary)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRichContentPreview(
      BuildContext context, dynamic richContent) {
    final sem = context.colors;
    if (richContent == null) {
      return Text(
        '(Không có nội dung)',
        style: TextStyle(
            color: sem.textTertiary, fontStyle: FontStyle.italic),
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
          border: Border.all(color: sem.border.withValues(alpha: 0.65)),
          borderRadius: BorderRadius.circular(8),
          color: sem.cardMuted,
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
        style: AppTextStyles.bodyMedium.copyWith(color: sem.textPrimary),
      );
    }
  }

  Widget _buildMediaPreview(BuildContext context, Map<String, dynamic>? media) {
    final sem = context.colors;
    final brandHi = Color.lerp(sem.brand, Colors.white, 0.55)!;
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
            context,
            icon: Icons.image_not_supported_outlined,
            text: 'Chưa có hình ảnh',
          ),
          const SizedBox(height: 12),
          _buildNoMediaPlaceholder(
            context,
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
              itemCount: (media['imageUrls'] as List).length,
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
                      placeholder: (_, __) => Container(
                        width: 100,
                        height: 100,
                        color: sem.cardMuted,
                        child: Center(
                            child: CircularProgressIndicator(
                                color: brandHi)),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 100,
                        height: 100,
                        color: sem.cardMuted,
                        child: Icon(Icons.error_outline_rounded,
                            color: sem.error),
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
              imageUrl: _getFullUrl(media['imageUrl']),
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                height: 200,
                color: sem.cardMuted,
                child: Center(
                    child: CircularProgressIndicator(
                        color: brandHi)),
              ),
              errorWidget: (_, __, ___) => Container(
                height: 200,
                color: sem.cardMuted,
                child: Icon(Icons.error_outline_rounded,
                    color: sem.error),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ] else ...[
          // No image placeholder
          _buildNoMediaPlaceholder(
            context,
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
                url: _getFullUrl(media['videoUrl']),
                height: 200,
              ),
            ),
          ),
        ] else ...[
          // No video placeholder
          _buildNoMediaPlaceholder(
            context,
            icon: Icons.videocam_off_outlined,
            text: 'Chưa có video',
          ),
        ],
      ],
    );
  }

  Widget _buildNoMediaPlaceholder(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    final sem = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: sem.cardMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: sem.border.withValues(alpha: 0.65)),
      ),
      child: Row(
        children: [
          Icon(icon, color: sem.textTertiary, size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: sem.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sem = context.colors;
    final brandHi = Color.lerp(sem.brand, Colors.white, 0.55)!;
    final original =
        widget.comparison['original'] as Map<String, dynamic>? ?? {};
    final proposed =
        widget.comparison['proposed'] as Map<String, dynamic>? ?? {};

    return Dialog(
      backgroundColor: sem.card,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.compare_arrows, color: sem.textOnBrand),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'So sánh: Bản gốc vs Bản đề xuất',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: sem.textOnBrand,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: sem.textOnBrand.withValues(alpha: 0.7)),
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
                        backgroundColor: _showOriginal
                            ? sem.brand
                            : sem.cardMuted,
                        foregroundColor: _showOriginal
                            ? sem.textOnBrand
                            : sem.textSecondary,
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
                            ? sem.success
                            : sem.cardMuted,
                        foregroundColor: !_showOriginal
                            ? sem.textOnBrand
                            : sem.textSecondary,
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
                        color: _showOriginal
                            ? brandHi
                            : sem.success,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _showOriginal
                          ? (original['title'] as String? ??
                              '(Không có tiêu đề)')
                          : (proposed['title'] as String? ??
                              '(Không có tiêu đề)'),
                      style: AppTextStyles.labelLarge.copyWith(
                          color: sem.textPrimary,
                          fontWeight: FontWeight.w600),
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
                          color: _showOriginal
                              ? brandHi
                              : sem.success,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildQuizPreview(
                        context,
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
                          color: _showOriginal
                              ? brandHi
                              : sem.success,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Complexity selector
                      Container(
                        decoration: BoxDecoration(
                          color: sem.cardMuted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: List.generate(3, (index) {
                            final isSelected = _complexityIndex == index;
                            final colors = [
                              sem.success,
                              sem.brand,
                              sem.warning
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
                                          ? sem.textOnBrand
                                          : sem.textSecondary,
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
                        context,
                        _getContentForComplexity(
                            _showOriginal ? original : proposed),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Media
                    _buildMediaPreview(
                      context,
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
  const ComparisonDialog({super.key, required super.comparison});
}
