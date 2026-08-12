import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme.dart';
import '../services/feedback_player.dart';
import '../models/energy_bar.dart';
import 'socket_painter.dart';

/// One socket set into the energy bar.
///
/// Deliberately has no card of its own — no border, no fill, no shadow. Eight
/// bordered tiles read as a list of controls sitting on a tray; the hardware
/// is a single moulded slab with receptacles in it, and the chassis behind
/// these is what supplies the surface. Removing that per-outlet chrome is also
/// what buys the width for a socket large enough to be convincing.
class OutletSocket extends StatefulWidget {
  const OutletSocket({
    super.key,
    required this.outlet,
    required this.onToggle,
    this.isPending = false,
    this.energizeDelay = Duration.zero,
  });

  final Outlet outlet;
  final VoidCallback onToggle;

  /// A switch request is in flight to the hardware.
  final bool isPending;

  /// How long to wait before an already-on outlet lights up on first build.
  ///
  /// Staggered across the board so the bar reads as powering up outlet by
  /// outlet rather than snapping on fully formed.
  final Duration energizeDelay;

  @override
  State<OutletSocket> createState() => _OutletSocketState();
}

class _OutletSocketState extends State<OutletSocket>
    with SingleTickerProviderStateMixin {
  /// Drives every "is this live" visual: body, rim, contacts, watts.
  late final AnimationController _energize = AnimationController(
    vsync: this,
    // Always starts dark, even for an outlet that is already on, so the board
    // has something to power up *from*.
    value: 0,
    duration: AppMotion.energize,
  );

  Timer? _bootTimer;

  @override
  void initState() {
    super.initState();
    if (widget.outlet.isOn) {
      _bootTimer = Timer(widget.energizeDelay, () {
        if (mounted) _energize.animateTo(1, curve: Curves.easeOutCubic);
      });
    }
  }

  @override
  void didUpdateWidget(OutletSocket oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.outlet.isOn == oldWidget.outlet.isOn) return;

    // A tap during the boot sequence wins — cancel the scheduled light-up so
    // it cannot fire after the user has already switched the outlet off.
    _bootTimer?.cancel();

    if (widget.outlet.isOn) {
      _energize.animateTo(1, curve: Curves.easeOutCubic);
    } else {
      _energize.animateTo(0, curve: Curves.easeInCubic);
    }
  }

  @override
  void dispose() {
    _bootTimer?.cancel();
    _energize.dispose();
    super.dispose();
  }

  void _handleTap() {
    // Fire and forget: the switch must not wait on the click or the buzz.
    unawaited(context.read<FeedbackPlayer>().tap());
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    final outlet = widget.outlet;

    return Semantics(
      button: true,
      toggled: outlet.isOn,
      label: 'Outlet ${outlet.number}, ${outlet.label}',
      value: outlet.isOn
          ? 'On, drawing ${outlet.watts.round()} watts'
          : 'Off, drawing no power',
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // The socket takes whatever width the chassis can spare, so the
            // board scales smoothly instead of stepping between breakpoints.
            final socket = constraints.maxWidth.clamp(44.0, 86.0);
            final scale = socket / 68.0;

            return AnimatedBuilder(
              animation: _energize,
              builder: (context, _) {
                // A live outlet holds a steady glow. The only movement is the
                // transition between on and off.
                final glow = _energize.value;
                final live = glow;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SilkscreenNumber(
                      number: outlet.number,
                      glow: glow,
                      scale: scale,
                    ),
                    SizedBox(height: 5 * scale),
                    SizedBox(
                      width: socket,
                      height: socket,
                      child: CustomPaint(
                        painter: SocketPainter(
                          energized: glow,
                          groundUp: outlet.groundUp,
                        ),
                      ),
                    ),
                    SizedBox(height: 7 * scale),
                    // Live draw sits directly beneath its outlet, per the
                    // brief. Scaled by the energize value rather than animated
                    // separately, so the number counts up as the socket lights
                    // and falls back to zero as it dies — one source of truth
                    // for "how much of this outlet is on".
                    _WattReadout(
                      watts: outlet.ratedWatts * glow,
                      glow: glow,
                      scale: scale,
                    ),
                    SizedBox(height: 5 * scale),
                    _ToggleSwitch(
                      live: live,
                      isPending: widget.isPending,
                      scale: scale,
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// The outlet number as it appears on the physical bar.
class _SilkscreenNumber extends StatelessWidget {
  const _SilkscreenNumber({
    required this.number,
    required this.glow,
    required this.scale,
  });

  final int number;
  final double glow;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Text(
      number.toString().padLeft(2, '0'),
      style: TextStyle(
        fontFamily: AppFonts.display,
        fontSize: 11 * scale,
        height: 1,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: Color.lerp(
          AppColors.textTertiary,
          AppColors.accentSoft,
          glow,
        ),
      ),
    );
  }
}

/// The live power figure, counting rather than snapping between values.
class _WattReadout extends StatelessWidget {
  const _WattReadout({
    required this.watts,
    required this.glow,
    required this.scale,
  });

  final double watts;
  final double glow;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          watts.round().toString(),
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 17 * scale,
            height: 1,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: Color.lerp(
              AppColors.textTertiary,
              AppColors.accentSoft,
              glow,
            ),
          ),
        ),
        SizedBox(width: 2 * scale),
        Text(
          'W',
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 9.5 * scale,
            fontWeight: FontWeight.w600,
            color: Color.lerp(AppColors.textTertiary, AppColors.accent, glow),
          ),
        ),
      ],
    );
  }
}

/// The switch under each outlet.
///
/// Driven by the same [live] value as the socket, so the knob travels on the
/// identical curve as the receptacle lights up — the two read as one motion
/// rather than as a control and a separate reaction to it.
///
/// Knob position carries state independently of colour, so the switch stays
/// legible without relying on the cyan alone.
class _ToggleSwitch extends StatelessWidget {
  const _ToggleSwitch({
    required this.live,
    required this.isPending,
    required this.scale,
  });

  final double live;
  final bool isPending;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final height = 20.0 * scale;
    final width = height * 1.95;
    final knob = height - 4.5 * scale;

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height / 2),
          color: Color.lerp(
            AppColors.socketWell,
            AppColors.accentDim,
            live * 0.95,
          )!,
          border: Border.all(
            color: Color.lerp(
              Colors.white.withValues(alpha: 0.12),
              AppColors.accent.withValues(alpha: 0.85),
              live,
            )!,
          ),
          boxShadow: [
            if (live > 0.02)
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.35 * live),
                blurRadius: 10 * scale,
                spreadRadius: -2,
              ),
          ],
        ),
        child: Align(
          alignment: Alignment.lerp(
            Alignment.centerLeft,
            Alignment.centerRight,
            live,
          )!,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.2 * scale),
            child: SizedBox(
              width: knob,
              height: knob,
              child: isPending
                  ? Padding(
                      padding: EdgeInsets.all(2.5 * scale),
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5 * scale,
                        color: AppColors.accentSoft,
                      ),
                    )
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.lerp(
                          AppColors.textTertiary,
                          Colors.white,
                          live,
                        ),
                        boxShadow: [
                          if (live > 0.02)
                            BoxShadow(
                              color: AppColors.accentSoft
                                  .withValues(alpha: 0.6 * live),
                              blurRadius: 8 * scale,
                            ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
