import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'code_scanner.dart';
import 'scan_feedback.dart';
import 'scan_frame.dart';

export 'code_scanner.dart';
export 'continuous_scanner.dart';
export 'scan_feedback.dart';

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
/// la operación (QR firmado de bultos, Code128 de etiquetas/andenes, EAN/UPC
/// de productos). Con la lista vacía ML Kit / Vision prueban los ~13 formatos
/// en cada cuadro: más CPU y más lecturas falsas.
const List<BarcodeFormat> kDefaultScannerFormats = [
  BarcodeFormat.qrCode,
  BarcodeFormat.code128,
  BarcodeFormat.ean13,
  BarcodeFormat.ean8,
  BarcodeFormat.upcA,
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // La cámara se libera al minimizar la app (llamada, otra app): en 1 GB el
    // sistema mata primero a los procesos que retienen la cámara. Se retoma
    // al volver si ya había arrancado.
    if (!_controller.value.isInitialized) return;
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_handled) unawaited(_controller.start());
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
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            tooltip: 'Cambiar cámara',
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          ScanFrame(helper: widget.helper),
        ],
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
