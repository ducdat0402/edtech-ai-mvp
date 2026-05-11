import 'package:flutter/material.dart';
import 'package:edtech_mobile/theme/theme.dart';

({Color tint, Color badge}) _podiumRankColors(
  SemanticColors sem,
  Brightness brightness,
  int rank,
) {
  final isDark = brightness == Brightness.dark;
  if (!isDark) {
    return switch (rank) {
      1 => (
          tint: const Color(0xFFFFF8E1),
          badge: const Color(0xFFFFC107),
        ),
      2 => (
          tint: const Color(0xFFE3F2FD),
          badge: const Color(0xFF2196F3),
        ),
      _ => (
          tint: const Color(0xFFFCE4EC),
          badge: const Color(0xFFE91E63),
        ),
    };
  }
  return switch (rank) {
    1 => (
        tint: Color.lerp(sem.card, sem.gold, 0.14)!,
        badge: sem.gold,
      ),
    2 => (
        tint: Color.lerp(sem.card, sem.info, 0.2)!,
        badge: sem.info,
      ),
    _ => (
        tint: Color.lerp(sem.card, sem.error, 0.12)!,
        badge: Color.lerp(sem.error, sem.brand, 0.25)!,
      ),
  };
}

enum LibraryFeaturedSort {
  byLearners,
  byName,
}

extension LibraryFeaturedSortX on LibraryFeaturedSort {
  String get labelVi => switch (this) {
        LibraryFeaturedSort.byLearners => 'Số người học',
        LibraryFeaturedSort.byName => 'Theo tên',
      };
}

/// Bục 3 môn: thứ tự hiển thị [2, 1, 3] (cao giữa = hạng 1).
class LibraryFeaturedPodium extends StatelessWidget {
  const LibraryFeaturedPodium({
    super.key,
    required this.subjects,
    required this.sort,
    required this.onSortChanged,
    required this.onSubjectTap,
    this.sectionTitle = 'Nổi bật tuần này',
    this.subtitleNote =
        'Xếp theo số người đang học (tất cả thời gian). Tuần gần đây: pha sau.',
  });

  final List<Map<String, dynamic>> subjects;
  final LibraryFeaturedSort sort;
  final ValueChanged<LibraryFeaturedSort> onSortChanged;
  final void Function(Map<String, dynamic> subject) onSubjectTap;
  final String sectionTitle;
  final String subtitleNote;

  List<Map<String, dynamic>> _topThree() {
    final copy = List<Map<String, dynamic>>.from(subjects);
    int count(Map<String, dynamic> s) =>
        (s['activeLearnerCount'] as num?)?.toInt() ?? 0;
    if (sort == LibraryFeaturedSort.byName) {
      copy.sort((a, b) {
        final na = (a['name'] ?? '').toString();
        final nb = (b['name'] ?? '').toString();
        return na.toLowerCase().compareTo(nb.toLowerCase());
      });
    } else {
      copy.sort((a, b) {
        final ca = count(a);
        final cb = count(b);
        if (cb != ca) return cb.compareTo(ca);
        return (a['name'] ?? '')
            .toString()
            .toLowerCase()
            .compareTo((b['name'] ?? '').toString().toLowerCase());
      });
    }
    return copy.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final sem = context.colors;
    final brightness = Theme.of(context).brightness;
    final top = _topThree();
    if (top.isEmpty) return const SizedBox.shrink();

    final first = top.isNotEmpty ? top[0] : null;
    final second = top.length > 1 ? top[1] : null;
    final third = top.length > 2 ? top[2] : null;
    final c2 = _podiumRankColors(sem, brightness, 2);
    final c1 = _podiumRankColors(sem, brightness, 1);
    final c3 = _podiumRankColors(sem, brightness, 3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                sectionTitle,
                style: AppTextStyles.h3.copyWith(
                  color: sem.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            PopupMenuButton<LibraryFeaturedSort>(
              initialValue: sort,
              onSelected: onSortChanged,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      sort.labelVi,
                      style: AppTextStyles.caption.copyWith(
                        color: sem.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Icon(Icons.expand_more_rounded,
                        size: 18, color: sem.textSecondary),
                  ],
                ),
              ),
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: LibraryFeaturedSort.byLearners,
                  child: Text(LibraryFeaturedSort.byLearners.labelVi),
                ),
                PopupMenuItem(
                  value: LibraryFeaturedSort.byName,
                  child: Text(LibraryFeaturedSort.byName.labelVi),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitleNote,
          style: AppTextStyles.caption.copyWith(
            color: sem.textTertiary,
            fontSize: 11,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 168,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _PodiumCard(
                  rank: 2,
                  subject: second,
                  height: 118,
                  tint: c2.tint,
                  badgeColor: c2.badge,
                  isDark: brightness == Brightness.dark,
                  onTap: second != null ? () => onSubjectTap(second) : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PodiumCard(
                  rank: 1,
                  subject: first,
                  height: 152,
                  tint: c1.tint,
                  badgeColor: c1.badge,
                  isDark: brightness == Brightness.dark,
                  onTap: first != null ? () => onSubjectTap(first) : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PodiumCard(
                  rank: 3,
                  subject: third,
                  height: 100,
                  tint: c3.tint,
                  badgeColor: c3.badge,
                  isDark: brightness == Brightness.dark,
                  onTap: third != null ? () => onSubjectTap(third) : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({
    required this.rank,
    required this.subject,
    required this.height,
    required this.tint,
    required this.badgeColor,
    required this.isDark,
    this.onTap,
  });

  final int rank;
  final Map<String, dynamic>? subject;
  final double height;
  final Color tint;
  final Color badgeColor;
  final bool isDark;
  final VoidCallback? onTap;

  String _learnersShort(Map<String, dynamic>? s) {
    if (s == null) return '—';
    final n = (s['activeLearnerCount'] as num?)?.toInt() ?? 0;
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k+';
    return '$n+';
  }

  @override
  Widget build(BuildContext context) {
    final sem = context.colors;
    final name = (subject?['name'] ?? '—').toString();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: height + 28,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                top: 14,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: subject != null ? tint : sem.cardMuted,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: sem.border),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: sem.textPrimary,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? sem.cardOverlay.withValues(alpha: 0.92)
                              : Colors.white.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _learnersShort(subject),
                          style: AppTextStyles.caption.copyWith(
                            color: sem.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 0,
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? sem.border : Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '$rank',
                    style: AppTextStyles.h4.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
