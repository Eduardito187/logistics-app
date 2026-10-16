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
  const CarrierSettlementDetailScreen({super.key, required this.settlementId});

  final String settlementId;

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
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: label),
          minLines: 1,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settlement = ref.watch(
      carrierSettlementProvider(widget.settlementId),
    );
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
