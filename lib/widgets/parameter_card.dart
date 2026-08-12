import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';
import 'entrance.dart';
import 'glass_panel.dart';
import '../models/water_parameter.dart';

/// One titration result, built around a ring gauge.
///
/// The gauge does the work a status icon and a row of range text used to do:
/// the arc sweeps to where the reading actually sits, and the target band is
/// marked on the track behind it. You can see whether a value is where it
/// should be without reading a label — and because that reading is geometric,
/// it survives without relying on colour.
class ParameterCard extends StatelessWidget {
  const ParameterCard({
    super.key,
    required this.parameter,
    this.compact = false,
    this.delay = Duration.zero,
  });

  final WaterParameter parameter;
  final bool compact;

  /// Held back to match the card's own entrance — a gauge that sweeps while
  /// its card is still fading in has finished before anyone can see it.
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final status = parameter.status;
    final flagged = status.needsAttention;
    final color = status.color;
    final maxRing = compact ? 96.0 : 112.0;

    return GlassPanel(
      radius: AppSpacing.radiusLg,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      tint: flagged ? color : null,
      tintStrength: 0.16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Square by construction, at whatever width is actually available.
          // A fixed SizedBox wider than its parent has its width clamped but
          // keeps its height, which silently turns the ring into an ellipse —
          // and then the marker, which travels on a circle, stops landing on
          // the arc anywhere except hard left and hard right.
          //
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxRing),
            child: AspectRatio(
              aspectRatio: 1,
              child: _Gauge(
                parameter: parameter,
                color: color,
                delay: delay,
              ),
            ),
          ),
          // The gauge's open bottom already supplies breathing room, so the
          // label sits close under it rather than floating away.
          const SizedBox(height: AppSpacing.sm),
          Text(
            parameter.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 11.5 : 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Gauge extends StatelessWidget {
  const _Gauge({
    required this.parameter,
    required this.color,
    required this.delay,
  });

  final WaterParameter parameter;
  final Color color;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    // Type scales with the ring, not with a breakpoint flag.
    //
    // The ring's diameter is whatever width the card can spare — 96pt on a
    // 390pt phone, 77 at 360, 64 at 320 — so a fixed font size means the
    // number-to-ring ratio drifts as the screen narrows, and a four-digit
    // reading like 1320 ends up crowding the arc. Deriving both sizes from the
    // measured diameter keeps that ratio constant at every width, and because
    // all three cards in a row share a diameter they still agree with each
    // other.
    return LayoutBuilder(
      builder: (context, constraints) {
        final diameter = constraints.maxWidth;
        return DelayedProgress(
          delay: delay,
          duration: const Duration(milliseconds: 1100),
          builder: (context, t) {
            return CustomPaint(
              painter: _RingGaugePainter(
                position: parameter.scalePosition * t,
                color: color,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      parameter.formattedValue,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: diameter * 0.27,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: AppColors.textPrimary,
                        shadows: [
                          Shadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: diameter * 0.03),
                    Text(
                      parameter.unit,
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: diameter * 0.10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                        color: color.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// An open-bottom gauge ring.
///
/// A dim track for the full scale, and a glowing arc sweeping to the current
/// reading. Health is carried by [color] rather than by any marking on the
/// track.
class _RingGaugePainter extends CustomPainter {
  const _RingGaugePainter({required this.position, required this.color});

  final double position;
  final Color color;

  // A 240° sweep opening at the bottom — reads as an instrument rather than a
  // progress circle.
  static const _start = 150 * math.pi / 180;
  static const _sweep = 240 * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    // Taken from the shorter side so the ring stays a ring even if the box it
    // is handed is not perfectly square.
    final stroke = math.min(size.width, size.height) * 0.075;
    final arcRect = (Offset.zero & size).deflate(stroke / 2 + 1);

    // Track.
    canvas.drawArc(
      arcRect,
      _start,
      _sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = AppColors.surfaceSunken,
    );

    if (position <= 0) return;

    final valueSweep = _sweep * position;

    // Bloom under the value arc.
    canvas.drawArc(
      arcRect,
      _start,
      valueSweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, stroke * 0.9)
        ..color = color.withValues(alpha: 0.55),
    );

    // Value arc, brightening as it travels. startAngle already places the
    // gradient — rotating it again as well throws a visible seam into the arc.
    canvas.drawArc(
      arcRect,
      _start,
      valueSweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: _start,
          endAngle: _start + _sweep,
          colors: [color.withValues(alpha: 0.45), color],
        ).createShader(arcRect),
    );

    // Marker, placed on the same ellipse the arc was drawn on. Using one
    // radius for both axes is what walks it off the track.
    final headAngle = _start + valueSweep;
    final head = Offset(
      arcRect.center.dx + (arcRect.width / 2) * math.cos(headAngle),
      arcRect.center.dy + (arcRect.height / 2) * math.sin(headAngle),
    );

    canvas.drawCircle(
      head,
      stroke * 0.75,
      Paint()
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, stroke * 0.8)
        ..color = color.withValues(alpha: 0.6),
    );
    canvas.drawCircle(head, stroke * 0.34, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_RingGaugePainter old) =>
      old.position != position || old.color != color;
}
