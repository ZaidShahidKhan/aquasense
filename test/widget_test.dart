import 'package:aquasense/services/controller_repository.dart';
import 'package:aquasense/models/energy_bar.dart';
import 'package:aquasense/models/water_parameter.dart';
import 'package:aquasense/dashboard_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Outlet', () {
    const outlet = Outlet(
      id: 'o1',
      number: 1,
      label: 'Return Pump',
      row: 0,
      column: 0,
      isOn: true,
      ratedWatts: 42,
    );

    test('draws its rated load while energized', () {
      expect(outlet.watts, 42);
    });

    test('draws nothing once switched off', () {
      expect(outlet.copyWith(isOn: false).watts, 0);
    });
  });

  group('EnergyBar', () {
    const bar = EnergyBar(
      rows: 2,
      columns: 4,
      outlets: [
        Outlet(id: '1', number: 1, label: 'A', row: 0, column: 0, isOn: true, ratedWatts: 100),
        Outlet(id: '2', number: 2, label: 'B', row: 0, column: 1, isOn: false, ratedWatts: 100),
        Outlet(id: '5', number: 5, label: 'E', row: 1, column: 0, isOn: true, ratedWatts: 80),
      ],
    );

    test('totals only what is actually drawing', () {
      expect(bar.totalWatts, 180);
    });

    test('places outlets on the grid by physical position', () {
      expect(bar.grid[0][0]?.number, 1);
      expect(bar.grid[1][0]?.number, 5);
      expect(bar.grid[1][3], isNull);
    });

    test('the grid matches the chassis, 2 rows of 4', () {
      expect(bar.grid.length, 2);
      expect(bar.grid.first.length, 4);
    });
  });

  group('WaterParameter', () {
    WaterParameter temp(double value) => WaterParameter(
          id: 'temp',
          label: 'Temperature',
          unit: '°F',
          value: value,
          safeMin: 76,
          safeMax: 80,
          warnMin: 74,
          warnMax: 81,
          scaleMin: 72,
          scaleMax: 86,
          decimals: 1,
          source: ParameterSource.probe,
        );

    test('inside the ideal band is ok', () {
      expect(temp(78).status, ParameterStatus.ok);
    });

    test('outside the ideal band but tolerable is a warning', () {
      expect(temp(80.5).status, ParameterStatus.warning);
    });

    test('beyond the tolerable band is critical', () {
      expect(temp(82.4).status, ParameterStatus.critical);
    });

    test('clamps the marker to the visible scale', () {
      expect(temp(200).scalePosition, 1.0);
      expect(temp(0).scalePosition, 0.0);
    });
  });

  group('DashboardController', () {
    test('splits titration results from continuous probes', () async {
      final controller = DashboardController(MockControllerRepository());
      await controller.load();

      expect(controller.tridentParameters, hasLength(3));
      expect(controller.liveParameters, hasLength(4));

      // Probes carry a trace; a titration result must not, because joining
      // tests hours apart with a line would assert data we do not have.
      expect(
        controller.liveParameters.every((p) => p.history.length > 1),
        isTrue,
      );
      expect(
        controller.tridentParameters.every((p) => p.history.isEmpty),
        isTrue,
      );
      expect(controller.tridentLastTested, isNotNull);
    });

    test('flags the problems seeded in the mock', () async {
      final controller = DashboardController(MockControllerRepository());
      await controller.load();

      final flagged =
          controller.parameters.where((p) => p.status.needsAttention);
      expect(flagged.map((p) => p.id), containsAll(['sal', 'temp']));
      expect(
        controller.parameters.firstWhere((p) => p.id == 'temp').status,
        ParameterStatus.critical,
      );
    });

    test('toggling an outlet updates the state and the total', () async {
      final controller = DashboardController(MockControllerRepository());
      await controller.load();

      final before = controller.bar!.totalWatts;
      await controller.toggleOutlet('o3'); // Display Lights, 165 W, starts off

      expect(
        controller.bar!.outlets.firstWhere((o) => o.id == 'o3').isOn,
        isTrue,
      );
      expect(controller.bar!.totalWatts, before + 165);
    });

    test('updates optimistically before the hardware settles', () async {
      final controller = DashboardController(MockControllerRepository());
      await controller.load();

      final future = controller.toggleOutlet('o1');
      // Already reflected in the UI while the relay request is in flight.
      expect(controller.bar!.outlets.first.isOn, isFalse);
      expect(controller.isPending('o1'), isTrue);

      await future;
      expect(controller.isPending('o1'), isFalse);
    });
  });
}
