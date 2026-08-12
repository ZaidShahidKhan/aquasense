import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';
import 'entrance.dart';
import 'glass_panel.dart';
import '../models/water_parameter.dart';

/// A continuously sampled probe: current value alongside its recent trace.
///
/// Probes get a line where the Trident parameters get a gauge, and the
/// distinction is honest rather than decorative — a probe really is sampled
/// between the points drawn, whereas joining titration results hours apart
/// with a line would assert knowledge the controller does not have.
///
/// The shape is the point. pH swinging on its daily cycle, or temperature
/// climbing all night, is invisible in a single number no matter how large.
class LiveWaterCard extends StatelessWidget {
  const LiveWaterCard({
    super.key,
    required this.parameter,
    this.delay = Duration.zero,
  });

  final WaterParameter parameter;

  /// Held back to match the card's own entrance, so the trace is seen being
  /// drawn rather than arriving already complete.
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final status = parameter.status;
    final flagged = status.needsAttention;
    final color = status.color;

    // Same glass, same radius, same tinting rules as the Trident cards. The
    // section differs in what it *contains* — a trace instead of a gauge —
    // not in what it is made of.
    return GlassPanel(
      radius: AppSpacing.radiusLg,
      padding: const EdgeInsets.all(AppSpacing.lg),
      tint: flagged ? color : null,
      tintStrength: 0.16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            parameter.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  parameter.formattedValue,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 30,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: flagged ? color : AppColors.textPrimary,
                    shadows: [
                      Shadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                parameter.unit,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 54,
            child: DelayedProgress(
              delay: delay,
              duration: const Duration(milliseconds: 1000),
              builder: (context, progress) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _TrendPainter(
                    samples: parameter.history,
                    safeMin: parameter.safeMin,
                    safeMax: parameter.safeMax,
                    color: color,
                    progress: progress,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The probe trace, with its target band shaded behind it.
///
/// The band is what makes the line mean something: a reader who knows nothing
/// about reef chemistry can still see the trace leaving the zone it should be
/// sitting in.
class _TrendPainter extends CustomPainter {
  const _TrendPainter({
    required this.samples,
    required this.safeMin,
    required this.safeMax,
    required this.color,
    required this.progress,
  });

  final List<double> samples;
  final double safeMin;
  final double safeMax;
  final Color color;

  /// Draw-in progress, so the trace sweeps left to right on load.
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.length < 2) return;

    // Scale to the data *and* the target band, so both are always visible.
    // Scaling to the data alone would hide how far outside the band it sits.
    var lo = samples.reduce(math.min);
    var hi = samples.reduce(math.max);
    lo = math.min(lo, safeMin);
    hi = math.max(hi, safeMax);
    final pad = (hi - lo) * 0.14;
    lo -= pad;
    hi += pad;
    final span = hi - lo;
    if (span <= 0) return;

    double y(double v) => size.height - ((v - lo) / span) * size.height;
    double x(int i) => i / (samples.length - 1) * size.width;

    // Target limits, drawn as dashed rules rather than as a filled band.
    //
    // A fill — hard-edged or faded — sits *behind* the chart and reads as
    // either a rectangle or a smudge. Dashes read as what they are: reference
    // marks. Dashed rather than solid so they can never be mistaken for a
    // second data series.
    final guide = Paint()
      ..color = Colors.white.withValues(alpha: 0.20)
      ..strokeWidth = 1
      ..isAntiAlias = false;
    _dashedRule(canvas, y(safeMax), size.width, guide);
    _dashedRule(canvas, y(safeMin), size.width, guide);

    final path = Path()..moveTo(x(0), y(samples[0]));
    for (var i = 1; i < samples.length; i++) {
      path.lineTo(x(i), y(samples[i]));
    }

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));

    // Wash beneath the trace.
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.30),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Offset.zero & size),
    );

    // Glow, then the trace itself.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
        ..color = color.withValues(alpha: 0.55),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );

    canvas.restore();

    // Head of the trace — where the tank is right now.
    if (progress > 0.985) {
      final head = Offset(x(samples.length - 1), y(samples.last));
      canvas.drawCircle(
        head,
        5,
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)
          ..color = color.withValues(alpha: 0.7),
      );
      canvas.drawCircle(head, 2.6, Paint()..color = Colors.white);
    }
  }

  /// Snapped to a whole pixel so a 1px rule stays a crisp hairline instead of
  /// smearing across two rows of pixels.
  static void _dashedRule(Canvas canvas, double y, double width, Paint paint) {
    const dash = 3.0;
    const gap = 3.0;
    final row = y.roundToDouble() + 0.5;
    for (var x = 0.0; x < width; x += dash + gap) {
      canvas.drawLine(
        Offset(x, row),
        Offset(math.min(x + dash, width), row),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.samples != samples;
}
