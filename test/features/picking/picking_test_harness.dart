import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logistics_app/core/api/models/address_confidence_level.dart';
import 'package:logistics_app/core/api/models/emit_labels_request.dart';
import 'package:logistics_app/core/api/models/emitted_label.dart';
import 'package:logistics_app/core/api/models/order_source.dart';
import 'package:logistics_app/core/api/models/preparation_scan_request.dart';
import 'package:logistics_app/core/api/models/reprint_labels_request.dart';
import 'package:logistics_app/core/api/models/shipment.dart';
import 'package:logistics_app/core/api/models/shipment_line.dart';
import 'package:logistics_app/core/api/models/shipment_status.dart';
import 'package:logistics_app/core/location/location_service.dart';
import 'package:logistics_app/core/offline/app_database.dart';
import 'package:logistics_app/core/offline/connectivity_notifier.dart';
import 'package:logistics_app/core/offline/submit_outcome.dart';
import 'package:logistics_app/core/printing/label_printer.dart';
import 'package:logistics_app/core/printing/printer_config.dart';
import 'package:logistics_app/core/offline/sync_queue_provider.dart';
import 'package:logistics_app/features/picking/domain/repositories/picking_repository.dart';

/// Repositorio de preparación totalmente controlable por los tests. Cada método
/// delega en una función inyectada; por defecto devuelve datos vacíos/neutros.
/// También registra argumentos y cantidad de llamadas para verificar el cableado.
class FakePickingRepository implements PickingRepository {
  FakePickingRepository({
    this.onListShipments,
    this.onGetOrderLabels,
    this.onEmitLabels,
    this.onReprintLabels,
    this.onGetSignedZpl,
    this.onRecordScan,
  });

  Future<List<Shipment>> Function()? onListShipments;
  Future<List<EmittedLabel>> Function(String orderNumber)? onGetOrderLabels;
  Future<List<EmittedLabel>> Function(
    String orderNumber,
    EmitLabelsRequest body,
  )?
  onEmitLabels;
  Future<List<EmittedLabel>> Function(
    String orderNumber,
    ReprintLabelsRequest body,
  )?
  onReprintLabels;
  Future<String> Function(String orderNumber)? onGetSignedZpl;
  Future<SubmitOutcome> Function(PreparationScanRequest scan)? onRecordScan;

  // Espías de las escrituras.
  int emitCalls = 0;
  int reprintCalls = 0;
  int recordScanCalls = 0;
  String? lastEmitOrder;
  EmitLabelsRequest? lastEmitBody;
  String? lastReprintOrder;
  ReprintLabelsRequest? lastReprintBody;
  PreparationScanRequest? lastScan;

  /// Estado pedido en cada `listShipments` (filtro de servidor).
  final List<ShipmentStatus?> listShipmentsStatuses = <ShipmentStatus?>[];

  @override
  Future<List<Shipment>> listShipments({ShipmentStatus? status}) {
    listShipmentsStatuses.add(status);
    return (onListShipments ?? (() async => <Shipment>[]))();
  }

  @override
  Future<List<EmittedLabel>> getOrderLabels(String orderNumber) =>
      (onGetOrderLabels ?? ((_) async => <EmittedLabel>[]))(orderNumber);

  @override
  Future<List<EmittedLabel>> emitLabels(
    String orderNumber,
    EmitLabelsRequest body,
  ) {
    emitCalls++;
    lastEmitOrder = orderNumber;
    lastEmitBody = body;
    return (onEmitLabels ?? ((_, _) async => <EmittedLabel>[]))(
      orderNumber,
      body,
    );
  }

  @override
  Future<List<EmittedLabel>> reprintLabels(
    String orderNumber,
    ReprintLabelsRequest body,
  ) {
    reprintCalls++;
    lastReprintOrder = orderNumber;
    lastReprintBody = body;
    return (onReprintLabels ?? ((_, _) async => <EmittedLabel>[]))(
      orderNumber,
      body,
    );
  }

  @override
  Future<String> getSignedZpl(String orderNumber) =>
      (onGetSignedZpl ?? ((_) async => ''))(orderNumber);

  @override
  Future<SubmitOutcome> recordPreparationScan(PreparationScanRequest scan) {
    recordScanCalls++;
    lastScan = scan;
    return (onRecordScan ?? ((_) async => SubmitOutcome.sent))(scan);
  }
}

/// Servicio de ubicación fijo que NO toca el GPS real (geolocator).
class FakeLocationService extends LocationService {
  FakeLocationService({this.fix});

  final GpsFix? fix;

  @override
  Future<GpsFix?> current({
    Duration timeout = const Duration(seconds: 6),
  }) async => fix;
}

/// Impresora falsa: registra los ZPL enviados y opcionalmente lanza
/// [PrinterException] para simular que no hay impresora seleccionada.
class FakeLabelPrinter extends LabelPrinter {
  FakeLabelPrinter({this.throwOnPrint = false})
    : super(const FlutterSecureStorage());

  bool throwOnPrint;
  final List<String> printed = <String>[];

  @override
  Future<void> printZpl(String zpl, {PrinterConfig? to}) async {
    printed.add(zpl);
    if (throwOnPrint) {
      throw const PrinterException('No hay impresora seleccionada.');
    }
  }
}

/// Conectividad fija (siempre en línea) que NO toca el plugin connectivity_plus.
class _StubConnectivity extends ConnectivityNotifier {
  @override
  Future<bool> build() async => true;
}

/// Overrides para que el [SyncBadge] de las AppBars renderice sin Drift ni el
/// plugin de conectividad (cola vacía, en línea).
List<Override> syncBadgeOverrides() => [
  syncQueueProvider.overrideWith((ref) => Stream.value(<OutboxAction>[])),
  connectivityProvider.overrideWith(_StubConnectivity.new),
];

// --- Fixtures del contrato -------------------------------------------------

/// Pedido de ejemplo. [lineCount] define cuántas líneas trae y
/// [quantityPerLine] cuántas unidades (paquetes) tiene cada una.
Shipment buildShipment({
  String externalId = 'EXT-1',
  String customerName = 'Cliente Demo',
  ShipmentStatus status = ShipmentStatus.received,
  int lineCount = 1,
  int quantityPerLine = 1,
}) {
  return Shipment(
    id: 'id-$externalId',
    source: OrderSource.store,
    externalId: externalId,
    customerName: customerName,
    addressText: 'Av. Siempre Viva 123',
    addressConfidenceScore: 80,
    addressConfidenceLevel: AddressConfidenceLevel.high,
    status: status,
    lines: List<ShipmentLine>.generate(
      lineCount,
      (i) => ShipmentLine(
        id: 'line-$i',
        sku: 'SKU$i',
        productName: 'Producto $i',
        quantity: quantityPerLine,
      ),
    ),
  );
}

/// Etiqueta emitida de ejemplo.
EmittedLabel buildLabel({
  String orderNumber = 'EXT-1',
  String labelId = 'LBL-00000001',
  String sku = 'SKU1',
  int lineNumber = 1,
  bool revoked = false,
  String zpl = '^XA^FDuno^XZ',
}) {
  return EmittedLabel(
    orderNumber: orderNumber,
    labelId: labelId,
    keyId: 1,
    sku: sku,
    lineNumber: lineNumber,
    qrContent: '{"id":"$labelId"}',
    zpl: zpl,
    emittedAt: 1700000000,
    revoked: revoked,
  );
}
