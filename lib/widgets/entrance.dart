import 'dart:async';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Fades a child in after [delay], with a slight scale for depth.
///
/// It used to rise 22px as it faded. Vertical travel is the obvious way to
/// animate a list and the wrong one here: staggered across three sections,
/// every card drifts upward at a slightly different moment and the whole page
/// reads as unsettled. Scale keeps each element anchored to its own position,
/// so a stagger reads as things appearing rather than as things moving.
class Entrance extends StatefulWidget {
  const Entrance({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.entrance,
  );

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.entranceCurve,
    );

    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final t = curved.value;
        return Opacity(
          opacity: t,
          child: Transform.scale(
            // Very slight, and it grows rather than contracts — just enough to
            // give the fade some depth. The fade is the effect; the scale only
            // stops it looking like a dissolve.
            scale: 0.975 + 0.025 * t,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Drives a 0→1 value that starts after [delay].
///
/// Exists so an element's own animation can be lined up with its entrance. A
/// gauge that starts sweeping the instant it is built has already finished by
/// the time its card has faded in — the reader never sees the movement, only
/// the result.
class DelayedProgress extends StatefulWidget {
  const DelayedProgress({
    super.key,
    required this.duration,
    required this.builder,
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
  });

  final Duration delay;
  final Duration duration;
  final Curve curve;
  final Widget Function(BuildContext context, double t) builder;

  @override
  State<DelayedProgress> createState() => _DelayedProgressState();
}

class _DelayedProgressState extends State<DelayedProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: widget.curve);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, _) => widget.builder(context, curved.value),
    );
  }
}
