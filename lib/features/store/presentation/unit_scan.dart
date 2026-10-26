import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/labels/label_format_exception.dart';
import '../../../core/labels/label_scanner.dart';
import '../../../core/labels/signed_label.dart';
import '../../../core/labels/verification_result.dart';
import '../../../core/location/location_service.dart';

/// Resultado de resolver un QR a un bulto: el id de la unidad y si la firma
/// Ed25519 pudo verificarse offline (`null` = no se verificó: sin claves o el
/// QR no es una etiqueta firmada).
class UnitScan {
  const UnitScan({required this.unitId, required this.verified, this.result});

  final String unitId;
  final bool? verified;

  /// Detalle de la verificación offline cuando se pudo verificar: permite
  /// distinguir una firma inválida (etiqueta editada/falsa) de una clave
  /// desconocida (no sincronizada), como ya hace la app de transportista.
  /// `null` cuando no se verificó (sin claves o QR no firmado).
  final VerificationResult? result;
}

/// Extrae el id del bulto de un QR y verifica su firma offline cuando hay claves
/// configuradas. Nunca lanza: si el QR no es una etiqueta firmada, usa su texto
/// crudo como id para no bloquear el flujo en terreno.
Future<UnitScan> resolveUnitScan(WidgetRef ref, String qr) async {
  final scanner = ref.read(labelScannerProvider);
  if (scanner.canVerify) {
    try {
      final result = await scanner.scanAndReport(qr);
      return UnitScan(
        unitId: result.label.payload.id,
        verified: result.isValid,
        result: result.verification,
      );
    } on LabelFormatException {
      return UnitScan(unitId: qr, verified: null);
    }
  }
  try {
    final label = SignedLabel.fromQrContent(qr);
    return UnitScan(unitId: label.payload.id, verified: null);
  } on LabelFormatException {
    return UnitScan(unitId: qr, verified: null);
  }
}

/// Mensaje en español para una etiqueta que no verificó, distinguiendo clave
/// desconocida de firma inválida (mismo criterio que la app de transportista).
String unitScanErrorMessage(UnitScan scan) =>
    scan.result == VerificationResult.unknownKey
    ? 'Etiqueta de una clave desconocida: no se puede verificar.'
    : 'Firma inválida: etiqueta editada o falsa.';

/// Mensaje corto (cabe en el aviso sobre la cámara del escaneo continuo) para
/// una etiqueta que no verificó.
String unitScanShortError(UnitScan scan) =>
    scan.result == VerificationResult.unknownKey
    ? 'Etiqueta inválida: clave desconocida'
    : 'Etiqueta inválida: editada o falsa';

/// Calienta el GPS al abrir la cámara (sin esperar, nunca lanza): al leer cada
/// código [prefetchFix] ya encuentra una posición fresca en caché.
void warmUpLocation(WidgetRef ref) {
  try {
    ref.read(locationServiceProvider).prefetch();
  } on Object {
    // Sin plugin/permiso: el escaneo sigue sin ubicación (offline-first).
  }
}

/// Posición para el registro de un código. No bloquea más de lo que tarda
/// `LocationService.current` (≤ 1,5 s, casi inmediato tras [warmUpLocation]);
/// se pasa como `Future` al caso de uso, que no la espera aparte. Nunca falla:
/// sin permiso, sin plugin o sin señal devuelve `null`.
Future<GpsFix?> prefetchFix(WidgetRef ref) async {
  try {
    return await ref.read(locationServiceProvider).current();
  } on Object {
    return null;
  }
}
