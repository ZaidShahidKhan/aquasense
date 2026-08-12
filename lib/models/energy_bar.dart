import 'package:flutter/foundation.dart';

/// Nominal mains voltage, used to derive amps from watts.
///
/// North American reef controllers are 120 V; this becomes a per-bar property
/// once real hardware is connected.
const double kMainsVoltage = 120.0;

/// A single switched outlet on the energy bar.
///
/// [row] and [column] describe where the outlet physically sits on the
/// chassis. The UI never hardcodes an arrangement — it reads these — so
/// matching a different bar is a data change, not a layout rewrite.
@immutable
class Outlet {
  const Outlet({
    required this.id,
    required this.number,
    required this.label,
    required this.row,
    required this.column,
    required this.isOn,
    required this.ratedWatts,
  });

  final String id;

  /// Number silkscreened on the physical bar.
  final int number;

  /// What is plugged in, e.g. "Return Pump".
  final String label;

  /// Physical row on the chassis, 0-indexed from the top.
  final int row;

  /// Physical column on the chassis, 0-indexed from the left.
  final int column;

  final bool isOn;

  /// Draw while energized. An outlet that is switched off draws nothing, so
  /// this is the *rated* figure and [watts] is what is actually flowing.
  final double ratedWatts;

  /// Live draw. Zero when switched off — the whole point of the readout.
  double get watts => isOn ? ratedWatts : 0;

  Outlet copyWith({bool? isOn}) {
    return Outlet(
      id: id,
      number: number,
      label: label,
      row: row,
      column: column,
      isOn: isOn ?? this.isOn,
      ratedWatts: ratedWatts,
    );
  }
}

/// A physical switched power bar and everything plugged into it.
///
/// [rows] and [columns] describe the real chassis. The renderer builds its grid
/// from these, so a bar with a different outlet arrangement is a change to the
/// data source alone.
@immutable
class EnergyBar {
  const EnergyBar({
    required this.rows,
    required this.columns,
    required this.outlets,
  });

  final int rows;
  final int columns;
  final List<Outlet> outlets;

  double get totalWatts => outlets.fold(0, (sum, o) => sum + o.watts);

  /// The chassis as a grid, indexed `[row][column]`. Positions with no outlet
  /// are null so the renderer can leave a gap.
  List<List<Outlet?>> get grid {
    final result = List.generate(
      rows,
      (_) => List<Outlet?>.filled(columns, null),
    );
    for (final outlet in outlets) {
      if (outlet.row < rows && outlet.column < columns) {
        result[outlet.row][outlet.column] = outlet;
      }
    }
    return result;
  }

  EnergyBar copyWithOutlet(Outlet updated) {
    return EnergyBar(
      rows: rows,
      columns: columns,
      outlets: [
        for (final o in outlets) if (o.id == updated.id) updated else o,
      ],
    );
  }
}
