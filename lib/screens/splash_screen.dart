import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme.dart';
import '../services/feedback_player.dart';
import 'dashboard_screen.dart';
import '../widgets/reef_background.dart';
import '../dashboard_controller.dart';

/// The launch screen.
///
/// Doubles as the loading gate: the controller fetches while this is on
/// screen, so the dashboard is only ever built with data in hand and never has
/// to render a spinner of its own.
///
/// Shares [ReefBackground] with the dashboard rather than using a separate
/// splash image, so the hand-off cross-fades only the content — the backdrop
/// stays exactly where it is and the two screens cannot drift apart.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// Long enough for the brand to register. The mock returns in a fraction of
  /// this, so without a floor the splash would flash past unread.
  static const _minimumDisplay = Duration(milliseconds: 2600);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  /// The shared backdrop, decoded here rather than on the dashboard's first
  /// frame.
  static const _backdrop = 'assets/images/coral_background.png';

  /// Held so the ambience can be faded from [dispose], where there is no longer
  /// a context to read it from.
  FeedbackPlayer? _feedback;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  @override
  void dispose() {
    // Fades out as this route is torn down, which happens after the cross-fade
    // to the dashboard — so the waves carry over the transition and then ebb,
    // rather than cutting the moment the screen changes.
    unawaited(_feedback?.stopAmbience() ?? Future<void>.value());
    super.dispose();
  }

  Future<void> _boot() async {
    if (!mounted) return;
    final controller = context.read<DashboardController>();
    final feedback = _feedback = context.read<FeedbackPlayer>();

    // Started before the warm-up queue rather than inside it, so the sound
    // arrives with the screen instead of after the slowest preload.
    unawaited(feedback.startAmbience());

    // Everything that would otherwise stall the first interaction happens
    // here, behind the brand, where a pause is expected and invisible:
    //
    //  * the tap clip is read out of the bundle and prepared, and the vibrator
    //    is queried, so the first outlet press is not also a disk read;
    //  * the reef backdrop is decoded, so the dashboard's first paint is not
    //    unpacking a two-megabyte PNG while the user is already tapping.
    //
    // Run together rather than in sequence, so the slowest one sets the pace
    // instead of the total.
    await Future.wait([
      controller.load(),
      feedback.warmUp(),
      precacheImage(const AssetImage(_backdrop), context),
      Future<void>.delayed(SplashScreen._minimumDisplay),
    ]);

    if (!mounted) return;

    await Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 650),
        pageBuilder: (_, _, _) => const DashboardScreen(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.abyss,
      body: ReefBackground(
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: AppMotion.entranceCurve,
            builder: (context, t, child) {
              return Opacity(
                opacity: t,
                // Same gesture as the dashboard's cards, drawn out — nothing
                // is waiting on this and the mark is alone on screen, so it
                // can afford to arrive slowly.
                child: Transform.scale(scale: 0.94 + 0.06 * t, child: child),
              );
            },
            child: const _SplashMark(),
          ),
        ),
      ),
    );
  }
}

/// The coral mark above the wordmark.
///
/// Works here — where the circular badge version would not — because the
/// backdrop is already a photographic reef, so a cut-out coral reads as
/// something *in* the scene rather than a picture placed on top of one.
class _SplashMark extends StatelessWidget {
  const _SplashMark();

  static const _logo = 'assets/images/reef_alone.png';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          // Light pooling behind the coral, so it sits in the water instead of
          // hovering over it.
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 0.62,
              colors: [
                AppColors.accent.withValues(alpha: 0.20),
                AppColors.accent.withValues(alpha: 0.05),
                Colors.transparent,
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
          child: ShaderMask(
            // Fades the bottom edge out. A cut-out's hard base line is the
            // usual giveaway that something was pasted on.
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.white, Colors.transparent],
              stops: [0.0, 0.84, 1.0],
            ).createShader(rect),
            blendMode: BlendMode.dstIn,
            child: const Image(
              image: AssetImage(_logo),
              width: 180,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _Wordmark(),
      ],
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'AQUA',
              style: TextStyle(
                fontSize: 32,
                height: 1,
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w300,
                letterSpacing: 2.5,
                color: AppColors.textPrimary,
                shadows: [
                  Shadow(
                    color: AppColors.accent.withValues(alpha: 0.35),
                    blurRadius: 28,
                  ),
                ],
              ),
            ),
            Text(
              'SENSE',
              style: TextStyle(
                fontSize: 32,
                height: 1,
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.5,
                color: AppColors.accent,
                shadows: [
                  Shadow(
                    color: AppColors.accent.withValues(alpha: 0.5),
                    blurRadius: 30,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'SEE BEYOND THE SURFACE',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.6,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
