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

  /// Starts the splash ambience, looping until [stopAmbience].
  Future<void> startAmbience();

  /// Fades the ambience out and stops it.
  Future<void> stopAmbience();

  void dispose();
}

class DeviceFeedback implements FeedbackPlayer {
  static const _tap = 'sounds/tap.mp3';
  static const _ambience = 'sounds/waves.mp3';

  /// Short enough to read as a switch click rather than a notification buzz.
  static const _tapMillis = 28;

  /// Roughly a third of full power. A relay click is a tick, not a jolt.
  static const _tapAmplitude = 90;

  /// Under the tap click, so a toggle still reads clearly over it.
  static const _ambienceVolume = 0.45;

  final AudioPlayer _player = AudioPlayer();

  /// A second player. The tap sound drives its own player with seek/resume, so
  /// sharing one would have each sound cutting the other off.
  final AudioPlayer _ambiencePlayer = AudioPlayer();

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
  Future<void> startAmbience() async {
    try {
      // Plays once, not looped. The clip is about 1.2s against a 2.6s splash,
      // so the last stretch is silent — preferred over hearing the loop seam.
      await _ambiencePlayer.setReleaseMode(ReleaseMode.stop);
      await _ambiencePlayer.setVolume(_ambienceVolume);
      await _ambiencePlayer.play(AssetSource(_ambience));
    } catch (_) {
      // Atmosphere, not function — silence is an acceptable outcome.
    }
  }

  @override
  Future<void> stopAmbience() async {
    try {
      // Ramped down rather than cut, in case the splash is left before the clip
      // has finished — stopping mid-waveform is audible as a click.
      const steps = 8;
      for (var i = steps - 1; i >= 0; i--) {
        await _ambiencePlayer.setVolume(_ambienceVolume * i / steps);
        await Future<void>.delayed(const Duration(milliseconds: 45));
      }
      await _ambiencePlayer.stop();
      await _ambiencePlayer.setVolume(_ambienceVolume);
    } catch (_) {
      // Ignore — but still make sure it is not left playing.
      try {
        await _ambiencePlayer.stop();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _ambiencePlayer.dispose();
  }
}
