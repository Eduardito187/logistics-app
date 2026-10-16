import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/core/location/location_service.dart';
import 'package:logistics_app/core/location/truck_tracking_service.dart';
import 'package:logistics_app/core/offline/offline_queue.dart';
import 'package:logistics_app/features/driver/domain/repositories/fleet_repository.dart';
import 'package:logistics_app/features/driver/domain/usecases/conduct_checklist.dart';
import 'package:logistics_app/features/driver/presentation/controllers/driver_controllers.dart';

// Soporte compartido de los tests del chofer: constructores de modelos del
// contrato (fixtures), dobles de prueba de los servicios de plataforma (GPS,
// rastreo, cola offline, repositorio de flota) y helpers para montar pantallas
// con ProviderScope sin tocar Dio/GPS/hardware real.

// ---------------------------------------------------------------------------
// Fixtures: constructores de modelos del contrato OpenAPI.
// ---------------------------------------------------------------------------

Vehicle buildVehicle({String id = 'v1', String? plate = 'ABC-123'}) => Vehicle(
  id: id,
  plate: plate,
  capacityKg: 1000,
  capacityM3: 10,
  status: 'active',
);

Driver buildDriver({String id = 'd1', String? name = 'Juan Pérez'}) =>
    Driver(id: id, name: name, licenseNumber: 'LIC-1');

MyCrew buildMyCrew({
  Vehicle? vehicle,
  Driver? driver,
  List<Helpers> helpers = const [],
  Shift? shift,
}) => MyCrew(
  crewId: 'crew-1',
  date: DateTime(2026, 10, 15),
  vehicle: vehicle ?? buildVehicle(),
  driver: driver ?? buildDriver(),
  helpers: helpers,
  shift: shift,
);

DriverRouteStop buildStop({
  String id = 'stop-1',
  String shipmentId = 'ship-1',
  int sequence = 1,
  DriverRouteStopStatus status = DriverRouteStopStatus.pending,
  String? customerName = 'Tienda Central',
  String? orderReference,
  String? address,
  DateTime? etaAt,
  double? lat,
  double? lng,
}) => DriverRouteStop(
  id: id,
  shipmentId: shipmentId,
  sequence: sequence,
  status: status,
  customerName: customerName,
  orderReference: orderReference,
  address: address,
  etaAt: etaAt,
  lat: lat,
  lng: lng,
);

DriverRoute buildRoute({
  String id = 'route-1',
  String vehicleId = 'v1',
  DriverRouteStatus status = DriverRouteStatus.inProgress,
  int totalStops = 2,
  int completedStops = 1,
  int stopsRemaining = 1,
  List<DriverRouteStop>? stops,
  DriverRouteStop? currentStop,
}) => DriverRoute(
  id: id,
  vehicleId: vehicleId,
  routeDate: DateTime(2026, 10, 15),
  status: status,
  totalStops: totalStops,
  completedStops: completedStops,
  stopsRemaining: stopsRemaining,
  currentStop: currentStop,
  stops: stops ?? const [],
);

/// Ruta vacía (sin paradas pendientes) para que el autostart del rastreo no
/// intente arrancar; sirve de default en las pantallas con gate.
DriverRoute buildEmptyRoute() => buildRoute(
  status: DriverRouteStatus.completed,
  totalStops: 0,
  completedStops: 0,
  stopsRemaining: 0,
  stops: const [],
);

Delivery buildDelivery({
  String id = 'del-1',
  String shipmentId = 'ship-1',
  DeliveryStatus status = DeliveryStatus.loaded,
  List<ScanEvent> scans = const [],
  String? podConfirmation,
  FailureReason? failureReason,
}) => Delivery(
  id: id,
  shipmentId: shipmentId,
  vehicleId: 'v1',
  status: status,
  scans: scans,
  podConfirmation: podConfirmation,
  failureReason: failureReason,
);

VehicleCostSummary buildCostSummary({int? costPerKmCents = 500}) =>
    VehicleCostSummary(
      vehicleId: 'v1',
      from: DateTime(2026, 9, 15),
      to: DateTime(2026, 10, 15),
      fuelCents: 100000,
      maintenanceCents: 50000,
      expensesCents: 20000,
      totalCents: 170000,
      currency: 'BOB',
      kilometers: 1200,
      costPerKmCents: costPerKmCents,
    );

FuelPrice buildFuelPrice({
  int priceCents = 374,
  FuelType type = FuelType.diesel,
}) => FuelPrice(
  id: 'fp-1',
  fuelType: type,
  priceCents: priceCents,
  currency: 'BOB',
  effectiveFrom: DateTime(2026, 10, 1),
);

Refuel buildRefuel({
  double liters = 40.0,
  int totalCostCents = 15000,
  FuelType type = FuelType.diesel,
  int? odometerKm = 12000,
}) => Refuel(
  id: 'r1',
  vehicleId: 'v1',
  fuelType: type,
  liters: liters,
  pricePerLiterCents: 375,
  totalCostCents: totalCostCents,
  currency: 'BOB',
  fullTank: true,
  refueledAt: DateTime(2026, 10, 14, 9, 30),
  odometerKm: odometerKm,
);

OdometerReading buildReading({int km = 12345}) => OdometerReading(
  id: 'o1',
  vehicleId: 'v1',
  km: km,
  source: OdometerReadingSource.manual,
  readAt: DateTime(2026, 10, 14, 8),
);

// ---------------------------------------------------------------------------
// Dobles de prueba de servicios de plataforma.
// ---------------------------------------------------------------------------

/// GPS falso: concede el permiso de segundo plano sin tocar Geolocator y
/// devuelve el fix configurado (por defecto `null`, como en terreno sin señal).
class FakeLocationService extends LocationService {
  FakeLocationService({this.granted = true, this.fix});

  final bool granted;
  final GpsFix? fix;

  @override
  Future<bool> ensurePermission() async => granted;

  @override
  Future<bool> ensureBackgroundPermission() async => granted;

  @override
  Future<GpsFix?> current({
    Duration timeout = const Duration(seconds: 6),
  }) async => fix;

  @override
  Stream<GpsFix> stream({int distanceFilterMeters = 20}) =>
      const Stream.empty();
}

/// Rastreo del camión falso: no levanta el foreground service ni Geolocator.
/// Expone un estado fijo y cuenta los start/stop recibidos.
class FakeTruckTracking extends TruckTrackingService {
  FakeTruckTracking([this.initial = const TruckTrackingState()]);

  final TruckTrackingState initial;
  int startCount = 0;
  int stopCount = 0;

  @override
  TruckTrackingState build() => initial;

  @override
  Future<bool> start({required String shipmentId}) async {
    startCount++;
    // El autostart invoca start/stop desde `initState` (listen con
    // fireImmediately), así que la mutación del estado debe diferirse fuera de
    // la fase síncrona de build para no disparar "Tried to modify a provider
    // while the widget tree was building". El servicio real también muta su
    // estado recién tras un await (permisos/servicio en primer plano).
    await Future<void>.value();
    state = state.copyWith(active: true, shipmentId: shipmentId);
    return true;
  }

  @override
  Future<void> stop() async {
    stopCount++;
    await Future<void>.value();
    state = state.copyWith(active: false);
  }
}

/// Cola offline falsa: devuelve un desenlace fijo sin tocar la base de datos ni
/// la red, y registra las escrituras recibidas para poder inspeccionarlas.
class FakeOfflineQueue implements OfflineQueue {
  FakeOfflineQueue(this.outcome);

  final SubmitOutcome outcome;
  final List<Map<String, Object?>> submissions = [];
  String? lastKind;

  @override
  Future<SubmitOutcome> submit({
    required String kind,
    required Map<String, Object?> payload,
    required String label,
    DateTime? occurredAt,
    String? idempotencyKey,
  }) async {
    lastKind = kind;
    submissions.add(payload);
    return outcome;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Repositorio de flota falso para checklist/tripulación/choferes.
class FakeFleetRepository implements FleetRepository {
  FakeFleetRepository({
    this.crew,
    this.crewError,
    this.drivers = const [],
    this.checklistResult,
    this.checklistError,
  });

  final MyCrew? crew;
  final Object? crewError;
  final List<Driver> drivers;
  final Data4? checklistResult;
  final Object? checklistError;

  Map<String, bool>? lastItems;

  @override
  Future<MyCrew> getMyCrew(DateTime date) async {
    if (crewError != null) throw crewError!;
    return crew ?? buildMyCrew();
  }

  @override
  Future<List<Driver>> listActiveDrivers() async => drivers;

  @override
  Future<Data4?> conductPreTripChecklist(
    ConductPreTripChecklistRequest request,
  ) async {
    if (checklistError != null) throw checklistError!;
    return checklistResult;
  }
}

/// Caso de uso de checklist falso: devuelve el [result] configurado o lanza
/// [error], sin tocar el repositorio real.
class FakeConductChecklist extends ConductChecklist {
  FakeConductChecklist({this.result, this.error})
    : super(FakeFleetRepository());

  final Data4? result;
  final Object? error;
  Map<String, bool>? lastItems;

  @override
  Future<Data4?> call({
    required String vehicleId,
    required String driverId,
    required Map<String, bool> items,
    required DateTime performedOn,
    String? notes,
  }) async {
    lastItems = items;
    if (error != null) throw error!;
    return result;
  }
}

// ---------------------------------------------------------------------------
// Helpers de montaje.
// ---------------------------------------------------------------------------

/// Monta [child] bajo un [ProviderScope] con [overrides] y una MaterialApp.
///
/// `overrides` se tipa como `List<Object>` porque `flutter_riverpod` no expone
/// públicamente el tipo `Override`; se castea al pasarlo al `ProviderScope`.
Future<void> pumpScoped(
  WidgetTester tester, {
  required Widget child,
  List<Object> overrides = const [],
  bool settle = true,
  bool tall = false,
}) async {
  if (tall) {
    // Superficie alta para que los botones al pie de los ListView queden
    // visibles y tocables (evita "warning: tap missed").
    tester.view.physicalSize = const Size(1200, 3600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides.cast(),
      // Sin reintentos automáticos: un provider en error no debe reintentar en
      // los tests (dejaría timers pendientes y nunca asentaría el estado de
      // error que la UI debe mostrar).
      retry: (_, _) => null,
      child: MaterialApp(home: child),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

/// Overrides base para una pantalla envuelta en `DriverVehicleGate`: concede el
/// permiso de ubicación, usa un rastreo falso, provee la asignación del día (o
/// su error) y una ruta sin paradas pendientes (para que el autostart no intente
/// arrancar el servicio GPS). Devuelve `List<Object>` por la misma razón que
/// [pumpScoped].
List<Object> gateBase({MyCrew? crew, Object? crewError, DriverRoute? route}) {
  return [
    locationServiceProvider.overrideWithValue(FakeLocationService()),
    truckTrackingProvider.overrideWith(FakeTruckTracking.new),
    myCrewProvider.overrideWith((ref) async {
      if (crewError != null) throw crewError;
      return crew ?? buildMyCrew();
    }),
    driverRouteProvider.overrideWith((ref) async => route ?? buildEmptyRoute()),
  ];
}
