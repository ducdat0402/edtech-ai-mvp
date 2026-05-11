import 'package:flutter/material.dart';
import 'package:edtech_mobile/features/subjects/widgets/library_category_chips.dart';
import 'package:edtech_mobile/features/subjects/widgets/library_curved_header.dart';
import 'package:edtech_mobile/features/subjects/widgets/library_featured_podium.dart';
import 'package:edtech_mobile/features/subjects/widgets/library_search_bar.dart';
import 'package:edtech_mobile/features/subjects/widgets/library_subject_group_row.dart';
import 'package:edtech_mobile/theme/semantic_colors.dart';

/// Hai nhánh chrome Thư viện (một `CustomScrollView`, sliver khác nhau).
enum LibraryPageMode {
  learner,
  contributor,
}

/// Khối nội dung bo góc chồng nhẹ lên header tím (mock Thư viện learner).
class LibraryLearnerOverlapSheet extends StatelessWidget {
  const LibraryLearnerOverlapSheet({
    super.key,
    required this.sem,
    required this.child,
  });

  final SemanticColors sem;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Material(
          color: sem.card,
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(26),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 22),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Tách `List<Widget>` sliver theo mode — màn hình chỉ truyền state + widget con (grid, section…).
abstract final class LibraryPageSlivers {
  static List<Widget> learner({
    required SemanticColors appSemantic,
    required TextEditingController searchController,
    required FocusNode searchFocusNode,
    required VoidCallback onContributeTab,
    required bool canSwitchToContribute,
    required Set<String> presentLibraryCategorySlugs,
    required String libraryCategoryFilter,
    required ValueChanged<String> onLibraryCategorySelected,
    required List<Map<String, dynamic>> hubFilteredSubjects,
    required LibraryFeaturedSort featuredSort,
    required ValueChanged<LibraryFeaturedSort> onFeaturedSortChanged,
    required void Function(Map<String, dynamic> subject) onSubjectTap,
    required String subjectTypeGroup,
    required Map<String, int> subjectCountsByType,
    required LibraryGroupTap onSubjectTypeGroupSelect,
    required Widget learnerGridSection,
  }) {
    return [
      SliverToBoxAdapter(
        child: LibraryCurvedHeader(
          studySelected: true,
          contributeSelected: false,
          onStudyTap: () {},
          onContributeTap: onContributeTab,
          canSwitchToContribute: canSwitchToContribute,
        ),
      ),
      SliverToBoxAdapter(
        child: LibraryLearnerOverlapSheet(
          sem: appSemantic,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LibrarySearchBar(
                controller: searchController,
                focusNode: searchFocusNode,
              ),
              const SizedBox(height: 16),
              LibraryCategoryChips(
                presentSlugs: presentLibraryCategorySlugs,
                selected: libraryCategoryFilter,
                onSelected: onLibraryCategorySelected,
              ),
              const SizedBox(height: 20),
              if (hubFilteredSubjects.isNotEmpty) ...[
                LibraryFeaturedPodium(
                  subjects: hubFilteredSubjects,
                  sort: featuredSort,
                  onSortChanged: onFeaturedSortChanged,
                  onSubjectTap: onSubjectTap,
                ),
                const SizedBox(height: 24),
              ],
              LibrarySubjectGroupRow(
                selectedType: subjectTypeGroup,
                countsByType: subjectCountsByType,
                onSelectType: onSubjectTypeGroupSelect,
              ),
              const SizedBox(height: 20),
              learnerGridSection,
            ],
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 32)),
    ];
  }

  static List<Widget> contributor({
    required SemanticColors screenTokens,
    required TextEditingController searchController,
    required FocusNode searchFocusNode,
    required VoidCallback onStudyTab,
    required Widget roleSwitcher,
    required Widget contributorBanner,
    required List<Map<String, dynamic>> subjects,
    required List<Map<String, dynamic>> filteredSubjects,
    required List<Widget> typeSectionChildren,
  }) {
    final t = screenTokens;
    return [
      SliverToBoxAdapter(
        child: LibraryCurvedHeader(
          studySelected: false,
          contributeSelected: true,
          onStudyTap: onStudyTab,
          onContributeTap: () {},
          canSwitchToContribute: true,
        ),
      ),
      SliverToBoxAdapter(
        child: LibraryLearnerOverlapSheet(
          sem: t,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LibrarySearchBar(
                controller: searchController,
                focusNode: searchFocusNode,
                semantics: SemanticColors.dark,
              ),
              const SizedBox(height: 12),
              roleSwitcher,
              const SizedBox(height: 14),
              contributorBanner,
              const SizedBox(height: 16),
              if (subjects.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Chưa có môn học nào',
                      style: TextStyle(color: t.textSecondary),
                    ),
                  ),
                )
              else if (filteredSubjects.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 18),
                  child: Center(
                    child: Text(
                      'Không tìm thấy môn học phù hợp.\nThử từ khóa khác hoặc xóa ô tìm kiếm.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: t.textSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                )
              else
                ...typeSectionChildren,
            ],
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 32)),
    ];
  }
}
