import 'package:flutter/material.dart';
import 'package:edtech_mobile/theme/theme.dart';

typedef LibraryGroupTap = void Function(String subjectType);

/// Ba thẻ nhóm: Cá nhân / Cộng đồng / Chuyên gia (mock "Nhóm môn học").
class LibrarySubjectGroupRow extends StatelessWidget {
  const LibrarySubjectGroupRow({
    super.key,
    required this.selectedType,
    required this.onSelectType,
    required this.countsByType,
  });

  /// `all` | `private` | `community` | `expert`
  final String selectedType;
  final LibraryGroupTap onSelectType;
  final Map<String, int> countsByType;

  @override
  Widget build(BuildContext context) {
    final sem = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nhóm môn học',
          style: AppTextStyles.h3.copyWith(
            color: sem.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _GroupCard(
                title: 'Môn học cá nhân',
                subtitle: '${countsByType['private'] ?? 0} môn',
                icon: Icons.lock_rounded,
                accent: sem.info,
                selected: selectedType == 'private',
                onTap: () => onSelectType('private'),
              ),
              const SizedBox(width: 12),
              _GroupCard(
                title: 'Môn học cộng đồng',
                subtitle: '${countsByType['community'] ?? 0} môn',
                icon: Icons.groups_rounded,
                accent: sem.gold,
                selected: selectedType == 'community',
                onTap: () => onSelectType('community'),
              ),
              const SizedBox(width: 12),
              _GroupCard(
                title: 'Môn học chuyên gia',
                subtitle: '${countsByType['expert'] ?? 0} môn',
                icon: Icons.workspace_premium_rounded,
                accent: sem.brand,
                selected: selectedType == 'expert',
                onTap: () => onSelectType('expert'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sem = context.colors;
    return SizedBox(
      width: 220,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: sem.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? accent : sem.border,
                width: selected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyBold.copyWith(
                          color: sem.textPrimary,
                          fontSize: 14,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTextStyles.caption.copyWith(
                          color: sem.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accent, size: 26),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
