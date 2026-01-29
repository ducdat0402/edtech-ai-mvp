import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:edtech_mobile/theme/theme.dart';

/// Confetti celebration widget for level ups, achievements, etc.
class ConfettiCelebration extends StatefulWidget {
  final Widget child;
  final ConfettiController controller;

  const ConfettiCelebration({
    super.key,
    required this.child,
    required this.controller,
  });

  @override
  State<ConfettiCelebration> createState() => _ConfettiCelebrationState();
}

class _ConfettiCelebrationState extends State<ConfettiCelebration> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Center confetti burst
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: widget.controller,
            blastDirection: pi / 2, // downward
            blastDirectionality: BlastDirectionality.explosive,
            maxBlastForce: 30,
            minBlastForce: 10,
            emissionFrequency: 0.03,
            numberOfParticles: 50,
            gravity: 0.2,
            shouldLoop: false,
            colors: const [
              AppColors.purpleNeon,
              AppColors.pinkNeon,
              AppColors.orangeNeon,
              AppColors.cyanNeon,
              AppColors.successNeon,
              AppColors.xpGold,
            ],
            createParticlePath: _drawStar,
          ),
        ),
      ],
    );
  }

  Path _drawStar(Size size) {
    final random = Random();
    // Randomly choose between star, circle, or rectangle
    final shape = random.nextInt(3);
    
    switch (shape) {
      case 0:
        return _starPath(size);
      case 1:
        return _circlePath(size);
      default:
        return _rectanglePath(size);
    }
  }

  Path _starPath(Size size) {
    double degToRad(double deg) => deg * (pi / 180.0);
    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(halfWidth + externalRadius * cos(step), halfWidth + externalRadius * sin(step));
      path.lineTo(halfWidth + internalRadius * cos(step + halfDegreesPerStep),
          halfWidth + internalRadius * sin(step + halfDegreesPerStep));
    }
    path.close();
    return path;
  }

  Path _circlePath(Size size) {
    return Path()..addOval(Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: size.width / 2));
  }

  Path _rectanglePath(Size size) {
    return Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height / 2));
  }
}

/// Controller helper for confetti celebrations
class CelebrationController {
  final ConfettiController _confettiController;

  CelebrationController()
      : _confettiController = ConfettiController(duration: const Duration(seconds: 3));

  ConfettiController get controller => _confettiController;

  void celebrate() {
    HapticFeedback.heavyImpact();
    _confettiController.play();
  }

  void stop() {
    _confettiController.stop();
  }

  void dispose() {
    _confettiController.dispose();
  }
}

/// Level up celebration dialog with confetti
class LevelUpCelebration extends StatefulWidget {
  final int newLevel;
  final String levelTitle;
  final Color levelColor;
  final VoidCallback? onDismiss;

  const LevelUpCelebration({
    super.key,
    required this.newLevel,
    required this.levelTitle,
    required this.levelColor,
    this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required int newLevel,
    required String levelTitle,
    required Color levelColor,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LevelUpCelebration(
        newLevel: newLevel,
        levelTitle: levelTitle,
        levelColor: levelColor,
      ),
    );
  }

  @override
  State<LevelUpCelebration> createState() => _LevelUpCelebrationState();
}

class _LevelUpCelebrationState extends State<LevelUpCelebration>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confettiController;
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Start animations
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.heavyImpact();
      _confettiController.play();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dialog
        Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: widget.levelColor.withOpacity(0.5), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: widget.levelColor.withOpacity(0.3 * _glowAnimation.value),
                        blurRadius: 40 * _glowAnimation.value,
                        spreadRadius: 10 * _glowAnimation.value,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Trophy icon with glow
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [widget.levelColor, widget.levelColor.withOpacity(0.7)]),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: widget.levelColor.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.emoji_events_rounded, size: 48, color: Colors.white),
                      ),
                      const SizedBox(height: 24),
                      
                      // Level up text
                      ShaderMask(
                        shaderCallback: (bounds) => AppGradients.primary.createShader(bounds),
                        child: Text('LEVEL UP!', style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 28)),
                      ),
                      const SizedBox(height: 16),
                      
                      // New level
                      AnimatedCounter(
                        value: widget.newLevel,
                        style: AppTextStyles.numberXLarge.copyWith(color: widget.levelColor, fontSize: 64),
                      ),
                      const SizedBox(height: 8),
                      
                      // Level title
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: widget.levelColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: widget.levelColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          widget.levelTitle,
                          style: AppTextStyles.labelLarge.copyWith(color: widget.levelColor),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Continue button
                      GamingButton(
                        text: 'Tuyệt vời!',
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.of(context).pop();
                          widget.onDismiss?.call();
                        },
                        gradient: LinearGradient(colors: [widget.levelColor, widget.levelColor.withOpacity(0.8)]),
                        glowColor: widget.levelColor,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        
        // Confetti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2,
            blastDirectionality: BlastDirectionality.explosive,
            maxBlastForce: 30,
            minBlastForce: 10,
            emissionFrequency: 0.02,
            numberOfParticles: 30,
            gravity: 0.15,
            shouldLoop: true,
            colors: [
              widget.levelColor,
              AppColors.purpleNeon,
              AppColors.pinkNeon,
              AppColors.xpGold,
              AppColors.cyanNeon,
            ],
          ),
        ),
      ],
    );
  }
}

/// Achievement unlocked celebration
class AchievementUnlockedCelebration extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int xpReward;
  final int coinReward;
  final VoidCallback? onDismiss;

  const AchievementUnlockedCelebration({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.xpReward = 0,
    this.coinReward = 0,
    this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    int xpReward = 0,
    int coinReward = 0,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AchievementUnlockedCelebration(
        title: title,
        description: description,
        icon: icon,
        color: color,
        xpReward: xpReward,
        coinReward: coinReward,
      ),
    );
  }

  @override
  State<AchievementUnlockedCelebration> createState() => _AchievementUnlockedCelebrationState();
}

class _AchievementUnlockedCelebrationState extends State<AchievementUnlockedCelebration>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confettiController;
  late final AnimationController _animationController;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _slideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.heavyImpact();
      _confettiController.play();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _slideAnimation.value),
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.bgSecondary,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: widget.color.withOpacity(0.5), width: 2),
                      boxShadow: [
                        BoxShadow(color: widget.color.withOpacity(0.3), blurRadius: 30, spreadRadius: 5),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Achievement badge
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: SweepGradient(
                              colors: [widget.color, widget.color.withOpacity(0.5), widget.color],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: widget.color.withOpacity(0.5), blurRadius: 15)],
                          ),
                          child: Icon(widget.icon, size: 40, color: Colors.white),
                        ),
                        const SizedBox(height: 20),
                        
                        // Title
                        Text('THÀNH TỰU MỚI!', style: AppTextStyles.labelMedium.copyWith(color: widget.color)),
                        const SizedBox(height: 8),
                        Text(widget.title, style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary), textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        Text(widget.description, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
                        
                        // Rewards
                        if (widget.xpReward > 0 || widget.coinReward > 0) ...[
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (widget.xpReward > 0)
                                _RewardChip(icon: Icons.star_rounded, value: '+${widget.xpReward}', label: 'XP', color: AppColors.xpGold),
                              if (widget.xpReward > 0 && widget.coinReward > 0) const SizedBox(width: 16),
                              if (widget.coinReward > 0)
                                _RewardChip(icon: Icons.monetization_on_rounded, value: '+${widget.coinReward}', label: 'Coin', color: AppColors.coinGold),
                            ],
                          ),
                        ],
                        
                        const SizedBox(height: 24),
                        GamingButton(
                          text: 'Tuyệt vời!',
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            Navigator.of(context).pop();
                            widget.onDismiss?.call();
                          },
                          gradient: LinearGradient(colors: [widget.color, widget.color.withOpacity(0.8)]),
                          glowColor: widget.color,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2,
            blastDirectionality: BlastDirectionality.explosive,
            maxBlastForce: 25,
            minBlastForce: 8,
            emissionFrequency: 0.03,
            numberOfParticles: 25,
            gravity: 0.2,
            shouldLoop: false,
            colors: [widget.color, AppColors.purpleNeon, AppColors.pinkNeon, AppColors.xpGold],
          ),
        ),
      ],
    );
  }
}

class _RewardChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _RewardChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(value, style: AppTextStyles.labelMedium.copyWith(color: color)),
        ],
      ),
    );
  }
}

/// Animated counter widget for smooth number transitions
class AnimatedCounter extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      builder: (context, value, child) {
        return Text(
          value.toString(),
          style: style ?? AppTextStyles.numberLarge,
        );
      },
    );
  }
}
