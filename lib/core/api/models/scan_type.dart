// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum ScanType {
  @JsonValue('PREPARATION')
  preparation('PREPARATION'),
  @JsonValue('LOAD')
  load('LOAD'),
  @JsonValue('UNLOAD')
  unload('UNLOAD'),
  @JsonValue('PROOF_OF_DELIVERY')
  proofOfDelivery('PROOF_OF_DELIVERY'),
  @JsonValue('NODE_RECEPTION')
  nodeReception('NODE_RECEPTION'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const ScanType(this.json);

  factory ScanType.fromJson(String json) =>
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
  static List<ScanType> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
