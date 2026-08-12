import 'package:flutter/material.dart';

import '../theme.dart';

/// The reef backdrop: a photographic seabed behind a contrast scrim.
///
/// Static by design. This previously carried an animated light overlay, which
/// meant a full-screen [CustomPaint] with three blurred paths repainting every
/// frame — behind a scrolling list that was already doing expensive
/// compositing. The photograph has its own light shafts, so the motion bought
/// very little and cost a great deal.
class ReefBackground extends StatefulWidget {
  const ReefBackground({super.key, required this.child});

  final Widget child;

  static const _asset = 'assets/images/coral_background.png';

  @override
  State<ReefBackground> createState() => _ReefBackgroundState();
}

class _ReefBackgroundState extends State<ReefBackground> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Decode ahead of the first paint so the dashboard never flashes an empty
    // background on launch.
    precacheImage(const AssetImage(ReefBackground._asset), context);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.abyss,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Isolated so scrolling content above never marks the backdrop
          // dirty — it never changes, so it should only ever be rasterised
          // once.
          const RepaintBoundary(
            child: DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(ReefBackground._asset),
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
              child: DecoratedBox(
                // Contrast wash. Kept as light as legibility allows: the cards
                // carry their own translucent fills, so this only has to
                // protect the header and section titles, which sit directly on
                // the image.
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    // 64% / 24% / 36% / 68% opacity.
                    colors: [
                      Color(0xA3050B14),
                      Color(0x3D050B14),
                      Color(0x5C050B14),
                      Color(0xAD050B14),
                    ],
                    stops: [0.0, 0.30, 0.66, 1.0],
                  ),
                ),
                child: SizedBox.expand(),
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}
