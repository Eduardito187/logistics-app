---
name: flutter-feature
description: Build or change a feature in the Dismac logistics internal Flutter app (/dismac/logistics-app) — screens for a role (chofer, preparador, tienda, transportista, supervisor), offline scanning, label QR verification, Zebra printing, API client — and run/analyze/test/build the app from WSL (toolchain Android ya montado). Use it whenever the user asks to add a screen or flow ("agrega la pantalla de ruta del chofer", "implementa el escaneo de carga", "conecta el login"), to run/launch the app or set up the play button (dev/staging/production), or when a Flutter analyze/test/build/Gradle/emulator run fails ("el play se cierra", "falla la build", "no compila el APK").
---

# Feature en la app interna — logistics-app

La app **solo consume el backend** (`/api/v1/app/*`); nunca integra servicios externos (SMS, SAP,
Telegram, tiles) — eso es del backend/ops. Única excepción: el push se **recibe** con Firebase Cloud
Messaging (`firebase_messaging`, credenciales `FIREBASE_*` en `config/*.json`); el **envío** es del backend. "Completo" para el dueño = **cubrir todos los
endpoints `/app/*`** útiles, no un MVP. Antes de diseñar, leer `CLAUDE.md` y `docs/architecture.md`;
la visión y los ADRs viven en el backend: `/dismac/logistics/docs/`.

## Herramientas (WSL)

El SDK es Flutter stable en `~/sdk/flutter`. `/dismac/flutter` es de root y es pre-release: no usarlo.
Correr siempre desde un script, porque las comillas de PowerShell → WSL rompen los `export`:

```bash
#!/usr/bin/env bash
export PATH="$HOME/sdk/flutter/bin:$PATH"
cd /dismac/logistics-app
dart format lib test
flutter analyze
flutter test
```

`flutter analyze`/`flutter test` corren en WSL sin más. **Correr/compilar la app también se puede en
WSL**: ya está montado el toolchain Android (JDK 17 en `~/jdk`, SDK en `~/Android/Sdk`, NDK), con
Flutter apuntado vía `flutter config --android-sdk ~/Android/Sdk --jdk-dir ~/jdk`. El APK sigue
pudiendo salir del CI (`logistics-app-debug-apk`) o Android Studio en Windows.

**⚠️ Memoria — crítico:** las builds de Gradle colgaron WSL entero una vez. Reglas:
- `android/gradle.properties` debe quedar con `-Xmx2G` (nunca varios GB) — heap grande satura la RAM.
- **Una build a la vez.** No lanzar múltiples `flutter run`/`flutter build` en background: se apilan y cuelgan el equipo.
- `.wslconfig` limita WSL a 10 GB/6 GB swap (aplica tras `wsl --shutdown`).
- Si se cuelga: `pkill -9 -f gradle; pkill -9 java; pkill -9 -f build_runner; pkill -9 dart`.

**Correr en emulador (play de VS Code / Android Studio):** entornos en `config/{dev,staging,production}.json`,
inyectados con `--dart-define-from-file`. VS Code debe usar el Flutter de WSL (`.vscode/settings.json`
fija `dart.flutterSdkPath`), no `C:\flutter` (CRLF → exited 127). Para el emulador de Windows desde
WSL: `adb start-server`, copiar `~/.android/adbkey*` desde `/mnt/c/Users/<user>/.android/`, arrancar el
AVD con `emulator.exe`, luego `flutter run -d emulator-5554`.

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
lib/core/            # transversal: config (dart-define), auth (UserRole, sesión), router, theme, labels, network
lib/features/<flujo>/{data,domain,presentation}/
test/                # espejo de lib/; fixtures en test/fixtures/
```

Un flujo nuevo = **una carpeta disjunta** en `features/`. Cada feature expone en
`presentation/<f>_routes.dart` dos listas que el **coordinador** cablea (no el agente de feature):

```dart
const List<RoleTask> <f>Tasks = [ RoleTask(id:'…', label:'…', icon:Icons.…,
    route:'/<f>/…', roles:{UserRole.driver /* u otros */}, accent:true) ];
final List<RouteBase> <f>Routes = [ GoRoute(path:'/<f>/…', builder:(c,s)=> const XScreen()) ];
```

- El coordinador agrega esas listas en `lib/core/navigation/feature_tasks.dart` (tarjetas del home por
  rol) y `lib/core/router/app_router.dart`. Un agente de feature **no toca** `lib/core/**`, `app.dart`,
  `main.dart`, `AndroidManifest.xml`, `app_router.dart`, `feature_tasks.dart` ni `pubspec.yaml`.
- `RoleHomeScreen` arma el inicio desde `featureTasksProvider` filtrando por `RoleTask.roles` (el campo
  legacy `UserRole.tasks` ya no alimenta el home).
- Roles (`core/auth/user_role.dart`) mapean al backend por `backendKey`: chofer→driver, preparador→picker,
  tienda→store, transportista→carrier, supervisor→supervisor, admin→admin (rol de oficina). El login real
  usa `UserRole.firstOperational(user.roles)`.

## Cliente API generado (regla #5)

No se escriben DTOs a mano. El cliente vive en `lib/core/api/` y se genera con `swagger_parser` desde
`openapi/v1.yaml`. Uso:

```dart
final api = ref.read(logisticsApiProvider);          // core/network/dio_client.dart
final res = await api.<module>.<operationId>(...);   // p.ej. api.execution.recordLoadScan(...)
final data = res.data;                               // las respuestas envuelven el payload en .data
// errores: try { … } on DioException catch(e){ throw ApiException.fromDio(e); }  // .message en español
```

**Regenerar** cuando el backend cambie el spec: `bash scripts/regen_api_client.sh` (o `make gen`): copia
el spec → preprocesa a `openapi/v1.json` (expande anchors YAML + inyecta `parameters` de nivel path, que
`swagger_parser` no traga) → `dart run swagger_parser` → `dart run build_runner build --delete-conflicting-outputs`.
`lib/core/api/**` y `**/*.g.dart` están excluidos del analyzer; tras regenerar correr `dart format lib`.

## Offline-first (concreto)

Escrituras de terreno (escaneos, POD, fallidas) van por la cola Drift, nunca esperan a la red:

```dart
await ref.read(offlineQueueProvider).submit(
  kind: 'recordLoadScan',                 // mapeado en core/offline/offline_dispatcher.dart
  payload: ScanRequest(...).toJson(),     // NO pongas idempotency_key: lo agrega submit (ULID)
  label: 'Carga · pedido X', occurredAt: DateTime.now());
```

El ULID es el `Idempotency-Key`; `ConnectivityNotifier` drena al recuperar señal. Para una acción nueva,
agregá su `kind` al dispatcher; los path params (vehículo/envío) viajan en el payload con prefijo `@`
(`'@vehicleId'`). Las **fotos** van por `photoUploadQueueProvider.enqueue(shipmentId, filePath, kind)`.
Las acciones de oficina (listar, aprobar, publicar) van **directo** por `api.*`, no por la cola.

**Semántica de resultado (no reintroducir falencias ya corregidas):**
- `submit` devuelve `SubmitOutcome`: `sent` (OK), `queued` (quedó pendiente), `failed` (error de datos permanente).
- **Transitorio = `queued`, no `failed`:** sin conexión, **429** (rate limit) y **5xx** NO se marcan `failed`
  (se perdería la escritura de terreno) — quedan pendientes para reintento. Solo los 4xx de datos → `failed`.
  El helper `_isTransient(ApiException)` concentra ese criterio.
- El `kind` se valida **antes** de encolar (un kind desconocido lanza `StateError`, no deja fila envenenada).
- `drain` atrapa `StateError` (kind obsoleto tras actualizar la app) y aísla esa fila sin frenar el resto.
- `markFailed` incrementa `attempts` (base para backoff/tope).

## Bloques reutilizables (core)

- **Providers:** `logisticsApiProvider`, `offlineQueueProvider`, `photoUploadQueueProvider`,
  `connectivityProvider`, `syncQueueProvider`, `locationServiceProvider` (`.current()`→`GpsFix?`, `.stream()`),
  `labelScannerProvider` (`.scan(qr)`→`LabelScanResult(isValid)`, Ed25519 OFFLINE), `labelKeysProvider`
  (`.refresh()`), `zebraPrinterProvider` (`.printZpl(zpl)`, lanza `PrinterException`), `pushRegistrationProvider`.
- **Widgets:** `AsyncValueView`, `SectionCard`, `StatTile`, `StatusPill(tone: PillTone.x)`, `EmptyState`,
  `SyncBadge` (`core/widgets/`). `AppColors` (`core/theme/app_colors.dart`). Botones ya 56px por tema.
- **Escáner:** `await scanCode(context, title:'…', formats:[BarcodeFormat.qrCode])`→`String?`
  (`core/scanning/`; importar `mobile_scanner` para `BarcodeFormat`).
- **Mapas (sin Google, ADR 013):** `buildOsmTileLayer()` y `openExternalNavigation(lat,lng)` (`core/map/`);
  `flutter_map` + `latlong2`, tiles de `AppConfig.mapTilesUrl`.

## Reglas

1. **UI en español** (la usan choferes y personal de tienda). Código en inglés, comentarios en español.
2. **Campo, no oficina:** botones de 56 px de alto como mínimo, flujos de pocos toques, legible al sol. El tema
   (`core/theme/app_theme.dart`) ya fija esos tamaños: no sobreescribirlos por pantalla.
3. **Offline-first:** un escaneo nunca espera a la red. Se guarda local con ID idempotente (ULID) y se
   sincroniza después. La base local (Drift) se agrega con el primer flujo que la necesite.
4. **API generada:** el cliente sale de `/dismac/logistics/openapi/v1.yaml`. No escribir DTOs de la API a mano.
5. **Etiquetas:** la verificación Ed25519 está en `lib/core/labels/`. El mensaje canónico debe coincidir
   byte a byte con el backend. `test/fixtures/label_test_vector.json` es copia exacta del vector del
   backend: si el backend lo regenera, se copia y `test/core/labels/` tiene que seguir pasando.
6. **Estado:** Riverpod 3 con `Notifier`/`NotifierProvider` (no `StateProvider`, que es legacy).
   Navegación con go_router.
7. **Tests:** lógica de `domain/` con unit tests sin Flutter; pantallas de lista/detalle con widget tests
   usando `ProviderScope(overrides:)` para stubear los providers de datos (sin Dio real). Pantallas con
   cámara/BT/GPS/mapa: smoke mínimo o se omiten documentando por qué.
8. **Lints activos:** prefer_single_quotes, require_trailing_commas, always_declare_return_types,
   avoid_dynamic_calls, prefer_final_locals, unawaited_futures, strict-casts.
9. **Clean Architecture + CQRS + SRP** (ver `docs/clean-architecture.md`): **una clase por archivo**
   (excepción: `StatefulWidget` + su `_State` van juntos). El API **solo** se toca en `data/datasources/`
   (y se expone vía use case / repositorio): **nunca** `ref.read(logisticsApiProvider)` en `presentation/`.
   Sub-widgets privados reutilizables → archivo público en `presentation/widgets/`. Reutilizar los helpers
   de core (`app_snack.dart`, `offline/submit_feedback.dart`, `commands/command_feedback.dart`) en vez de
   duplicar SnackBars.
10. **`copyWith` con nullables:** si un `copyWith` debe poder volver un campo a `null`, usar centinela
    (`static const Object _unset = Object();` + `identical(x, _unset) ? this.x : x as T?`). El patrón
    `x ?? this.x` NO puede limpiar a null (bug ya visto en push/tracking).

## Definición de terminado

`dart format` sin cambios + `flutter analyze` sin issues + `flutter test` verde, con números
reportados. Si cambia la UI, describir qué se probó en emulador o dispositivo (o decir que no se pudo).

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
