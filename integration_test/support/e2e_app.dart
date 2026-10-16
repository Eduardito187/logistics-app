import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logistics_app/app.dart';
import 'package:logistics_app/core/labels/label_scanner.dart';
import 'package:logistics_app/core/location/location_service.dart';
import 'package:logistics_app/core/location/truck_tracking_service.dart';
import 'package:logistics_app/core/media/photo_picker.dart';
import 'package:logistics_app/core/network/dio_client.dart';
import 'package:logistics_app/core/offline/app_database.dart';
import 'package:logistics_app/core/offline/offline_queue.dart';
import 'package:logistics_app/core/offline/photo_upload_queue.dart';
import 'package:logistics_app/core/printing/label_printer.dart';
import 'package:logistics_app/core/push/push_controller.dart';
import 'package:logistics_app/core/scanning/code_scanner.dart';
import 'package:logistics_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:logistics_app/features/driver/data/repositories/driver_route_repository_impl.dart';
import 'package:logistics_app/features/driver/data/repositories/fleet_repository_impl.dart';
import 'package:logistics_app/features/picking/data/repositories/picking_repository_impl.dart';
import 'package:logistics_app/features/store/data/repositories/store_repository_impl.dart';

import '../../test/features/driver/support/driver_test_support.dart'
    show FakeFleetRepository, FakeLocationService, FakeTruckTracking;
import '../../test/features/picking/picking_test_harness.dart'
    show FakeLabelPrinter;
import '../../test/support/fake_code_scanner.dart';
import '../../test/support/fake_photo_picker.dart';
import 'fake_backend.dart';
import 'label_vector.dart';

export '../../test/features/picking/picking_test_harness.dart'
    show FakeLabelPrinter;
export '../../test/support/button_finders.dart';
export '../../test/support/fake_code_scanner.dart';
export '../../test/support/fake_photo_picker.dart';
export 'fake_backend.dart';
export 'label_vector.dart';

// Arranque de la app REAL (`LogisticsApp`: router, tema, home por rol, cola
// offline, sesión persistente) con dobles SOLO en los bordes:
//
// | Borde        | Doble                                                    |
// |--------------|----------------------------------------------------------|
// | Backend      | FakeBackend: lecturas por repositorios falsos; escrituras |
// |              | por la cola offline real → cliente generado → Dio falso   |
// | Storage      | FlutterSecureStorage en memoria + Drift en memoria         |
// | Cámara       | FakeCodeScanner (códigos) + FakePhotoPicker (fotos)        |
// | GPS          | FakeLocationService + FakeTruckTracking (sin servicio FG)  |
// | Impresora    | FakeLabelPrinter (registra el ZPL)                         |
// | Push/red     | push sin configurar; conectividad fija "en línea"          |

/// Conectividad fija (en línea) sin tocar el plugin connectivity_plus.
class _OnlineConnectivity extends ConnectivityNotifier {
  @override
  Future<bool> build() async => true;
}

/// Claves de etiquetas: las del vector, sin ir al backend a refrescarlas.
class _VectorLabelKeys extends LabelKeysNotifier {
  @override
  Map<int, List<int>> build() => vectorKeys();

  @override
  Future<void> refresh() async {}
}

/// Cola de fotos falsa: registra lo encolado (la subida multipart y el
/// directorio de documentos quedan fuera del e2e: dependen de path_provider).
class FakePhotoUploadQueue implements PhotoUploadQueue {
  final List<({String shipmentId, String filePath, String kind})> enqueued = [];

  @override
  Future<void> enqueue({
    required String shipmentId,
    required String filePath,
    required String kind,
  }) async {
    enqueued.add((shipmentId: shipmentId, filePath: filePath, kind: kind));
  }

  @override
  Future<void> drain() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Todo lo que un test de flujo necesita para manejar y verificar la app.
class E2eHarness {
  E2eHarness({
    required this.backend,
    required this.scanner,
    required this.picker,
    required this.printer,
    required this.photos,
    required this.database,
  });

  final FakeBackend backend;
  final FakeCodeScanner scanner;
  final FakePhotoPicker picker;
  final FakeLabelPrinter printer;
  final FakePhotoUploadQueue photos;
  final AppDatabase database;

  /// Contenedor de Riverpod de la app montada.
  late ProviderContainer container;

  /// Acciones de la cola offline todavía sin subir (0 = todo sincronizado).
  Future<int> pendingOutbox() => database.countPendingActions();
}

/// Inicialización común: fechas en español (como `main.dart`) y almacén seguro
/// en memoria y vacío (sin sesión guardada).
Future<void> e2eSetUp() async {
  await initializeDateFormatting('es');
  FlutterSecureStorage.setMockInitialValues({});
  // Cada test abre su propia base Drift en memoria a propósito.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
}

/// En el host (flutter_tester) la superficie por defecto es 800x600: se usa un
/// teléfono típico (360x800 dp). En un dispositivo real se respeta su pantalla.
void _usePhoneSurfaceOnHost(WidgetTester tester) {
  if (Platform.isAndroid || Platform.isIOS) return;
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Monta la app real con los dobles de borde y deja la pantalla de login.
Future<E2eHarness> pumpE2eApp(
  WidgetTester tester, {
  List<String?> scans = const [],
  List<String?> photos = const [],
  bool printerFails = false,
}) async {
  _usePhoneSurfaceOnHost(tester);
  final backend = FakeBackend();
  final database = AppDatabase(NativeDatabase.memory());
  final h = E2eHarness(
    backend: backend,
    scanner: FakeCodeScanner(scans),
    picker: FakePhotoPicker(photos),
    printer: FakeLabelPrinter(throwOnPrint: printerFails),
    photos: FakePhotoUploadQueue(),
    database: database,
  );

  final overrides = <Override>[
    // Backend.
    dioProvider.overrideWithValue(backend.dio),
    authRemoteDataSourceProvider.overrideWith(
      (ref) => FakeAuthRemoteDataSource(ref, backend),
    ),
    fleetRepositoryProvider.overrideWithValue(
      FakeFleetRepository(crew: backend.crew),
    ),
    driverRouteRepositoryProvider.overrideWithValue(
      FakeDriverRouteRepository(backend),
    ),
    storeRepositoryProvider.overrideWithValue(FakeStoreRepository(backend)),
    pickingRepositoryProvider.overrideWith(
      (ref) => FakePickingRepository(backend, ref.watch(offlineQueueProvider)),
    ),
    labelKeysProvider.overrideWith(_VectorLabelKeys.new),
    labelScannerProvider.overrideWithValue(vectorLabelScanner()),
    // Storage (el secure storage se mockea en e2eSetUp).
    appDatabaseProvider.overrideWithValue(database),
    photoUploadQueueProvider.overrideWithValue(h.photos),
    // Cámara.
    codeScannerProvider.overrideWithValue(h.scanner.call),
    photoPickerProvider.overrideWithValue(h.picker.call),
    // GPS.
    locationServiceProvider.overrideWithValue(
      FakeLocationService(fix: e2eGpsFix),
    ),
    truckTrackingProvider.overrideWith(FakeTruckTracking.new),
    // Impresora.
    labelPrinterProvider.overrideWithValue(h.printer),
    // Push y red.
    pushConfiguredProvider.overrideWithValue(false),
    connectivityProvider.overrideWith(_OnlineConnectivity.new),
  ];

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      // Sin reintentos automáticos: un error debe verse, no reintentarse.
      retry: (_, _) => null,
      child: const LogisticsApp(),
    ),
  );
  await settle(tester);
  h.container = ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp)),
  );
  return h;
}

/// `pumpAndSettle` tolerante: en un dispositivo el mapa puede seguir animando
/// tiles; si no se asienta en [timeout] se sigue igual (los `expect` posteriores
/// son los que validan la pantalla).
Future<void> settle(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  try {
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      timeout,
    );
  } on FlutterError {
    // Animación continua (tiles/spinner): se continúa.
  }
}

/// Bombea frames hasta que [finder] encuentre algo (o falla tras [maxTries]).
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxTries = 100,
}) async {
  for (var i = 0; i < maxTries; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsWidgets, reason: 'No apareció a tiempo');
}

/// Lleva [finder] a la vista (scroll) y lo toca.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await pumpUntilFound(tester, finder);
  // Centrado en su lista: al pie podría quedar tapado por un aviso flotante.
  final element = tester.element(finder.first);
  if (Scrollable.maybeOf(element) != null) {
    await Scrollable.ensureVisible(element, alignment: 0.5);
  }
  await tester.pump();
  // Un aviso (SnackBar) puede tapar el botón unos segundos, como en la mano
  // del usuario: se espera a que el toque llegue de verdad al widget.
  await pumpUntil(
    tester,
    () => finder.first.hitTestable().evaluate().isNotEmpty,
    reason: 'Algo tapa $finder',
  );
  await tester.tap(finder.first);
  await settle(tester);
}

/// Bombea frames hasta que [condition] se cumpla (o falla tras [maxTries]).
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  String reason = 'La condición no se cumplió a tiempo',
  int maxTries = 100,
}) async {
  for (var i = 0; i < maxTries; i++) {
    if (condition()) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
  fail(reason);
}

/// Ingresa con [email] y la contraseña de prueba desde la pantalla de login.
Future<void> login(
  WidgetTester tester,
  String email, {
  String password = FakeBackend.password,
}) async {
  await pumpUntilFound(tester, find.text('Ingresá a tu cuenta'));
  final fields = find.byType(TextField);
  await tester.enterText(fields.first, email);
  await tester.enterText(fields.last, password);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await settle(tester);
}

/// Cierra sesión desde el inicio del rol.
Future<void> logout(WidgetTester tester) async {
  await tapVisible(tester, find.byTooltip('Cerrar sesión'));
  await pumpUntilFound(tester, find.text('Ingresar'));
}

/// PNG de 1x1 escrito en un temporal: la foto "tomada" por la cámara falsa
/// tiene que existir (la vista previa la decodifica de verdad en el
/// dispositivo).
String writeFakePhoto(String name) {
  final dir = Directory.systemTemp.createTempSync('e2e_photos');
  final file = File('${dir.path}${Platform.pathSeparator}$name')
    ..writeAsBytesSync(
      base64.decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
      ),
    );
  return file.path;
}

/// Posición GPS del dispositivo en los e2e: a unas cuadras de la parada 1.
///
/// OJO (reportado): NO usar exactamente las coordenadas de la parada. Con el
/// camión justo en el destino, `DeliveryMap` hace `CameraFit.coordinates` sobre
/// dos puntos iguales sin `maxZoom` y flutter_map calcula zoom infinito
/// ("Infinity or NaN toInt" en TileLayer/PolylineLayer/MarkerLayer).
const e2eGpsFix = GpsFix(lat: -17.80, lng: -63.20);
