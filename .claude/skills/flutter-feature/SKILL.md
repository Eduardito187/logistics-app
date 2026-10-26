---
name: flutter-feature
description: Build or change a feature in the Dismac logistics internal Flutter app (logistics-app, Windows, Flutter 3.32 / Dart 3.8) — screens for a role (chofer, preparador, tienda, transportista, supervisor), offline-invisible scanning, label QR verification, Zebra printing, photos/signature, maps, push FCM, API client regeneration — and run/analyze/test/build the app (Android and iOS). Use it whenever the user asks to add or change a screen or flow ("agrega la pantalla de…", "implementa el escaneo de…", "cambia el diseño de…"), to regenerate the API client after a backend change, to run/launch the app or the play button (dev/staging/production), or when a Flutter analyze/test/build/Gradle/emulator/iOS run fails ("el play se cierra", "falla la build", "no compila el APK", "Data4 isn't a type").
---

# Feature en la app interna — logistics-app

La app **solo consume el backend** (`/api/v1/app/*`); nunca integra servicios externos (SMS, SAP,
Telegram) — eso es del backend/ops. Excepciones del lado cliente: recibir push con **Firebase Cloud
Messaging**, Crashlytics y tiles OSM. "Completo" para el dueño = cubrir los endpoints `/app/*` útiles y
cerrar al 100%, no un MVP. Antes de diseñar: `CLAUDE.md`, `.claude/memory/*.md` (decisiones vigentes del
dueño) y `docs/` (release, ios, firebase-setup, cliente-api, rendimiento-y-pantallas, e2e, qa-dispositivo-real).

## Herramientas (Windows nativo)

- **Flutter del proyecto: 3.32.0 / Dart 3.8 en `C:\flutter`** (decisión del dueño: un solo Flutter en la PC;
  NO subir el proyecto). Desde Bash: `/c/flutter/bin/flutter.bat`, `/c/flutter/bin/dart.bat`.
- `C:\sdk\flutter` (3.47.6) existe SOLO para regenerar el cliente API (el `retrofit_generator` necesita Dart ≥3.9).
- Android SDK `%LOCALAPPDATA%\Android\Sdk`, JDK 21 `C:\Users\ehhuallata\jdk21`. Gradle 8.12, AGP 8.7.3,
  Kotlin 2.1.0, minSdk 24, compileSdk 36, NDK 27.0.12077973 (máximos de Flutter 3.32; no cambiar).
- `.vscode/settings.json` → `C:/flutter` (barras `/`: con `\` simple el JSON queda inválido y VS Code lo ignora).
- `android/local.properties` (ignorado): `flutter.sdk=C:/flutter`, `sdk.dir=C:/Users/ehhuallata/AppData/Local/Android/Sdk`.
  Si aparece con rutas `/home/...` es un **VS Code abierto en modo WSL** sobre la carpeta (corre `pub get`
  con el Flutter de WSL y pisa `.dart_tool`, `pubspec.lock` y `local.properties`): reescribirlo y correr
  `C:\flutter\bin\flutter.bat pub get`; pedir al usuario cerrar esa ventana.
- El backend vive en WSL: `\\wsl.localhost\Ubuntu-22.04\dismac\logistics` (puede tener cambios sin push;
  GitHub puede ir atrasado). Grep pesado ahí: correr DENTRO de WSL con un `.sh` (`wsl.exe -d Ubuntu-22.04 -- bash /mnt/c/...sh`).

```bash
/c/flutter/bin/dart.bat format lib test integration_test
/c/flutter/bin/flutter.bat analyze
/c/flutter/bin/flutter.bat test                    # ~1726 tests
/c/flutter/bin/flutter.bat test integration_test -d flutter-tester   # e2e en host (6)
make apk ENV=staging                               # release --split-per-abi (necesita android/key.properties)
```

`flutter analyze`/`flutter test` corren en WSL sin más. **Correr/compilar la app también se puede en
WSL**: ya está montado el toolchain Android (JDK 17 en `~/jdk`, SDK en `~/Android/Sdk`, NDK), con
Flutter apuntado vía `flutter config --android-sdk ~/Android/Sdk --jdk-dir ~/jdk`. El APK sigue
pudiendo salir del CI (`logistics-app-debug-apk`) o Android Studio en Windows.

**⚠️ Memoria — crítico:** las builds de Gradle colgaron WSL entero una vez. Reglas:
- `android/gradle.properties` debe quedar con `-Xmx2G` (nunca varios GB) — heap grande satura la RAM.
- **Una build a la vez.** No lanzar múltiples `flutter run`/`flutter build` en background: se apilan y cuelgan el equipo.
- **No correr `pub get` mientras hay una build:** `integration_test` (dev-dep) se cuela en `GeneratedPluginRegistrant` y rompe la release.
- `.wslconfig` limita WSL a 10 GB/6 GB swap (aplica tras `wsl --shutdown`).
- Si se cuelga: `pkill -9 -f gradle; pkill -9 java; pkill -9 -f build_runner; pkill -9 dart`.

**Correr en emulador (play de VS Code / Android Studio):** entornos en `config/{dev,staging,production}.json`,
inyectados con `--dart-define-from-file`. VS Code debe usar el Flutter de WSL (`.vscode/settings.json`
fija `dart.flutterSdkPath`), no `C:\flutter` (CRLF → exited 127). Para el emulador de Windows desde
WSL: `adb start-server`, copiar `~/.android/adbkey*` desde `/mnt/c/Users/<user>/.android/`, arrancar el
AVD con `emulator.exe`, luego `flutter run -d emulator-5554`.

**Correr en teléfono físico por ADB INALÁMBRICO desde WSL** (sin cable; funciona, Honor Magic 5 Lite):
`scripts/adb-wireless.sh` (connect/reconnect/mdns/pair) + tareas de VS Code; detalle en
`docs/run-wireless.md`. Claves: copiar las llaves adb de Windows a `~/.android/` (no re-emparejar),
`export ADB_MDNS_OPENSCREEN=1` para que mDNS reconecte solo, y para el backend `adb reverse tcp:8110
tcp:8110` + `config/dev.json` con `API_BASE_URL=http://localhost:8110/api/v1` (el teléfono NO llega a la
IP LAN de la PC por firewall). **Trampas:** los puertos de depuración inalámbrica ROTAN al dormir el
teléfono (dir vieja → `Connection refused`, releer `IP:puerto`); si duerme a mitad de build, la
instalación da `adb: device offline` aunque el APK sí se construyó (reconectar e instalar el APK ya hecho,
no reconstruir); mDNS puede listar dispositivos AJENOS (verificar `model:`/`product:` en `adb devices -l`
antes de instalar). Memoria completa: ver `.claude/memory/device-run-wireless-adb.md`.

## Portabilidad (mover el proyecto / Windows nativo)

Las rutas de arriba (`~/sdk/flutter`, `~/Android/Sdk`, `/dismac/...`) son de **este WSL**. Al mover el
proyecto a otra ruta u OS:
- **Skills:** viajan solas con el repo (`.claude/skills/`), funcionan en cualquier OS. Los scripts de
  `github-pr-flow` son `.ps1` de Windows a propósito.
- **Memorias:** NO viajan con el repo (viven en `~/.claude/projects/<slug>/memory/`, con el slug ligado a
  la ruta). Hay espejo versionado en `.claude/memory/` + instalador: tras clonar/mover correr una vez
  `.\.claude\memory\install.ps1` (Windows) o `bash .claude/memory/install.sh` (Linux/WSL/macOS). Ver
  `.claude/memory/README.md`.
- **Flutter en Windows nativo:** el SDK ya no está en `~/sdk/flutter`; usar la instalación de Windows
  (p. ej. la que apunta `.vscode/settings.json`, o `flutter` en el PATH) y correr desde PowerShell.
  `flutter analyze`/`test`/`run` son iguales; `config/{dev,staging,production}.json` + `--dart-define-from-file`
  siguen igual.

## Dónde va cada cosa

```
lib/core/            # transversal: config, auth, router, theme, layout, media, labels, network, offline,
                     # background, push, monitoring, version, map, scanning, printing, widgets, api (generado)
lib/features/<f>/{data,domain,presentation}/
test/                # espejo de lib/; test/support/ = fakes y arneses compartidos
integration_test/    # e2e de flujos críticos (app real + backend falso)
```

Cada feature expone en `presentation/<f>_routes.dart`: `const List<RoleTask> <f>Tasks` (tarjetas del inicio,
`roles:{UserRole.x}`, `accent:` la principal) y `final List<RouteBase> <f>Routes`. Se cablean en
`lib/core/navigation/feature_tasks.dart` y `lib/core/router/app_router.dart`. Roles por `backendKey`:
chofer, preparador, tienda, transportista, supervisor, admin.

## Decisiones del dueño (no reintroducir lo contrario)

- **Offline invisible:** el usuario NUNCA ve "sin conexión", "pendiente" ni sincronización. Encolado = "Registrado." /
  pastilla "Enviado". Única señal: "Sincronizando..." al volver la red. Errores de red: "No se pudo completar…".
- **Notificaciones:** solo la campana del header del inicio. **Sin chat** en ningún flujo.
- **Tienda fija** del usuario (`Session.storeNode`, `selectedStoreNodeProvider`), sin selector. "Recojo en tienda".
- **Sesión persistente** (restore en `main`), como WhatsApp.
- **Chofer:** "Entrega en curso" estilo app de delivery (mapa, tarjeta de estado, hoja con cliente/pedido, botones
  del paso, Ayuda sin chat). **Foto del POD obligatoria**; firma digital del cliente en pantalla.
- **1 GB de RAM y pantallas de 320 dp a tablets**: ver "Base común" y probar con `testOnScreens`.
- **iOS sí** (se compila en Mac/CI; protección de archivos hasta el primer desbloqueo).

## Base común (usar, no reinventar)

- **API:** `ref.read(logisticsApiProvider)` SOLO en `data/datasources/`; presentación → use case/repositorio.
  Respuestas en `.data`; errores `on DioException catch (e) { throw ApiException.fromDio(e); }`.
- **Cola offline:** `ref.read(offlineQueueProvider).submit(kind:, payload:, label:, occurredAt:)` → `SubmitOutcome`.
  El id es el `Idempotency-Key`; kinds en `core/offline/offline_dispatcher.dart`; path params como `'@shipmentId'`.
  Fotos: `photoUploadQueueProvider`/`enqueueDeliveryPhotoProvider` (kind `pod`/`damage`). Feedback: `showSubmitOutcome`.
- **Cámara/escáner (seams para tests):** `scanCode(context, …)` → delega en `codeScannerProvider`;
  fotos con `ref.read(photoPickerProvider)(maxWidth: kEvidencePhotoMaxWidth, imageQuality: kEvidencePhotoQuality)`;
  previews `Image.file(cacheWidth: 800)`. Feedback de escaneo: `scanFeedbackFor(context, success:)`.
- **Layout:** `AppBreakpoints` (`columnsFor`, `maxContentWidth` 720, `maxFormWidth` 520), `ResponsiveBody`,
  `SliverAdaptiveCardRows`/`AdaptiveCardRows` (`core/layout/`). Nada de grillas con `childAspectRatio` fijo.
- **Avisos:** `showSuccessSnack`/`showInfoSnack`/`showErrorSnack` (2 s / error 4 s); con botón fijo al pie pasar
  `bottomClearance: kBottomActionClearance`. SnackBar propio → `buildAppSnackBar`.
- **Mapa:** `const OsmTileLayer()` (nunca `buildOsmTileLayer()` en un build frecuente), tiles en disco;
  precarga `prefetchRouteTiles(puntos)`; `openExternalNavigation(lat,lng)` para navegar.
- **Push/monitoreo/versión:** `pushRegistrationProvider`, `pushTokenProvider`, `crashReporterProvider.breadcrumb('x.y')`
  (sin datos personales), `VersionGate` ya cableado en `app.dart`.
- **Widgets:** `AsyncValueView`, `SectionCard`, `StatTile`, `StatusPill(tone:)`, `EmptyState`, `NotificationsButton`,
  `LoadingView`. Tema con alto contraste (`highContrastProvider`, `AppContrast.isHigh`). Impresora: `labelPrinterProvider`.

## Reglas

1. UI en español; código en inglés; comentarios en español. Botones ≥ 48 dp (principales 56), pocos toques, legible al sol.
2. Riverpod 3 (`Notifier`, `.value`), go_router, Clean Architecture + CQRS, **una clase por archivo**.
3. Cliente API generado (regla #5): nunca DTOs a mano. Regenerar: `scripts/regen_api_client.ps1` (ver abajo).
4. Etiquetas Ed25519 offline en `lib/core/labels/`; `test/fixtures/label_test_vector.json` = copia del backend.
5. `copyWith` que deba volver a `null`: centinela `_unset` (no `x ?? this.x`).
6. **Flutter 3.32:** no existen `RadioGroup` (usar `groupValue`/`onChanged` por tile) ni
   `DropdownButtonFormField(initialValue:)` (usar `value:`). Formatear con el `dart` de 3.32 (el de 3.13 formatea distinto y rompe CI).
7. Toda pantalla nueva: test de widget + `testOnScreens` (`test/support/screen_sizes.dart`, 4 tamaños, `withTextScale(1.3)`).
8. Pedidos al backend: doc en `docs/backend-requests/AAAA-MM-DD-tema.md` + fila en su `README.md` (no hay sesión
   del backend para mensajear); si hay una abierta (`ListAgents`), mandarle el doc.

## Regenerar el cliente API

`powershell -ExecutionPolicy Bypass -File scripts/regen_api_client.ps1 [-Spec <v1.yaml>] [-DryRun|-Out <dir>]`
(o `scripts/regen_api_client.sh`). Genera en una copia temporal con `C:\sdk\flutter` y `tool/api_gen/`
(pubspec Dart 3.13), preprocesa el spec con la Python de WSL (la de Windows no tiene PyYAML), parcha
`MetaSealed?`, corre build_runner, formatea con 3.32 y copia solo `lib/core/api/`. **Avisa si cambió la
numeración de tipos anónimos `DataN`**: renombrar las referencias de la app/tests y los imports `models/dataN.dart`
comparando campos (pasó: `Data4→Data5`, `Data6→Data7`, `Data21→Data22`).

## Definición de terminado

`dart format` sin cambios + `flutter analyze` sin issues + `flutter test` verde (+ e2e si tocaste un flujo crítico),
con números. Si cambió Android/iOS: una build (`make apk`). Reportar qué no se pudo probar (hardware real).

## Gotchas ya vistos

| Síntoma | Causa | Arreglo |
| --- | --- | --- |
| Aserción `fontSize != null` en `TextStyle.apply` al arrancar | `Typography.black` y `ThemeData.textTheme` no traen tamaños: viven en `typography.englishLike` | Escalar `base.typography.englishLike.merge(base.textTheme)` |
| `scrollUntilVisible` → `Bad state: Too many elements`, o botón "no se toca" / sigue en login en widget test | Cada `TextField` trae su propio `Scrollable`; `scrollUntilVisible` scrollea el equivocado | `await tester.ensureVisible(btn); await tester.pumpAndSettle();` antes de `tap` |
| `logout`/acción no surte efecto o cuelga en test | `flutter_secure_storage` y otros plugins no existen en widget tests | En `signOut` limpiar estado **síncrono primero**, luego `await` del almacén en try/catch |
| App no monta en test / push revienta en dispositivo sin Google Play | Firebase lanza **Error** (no Exception) sin plugin o sin credenciales | Bootstrap del push con `catch` amplio (`on Object`); sin `FIREBASE_*` el push queda "No disponible", nunca tumbar la app |
| `AsyncValue.valueOrNull` no existe | Riverpod 3.x | Usar `.value` (nullable) |
| `RadioGroup` / `DropdownButtonFormField(initialValue:)` no existen | El proyecto usa Flutter 3.32 | `groupValue`/`onChanged` en cada `RadioListTile`; `value:` en el dropdown |
| `package:latlong2/latlong2.dart` no existe | nombre del archivo | Importar `package:latlong2/latlong.dart` |
| `swagger_parser` falla (`List` no es `Map`) al generar | anchors YAML + `parameters` a nivel path | Preprocesar a JSON (ver "Cliente API generado" / `scripts/preprocess_openapi.py`) |
| `export: not a valid identifier` | Comillas de PowerShell → `wsl bash -lc` | Correr los comandos desde un `.sh` o `export PATH=…` inline |
| VS Code: "Errors exist in your project" / clases `undefined` (`PendingPhoto`, `DriverRoute`) que sí existen | `.g.dart` desactualizado tras cambiar tabla Drift o modelo API | `dart run build_runner build`; si persiste, `Dart: Restart Analysis Server` |
| APK no compila: `meta` no-nullable con constructor opcional en `*_response.dart` | Bug de swagger_parser (campo no-nullable, param opcional) | Parchar a `MetaSealed? meta` + regenerar; **fix de fondo en backend `openapi/`** (se pisa al regenerar) |
| Gradle: `requires core library desugaring to be enabled` (`flutter_local_notifications`) | Plugin usa APIs java.time en minSdk bajo | `isCoreLibraryDesugaringEnabled = true` + dep `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:…")` en `android/app/build.gradle.kts` |
| `'bash\r': No such file or directory`, exited 127, consola de play se cierra al segundo | VS Code usa `C:\flutter` (CRLF) en vez del Flutter de WSL | `.vscode/settings.json` → `dart.flutterSdkPath=~/sdk/flutter` + Reload Window |
| Emulador aparece `unauthorized` | adb de WSL usa llave nueva que el emulador no confía | Copiar `adbkey{,.pub}` de Windows a `~/.android/` y reiniciar adb |
| `flutter test`: `Failed to load dynamic library 'libsqlite3.so'` (tests Drift) | WSL/Linux solo trae `libsqlite3.so.0`, no el symlink sin versión | Ya resuelto: `test/flutter_test_config.dart` redirige la carga a `.so.0` (no borrarlo). No requiere root |
| Widget test de pantalla con providers: `Tried to modify a provider while the widget tree was building` | El harness/override modifica un provider dentro de build/initState, o un widget llama `.notifier.metodo()` en `build` | Mover la mutación fuera del ciclo de vida (p. ej. a `onPressed`) o arreglar el override del harness de test |
| APK no compila por CameraX 1.6.1 / AGP 8.9.1, o CocoaPods choca con `GoogleDataTransport` | `mobile_scanner` > 7.2.0 (7.2.1+ sube CameraX; en iOS vuelve a MLKit) | Fijar `mobile_scanner: 7.2.0` EXACTO (ni `^` ni rango). No subirlo sin subir Flutter/AGP. Commit 9fdce63 |
| "Tu sesión expiró" apenas se inicia sesión y vuelve al login | El 401-logout global (`_AuthInterceptor.onError` en `dio_client.dart`) se disparaba con el 401 de `/app/auth/me` que pide el login (degradación segura) | `_isAuthEndpoint` excluye `/login`, `/token` **y** `/auth/me`. Si "sesión expiró" sale al ABRIR la app, es token viejo restaurado (otro tema) |
| La app calienta/cuelga "en todas las páginas" en dispositivo real (no en emulador/tests) | `ConnectivityNotifier` drenaba las colas offline en CADA evento de conectividad | Drenar solo en el flanco offline→online (`if (online && !wasOnline)`). Patrón: nada caro en callbacks que se disparan seguido |
| Listeners de FCM duplicados / "Could not decrypt key" en secure storage / botón girando para siempre | Re-suscripción sin cancelar; clave corrupta tras reinstalar; `on ApiException` deja pasar otros errores | `push_service.initialize()` cancela `_subs` antes de re-suscribir; `AndroidOptions(resetOnError: true)` en `token_store.dart`; atrapar `on Object` en controllers de submit. Ver `.claude/memory/perf-rebrand-stability-fixes.md` |
| Splash animado no se reproduce (imagen fija) o la app re-decodifica el Lottie en cada navegación | El splash estaba sin cablear, o el gate en el `builder` de MaterialApp se recreaba | `BrandSplash` vía `BootSplashGate` one-shot creado en `runApp` (en `main.dart`, NO en el `builder`); guarda `_started` porque Lottie puede re-invocar `onLoaded` |
| `The current Dart SDK version is 3.8.0 … requires ^3.13.5` | Se usó otra versión o un pubspec ajeno | El proyecto es `sdk: ^3.8.0`; usar `C:\flutter` |
| Finder `widgetWithText(FilledButton, …)` no encuentra | En 3.32 `FilledButton.icon`/`OutlinedButton.icon` son subclases privadas | `findButtonWithText<FilledButton>()` / `findButton<T>()` (`test/support/button_finders.dart`) |
| Layout roto con un botón del tema en un `Row` | El tema da `minimumSize: Size.fromHeight(56)` (ancho mínimo infinito) | `Expanded` o `minimumSize: Size(48, 56)` |
| "LayoutBuilder does not support returning intrinsic dimensions" | Scroll/LayoutBuilder dentro de `EmptyState` usado en `SliverFillRemaining(hasScrollBody:false)` | No tocar `EmptyState`; resolver el scroll en la pantalla |
| Test pasa en Android y falla el fallback | En flutter_test `defaultTargetPlatform` es **Android** | `debugDefaultTargetPlatformOverride` en setUp/tearDown |
| `signOut` cuelga / segundo logout ignorado en test | Secure storage sin mock responde fuera del reloj falso | `FlutterSecureStorage.setMockInitialValues({})` en setUp |
| `LocaleDataException` en test | Falta inicializar fechas en español | `setUpAll(() => initializeDateFormatting('es'))` |
| Overflow solo en teléfono chico / lista no construye el ítem | ListView perezoso en 800x600 o letra 1.3x | `tall: true` / `testOnScreens` y arreglar con `Expanded`/`Wrap`/ellipsis |
| `pumpAndSettle timed out` | Spinner infinito | `pump()` + `pump(Duration)` |
| "Tried to override a provider twice" | El arnés (`gateBase`) ya hace override | Override de un provider más específico (p. ej. `deliveryDriverFixProvider`) |
| Zoom infinito / NaN en el mapa | `CameraFit.coordinates` con puntos iguales | `maxZoom: 18` |
| `workmanager_apple` no compila (`foregroundServiceConfig`) | platform_interface 0.9.4 vs apple 0.9.4 | `dependency_overrides`: platform_interface 0.9.3, android 0.9.2 (ya en pubspec) |
| Release no llega a `http://10.0.2.2` | `networkSecurityConfig` bloquea cleartext en release | Probar release con staging/production |
| Script con `'\\n'`/rutas `C:\...` sale roto | La herramienta Bash colapsa `\\` en heredocs (`\f` → form feed) | Scripts/JSON con barras `/` o escribirlos con la herramienta Write |
| PowerShell muestra "logÃ­stica" | `.ps1` en UTF-8 sin BOM lo lee como Windows-1252 | `.ps1` en ASCII; textos en archivos UTF-8 |
| Muchos `ClientException … tile.openstreetmap.org` en tests | La capa de tiles intenta red en test | Ruido esperado; no falla el test |
