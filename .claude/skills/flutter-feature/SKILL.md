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

**Una build de Gradle a la vez** (la RAM es justa; builds apiladas colgaron la máquina). No correr `pub get`
mientras hay una build: `integration_test` (dev-dep) se cuela en `GeneratedPluginRegistrant` y rompe la release.

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
| `swagger_parser` falla (`List` no es `Map`) | anchors YAML + `parameters` de nivel path | Preprocesado `scripts/preprocess_openapi.py` (lo hace el script) |
| Errores fantasma (`undefined` PendingPhoto/DriverRoute) | `.g.dart` desactualizado | build_runner (Drift) o regenerar API; `Dart: Restart Analysis Server` |
| Gradle: `requires core library desugaring` | flutter_local_notifications | Ya habilitado en `android/app/build.gradle.kts` |
| Muchos `ClientException … tile.openstreetmap.org` en tests | La capa de tiles intenta red en test | Ruido esperado; no falla el test |
