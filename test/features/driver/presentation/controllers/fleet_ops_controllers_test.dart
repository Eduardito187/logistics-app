import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/features/driver/data/repositories/fleet_ops_repository_impl.dart';
import 'package:logistics_app/features/driver/domain/repositories/fleet_ops_repository.dart';
import 'package:logistics_app/features/driver/presentation/controllers/driver_controllers.dart';
import 'package:logistics_app/features/driver/presentation/controllers/fleet_ops_controllers.dart';

// Rangos de fechas con los que el chofer pide el historial del vehículo: el
// teléfono NO baja años de registros para pintar diez filas ni para una resta.

/// Repositorio de flota que anota el rango con el que se le pidió el historial
/// (sin tocar la red). El resto del contrato no se usa en estos tests.
class _RecordingFleetOpsRepository implements FleetOpsRepository {
  DateTime? refuelsFrom;
  DateTime? refuelsTo;
  DateTime? readingsFrom;
  DateTime? readingsTo;
  String? lastVehicleId;

  @override
  Future<List<Refuel>> listVehicleRefuels({
    required String vehicleId,
    required DateTime from,
    required DateTime to,
  }) async {
    lastVehicleId = vehicleId;
    refuelsFrom = from;
    refuelsTo = to;
    // Camión sin actividad reciente: lista vacía, no un error.
    return const [];
  }

  @override
  Future<List<OdometerReading>> listOdometerReadings({
    required String vehicleId,
    required DateTime from,
    required DateTime to,
  }) async {
    lastVehicleId = vehicleId;
    readingsFrom = from;
    readingsTo = to;
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProviderContainer _container(_RecordingFleetOpsRepository repo) {
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      assignedVehicleIdProvider.overrideWithValue('v1'),
      fleetOpsRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('rangos', () {
    test('todayRange es un solo día de calendario a medianoche local', () {
      final range = todayRange(DateTime(2026, 11, 12, 17, 43));
      expect(range.from, DateTime(2026, 11, 12));
      expect(range.to, DateTime(2026, 11, 12));
      // Medianoche local exacta: `DateQueryInterceptor` lo manda como `Y-m-d`.
      expect(range.from.hour, 0);
      expect(range.from.isUtc, isFalse);
    });

    test('recentRange cubre los últimos 30 días hasta hoy', () {
      final range = recentRange(DateTime(2026, 11, 12, 17, 43));
      expect(recentHistoryDays, 30);
      expect(range.to, DateTime(2026, 11, 12));
      expect(range.from, DateTime(2026, 10, 13));
    });
  });

  test('las cargas recientes se piden por los últimos 30 días', () async {
    final repo = _RecordingFleetOpsRepository();
    final container = _container(repo);

    final refuels = await container.read(vehicleRefuelsProvider.future);

    expect(refuels, isEmpty);
    expect(repo.lastVehicleId, 'v1');
    final expected = recentRange();
    expect(repo.refuelsFrom, expected.from);
    expect(repo.refuelsTo, expected.to);
  });

  test('las lecturas recientes se piden por los últimos 30 días', () async {
    final repo = _RecordingFleetOpsRepository();
    final container = _container(repo);

    final readings = await container.read(
      vehicleOdometerReadingsProvider.future,
    );

    expect(readings, isEmpty);
    final expected = recentRange();
    expect(repo.readingsFrom, expected.from);
    expect(repo.readingsTo, expected.to);
  });

  test('los km de hoy piden solo el día de hoy', () async {
    final repo = _RecordingFleetOpsRepository();
    final container = _container(repo);

    await container.read(todayOdometerReadingsProvider.future);

    final today = todayRange();
    expect(repo.readingsFrom, today.from);
    expect(repo.readingsTo, today.to);
    expect(repo.readingsFrom, repo.readingsTo);
  });
}
