import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/scanning/scanner_screen.dart';
import '../../../core/widgets/section_card.dart';

/// Primer paso del preparador: ingresar o escanear el número de pedido para
/// ver sus etiquetas y armarlo.
class PrepareOrderScreen extends ConsumerStatefulWidget {
  const PrepareOrderScreen({super.key});

  @override
  ConsumerState<PrepareOrderScreen> createState() => _PrepareOrderScreenState();
}

class _PrepareOrderScreenState extends ConsumerState<PrepareOrderScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open(String raw) {
    final orderNumber = raw.trim();
    if (orderNumber.isEmpty) return;
    context.push('/picking/order/$orderNumber');
  }

  Future<void> _scan() async {
    final code = await scanCode(
      context,
      title: 'Escanear pedido',
      helper: 'Apuntá al código del pedido o del documento.',
      formats: const <BarcodeFormat>[
        BarcodeFormat.code128,
        BarcodeFormat.qrCode,
        BarcodeFormat.ean13,
      ],
    );
    if (!mounted || code == null) return;
    _controller.text = code;
    _open(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preparar pedido')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SectionCard(
          title: 'Número de pedido',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.go,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  hintText: 'Ej. DIS-123456',
                  prefixIcon: Icon(Icons.receipt_long),
                ),
                onSubmitted: _open,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _open(_controller.text),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Ver etiquetas'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _scan,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Escanear pedido'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
