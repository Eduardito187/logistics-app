import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/models/settlement.dart';
import '../../../core/commands/command_feedback.dart';
import '../../../core/commands/command_outcome.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/async_value_view.dart';
import '../domain/usecases/approve_settlement.dart';
import '../domain/usecases/dispute_settlement.dart';
import '../domain/usecases/pay_settlement.dart';
import 'controllers/carrier_controllers.dart';
import 'widgets/settlement_detail.dart';

/// Detalle de una liquidación con las acciones aprobar / disputar / pagar.
/// Estas acciones son comandos asíncronos: el backend responde 202
/// (`AcceptedEnvelope`) y procesa la orden después. Por eso se avisa "en
/// proceso" (no un estado ya aplicado) y se invalida detalle + lista para que
/// reflejen el estado real cuando el backend termine de procesarla.
class CarrierSettlementDetailScreen extends ConsumerStatefulWidget {
  const CarrierSettlementDetailScreen({
    super.key,
    required this.settlementId,
    this.initial,
  });

  final String settlementId;

  /// Liquidación de la lista (semilla): se muestra mientras llega el detalle.
  final Settlement? initial;

  @override
  ConsumerState<CarrierSettlementDetailScreen> createState() =>
      _CarrierSettlementDetailScreenState();
}

class _CarrierSettlementDetailScreenState
    extends ConsumerState<CarrierSettlementDetailScreen> {
  bool _busy = false;

  void _refresh() {
    ref.invalidate(carrierSettlementProvider(widget.settlementId));
    final carrier = ref.read(selectedCarrierProvider);
    if (carrier != null) {
      ref.invalidate(carrierSettlementsProvider(carrier.id));
    }
  }

  /// Ejecuta un comando async (aprobar/disputar/pagar). El backend responde 202
  /// y procesa después: se avisa "en proceso" y se invalidan las lecturas.
  Future<void> _runAction(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      _refresh();
      showCommandOutcome(context, const CommandOutcome.accepted());
    } on ApiException catch (e) {
      if (!mounted) return;
      showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _approve() => _runAction(
    () => ref.read(approveSettlementProvider)(widget.settlementId),
  );

  Future<void> _dispute() async {
    final reason = await _promptText(
      title: 'Disputar liquidación',
      label: 'Motivo de la disputa',
      confirmLabel: 'Disputar',
    );
    if (reason == null || reason.isEmpty) return;
    await _runAction(
      () => ref.read(disputeSettlementProvider)(widget.settlementId, reason),
    );
  }

  Future<void> _pay() async {
    final reference = await _promptText(
      title: 'Marcar como pagada',
      label: 'Referencia de pago',
      confirmLabel: 'Pagar',
    );
    if (reference == null || reference.isEmpty) return;
    await _runAction(
      () => ref.read(paySettlementProvider)(widget.settlementId, reference),
    );
  }

  Future<String?> _promptText({
    required String title,
    required String label,
    required String confirmLabel,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => _TextPromptDialog(
        title: title,
        label: label,
        confirmLabel: confirmLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fetched = ref.watch(carrierSettlementProvider(widget.settlementId));
    final seed = widget.initial;
    // Primera carga con semilla de la lista: se muestra ya, sin spinner. Un
    // error sí se muestra (con reintento) aunque haya semilla.
    final settlement = fetched.isLoading && !fetched.hasValue && seed != null
        ? AsyncValue<Settlement>.data(seed)
        : fetched;
    return Scaffold(
      appBar: AppBar(title: const Text('Liquidación')),
      body: AsyncValueView<Settlement>(
        value: settlement,
        onRetry: () =>
            ref.invalidate(carrierSettlementProvider(widget.settlementId)),
        data: (data) => SettlementDetail(
          settlement: data,
          busy: _busy,
          onApprove: _approve,
          onDispute: _dispute,
          onPay: _pay,
        ),
      ),
    );
  }
}

/// Diálogo con un campo de texto (motivo de disputa, referencia de pago). Es
/// dueño de su [TextEditingController] y lo libera al cerrarse (antes quedaba
/// sin `dispose` en cada apertura).
class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({
    required this.title,
    required this.label,
    required this.confirmLabel,
  });

  final String title;
  final String label;
  final String confirmLabel;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      // Scrollable: con teclado abierto en un teléfono chico no se desborda.
      scrollable: true,
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: widget.label),
        minLines: 1,
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
