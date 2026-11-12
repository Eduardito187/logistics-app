import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:logistics_app/core/api/models/assignment.dart';
import 'package:logistics_app/core/api/models/carrier.dart';
import 'package:logistics_app/core/api/models/corridor_type.dart';
import 'package:logistics_app/core/api/models/settlement.dart';
import 'package:logistics_app/core/api/models/tariff.dart';
import 'package:logistics_app/core/api/models/vehicle_class.dart';
import 'package:logistics_app/core/auth/session.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/core/offline/app_database.dart';
import 'package:logistics_app/core/offline/connectivity_notifier.dart';
import 'package:logistics_app/core/offline/sync_queue_provider.dart';
import 'package:logistics_app/features/carrier/domain/repositories/carrier_repository.dart';

/// Conectividad fija (siempre en línea) sin tocar el plugin connectivity_plus.
class _StubConnectivity extends ConnectivityNotifier {
  @override
  Future<bool> build() async => true;
}

/// Overrides para que el [SyncBadge] de las AppBars renderice sin Drift ni el
/// plugin de conectividad.
List<Override> syncBadgeOverrides() => [
  syncQueueProvider.overrideWith((ref) => Stream.value(<OutboxAction>[])),
  connectivityProvider.overrideWith(_StubConnectivity.new),
];

/// Sesión fija (rol + abilities) sin pasar por el login real.
class StubSessionNotifier extends SessionNotifier {
  StubSessionNotifier(this.session);

  final Session? session;

  @override
  Session? build() => session;
}

/// Override de la sesión con el rol y las abilities dados.
Override sessionOverride({
  required UserRole role,
  List<String> abilities = const [],
}) => sessionProvider.overrideWith(
  () => StubSessionNotifier(
    Session(userName: 'test.${role.name}', role: role, abilities: abilities),
  ),
);

/// Sesión de OFICINA: puede aprobar y marcar como pagada (`planning:write`).
Override officeSessionOverride() => sessionOverride(
  role: UserRole.supervisor,
  abilities: const ['planning:write', 'carriers:read', 'execution:read'],
);

/// Sesión del TRANSPORTISTA: solo puede disputar (`carriers:write`).
Override carrierSessionOverride() => sessionOverride(
  role: UserRole.carrier,
  abilities: const ['carriers:write', 'execution:read', 'tracking:read'],
);

/// Repositorio del transportista controlable por los tests (sin Dio).
class FakeCarrierRepository implements CarrierRepository {
  FakeCarrierRepository({
    this.onListCarriers,
    this.onListSettlements,
    this.onGetSettlement,
    this.onApprove,
    this.onDispute,
    this.onPay,
    this.onGetTariff,
    this.onAssignForVolume,
    this.onCheapestTariff,
  });

  Future<List<Carrier>> Function()? onListCarriers;
  Future<List<Settlement>> Function(String carrierId)? onListSettlements;
  Future<Settlement> Function(String settlementId)? onGetSettlement;
  Future<void> Function(String settlementId)? onApprove;
  Future<void> Function(String settlementId, String reason)? onDispute;
  Future<void> Function(String settlementId, String reference)? onPay;
  Future<Tariff> Function()? onGetTariff;
  Future<Assignment> Function()? onAssignForVolume;
  Future<Tariff> Function()? onCheapestTariff;

  int approveCalls = 0;
  int disputeCalls = 0;
  int payCalls = 0;
  String? lastDisputeReason;
  String? lastPaymentReference;

  /// Último corredor consultado (tarifa, asignación o más barata): sirve para
  /// verificar que el selector manda origen, destino y tipo coherentes.
  String? lastCorridorFrom;
  String? lastCorridorTo;
  CorridorType? lastCorridorType;

  @override
  Future<List<Carrier>> listCarriers() =>
      (onListCarriers ?? (() async => <Carrier>[]))();

  @override
  Future<List<Settlement>> listSettlements(String carrierId) =>
      (onListSettlements ?? ((_) async => <Settlement>[]))(carrierId);

  @override
  Future<Settlement> getSettlement(String settlementId) =>
      (onGetSettlement ??
      ((_) async => throw UnimplementedError('getSettlement')))(settlementId);

  @override
  Future<void> approveSettlement(String settlementId) async {
    approveCalls++;
    if (onApprove != null) await onApprove!(settlementId);
  }

  @override
  Future<void> disputeSettlement(String settlementId, String reason) async {
    disputeCalls++;
    lastDisputeReason = reason;
    if (onDispute != null) await onDispute!(settlementId, reason);
  }

  @override
  Future<void> paySettlement(
    String settlementId,
    String paymentReference,
  ) async {
    payCalls++;
    lastPaymentReference = paymentReference;
    if (onPay != null) await onPay!(settlementId, paymentReference);
  }

  @override
  Future<Tariff> getTariff({
    required String carrierId,
    required String corridorFrom,
    required String corridorTo,
    required CorridorType corridorType,
    required VehicleClass vehicleClass,
  }) {
    _recordCorridor(corridorFrom, corridorTo, corridorType);
    return (onGetTariff ??
        (() async => throw UnimplementedError('getTariff')))();
  }

  @override
  Future<Assignment> assignForVolume({
    required String corridorFrom,
    required String corridorTo,
    required CorridorType corridorType,
    required double volumeM3,
  }) {
    _recordCorridor(corridorFrom, corridorTo, corridorType);
    return (onAssignForVolume ??
        (() async => throw UnimplementedError('assignForVolume')))();
  }

  @override
  Future<Tariff> cheapestTariff({
    required String corridorFrom,
    required String corridorTo,
    required CorridorType corridorType,
  }) {
    _recordCorridor(corridorFrom, corridorTo, corridorType);
    return (onCheapestTariff ??
        (() async => throw UnimplementedError('cheapestTariff')))();
  }

  void _recordCorridor(String from, String to, CorridorType type) {
    lastCorridorFrom = from;
    lastCorridorTo = to;
    lastCorridorType = type;
  }
}
