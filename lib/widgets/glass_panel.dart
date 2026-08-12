import 'package:flutter/material.dart';

import '../theme.dart';

/// A frosted panel sitting over the reef.
///
/// Deliberately **not** a [BackdropFilter]. There are eight of these on the
/// dashboard, all inside a scrolling list, and each backdrop blur forces a
/// `saveLayer` plus a framebuffer read-back — enough to drop frames on every
/// scroll on real hardware.
///
/// Over a ground this dark the blur was buying almost nothing visually: what
/// reads as "glass" here is the translucent tint, the hairline border, and the
/// lit top edge. Those are close to free, so the look survives and the cost
/// does not.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 22,
    this.tint,
    this.tintStrength = 0.18,
    this.opacity = 0.62,
    this.shadowColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  /// Pulls the glass toward a status colour when something needs attention.
  final Color? tint;
  final double tintStrength;

  /// How much the panel obscures the reef behind it. Lower lets more through;
  /// too low and text starts fighting the image.
  final double opacity;

  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    final tinted = tint;
    final base = tinted == null
        ? AppColors.surfaceRaised
        : Color.lerp(AppColors.surfaceRaised, tinted, tintStrength)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            base.withValues(alpha: (opacity + 0.10).clamp(0.0, 1.0)),
            base.withValues(alpha: (opacity - 0.08).clamp(0.0, 1.0)),
          ],
        ),
        border: Border.all(
          color: tinted == null
              ? Colors.white.withValues(alpha: 0.10)
              : tinted.withValues(alpha: 0.34),
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor ?? Colors.black.withValues(alpha: 0.38),
            blurRadius: 22,
            spreadRadius: -8,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            Padding(padding: padding, child: child),
            // Light comes from the surface in this scene, so the top edge of
            // every pane catches it. This is what reads as glass.
            Positioned(
              top: 0,
              left: radius * 0.6,
              right: radius * 0.6,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.28),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
