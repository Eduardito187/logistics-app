import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/models/emitted_label.dart';
import '../../../core/api/models/vehicle.dart';
import '../../../core/layout/adaptive_card_rows.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/printing/label_printer.dart';
import '../../../core/printing/printer_config.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/icons/icons.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../domain/order_number.dart';
import '../domain/usecases/assign_order_vehicle.dart';
import '../domain/usecases/emit_labels.dart';
import '../domain/usecases/get_signed_zpl.dart';
import 'controllers/order_labels_controller.dart';
import 'controllers/orders_worklist_controller.dart';
import 'controllers/preparation_controller.dart';
import 'widgets/assign_lane_dialog.dart';
import 'widgets/dispatch_lines_body.dart';
import 'widgets/label_preview_sheet.dart';
import 'widgets/preparation_units_layout.dart';
import 'widgets/printable_label_renderer.dart';
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

  /// Operación a nivel pedido en curso (emitir, imprimir todo).
  bool _orderBusy = false;

  String get _orderNumber => widget.orderNumber;

  /// Unidades vigentes (sin revocadas) de la última lista de etiquetas. Se
  /// recalcula solo si llega otra lista: cada escaneo hace dos `setState`
  /// (spinner de la fila) y no hace falta refiltrar cientos de etiquetas.
  List<EmittedLabel>? _labelsSource;
  List<EmittedLabel> _activeUnits = const [];

  List<EmittedLabel> _unitsOf(List<EmittedLabel> labels) {
    if (!identical(labels, _labelsSource)) {
      _labelsSource = labels;
      // Etiquetas PERMANENTES: no hay anuladas, se toman todas.
      _activeUnits = List<EmittedLabel>.unmodifiable(labels);
    }
    return _activeUnits;
  }

  Future<void> _assignLane() async {
    final current = ref.read(preparationControllerProvider(_orderNumber));
    final vehicle = await showDialog<Vehicle>(
      context: context,
      builder: (_) => AssignLaneDialog(initial: current.lane),
    );
    if (!mounted || vehicle == null) return;
    final plate = (vehicle.plate ?? '').trim();

    setState(() => _orderBusy = true);
    try {
      // ATA el pedido al vehículo EN EL BACKEND: así deja de figurar en
      // "Pedidos por preparar" y pasa a la ruta de ese camión. Antes esto era
      // solo estado local y el pedido seguía apareciendo en la worklist.
      await ref.read(assignOrderVehicleProvider).call(_orderNumber, vehicle.id);
      if (!mounted) return;
      ref
          .read(preparationControllerProvider(_orderNumber).notifier)
          .assign(vehicleId: vehicle.id, lane: plate.isEmpty ? null : plate);
      // Asignar el vehículo PREPARA el pedido: sus etiquetas quedan marcadas
      // como preparadas (ya no hay escaneo del producto, decisión del dueño).
      _markAllPrepared();
      // La worklist ya no debe mostrarlo.
      ref.invalidate(ordersWorklistProvider);
      showSuccessSnack(
        context,
        plate.isEmpty
            ? 'Pedido asignado al vehículo.'
            : 'Pedido asignado al vehículo $plate.',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _orderBusy = false);
    }
  }

  /// Marca TODAS las etiquetas del pedido como preparadas.
  void _markAllPrepared() {
    final prep = ref.read(preparationControllerProvider(_orderNumber).notifier);
    for (final label in _activeUnits) {
      prep.markPrepared(label.labelId);
    }
  }

  /// "Marcar como preparadas" a mano. EXIGE vehículo asignado: sin vehículo no
  /// se puede preparar (acción limitada) y se ofrece asignarlo ahí mismo.
  Future<void> _markPreparedManually() async {
    if (!ref.read(preparationControllerProvider(_orderNumber)).hasAssignment) {
      showInfoSnack(
        context,
        'Asigná el vehículo antes de marcar como preparadas.',
      );
      await _assignLane();
      return;
    }
    _markAllPrepared();
    if (!mounted) return;
    showSuccessSnack(context, 'Productos marcados como preparados.');
  }

  /// Manda una etiqueta a la impresora activa: el ZPL a las Zebra o la
  /// etiqueta dibujada (fuera de pantalla) a las de oficina.
  Future<PrintOutcome> _send(EmittedLabel label, ui.FlutterView view) {
    return ref
        .read(labelPrinterProvider)
        .printLabel(
          zpl: label.zpl,
          render: printableLabelRenderer(label, view: view),
          jobName: 'Etiqueta ${label.orderNumber} L${label.lineNumber}',
        );
  }

  /// Texto del error de impresión para el operario.
  static String _printerErrorText(PrinterException e) =>
      e.message == PrinterException.notSelected.message
      ? 'Seleccioná una impresora en Ajustes.'
      : e.message;

  /// Imprime la etiqueta de un producto (acción principal del tile y de la
  /// vista previa) y dice, veraz, qué pasó.
  Future<void> _printUnit(EmittedLabel label) async {
    setState(() => _busyUnitId = label.labelId);
    try {
      final outcome = await _printLabel(label);
      if (!mounted || outcome == null) return;
      if (outcome.kind == PrintOutcomeKind.sentUnconfirmed) {
        showInfoSnack(context, outcome.message);
      } else {
        showSuccessSnack(context, outcome.message);
      }
    } finally {
      if (mounted) setState(() => _busyUnitId = null);
    }
  }

  /// Imprime la etiqueta; `null` si falló (ya avisó el motivo al usuario).
  Future<PrintOutcome?> _printLabel(EmittedLabel label) async {
    try {
      return await _send(label, View.of(context));
    } on PrinterException catch (e) {
      if (mounted) showInfoSnack(context, _printerErrorText(e));
      return null;
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
      final printer = ref.read(labelPrinterProvider);
      final view = View.of(context);
      PrinterConfig? target;
      try {
        target = await printer.selectedPrinter();
      } on Object {
        target = null;
      }
      try {
        PrintOutcome outcome;
        if (target != null && target.isOffice) {
          // Oficina: no entiende ZPL; una hoja por etiqueta, dibujada.
          outcome = const PrintOutcome.sent();
          for (final label in labels) {
            outcome = await _send(label, view);
          }
        } else {
          outcome = await printer.printLabel(
            zpl: zpl,
            jobName: 'Etiquetas $_orderNumber',
          );
        }
        if (!mounted) return;
        showSuccessSnack(
          context,
          outcome.kind == PrintOutcomeKind.sent
              ? 'Enviadas ${labels.length} etiquetas a la impresora.'
              : 'Enviadas ${labels.length} etiquetas. ${outcome.message}',
        );
      } on PrinterException catch (e) {
        if (!mounted) return;
        showInfoSnack(context, _printerErrorText(e));
      }
    } finally {
      if (mounted) setState(() => _orderBusy = false);
    }
  }

  /// Emite las etiquetas del pedido POR ORDEN, sin formulario: el backend
  /// deriva origen, destino y líneas de la orden (plan publicado) y emite una
  /// etiqueta por producto autorizado. Idempotente: si ya estaban, refresca.
  Future<void> _emitLabels() async {
    if (_orderBusy) return;
    setState(() => _orderBusy = true);
    try {
      final labels = await ref.read(emitOrderLabelsProvider).call(_orderNumber);
      if (!mounted) return;
      ref
        ..invalidate(orderLabelsProvider(_orderNumber))
        ..invalidate(orderDispatchLinesProvider(_orderNumber));
      showSuccessSnack(
        context,
        labels.isEmpty
            ? 'No hay productos autorizados para etiquetar todavía.'
            : 'Etiquetas emitidas: ${labels.length}.',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.isConflict) {
        ref.invalidate(orderLabelsProvider(_orderNumber));
        showInfoSnack(context, 'El pedido ya tiene todas sus etiquetas.');
      } else {
        showErrorSnack(context, e);
      }
    } finally {
      if (mounted) setState(() => _orderBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Defensa: un código que no es un pedido (p. ej. el JSON de una etiqueta QR
    // llegado por un link viejo) nunca va al título ni se consulta al backend.
    if (!isPlausibleOrderNumber(_orderNumber)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pedido')),
        body: const EmptyState(
          icon: AppIcon.error,
          title: 'Ese código no es un número de pedido',
          message:
              'Volvé atrás y escaneá la etiqueta de un producto del pedido.',
        ),
      );
    }
    final labelsAsync = ref.watch(orderLabelsProvider(_orderNumber));
    return Scaffold(
      appBar: AppBar(title: Text('Pedido $_orderNumber')),
      body: AsyncValueView<List<EmittedLabel>>(
        value: labelsAsync,
        onRetry: () => ref.invalidate(orderLabelsProvider(_orderNumber)),
        data: (labels) {
          final units = _unitsOf(labels);
          if (units.isEmpty) return _buildEmpty();
          return _buildUnits(context, units);
        },
      ),
    );
  }

  /// Sin etiquetas emitidas todavía: en vez del viejo formulario manual
  /// (origen/destino/SKU a mano), se muestra la LISTA de productos del pedido
  /// (dispatch-lines: nombre, SKU, foto y destino ya resueltos) y el botón para
  /// emitir el lote.
  Widget _buildEmpty() => DispatchLinesBody(
    orderNumber: _orderNumber,
    busy: _orderBusy,
    onEmit: _emitLabels,
  );

  Widget _buildUnits(BuildContext context, List<EmittedLabel> units) {
    final state = ref.watch(preparationControllerProvider(_orderNumber));
    final prepared = units.where((l) => state.isPrepared(l.labelId)).length;
    final pending = units.length - prepared;

    final progress = ProgressCard(
      prepared: prepared,
      total: units.length,
      lane: state.lane,
      busy: _orderBusy,
      onAssign: _assignLane,
      onPrintAll: () => _printAll(units),
      // Marcar a mano las que falten. Exige vehículo asignado (lo valida).
      onMarkPrepared: pending > 0 ? _markPreparedManually : null,
    );
    final title = Text(
      'Productos (${units.length})',
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
          onPrint: () => _printUnit(label),
          // Ver la etiqueta (QR real + datos del backend: nombre, foto,
          // destino) antes de imprimir, o solo verla.
          onPreview: () => showLabelPreviewSheet(
            context,
            label: label,
            productName: label.productName,
            imageUrl: label.imageUrl,
            destination: labelDestinationText(label.destination),
            onPrint: () => _printUnit(label),
          ),
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
