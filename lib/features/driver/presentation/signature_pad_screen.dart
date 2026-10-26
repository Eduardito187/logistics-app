import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';

/// Exporta el trazo a PNG (inyectable: en tests no se rasteriza).
typedef SignaturePngExporter =
    Future<Uint8List?> Function(SignatureController controller);

/// PNG liviano: recortado al área firmada, trazo negro sobre fondo blanco
/// (dos colores comprimen muy bien, unas decenas de KB).
final signaturePngExporterProvider = Provider<SignaturePngExporter>(
  (ref) =>
      (controller) => controller.toPngBytes(),
);

/// Abre el pad de firma a pantalla completa y devuelve el PNG, o `null` si el
/// chofer vuelve sin confirmar.
Future<Uint8List?> captureCustomerSignature(BuildContext context) =>
    Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const SignaturePadScreen(),
      ),
    );

/// Firma del cliente con el dedo: pad grande que ocupa la pantalla, con
/// "Borrar" y "Listo" (este último solo cuando hay trazo).
class SignaturePadScreen extends ConsumerStatefulWidget {
  const SignaturePadScreen({super.key});

  @override
  ConsumerState<SignaturePadScreen> createState() => _SignaturePadScreenState();
}

class _SignaturePadScreenState extends ConsumerState<SignaturePadScreen> {
  late final SignatureController _controller = SignatureController(
    penStrokeWidth: 4,
    penColor: Colors.black,
    exportPenColor: Colors.black,
    exportBackgroundColor: Colors.white,
    strokeCap: StrokeCap.round,
    strokeJoin: StrokeJoin.round,
  );
  bool _busy = false;

  /// Vacío / con trazo. Los botones escuchan SOLO esto (cambia al primer trazo
  /// y al borrar), no cada punto del dedo como el controlador de la firma.
  final ValueNotifier<bool> _empty = ValueNotifier(true);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncEmpty);
  }

  void _syncEmpty() => _empty.value = _controller.isEmpty;

  @override
  void dispose() {
    _controller.removeListener(_syncEmpty);
    _controller.dispose();
    _empty.dispose();
    super.dispose();
  }

  Future<void> _done() async {
    setState(() => _busy = true);
    try {
      final png = await ref.read(signaturePngExporterProvider)(_controller);
      if (!mounted) return;
      if (png != null) Navigator.of(context).pop(png);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Firma del cliente')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pedile al cliente que firme con el dedo dentro del recuadro.',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.colorScheme.outline,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  // Capa propia: cada punto del trazo repinta solo el pad, no
                  // la pantalla entera (se nota en teléfonos de gama baja).
                  child: RepaintBoundary(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Signature(
                        key: const ValueKey('signature-pad'),
                        controller: _controller,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<bool>(
                valueListenable: _empty,
                builder: (context, empty, _) {
                  return Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                          ),
                          onPressed: empty || _busy ? null : _controller.clear,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Borrar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                          ),
                          onPressed: empty || _busy ? null : _done,
                          icon: const Icon(Icons.check),
                          label: const Text('Listo'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
