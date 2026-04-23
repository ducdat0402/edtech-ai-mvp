import 'package:flutter/material.dart';
import 'package:edtech_mobile/core/widgets/app_bar_leading_back_home.dart';
import 'package:edtech_mobile/core/widgets/ai_generated_notice.dart';
import 'package:edtech_mobile/core/widgets/contributor_credit_button.dart';
import 'package:flutter/services.dart';
import 'package:edtech_mobile/theme/colors.dart';
import 'end_quiz_screen.dart';

class VideoLessonScreen extends StatefulWidget {
  final String nodeId;
  final Map<String, dynamic> lessonData;
  final String title;
  final Map<String, dynamic>? endQuiz;
  final String? lessonType;
  final Map<String, dynamic>? contributor;

  const VideoLessonScreen({
    super.key,
    required this.nodeId,
    required this.lessonData,
    required this.title,
    this.endQuiz,
    this.lessonType,
    this.contributor,
  });

  @override
  State<VideoLessonScreen> createState() => _VideoLessonScreenState();
}

class _VideoLessonScreenState extends State<VideoLessonScreen> {
  String get _videoUrl =>
      (widget.lessonData['videoUrl'] ?? widget.lessonData['video'] ?? '')
          .toString();

  String get _summary =>
      (widget.lessonData['summary'] ?? widget.lessonData['description'] ?? '')
          .toString();

  List<Map<String, dynamic>> get _keyPoints {
    final raw =
        widget.lessonData['keyPoints'] ?? widget.lessonData['key_points'] ?? [];
    return List<Map<String, dynamic>>.from(raw);
  }

  List<String> get _keywords {
    final raw =
        widget.lessonData['keywords'] ?? widget.lessonData['tags'] ?? [];
    return List<String>.from(raw.map((e) => e.toString()));
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Đã sao chép link!'),
        backgroundColor: AppColors.successNeon.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Video placeholder
                  _buildVideoPlaceholder(),
                  const SizedBox(height: 20),

                  // Summary section
                  if (_summary.isNotEmpty)
                    _buildCollapsibleSection(
                      title: 'Tóm tắt',
                      icon: Icons.summarize,
                      initiallyExpanded: true,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.bgSecondary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x332D363D)),
                        ),
                        child: Text(
                          _summary,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),

                  // Key points section
                  if (_keyPoints.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildCollapsibleSection(
                      title: 'Nội dung chính',
                      icon: Icons.list_alt,
                      initiallyExpanded: true,
                      child: Column(
                        children: _keyPoints.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final point = entry.value;
                          return _buildKeyPointCard(idx, point);
                        }).toList(),
                      ),
                    ),
                  ],

                  // Keywords section
                  if (_keywords.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildCollapsibleSection(
                      title: 'Từ khóa',
                      icon: Icons.tag,
                      initiallyExpanded: false,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _keywords.map((keyword) {
                            return Chip(
                              label: Text(
                                keyword,
                                style: const TextStyle(
                                  color: AppColors.purpleNeon,
                                  fontSize: 13,
                                ),
                              ),
                              backgroundColor:
                                  AppColors.purpleNeon.withValues(alpha: 0.1),
                              side: BorderSide(
                                color:
                                    AppColors.purpleNeon.withValues(alpha: 0.3),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                ],
              ),
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
                        lessonType: widget.lessonType ?? 'video',
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

  Widget _buildVideoPlaceholder() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x332D363D)),
      ),
      child: Column(
        children: [
          // Video thumbnail area
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.bgTertiary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.purpleNeon.withValues(alpha: 0.15),
                  AppColors.pinkNeon.withValues(alpha: 0.1),
                ],
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_circle_outline,
                  size: 72,
                  color: AppColors.purpleNeon,
                ),
                SizedBox(height: 12),
                Text(
                  'Video bài học',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Nhấn để mở trong trình duyệt',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // URL section
          if (_videoUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.link,
                      color: AppColors.primaryLight, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _videoUrl,
                      style: const TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy,
                        color: AppColors.textSecondary, size: 18),
                    onPressed: () => _copyToClipboard(_videoUrl),
                    tooltip: 'Sao chép link',
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ],
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Chưa có link video',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleSection({
    required String title,
    required IconData icon,
    required Widget child,
    bool initiallyExpanded = true,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        leading: Icon(icon, color: AppColors.purpleNeon, size: 22),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconColor: AppColors.textSecondary,
        collapsedIconColor: AppColors.textTertiary,
        children: [child],
      ),
    );
  }

  Widget _buildKeyPointCard(int index, Map<String, dynamic> point) {
    final pointTitle = (point['title'] ?? point['name'] ?? '').toString();
    final description =
        (point['description'] ?? point['content'] ?? '').toString();
    final timestamp = (point['timestamp'] ?? point['time'] ?? '').toString();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x332D363D)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Index badge
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: AppColors.purpleNeon.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: AppColors.purpleNeon,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pointTitle,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (timestamp.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          timestamp,
                          style: const TextStyle(
                            color: AppColors.primaryLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
