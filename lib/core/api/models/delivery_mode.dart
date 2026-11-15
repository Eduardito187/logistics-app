// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

/// Derived. transfer = internal replenishment/transfer (source TRANSFER) to a node, never offered for counter pickup; store_pickup = customer order to a store/pickup point; home_delivery otherwise.
@JsonEnum()
enum DeliveryMode {
  @JsonValue('home_delivery')
  homeDelivery('home_delivery'),
  @JsonValue('store_pickup')
  storePickup('store_pickup'),
  @JsonValue('transfer')
  transfer('transfer'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const DeliveryMode(this.json);

  factory DeliveryMode.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;
  String toJson() {
    final value = json;
    if (value == null) {
      throw StateError(
        'Cannot convert enum value with null JSON representation to String. '
        'This usually happens for \$unknown or @JsonValue(null) entries.',
      );
    }
    return value as String;
  }

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<DeliveryMode> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
