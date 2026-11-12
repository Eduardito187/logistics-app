# Consumo de batería — auditoría y arreglos (nov 2026)

Reporte del dueño: con la app abierta el teléfono perdió ~50 % de batería en 1–2 h (un juego pesado
gasta 15–20 % en el mismo tiempo). Se auditó todo lo que despierta CPU, radio, GPS, GPU o cámara.

> Estado: cambios **sin compilar** (los corre el dueño). Ver "Verificación" al final.

## Hallazgos, ordenados por impacto estimado

| # | Hallazgo | Impacto | Arreglo |
|---|----------|---------|---------|
| 1 | **Un POST por posición GPS cada 10 s** (`TruckTrackingService._onFix` → `OfflineQueue.submit` inmediato). Cada envío deja la radio celular ~10–15 s en alto consumo: con uno cada 10 s la radio **nunca se dormía** en todo el turno del chofer. | Muy alto (radio 3G/4G encendida permanente ≈ lo mismo que una llamada/streaming) | **Envío por lotes**: las posiciones se juntan en memoria y se encolan en ráfaga cada 60 s (120 s con ahorro). La primera de cada arranque sale enseguida. El lote se vacía al pasar a 2.º plano, al detener y al cambiar de parada. |
| 2 | **GPS en alta precisión todo el día**, aunque el camión esté estacionado (carga en el depósito, almuerzo, descarga). El rastreo arranca apenas hay una parada pendiente. | Muy alto (chip GPS encendido horas sin necesidad) | **GPS adaptativo** (`MotionDetector` + `TrackingProfile`): tras 3 min sin salir de un radio de 40 m pasa a "detenido" = precisión balanceada (Wi-Fi/antenas, **chip GPS apagado**), lecturas cada 60 s y solo si se movió 50 m. Al moverse vuelve a "en marcha" (GPS preciso, 15 s). Con el camión quieto, un latido cada 5 min lo mantiene "vivo" para el supervisor. |
| 3 | **Cámara + análisis de códigos sin límite**: el escáner (continuo o puntual) abierto sobre la mesa o en el bolsillo sigue con la cámara y ML Kit a pleno. | Alto mientras pasa (cámara ≈ juego pesado) | **Pausa por inactividad**: 60 s sin leer nada → cámara apagada con la capa "Cámara en pausa para ahorrar batería" y botón grande "Seguir escaneando". Cada lectura posterga la pausa. |
| 4 | **Loops de animación infinitos**: el ícono en `loading` hacía `repeat()` sin fin; si algo quedaba en "cargando" la GPU dibujaba a 60 fps para siempre. Además las pestañas ocultas del `IndexedStack` (Inicio/Tareas) **no pausan sus tickers**. | Medio–alto (GPU a 60 fps continuo) | Tope al loop de `loading` (~30 s; ~5 s con ahorro), después queda quieto en su estado. `TickerMode(enabled: …)` en las pestañas ocultas del `HomeShell`. |
| 5 | **Radar del camión**: pulso de 2,5 s por cada lectura (≈25 % del tiempo animando) sobre el mapa oscuro, que tiene una capa con `ColorFilter` → cada cuadro recompone toda la pantalla. | Medio (en "Entrega en curso") | Pulso de 1,2 s (≈8 % del tiempo con lecturas cada 15 s) y **estático** con ahorro de energía / batería baja (también al activarlo en caliente). |
| 6 | **`Timer.periodic(1 s)` del auto-enfoque del mapa**: despertaba la CPU cada segundo todo el turno, **también en 2.º plano** (el foreground service mantiene vivo el proceso). | Bajo–medio (en 2.º plano impide el reposo profundo) | Un único `Timer` programado al instante exacto en que se cumple la ventana de quietud (al detenerse el camión o soltar el mapa). Cero timers mientras nada cambia. |
| 7 | **Wi-Fi lock** del foreground service (`allowWifiLock: true`): mantenía la Wi-Fi en alto rendimiento con la app en 2.º plano. El chofer va con datos móviles. | Bajo–medio (en 2.º plano) | `allowWifiLock: false`. El `allowWakeLock` se mantiene (sin él Android puede dormir la CPU y cortar el GPS/lote en 2.º plano; la telemetría es obligatoria). |
| 8 | **Sin modo ahorro**: la app ignoraba el "Ahorro de batería" del sistema y la batería baja. | — | Nuevo `lib/core/power/` (ver abajo). Con ahorro o batería < 20 % (sin cargar): GPS el doble de espaciado, envíos cada 2 min, sin respiración del botón central ni pulso del radar, loader de marca quieto, loops de carga cortos, polling de "Flota en vivo" cada 90 s (en vez de 30 s). |

**Revisado y sin problemas** (no se tocó): `ConnectivityNotifier` (ya drena solo en el flanco
offline→online), WorkManager periódico (15 min, con `requiresBatteryNotLow`), `UiAliveBeacon`, cola
offline (lotes de 25, backoff exponencial, un timer a la vez), polling de "Flota en vivo" (ya se
detiene en 2.º plano y con la pantalla tapada), escáneres (720p, 4 análisis/s, se sueltan al
minimizar), splash Lottie (one-shot), `CircularProgressIndicator` indeterminados (todos transitorios),
tiles del mapa (caché en disco, `const OsmTileLayer()`), nada mantiene la pantalla encendida
(no hay `wakelock`/`FLAG_KEEP_SCREEN_ON`; el `WAKE_LOCK` del manifest es del foreground service).

## Impacto esperado

- **Chofer en ruta, app abierta** (el caso del reporte): la radio pasa de "siempre encendida" a
  ~1 ráfaga por minuto; el GPS se apaga en las paradas largas; el mapa anima mucho menos. Estimado:
  **−50 a −70 % del consumo atribuible a la app** (la pantalla encendida sigue gastando lo suyo).
- **Chofer con la app en 2.º plano**: sin timer de 1 s ni Wi-Fi lock; lote cada 60 s; GPS balanceado
  detenido.
- **Preparador/tienda con escáner olvidado abierto**: la cámara se apaga sola al minuto.
- **Supervisor**: sin cambios grandes (ya estaba bien); con ahorro, refresco cada 90 s.

Trade-off aceptado: el supervisor ve la posición del camión con hasta ~60 s de retraso (antes ~10 s);
la primera posición de cada arranque sale al instante. Si el SO mata la app sin aviso se pueden perder
hasta ~60 s de posiciones (no escaneos: esos siguen persistiéndose al instante).

## Qué se cambió (archivos)

- `lib/core/location/tracking_profile.dart` (nuevo): perfiles en marcha / detenido × normal / ahorro.
- `lib/core/location/motion_detector.dart` (nuevo): en marcha vs detenido (puro, testeable).
- `lib/core/location/location_service.dart`: `stream(profile:)`, `settingsForProfile`, intervalo 15 s.
- `lib/core/location/truck_tracking_service.dart`: GPS adaptativo, lote, latido, dedupe por distancia,
  flush en 2.º plano/stop/cambio de parada, reacción al ahorro de energía, sin Wi-Fi lock.
- `lib/core/power/` (nuevo): `PowerStatus`, `PowerChannel` (MethodChannel `bo.com.dismac/power`,
  degrada a "desconocido" sin plugin), `PowerStatusNotifier` (lee al crear, al volver a primer plano
  y en cada lote del GPS; sin timers propios), `MotionBudget` (presupuesto global de animaciones).
- `android/.../PowerChannel.kt` (nuevo; ya llamado desde `MainActivity`), `ios/Runner/PowerChannel.swift` (nuevo).
- `lib/core/icons/animated_app_icon.dart`: tope del loop de `loading`; sin respiración con ahorro.
- `lib/features/driver/presentation/widgets/radar_pulse.dart`: 1,2 s y estático con ahorro.
- `lib/features/driver/presentation/widgets/active_delivery/delivery_map.dart`: timer puntual.
- `lib/core/navigation/home_shell.dart`: `TickerMode` en pestañas ocultas.
- `lib/core/scanning/scanner_paused_overlay.dart` (nuevo), `continuous_scanner.dart`,
  `scanner_screen.dart`: pausa de cámara por inactividad.
- `lib/core/widgets/brand_loader.dart`: quieto con ahorro.
- `lib/features/supervisor/presentation/supervisor_fleet_screen.dart`: 90 s con ahorro.
- `lib/app.dart`: mantiene vivo `powerStatusProvider`.

## Para probar en dispositivo (no se puede headless)

1. **Android → Ajustes → Batería → Uso de batería** (o "Uso desde la última carga completa"): comparar
   DisTrack antes/después con 1 h de ruta real (app abierta en "Entrega en curso"). Ver el desglose
   "Primer plano / Segundo plano" y "Red móvil" / "GPS".
2. **Perfil de energía** en Android Studio (*Profiler → Energy*) o `adb shell dumpsys batterystats`
   (`--reset` antes, `dumpsys batterystats --charged bo.com.dismac.logistics_app` después): revisar
   wakelocks, "Mobile radio active" (debe bajar mucho) y GPS ("Location: … high power").
3. **GPS adaptativo**: dejar el camión quieto 3+ min → en `dumpsys location` la solicitud debe pasar a
   `BALANCED_POWER_ACCURACY` con intervalo 60 s; al moverse, vuelve a `HIGH_ACCURACY` 15 s.
4. **Ahorro de energía**: activar "Ahorro de batería" desde la bandeja → al volver a la app, el radar
   no pulsa y el botón central no respira; en `dumpsys location` el intervalo pasa a 30 s.
5. **Escáner**: abrir el escaneo continuo y no leer nada 60 s → "Cámara en pausa…"; "Seguir
   escaneando" la retoma.
6. **iOS**: Ajustes → Batería (uso por app) y Modo de bajo consumo.
7. Pendiente sugerido: perfilar con DevTools (Performance overlay) "Entrega en curso" para medir el
   costo por cuadro del `ColorFilter` del mapa oscuro (si es alto, evaluar tiles oscuros
   pre-renderizados).

## Verificación (la corre el dueño, de a uno)

```bash
dart format lib test
```
```bash
flutter analyze
```
```bash
flutter test test/core/location test/core/power test/core/scanning test/icons
```
```bash
flutter test
```

Nativo: el coordinador debe agregar `ios/Runner/PowerChannel.swift` al target Runner en Xcode y
llamar `PowerChannel.register(messenger:)` en el `AppDelegate`; Android ya lo registra `MainActivity`.
