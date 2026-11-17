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
- El backend vigente vive en Windows: `C:\Users\ehhuallata\Documents\APP\logistics` (spec:
  `openapi\v1.yaml`; puede tener cambios sin commit de la sesión del backend → SOLO LECTURA). El
  `~/dismac/logistics` de WSL es una copia VIEJA (13-oct): no usarla. Staging corre en OCI (`ssh oci`).

```bash
/c/flutter/bin/dart.bat format lib test integration_test
/c/flutter/bin/flutter.bat analyze
/c/flutter/bin/flutter.bat test                    # ~2026 tests
/c/flutter/bin/flutter.bat test integration_test -d flutter-tester   # e2e en host (6)
make apk ENV=staging                               # release --split-per-abi (necesita android/key.properties)
```

**🛑 Quién ejecuta (regla del dueño, 2026-10-26):** NO correr ningún comando de arriba (ni `pub get`,
`build_runner`, emulador, Docker o backend) salvo que el dueño lo pida en ese turno, y **nunca** desde
subagentes/workflows: 8 agentes con `flutter test` a la vez colgaron WSL ~20 min. Por defecto: editar
código, revisar estáticamente y entregarle los comandos, uno por bloque, para que los corra de a uno.
Si él lo pide: UN proceso de Flutter a la vez en todo el equipo (`dart_test.yaml` ya limita a `concurrency: 2`).

**🛑 NUNCA correr la suite de tests (regla del dueño, 2026-11-16):** "nunca más vuelves a lanzar la suite de
test, eso yo lo veo". NO ejecutar `flutter test` (ni la suite completa ni una carpeta) en ninguna sesión.
El dueño la corre y mira los números él. Esto corrige una interpretación mía anterior de que estaba OK
correrla desde la sesión principal: NO lo está. Para verificar, usar `mcp__claude-vscode__getDiagnostics`
(estático, no lanza proceso; el hook ya lo muestra tras cada Edit) y, si hace falta, `flutter analyze` /
`dart format` para dejar el código limpio y formateado (el formato debe ser el del Dart 3.32 o rompe CI).
Al cerrar: entregar el código verificado estáticamente + los comandos para que los corra él (`dart format`
→ `flutter analyze` → `flutter test`), sin ejecutar el último. Sigue firme: nunca builds/emulador/Docker
sin pedido, nunca desde subagentes en paralelo.

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
  Esto incluye los campos "pending" que el backend EXPONE (p. ej. `pod_photo_pending` de la entrega): son verdad
  interna/diagnóstico, **no se muestran** en la UI. El POD de tienda sale sin foto si la subida no terminó y la
  foto viaja por su cola; el backend la liga solo (ver `.claude/memory/backend-audit-2026-11-12.md`).
- **Notificaciones:** solo la campana del header del inicio. **Sin chat** en ningún flujo.
- **Tienda fija** del usuario (`Session.storeNode`, `selectedStoreNodeProvider`), sin selector. "Recojo en tienda".
- **Sesión persistente** (restore en `main`), como WhatsApp.
- **Chofer:** "Entrega en curso" estilo app de delivery (mapa, tarjeta de estado, hoja con cliente/pedido, botones
  del paso, Ayuda sin chat). **Foto del POD obligatoria**; firma digital del cliente en pantalla.
- **1 GB de RAM y pantallas de 320 dp a tablets**: ver "Base común" y probar con `testOnScreens`.
- **iOS sí** (se compila en Mac/CI; protección de archivos hasta el primer desbloqueo).
- **Tiempo real, no refresco por tiempo:** lo que tiene que estar al día va por sockets. Nada de
  `Timer.periodic` para pedir datos en una pantalla nueva → skill **realtime-feature**.
- **Diseño que el dueño ya corrigió varias veces** (no volver a lo anterior):
  - Filtros y opciones como **SELECT** (`DropdownButtonFormField`): ciudad, estado, rol, destinatario. Nunca
    chips ni un campo de texto para eso.
  - **El botón principal va FIJO al pie** (`bottomNavigationBar` con `SafeArea`, 56 dp), no al final del scroll.
  - Formularios con varios campos = **pantalla completa** agrupada en `SectionCard` (ver
    `admin/.../widgets/personal_data_form.dart`), no un `AlertDialog` con campos apilados.
  - Fotos = **recuadro que se toca y muestra la vista previa** (`DocumentPhotoTile`); documentos de dos caras
    piden Anverso y Reverso. Sin botones tipo "Sacar foto del anverso".
  - Listas de paradas/pasos = **línea de tiempo en tarjetas** (`supervisor/.../widgets/stop_tile.dart`).
  - **Ningún dato cortado** (sin `ellipsis` en pedido, cliente, dirección), **ningún UUID** a la vista, el SKU
    va solo (sin la palabra "SKU"), foto del producto en los detalles.
  - Hojas (modales) del alto de su contenido; el camión en mapas es el visto desde arriba del chofer.
  - Mientras algo carga se muestra carga, **nunca el estado vacío** ("Sin notificaciones" parpadeando).

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
- **Tiempo real:** `ref.refreshOnRealtime(tema, {eventos}, when:)` en el provider de lectura,
  `RealtimeListener` / `PagedSearchListState.refreshSilently()` en pantallas (`lib/core/realtime/`). Detalle
  y temas vigentes en el skill **realtime-feature**.
- **Aviso en el teléfono sin Firebase:** `localAlertsProvider` (`core/push/local_alerts.dart`).
- **Caché de lecturas:** `ref.cacheFor(CacheTtl.short|long)` + `ref.watch(sessionProvider.select(...))` para
  que no sobreviva a otro usuario. Volver a una pantalla no debe mostrar spinner ni vacío.
- **Widgets:** `AsyncValueView`, `SectionCard`, `StatTile`, `StatusPill(tone:)`, `EmptyState`, `NotificationsButton`,
  `LoadingView`. Tema con alto contraste (`highContrastProvider`, `AppContrast.isHigh`).
- **Impresión:** `labelPrinterProvider.printLabel({zpl, render, jobName, to}) → PrintOutcome` (texto VERAZ; "aceptado"
  nunca = éxito). **Zebra** = ZPL por Bluetooth/USB/WiFi-9100 (+`~HS`). **Oficina (Ricoh/láser)** = `OfficePrinter`:
  Ricoh se detecta y va por **9100 con PDF DIRECTO** (`PdfDirectJobWriter`, `@PJL ENTER LANGUAGE=PDF`) + código de
  usuario en texto claro (`USERCODE`); el PCL5 crudo le sale EN BLANCO e IPP lo cancela. Búsqueda WiFi y credenciales
  por impresora en `lib/core/printing/`. Ver `.claude/memory/wifi-printer-discovery.md`.
- **Íconos:** NUNCA `Icon(Icons.x)`. Siempre `AnimatedAppIcon(AppIcon.x, state: …)` (`lib/core/icons/icons.dart`):
  `active` al seleccionar, `loading` mientras escanea/sincroniza/imprime/GPS, `success`/`error` como resultado.
  `EmptyState`, `StatTile`, `StatusPill` y `UserRole.icon` reciben `AppIcon`; `NavTab`/`RoleTask` llevan `appIcon`.
  En tests: `findAppIcon`/`findAppIconInState` (`test/support/app_icon_finders.dart`), no `find.byIcon`.
  ¿Falta un ícono o hay que cambiar una animación? Usar el skill **animated-app-icons**.

## Reglas

0. **VOCABULARIO: "producto"/"productos", NUNCA "bulto"/"bultos".** Regla dura del dueño, aplica a todo lo que ve
   el usuario Y a comentarios en español. Los identificadores en inglés (`unitId`, `UnitTile`, `unitsTotal`) NO se
   tocan. Antes de cerrar: `grep -ri "bulto" lib/ test/` debe volver vacío (salvo `lib/core/api/**`, que viene del
   OpenAPI). Si un reemplazo mecánico diría un absurdo, **reescribir la frase** (p. ej. "ítems del pedido" vs
   "productos etiquetados"). Ver `.claude/memory/` → `vocabulario-producto-no-bulto`.
0b. **PROHIBIDO mutar etiquetas**: nunca emitir, reimprimir, revocar ni re-emitir etiquetas (ni por API, ni por DB).
   No es del agente. Si una etiqueta "no valida", el arreglo es del lado app o se le pide al dueño/backend.
   Diagnóstico de solo lectura sí; mutaciones NO. Ver `no-label-mutations-rule`.
1. UI en español; código en inglés; comentarios en español. Botones ≥ 48 dp (principales 56), pocos toques, legible al sol.
2. Riverpod 3 (`Notifier`, `.value`), go_router, Clean Architecture + CQRS, **una clase por archivo**.
3. Cliente API generado (regla #5): nunca DTOs a mano. Regenerar: `scripts/regen_api_client.ps1` (ver abajo).
4. Etiquetas Ed25519 offline en `lib/core/labels/`; `test/fixtures/label_test_vector.json` = copia del backend.
5. `copyWith` que deba volver a `null`: centinela `_unset` (no `x ?? this.x`).
6. **Flutter 3.32:** no existen `RadioGroup` (usar `groupValue`/`onChanged` por tile) ni
   `DropdownButtonFormField(initialValue:)` (usar `value:`). Formatear con el `dart` de 3.32 (el de 3.13 formatea distinto y rompe CI).
7. Toda pantalla nueva: test de widget + `testOnScreens` (`test/support/screen_sizes.dart`, 4 tamaños, `withTextScale(1.3)`).
8. Pedidos al backend: contrato concreto por `SendMessage` a la sesión del backend + doc en
   `docs/backend-requests/AAAA-MM-DD-tema.md` y fila en su `README.md`. Cómo derivar, implementar contra un
   contrato sin desplegar y diagnosticar datos: skill **backend-coordination**.

## Regenerar el cliente API

`powershell -ExecutionPolicy Bypass -File scripts/regen_api_client.ps1 [-Spec <v1.yaml>] [-DryRun|-Out <dir>]`
(o `scripts/regen_api_client.sh`). Genera en una copia temporal con `C:\sdk\flutter` y `tool/api_gen/`
(pubspec Dart 3.13), preprocesa el spec con la Python de WSL (la de Windows no tiene PyYAML), parcha
`MetaSealed?`, corre build_runner, formatea con 3.32 y copia solo `lib/core/api/`. **Avisa si cambió la
numeración de tipos anónimos `DataN`** ("[6/7] Revisando tipos anonimos DataN" → "Sin cambios" o la lista):
renombrar las referencias de la app/tests y los imports `models/dataN.dart` comparando campos (pasó:
`Data4→Data5`, `Data6→Data7`, `Data21→Data22`).

- **Pasar SIEMPRE `-Spec C:\Users\ehhuallata\Documents\APP\logistics\openapi\v1.yaml`**: el valor por defecto
  apunta al backend viejo de WSL. Probar primero con `-DryRun`.
- **`-DryRun` "falla" con exit 1 pero NO es un error:** el último paso es `git diff --no-index`, que devuelve 1
  cuando HAY diferencias (lo normal). El dry-run igual generó: mirá el resumen de archivos y los avisos.
- **No solo `DataN` se renumera: los `HelpersN` anónimos también** (pasó `Helpers2→Helpers3` en `my_crew`,
  2026-11-16). El script solo chequea `DataN`; tras aplicar, `flutter analyze` caza el resto
  (`List<Helpers2>` no asigna a `List<Helpers3>`) y se renombra en app/tests.
- **Un campo que el backend hizo REQUERIDO rompe la app contra un backend AÚN NO DESPLEGADO** (el modelo
  generado exige el campo; el staging viejo no lo manda → el parseo del objeto entero falla, p. ej. toda la
  lista de envíos entregados). Avisar al dueño: desplegar backend + app juntos, no la app sola contra staging
  viejo. Alternativa: pedir al backend que el campo sea nullable (pasó con `delivery_evidence.with_shortage`).
- **UN SOLO regen coordinado** cuando el backend tiene mucho spec en vuelo sin commitear: regenerar trae TODO
  de una (acopla trabajo no desplegado y puede renumerar). Esperar la señal "SPEC ESTABLE" del backend (o el
  commit/deploy del dueño) y regenerar una vez con todo. Ver [[realtime-sockets-contract]], skill
  **backend-coordination**.
- **Verificación sin suite:** el dueño NO quiere que corras `flutter test`. Tras el regen, verificá con
  `flutter analyze` (y el truco de abajo para el cliente generado, que está excluido); el build_runner que
  corre dentro del regen ya probó que el cliente generado compila. Entregá el comando de tests al dueño.
- El cliente generado está EXCLUIDO del analizador (`analysis_options.yaml`): `flutter analyze` en verde no
  prueba que compile. Para revisarlo: comentar un momento las exclusiones `lib/core/api/**` y `**/*.g.dart`,
  `dart analyze lib/core/api`, y restaurarlas.
- `scripts/preprocess_openapi.py` arregla lo que rompe a swagger_parser y avisa con una línea por arreglo:
  enums/objetos anónimos con el mismo nombre, parámetros unión, `data` de las respuestas con nombre propio
  (`<OperationId>Data`, `<Schema>Data`), tipos que chocan con Dart (`map` → `MapSettings`), JSON antes que
  multipart. Si un regen falla (Stack Overflow, `class Map`, un enum pisado, `.toJson()` sobre null), el
  arreglo va ahí, nunca a mano en `lib/core/api/`.
- Tras regenerar: `flutter analyze` (la suite la corre el dueño); los renombres se aplican con un script de
  Python en el scratchpad (los heredocs de Git Bash con Dart adentro se rompen).

## Reglas de negocio vigentes (nov 2026)

- **Tienda solo entrega al cliente final.** La llegada del pedido a la tienda la marca el CHOFER ("Entregar en
  tienda": escanear + foto). No existe "Recepción de mercadería" en el rol tienda: no reintroducirla.
- **"Consultar pedido"** (`lib/features/lookup/`, `/lookup`) es de los 6 roles y solo lectura: usa
  `GET /app/orders/lookup`; la etapa la calcula el servidor (`tracking.stage`), la app solo la traduce.
- **Admin** entra a la app (`lib/features/admin/`); la ficha del personal es UNA vista por pestañas para todos
  los roles. Listas paginadas con `PagedSearchList<T>` (`lib/core/widgets/`).
- Personal por ciudad; el alcance por rol lo aplica el servidor (`can_process`), no la app.
- Inspección y odómetro van por SALIDA (`route_id`), no por día: el chofer sale N veces.
- Lo que decide el dueño se implementa tal cual, sin dejar el flujo viejo "como control".

## Robustez por marca / plataforma (crítico: la app debe andar en TODAS las marcas)

Regla dura del dueño: que la app NO funcione en algunas marcas/teléfonos es crítico. No depender de
permisos o capacidades específicas de marca.

- **Ubicación: exigir solo PRIMER PLANO ("mientras se usa la app"), NUNCA "Permitir siempre" (background).**
  El rastreo corre con un **foreground service de tipo `location`** (manifest ya tiene
  `FOREGROUND_SERVICE_LOCATION` + `foregroundServiceType="location"`), y un FGS cuenta como uso activo → con
  primer plano alcanza para rastrear (incluida la app minimizada). Exigir `Permission.locationAlways`
  (ACCESS_BACKGROUND_LOCATION) dejaba BLOQUEADOS a Honor/Magic OS y a quien da solo "mientras se usa la app"
  (Android 11+ ni lo pide por diálogo). El gate (`LocationPermissionGate`) y `TruckTrackingService._start`
  usan `ensurePermission()` (primer plano). `ensureBackgroundPermission` sigue en `LocationService` pero NO
  se usa para gatear. Ver `.claude/memory/location-permission-foreground-honor.md`.
- **Sin Google Play Services (algunas marcas/regiones):** FCM/maps/Data Layer degradan sin tumbar la app
  (push "No disponible", etc.). Nunca asumir GMS presente.
- **Matanza agresiva de procesos (Xiaomi/Honor/HyperOS):** el foreground service mitiga; no romper su
  configuración (`-Xmx`, wake lock, id de servicio = id de la Live Update).

## Wear OS / smartwatch

- **Widgets del teléfono ≠ tiles del reloj.** Los App Widgets de Android (`lib/core/home_widgets/` + nativo
  en `android/app/.../widgets/`) YA existen y son del TELÉFONO. El reloj es aparte: un **módulo `:wear`**
  (nativo, Jetpack Tiles + ProtoLayout). No se "comparte" un widget del teléfono al reloj.
- **Dos caminos, trade-off real:**
  1. **Notificación espejada (SIN instalar app de reloj):** el teléfono postea una notificación NORMAL
     (no-ongoing, que alerta ≥1 vez; `WearMirror.kt`). El reloj la espeja como las de WhatsApp. **Las
     notificaciones de foreground service (ongoing) NO se espejan** → por eso la de la ruta/isla no llegaba.
     Es best-effort: depende del ajuste POR-APP del reloj (Galaxy Wearable / Wear OS). No se puede forzar
     desde la app.
  2. **App de reloj (`:wear`, Data Layer, SIN login):** el teléfono empuja el resumen (`WearBridge` →
     DataClient) y el reloj muestra **su propio tile + notificación** (no depende del espejado). Es lo
     ÚNICO confiable en todas las marcas, pero hay que instalar el `:wear` una vez (`./gradlew
     :wear:assembleDebug` + `adb install`).
- **El envío al reloj es AUTOMÁTICO** (en `LiveUpdatesChannel.show()`/`end()`), nunca un botón manual (el
  dueño lo pidió así; se quitó el botón de Ajustes).
- **Tile ProtoLayout: simple o no renderiza.** `EdgeContentLayout`/`CircularProgressIndicator`/`PrimaryLayout`/
  `screenShape` quedaban en BLANCO en algunos relojes. Usar una **caja centrada + texto** (`Box`+`Column`+
  `Text`), que se ve en redondo y cuadrado. El tile NUNCA debe quedar vacío (default "Sin ruta activa").
- Ver `.claude/memory/wear-os-data-layer.md`.

## Código nativo (Kotlin / Gradle / Wear): NO se verifica con analyze

`flutter analyze` y `getDiagnostics` solo cubren Dart. El código Kotlin/Gradle (canales, widgets, módulo
`:wear`) **no se valida acá**: se valida compilando/instalando en el dispositivo (lo corre el dueño).
Entregar el código + el comando y pedir el error de build si falla (iterar como con NDK/CameraX). Un
`include(":<módulo>")` nuevo en `settings.gradle.kts` ACOPLA su build al del teléfono: si rompe, comentar
el include para destrabar.

## Definición de terminado

`dart format` sin cambios + `flutter analyze` sin issues + `flutter test` verde (+ e2e si tocaste un flujo crítico),
con números. Si cambió Android/iOS: una build (`make apk`). Reportar qué no se pudo probar (hardware real).
**Quien lo corre es el dueño** (ver "Quién ejecuta"): si no pidió que lo corras, terminar con revisión estática
(imports, nombres contra enums/catálogos, fin de línea conservado, sin duplicados), decir claramente "no compilado"
y darle los comandos en orden, uno por bloque: `dart format lib test` → `flutter analyze` → `flutter test <carpeta tocada>`
→ `flutter test`.

**Verificación estática SIN correr flutter:** la herramienta `mcp__claude-vscode__getDiagnostics` devuelve los
errores/warnings del analizador del IDE (mismos que `flutter analyze`) y el hook los muestra tras CADA `Edit`.
Usala para dejar el código con **0 errores / 0 warnings** antes de entregar (incluye los tests: fakes que no
implementan una firma nueva salen acá). No reemplaza `flutter test` del dueño, pero cierra el grueso. Al terminar,
una corrida con `minSeverity: "Warning"` que vuelve `[]` es la señal de "estáticamente limpio".

## Antes de culpar al app: medir contra staging

Varias veces lo que parecía un bug del app era del backend (o al revés). El método que funcionó, en orden:

1. **`curl` directo al endpoint** con un usuario de prueba (`preparador@dismac.test`/`password123`, ver
   `.claude/memory/dev-test-users-scenario`) y mirar el **código HTTP y el JSON crudo**. 200 con datos ⇒ el
   problema es del app (parseo, filtro, estado); 4xx/5xx ⇒ es del backend.
2. **Comparar el JSON real contra el modelo generado**: claves que faltan y están como `required` rompen la
   pantalla entera sin decir por qué.
3. **Logs del backend** cuando hay 5xx: `ssh oci` → `docker logs --since 10m logistics-staging-app-1`; y el
   **access log** (`logistics-staging-web-1`) para ver el status real de cada request — ahí se ve, por ejemplo,
   que el POD daba 422 y la subida de fotos 500.
4. **`adb logcat`/`dumpsys`** para lo nativo (notificaciones, permisos, overlay): `dumpsys notification` muestra
   el contenido exacto que se está posteando; `appops get <pkg> SYSTEM_ALERT_WINDOW` el permiso de overlay.
5. Recién con el dato en la mano, decidir y **decirlo con el número** (status, cantidad de filas, campo que falta).

No asumir ni "arreglar" a ciegas: en esta app un diagnóstico equivocado llevó a re-emitir etiquetas que estaban
en uso (ver regla 0b).

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
| CI (runner Linux): `Install NDK (Side by side) 27.0.12077973 failed` → `Error on ZipFile unknown archive` / `Archive is not a ZIP archive`, build cae configurando `:app` | `android/app/build.gradle.kts` fija `ndkVersion` → AGP intenta auto-instalar el NDK y el zip que baja el instalador de Gradle sale corrupto (mirror responde algo que no es el zip) | Pre-instalar el NDK con `sdkmanager` ANTES del build, en cada job que compila Android (`.github/workflows/ci.yml`, jobs `build-apk` y `release-apk`): `yes \| "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --install "ndk;27.0.12077973"` con reintentos + `rm -rf $ANDROID_HOME/ndk/27.0.12077973` entre intentos. NO quitar el `ndkVersion` (está pineado a propósito) |
| `'bash\r': No such file or directory`, exited 127, consola de play se cierra al segundo | VS Code usa `C:\flutter` (CRLF) en vez del Flutter de WSL | `.vscode/settings.json` → `dart.flutterSdkPath=~/sdk/flutter` + Reload Window |
| Emulador aparece `unauthorized` | adb de WSL usa llave nueva que el emulador no confía | Copiar `adbkey{,.pub}` de Windows a `~/.android/` y reiniciar adb |
| `flutter test`: `Failed to load dynamic library 'libsqlite3.so'` (tests Drift) | WSL/Linux solo trae `libsqlite3.so.0`, no el symlink sin versión | Ya resuelto: `test/flutter_test_config.dart` redirige la carga a `.so.0` (no borrarlo). No requiere root |
| `flutter test integration_test`: mismo `libsqlite3.so` que arriba, solo en e2e | `flutter_test_config.dart` NO se hereda entre carpetas: el de `test/` no cubre `integration_test/` | Ya resuelto: `integration_test/flutter_test_config.dart` (copia del de `test/`). No borrarlo |
| e2e: `MissingPluginException(... mobile_scanner ...)` al escanear | La pantalla usa `scanContinuous` (`continuousScannerProvider`) y el e2e solo overrideaba `codeScannerProvider` → abre el escáner REAL | `e2e_app.dart` cablea `continuousScannerProvider.overrideWithValue(h.scanner.callContinuous)`; el texto de `ScanFeedback` NO aparece en pantalla (vive en el overlay) → verificar por `h.scanner.continuousMessages`. Ver `.claude/memory/test-battery-and-infra.md` |
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
| Muchos `ClientException … tile.openstreetmap.org` en tests | La capa de tiles intenta red en test | Ruido esperado; no falla el test. PERO tapa el fallo real y hasta `--reporter failures-only` queda sepultado (el `+N:` con `+` es un test que PASA). Para aislar: `flutter test <dirs> --reporter json 2>$null \| Out-File $j` + `ConvertFrom-Json` filtrando `testDone`/`result!=success` y `type=='error'`. Ver `.claude/memory/test-battery-and-infra.md` |
| Un test que debería pasar REVIENTA con `Null check operator used on a null value` dentro de un fake (no en `lib/`) | Un fake a mano devuelve `campo!` cuando el test no seteó ese campo; el error crudo (no es `ApiException`) se escapa del `catch (on ApiException)` del código bajo prueba (p. ej. `_completeSignIn` que degrada `/me`) y rompe el flujo | El fake debe DEGRADAR con el MISMO tipo de excepción que simula, no con un null-check: `if (meResponse == null) throw const ApiException(status: 503, …)`. Así los tests que no configuran ese campo igualan el comportamiento real. Trampa que dejó un agente (nov 2026) |
| `pumpAndSettle timed out` con un `AnimatedAppIcon` en pantalla | Ícono en `state: loading` (loop real) | `pump()` + `pump(Duration)`; el `ambient` del botón central respira solo 3 ciclos y se detiene |
| `find.byIcon(Icons.x)` no encuentra nada | La app ya no usa `Icon` | `findAppIcon(AppIcon.x)` / `findAppIconInState(AppIcon.x, AppIconState.success)` |
| `UnimplementedError` en `Matrix4.translate` | vector_math 2.1 no acepta `int` | `m.multiply(Matrix4.translationValues(x, y, 0))` |
| El diff muestra el archivo entero tras un script/codemod, o `git` escupe "LF will be replaced by CRLF" | El repo mezclaba CRLF y LF y `core.autocrlf=true` convertía en Windows | **Ya resuelto:** `.gitattributes` fija LF para todo el texto (`.bat`/`.cmd` CRLF, binarios `binary`) y el repo se normalizó (`git add --renormalize .`); `core.autocrlf=false` local. Si reaparece, revisar que `.gitattributes` exista y `git config core.autocrlf` sea `false` |
| WSL colgado, VS Code "Starting Linux Subsystem" | Varios `flutter test`/`analyze` en paralelo (agentes) | Matar `dart`/`flutter`; liberar RAM sin `wsl --shutdown`: `wsl -d Ubuntu-22.04 -u root -- sh -c "sync; echo 3 > /proc/sys/vm/drop_caches"` |
| "Tengo una tarea ejecutando hace N min" / un `flutter run` que nunca termina | `flutter run` queda ADJUNTO para siempre (hot-reload + logs del device); no es un cuelgue | `TaskStop <id>` + `pkill -9 -f 'flutter.*run -d <ip>'` (y su `frontend_server_aot`/`dds_aot`). NO matar `dart language-server`/`devtools`/`dart_tooling_daemon`/`flutter daemon --show-web-server-device`: son de la extensión de VS Code |
| `SendMessage` al backend falla ("No agent named …") | La sesión del backend ROTA de nombre (logistics-8e → 4c → 1a → 68…) | Antes de mensajear, `ListAgents` y usar el nombre vigente; el pedido igual queda en `docs/backend-requests/` para quien lo tome |
| Escanear una etiqueta Zebra/Code128 no la reconoce, o un test de escaneo rompe al leer un código plano | La etiqueta acepta QR (offline Ed25519) **y Code128** (el valor ES el `label_id` → se resuelve online por `/app/labels/{id}/resolve`); `kLabelScanFormats=[qrCode,code128]` | En lib ya está cableado (`label_resolver.dart`); en tests que escanean códigos PLANOS pasar `labelResolverProvider.overrideWithValue(FakeLabelResolver(echo:true))`. Detectar QR con `SignedLabel.fromQrContent` ANTES de resolver (un QR sin claves NO va a `/resolve`). Ver `.claude/memory/code128-label-scanning.md` |
| Un agente dejó un archivo roto / se colgó sin terminar | Los agentes NO corren flutter; a veces dejan sintaxis rota o se cuelgan | Correr `getDiagnostics` sobre CADA archivo que tocó el agente apenas cierra; lo interconectado (mapa/GPS, pantallas compartidas) hacerlo el coordinador, no repartirlo. Ver `.claude/memory/parallel-agents-method.md` |
| La app muestra **"Error del servidor"** (login u otra pantalla) | Ese texto sale de `api_exception.dart` SOLO con **HTTP ≥ 500**: es un 5xx REAL del backend, NO bug de la app | Aislar con `curl` directo al endpoint por rol (`curl -X POST http://137.131.245.152:8110/api/v1/app/auth/login -d '{"email":…,"password":"password123","device":{"fingerprint":"x","platform":"android","name":"x"}}'`). Si da 500, leer el log del contenedor (`ssh oci 'docker logs --since 10m logistics-staging-app-1'`). Caso real: 2FA cifrado con APP_KEY viejo → `DecryptException`. Ver `.claude/memory/staging-login-500-2fa-appkey.md` y `staging-server-access.md` |
| Compilar **staging** en el teléfono por USB desde WSL ("no sale en la lista de dispositivos") | El picker de VS Code corre en WSL y NO ve el USB de Windows; usbipd se cae con el OnePlus | Build en WSL `flutter build apk --profile --dart-define-from-file=config/staging.json` + instalar con el **adb de Windows** (`adb.exe install -r -d`); staging es **profile** (release bloquea el http en claro). Fix del driver y pasos: `.claude/memory/device-run-usb-wsl.md` |
| Impresora de oficina (Ricoh/láser) "dice que imprimió pero no sale nada" o "sale en blanco" | Ricoh exige autenticación de usuario: por IPP CANCELA todo (`job-canceled-at-device`); el PCL5 crudo le sale EN BLANCO (su driver usa PCLXL) | Imprimir por **9100 con PDF DIRECTO** (`PdfDirectJobWriter`, `@PJL ENTER LANGUAGE=PDF`) + **código de usuario en texto claro** (`USERCODE`, el operario lo carga en avanzado). La detección ya manda Ricoh por 9100. Diagnosticar desde una PC en la red de la impresora (IPP solo-lectura + capturar la salida del driver con `PrintDocument.PrintToFile`). NUNCA credenciales reales en repo/tests. Ver `.claude/memory/wifi-printer-discovery.md` |
| Una pantalla dice **"No se pudo cargar"** pero `curl` al endpoint devuelve **200** | El backend dejó de mandar un campo que el modelo GENERADO tiene como `required` → `fromJson` explota. Pasó con `EmittedLabel.revoked` cuando el backend quitó `revoked`: **ningún** pedido cargaba | Comparar las claves del JSON real contra los `required` del modelo. Parche: campo opcional con default (`this.x = false` + `json['x'] as bool? ?? false` en el `.g.dart`) + test de regresión con el JSON REAL. Se resuelve solo al regenerar |
| La paginación "no avanza": `next_page`/`next_cursor` siempre vacíos | **`MetaSealed` es inservible**: (a) deserializa en camelCase (`perPage`, `nextCursor`) y el backend manda snake_case; (b) la PRIMERA variante solo exige `count`, así que **siempre gana** y las de paginación son inalcanzables | Paginar por **número de página** con heurística "página completa ⇒ puede haber más" (cuesta un GET vacío al final). Al regenerar con el `ListMeta` único del backend, sacar la heurística |
| `GET /app/shipments?status=planned` → **422** "The selected status is invalid" | Los estados del backend son **MAYÚSCULAS** (`PLANNED`, `RECEIVED`, `IN_EXECUTION`) | Mandar el valor del enum (`ShipmentStatus` serializa bien); en `curl` a mano usar mayúsculas. El backend va a aceptar ambos |
| **422 "the field must match the format Y-m-d"** en un POST (p. ej. `performed_on` del checklist pre-salida) | El cliente generado serializa los `DateTime` del CUERPO como fecha-hora ISO (`toIso8601String`), pero varios campos del backend se validan `date_format:Y-m-d` (fecha de calendario). `DateQueryInterceptor` solo arregla los QUERY params, NO el cuerpo | Mandar ese endpoint por **Dio directo** con el campo en `Y-m-d` (`request.toJson()..['campo']='YYYY-MM-DD'`), reusando el modelo generado para parsear la respuesta. Patrón ya usado en `fleet_data_source.dart` (`getMyCrew`, `conductPreTripChecklist`) |
| Tarifa del transportista siempre **404** aunque el corredor "exista" | Los corredores de tarifas/liquidaciones son **slugs** (`cd-santa-cruz`), NO los códigos de nodo de `/app/network/nodes` (`CD-SCZ-01`) | Usar los slugs (salen de las liquidaciones del transportista). Ver `.claude/memory/carrier-corridor-slugs` |
| El avance de la ruta se contradice (resumen dice "5/7" pero la lista muestra 6 entregadas, o "ruta completada" con pendientes) | DOS fuentes: el resumen usaba los conteos agregados del backend (`completed_stops`/`stops_remaining`/`status`, que además cuentan fallidas/reprogramadas como "completadas") y la lista usa el estado por parada | **Fuente ÚNICA item-por-item:** `RouteProgress.of(route, settled)` (`domain/route_progress.dart`) cuenta el estado EFECTIVO de cada `stop` (`effectiveStopStatus`); `isComplete` = sin pendientes, NUNCA el `status`/conteo del backend. Usarla en resumen, barra, "Mi día", detección de ruta terminada y gate del botón "Finalizar". Ver `.claude/memory/driver-tracking-count-single-source` |
| Un botón "Siguiente entrega"/"avanzar" marca una parada como entregada que el chofer NO entregó | La barra decidía "cerrada" por `deliveryStateProvider` (estado de la ENTREGA del envío); si el backend reportaba el envío `delivered` por su cuenta, aparecía el botón para una parada pendiente y al tocarlo hacía `settle(completed)` | Gatear las acciones de parada por el **estado EFECTIVO de la parada** (`effectiveStopStatus(stop, settled)`), no por el estado del envío. El POD/fallida ya hacen `settle`; el botón de avanzar SOLO refresca, nunca marca |
| Backend agregó un campo/param aditivo (nullable) y no querés/ no podés regenerar el cliente ahora | El regen (`scripts/regen_api_client.ps1`) es un comando del dueño (Dart 3.9 en `C:\sdk\flutter`) | Agregar el campo A MANO al modelo generado + su `.g.dart` (from/toJson), con comentario "al regenerar viene solo" (precedente: `unit_ids`, `route_id`/`plate`/`driver_name`). Al regenerar se pisa idéntico. Si va por **Dio directo** (`fleet_data_source`), `request.toJson()` ya lo incluye |
| Querés que una feature nueva del backend NO regresione mientras no esté deployada | Si cableás el comportamiento nuevo "a lo bruto", antes del deploy (el campo llega null/ausente) rompés el flujo viejo | **Auto-upgrade sin regresión:** detectar si el backend ya manda el dato (p. ej. `items.any((c)=>c.routeId!=null)`) → si sí, comportamiento nuevo; si no, fallback al viejo. Así se activa solo al deployar, sin tocar código. Ej.: checklist por ruta vs diario (`inspectionForCurrentRoute`). Ver `.claude/memory/checklist-por-ruta-y-hora-entrega` |
| `pumpAndSettle timed out` en un test de un pie/estado "cargando" | El spinner es una animación en loop (igual que `AnimatedAppIcon` en `loading`) | `pump()` + `pump(Duration(...))` en vez de `pumpAndSettle()` |
| La herramienta Bash muere con `fatal error - add_item ... failed, errno 1` | Git Bash en esta PC se cae con heredocs/`python - <<EOF` y comandos largos encadenados | Reintentar el comando (suele pasar 1 de cada N) o, mejor, editar con las herramientas Edit/Write en vez de scripts por heredoc |
| Emitir etiquetas tira **"Error del servidor"** (500) | Backend sin `LABELS_SIGNING_KEY` en el env (clave Ed25519 de firma) → `RuntimeException` en `LabelsServiceProvider`. NO es la app | Es backend/ops: `php artisan logistics:labels:keygen` + setear la env. La app verifica con las públicas de `GET /app/labels/public-keys` (no fija ninguna). Derivar por `docs/backend-requests/` + a la sesión del backend. Ver `.claude/memory/staging-login-500-2fa-appkey.md` |
| El APK "pesa 90+ MB" | Es el APK **universal** (`flutter build apk` sin split): trae las **4 ABIs** (x86/x86_64/armeabi-v7a/arm64), ~95% del peso. `--target-platform android-arm64` NO basta (baja solo el motor; los .so de plugins siguen con 4 ABIs → ~50 MB) | Compilar con **`--split-per-abi`** (lo que ya hace `make apk`/CI): `app-arm64-v8a-release.apk` ≈ **33 MB**. Instalar ese en el teléfono. Sin `key.properties` el release se firma con la clave debug (sirve para probar). Ver `.claude/memory/apk-size-split-abi.md` |
| Desde esta sesión (Git Bash de Windows) el teléfono conectado en VS Code "no aparece" | WSL y Windows tienen **servidores adb SEPARADOS** (WSL2 es NAT). Si VS Code está en modo WSL-remoto, sus tareas usan el adb de WSL; esta sesión usa el `adb.exe` de Windows | Conectar con el **adb de Windows** (`$HOME/AppData/Local/Android/Sdk/platform-tools/adb.exe`) a la MISMA `ip:puerto` (por WiFi conviven). Fijar `tcpip 5555` para un puerto estable. En `tasks.json` pasar la ruta del script **relativa** + `cwd`, no `${workspaceFolder}/...` (los `\` rompen bash). Ver `.claude/memory/device-run-wireless-adb.md` |
| El chofer ve **"No se pudo registrar. Intentá de nuevo."** y no se sabe por qué | El genérico de `submit_feedback.dart` tragaba el motivo real del backend; había que sacar la DB del teléfono para verlo | La app ya MUESTRA el motivo real: `OfflineQueue.submit(onReject: (e) => ...)` entrega el `ApiException` del 4xx permanente → pasar `e.message` a `showSubmitOutcome(..., failureDetail:)`. Último recurso para ver el error crudo: leer `outbox_actions.last_error` de la DB del teléfono con **Python stdlib** (`adb exec-out run-as PKG cat app_flutter/logistics_app.sqlite{,-wal,-shm}`; el -wal tiene lo último). Ver `.claude/memory/pod-scanner-vehicle-hardening.md` |
| El POD falla con **"no hay entrega abierta para el envío …"** (aunque la etiqueta esté "Cargada") | La ETIQUETA está Cargada (nivel envío) pero la ENTREGA (objeto de execution) no está ABIERTA. El app NO la puede abrir solo. Casi siempre = el backend **no está deployado** con el fix de auto-abrir-entrega | Es del BACKEND: desplegar + `php artisan logistics:execution:open-missing-deliveries [--force] [--shipment=<uuid>]` (abre en Loaded las faltantes; NO re-emite etiquetas). El "transición inválida desde DELIVERED" = ya entregado (backend lo hace idempotente). La FOTO no es la causa (el POD manda `photo_url:null` y falla antes). Ver `.claude/memory/pod-scanner-vehicle-hardening.md` |
| La Live Update / isla (chip en la cámara, Android 16 / Dynamic Island) muestra mal el avance ("Parada 1 de 7" congelado, pocos puntos) o se quiere cambiar su texto/tamaño | El contenido se arma en Dart (`RouteLiveStatus`): `chipText` = texto del chip del sistema (ahora SOLO `completedCount/stopCount` sin hora), `completedCount` item-por-item (no `route.completedStops`). El render lo hace el SO: `LiveUpdatesChannel.kt` (notificación + ProgressStyle, segmentos=`stopCount`, puntos=`completed`). "1 de 7 congelado" = el `settled` en memoria se pierde al reiniciar y el route sheet sin deploy devuelve todo pendiente → lo fija el deploy del backend | Cambiar textos/contador en `RouteLiveStatus` (Dart, probado); el **tamaño** de la pastilla del sistema NO se controla (lo decide el SO/fabricante). La pastilla PROPIA (`IslandOverlay.kt`, overlay, requiere permiso) SÍ se controla: ahí está la compacta (camión + contador) y `celebrate()` (camión verde + bote al entregar). Ver `.claude/memory/driver-tracking-count-single-source` |
| Tentación de que cada widget/pantalla pida el mismo dato al backend (varias llamadas al mismo endpoint) | Regla dura del dueño: **no saturar el backend** ("si se ocupa lo mismo en varios lugares, centraliza, si no colapsaremos el backend") | UN provider compartido por dato (`driverRouteProvider`, `truckTrackingProvider.lastFix`, `deliveryStateProvider`…) y los widgets lo `watch`ean. Lo derivable se calcula EN EL TELÉFONO (distancia GPS→parada con `remainingToStop`, avance item-por-item con `RouteProgress`) sin pegarle al backend. ¿Falta un campo? Enriquecer un endpoint existente antes que agregar una 2.ª llamada. Ver `.claude/memory/feedback-working-style` |
| Un pedido sale "Sin autorizar" / "Falta asignar camión" en despacho | El backend autoriza el pedido cuando tiene camión asignado; el motivo llega en `authorized_reason_code` | El texto sale de `dispatchBlockText(line)` (`dispatch_lines_body.dart`); lo destraba el admin/supervisor desde Envíos → "Asignar a un camión". No agregar botones de "publicar plan" |
| Probar staging con una cuenta y el teléfono de esa cuenta se desloguea | Hay 1 sesión activa por tipo de cliente; un login de diagnóstico como app móvil pisa la del teléfono | Loguear el diagnóstico con `device.client_kind: "web"` |
| Un test de widget falla con `contains(<Map>)` aunque el mapa "es igual" | `contains` compara por identidad los mapas | `contains(equals({...}))` |
| El análisis pasa pero un test no compila tras regenerar el cliente | Los fakes de `test/` implementan data sources con tipos del cliente (`Role` vs `StaffRoleName`, `DataN`) | Revisar `test/features/*/fake_*.dart` y los helpers `fromJson` junto con cada regen |
| Un test con `pumpAndSettle` no ve el efecto de un evento con debounce (tiempo real, búsqueda) | `pumpAndSettle` no avanza timers si no hay frames | `await tester.pump(const Duration(milliseconds: 500))` antes |
| `find.widgetWithText(FilledButton, 'Guardar')` no encuentra el botón fijo al pie | `FilledButton.icon` es una subclase privada | `find.text('Guardar')` o `findButtonWithText<FilledButton>()` |
| Un test toca "el día 24" y abre otra cosa, o no toca nada | El mismo texto está en la pantalla de atrás (grilla) y en el diálogo de arriba | `find.descendant(of: find.byType(DateRangePickerDialog), matching: ...)` |
| El test de una pantalla larga no encuentra un campo | `ListView` es perezosa y el campo no se construyó | Agrandar la vista (`tester.view.physicalSize`) o `ensureVisible` |
| `Cannot use Ref ... inside life-cycles` al cerrar un notifier | `ref.read` dentro de `ref.onDispose` | Guardar la referencia en un campo durante `build` |
| `AutoDisposeFutureProvider` no existe | Riverpod 3 unificó los tipos | `FutureProvider<T>` (y `AsyncNotifierProvider.autoDispose`) |
| El heredoc de Bash con código Dart falla ("unexpected EOF"), o Git Bash muere con `add_item ... errno 1` | Comillas y `$` del Dart; el crash es transitorio | Script de parche escrito con Write al scratchpad y corrido con `python`; repetir el comando tras el crash |
| El chofer da permiso de ubicación pero la app lo deja en la **pantalla bloqueada** (Honor/Magic OS, otros) | El gate exigía "Permitir siempre" (`locationAlways`/ACCESS_BACKGROUND_LOCATION); Android 11+ no lo da por diálogo y Honor lo esconde/reporta mal | Exigir solo PRIMER PLANO (`ensurePermission`): el foreground service de tipo `location` alcanza. Ver sección "Robustez por marca" y `location-permission-foreground-honor` |
| La notificación de ruta (o la isla) **no se espeja al reloj** (Samsung/Wear OS) pero WhatsApp sí | Es de **foreground service (ongoing)**; los relojes NO espejan las ongoing. La isla es un overlay del teléfono, nunca viaja | Postear una notificación NORMAL aparte (`WearMirror`, no-ongoing, que alerta ≥1 vez). Igual depende del ajuste por-app del reloj. Lo garantizado = app de reloj `:wear` (Data Layer). Ver `wear-os-data-layer` |
| El **tile de Wear OS queda en blanco** aunque el `:wear` esté instalado | `EdgeContentLayout`/`CircularProgressIndicator`/`PrimaryLayout`/`screenShape` de ProtoLayout no renderizan en algunos relojes | Caja centrada + texto (`Box`+`Column`+`Text`); nunca dejar el tile vacío (default "Sin ruta activa"). Validar compilando en el reloj (no lo cubre `analyze`) |
