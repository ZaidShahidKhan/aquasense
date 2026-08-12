@Tags(['preview'])
library;

import 'dart:io';

import 'package:aquasense/theme.dart';
import 'package:aquasense/services/controller_repository.dart';
import 'package:aquasense/models/water_parameter.dart';
import 'package:aquasense/screens/dashboard_screen.dart';
import 'package:aquasense/widgets/parameter_card.dart';
import 'package:aquasense/dashboard_controller.dart';
import 'package:aquasense/screens/splash_screen.dart';
import 'package:aquasense/services/feedback_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Stands in for the real feedback player so rendering the splash never
/// reaches for an audio or vibration platform channel.
class _SilentFeedback implements FeedbackPlayer {
  @override
  Future<void> warmUp() async {}

  @override
  Future<void> tap() async {}

  @override
  Future<void> startAmbience() async {}

  @override
  Future<void> stopAmbience() async {}

  @override
  void dispose() {}
}

Widget _splashHarness() {
  return MultiProvider(
    providers: [
      Provider<ControllerRepository>(create: (_) => MockControllerRepository()),
      Provider<FeedbackPlayer>(create: (_) => _SilentFeedback()),
      ChangeNotifierProvider(
        create: (context) =>
            DashboardController(context.read<ControllerRepository>()),
      ),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAquaSenseTheme(),
      home: const SplashScreen(),
    ),
  );
}

/// The dashboard with its dependencies, but without the splash route in front
/// of it — these previews exist to review the dashboard, not the launch
/// sequence, and the audio player is deliberately left unprovided because
/// nothing reads it during a render.
Widget _dashboardHarness() {
  return MultiProvider(
    providers: [
      Provider<ControllerRepository>(create: (_) => MockControllerRepository()),
      ChangeNotifierProvider(
        create: (context) =>
            DashboardController(context.read<ControllerRepository>())..load(),
      ),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAquaSenseTheme(),
      home: const DashboardScreen(),
    ),
  );
}

/// Renders the dashboard to PNG at each breakpoint.
///
/// Run with `flutter test --update-goldens test/preview_test.dart` to refresh
/// the images in `test/goldens/`. This is a design tool, not an assertion —
/// it exists so the layout can be reviewed without a device attached.
/// Loads the app's own bundled faces so the previews show real typography.
///
/// The test environment ships no font, so anything unloaded renders as boxes.
/// These are the exact TTFs the app ships, read straight off disk, so a golden
/// is typographically identical to the build.
Future<void> _loadRealFonts() async {
  Future<void> load(String family, List<String> paths) async {
    final loader = FontLoader(family);
    for (final path in paths) {
      final file = File(path);
      if (!file.existsSync()) continue;
      final bytes = Uint8List.fromList(file.readAsBytesSync());
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }

  await load('LibreFranklin', [
    'assets/fonts/LibreFranklin-300.ttf',
    'assets/fonts/LibreFranklin-400.ttf',
    'assets/fonts/LibreFranklin-500.ttf',
    'assets/fonts/LibreFranklin-600.ttf',
    'assets/fonts/LibreFranklin-700.ttf',
  ]);
}

void main() {
  setUpAll(_loadRealFonts);

  Future<void> renderAt(
    WidgetTester tester, {
    required Size size,
    required String name,
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_dashboardHarness());

    // Real async work is suspended inside pump(), so the background PNG would
    // never finish decoding and the preview would render without it.
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 900));
    });

    // Mock repository latency, then step through the boot sequence.
    //
    // Small repeated pumps rather than a few large ones: each pump advances
    // the clock *and* renders one frame, so a single long jump fires the
    // staggered timers but leaves their animations with nowhere to tick. That
    // is what left the power board dark in an earlier revision.
    //
    // pumpAndSettle is no help here — a pending Timer schedules no frame, so
    // it returns before the later outlets have even started.
    await tester.pump(const Duration(milliseconds: 400));
    for (var i = 0; i < 14; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  testWidgets('splash', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_splashHarness());

    // Let the backdrop decode, then settle on the wordmark's entrance —
    // captured well before the boot timer hands off to the dashboard.
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 900));
    });
    await tester.pump(const Duration(milliseconds: 800));

    await expectLater(
      find.byType(SplashScreen),
      matchesGoldenFile('goldens/splash.png'),
    );

    // Run the hand-off through to completion so no timer outlives the test.
    // Fake time only advances via pump — a real delay would leave the boot
    // timer pending and fail the invariant check. Must exceed the splash's
    // minimum display, so this grows whenever that does.
    await tester.pump(const Duration(milliseconds: 2200));
    await tester.pumpAndSettle();
  });

  // True device viewport — what actually reaches the eye, and the only size
  // at which the background's framing can be judged.
  testWidgets('phone', (tester) async {
    await renderAt(tester, size: const Size(390, 844), name: 'phone');
  });

  // Over-tall viewport used only to review the full page in one image. The
  // background crops hard at this aspect ratio; that is an artefact of the
  // preview, not of the app.
  testWidgets('phone full page', (tester) async {
    await renderAt(tester, size: const Size(390, 1500), name: 'phone_full');
  });

  // The realistic floor: most small Androids sit at 360, an SE 2/3 at 375.
  // This is the narrowest width the app should be *designed* for.
  testWidgets('narrow phone', (tester) async {
    await renderAt(tester, size: const Size(360, 1400), name: 'phone_narrow');
  });

  // iPhone SE 1st gen / iPhone 5 territory. Rare enough in 2026 to be a
  // graceful-degradation case rather than a design target — this is the width
  // that decides whether the board's horizontal-scroll fallback ever fires.
  testWidgets('tiny phone', (tester) async {
    await renderAt(tester, size: const Size(320, 1400), name: 'phone_small');
  });

  // A large phone, and the one width above the compact breakpoint. Mobile is
  // the deliverable, but responsiveness is being assessed, so these have to be
  // looked at rather than assumed.
  testWidgets('large phone', (tester) async {
    await renderAt(tester, size: const Size(430, 1500), name: 'phone_large');
  });

  testWidgets('tablet', (tester) async {
    await renderAt(tester, size: const Size(834, 1180), name: 'tablet');
  });

  // Gauges at four points around the sweep, big enough to confirm the marker
  // tracks the arc rather than drifting off it.
  testWidgets('gauge detail', (tester) async {
    tester.view
      ..physicalSize = const Size(760, 260)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    WaterParameter at(String label, double value) => WaterParameter(
          id: label,
          label: label,
          unit: 'x',
          value: value,
          safeMin: 30,
          safeMax: 70,
          warnMin: 10,
          warnMax: 90,
          scaleMin: 0,
          scaleMax: 100,
          source: ParameterSource.trident,
        );

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAquaSenseTheme(),
        home: Scaffold(
          backgroundColor: AppColors.abyss,
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                for (final v in [5.0, 35.0, 65.0, 97.0]) ...[
                  Expanded(child: ParameterCard(parameter: at('$v', v))),
                  const SizedBox(width: 12),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 1400));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/gauge_detail.png'),
    );
  });
}
