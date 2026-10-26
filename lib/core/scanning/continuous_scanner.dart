import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'scan_feedback.dart';
import 'scan_frame.dart';
import 'scanner_screen.dart' show createScannerController;

/// Resultado de procesar un código en el escaneo continuo: si se registró
/// (`ok`) y el texto corto que se muestra sobre la cámara.
class ScanFeedback {
  const ScanFeedback({required this.ok, required this.message});

  /// Código aceptado (p. ej. "Bulto 3/12 registrado").
  const ScanFeedback.ok(this.message) : ok = true;

  /// Código rechazado (p. ej. "No es de esta ruta").
  const ScanFeedback.error(this.message) : ok = false;

  final bool ok;
  final String message;
}

/// Procesa un código leído en el escaneo continuo.
typedef ScanCodeHandler = Future<ScanFeedback> Function(String code);

/// Escaneo continuo (firma de [scanContinuous]); reemplazable en tests vía
/// [continuousScannerProvider].
typedef ContinuousCodeScanner =
    Future<void> Function(
      BuildContext context, {
      required String title,
      String? helper,
      List<BarcodeFormat>? formats,
      required ScanCodeHandler onCode,
    });

/// Escáner continuo de la app. `null` (default) = cámara real
/// ([ContinuousScannerScreen]); en widget tests se reemplaza con
/// `continuousScannerProvider.overrideWithValue(...)` para inyectar códigos.
final continuousScannerProvider = Provider<ContinuousCodeScanner?>(
  (ref) => null,
);

/// Ventana en la que el MISMO código leído otra vez se ignora (la cámara queda
/// apoyada sobre el bulto y lo lee ~4 veces por segundo).
const Duration kContinuousScanRepeatWindow = Duration(seconds: 2);

/// Tiempo que queda visible el aviso del último código.
const Duration kContinuousScanFeedbackVisible = Duration(seconds: 3);

/// Abre la cámara en modo CONTINUO: no se cierra entre bultos. Por cada código
/// leído llama a [onCode] y muestra su [ScanFeedback] sobre la cámara (verde o
/// rojo, con vibración/sonido según la preferencia). El mismo código repetido
/// dentro de [kContinuousScanRepeatWindow] se ignora, y mientras [onCode]
/// procesa uno no se toman otros. Termina con el botón "Terminar" (o atrás).
///
/// Carga/descarga/recepción: la cámara se abre una sola vez por tanda en vez
/// de una por bulto (0,5–1,5 s ahorrados por bulto en gama baja).
Future<void> scanContinuous(
  BuildContext context, {
  required String title,
  String? helper,
  List<BarcodeFormat>? formats,
  required ScanCodeHandler onCode,
}) {
  final scanner = _overriddenScanner(context) ?? openContinuousCameraScanner;
  return scanner(
    context,
    title: title,
    helper: helper,
    formats: formats,
    onCode: onCode,
  );
}

/// Escáner continuo real: [ContinuousScannerScreen] a pantalla completa.
Future<void> openContinuousCameraScanner(
  BuildContext context, {
  required String title,
  String? helper,
  List<BarcodeFormat>? formats,
  required ScanCodeHandler onCode,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => ContinuousScannerScreen(
        title: title,
        helper: helper,
        formats: formats ?? const [],
        onCode: onCode,
      ),
    ),
  );
}

ContinuousCodeScanner? _overriddenScanner(BuildContext context) {
  try {
    return ProviderScope.containerOf(
      context,
      listen: false,
    ).read(continuousScannerProvider);
  } on StateError {
    return null;
  }
}

/// Pantalla de escaneo continuo (ver [scanContinuous]).
class ContinuousScannerScreen extends StatefulWidget {
  const ContinuousScannerScreen({
    super.key,
    required this.title,
    required this.onCode,
    this.helper,
    this.formats = const [],
    this.repeatWindow = kContinuousScanRepeatWindow,
    this.now,
  });

  final String title;
  final String? helper;
  final List<BarcodeFormat> formats;
  final ScanCodeHandler onCode;

  /// Ventana anti-repetición del mismo código.
  final Duration repeatWindow;

  /// Reloj inyectable (tests).
  final DateTime Function()? now;

  @override
  State<ContinuousScannerScreen> createState() =>
      _ContinuousScannerScreenState();
}

class _ContinuousScannerScreenState extends State<ContinuousScannerScreen>
    with WidgetsBindingObserver {
  late final MobileScannerController _controller = createScannerController(
    widget.formats,
  );

  String? _lastCode;
  DateTime? _lastSeenAt;
  bool _busy = false;
  ScanFeedback? _feedback;
  Timer? _feedbackTimer;
  int _okCount = 0;

  DateTime _now() => (widget.now ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Igual que ScannerScreen: se suelta la cámara al minimizar.
    if (!_controller.value.isInitialized) return;
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_controller.start());
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
    _feedbackTimer?.cancel();
    unawaited(_controller.dispose());
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final code = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null && v.isNotEmpty, orElse: () => null);
    if (code == null) return;
    final now = _now();
    final lastAt = _lastSeenAt;
    final repeated =
        code == _lastCode &&
        lastAt != null &&
        now.difference(lastAt) < widget.repeatWindow;
    if (code == _lastCode) {
      // Mientras la cámara siga sobre el mismo bulto se renueva la ventana.
      _lastSeenAt = now;
    }
    if (repeated || _busy) return;
    _lastCode = code;
    _lastSeenAt = now;
    unawaited(_process(code));
  }

  Future<void> _process(String code) async {
    _busy = true;
    ScanFeedback feedback;
    try {
      feedback = await widget.onCode(code);
    } on Object {
      feedback = const ScanFeedback.error('No se pudo registrar. Reintentá.');
    }
    _busy = false;
    if (!mounted) return;
    unawaited(scanFeedbackFor(context, success: feedback.ok));
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(kContinuousScanFeedbackVisible, () {
      if (mounted) setState(() => _feedback = null);
    });
    setState(() {
      _feedback = feedback;
      if (feedback.ok) _okCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final feedback = _feedback;
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
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          ScanFrame(helper: widget.helper),
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CountChip(count: _okCount),
                if (feedback != null) ...[
                  const SizedBox(height: 12),
                  _FeedbackBanner(feedback: feedback),
                ],
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 64,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.check, size: 28),
                  label: const Text(
                    'Terminar',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            count == 1 ? '1 registrado' : '$count registrados',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.feedback});

  final ScanFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final color = feedback.ok ? Colors.green.shade700 : Colors.red.shade700;
    return Semantics(
      liveRegion: true,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                feedback.ok ? Icons.check_circle : Icons.error,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  feedback.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
