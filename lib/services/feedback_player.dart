import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

/// Non-visual feedback for direct manipulation — the click and the buzz that
/// make a screen switch feel like a physical one.
///
/// An interface rather than direct plugin calls so the widgets never depend on
/// `audioplayers` or `vibration`, and so a test or a preview can supply a
/// silent implementation without pulling platform channels into the tree.
abstract interface class FeedbackPlayer {
  /// Does the expensive first-use work up front.
  ///
  /// Without this the very first [tap] pays for reading the clip out of the
  /// asset bundle, preparing the player, and querying the vibrator — which
  /// lands as a stall at the exact moment the user presses an outlet. Call it
  /// somewhere the delay is already expected: during the splash.
  Future<void> warmUp();

  /// A short click and tick, played when an outlet is switched.
  Future<void> tap();

  void dispose();
}

class DeviceFeedback implements FeedbackPlayer {
  static const _tap = 'sounds/tap.mp3';

  /// Short enough to read as a switch click rather than a notification buzz.
  static const _tapMillis = 28;

  /// Roughly a third of full power. A relay click is a tick, not a jolt.
  static const _tapAmplitude = 90;

  final AudioPlayer _player = AudioPlayer();

  bool _canVibrate = false;
  bool _canSetAmplitude = false;

  /// Resolved once and reused. Calling `play(AssetSource(...))` per tap makes
  /// the plugin re-resolve and re-decode the clip every time, which is what
  /// makes an outlet feel like it sticks under the finger.
  Future<void>? _loading;

  Future<void> _load() {
    return _loading ??= () async {
      _canVibrate = await Vibration.hasVibrator();
      _canSetAmplitude = await Vibration.hasAmplitudeControl();
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setVolume(0.6);
      await _player.setSource(AssetSource(_tap));
    }();
  }

  @override
  Future<void> warmUp() async {
    try {
      // Bounded, so a device with no working audio backend delays the splash
      // by seconds at worst rather than holding it forever.
      await _load().timeout(const Duration(seconds: 3));
    } catch (_) {
      // Nothing to do — tap() will retry and fail quietly if it comes to it.
    }
  }

  @override
  Future<void> tap() async {
    // Fired first and never awaited: the motor should move with the finger
    // rather than after an audio round trip.
    if (_canVibrate) {
      if (_canSetAmplitude) {
        Vibration.vibrate(duration: _tapMillis, amplitude: _tapAmplitude);
      } else {
        Vibration.vibrate(duration: _tapMillis);
      }
    }

    try {
      await _load();
      // Rewind and replay the clip already in memory.
      await _player.seek(Duration.zero);
      await _player.resume();
    } catch (_) {
      // Feedback, not function. A missing codec, a denied audio focus or a
      // silent-mode device must never stop an outlet from switching.
    }
  }

  @override
  void dispose() => _player.dispose();
}
