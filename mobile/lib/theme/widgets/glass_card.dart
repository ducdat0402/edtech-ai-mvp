import 'dart:ui';
import 'package:flutter/material.dart';
import '../semantic_colors.dart';

/// Card sang **light mode**: nền trắng + border mềm + shadow nhẹ.
/// Ở **dark mode**: giữ glassmorphism (blur + lớp trong suốt) như cũ.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;
  final Color? borderColor;
  final double blur;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final List<BoxShadow>? boxShadow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 16,
    this.borderColor,
    this.blur = 10,
    this.backgroundColor,
    this.onTap,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = context.colors;

    if (!isDark) {
      return _LightCard(
        padding: padding,
        borderRadius: borderRadius,
        borderColor: borderColor ?? tokens.border,
        backgroundColor: backgroundColor ?? tokens.card,
        onTap: onTap,
        boxShadow: boxShadow,
        tokens: tokens,
        child: child,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color:
            (backgroundColor ?? tokens.card).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? tokens.border,
          width: 1,
        ),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(borderRadius),
              child: Padding(
                padding: padding ?? const EdgeInsets.all(20),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LightCard extends StatelessWidget {
  const _LightCard({
    required this.child,
    required this.borderRadius,
    required this.tokens,
    this.padding,
    this.borderColor,
    this.backgroundColor,
    this.onTap,
    this.boxShadow,
  });

  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;
  final Color? borderColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final List<BoxShadow>? boxShadow;
  final SemanticColors tokens;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? tokens.card,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor ?? tokens.border),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: tokens.shadowColor,
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Card with neon glow border on hover/active
class NeonCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;
  /// null → [SemanticColors.brand] theo theme.
  final Color? glowColor;
  final VoidCallback? onTap;
  final bool isActive;

  const NeonCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 16,
    this.glowColor,
    this.onTap,
    this.isActive = false,
  });

  @override
  State<NeonCard> createState() => _NeonCardState();
}

class _NeonCardState extends State<NeonCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final glow = widget.glowColor ?? tokens.brand;
    final showGlow = _isHovered || widget.isActive;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: tokens.card,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: showGlow ? glow : tokens.border,
            width: showGlow ? 2 : 1,
          ),
          boxShadow: showGlow
              ? [
                  BoxShadow(
                    color: glow.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Padding(
              padding: widget.padding ?? const EdgeInsets.all(20),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple dark card without blur
class DarkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;
  final VoidCallback? onTap;

  const DarkCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 16,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: t.border,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}
