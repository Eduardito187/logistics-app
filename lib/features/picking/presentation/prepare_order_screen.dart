import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/icons/icons.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/layout/responsive_body.dart';
import '../../../core/scanning/scanner_screen.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/field_icon.dart';
import '../../../core/widgets/section_card.dart';
import '../domain/order_number.dart';
import 'controllers/order_scan.dart';

/// Primer paso del preparador: abrir un pedido para armarlo.
///
/// Las etiquetas son POR PRODUCTO: la acción principal es escanear la etiqueta
/// de cualquier producto y se abre SU pedido. Escribir el número queda como
/// alternativa. Nunca se navega con un código que no sea un pedido (antes un QR
/// de etiqueta abría "Pedido {"v":1,…}" sin productos).
class PrepareOrderScreen extends ConsumerStatefulWidget {
  const PrepareOrderScreen({super.key});

  @override
  ConsumerState<PrepareOrderScreen> createState() => _PrepareOrderScreenState();
}

class _PrepareOrderScreenState extends ConsumerState<PrepareOrderScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _resolving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openTyped(String raw) {
    final orderNumber = raw.trim();
    if (orderNumber.isEmpty) {
      showInfoSnack(context, 'Escribí el número de pedido.');
      return;
    }
    if (!isPlausibleOrderNumber(orderNumber)) {
      showErrorSnack(
        context,
        'Ese no es un número de pedido válido (ej. DIS-123456).',
      );
      return;
    }
    context.push(orderPreparationPath(orderNumber));
  }

  Future<void> _scan() async {
    final code = await scanCode(
      context,
      title: 'Escanear un producto',
      helper: 'Apuntá a la etiqueta de cualquier producto del pedido.',
      formats: kLabelScanFormats,
    );
    if (!mounted || code == null) return;
    setState(() => _resolving = true);
    final result = await orderFromScannedCode(ref, code);
    if (!mounted) return;
    setState(() => _resolving = false);
    final order = result.orderNumber;
    if (order == null) {
      showErrorSnack(context, result.error ?? 'No se reconoció el código.');
      return;
    }
    unawaited(context.push(orderPreparationPath(order)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preparar pedido')),
      // Formulario corto: en tablet no se estira de borde a borde.
      body: ResponsiveBody(
        maxWidth: AppBreakpoints.maxFormWidth,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionCard(
                title: 'Escaneá un producto',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Escaneá la etiqueta de cualquier producto y se abre su '
                      'pedido con todas sus etiquetas.',
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _resolving ? null : _scan,
                      icon: AnimatedAppIcon(
                        AppIcon.scan,
                        state: _resolving
                            ? AppIconState.loading
                            : AppIconState.idle,
                        excludeFromSemantics: true,
                      ),
                      label: Text(
                        _resolving ? 'Buscando el pedido…' : 'Escanear producto',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'O escribí el número de pedido',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.go,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Ej. DIS-123456',
                        prefixIconConstraints: FieldIcon.prefixConstraints,
                        prefixIcon: FieldIcon(icon: AppIcon.settle),
                      ),
                      onSubmitted: _openTyped,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _openTyped(_controller.text),
                      icon: const AnimatedAppIcon(AppIcon.arrowForward),
                      label: const Text('Abrir pedido'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
