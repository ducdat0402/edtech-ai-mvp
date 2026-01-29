import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../colors.dart';
import '../gradients.dart';
import '../text_styles.dart';

/// Cyberpunk-style gradient button with glow effect
class GamingButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Gradient? gradient;
  final Color? glowColor;
  final double? width;
  final double height;
  final bool isLoading;
  final IconData? icon;

  const GamingButton({
    super.key,
    required this.text,
    this.onPressed,
    this.gradient,
    this.glowColor,
    this.width,
    this.height = 52,
    this.isLoading = false,
    this.icon,
  });

  @override
  State<GamingButton> createState() => _GamingButtonState();
}

class _GamingButtonState extends State<GamingButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final gradient = widget.gradient ?? AppGradients.primary;
    final glowColor = widget.glowColor ?? AppColors.pinkNeon;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
        transformAlignment: Alignment.center,
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          gradient: widget.onPressed != null ? gradient : null,
          color: widget.onPressed == null ? AppColors.bgTertiary : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: widget.onPressed != null
              ? [
                  BoxShadow(
                    color: glowColor.withOpacity(_isPressed ? 0.3 : 0.5),
                    blurRadius: _isPressed ? 10 : 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isLoading ? null : widget.onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.text.toUpperCase(),
                          style: AppTextStyles.button.copyWith(
                            color: widget.onPressed != null
                                ? Colors.white
                                : AppColors.textDisabled,
                          ),
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

/// Secondary button with border (outlined style)
class GamingButtonOutlined extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? borderColor;
  final double? width;
  final double height;
  final IconData? icon;

  const GamingButtonOutlined({
    super.key,
    required this.text,
    this.onPressed,
    this.borderColor,
    this.width,
    this.height = 48,
    this.icon,
  });

  @override
  State<GamingButtonOutlined> createState() => _GamingButtonOutlinedState();
}

class _GamingButtonOutlinedState extends State<GamingButtonOutlined> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.borderColor ?? AppColors.cyanNeon;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
        transformAlignment: Alignment.center,
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: _isPressed ? borderColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: borderColor.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: borderColor, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.text.toUpperCase(),
                    style: AppTextStyles.button.copyWith(color: borderColor),
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
