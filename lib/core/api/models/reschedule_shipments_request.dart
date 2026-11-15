// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'scope.dart';

part 'reschedule_shipments_request.g.dart';

@JsonSerializable()
class RescheduleShipmentsRequest {
  const RescheduleShipmentsRequest({
    required this.scope,
    required this.newDate,
    required this.windowStart,
    required this.windowEnd,
    this.notifyCustomer = false,
    this.reason,
  });

  factory RescheduleShipmentsRequest.fromJson(Map<String, Object?> json) =>
      _$RescheduleShipmentsRequestFromJson(json);

  /// EXACTAMENTE uno de shipment_ids, vehicle_id o city. `route_date` acota vehicle_id / city al día comprometido actual.
  final Scope scope;
  @JsonKey(name: 'new_date')
  final DateTime newDate;
  @JsonKey(name: 'window_start')
  final String windowStart;
  @JsonKey(name: 'window_end')
  final String windowEnd;
  final String? reason;

  /// Avisar al cliente de cada pedido reprogramado
  @JsonKey(name: 'notify_customer')
  final bool notifyCustomer;

  Map<String, Object?> toJson() => _$RescheduleShipmentsRequestToJson(this);
}
