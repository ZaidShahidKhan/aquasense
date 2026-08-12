import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme.dart';
import '../models/water_parameter.dart';
import '../dashboard_controller.dart';
import '../widgets/entrance.dart';
import '../widgets/live_water_card.dart';
import '../widgets/parameter_card.dart';
import '../widgets/power_bar_view.dart';
import '../widgets/reef_background.dart';

/// The dashboard.
///
/// Assumes its data is already loaded — the splash awaits [DashboardController.load]
/// before pushing this route, so there is no in-page loading state to render.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DashboardController>();

    return Scaffold(
      backgroundColor: AppColors.abyss,
      body: ReefBackground(
        child: SafeArea(
          child: _DashboardBody(
            controller: controller,
            formFactor: FormFactor.of(context),
          ),
        ),
      ),
    );
  }
}

/// The screen's boot sequence, in one place.
///
/// Sections arrive in the order the eye should read them — health first, then
/// trends, then controls — and each element's own animation is keyed to the
/// same clock so nothing sweeps or draws before it is visible. The whole
/// sequence lands in under two seconds.
abstract final class _Boot {
  static const tridentTitle = Duration(milliseconds: 70);
  static const tridentCards = Duration(milliseconds: 130);
  static const tridentStep = Duration(milliseconds: 60);

  static const liveTitle = Duration(milliseconds: 300);
  static const liveCards = Duration(milliseconds: 360);
  static const liveStep = Duration(milliseconds: 55);

  static const boardTitle = Duration(milliseconds: 570);
  static const board = Duration(milliseconds: 630);

  /// The bar powers up last, once its chassis has settled.
  static const energize = Duration(milliseconds: 800);
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.controller, required this.formFactor});

  final DashboardController controller;
  final FormFactor formFactor;

  @override
  Widget build(BuildContext context) {
    final bar = controller.bar;
    final pad = formFactor.isCompact ? AppSpacing.lg : AppSpacing.xl;
    final sectionGap =
        formFactor.isCompact ? AppSpacing.xl : AppSpacing.xxl;

    return Center(
      child: ConstrainedBox(
        // Keeps line lengths and tile sizes sane on a wide desktop window
        // instead of letting eight outlets stretch across 2000px.
        constraints: const BoxConstraints(maxWidth: 1240),
        child: ListView(
          padding: EdgeInsets.fromLTRB(pad, pad, pad, pad * 1.5),
          children: [
            Entrance(child: _Header(formFactor: formFactor)),
            SizedBox(height: sectionGap),

            // Titration results: discrete tests, hours apart, shown as gauges.
            Entrance(
              delay: _Boot.tridentTitle,
              child: _SectionTitle(
                title: 'Trident',
                trailing: _testedLabel(controller.tridentLastTested),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _TridentRow(
              parameters: controller.tridentParameters,
              compact: formFactor.isCompact,
            ),
            SizedBox(height: sectionGap),

            // Probes: continuously sampled, so a trend line is honest here.
            const Entrance(
              delay: _Boot.liveTitle,
              child: _SectionTitle(title: 'Live Water', trailing: 'Last 24h'),
            ),
            const SizedBox(height: AppSpacing.lg),
            _LiveWaterGrid(parameters: controller.liveParameters),
            SizedBox(height: sectionGap),

            const Entrance(
              delay: _Boot.boardTitle,
              child: _SectionTitle(
                title: 'Power Board',
                subtitle: 'Tap any outlet to switch it',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (bar != null)
              Entrance(
                delay: _Boot.board,
                child: PowerBarView(
                  bar: bar,
                  onToggle: controller.toggleOutlet,
                  isPending: controller.isPending,
                  energizeStart: _Boot.energize,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Trident runs on a schedule, so how stale the result is matters as much as
  /// the number itself.
  static String _testedLabel(DateTime? lastTested) {
    if (lastTested == null) return '';
    final elapsed = DateTime.now().difference(lastTested);
    if (elapsed.inMinutes < 60) return 'Tested ${elapsed.inMinutes}m ago';
    return 'Tested ${elapsed.inHours}h ago';
  }
}

/// The three titration parameters, always side by side — they are produced by
/// one test run and read as a set.
class _TridentRow extends StatelessWidget {
  const _TridentRow({required this.parameters, required this.compact});

  final List<WaterParameter> parameters;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    // No IntrinsicHeight here. The gauge is an AspectRatio, and asking a Row to
    // measure one produced a height far larger than the card's real content —
    // hence a dead gap under every label, invisible on a phone and obvious on a
    // tablet. All three cards hold the same structure, so they match heights on
    // their own without being forced to.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < parameters.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Entrance(
              delay: _Boot.tridentCards + _Boot.tridentStep * i,
              child: ParameterCard(
                parameter: parameters[i],
                compact: compact,
                // Same clock as the entrance, so the needle sweeps as the card
                // lands rather than before it.
                delay: _Boot.tridentCards + _Boot.tridentStep * i,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The four probes as a 2x2 of cards.
///
/// Four parameters divide evenly, and matching the Trident cards' shape is
/// what keeps the screen reading as one instrument rather than as two
/// unrelated sections stacked together.
class _LiveWaterGrid extends StatelessWidget {
  const _LiveWaterGrid({required this.parameters});

  final List<WaterParameter> parameters;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var start = 0; start < parameters.length; start += 2) ...[
          if (start > 0) const SizedBox(height: AppSpacing.md),
          // Same reasoning as the Trident row: identical structure means these
          // match heights without IntrinsicHeight forcing it, and forcing it
          // costs a second layout pass per row.
          Builder(
            builder: (context) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < 2; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: start + i < parameters.length
                        ? Builder(
                            builder: (context) {
                              final delay = _Boot.liveCards +
                                  _Boot.liveStep * (start + i);
                              return Entrance(
                                delay: delay,
                                child: LiveWaterCard(
                                  parameter: parameters[start + i],
                                  delay: delay,
                                ),
                              );
                            },
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.formFactor});

  final FormFactor formFactor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              'AQUA',
              style: TextStyle(
                fontSize: formFactor.isCompact ? 21 : 25,
                height: 1,
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w300,
                letterSpacing: 1.5,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'SENSE',
              style: TextStyle(
                fontSize: formFactor.isCompact ? 21 : 25,
                height: 1,
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'REEF CONTROLLER',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;

  /// Right-aligned context for the section — how stale the data is, or what
  /// window the traces cover.
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final sub = subtitle;
    final trail = trailing;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: AppColors.textPrimary,
                ),
              ),
              if (sub != null) ...[
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trail != null && trail.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.sm),
            child: Text(
              trail,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textTertiary,
              ),
            ),
          ),
      ],
    );
  }
}
