import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/labels/label_format_exception.dart';
import '../../../core/labels/label_resolver.dart';
import '../../../core/labels/label_scanner.dart';
import '../../../core/labels/signed_label.dart';
import '../../../core/labels/verification_result.dart';
import '../../../core/location/location_service.dart';

/// Resultado de resolver una etiqueta escaneada a un producto.
///
/// Dos simbologías: el **QR** firmado (se verifica offline Ed25519; [verified] =
/// resultado de la firma) y el **Code128** cuyo valor ES el `label_id` (se
/// resuelve ONLINE contra el backend; [online] = `true`, sin firma). [verified]
/// es `null` cuando no hubo verificación offline (QR sin claves, o un Code128
/// aceptado por el servidor).
class UnitScan {
  const UnitScan({
    required this.unitId,
    required this.verified,
    this.result,
    this.online = false,
    this.revoked = false,
    this.unreachable = false,
  });

  final String unitId;
  final bool? verified;

  /// Detalle de la verificación offline cuando se pudo verificar: permite
  /// distinguir una firma inválida (etiqueta editada/falsa) de una clave
  /// desconocida (no sincronizada), como ya hace la app de transportista.
  /// `null` cuando no se verificó (sin claves, QR no firmado o Code128 online).
  final VerificationResult? result;

  /// La etiqueta se resolvió ONLINE (Code128, sin firma). Con `verified == false`
  /// significa que el backend la rechazó (no reconocida, anulada o sin señal).
  final bool online;

  /// Etiqueta anulada (reimpresa/dada de baja): el backend la resolvió pero no
  /// debe aceptarse. Solo aplica al camino online (Code128).
  final bool revoked;

  /// No se pudo consultar al backend (sin señal): un Code128 no es validable sin
  /// red, así que se rechaza. Solo aplica al camino online.
  final bool unreachable;
}

/// Resuelve una etiqueta escaneada a un producto. QR firmado → verificación
/// offline (sin red); Code128 (`label_id` sin firma) → resolución ONLINE contra el
/// backend. Nunca lanza. Un Code128 que el backend no reconoce, anula o que no
/// se pudo consultar (sin señal) vuelve con `verified == false` (se rechaza).
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
      // No es un QR firmado → se intenta como Code128 (abajo).
    }
  } else {
    // Sin claves: si es un QR firmado se lee el id sin verificar; si no, Code128.
    try {
      final label = SignedLabel.fromQrContent(qr);
      return UnitScan(unitId: label.payload.id, verified: null);
    } on LabelFormatException {
      // No es un QR firmado → se intenta como Code128 (abajo).
    }
  }
  // Code128: el valor escaneado ES el `label_id` → se resuelve ONLINE.
  final res = await resolveLabelId(ref, qr);
  if (res == null) {
    return UnitScan(
      unitId: qr,
      verified: false,
      online: true,
      unreachable: true,
    );
  }
  if (res.accepted) {
    return UnitScan(unitId: res.unitId!, verified: null, online: true);
  }
  return UnitScan(
    unitId: qr,
    verified: false,
    online: true,
    revoked: res.revoked,
  );
}

/// Mensaje en español para una etiqueta que no verificó/ no se aceptó.
String unitScanErrorMessage(UnitScan scan) {
  if (scan.unreachable) {
    return 'Sin señal para validar la etiqueta. Intentá de nuevo.';
  }
  if (scan.revoked) return 'Etiqueta anulada: ya no es válida.';
  if (scan.online) return 'Etiqueta no reconocida por el sistema.';
  return scan.result == VerificationResult.unknownKey
      ? 'Etiqueta de una clave desconocida: no se puede verificar.'
      : 'Firma inválida: etiqueta editada o falsa.';
}

/// Mensaje corto (cabe en el aviso sobre la cámara del escaneo continuo) para
/// una etiqueta que no verificó/ no se aceptó.
String unitScanShortError(UnitScan scan) {
  if (scan.unreachable) return 'Sin señal para validar';
  if (scan.revoked) return 'Etiqueta anulada';
  if (scan.online) return 'Etiqueta no reconocida';
  return scan.result == VerificationResult.unknownKey
      ? 'Etiqueta inválida: clave desconocida'
      : 'Etiqueta inválida: editada o falsa';
}

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
