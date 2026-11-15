// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

/// Código del catálogo de errores de la API. Valor estable, legible por máquina, que los clientes.
/// usan para ramificar su lógica. Incluye el catálogo central (App\Http\Problem\ErrorCode) y códigos.
/// estables específicos de contexto (entregas, etiquetas, pedidos, vales). La lista puede crecer: un.
/// cliente debe tolerar un valor no enumerado (mostrar `detail`) en vez de romper.
///
@JsonEnum()
enum ProblemCode {
  @JsonValue('bad_request')
  badRequest('bad_request'),
  @JsonValue('invalid_idempotency_key')
  invalidIdempotencyKey('invalid_idempotency_key'),
  @JsonValue('unauthenticated')
  unauthenticated('unauthenticated'),
  @JsonValue('missing_credentials')
  missingCredentials('missing_credentials'),
  @JsonValue('invalid_credentials')
  invalidCredentials('invalid_credentials'),
  @JsonValue('device_revoked')
  deviceRevoked('device_revoked'),
  @JsonValue('session_superseded')
  sessionSuperseded('session_superseded'),
  @JsonValue('forbidden')
  forbidden('forbidden'),
  @JsonValue('insufficient_role')
  insufficientRole('insufficient_role'),
  @JsonValue('insufficient_scope')
  insufficientScope('insufficient_scope'),
  @JsonValue('not_found')
  notFound('not_found'),
  @JsonValue('method_not_allowed')
  methodNotAllowed('method_not_allowed'),
  @JsonValue('conflict')
  conflict('conflict'),
  @JsonValue('idempotency_key_in_progress')
  idempotencyKeyInProgress('idempotency_key_in_progress'),
  @JsonValue('idempotency_key_reused')
  idempotencyKeyReused('idempotency_key_reused'),
  @JsonValue('payload_too_large')
  payloadTooLarge('payload_too_large'),
  @JsonValue('unsupported_media_type')
  unsupportedMediaType('unsupported_media_type'),
  @JsonValue('validation_failed')
  validationFailed('validation_failed'),
  @JsonValue('business_rule_violation')
  businessRuleViolation('business_rule_violation'),
  @JsonValue('upgrade_required')
  upgradeRequired('upgrade_required'),
  @JsonValue('rate_limited')
  rateLimited('rate_limited'),
  @JsonValue('server_error')
  serverError('server_error'),
  @JsonValue('service_unavailable')
  serviceUnavailable('service_unavailable'),
  @JsonValue('invalid_route')
  invalidRoute('invalid_route'),
  @JsonValue('delivery_not_found')
  deliveryNotFound('delivery_not_found'),
  @JsonValue('node_reception_not_found')
  nodeReceptionNotFound('node_reception_not_found'),
  @JsonValue('evidence_unreadable')
  evidenceUnreadable('evidence_unreadable'),
  @JsonValue('evidence_upload_failed')
  evidenceUploadFailed('evidence_upload_failed'),
  @JsonValue('label_already_emitted')
  labelAlreadyEmitted('label_already_emitted'),
  @JsonValue('order_not_found')
  orderNotFound('order_not_found'),
  @JsonValue('voucher_not_found')
  voucherNotFound('voucher_not_found'),
  @JsonValue('voucher_expired')
  voucherExpired('voucher_expired'),
  @JsonValue('voucher_redeemed')
  voucherRedeemed('voucher_redeemed'),
  @JsonValue('voucher_held')
  voucherHeld('voucher_held'),
  @JsonValue('voucher_holder_mismatch')
  voucherHolderMismatch('voucher_holder_mismatch'),
  @JsonValue('voucher_revoked')
  voucherRevoked('voucher_revoked'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const ProblemCode(this.json);

  factory ProblemCode.fromJson(String json) =>
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
  static List<ProblemCode> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
