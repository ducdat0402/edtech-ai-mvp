import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:edtech_mobile/core/services/tutorial_service.dart';
import 'package:edtech_mobile/theme/theme.dart';

export 'package:tutorial_coach_mark/tutorial_coach_mark.dart'
    show ContentAlign, TargetFocus, ShapeLightFocus;

class TutorialHelper {
  static TargetFocus buildTarget({
    required GlobalKey key,
    required String title,
    required String description,
    ContentAlign align = ContentAlign.bottom,
    ShapeLightFocus shape = ShapeLightFocus.RRect,
    double radius = 12,
    IconData? icon,
    String? stepLabel,
  }) {
    return TargetFocus(
      identify: key.toString(),
      keyTarget: key,
      alignSkip: Alignment.topRight,
      enableOverlayTab: true,
      enableTargetTab: true,
      shape: shape,
      radius: radius,
      paddingFocus: 8,
      contents: [
        TargetContent(
          align: align,
          builder: (context, controller) {
            return _TutorialContent(
              title: title,
              description: description,
              icon: icon,
              stepLabel: stepLabel,
              onNext: controller.next,
            );
          },
        ),
      ],
    );
  }

  static Future<void> showTutorial({
    required BuildContext context,
    required String tutorialId,
    required List<TargetFocus> targets,
    VoidCallback? onFinish,
    bool force = false,
  }) async {
    if (!force) {
      final seen = await TutorialService.hasSeenTutorial(tutorialId);
      if (seen) return;
    }

    if (targets.isEmpty) return;

    if (!context.mounted) return;

    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.85,
      textSkip: 'BỎ QUA',
      textStyleSkip: const TextStyle(
        color: Colors.white70,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      paddingFocus: 8,
      focusAnimationDuration: const Duration(milliseconds: 300),
      unFocusAnimationDuration: const Duration(milliseconds: 300),
      beforeFocus: (target) async {
        final ctx = target.keyTarget?.currentContext;
        if (ctx != null && ctx.mounted) {
          // explicit: luôn cuộn để đưa target vào viewport (kể cả phần dưới màn hình, vd. chat AI)
          await Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOut,
            alignment: 0.2,
            alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
          );
        }
      },
      onFinish: () {
        TutorialService.markTutorialSeen(tutorialId);
        onFinish?.call();
      },
      onSkip: () {
        TutorialService.markTutorialSeen(tutorialId);
        return true;
      },
    ).show(context: context);
  }
}

class _TutorialContent extends StatelessWidget {
  final String title;
  final String description;
  final IconData? icon;
  final String? stepLabel;
  final VoidCallback? onNext;

  const _TutorialContent({
    required this.title,
    required this.description,
    this.icon,
    this.stepLabel,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.purpleNeon.withValues(alpha: 0.2),
            AppColors.cyanNeon.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.purpleNeon.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (stepLabel != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cyanNeon.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  stepLabel!,
                  style: const TextStyle(
                    color: AppColors.cyanNeon,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.purpleNeon, size: 22),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onNext,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.purpleNeon, AppColors.cyanNeon],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tiếp',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
