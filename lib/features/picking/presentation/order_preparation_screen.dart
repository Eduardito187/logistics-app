import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/api/models/emit_label_line.dart';
import '../../../core/api/models/emit_labels_request.dart';
import '../../../core/api/models/emitted_label.dart';
import '../../../core/api/models/preparation_scan_request.dart';
import '../../../core/api/models/reprint_labels_request.dart';
import '../../../core/layout/adaptive_card_rows.dart';
import '../../../core/location/location_service.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/offline/offline_queue.dart';
import '../../../core/offline/submit_feedback.dart';
import '../../../core/printing/label_printer.dart';
import '../../../core/printing/printer_config.dart';
import '../../../core/scanning/scanner_screen.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/async_value_view.dart';
import '../domain/usecases/emit_labels.dart';
import '../domain/usecases/get_signed_zpl.dart';
import '../domain/usecases/record_preparation_scan.dart';
import '../domain/usecases/reprint_labels.dart';
import 'controllers/order_labels_controller.dart';
import 'controllers/preparation_controller.dart';
import 'widgets/assign_lane_dialog.dart';
import 'widgets/label_batch_sheet.dart';
import 'widgets/preparation_empty_body.dart';
import 'widgets/preparation_units_layout.dart';
import 'widgets/progress_card.dart';
import 'widgets/unit_tile.dart';

/// Pantalla de armado de un pedido: progreso, asignación de carril y, por cada
/// unidad, escanear el EAN del producto para registrar la preparación e
/// imprimir su etiqueta QR en la Zebra.
class OrderPreparationScreen extends ConsumerStatefulWidget {
  const OrderPreparationScreen({super.key, required this.orderNumber});

  final String orderNumber;

  @override
  ConsumerState<OrderPreparationScreen> createState() =>
      _OrderPreparationScreenState();
}

class _OrderPreparationScreenState
    extends ConsumerState<OrderPreparationScreen> {
  /// Unidad con una operación en curso (muestra spinner en su fila).
  String? _busyUnitId;

  /// Operación a nivel pedido en curso (emitir, reimprimir lote, imprimir todo).
  bool _orderBusy = false;

  /// La operación de pedido en curso es "Reimprimir lote" (spinner propio).
  bool _reprintingBatch = false;

  String get _orderNumber => widget.orderNumber;

  Future<void> _assignLane() async {
    final current = ref.read(preparationControllerProvider(_orderNumber));
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AssignLaneDialog(initial: current.vehicleId),
    );
    if (!mounted || result == null) return;
    final value = result.trim();
    if (value.isEmpty) return;
    ref
        .read(preparationControllerProvider(_orderNumber).notifier)
        .assign(vehicleId: value, lane: value);
  }

  Future<void> _prepareUnit(EmittedLabel label) async {
    // El carril/vehículo abre la entrega: es obligatorio antes del primer escaneo.
    if (!ref.read(preparationControllerProvider(_orderNumber)).hasAssignment) {
      await _assignLane();
      if (!mounted) return;
      if (!ref
          .read(preparationControllerProvider(_orderNumber))
          .hasAssignment) {
        showInfoSnack(context, 'Asigná un carril o vehículo para empezar.');
        return;
      }
    }

    final ean = await scanCode(
      context,
      title: 'Escanear EAN',
      helper: 'Escaneá el EAN del producto (SKU ${label.sku}).',
      formats: const <BarcodeFormat>[
        BarcodeFormat.ean13,
        BarcodeFormat.code128,
      ],
    );
    if (!mounted || ean == null) return;

    setState(() => _busyUnitId = label.labelId);
    try {
      // El GPS no debe trabar el escaneo: si no hay fix a tiempo, va en cero.
      final fix = await ref.read(locationServiceProvider).current();
      if (!mounted) return;
      final vehicleId = ref
          .read(preparationControllerProvider(_orderNumber))
          .vehicleId!;
      final now = DateTime.now();
      final outcome = await ref
          .read(recordPreparationScanProvider)
          .call(
            PreparationScanRequest(
              shipmentId: _orderNumber,
              unitId: label.labelId,
              lat: fix?.lat ?? 0,
              lng: fix?.lng ?? 0,
              occurredAt: now,
              vehicleId: vehicleId,
            ),
          );
      if (!mounted) return;
      if (outcome == SubmitOutcome.failed) {
        showSubmitOutcome(context, outcome);
        return;
      }
      ref
          .read(preparationControllerProvider(_orderNumber).notifier)
          .markPrepared(label.labelId);
      // Sin impresora, _printLabel ya avisó "Seleccioná una impresora": no se
      // pisa ese aviso con un "impresa" falso.
      final printed = await _printLabel(label);
      if (!mounted || !printed) return;
      // Offline invisible: encolado o enviado, para el usuario es lo mismo.
      showSuccessSnack(context, 'Unidad preparada e impresa.');
    } finally {
      if (mounted) setState(() => _busyUnitId = null);
    }
  }

  Future<void> _reprintUnit(EmittedLabel label) async {
    setState(() => _busyUnitId = label.labelId);
    try {
      final printed = await _printLabel(label);
      if (!mounted || !printed) return;
      showSuccessSnack(context, 'Etiqueta reenviada a la impresora.');
    } finally {
      if (mounted) setState(() => _busyUnitId = null);
    }
  }

  /// Imprime la etiqueta; devuelve false si no hay impresora utilizable (ya
  /// avisó al usuario).
  Future<bool> _printLabel(EmittedLabel label) async {
    try {
      await ref.read(labelPrinterProvider).printZpl(label.zpl);
      return true;
    } on PrinterException {
      if (mounted) {
        showInfoSnack(context, 'Seleccioná una impresora en Ajustes.');
      }
      return false;
    }
  }

  Future<void> _printAll(List<EmittedLabel> labels) async {
    if (labels.isEmpty || _orderBusy) return;
    setState(() => _orderBusy = true);
    try {
      // Ruta principal: ZPL firmado por el backend. Respaldo offline: el ZPL
      // local de cada etiqueta, por si no hay señal al momento de imprimir.
      String zpl;
      try {
        zpl = await ref.read(getSignedZplProvider).call(_orderNumber);
      } on ApiException {
        zpl = labels.map((l) => l.zpl).join('\n');
      }
      if (!mounted) return;
      try {
        await ref.read(labelPrinterProvider).printZpl(zpl);
        if (!mounted) return;
        showSuccessSnack(
          context,
          'Enviadas ${labels.length} etiquetas a la impresora.',
        );
      } on PrinterException {
        if (!mounted) return;
        showInfoSnack(context, 'Seleccioná una impresora en Ajustes.');
      }
    } finally {
      if (mounted) setState(() => _orderBusy = false);
    }
  }

  /// Emite el lote de etiquetas del pedido cuando todavía no existe ninguna.
  /// Pide origen, destino y las líneas del pedido en un formulario.
  Future<void> _emitLabels() async {
    if (_orderBusy) return;
    final result = await showLabelBatchSheet(
      context,
      title: 'Emitir etiquetas',
      submitLabel: 'Emitir etiquetas',
      requireReason: false,
    );
    if (!mounted || result == null) return;

    setState(() => _orderBusy = true);
    try {
      await ref
          .read(emitLabelsProvider)
          .call(
            _orderNumber,
            EmitLabelsRequest(
              origin: result.origin,
              destination: result.destination,
              lines: result.lines,
            ),
          );
      if (!mounted) return;
      ref.invalidate(orderLabelsProvider(_orderNumber));
      showSuccessSnack(context, 'Etiquetas emitidas.');
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.isConflict) {
        showInfoSnack(context, 'El pedido ya tiene etiquetas emitidas.');
      } else {
        showErrorSnack(context, e);
      }
    } finally {
      if (mounted) setState(() => _orderBusy = false);
    }
  }

  /// Reimprime el lote: revoca las etiquetas vigentes y emite identidades
  /// nuevas en el backend. Requiere un motivo (ADR 004).
  Future<void> _reprintBatch(List<EmittedLabel> current) async {
    if (_orderBusy) return;
    // Pre-carga las líneas agrupando las etiquetas vigentes por SKU.
    final initialLines = _linesFromLabels(current);
    final result = await showLabelBatchSheet(
      context,
      title: 'Reimprimir etiquetas',
      submitLabel: 'Reimprimir',
      requireReason: true,
      initialLines: initialLines,
    );
    if (!mounted || result == null) return;

    setState(() {
      _orderBusy = true;
      _reprintingBatch = true;
    });
    try {
      await ref
          .read(reprintLabelsProvider)
          .call(
            _orderNumber,
            ReprintLabelsRequest(
              origin: result.origin,
              destination: result.destination,
              lines: result.lines,
              reason: result.reason ?? '',
            ),
          );
      if (!mounted) return;
      ref.invalidate(orderLabelsProvider(_orderNumber));
      showSuccessSnack(
        context,
        'Lote reimpreso: se emitieron etiquetas nuevas.',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      showErrorSnack(context, e);
    } finally {
      if (mounted) {
        setState(() {
          _orderBusy = false;
          _reprintingBatch = false;
        });
      }
    }
  }

  /// Agrupa las etiquetas vigentes por SKU para proponer las líneas al
  /// reimprimir. El nombre no viaja en la etiqueta (ADR 004): se deja el SKU.
  List<EmitLabelLine> _linesFromLabels(List<EmittedLabel> labels) {
    final counts = <String, int>{};
    for (final label in labels) {
      counts[label.sku] = (counts[label.sku] ?? 0) + 1;
    }
    return counts.entries
        .map((e) => EmitLabelLine(sku: e.key, name: e.key, quantity: e.value))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final labelsAsync = ref.watch(orderLabelsProvider(_orderNumber));
    return Scaffold(
      appBar: AppBar(title: Text('Pedido $_orderNumber')),
      body: AsyncValueView<List<EmittedLabel>>(
        value: labelsAsync,
        onRetry: () => ref.invalidate(orderLabelsProvider(_orderNumber)),
        data: (labels) {
          final units = labels.where((l) => !l.revoked).toList(growable: false);
          if (units.isEmpty) return _buildEmpty();
          return _buildUnits(context, units);
        },
      ),
    );
  }

  Widget _buildEmpty() =>
      PreparationEmptyBody(busy: _orderBusy, onEmit: _emitLabels);

  Widget _buildUnits(BuildContext context, List<EmittedLabel> units) {
    final state = ref.watch(preparationControllerProvider(_orderNumber));
    final prepared = units.where((l) => state.isPrepared(l.labelId)).length;

    final progress = ProgressCard(
      prepared: prepared,
      total: units.length,
      lane: state.lane,
      busy: _orderBusy,
      reprinting: _reprintingBatch,
      onAssign: _assignLane,
      onPrintAll: () => _printAll(units),
      onReprintBatch: () => _reprintBatch(units),
    );
    final title = Text(
      'Unidades (${units.length})',
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
    // La lista de unidades puede ser larga: se construye perezosa (solo las
    // filas visibles) y en 2 columnas cuando el ancho lo permite.
    final unitRows = SliverAdaptiveCardRows(
      itemCount: units.length,
      maxColumns: 2,
      itemBuilder: (context, index) {
        final label = units[index];
        return UnitTile(
          key: ValueKey(label.labelId),
          label: label,
          prepared: state.isPrepared(label.labelId),
          busy: _busyUnitId == label.labelId,
          onPrepare: () => _prepareUnit(label),
          onReprint: () => _reprintUnit(label),
        );
      },
    );
    Future<void> refresh() async =>
        ref.invalidate(orderLabelsProvider(_orderNumber));

    return PreparationUnitsLayout(
      progress: progress,
      title: title,
      unitRows: unitRows,
      onRefresh: refresh,
    );
  }
}
