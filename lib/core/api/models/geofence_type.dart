// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum GeofenceType {
  @JsonValue('distribution_center')
  distributionCenter('distribution_center'),
  @JsonValue('store')
  store('store'),
  @JsonValue('authorized_zone')
  authorizedZone('authorized_zone'),
  @JsonValue('forbidden_zone')
  forbiddenZone('forbidden_zone'),
  @JsonValue('rest_area')
  restArea('rest_area'),
  @JsonValue('fuel_station')
  fuelStation('fuel_station'),
  @JsonValue('customer')
  customer('customer'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const GeofenceType(this.json);

  factory GeofenceType.fromJson(String json) =>
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
  static List<GeofenceType> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
