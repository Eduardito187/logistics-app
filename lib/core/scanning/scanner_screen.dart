import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../icons/icons.dart';

import 'code_scanner.dart';
import 'scan_feedback.dart';
import 'scan_frame.dart';
import 'scanner_paused_overlay.dart';

export 'code_scanner.dart';
export 'continuous_scanner.dart';
export 'scan_feedback.dart';
export 'scanner_paused_overlay.dart';

/// Pantalla de escaneo a pantalla completa (EAN o QR). Devuelve el primer
/// código leído con `Navigator.pop`. Botones grandes, overlay de guía y
/// linterna: pensada para usarse con una mano en el andén o el camión.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({
    super.key,
    this.title = 'Escanear',
    this.helper,
    this.formats = const [],
  });

  final String title;
  final String? helper;

  /// Restringe los formatos (p. ej. solo QR para etiquetas, EAN para productos).
  final List<BarcodeFormat> formats;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

/// Resolución pedida a la cámara (solo Android).
///
/// 1280x720 lee EAN-13 chicos a distancia de brazo; más (1080p/4K) multiplica
/// la memoria de cada cuadro y el trabajo de ML Kit sin leer mejor. En equipos
/// sin 720p la cámara toma la resolución soportada más cercana.
const Size kScannerCameraResolution = Size(1280, 720);

/// Pausa entre análisis de cuadros: analizar todos (~30/seg) calienta y
/// traba un teléfono de 1 GB; 4 por segundo sigue sintiéndose instantáneo.
const int kScannerDetectionTimeoutMs = 250;

/// Formatos que se buscan cuando la pantalla no restringe ninguno: los que usa
/// la operación (QR firmado de productos, Code128 de etiquetas/andenes, EAN/UPC
/// de productos). Con la lista vacía ML Kit / Vision prueban los ~13 formatos
/// en cada cuadro: más CPU y más lecturas falsas.
const List<BarcodeFormat> kDefaultScannerFormats = [
  BarcodeFormat.qrCode,
  BarcodeFormat.code128,
  BarcodeFormat.ean13,
  BarcodeFormat.ean8,
  BarcodeFormat.upcA,
];

/// Formatos aceptados al escanear una ETIQUETA de producto: el QR firmado (se
/// verifica offline Ed25519) o el Code128 cuyo valor ES el `label_id` (se
/// resuelve online, ver `LabelResolver`). Un único punto para todos los
/// escaneos de etiqueta (chofer, tienda, transportista). NO usar para el QR de
/// confirmación del cliente ni para el EAN de productos (tienen sus formatos).
const List<BarcodeFormat> kLabelScanFormats = [
  BarcodeFormat.qrCode,
  BarcodeFormat.code128,
];

/// Controller del escáner afinado para gama baja (ver constantes arriba).
/// Sin imagen de retorno (`returnImage: false`): no copia cada cuadro a Dart.
///
/// `DetectionSpeed.normal` + [kScannerDetectionTimeoutMs] (y no
/// `noDuplicates`): `noDuplicates` analiza TODOS los cuadros y solo filtra los
/// repetidos; el espaciado entre análisis es lo que ahorra CPU y temperatura.
/// Lo comparten [ScannerScreen] (cierra con la primera lectura) y el escaneo
/// continuo (`continuous_scanner.dart`, que filtra los repetidos a mano).
MobileScannerController createScannerController(List<BarcodeFormat> formats) {
  return MobileScannerController(
    formats: formats.isEmpty ? kDefaultScannerFormats : formats,
    cameraResolution: kScannerCameraResolution,
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: kScannerDetectionTimeoutMs,
    returnImage: false,
  );
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  late final MobileScannerController _controller = createScannerController(
    widget.formats,
  );
  bool _handled = false;

  /// Pausa por inactividad (ver [kScannerIdlePause]): cámara abierta sin leer
  /// nada = batería tirada.
  Timer? _idleTimer;
  bool _idlePaused = false;

  /// Falla de arranque de la cámara (permiso, hardware, en uso por otra app):
  /// se muestra un mensaje en vez de dejar la pantalla NEGRA y colgada.
  Object? _startError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startCamera();
    _armIdle();
  }

  /// Arranca la cámara explícitamente (mobile_scanner 7.x no garantiza el
  /// auto-start con un controller propio). Si falla, se guarda el error para
  /// mostrar un aviso con "Reintentar" en vez de una pantalla negra.
  Future<void> _startCamera() async {
    try {
      await _controller.start();
      if (mounted && _startError != null) setState(() => _startError = null);
    } on MobileScannerException catch (e) {
      // El widget pudo auto-arrancar la cámara: "ya iniciada" / "iniciando" no
      // son fallas, no se muestran como error.
      if (e.errorCode == MobileScannerErrorCode.controllerAlreadyInitialized ||
          e.errorCode == MobileScannerErrorCode.controllerInitializing) {
        if (mounted && _startError != null) setState(() => _startError = null);
        return;
      }
      if (mounted) setState(() => _startError = e);
    } on Object catch (e) {
      if (mounted) setState(() => _startError = e);
    }
  }

  Future<void> _retryCamera() async {
    setState(() => _startError = null);
    await _startCamera();
  }

  void _armIdle() {
    _idleTimer?.cancel();
    _idleTimer = Timer(kScannerIdlePause, _pauseForIdle);
  }

  void _pauseForIdle() {
    _idleTimer = null;
    if (!mounted || _idlePaused || _handled) return;
    setState(() => _idlePaused = true);
    unawaited(_controller.stop().catchError((Object _) {}));
  }

  void _resumeFromIdle() {
    setState(() => _idlePaused = false);
    unawaited(_controller.start().catchError((Object _) {}));
    _armIdle();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // La cámara se libera al minimizar la app (llamada, otra app): en 1 GB el
    // sistema mata primero a los procesos que retienen la cámara. Se retoma
    // al volver si ya había arrancado.
    if (!_controller.value.isInitialized) return;
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_handled && !_idlePaused) unawaited(_startCamera());
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        unawaited(_controller.stop());
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _idleTimer?.cancel();
    unawaited(_controller.dispose());
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final code = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null && v.isNotEmpty, orElse: () => null);
    if (code == null) return;
    _handled = true;
    // Vibración + click del sistema (si está activado en Ajustes): confirma
    // la lectura sin tener que mirar la pantalla.
    unawaited(scanFeedbackFor(context, success: true));
    // Se suelta la cámara ya (no al terminar la animación de salida).
    unawaited(_controller.stop());
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Linterna',
            icon: const AnimatedAppIcon(AppIcon.bolt),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            tooltip: 'Cambiar cámara',
            icon: const AnimatedAppIcon(AppIcon.cameraSwitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            // Error EN VIVO de la cámara (se desconecta, otra app la toma): se
            // muestra el aviso en vez de una pantalla negra.
            errorBuilder: (context, error) =>
                _CameraError(error: error, onRetry: _retryCamera),
          ),
          ScanFrame(helper: widget.helper),
          // Error de ARRANQUE (permiso denegado, cámara en uso): mismo aviso.
          if (_startError != null)
            Positioned.fill(
              child: _CameraError(error: _startError!, onRetry: _retryCamera),
            ),
          if (_idlePaused)
            Positioned.fill(
              child: ScannerPausedOverlay(onResume: _resumeFromIdle),
            ),
        ],
      ),
    );
  }
}

/// Aviso de cámara (arranque fallido o error en vivo): en vez de una pantalla
/// NEGRA colgada, explica qué pasó y ofrece reintentar. Cerrar con la flecha.
class _CameraError extends StatelessWidget {
  const _CameraError({required this.error, required this.onRetry});

  final Object error;
  final Future<void> Function() onRetry;

  /// Mensaje para el operario según el tipo de falla de mobile_scanner.
  String get _message {
    final e = error;
    if (e is MobileScannerException) {
      switch (e.errorCode) {
        case MobileScannerErrorCode.permissionDenied:
          return 'La app no tiene permiso de cámara. Habilitalo en los '
              'ajustes del teléfono y volvé a intentar.';
        case MobileScannerErrorCode.unsupported:
          return 'Este teléfono no soporta la cámara para escanear.';
        default:
          return 'No se pudo abrir la cámara. Puede estar en uso por otra app. '
              'Cerrá la otra app y reintentá.';
      }
    }
    return 'No se pudo abrir la cámara. Reintentá.';
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AnimatedAppIcon(
                AppIcon.error,
                state: AppIconState.error,
                size: 48,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => onRetry(),
                icon: const AnimatedAppIcon(AppIcon.syncing),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Abre el escáner y devuelve el código leído, o `null` si se canceló.
///
/// Delega en [codeScannerProvider] si hay uno configurado en el `ProviderScope`
/// (tests); si no, abre la cámara con [ScannerScreen].
Future<String?> scanCode(
  BuildContext context, {
  String title = 'Escanear',
  String? helper,
  List<BarcodeFormat> formats = const [],
}) {
  final scanner = _overriddenScanner(context) ?? openCameraScanner;
  return scanner(context, title: title, helper: helper, formats: formats);
}

/// Escáner real: [ScannerScreen] a pantalla completa.
Future<String?> openCameraScanner(
  BuildContext context, {
  required String title,
  String? helper,
  required List<BarcodeFormat> formats,
}) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) =>
          ScannerScreen(title: title, helper: helper, formats: formats),
    ),
  );
}

CodeScanner? _overriddenScanner(BuildContext context) {
  try {
    return ProviderScope.containerOf(
      context,
      listen: false,
    ).read(codeScannerProvider);
  } on StateError {
    // Sin ProviderScope (p. ej. un widget suelto en test): cámara real.
    return null;
  }
}
