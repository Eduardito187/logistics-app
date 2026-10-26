import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/labels/label_format_exception.dart';
import '../../../../core/labels/label_scanner.dart';
import '../../../../core/labels/label_verifier.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/widgets/app_snack.dart';
import 'signed_label_result.dart';

/// Resultado de verificar un QR de bulto: la etiqueta válida o el motivo
/// (corto, para el aviso sobre la cámara del escaneo continuo).
typedef LabelCheck = ({SignedLabelResult? label, String? error});

/// Verifica la firma Ed25519 de un QR de bulto SIN red. Nunca lanza: devuelve
/// la etiqueta solo si es válida; si no, el motivo en español.
Future<LabelCheck> verifyLabelQr(WidgetRef ref, String qr) async {
  final scanner = ref.read(labelScannerProvider);
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
    return (label: null, error: e.reason);
  }
}

/// Calienta el GPS al abrir la cámara (sin esperar, nunca lanza): al leer cada
/// bulto [prefetchCarrierFix] ya encuentra una posición fresca en caché.
void warmUpCarrierLocation(WidgetRef ref) {
  try {
    ref.read(locationServiceProvider).prefetch();
  } on Object {
    // Sin plugin/permiso: lat/lng van en cero.
  }
}

/// Posición para el registro de un bulto (≤ 1,5 s; casi inmediata tras
/// [warmUpCarrierLocation]). Nunca falla: sin permiso, plugin o señal devuelve
/// `null` (lat/lng van en cero).
Future<GpsFix?> prefetchCarrierFix(WidgetRef ref) async {
  try {
    return await ref.read(locationServiceProvider).current();
  } on Object {
    return null;
  }
}

/// Resumen al cerrar la cámara: cuántos bultos quedaron registrados en la
/// tanda. Flota ENCIMA del botón del pie ([kBottomActionClearance]).
void showCarrierBatchSummary(BuildContext context, String message) {
  showSuccessSnack(context, message, bottomClearance: kBottomActionClearance);
}
