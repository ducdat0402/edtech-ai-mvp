import 'package:flutter/material.dart';
import 'package:edtech_mobile/theme/theme.dart';

/// Header tím + đáy cong + tab Học tập / Đóng góp (mock Thư viện).
class LibraryCurvedHeader extends StatelessWidget {
  const LibraryCurvedHeader({
    super.key,
    required this.studySelected,
    required this.contributeSelected,
    required this.onStudyTap,
    required this.onContributeTap,
    this.canSwitchToContribute = true,
  });

  final bool studySelected;
  final bool contributeSelected;
  final VoidCallback onStudyTap;
  final VoidCallback onContributeTap;
  final bool canSwitchToContribute;

  @override
  Widget build(BuildContext context) {
    final sem = context.colors;
    return ClipPath(
      clipper: const _LibraryHeaderWaveClipper(),
      child: Container(
        width: double.infinity,
        color: sem.brand,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [sem.brandStrong, sem.brand],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Thư viện',
                    style: AppTextStyles.h2.copyWith(
                      color: sem.textOnBrand,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _HeaderTabCard(
                          selected: studySelected,
                          title: 'Học tập',
                          subtitle: 'Khám phá môn',
                          icon: Icons.school_rounded,
                          accent: sem.gold,
                          onTap: onStudyTap,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _HeaderTabCard(
                          selected: contributeSelected,
                          title: 'Đóng góp',
                          subtitle: 'Bài & môn học',
                          icon: Icons.volunteer_activism_rounded,
                          accent: sem.textOnBrand,
                          onTap: canSwitchToContribute ? onContributeTap : null,
                          dimmed: !canSwitchToContribute,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderTabCard extends StatelessWidget {
  const _HeaderTabCard({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.dimmed = false,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final sem = context.colors;
    final border = selected
        ? accent.withValues(alpha: 0.95)
        : Colors.white.withValues(alpha: 0.35);
    final bg = selected
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.08);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: selected ? 1.6 : 1),
          ),
          child: Opacity(
            opacity: dimmed ? 0.55 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 28, color: selected ? accent : sem.textOnBrand),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: AppTextStyles.bodyBold.copyWith(
                    color: selected ? accent : sem.textOnBrand,
                    fontSize: 15,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: sem.textOnBrand.withValues(alpha: 0.85),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LibraryHeaderWaveClipper extends CustomClipper<Path> {
  const _LibraryHeaderWaveClipper();

  @override
  Path getClip(Size size) {
    final p = Path();
    p.moveTo(0, 0);
    p.lineTo(0, size.height - 18);
    p.quadraticBezierTo(
      size.width * 0.22,
      size.height + 10,
      size.width * 0.5,
      size.height - 14,
    );
    p.quadraticBezierTo(
      size.width * 0.78,
      size.height - 38,
      size.width,
      size.height - 12,
    );
    p.lineTo(size.width, 0);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
