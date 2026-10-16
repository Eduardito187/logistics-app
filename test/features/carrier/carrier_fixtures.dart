import 'package:logistics_app/core/api/models/assignment.dart';
import 'package:logistics_app/core/api/models/carrier.dart';
import 'package:logistics_app/core/api/models/carrier_status.dart';
import 'package:logistics_app/core/api/models/corridor_type.dart';
import 'package:logistics_app/core/api/models/settlement.dart';
import 'package:logistics_app/core/api/models/settlement_status.dart';
import 'package:logistics_app/core/api/models/tariff.dart';
import 'package:logistics_app/core/api/models/vehicle_class.dart';

// Fixtures compartidos del feature Transportista (modelos del contrato OpenAPI).

Carrier carrier({
  String id = 'c1',
  String name = 'Transportes Andinos',
  String taxId = '123456',
  CarrierStatus status = CarrierStatus.active,
}) => Carrier(
  id: id,
  name: name,
  taxId: taxId,
  status: status,
  ratingCount: 0,
  documents: const [],
);

Settlement settlement({
  String id = 's1',
  String carrierId = 'c1',
  SettlementStatus status = SettlementStatus.submitted,
  String period = '2026-03',
  int amountCents = 123456,
  String currency = 'BOB',
  String reference = 'REF-1',
  String? carrierName,
  String? disputeReason,
  String? paymentReference,
}) => Settlement(
  id: id,
  carrierId: carrierId,
  corridorFrom: 'LPZ',
  corridorTo: 'SCZ',
  corridorType: CorridorType.cdToCd,
  period: period,
  amountCents: amountCents,
  currency: currency,
  reference: reference,
  status: status,
  carrierName: carrierName,
  disputeReason: disputeReason,
  paymentReference: paymentReference,
  documents: const [],
);

Tariff tariff({
  String id = 't1',
  String carrierId = 'c1',
  String? carrierName = 'Transportes Andinos',
  CorridorType corridorType = CorridorType.cdToStore,
  VehicleClass vehicleClass = VehicleClass.truck,
  int priceCents = 500000,
  String currency = 'BOB',
}) => Tariff(
  id: id,
  carrierId: carrierId,
  carrierName: carrierName,
  corridorFrom: 'LPB',
  corridorTo: 'SCZ',
  corridorType: corridorType,
  vehicleClass: vehicleClass,
  priceCents: priceCents,
  currency: currency,
  effectiveFrom: DateTime(2026, 1, 15),
);

Assignment assignment({
  double volumeM3 = 12.5,
  VehicleClass vehicleClass = VehicleClass.truck,
  Tariff? tariffValue,
}) => Assignment(
  volumeM3: volumeM3,
  vehicleClass: vehicleClass,
  tariff: tariffValue,
);
