import 'package:flutter/material.dart';

import '../theme.dart';

/// Health of a single reading.
enum ParameterStatus {
  ok,
  warning,
  critical;

  bool get needsAttention => this != ParameterStatus.ok;
}

/// Where a reading comes from, which decides how it can honestly be drawn.
enum ParameterSource {
  /// Automated titration unit. Runs a chemical test on a schedule, so these are
  /// discrete results hours apart — never a continuous line.
  trident,

  /// Continuously sampled probe. A trend line is meaningful here because the
  /// signal really is continuous.
  probe,
}

/// The one place a parameter's health becomes a colour, so a gauge and a trend
/// line can never disagree about what "warning" looks like.
extension ParameterStatusColor on ParameterStatus {
  Color get color => switch (this) {
        ParameterStatus.ok => AppColors.accent,
        ParameterStatus.warning => AppColors.warning,
        ParameterStatus.critical => AppColors.critical,
      };
}

/// One measured water chemistry value, with the bands that give it meaning.
///
/// A bare number is useless to anyone who does not already know reef chemistry:
/// "435 ppm" only reads as good or bad against a target range. Every parameter
/// therefore carries its own bands and reports its own status rather than
/// leaving that judgement to the widget layer.
@immutable
class WaterParameter {
  const WaterParameter({
    required this.id,
    required this.label,
    required this.unit,
    required this.value,
    required this.safeMin,
    required this.safeMax,
    required this.warnMin,
    required this.warnMax,
    required this.scaleMin,
    required this.scaleMax,
    required this.source,
    this.decimals = 0,
    this.history = const [],
    this.lastTested,
  });

  final String id;
  final String label;
  final String unit;
  final double value;

  /// Ideal band. Inside this is [ParameterStatus.ok].
  final double safeMin;
  final double safeMax;

  /// Tolerable band. Outside this is [ParameterStatus.critical].
  final double warnMin;
  final double warnMax;

  /// Full extent of the ring gauge, so the marker has somewhere to travel.
  final double scaleMin;
  final double scaleMax;

  final ParameterSource source;
  final int decimals;

  /// Recent samples, oldest first. Populated for probes only — a titration
  /// result has nothing continuous to plot.
  final List<double> history;

  /// When the titration last ran. Null for probes, which are always current.
  final DateTime? lastTested;

  ParameterStatus get status {
    if (value < warnMin || value > warnMax) return ParameterStatus.critical;
    if (value < safeMin || value > safeMax) return ParameterStatus.warning;
    return ParameterStatus.ok;
  }

  String get formattedValue => value.toStringAsFixed(decimals);

  /// Where the reading sits across the full scale, 0.0–1.0.
  double get scalePosition => _fraction(value);

  double _fraction(double v) {
    final span = scaleMax - scaleMin;
    if (span <= 0) return 0;
    return ((v - scaleMin) / span).clamp(0.0, 1.0);
  }
}
