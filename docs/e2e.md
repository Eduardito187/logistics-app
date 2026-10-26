# Tests de integración (e2e)

`integration_test/` ejercita los **4 flujos críticos** con la app real (`LogisticsApp`: router,
tema, inicio por rol, sesión persistente, cola offline) y dobles **solo en los bordes**. Complementa
la batería de widget tests de `test/`: acá se prueba que las piezas encajan de punta a punta.

| # | Flujo | Archivo | Qué verifica |
|---|---|---|---|
| 1 | Login → inicio por rol | `flows/login_flow.dart` | credenciales malas y usuario sin rol de terreno no entran; los 5 roles entran a su inicio con sus tarjetas (y no las de otros), la sesión queda en el almacén seguro y "Cerrar sesión" la revoca en el backend |
| 2 | Chofer: entrega | `flows/driver_delivery_flow.dart` | entrega en curso (parada 1 de 2) → escanear bultos (QR firmado) → entregar: sin foto el botón queda deshabilitado; con foto se registra el POD → "Siguiente entrega" → parada 2 de 2 |
| 3 | Tienda: recepción | `flows/store_reception_flow.dart` | tienda fija del usuario (sin selector) → abrir recepción con nodo de origen → etiqueta adulterada rechazada → 2 bultos recibidos (con y sin ubicación en estante) → conciliar |
| 4 | Picking | `flows/picking_flow.dart` | pedido → asignar carril → escanear EAN por unidad → imprime el ZPL de cada etiqueta → "Imprimir todas" con el ZPL firmado; y sin impresora: registra igual y pide elegirla |

Un único punto de entrada (`integration_test/app_test.dart`) llama a los cuatro: en un dispositivo
se compila e instala **una sola vez** (menos tiempo y RAM que un APK por archivo).

## Dobles de prueba

| Borde | Doble | Notas |
|---|---|---|
| Backend (lecturas) | `support/fake_backend.dart`: repositorios falsos (auth remoto, ruta, flota, tienda, preparación) | un solo `FakeBackend` con estado coherente entre pantallas |
| Backend (escrituras) | **cola offline real** + dispatcher real + cliente generado real → `Dio` con interceptor de `FakeBackend` | responde como el backend (`{data: ...}`), registra body e `Idempotency-Key`; cualquier endpoint no simulado queda en `backend.unhandled` (los tests exigen que esté vacío) |
| Storage | `FlutterSecureStorage.setMockInitialValues({})` + Drift `NativeDatabase.memory()` | la sesión se persiste y se verifica de verdad |
| Cámara | `FakeCodeScanner` y `FakePhotoPicker` de `test/support/` (vía `codeScannerProvider` / `photoPickerProvider`) | la foto es un PNG real en un temporal (en el dispositivo la vista previa la decodifica) |
| GPS | `FakeLocationService` + `FakeTruckTracking` de `test/features/driver/support/` | sin servicio en primer plano ni permisos reales |
| Impresora | `FakeLabelPrinter` de `test/features/picking/picking_test_harness.dart` | registra el ZPL enviado |
| Fotos | `FakePhotoUploadQueue` | la subida multipart y `path_provider` quedan fuera |
| Push / red | `pushConfiguredProvider=false`; conectividad fija "en línea" | |
| Etiquetas | vector Ed25519 del backend embebido en `support/label_vector.dart` | en el dispositivo no existe `test/fixtures/*.json`; si el backend regenera el vector, actualizar también estas constantes |

Los fakes de `test/` se importan con rutas relativas (`../../test/...`): no se duplican.

## Cómo correrlos

```bash
# Host (sin emulador; ~35 s). En Windows hay que indicar el dispositivo: sin `-d` flutter busca un
# dispositivo real y falla con "No supported devices connected".
C:/flutter/bin/flutter.bat test integration_test -d flutter-tester
make e2e                                   # lo mismo (WSL/Linux/CI)

# Emulador o teléfono (Android). Un solo dispositivo a la vez: la PC tiene RAM justa.
flutter devices                            # id, p. ej. emulator-5554
flutter test integration_test -d emulator-5554 --dart-define-from-file=config/dev.json
make e2e DEVICE=emulator-5554 ENV=dev
```

Emulador desde la línea de comandos (Windows, Git Bash):

```bash
SDK=/c/Users/ehhuallata/AppData/Local/Android/Sdk
$SDK/emulator/emulator.exe -list-avds
$SDK/emulator/emulator.exe -avd Medium_Phone_API_36.1 -no-snapshot -no-boot-anim -no-audio -memory 2048 &
$SDK/platform-tools/adb.exe wait-for-device
until [ "$($SDK/platform-tools/adb.exe shell getprop sys.boot_completed | tr -d '\r')" = 1 ]; do sleep 5; done
# ... correr los tests ...
$SDK/platform-tools/adb.exe emu kill       # apagarlo al terminar
```

## Escribir un flujo nuevo

1. Crear `integration_test/flows/<flujo>_flow.dart` con una función `void <flujo>FlowTests()` que
   declare sus `group`/`testWidgets` y use `setUp(e2eSetUp)`.
2. Llamarla desde `integration_test/app_test.dart`.
3. Montar con `pumpE2eApp(tester, scans: [...], photos: [...], printerFails: ...)`, entrar con
   `login(tester, '<rol>@dismac.test')` y navegar tocando los textos reales de la UI con
   `tapVisible` (centra el widget y espera a que ningún aviso lo tape) y `pumpUntilFound`.
4. Si la pantalla escribe por la cola offline, simular el endpoint en `FakeBackend._handle`
   (respuesta con el mismo sobre que el contrato OpenAPI) y verificar lo recibido.
5. Cerrar con `expect(h.backend.unhandled, isEmpty)` y, si corresponde, `await h.pendingOutbox()`
   en 0 (todo sincronizado).

Reglas: nada de `pumpAndSettle` sin tope (el mapa anima tiles en el dispositivo; usar `settle`), y
nunca leer archivos del repo en tiempo de test (en el dispositivo no existen).

## Hallazgos de la primera corrida (para `lib/`)

- **Usuario sin rol de terreno**: `AuthRepositoryImpl` lanza un 403 con el detalle "Tu usuario no
  tiene un rol de terreno asignado...", pero `ApiException.message` prioriza el texto genérico de 403
  ("No tenés permiso para esta acción.") y el detalle no se ve. El test acepta ambos textos.
- **Mapa con el camión justo en el destino**: `DeliveryMap` hace `CameraFit.coordinates` con dos
  puntos idénticos y sin `maxZoom` → zoom infinito → "Infinity or NaN toInt" en
  `TileLayer`/`PolylineLayer`/`MarkerLayer` (pantalla roja/gris). Sugerido: `maxZoom: 18` en el
  `CameraFit` (o `move(punto, 16)` si los puntos coinciden). El e2e usa un GPS a unas cuadras.
- **Avisos que tapan botones**: el "Registrado." de "Escanear bultos" sigue visible al volver a la
  entrega y tapa "Entregar pedido" ~2 s; en preparación, "Unidad preparada e impresa." tapa el botón
  de la última unidad de la lista. No bloquea (el aviso se va solo), pero con guantes y apuro puede
  dar un toque en falso.
