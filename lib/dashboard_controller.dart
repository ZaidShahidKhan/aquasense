import 'package:flutter/foundation.dart';

import '../services/controller_repository.dart';
import '../models/energy_bar.dart';
import '../models/water_parameter.dart';

/// Single source of truth for the dashboard screen.
///
/// A [ChangeNotifier] is the right weight here: one screen, one repository,
/// and a handful of booleans. Reaching for a heavier state solution would add
/// indirection without buying anything.
class DashboardController extends ChangeNotifier {
  DashboardController(this._repository);

  final ControllerRepository _repository;

  EnergyBar? _bar;
  List<WaterParameter> _parameters = const [];

  /// Outlets with a switch request still in flight, so the UI can show the
  /// relay as busy instead of pretending the change was instant.
  final Set<String> _pending = {};

  EnergyBar? get bar => _bar;
  List<WaterParameter> get parameters => _parameters;

  /// Titration results — discrete tests, shown as gauges.
  List<WaterParameter> get tridentParameters =>
      _parameters.where((p) => p.source == ParameterSource.trident).toList();

  /// Continuously sampled probes — shown with a trend line, because unlike a
  /// titration result the signal between samples is real.
  List<WaterParameter> get liveParameters =>
      _parameters.where((p) => p.source == ParameterSource.probe).toList();

  /// When the titration unit last ran, for the Trident section header.
  DateTime? get tridentLastTested {
    final stamps = _parameters
        .map((p) => p.lastTested)
        .whereType<DateTime>()
        .toList();
    if (stamps.isEmpty) return null;
    return stamps.reduce((a, b) => a.isAfter(b) ? a : b);
  }

  bool isPending(String outletId) => _pending.contains(outletId);

  Future<void> load() async {
    final results = await Future.wait([
      _repository.fetchEnergyBar(),
      _repository.fetchParameters(),
    ]);

    _bar = results[0] as EnergyBar;
    _parameters = results[1] as List<WaterParameter>;
    notifyListeners();
  }

  /// Flips an outlet, updating the UI immediately and reconciling against what
  /// the hardware reports.
  ///
  /// Optimistic because a relay round-trip is slow enough to feel broken if
  /// the socket does not light until it completes; reconciled because a relay
  /// is entitled to disagree.
  Future<void> toggleOutlet(String outletId) async {
    final current = _bar;
    if (current == null || _pending.contains(outletId)) return;

    final outlet = current.outlets.firstWhere((o) => o.id == outletId);
    final requested = !outlet.isOn;

    _pending.add(outletId);
    _bar = current.copyWithOutlet(outlet.copyWith(isOn: requested));
    notifyListeners();

    try {
      final settled = await _repository.setOutletState(
        outletId: outletId,
        isOn: requested,
      );
      if (settled != requested) {
        _bar = _bar!.copyWithOutlet(outlet.copyWith(isOn: settled));
      }
    } catch (_) {
      // Hardware refused or dropped out — put the socket back where it was
      // rather than leaving the UI asserting something untrue.
      _bar = _bar!.copyWithOutlet(outlet.copyWith(isOn: outlet.isOn));
    } finally {
      _pending.remove(outletId);
      notifyListeners();
    }
  }
}
