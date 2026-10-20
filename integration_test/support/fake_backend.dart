import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/core/offline/offline_queue.dart';
import 'package:logistics_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:logistics_app/features/driver/domain/repositories/driver_route_repository.dart';
import 'package:logistics_app/features/picking/domain/repositories/picking_repository.dart';
import 'package:logistics_app/features/store/domain/repositories/store_repository.dart';

import '../../test/features/driver/support/driver_test_support.dart'
    show buildDelivery, buildMyCrew, buildStop;
import 'label_vector.dart';

// Backend falso de los tests de integración. Un solo objeto con el estado del
// "servidor" (usuarios, ruta del chofer, recepción de la tienda, pedido del
// preparador) que atiende a la app por dos vías:
//
// - LECTURAS: repositorios falsos (auth remoto, ruta, tienda, preparación) que
//   la app recibe vía overrides de Riverpod en lugar de los reales.
// - ESCRITURAS: el camino real de producción. Las pantallas llaman a la cola
//   offline REAL (Drift en memoria), que usa el dispatcher y el cliente
//   generado REALES; acá solo se reemplaza el transporte HTTP de Dio por
//   [FakeBackend.dio], que responde como el backend y registra lo recibido.
//
// Cualquier request HTTP no prevista se registra en [FakeBackend.unhandled] y
// se responde como "sin conexión": los tests verifican que quede vacía.

/// Usuario del backend falso.
class FakeUser {
  const FakeUser({
    required this.id,
    required this.name,
    required this.email,
    required this.roles,
    this.node,
  });

  final int id;
  final String name;
  final String email;
  final List<String> roles;
  final Node? node;

  AppUserProfile toProfile() => AppUserProfile(
    id: id,
    name: name,
    email: email,
    roles: roles,
    node: node,
  );
}

/// Request HTTP recibida por el backend falso.
class RecordedRequest {
  RecordedRequest(this.method, this.path, this.body, this.idempotencyKey);

  final String method;
  final String path;
  final Map<String, Object?> body;
  final String? idempotencyKey;

  @override
  String toString() => '$method $path';
}

class FakeBackend {
  FakeBackend() {
    dio = Dio(BaseOptions(baseUrl: 'http://backend.e2e/api/v1'))
      ..interceptors.add(InterceptorsWrapper(onRequest: _handle));
  }

  /// Contraseña de todos los usuarios de prueba.
  static const password = 'secreto';

  // ---------------------------------------------------------------------------
  // Datos maestros.
  // ---------------------------------------------------------------------------

  static final storeNode = Node(
    id: 'node-store',
    code: 'ST-01',
    name: 'Tienda Centro',
    type: NodeType.store,
    lat: -16.5,
    lng: -68.1,
    status: NodeStatus.active,
  );

  static final originNode = Node(
    id: 'node-cd',
    code: 'CD-SCZ',
    name: 'CD Santa Cruz',
    type: NodeType.distributionCenter,
    lat: -17.7,
    lng: -63.1,
    status: NodeStatus.active,
  );

  static final users = <String, FakeUser>{
    'chofer@dismac.test': const FakeUser(
      id: 1,
      name: 'Juan Chofer',
      email: 'chofer@dismac.test',
      roles: ['chofer'],
    ),
    'preparador@dismac.test': const FakeUser(
      id: 2,
      name: 'Pedro Andén',
      email: 'preparador@dismac.test',
      roles: ['preparador'],
    ),
    'tienda@dismac.test': FakeUser(
      id: 3,
      name: 'Tania Tienda',
      email: 'tienda@dismac.test',
      roles: const ['tienda'],
      node: storeNode,
    ),
    'transportista@dismac.test': const FakeUser(
      id: 4,
      name: 'Tito Transporte',
      email: 'transportista@dismac.test',
      roles: ['transportista'],
    ),
    'supervisor@dismac.test': const FakeUser(
      id: 5,
      name: 'Sara Supervisora',
      email: 'supervisor@dismac.test',
      roles: ['supervisor'],
    ),
    // Usuario de oficina: existe pero no tiene rol de terreno.
    'admin@dismac.test': const FakeUser(
      id: 6,
      name: 'Ana Admin',
      email: 'admin@dismac.test',
      roles: ['admin'],
    ),
  };

  FakeUser? loggedUser;
  int logins = 0;

  // ---------------------------------------------------------------------------
  // Transporte HTTP (escrituras reales de la cola offline).
  // ---------------------------------------------------------------------------

  late final Dio dio;

  /// Todas las requests HTTP atendidas, en orden.
  final List<RecordedRequest> requests = [];

  /// Requests que el backend falso no sabe atender (deben quedar vacías).
  final List<String> unhandled = [];

  List<RecordedRequest> requestsTo(String path) =>
      requests.where((r) => r.path == path).toList(growable: false);

  void _handle(RequestOptions options, RequestInterceptorHandler handler) {
    final data = options.data;
    final body = data is Map
        ? Map<String, Object?>.from(data)
        : const <String, Object?>{};
    final key = options.headers['Idempotency-Key'] as String?;
    final path = options.path;
    requests.add(RecordedRequest(options.method, path, body, key));

    final Object? response = switch ((options.method, path)) {
      ('POST', '/app/auth/logout') => {'message': 'Sesión cerrada.'},
      ('POST', '/app/deliveries/scans/unload') => _unload(body),
      ('POST', '/app/deliveries/proof-of-delivery') => _proofOfDelivery(body),
      ('POST', '/app/node-receptions/units') => _receiveUnit(body),
      ('POST', '/app/deliveries/scans/preparation') => _preparation(body),
      _ => null,
    };
    if (response == null) {
      unhandled.add('${options.method} $path');
      handler.reject(
        DioException.connectionError(
          requestOptions: options,
          reason: 'Backend e2e: endpoint no simulado',
        ),
      );
      return;
    }
    // Ida y vuelta por JSON: así el cliente generado parsea exactamente lo que
    // recibiría del backend real (modelos anidados incluidos).
    handler.resolve(
      Response<Object?>(
        requestOptions: options,
        statusCode: 200,
        data: jsonDecode(jsonEncode(response)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Chofer: ruta del día con dos paradas.
  // ---------------------------------------------------------------------------

  final crew = buildMyCrew();

  final List<DriverRouteStop> _stops = [
    buildStop(
      id: 'stop-1',
      shipmentId: 'ship-1',
      sequence: 1,
      customerName: 'Ana Pérez',
      orderReference: 'PED-1',
      address: 'Av. Banzer 123',
      lat: -17.78,
      lng: -63.18,
    ),
    buildStop(
      id: 'stop-2',
      shipmentId: 'ship-2',
      sequence: 2,
      customerName: 'Carlos Rojas',
      orderReference: 'PED-2',
      address: 'Calle Sucre 45',
      lat: -17.79,
      lng: -63.17,
    ),
  ];

  /// Envíos entregados (POD aceptado).
  final Set<String> delivered = {};

  /// Envíos entregados que la proyección de la ruta todavía no reflejó: el
  /// read model de la ruta se actualiza con un pequeño retraso (CQRS), por eso
  /// la app ofrece "Siguiente entrega" para refrescar. Se consume en la
  /// siguiente lectura de la ruta.
  final Set<String> _routeProjectionLag = {};

  final List<UnloadScanRequest> unloadScans = [];
  final List<ProofOfDeliveryRequest> proofsOfDelivery = [];

  DriverRoute driverRoute() {
    final stops = [
      for (final s in _stops)
        delivered.contains(s.shipmentId) &&
                !_routeProjectionLag.contains(s.shipmentId)
            ? buildStop(
                id: s.id,
                shipmentId: s.shipmentId,
                sequence: s.sequence,
                customerName: s.customerName,
                orderReference: s.orderReference,
                address: s.address,
                lat: s.lat,
                lng: s.lng,
                status: DriverRouteStopStatus.completed,
              )
            : s,
    ];
    _routeProjectionLag.clear();
    final completed = stops
        .where((s) => s.status == DriverRouteStopStatus.completed)
        .length;
    return DriverRoute(
      id: 'route-1',
      vehicleId: crew.vehicle.id,
      routeDate: DateTime.now(),
      status: DriverRouteStatus.inProgress,
      totalStops: stops.length,
      completedStops: completed,
      stopsRemaining: stops.length - completed,
      stops: stops,
    );
  }

  Shipment driverShipment(String shipmentId) {
    final stop = _stops.firstWhere((s) => s.shipmentId == shipmentId);
    return Shipment(
      id: shipmentId,
      source: OrderSource.store,
      externalId: stop.orderReference ?? shipmentId,
      customerName: stop.customerName ?? 'Cliente',
      customerPhone: '+591 70000001',
      addressText: stop.address ?? '',
      addressConfidenceScore: 90,
      addressConfidenceLevel: AddressConfidenceLevel.high,
      status: ShipmentStatus.inExecution,
      lines: const [
        ShipmentLine(
          id: 'l1',
          sku: 'LG-GT32WPP',
          productName: 'Refrigerador LG',
          quantity: 1,
        ),
      ],
    );
  }

  Delivery deliveryState(String shipmentId) => buildDelivery(
    id: 'del-$shipmentId',
    shipmentId: shipmentId,
    status: delivered.contains(shipmentId)
        ? DeliveryStatus.delivered
        : DeliveryStatus.inTransit,
  );

  Map<String, Object?> _unload(Map<String, Object?> body) {
    final scan = UnloadScanRequest.fromJson(body);
    unloadScans.add(scan);
    return {'data': deliveryState(scan.shipmentId)};
  }

  Map<String, Object?> _proofOfDelivery(Map<String, Object?> body) {
    final pod = ProofOfDeliveryRequest.fromJson(body);
    proofsOfDelivery.add(pod);
    delivered.add(pod.shipmentId);
    _routeProjectionLag.add(pod.shipmentId);
    return {'data': deliveryState(pod.shipmentId)};
  }

  // ---------------------------------------------------------------------------
  // Tienda: un envío que llega a la tienda del usuario con dos bultos.
  // ---------------------------------------------------------------------------

  static final storeShipment = Shipment(
    id: 'ship-store-1',
    source: OrderSource.sap,
    externalId: 'DM-260012345',
    customerName: 'María López',
    customerDocumentId: '12345678',
    addressText: 'Av. Siempre Viva 123',
    addressConfidenceScore: 90,
    addressConfidenceLevel: AddressConfidenceLevel.high,
    status: ShipmentStatus.inExecution,
    lines: const [
      ShipmentLine(
        id: 'line-1',
        sku: 'LG-GT32WPP',
        productName: 'Refrigerador LG',
        quantity: 1,
      ),
      ShipmentLine(
        id: 'line-2',
        sku: 'SKU-SOP',
        productName: 'Soporte de pared',
        quantity: 1,
      ),
    ],
  );

  /// Bultos esperados del envío: el del QR firmado del vector y uno con
  /// etiqueta sin firma (código simple).
  static const storeExpectedUnits = [vectorUnitId, 'BULTO-2'];

  OpenNodeReceptionRequest? openedReception;
  final List<String> receivedUnits = [];
  final List<ReceiveUnitAtNodeRequest> receiveRequests = [];
  bool reconciled = false;

  NodeReceptionView? nodeReception() {
    final opened = openedReception;
    if (opened == null) return null;
    final expected = opened.expectedUnitIds;
    final received = receivedUnits.toSet().toList();
    final missing = expected.where((u) => !received.contains(u)).toList();
    final surplus = received.where((u) => !expected.contains(u)).toList();
    return NodeReceptionView(
      id: 'reception-1',
      shipmentId: opened.shipmentId,
      originNodeId: opened.originNodeId,
      destinationNodeId: opened.destinationNodeId,
      corridor: NodeReceptionViewCorridor.cdToStore,
      status: reconciled
          ? NodeReceptionViewStatus.reconciled
          : NodeReceptionViewStatus.open,
      expectedUnitIds: expected,
      receivedUnitIds: received,
      missingUnitIds: missing,
      surplusUnitIds: surplus,
      expectedCount: expected.length,
      receivedCount: received.length,
      complete: missing.isEmpty && surplus.isEmpty,
      openedAt: opened.occurredAt,
      reconciledAt: reconciled ? DateTime.now() : null,
    );
  }

  Map<String, Object?> _receiveUnit(Map<String, Object?> body) {
    final request = ReceiveUnitAtNodeRequest.fromJson(body);
    receiveRequests.add(request);
    receivedUnits.add(request.unitId);
    return {'data': nodeReception()};
  }

  // ---------------------------------------------------------------------------
  // Preparador: un pedido con dos unidades ya etiquetadas.
  // ---------------------------------------------------------------------------

  static const pickingOrderNumber = 'PED-100';

  static final pickingOrder = Shipment(
    id: 'ship-ped-100',
    source: OrderSource.store,
    externalId: pickingOrderNumber,
    customerName: 'Luis Gómez',
    addressText: 'Av. Busch 500',
    addressConfidenceScore: 80,
    addressConfidenceLevel: AddressConfidenceLevel.high,
    status: ShipmentStatus.received,
    lines: const [
      ShipmentLine(
        id: 'line-1',
        sku: 'LG-GT32WPP',
        productName: 'Refrigerador LG',
        quantity: 2,
      ),
    ],
  );

  static final pickingLabels = [
    for (var i = 1; i <= 2; i++)
      EmittedLabel(
        orderNumber: pickingOrderNumber,
        labelId: 'LBL-0000000$i',
        keyId: 1,
        sku: 'LG-GT32WPP',
        lineNumber: 1,
        qrContent: '{"id":"LBL-0000000$i"}',
        zpl: '^XA^FDLBL-0000000$i^FS^XZ',
        emittedAt: 1700000000,
        revoked: false,
      ),
  ];

  static const signedOrderZpl = '^XA^FDPED-100 firmado^FS^XZ';

  final List<PreparationScanRequest> preparationScans = [];

  Map<String, Object?> _preparation(Map<String, Object?> body) {
    final scan = PreparationScanRequest.fromJson(body);
    preparationScans.add(scan);
    return {
      'data': buildDelivery(
        id: 'del-${scan.shipmentId}',
        shipmentId: scan.shipmentId,
        status: DeliveryStatus.prepared,
      ),
    };
  }
}

// -----------------------------------------------------------------------------
// Repositorios / fuentes falsas (lecturas) respaldadas por [FakeBackend].
// -----------------------------------------------------------------------------

/// `/app/auth/login` y `/app/auth/me`. El repositorio de auth es el REAL: mapea
/// el rol, abre la sesión y la persiste en el almacén seguro (falso en memoria).
class FakeAuthRemoteDataSource extends AuthRemoteDataSource {
  const FakeAuthRemoteDataSource(super.ref, this.backend);

  final FakeBackend backend;

  @override
  Future<AppLoginResponse> login(AppLoginRequest request) async {
    final user = FakeBackend.users[request.email];
    if (user == null || request.password != FakeBackend.password) {
      throw const ApiException(
        status: 401,
        title: 'Unauthenticated',
        detail: 'Credenciales inválidas.',
      );
    }
    backend
      ..loggedUser = user
      ..logins += 1;
    return AppLoginResponse(
      token: 'token-${user.id}-${backend.logins}',
      tokenType: 'Bearer',
      expiresAt: null,
      user: user.toProfile(),
      device: AppDevicePayload(
        uuid: request.device.fingerprint,
        platform: request.device.platform,
        name: request.device.name,
        lastSeenAt: null,
      ),
    );
  }

  @override
  Future<AppMeResponse> me() async {
    final user = backend.loggedUser;
    if (user == null) {
      throw const ApiException(status: 401, title: 'Unauthenticated');
    }
    // Sin abilities: la app cae a filtro solo-rol (degradación segura).
    return AppMeResponse(user: user.toProfile(), device: null, abilities: []);
  }
}

class FakeDriverRouteRepository implements DriverRouteRepository {
  FakeDriverRouteRepository(this.backend);

  final FakeBackend backend;

  @override
  Future<DriverRoute> getDriverRoute({
    required String vehicleId,
    required DateTime date,
  }) async => backend.driverRoute();

  @override
  Future<Shipment> getShipment({required String shipmentId}) async =>
      backend.driverShipment(shipmentId);

  @override
  Future<Delivery> getDeliveryState({required String shipmentId}) async =>
      backend.deliveryState(shipmentId);

  @override
  Future<List<Delivery>> listVehicleDeliveries({
    required String vehicleId,
  }) async => [
    backend.deliveryState('ship-1'),
    backend.deliveryState('ship-2'),
  ];

  @override
  Future<void> assembleDailyRoute({
    required String vehicleId,
    required DateTime date,
  }) async {}
}

class FakeStoreRepository implements StoreRepository {
  FakeStoreRepository(this.backend);

  final FakeBackend backend;

  @override
  Future<List<Node>> listNodes() async => [
    FakeBackend.storeNode,
    FakeBackend.originNode,
  ];

  @override
  Future<List<Shipment>> listShipments() async => [FakeBackend.storeShipment];

  @override
  Future<NodeReceptionView?> getNodeReception({
    required String shipmentId,
    required String nodeId,
  }) async => backend.nodeReception();

  @override
  Future<List<UnitTracking>> getShipmentUnits(String shipmentId) async => [
    for (final (i, unitId) in FakeBackend.storeExpectedUnits.indexed)
      UnitTracking(
        id: 'tracking-$unitId',
        unitId: unitId,
        shipmentId: shipmentId,
        status: UnitStatus.registered,
        lastLocationId: null,
        lastSeenAt: null,
        label: '${i + 1}/${FakeBackend.storeExpectedUnits.length}',
      ),
  ];

  @override
  Future<Delivery> getDeliveryState(String shipmentId) async =>
      buildDelivery(shipmentId: shipmentId);

  @override
  Future<void> openNodeReception(OpenNodeReceptionRequest body) async {
    backend.openedReception = body;
  }

  @override
  Future<void> reconcileNodeReception(
    ReconcileNodeReceptionRequest body,
  ) async {
    backend.reconciled = true;
  }
}

/// Lecturas del preparador desde el backend falso; el escaneo de preparación
/// va por la cola offline REAL (igual que `PickingRepositoryImpl`).
class FakePickingRepository implements PickingRepository {
  FakePickingRepository(this.backend, this.queue);

  final FakeBackend backend;
  final OfflineQueue queue;

  @override
  Future<List<Shipment>> listShipments() async => [FakeBackend.pickingOrder];

  @override
  Future<List<EmittedLabel>> getOrderLabels(String orderNumber) async =>
      orderNumber == FakeBackend.pickingOrderNumber
      ? FakeBackend.pickingLabels
      : const [];

  @override
  Future<List<EmittedLabel>> emitLabels(
    String orderNumber,
    EmitLabelsRequest body,
  ) => throw UnimplementedError('emitLabels no se usa en el e2e');

  @override
  Future<List<EmittedLabel>> reprintLabels(
    String orderNumber,
    ReprintLabelsRequest body,
  ) => throw UnimplementedError('reprintLabels no se usa en el e2e');

  @override
  Future<String> getSignedZpl(String orderNumber) async =>
      FakeBackend.signedOrderZpl;

  @override
  Future<SubmitOutcome> recordPreparationScan(PreparationScanRequest scan) =>
      queue.submit(
        kind: 'recordPreparationScan',
        payload: scan.toJson(),
        label: 'Preparación · pedido ${scan.shipmentId}',
        occurredAt: scan.occurredAt,
      );
}
