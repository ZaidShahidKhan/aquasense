import 'package:flutter/material.dart';

import '../theme.dart';
import 'glass_panel.dart';
import '../models/energy_bar.dart';
import 'outlet_socket.dart';

/// The digital twin of the physical power bar.
///
/// One chassis with eight receptacles set into it — not eight cards in a
/// container. The arrangement always comes from [EnergyBar.rows] /
/// [EnergyBar.columns] and never from hardcoded layout, so matching a
/// different bar is a data change.
class PowerBarView extends StatelessWidget {
  const PowerBarView({
    super.key,
    required this.bar,
    required this.onToggle,
    required this.isPending,
    this.energizeStart = Duration.zero,
  });

  final EnergyBar bar;
  final void Function(String outletId) onToggle;
  final bool Function(String outletId) isPending;

  /// When the first outlet lights up, measured from build.
  final Duration energizeStart;

  @override
  Widget build(BuildContext context) {
    // Smoked glass rather than opaque plastic: the chassis still reads as a
    // housing, but the reef carries through it so the board belongs to the
    // scene instead of sitting on top of it.
    return GlassPanel(
      radius: AppSpacing.radiusLg,
      opacity: 0.66,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ChassisHeader(bar: bar),
          const SizedBox(height: AppSpacing.lg),
          _SocketBoard(
            bar: bar,
            onToggle: onToggle,
            isPending: isPending,
            energizeStart: energizeStart,
          ),
        ],
      ),
    );
  }
}

/// The receptacles, always in the chassis's true arrangement.
class _SocketBoard extends StatelessWidget {
  const _SocketBoard({
    required this.bar,
    required this.onToggle,
    required this.isPending,
    required this.energizeStart,
  });

  final EnergyBar bar;
  final void Function(String outletId) onToggle;
  final bool Function(String outletId) isPending;
  final Duration energizeStart;

  /// Gap between one outlet lighting and the next.
  static const _energizeStep = Duration(milliseconds: 70);

  /// Below this the sockets would shrink past the point of being convincing,
  /// so the board scrolls sideways instead of squashing. On anything from a
  /// 375pt phone upward this never triggers — it exists for the small ones.
  static const _minBoardWidth = 300.0;

  @override
  Widget build(BuildContext context) {
    // Rotating or reflowing on a narrow screen would fit more comfortably, but
    // the brief asks for the digital layout to reflect the physical positions,
    // and an outlet that moves when the screen narrows cannot be matched to
    // the wall.
    final grid = bar.grid;

    final board = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < grid.length; r++) ...[
          if (r > 0) const SizedBox(height: AppSpacing.md),
          // A recessed channel per row. Without it the receptacles float on
          // the chassis and the board looks assembled rather than moulded.
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md,
              horizontal: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              color: Colors.black.withValues(alpha: 0.22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.045)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var c = 0; c < grid[r].length; c++) ...[
                  if (c > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _Cell(
                      outlet: grid[r][c],
                      onToggle: onToggle,
                      isPending: isPending,
                      // Reading order across the chassis, so the bar lights up
                      // left to right and top to bottom.
                      energizeDelay: energizeStart +
                          _energizeStep * (r * grid[r].length + c),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _minBoardWidth) return board;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: _minBoardWidth, child: board),
        );
      },
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.outlet,
    required this.onToggle,
    required this.isPending,
    required this.energizeDelay,
  });

  final Outlet? outlet;
  final void Function(String outletId) onToggle;
  final bool Function(String outletId) isPending;
  final Duration energizeDelay;

  @override
  Widget build(BuildContext context) {
    final o = outlet;
    // A chassis position with no outlet still occupies space, so the physical
    // arrangement survives.
    if (o == null) return const SizedBox.shrink();

    // Isolated so an outlet lighting up repaints only itself, not the other
    // seven and the chassis around them.
    return RepaintBoundary(
      child: OutletSocket(
        outlet: o,
        isPending: isPending(o.id),
        onToggle: () => onToggle(o.id),
        energizeDelay: energizeDelay,
      ),
    );
  }
}

/// Top of the chassis: a live LED and the aggregate draw, nothing else.
class _ChassisHeader extends StatelessWidget {
  const _ChassisHeader({required this.bar});

  final EnergyBar bar;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Spacer(),
        TweenAnimationBuilder<double>(
          // Begins at zero so the total counts up on first build; afterwards
          // TweenAnimationBuilder animates from the current value, so toggling
          // still runs from wherever the number happens to be.
          tween: Tween(begin: 0, end: bar.totalWatts),
          duration: const Duration(milliseconds: 1100),
          curve: Curves.easeOutCubic,
          builder: (context, watts, _) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  watts.round().toString(),
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 30,
                    height: 1,
                    // Same weight as every other reading. A Light cut here
                    // reads as a different typeface next to the bold numerals
                    // on the cards and the sockets.
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.5,
                    color: AppColors.textPrimary,
                    shadows: [
                      Shadow(
                        color: AppColors.accent.withValues(alpha: 0.45),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'W',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  '${(watts / kMainsVoltage).toStringAsFixed(1)} A',
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

