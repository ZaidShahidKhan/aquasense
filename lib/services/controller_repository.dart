import 'dart:math' as math;

import '../models/energy_bar.dart';
import '../models/water_parameter.dart';

/// Everything the dashboard needs from a reef controller.
///
/// The UI depends on this interface and never on the mock below it. Putting real
/// hardware or a cloud API behind the dashboard means writing a second
/// implementation and changing one line in `app.dart` — no screen, widget or
/// model has to be touched.
abstract interface class ControllerRepository {
  Future<EnergyBar> fetchEnergyBar();

  Future<List<WaterParameter>> fetchParameters();

  /// Asks the hardware to switch an outlet, returning its settled state.
  ///
  /// Returning the result rather than void matters: real relays can refuse, and
  /// the caller needs to reconcile against what actually happened rather than
  /// assume success.
  Future<bool> setOutletState({required String outletId, required bool isOn});
}

/// Hardcoded stand-in for a real controller.
///
/// Values are drawn from plausible mixed-reef husbandry so the screen reads as
/// a real tank rather than as lorem ipsum. Two parameters are deliberately out
/// of band: a dashboard where everything is always green never demonstrates
/// the thing a controller exists to do, which is tell you something is wrong.
class MockControllerRepository implements ControllerRepository {
  /// Simulated hardware round-trip, so loading and optimistic-update paths are
  /// exercised in the mock exactly as they would be against real relays.
  static const _latency = Duration(milliseconds: 260);

  @override
  Future<EnergyBar> fetchEnergyBar() async {
    await Future<void>.delayed(_latency);
    return const EnergyBar(
      rows: 2,
      columns: 4,
      outlets: [
        Outlet(
          id: 'o1',
          number: 1,
          label: 'Return Pump',
          row: 0,
          column: 0,
          isOn: true,
          ratedWatts: 42,
        ),
        Outlet(
          id: 'o2',
          number: 2,
          label: 'Protein Skimmer',
          row: 0,
          column: 1,
          isOn: true,
          ratedWatts: 31,
        ),
        Outlet(
          id: 'o3',
          number: 3,
          label: 'Display Lights',
          row: 0,
          column: 2,
          isOn: false,
          ratedWatts: 165,
        ),
        Outlet(
          id: 'o4',
          number: 4,
          label: 'Heater',
          row: 0,
          column: 3,
          isOn: true,
          ratedWatts: 78,
        ),
        Outlet(
          id: 'o5',
          number: 5,
          label: 'Circulation Pump',
          row: 1,
          column: 0,
          isOn: true,
          ratedWatts: 18,
        ),
        Outlet(
          id: 'o6',
          number: 6,
          label: 'ATO Pump',
          row: 1,
          column: 1,
          isOn: false,
          ratedWatts: 9,
        ),
        Outlet(
          id: 'o7',
          number: 7,
          label: 'Doser',
          row: 1,
          column: 2,
          isOn: true,
          ratedWatts: 12,
        ),
        Outlet(
          id: 'o8',
          number: 8,
          label: 'Spare',
          row: 1,
          column: 3,
          isOn: false,
          ratedWatts: 0,
        ),
      ],
    );
  }

  /// Builds a probe trace from three ingredients: the underlying signal, a
  /// damped random walk, and fine per-sample jitter.
  ///
  /// A pure sine or a straight ramp is instantly readable as generated. Real
  /// probes wander — the walk supplies that, damped so it drifts around the
  /// signal instead of escaping it — and they sit on a bed of sensor noise,
  /// which the jitter supplies.
  ///
  /// Seeded, so the same tank state renders identically on every run. A
  /// dashboard whose history reshuffles on each rebuild is worse than one that
  /// is obviously static.
  static List<double> _trace({
    required double Function(double t) signal,
    required double wander,
    required double noise,
    required int seed,
    int points = 72,
  }) {
    final rng = math.Random(seed);
    var walk = 0.0;
    return List.generate(points, (i) {
      final t = i / (points - 1);
      walk = walk * 0.96 + (rng.nextDouble() - 0.5) * wander;
      return signal(t) + walk + (rng.nextDouble() - 0.5) * noise;
    });
  }

  @override
  Future<List<WaterParameter>> fetchParameters() async {
    await Future<void>.delayed(_latency);

    // Two hours since the last titration — Trident runs on a schedule rather
    // than continuously, and the screen should say so.
    final lastTested = DateTime.now().subtract(const Duration(minutes: 47));

    // pH follows the tank's daily rhythm — down overnight, up once the lights
    // are on and photosynthesis is pulling CO2 out of the water.
    final ph = _trace(
      signal: (t) => 8.14 + math.sin(t * math.pi * 2 - 1.1) * 0.17,
      wander: 0.05,
      noise: 0.010,
      seed: 11,
    );
    // Climbing all window: the story behind the critical temperature alarm is
    // a heater that has stopped cutting out.
    final temp = _trace(
      signal: (t) => 79.1 + (82.4 - 79.1) * t,
      wander: 0.14,
      noise: 0.045,
      seed: 23,
    );
    // Sagging: top-off is not keeping pace with evaporation.
    final salinity = _trace(
      signal: (t) => 34.8 + (34.1 - 34.8) * t,
      wander: 0.05,
      noise: 0.014,
      seed: 37,
    );
    // ORP probes are the noisiest of the four in practice.
    final orp = _trace(
      signal: (t) => 384 + math.sin(t * math.pi * 2 + 0.6) * 14,
      wander: 5.0,
      noise: 2.0,
      seed: 53,
    );

    return [
      // ------------------------------------------------------------ Trident
      WaterParameter(
        id: 'alk',
        label: 'Alkalinity',
        unit: 'dKH',
        value: 8.4,
        safeMin: 8.0,
        safeMax: 9.5,
        warnMin: 7.0,
        warnMax: 11.0,
        scaleMin: 6,
        scaleMax: 12,
        decimals: 1,
        source: ParameterSource.trident,
        lastTested: lastTested,
      ),
      WaterParameter(
        id: 'ca',
        label: 'Calcium',
        unit: 'ppm',
        value: 435,
        safeMin: 400,
        safeMax: 450,
        warnMin: 380,
        warnMax: 470,
        scaleMin: 350,
        scaleMax: 500,
        source: ParameterSource.trident,
        lastTested: lastTested,
      ),
      WaterParameter(
        id: 'mg',
        label: 'Magnesium',
        unit: 'ppm',
        value: 1320,
        safeMin: 1250,
        safeMax: 1350,
        warnMin: 1200,
        warnMax: 1400,
        scaleMin: 1150,
        scaleMax: 1450,
        source: ParameterSource.trident,
        lastTested: lastTested,
      ),

      // --------------------------------------------------------- Live water
      WaterParameter(
        id: 'ph',
        label: 'pH',
        unit: 'pH',
        value: ph.last,
        safeMin: 7.9,
        safeMax: 8.4,
        warnMin: 7.7,
        warnMax: 8.5,
        scaleMin: 7.6,
        scaleMax: 8.6,
        decimals: 2,
        source: ParameterSource.probe,
        history: ph,
      ),
      // Below the ideal band — a slow drift a controller should surface before
      // it becomes a livestock problem.
      WaterParameter(
        id: 'sal',
        label: 'Salinity',
        unit: 'ppt',
        value: salinity.last,
        safeMin: 34.5,
        safeMax: 35.5,
        warnMin: 33.5,
        warnMax: 36.5,
        scaleMin: 33,
        scaleMax: 37,
        decimals: 1,
        source: ParameterSource.probe,
        history: salinity,
      ),
      // Past the tolerable band. A stuck heater is the classic way to lose a
      // tank overnight, so this is the alarm worth designing around.
      WaterParameter(
        id: 'temp',
        label: 'Temperature',
        unit: '°F',
        value: temp.last,
        safeMin: 76,
        safeMax: 80,
        warnMin: 74,
        warnMax: 81,
        scaleMin: 72,
        scaleMax: 86,
        decimals: 1,
        source: ParameterSource.probe,
        history: temp,
      ),
      WaterParameter(
        id: 'orp',
        label: 'ORP',
        unit: 'mV',
        value: orp.last,
        safeMin: 350,
        safeMax: 450,
        warnMin: 300,
        warnMax: 500,
        scaleMin: 250,
        scaleMax: 550,
        source: ParameterSource.probe,
        history: orp,
      ),
    ];
  }

  @override
  Future<bool> setOutletState({
    required String outletId,
    required bool isOn,
  }) async {
    await Future<void>.delayed(_latency);
    return isOn;
  }
}
