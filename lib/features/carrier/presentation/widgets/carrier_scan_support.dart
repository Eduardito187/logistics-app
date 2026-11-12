import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/labels/label_format_exception.dart';
import '../../../../core/labels/label_resolver.dart';
import '../../../../core/labels/label_scanner.dart';
import '../../../../core/labels/label_verifier.dart';
import '../../../../core/labels/signed_label.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/widgets/app_snack.dart';
import 'signed_label_result.dart';

/// Resultado de verificar un QR de producto: la etiqueta válida o el motivo
/// (corto, para el aviso sobre la cámara del escaneo continuo).
typedef LabelCheck = ({SignedLabelResult? label, String? error});

/// Verifica una etiqueta escaneada. Un QR firmado se verifica OFFLINE (Ed25519);
/// un Code128 (el valor ES el `label_id`, sin firma) se resuelve ONLINE contra
/// el backend. Nunca lanza: devuelve la etiqueta solo si es válida; si no, el
/// motivo en español.
Future<LabelCheck> verifyLabelQr(WidgetRef ref, String qr) async {
  final scanner = ref.read(labelScannerProvider);
  // ¿El contenido es una etiqueta QR (estructura válida)? Un QR se verifica
  // offline; un QR sin claves o con firma mala se avisa, NO se resuelve online.
  // Solo un valor que NO es QR (Code128) va a la resolución online.
  var isQrLabel = true;
  try {
    SignedLabel.fromQrContent(qr);
  } on LabelFormatException {
    isQrLabel = false;
  }
  if (isQrLabel) {
    try {
      final result = await scanner.scanAndReport(qr);
      if (!result.isValid) {
        return (
          label: null,
          error: result.verification == VerificationResult.unknownKey
              ? 'Etiqueta inválida: clave desconocida'
              : 'Etiqueta inválida: editada o falsa',
        );
      }
      return (
        label: SignedLabelResult(
          unitId: result.label.payload.id,
          shipmentId: result.label.payload.orderNumber,
          sku: result.label.payload.sku,
        ),
        error: null,
      );
    } on LabelFormatException catch (e) {
      // QR válido pero no verificable (sin claves configuradas): se avisa.
      return (label: null, error: e.reason);
    }
  }
  // No es un QR → Code128 (el valor ES el `label_id`): se resuelve ONLINE. Sin
  // red no es validable. Etiquetas PERMANENTES: nada se "anula"; solo se
  // rechaza la que el backend NO reconoce.
  final res = await resolveLabelId(ref, qr);
  if (res == null) {
    return (label: null, error: 'Sin señal para validar la etiqueta');
  }
  if (!res.accepted) {
    return (label: null, error: 'Etiqueta no reconocida');
  }
  return (
    label: SignedLabelResult(
      unitId: res.unitId!,
      shipmentId: res.orderNumber ?? res.shipmentId ?? '',
      sku: res.sku ?? '',
    ),
    error: null,
  );
}

/// Calienta el GPS al abrir la cámara (sin esperar, nunca lanza): al leer cada
/// producto [prefetchCarrierFix] ya encuentra una posición fresca en caché.
void warmUpCarrierLocation(WidgetRef ref) {
  try {
    ref.read(locationServiceProvider).prefetch();
  } on Object {
    // Sin plugin/permiso: lat/lng van en cero.
  }
}

/// Posición para el registro de un producto (≤ 1,5 s; casi inmediata tras
/// [warmUpCarrierLocation]). Nunca falla: sin permiso, plugin o señal devuelve
/// `null` (lat/lng van en cero).
Future<GpsFix?> prefetchCarrierFix(WidgetRef ref) async {
  try {
    return await ref.read(locationServiceProvider).current();
  } on Object {
    return null;
  }
}

/// Resumen al cerrar la cámara: cuántos productos quedaron registrados en la
/// tanda. Flota ENCIMA del botón del pie ([kBottomActionClearance]).
void showCarrierBatchSummary(BuildContext context, String message) {
  showSuccessSnack(context, message, bottomClearance: kBottomActionClearance);
}
