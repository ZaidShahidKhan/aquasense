import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/controller_repository.dart';
import '../dashboard_controller.dart';
import '../screens/splash_screen.dart';
import '../services/feedback_player.dart';
import '../theme.dart';

/// Composition root.
///
/// This is the only place that names a concrete repository. Swapping the mock
/// for real hardware or a cloud API is a one-line change here — nothing in the
/// domain, state, or widget layers knows which implementation it is talking to.
class AquaSenseApp extends StatelessWidget {
  const AquaSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ControllerRepository>(
          create: (_) => MockControllerRepository(),
        ),
        // Lazy on purpose: nothing touches the audio platform channel until
        // the first outlet is actually tapped.
        Provider<FeedbackPlayer>(
          create: (_) => DeviceFeedback(),
          dispose: (_, player) => player.dispose(),
        ),
        ChangeNotifierProvider(
          create: (context) => DashboardController(
            context.read<ControllerRepository>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'AquaSense',
        debugShowCheckedModeBanner: false,
        theme: buildAquaSenseTheme(),
        home: const SplashScreen(),
      ),
    );
  }
}
