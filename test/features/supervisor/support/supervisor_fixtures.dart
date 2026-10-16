import 'package:logistics_app/core/api/models/address_confidence_level.dart';
import 'package:logistics_app/core/api/models/alert.dart';
import 'package:logistics_app/core/api/models/alert_severity.dart';
import 'package:logistics_app/core/api/models/alert_type.dart';
import 'package:logistics_app/core/api/models/data7.dart';
import 'package:logistics_app/core/api/models/order_source.dart';
import 'package:logistics_app/core/api/models/plan.dart';
import 'package:logistics_app/core/api/models/plan_status.dart';
import 'package:logistics_app/core/api/models/planned_stop.dart';
import 'package:logistics_app/core/api/models/shipment.dart';
import 'package:logistics_app/core/api/models/shipment_status.dart';
import 'package:logistics_app/core/api/models/stop_eta.dart';
import 'package:logistics_app/core/api/models/vehicle_live.dart';
import 'package:logistics_app/core/api/models/vehicle_telemetry_summary.dart';

// Constructores de datos de ejemplo para los tests del supervisor. Mantienen los
// campos obligatorios en un solo lugar para que cada test pida solo lo que mira.

Shipment shipment(ShipmentStatus status, {String? id}) => Shipment(
  id: id ?? 's-${status.name}',
  source: OrderSource.sap,
  externalId: 'EXT',
  customerName: 'Cliente',
  addressText: 'Calle 1',
  addressConfidenceScore: 80,
  addressConfidenceLevel: AddressConfidenceLevel.high,
  status: status,
  lines: const [],
);

PlannedStop plannedStop({
  required int sequence,
  required int loadOrder,
  String shipmentId = 'ship',
  String id = 'stop',
  DateTime? etaAt,
  int? etaMinutes,
  String? lane,
}) => PlannedStop(
  id: id,
  shipmentId: shipmentId,
  sequence: sequence,
  loadOrder: loadOrder,
  etaAt: etaAt,
  etaMinutes: etaMinutes,
  lane: lane,
);

Plan plan({
  String id = 'p1',
  String vehicleId = 'v1',
  PlanStatus status = PlanStatus.published,
  DateTime? planDate,
  List<PlannedStop> stops = const [],
  bool withRouteGeometry = false,
}) => Plan(
  id: id,
  planDate: planDate ?? DateTime(2026, 3, 9),
  vehicleId: vehicleId,
  status: status,
  stops: stops,
  // routeGeometry se deja en null salvo que el test pida el trazado; se evita
  // construir el modelo generado directamente para no acoplar a su forma.
  routeGeometry: null,
);

Alert alert({
  String id = 'a1',
  String vehicleId = 'v1',
  AlertType type = AlertType.speeding,
  AlertSeverity severity = AlertSeverity.warning,
  Object? detail,
  DateTime? occurredAt,
  DateTime? acknowledgedAt,
}) => Alert(
  id: id,
  vehicleId: vehicleId,
  type: type,
  severity: severity,
  detail: detail,
  occurredAt: occurredAt ?? DateTime(2026, 3, 9, 8, 30),
  acknowledgedAt: acknowledgedAt,
);

VehicleLive vehicleLive({
  String vehicleId = 'v1',
  double lat = -16.5,
  double lng = -68.15,
  bool moving = true,
  double? speedKph,
  DateTime? recordedAt,
}) => VehicleLive(
  vehicleId: vehicleId,
  lat: lat,
  lng: lng,
  moving: moving,
  speedKph: speedKph,
  recordedAt: recordedAt ?? DateTime(2026, 3, 9, 9, 15),
);

VehicleTelemetrySummary vehicleSummary({
  String vehicleId = 'v1',
  double distanceM = 12500,
  int trips = 3,
  double maxSpeedKph = 82.4,
}) => VehicleTelemetrySummary(
  vehicleId: vehicleId,
  date: DateTime(2026, 3, 9),
  distanceM: distanceM,
  movingS: 3600,
  idleS: 600,
  trips: trips,
  maxSpeedKph: maxSpeedKph,
);

StopEta stopEta({
  required int sequence,
  String shipmentId = 'ship',
  DateTime? etaAt,
  int? etaMinutes,
}) => StopEta(
  shipmentId: shipmentId,
  sequence: sequence,
  etaAt: etaAt,
  etaMinutes: etaMinutes,
);

Data7 planEtaData({
  String planId = 'p1',
  PlanStatus status = PlanStatus.published,
  List<StopEta> stops = const [],
}) => Data7(planId: planId, status: status, stops: stops);
