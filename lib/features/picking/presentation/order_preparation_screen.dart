import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/api/models/emit_label_line.dart';
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
import '../../../core/icons/icons.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../domain/order_number.dart';
import '../domain/usecases/emit_labels.dart';
import '../domain/usecases/get_signed_zpl.dart';
import '../domain/usecases/record_preparation_scan.dart';
import '../domain/usecases/reprint_labels.dart';
import 'controllers/order_labels_controller.dart';
import 'controllers/preparation_controller.dart';
import 'widgets/assign_lane_dialog.dart';
import 'widgets/dispatch_lines_body.dart';
import 'widgets/label_batch_sheet.dart';
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

  /// Operación a nivel pedido en curso (emitir, reimprimir lote, imprimir todo).
  bool _orderBusy = false;

  /// La operación de pedido en curso es "Reimprimir lote" (spinner propio).
  bool _reprintingBatch = false;

  String get _orderNumber => widget.orderNumber;

  /// Unidades vigentes (sin revocadas) de la última lista de etiquetas. Se
  /// recalcula solo si llega otra lista: cada escaneo hace dos `setState`
  /// (spinner de la fila) y no hace falta refiltrar cientos de etiquetas.
  List<EmittedLabel>? _labelsSource;
  List<EmittedLabel> _activeUnits = const [];

  List<EmittedLabel> _unitsOf(List<EmittedLabel> labels) {
    if (!identical(labels, _labelsSource)) {
      _labelsSource = labels;
      _activeUnits = labels.where((l) => !l.revoked).toList(growable: false);
    }
    return _activeUnits;
  }

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

  /// Verificación por escaneo del pedido ENTERO (un solo flujo, no por ítem):
  /// abre la cámara en escaneo continuo empezando por el primer producto por
  /// preparar; cada código leído marca su producto. Es opcional.
  Future<void> _verifyAll(List<EmittedLabel> units) async {
    final state = ref.read(preparationControllerProvider(_orderNumber));
    EmittedLabel? first;
    for (final u in units) {
      if (!state.isPrepared(u.labelId)) {
        first = u;
        break;
      }
    }
    if (first == null) return;
    await _prepareUnit(first);
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

    // Escaneo CONTINUO: la cámara queda abierta y cada EAN prepara una unidad.
    // El primero es la unidad tocada; los siguientes, la pendiente cuyo SKU
    // coincide con el código leído o, si ninguna coincide, la siguiente
    // pendiente de la lista (el EAN no viaja en la etiqueta, igual que antes
    // no se valida contra el producto).
    final session = _PrepSession(first: label);
    // El GPS se calienta junto con la cámara: al leer el EAN ya suele haber
    // fix y el registro no lo espera aparte.
    _warmUpLocation();
    await scanContinuous(
      context,
      title: 'Escanear producto',
      helper:
          'Escaneá el código de cada producto (empezá por SKU ${label.sku}).',
      formats: const <BarcodeFormat>[
        BarcodeFormat.ean13,
        BarcodeFormat.code128,
      ],
      onCode: (ean) => _prepareCode(ean, session),
    );
    if (!mounted || session.prepared == 0) return;
    // La impresión va en cola (no frena la cámara): se espera a que salga la
    // última etiqueta para avisar una sola vez.
    await session.printing;
    if (!mounted) return;
    final printError = session.printError;
    if (printError != null) {
      // Sin impresora o la impresora rechazó: no se anuncia "impresa" en
      // falso; se dice el motivo.
      showInfoSnack(context, printError);
      return;
    }
    if (session.unconfirmed) {
      // 9100 sin confirmación: veraz, se pide revisar que hayan salido.
      showSuccessSnack(
        context,
        session.prepared == 1
            ? 'Producto preparado. Etiqueta enviada; la impresora no '
                  'confirma, revisá que haya salido.'
            : '${session.prepared} productos preparados. Etiquetas '
                  'enviadas; la impresora no confirma, revisá que hayan '
                  'salido.',
      );
      return;
    }
    // Offline invisible: encolado o enviado, para el usuario es lo mismo.
    showSuccessSnack(
      context,
      session.prepared == 1
          ? 'Producto preparado e impreso.'
          : '${session.prepared} productos preparados e impresos.',
    );
  }

  /// Unidad que corresponde al próximo EAN de la ráfaga (ver [_prepareUnit]).
  EmittedLabel? _nextUnit(String code, _PrepSession session) {
    final first = session.takeFirst();
    final state = ref.read(preparationControllerProvider(_orderNumber));
    if (first != null && !state.isPrepared(first.labelId)) return first;
    final pending = _activeUnits
        .where((l) => !state.isPrepared(l.labelId))
        .toList(growable: false);
    if (pending.isEmpty) return null;
    return pending.firstWhere(
      (l) => l.sku == code,
      orElse: () => pending.first,
    );
  }

  /// Registra la preparación de una unidad por un EAN leído y encola su
  /// etiqueta en la impresora.
  Future<ScanFeedback> _prepareCode(String ean, _PrepSession session) async {
    if (!mounted) return const ScanFeedback.error('Pantalla cerrada');
    final label = _nextUnit(ean, session);
    if (label == null) {
      return const ScanFeedback.error('Pedido completo: no quedan productos');
    }

    // Feedback inmediato: la unidad se marca apenas se lee el código; si el
    // backend rechaza el registro (error de datos) se desmarca.
    final prep = ref.read(preparationControllerProvider(_orderNumber).notifier);
    prep.markPrepared(label.labelId);
    // Se leen antes de esperar: si el usuario sale de la pantalla, el escaneo
    // ya marcado igual se registra (no queda marcado sin registrar).
    final vehicleId = ref
        .read(preparationControllerProvider(_orderNumber))
        .vehicleId!;
    final record = ref.read(recordPreparationScanProvider);
    // Vista para dibujar la etiqueta si la impresora es de oficina.
    final view = View.of(context);
    setState(() => _busyUnitId = label.labelId);
    try {
      // El GPS no debe trabar el escaneo: si no hay fix a tiempo, va en cero.
      final fix = await _currentFix();
      final outcome = await record(
        PreparationScanRequest(
          shipmentId: _orderNumber,
          unitId: label.labelId,
          lat: fix?.lat ?? 0,
          lng: fix?.lng ?? 0,
          occurredAt: DateTime.now(),
          vehicleId: vehicleId,
        ),
      );
      if (outcome == SubmitOutcome.failed) {
        prep.unmarkPrepared(label.labelId);
        return ScanFeedback.error(submitOutcomeMessage(outcome));
      }
      session.prepared++;
      // Impresión en cola, en orden de escaneo: la Zebra puede tardar y la
      // cámara no espera a que salga cada etiqueta.
      session.enqueuePrint(() => _send(label, view));
      final state = ref.read(preparationControllerProvider(_orderNumber));
      final done = _activeUnits.where((l) => state.isPrepared(l.labelId));
      return ScanFeedback.ok(
        'Producto ${done.length}/${_activeUnits.length} preparado · SKU '
        '${label.sku}',
      );
    } finally {
      if (mounted) setState(() => _busyUnitId = null);
    }
  }

  /// Calienta el GPS sin esperar (nunca lanza).
  void _warmUpLocation() {
    try {
      ref.read(locationServiceProvider).prefetch();
    } on Object {
      // Sin plugin/permiso: lat/lng van en cero.
    }
  }

  /// Ubicación para el registro. Nunca falla: sin permiso, plugin o señal
  /// devuelve `null` (lat/lng van en cero); tras [_warmUpLocation] suele salir
  /// de la caché al instante.
  Future<GpsFix?> _currentFix() async {
    try {
      return await ref.read(locationServiceProvider).current();
    } on Object {
      return null;
    }
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
      reprinting: _reprintingBatch,
      onAssign: _assignLane,
      onPrintAll: () => _printAll(units),
      onReprintBatch: () => _reprintBatch(units),
      // Verificación por escaneo GLOBAL (un botón para el pedido, no por ítem).
      // Solo si quedan productos por preparar.
      onVerify: pending > 0 ? () => _verifyAll(units) : null,
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

/// Estado de una ráfaga de escaneo continuo del preparador: la unidad tocada
/// (va primero), cuántas se prepararon y la cola de impresión.
class _PrepSession {
  _PrepSession({required EmittedLabel first}) : _first = first;

  EmittedLabel? _first;
  int prepared = 0;

  /// Primer error de impresión de la ráfaga (texto para el operario).
  String? printError;

  /// Alguna etiqueta salió por 9100 sin confirmación de la impresora.
  bool unconfirmed = false;

  /// Cola serial de impresión: cada etiqueta sale cuando terminó la anterior.
  Future<void> printing = Future<void>.value();

  /// Devuelve la unidad tocada la primera vez y `null` después.
  EmittedLabel? takeFirst() {
    final first = _first;
    _first = null;
    return first;
  }

  void enqueuePrint(Future<PrintOutcome> Function() print) {
    printing = printing.then((_) async {
      try {
        final outcome = await print();
        if (outcome.kind == PrintOutcomeKind.sentUnconfirmed) {
          unconfirmed = true;
        }
      } on PrinterException catch (e) {
        printError ??= _OrderPreparationScreenState._printerErrorText(e);
      }
    });
  }
}
