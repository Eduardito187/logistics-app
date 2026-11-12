import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/logistics_api.dart';
import '../api/models/label_verification.dart';
import '../api/models/verify_label_request.dart';
import '../network/api_exception.dart';
import '../network/dio_client.dart';
import 'label_format_exception.dart';
import 'label_keys_notifier.dart';
import 'label_scan_result.dart';
import 'labels_open_mode.dart';
import 'label_verifier.dart';
import 'signed_label.dart';

// Se reexportan las piezas movidas por SRP ([LabelScanResult] y
// [LabelKeysNotifier] con `labelKeysProvider`) para no romper a quienes importan
// `labels/label_scanner.dart`.
export 'label_keys_notifier.dart';
export 'label_scan_result.dart';

/// Verificación offline de etiquetas (CLAUDE.md "Etiquetas QR"): parsea el QR y
/// comprueba la firma Ed25519 byte a byte contra las claves públicas que trae
/// la app, sin llamar al servidor.
///
/// Además, de forma OPCIONAL y best-effort, puede reportar/consultar la etiqueta
/// al backend (`POST /app/labels/verify`) para un contrahecheo del servidor. Ese
/// reporte nunca condiciona la verificación offline (offline-first).
class LabelScanner {
  // Un formal de inicialización con nombre no puede ser un campo privado
  // (`this._api` no es un parámetro con nombre válido), por eso se asigna a mano.
  // ignore: prefer_initializing_formals
  LabelScanner(this._verifier, {LogisticsApi? api, bool openMode = false})
    : _api = api,
      _openMode = openMode;

  final LabelVerifier? _verifier;
  final LogisticsApi? _api;

  /// Modo ABIERTO: el backend opera sin firma (`open:true`). En este modo NO se
  /// verifica Ed25519 de NINGUNA etiqueta (ni `k:0` nueva ni `k:1` ya impresa);
  /// se acepta en la capa de firma y la pertenencia la deciden los flujos de
  /// campo (por orden). Así una etiqueta impresa nunca se descarta por claves.
  final bool _openMode;

  /// `true` si la app tiene claves públicas configuradas para verificar.
  bool get canVerify => _verifier != null;

  /// Parsea el contenido del QR y verifica la firma OFFLINE. Lanza
  /// [LabelFormatException] si el QR no es una etiqueta válida.
  ///
  /// No toca la red: este es el camino que usa el escaneo en terreno y el que
  /// decide la aceptación del producto. Los llamadores existentes siguen igual.
  Future<LabelScanResult> scan(String qrContent) async {
    final label = SignedLabel.fromQrContent(qrContent);
    // MODO ABIERTO (backend `open:true`) o etiqueta ABIERTA individual (`k:0`):
    // NO se verifica Ed25519 y NO se necesitan claves públicas. No se rechaza por
    // firma; su autenticidad la deciden el registro/pertenencia aguas abajo (que
    // el `id` pertenezca al envío/ruta). En modo abierto esto cubre TAMBIÉN las
    // etiquetas firmadas viejas (`k:1`) ya impresas: nunca se descartan por un
    // tema de claves (offline-first, decisión del dueño).
    if (_openMode || label.payload.isOpen) {
      return LabelScanResult(
        label: label,
        verification: VerificationResult.open,
      );
    }
    final verifier = _verifier;
    if (verifier == null) {
      // Sin claves (ni embebidas, ni en caché, ni traídas): no se puede verificar.
      throw LabelFormatException(
        'La app no tiene claves públicas de etiquetas configuradas.',
      );
    }
    final result = await verifier.verify(label);
    return LabelScanResult(label: label, verification: result);
  }

  /// Igual que [scan], pero además —si hay cliente API— dispara el reporte de
  /// la etiqueta al backend (`POST /app/labels/verify`) SIN esperarlo.
  ///
  /// OFFLINE-FIRST (regla 4): devuelve al instante el resultado offline, que es
  /// el que decide; ningún llamador usa el veredicto del backend, así que el
  /// escaneo no paga ese viaje de red (con señal floja podía colgar segundos).
  /// Los errores del reporte se tragan. [LabelScanResult.backendVerification]
  /// queda `null`; quien necesite el veredicto usa [verifyWithBackend].
  Future<LabelScanResult> scanAndReport(String qrContent) async {
    final offline = await scan(qrContent);
    if (_api != null) {
      unawaited(
        verifyWithBackend(
          offline.label,
        ).then<void>((_) {}, onError: (Object _) {}),
      );
    }
    return offline;
  }

  /// Reporta/consulta una etiqueta ya parseada al backend y devuelve su
  /// veredicto. Lanza [ApiException] si no hay red o el servidor falla; lanza
  /// [StateError] si el scanner no tiene cliente API.
  Future<LabelVerification> verifyWithBackend(SignedLabel label) async {
    final api = _api;
    if (api == null) {
      throw StateError('El scanner no tiene cliente API configurado.');
    }
    try {
      final response = await api.execution.verifyLabel(
        body: buildVerifyRequest(label),
      );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Arma el cuerpo del `POST /app/labels/verify` desde una etiqueta firmada:
  /// el mensaje canónico exacto que se firmó, la firma y el id de la clave.
  static VerifyLabelRequest buildVerifyRequest(SignedLabel label) =>
      VerifyLabelRequest(
        payload: label.payload.canonical(),
        signature: encodeSignature(label.signature),
        keyId: label.payload.keyId,
      );

  /// Codifica la firma al formato que espera el backend: base64url SIN relleno,
  /// idéntico a cómo viaja en el campo "s" del QR (ver [SignedLabel]).
  static String encodeSignature(List<int> signature) =>
      base64Url.encode(signature).replaceAll('=', '');
}

/// Scanner con verificación Ed25519 offline, construido con las claves vigentes
/// (embebidas + caché + backend). Solo se consideran claves de 32 bytes.
final labelScannerProvider = Provider<LabelScanner>((ref) {
  final keys = ref.watch(labelKeysProvider);
  final openMode = ref.watch(labelsOpenModeProvider);
  final valid = <int, List<int>>{
    for (final entry in keys.entries)
      if (entry.value.length == 32) entry.key: entry.value,
  };
  // El cliente API viaja por ref: habilita el reporte best-effort al backend sin
  // romper la API pública `labelScannerProvider.scan`.
  final api = ref.watch(logisticsApiProvider);
  if (valid.isEmpty) {
    return LabelScanner(null, api: api, openMode: openMode);
  }
  return LabelScanner(LabelVerifier(valid), api: api, openMode: openMode);
});
