import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'scan_frame.dart';

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

class _ScannerScreenState extends State<ScannerScreen> {
  late final MobileScannerController _controller = MobileScannerController(
    formats: widget.formats,
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final code = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null && v.isNotEmpty, orElse: () => null);
    if (code == null) return;
    _handled = true;
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
Future<String?> scanCode(
  BuildContext context, {
  String title = 'Escanear',
  String? helper,
  List<BarcodeFormat> formats = const [],
}) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) =>
          ScannerScreen(title: title, helper: helper, formats: formats),
    ),
  );
}
