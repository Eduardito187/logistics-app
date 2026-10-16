import '../api/models/label_verification.dart';
import 'label_verifier.dart';
import 'signed_label.dart';

/// Resultado de escanear una etiqueta.
///
/// La verificación offline Ed25519 ([verification]) es SIEMPRE la principal y la
/// que decide si el bulto se acepta en terreno; nunca espera a la red. El campo
/// [backendVerification] es OPCIONAL (best-effort): trae el contrahecheo del
/// backend (`POST /app/labels/verify`) cuando había red y la llamada respondió;
/// es `null` si no se consultó (vía [LabelScanner.scan]) o si falló/no hubo red.
class LabelScanResult {
  const LabelScanResult({
    required this.label,
    required this.verification,
    this.backendVerification,
  });

  final SignedLabel label;
  final VerificationResult verification;

  /// Resultado del contrahecheo del backend, o `null` si no se reportó/consultó.
  /// No cambia [isValid]: la decisión en terreno es siempre la offline.
  final LabelVerification? backendVerification;

  bool get isValid => verification.isValid;

  /// true cuando el backend respondió y su veredicto CONTRADICE al offline
  /// (p. ej. la etiqueta verifica en terreno pero el backend la rechaza, o al
  /// revés). La decisión operativa sigue siendo la offline ([isValid]); este
  /// flag permite que la UI o el log eleven la discrepancia en vez de que pase
  /// en silencio. `false` si no hubo respuesta del backend.
  bool get backendDisagrees {
    final backend = backendVerification;
    if (backend == null) {
      return false;
    }
    return backend.valid != isValid;
  }
}
