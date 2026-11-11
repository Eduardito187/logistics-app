import 'scanned_network.dart';
import 'wifi_printer_hit.dart';

/// Avance de una búsqueda de impresoras en la red: lo que se va encontrando se
/// muestra en vivo, sin esperar a que termine el barrido.
class WifiScanProgress {
  const WifiScanProgress({
    required this.scanned,
    required this.total,
    required this.found,
    required this.networks,
    this.done = false,
    this.error,
    this.discoveringServices = false,
  });

  /// Estado inicial mientras se detecta la red del teléfono.
  const WifiScanProgress.starting()
    : scanned = 0,
      total = 0,
      found = const [],
      networks = const [],
      done = false,
      error = null,
      discoveringServices = false;

  /// Búsqueda que no pudo correr (sin WiFi, error inesperado).
  const WifiScanProgress.failed(String this.error)
    : scanned = 0,
      total = 0,
      found = const [],
      networks = const [],
      done = true,
      discoveringServices = false;

  /// Direcciones ya probadas.
  final int scanned;

  /// Direcciones a probar en total (0 mientras se detecta la red).
  final int total;

  /// Impresoras encontradas hasta ahora (ordenadas: Zebra primero).
  final List<WifiPrinterHit> found;

  /// Redes que se barren (las del teléfono y las agregadas).
  final List<ScannedNetwork> networks;

  final bool done;

  /// Mensaje para el usuario si la búsqueda falló.
  final String? error;

  /// `true` mientras sigue la búsqueda por Bonjour (mDNS) / WS-Discovery.
  final bool discoveringServices;

  bool get isRunning => !done;

  /// Fracción 0–1 para la barra de progreso; `null` = indeterminada.
  double? get fraction => total == 0 ? null : scanned / total;

  /// Rangos barridos como texto (`10.168.48.0/22`).
  List<String> get networkLabels => [for (final n in networks) n.label];

  /// Copia terminada (el usuario detuvo la búsqueda): conserva lo encontrado.
  WifiScanProgress stopped() => WifiScanProgress(
    scanned: scanned,
    total: total,
    found: found,
    networks: networks,
    done: true,
    error: error,
  );
}
