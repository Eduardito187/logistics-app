# Brief para agentes — Íconos animados custom "en acción" (DisTrack / logistics-app)

> **Para quién es esto:** los agentes/desarrolladores que van a diseñar y
> cablear los íconos animados personalizados de la app. Es un brief autónomo:
> contiene TODO el contexto (marca, técnica, inventario ícono por ícono,
> especificación de animación, wiring y checklist). Leerlo entero antes de tocar
> nada. UI en español, código en inglés, comentarios en español.

---

## 0. Qué vas a construir (resumen de una línea)

Reemplazar los `Icons.*` de Material por un set de íconos **custom animados**,
coherentes con la marca **DisTrack**, que reaccionan "en acción" (al tocar, al
quedar activos, al cargar, al tener éxito/error), optimizados para choferes y
personal de tienda mayores, con guantes, bajo el sol y con una sola mano.

**Decisión técnica tomada (MIXTO):**
- **Hero (impacto visual):** barra de navegación (4 tabs + botón central) y las
  **acciones estrella** de cada rol → **Rive** (`.riv`, state machines) o
  **Lottie** (`.json`) cuando sea una animación lineal simple.
- **Estados/feedback simples** (check, error, sync, escaneo, GPS, etc.) →
  **Flutter puro** (`CustomPainter`/`AnimatedIcon`/`AnimatedSwitcher`), sin
  assets, que heredan color y dark mode solos.
- **Un único contrato de widget** `AnimatedAppIcon` envuelve a los tres para que
  el resto de la app no sepa ni le importe cómo está hecho cada ícono.

---

## 1. Marca DisTrack (obligatorio respetar)

Fuente de verdad: `lib/core/brand/` y la memoria `distrack-rebrand`.

| Token | Valor | Uso |
| --- | --- | --- |
| Rojo marca | `#E30613` | Acento PUNTUAL (nunca inunda la pantalla; "rojo neutralizado") |
| Tinta / casi negro | `#141414` | Íconos e íconos activos en tema claro |
| Ámbar | `#FFB000` | Advertencias, estados intermedios, highlight |
| Hueso / fondo | `#F3F3F1` | Fondos claros |

- Tipografía: **Barlow** / **Barlow Condensed** (no aplica a íconos, pero el
  trazo de los íconos debe sentirse de la misma familia: geométrico, grueso,
  redondeado en las puntas).
- **Rojo neutralizado:** el `#E30613` es acento, no color base. Un ícono NO debe
  ser rojo "porque sí"; el rojo se reserva para alerta/acción crítica. Estados
  normales = tinta (`#141414` claro / blanco-hueso en dark).
- Grosor de trazo coherente (≈2.2–2.5 px a 24 dp), esquinas redondeadas,
  legible a 1 color. Debe leerse a **24 dp** y a **28–32 dp** (botón central).

## 2. Contexto técnico del proyecto

- **Flutter 3.32.0 / Dart 3.8**, Riverpod 3 (Notifier), go_router 17.
- **Lottie ya es dependencia** (la usa el splash `BrandSplash`). Rive NO está:
  si se usa, agregar `rive` a `pubspec.yaml` (pinnear versión, correr
  `flutter pub get`; **no** correr `pub get` con una build de Gradle en curso).
- La barra inferior **flota sobre el contenido** (`extendBody: true`); los
  íconos de la barra viven en `lib/core/widgets/floating_pill_nav_bar.dart`
  (`_NavItem` y `_CenterButton`). La barra adapta sus items por rol.
- Pantallas pensadas para **gama baja** (hay fase de performance con `cacheFor`,
  escáner continuo, prefetch): las animaciones NO deben tirar FPS ni calentar el
  equipo. Nada caro en loops infinitos salvo que el estado lo exija (escaneando,
  sincronizando).
- **Offline-invisible:** un escaneo nunca espera a la red. Las animaciones de
  "sync/nube" deben ser sutiles y NO sugerir que el usuario tiene que esperar.
- Dark mode: la app tiene tema claro y oscuro. Todo ícono debe verse bien en
  ambos (en Flutter puro usar `ColorScheme`; en Rive/Lottie exponer el color
  como input/delegate y pasárselo desde el tema).

### Dónde se usan los íconos hoy (puntos de integración)
- `lib/core/navigation/app_nav.dart` → `NavTab { icon, activeIcon }` y
  `kPrimaryNavTabs` (los 4 tabs laterales) + `centerActionFor()` (ícono del
  botón central, dinámico por rol).
- `lib/core/widgets/floating_pill_nav_bar.dart` → `_NavItem` (tabs) y
  `_CenterButton` (acción central). **Aquí** se renderizan hoy con
  `AnimatedSwitcher` outlined↔rounded.
- `lib/core/navigation/role_task.dart` + `lib/features/*/presentation/*_routes.dart`
  → `RoleTask { icon, label, route, accent }` (acciones por rol).
- `lib/features/home/presentation/widgets/big_action_tile.dart` y
  `hero_task_card.dart` → tarjetas grandes que muestran `RoleTask.icon`.
- Estados: repartidos en pantallas (`check_circle`, `error`, `schedule`,
  `cloud_done`, `qr_code_scanner`, etc.).

---

## 3. Arquitectura de la solución (contrato único)

Crear UN widget que toda la app use en lugar de `Icon(Icons.x)`:

```dart
// lib/core/icons/animated_app_icon.dart
/// Ícono animado custom de DisTrack. Abstrae el backend (Rive / Lottie /
/// pintado en Dart): el resto de la app solo pide un AppIcon + estado.
enum AppIcon { home, tasks, alerts, profile, /* centro por rol */ deliver,
  scan, receive, pickupStore, dashboard, route, myDay, checklist, load, gps,
  incident, vehicleSummary, fuel, orders, settle, fleet, plans, roleAlerts,
  /* estados */ success, error, pending, syncing, offlineDone, printing,
  capture, locating, ... }

enum AppIconState { idle, active, pressed, loading, success, error }

class AnimatedAppIcon extends StatelessWidget {
  const AnimatedAppIcon(this.icon, {
    this.state = AppIconState.idle,
    this.size = 24,
    this.color,          // null => hereda del tema (IconTheme/ColorScheme)
    this.semanticLabel,  // accesibilidad obligatoria
    super.key,
  });
  // ...
}
```

Reglas del contrato:
- **El color por defecto se hereda del tema** (nunca hardcodear salvo acento).
- `state` dispara la animación (ver §5). El mismo widget sirve para Rive, Lottie
  o Flutter puro: adentro elige la implementación por `icon`.
- `semanticLabel` **obligatorio** (lectores de pantalla + QA). Texto en español.
- Respetar **reduce motion**: si `MediaQuery.disableAnimations` (o
  `accessibleNavigation`) está activo, mostrar el estado final sin animar.
- Tap target mínimo 48×48 dp aunque el dibujo sea 24 (lo da el contenedor, no el
  ícono, pero no romperlo).

### Formato y carpetas
- Rive: `assets/icons/rive/<nombre>.riv` — una state machine `Icon` con inputs:
  `active` (bool), `pressed` (trigger), `loading` (bool), `success` (trigger),
  `error` (trigger), y un input de color si el runtime lo permite (si no, tintar
  por `ColorFilter`/tema del contenedor).
- Lottie: `assets/icons/lottie/<nombre>.json` — segmentos marcados (markers) o
  rangos de frames documentados por estado; tintar con `LottieDelegates`.
- Flutter puro: `lib/core/icons/painters/<nombre>_painter.dart`
  (`CustomPainter` + `AnimationController`), o `AnimatedSwitcher` entre dos
  glifos.
- Registrar los paths en `pubspec.yaml > flutter > assets`.
- **Peso objetivo:** ≤ 20 KB por `.riv`, ≤ 30 KB por `.json`. Flutter puro = 0 KB.
- Nombre en inglés, kebab-case para assets, `camelCase` en el enum.

---

## 4. Inventario COMPLETO de íconos (qué es, para qué, cómo animarlo)

Clasificación: **HERO** = Rive/Lottie, animación rica. **ESTADO** = Flutter puro,
micro-animación funcional. **UTIL** = estático o micro-tap, baja prioridad.

### 4.1 Navegación — barra inferior flotante (HERO, prioridad máxima)
La barra tiene 4 tabs laterales + 1 botón central. El activo cambia de
outlined→filled hoy; reemplazar por animación custom.

| AppIcon | Material hoy | Qué es / para qué | Animación "en acción" |
| --- | --- | --- | --- |
| `home` | `home_outlined` / `home_rounded` | Pestaña **Inicio** (panel glanceable del rol). | Al seleccionar: el techo se dibuja y el relleno "baja" dentro de la casa; idle quieto. Deseleccionar: se vacía. |
| `tasks` | `grid_view_outlined` / `grid_view_rounded` | Pestaña **Tareas** (todas las acciones del rol en grilla). | Al seleccionar: las 4 celdas aparecen en secuencia (pop escalonado 40 ms). |
| `alerts` | `notifications_outlined` / `notifications_rounded` | Pestaña **Avisos** (bandeja de notificaciones). | Badge con no leídos: campana hace swing corto + punto rojo (acento) aparece. Al seleccionar: campana se asienta. |
| `profile` | `person_outline_rounded` / `person_rounded` | Pestaña **Perfil** (ajustes, seguridad/2FA, sesión). | Al seleccionar: hombros/cabeza se rellenan de abajo hacia arriba. |
| **centro** | dinámico por rol (ver 4.2 accent) | **Botón central** = acción estrella del rol (`centerActionFor`). Es una pestaña más, no un link. | El más vistoso. Reposo: respiración muy sutil (scale 1.0↔1.02, 2.5 s) para invitar al toque. Tap: la metáfora del rol "ejecuta" (ver cada accent abajo). |

> El ícono central **cambia según el rol logueado**. No hardcodear: lo resuelve
> `centerActionFor(role, tasks)`. Hay que animar las 5 variantes (una por rol).

### 4.2 Acciones por rol — `RoleTask` (HERO las `accent`, media el resto)
Se muestran en el botón central (si `accent`), en la tarjeta héroe del Inicio y
en los tiles grandes de "Tareas". Columnas: ícono actual · label (UI) · ruta ·
`accent` (estrella del rol).

**Chofer (driver)**
| AppIcon | Material | Label (UI) | Ruta | ¿accent? | Animación |
| --- | --- | --- | --- | --- | --- |
| `deliver` | `local_shipping` | Entrega en curso | `/driver/delivery` | sí (hero) | El camión avanza un tramo y "deja" un paquete; al éxito, check sobre la caja. |
| `route` | `map` | Mi ruta de hoy | `/driver/route` | no | Pin cae sobre el mapa y la línea de ruta se traza. |
| `myDay` | `today` | Mi día | `/driver/my-day` | no | Hoja de calendario con tilde que se dibuja. |
| `checklist` | `checklist` | Checklist pre-salida | `/driver/checklist` | no | Ítems se tildan en secuencia. |
| `load` | `upload` | Carga del camión | `/driver/load` | no | Flecha/caja sube hacia el camión. |
| `gps` | `my_location` | Rastreo del camión | `/driver/gps` | no | Anillo de "locating" pulsa y se fija (punto sólido). |
| `incident` | `report` | Reportar incidente | `/driver/incident` | no | Triángulo/bocadillo con "!" que parpadea 1 vez (ámbar, no rojo). |
| `vehicleSummary` | `insights` | Resumen del vehículo | `/driver/summary` | no | Barras/línea que crecen. |
| `fuel` | `local_gas_station` | Cargar combustible | `/driver/fuel` | no | Surtidor con gota que cae; aguja sube. |

**Preparador (picker)**
| `orders` | `list_alt` | Pedidos por preparar | `/picking/orders` | no | Renglones de lista que aparecen; tilde al final. |
| `scan` | `qr_code_scanner` | Ingresar pedido | `/picking/prepare` | sí (hero) | **Láser** barre el marco del QR (loop mientras escanea) → morph a check al leer. |

**Tienda (store)**
| `receive` | `inventory_2` | Recepción de mercadería | `/store/reception` | sí (hero) | Caja que se "sella"/tilda; tapa que baja. |
| `pickupStore` | `storefront` | Recojo en tienda | `/store/pickup` | no | Toldo de tienda que se despliega. |

**Transportista (carrier)**
| `scan`/`pickupScan` | `upload_file` | Escanear al recoger | `/carrier/pickup` | sí (hero) | Documento con flecha hacia arriba + barrido de escaneo. |
| `deliverScan` | `task_alt` | Escanear al entregar | `/carrier/deliver` | no | Círculo con tilde que se dibuja. |
| `settle` | `receipt_long` | Mis liquidaciones | `/carrier/settlements` | no | Recibo que se "imprime" (se despliega hacia abajo). |

**Supervisor (supervisor)**
| `dashboard` | `dashboard` | Tablero del día | `/supervisor/dashboard` | sí (hero) | Mosaicos del tablero que entran en secuencia. |
| `fleet` | `map` | Flota en vivo | `/supervisor/fleet` | no | Pines de camiones que laten sobre el mapa. |
| `plans` | `alt_route` | Rutas en curso | `/supervisor/plans` | no | Rutas alternativas que se trazan. |
| `roleAlerts` | `notification_important` | Alertas | `/supervisor/alerts` | no | Campana con "!" (ámbar) que vibra 1 vez. |

> Admin: ve tareas de varios roles (mismo set, sin íconos nuevos).

### 4.3 Estados y feedback (ESTADO — Flutter puro, micro-animación)
Son los que más se repiten en la operación; priorizar legibilidad sobre "show".

| AppIcon | Material (todas las variantes vistas) | Qué comunica | Animación |
| --- | --- | --- | --- |
| `scan` | `qr_code_scanner`(×16) `qr_code_2` `qr_code` | Escanear bulto/pedido/QR. | Láser que barre en loop mientras la cámara está activa; se apaga al leer. |
| `success` | `check_circle`(×9) `check`(×5) `task_alt`(×4) `done_all` `check_circle_outline` `verified`(×4) `verified_user_outlined` | Éxito: escaneo/entrega/guardado OK. | Tilde que se **dibuja** (stroke) + pop de escala 1.0→1.15→1.0. |
| `error` | `error`(×3) `error_outline`(×3) `cancel`(×3) `cancel_outlined` `block` `report`(×2) `report_gmailerrorred`(×2) `report_problem_outlined` `report_outlined` `warning_amber_rounded` `car_crash_outlined` `assignment_late_outlined` | Error/rechazo/incidente. | Shake horizontal corto (±3 px, 250 ms) + pulso de color **ámbar** (reservar rojo solo a lo crítico irreversible). |
| `pending` | `schedule`(×8) `timer_outlined` `hourglass_bottom` `pending_actions` `event_available` `today` `calendar_today` | Pendiente / en horario / tiempo. | Manecilla del reloj que gira 1 vuelta suave, o arena del reloj que cae. |
| `syncing` | `sync` `autorenew` `restart_alt` `cloud_done`(×3) `cloud_off` `wifi` `wifi_off` `done_all` | Cola offline / sincronización / conectividad. | Nube con flechas que giran MIENTRAS sincroniza → tilde al terminar. **Sutil** (offline-invisible: no debe parecer que hay que esperar). |
| `locating` | `my_location`(×3) `gps_fixed`(×2) `gps_not_fixed` `gps_off` `location_on` `location_on_outlined` `location_off`(×2) `place`(×4) `pin_drop`(×2) `navigation`(×4) `navigation_outlined` | GPS/ubicación/navegación del camión. | Anillo que pulsa (buscando) → punto sólido + anillo fijo (fijado). Flecha de navegación que gira al cambiar rumbo. |
| `printing` | `print`(×4) | Imprimir etiqueta ZPL (Zebra). | Hoja que se desliza saliendo de la impresora (loop mientras imprime). |
| `capture` | `photo_camera`(×2) `camera_alt`(×2) `cameraswitch` `image_outlined` `broken_image_outlined` | Foto de evidencia (POD, incidente). | Flash de obturador (destello + "parpadeo" del marco) al disparar. |
| `signature` | `draw` `edit_note` `gesture`(si aplica) | Firma del cliente (POD). | Trazo de firma que se dibuja. |
| `security` | `lock_outline`(×4) `shield_outlined` `verified_user_outlined` `badge_outlined` | 2FA / seguridad / sesión. | Candado que se cierra (gancho que baja) al verificar. |
| `power`/`action` | `bolt` `flash_on`(×2) `play_circle_outline` | Acción rápida / "ejecutar". | Rayo que "carga" y destella 1 vez. |
| `alertLive` | `notifications_active` `notification_important` `notifications_none` `notifications_off`/`_outlined` | Alerta viva (supervisor) / silenciada. | Campana que vibra 1 vez al llegar; cruz que aparece al silenciar. |

### 4.4 Utilitarios / navegación interna (UTIL — estático o micro-tap)
Baja prioridad: mantener nítidos, con a lo sumo una micro-reacción al tocar
(scale 0.9 en press). NO invertir esfuerzo de animación rica aquí.

`chevron_right`(×9) `arrow_forward`(×2) `arrow_forward_rounded` `expand_more`
`close`(×2) `add`(×2) `remove` `search` `settings`(×2) `logout`(×3) `refresh`(×6,
girar al refrescar) `call`(×2) `phone` `phone_android`/`_iphone` `smartphone`
`mail_outline` `send` `support_agent` `handshake` `build`(×2, llave que gira)
`savings`(×2) `payments`/`_outlined` `price_change_outlined` `receipt_long`(×5)
`inventory`/`inventory_2_outlined`(×4) `store` `storefront`(×5) `supervisor_account`
`account_circle` `person_outline`(×2) `person_off`/`_outlined` `devices`(×2)
`devices_other` `computer` `lan` `usb` `bluetooth` `settings_ethernet` `wifi`(×2)
`system_update` `download`(×2) `upload_file`(×2) `save`(×2) `copy_outlined`(×2)
`delete_outline`(×2) `visibility_outlined`(×3)/`visibility_off_outlined`(×3,
ojo que parpadea al togglear password) `pin_outlined`(×3) `keyboard` `list`/`list_alt`
`fact_check_outlined` `playlist_add_check`(×2) `new_label` `label_off` `flag`
`swap_horiz` `zoom_out_map` `wb_sunny_outlined`(×2) `vibration` `speed`(×5,
aguja que sube) `insights` `dashboard` `alt_route`(×6) `route`(×3) `map_outlined`(×2)
`outbound_outlined` `radio_button_unchecked` `timer_outlined` `hourglass_bottom`.

> Si un `Icons.*` de arriba no aparece en §4.1–4.3, trátalo como UTIL: ícono
> custom estático en el estilo DisTrack + micro-press, sin estado animado.

---

## 5. Especificación de animación "en acción"

**Taxonomía de triggers (mapear a `AppIconState`):**
1. **pressed** (tap down): scale 0.9 + opacidad 0.9, 80 ms — feedback inmediato.
   Aplica a TODOS (incluido UTIL).
2. **active/selected** (tabs, tile activo): transición outlined→filled con la
   metáfora del ícono (ver §4). 200–300 ms.
3. **loading** (mientras una acción corre): loop sutil (escaneo, sync, print,
   locating). Debe poder cortarse al instante cuando cambia el estado.
4. **success**: tilde dibujado + pop. 400–500 ms, una sola vez.
5. **error**: shake + pulso ámbar. 250–400 ms, una sola vez.
6. **idle/ambient**: solo el botón central respira sutilmente; el resto, quieto.

**Presupuesto y curvas:**
- Duración micro-interacción: 150–300 ms. Feedback de éxito/error: ≤ 500 ms.
- Easing: `Curves.easeOutCubic` para entradas, `easeInOut` para loops.
- 60 fps en gama baja. Nada de loops infinitos salvo estado real (scan/sync).
- **Legibilidad para mayores:** movimiento claro y lento, sin rebotes exagerados
  ni partículas. El ícono debe ser reconocible en CUALQUIER frame (si pausás la
  animación en cualquier punto, se entiende qué es).
- **Reduce motion:** `MediaQuery.of(context).disableAnimations == true` →
  saltar a estado final sin animar.

**Color/tema:**
- Estado normal: tinta del tema (`colorScheme.onSurface` claro / claro en dark).
- Activo: acento de marca según contexto (tinta o `#E30613` solo donde hoy el
  diseño usa acento; **no** teñir todo de rojo).
- Error: **ámbar `#FFB000`** por defecto; rojo `#E30613` solo en error crítico
  irreversible. Éxito: verde del `ColorScheme` o tinta (seguir el tema actual).

---

## 6. Wiring (cómo meterlo sin romper nada)

1. Crear `lib/core/icons/animated_app_icon.dart` (contrato §3) + el `enum AppIcon`
   + un mapa `AppIcon → implementación`.
2. **Navegación:** en `floating_pill_nav_bar.dart`, reemplazar el
   `AnimatedSwitcher`/`Icon` de `_NavItem` y `_CenterButton` por
   `AnimatedAppIcon(appIconForTab(tab), state: selected ? active : idle)`. Mapear
   cada `NavTab`/acción central a un `AppIcon`. NO cambiar la API de `NavTab`
   (sigue teniendo `icon`/`activeIcon` Material como fallback).
3. **RoleTask:** agregar un getter opcional `AppIcon? appIcon` a `RoleTask` (o un
   mapa `route → AppIcon`) para que `BigActionTile`/`HeroTaskCard` usen
   `AnimatedAppIcon` cuando exista, y caigan al `IconData` Material si no.
4. **Estados:** reemplazar los `Icon(Icons.check_circle...)` etc. por
   `AnimatedAppIcon(AppIcon.success, state: ...)` en los puntos de feedback
   (escaneo, guardado, POD, sync, GPS, impresión).
5. **Fallback:** mientras un ícono custom no exista, `AnimatedAppIcon` debe
   renderizar el `Icons.*` Material equivalente. Así se migra incremental sin
   romper pantallas.
6. **Assets:** declarar en `pubspec.yaml`. Si se usa Rive, agregar el paquete
   `rive` (versión pinneada).

---

## 7. División del trabajo (método de agentes en paralelo)

Carpetas/áreas disjuntas, un agente por lote; el coordinador cablea al final
(ver memoria `parallel-agents-method`). Contrato común: todos entregan `AppIcon`
nuevos detrás de `AnimatedAppIcon`, con fallback Material, sin tocar los otros
lotes.

- **Agente A — Navegación (HERO):** 4 tabs + botón central (5 variantes de rol).
  Entrega `floating_pill_nav_bar.dart` cableado.
- **Agente B — Acciones de rol (HERO/media):** los `RoleTask` de §4.2 (Rive/Lottie
  para `accent`, resto media). No toca navegación.
- **Agente C — Estados/feedback (Flutter puro):** §4.3 (scan, success, error,
  pending, syncing, locating, printing, capture, security). CustomPainters.
- **Agente D (opcional) — Utilitarios:** §4.4 estáticos + micro-press.
- **Coordinador:** define `AnimatedAppIcon` + `enum AppIcon` PRIMERO (para que
  todos programen contra el mismo contrato), registra assets en `pubspec.yaml`,
  y al final verifica `flutter analyze` limpio + `flutter test` verde.

---

## 8. Checklist de "terminado" (por ícono y global)

Por ícono:
- [ ] Legible y reconocible a 24 dp y a 28–32 dp (botón central), en claro y dark.
- [ ] Hereda color del tema (o usa acento solo donde corresponde; rojo neutralizado).
- [ ] Anima en el/los `AppIconState` que le toca; estado final claro sin animar.
- [ ] Respeta reduce-motion (salta a final).
- [ ] `semanticLabel` en español.
- [ ] Peso dentro del presupuesto (≤20 KB .riv / ≤30 KB .json / 0 KB Flutter puro).
- [ ] Sin jank en gama baja; loops cortables al instante.

Global:
- [ ] `AnimatedAppIcon` con fallback Material para íconos aún no migrados.
- [ ] `flutter analyze` sin issues · `flutter test` verde (reportar números).
- [ ] `dart format lib test` aplicado.
- [ ] Assets declarados en `pubspec.yaml`; `rive` pinneado si se usó.
- [ ] No se rompió la navegación, el botón central sigue siendo pestaña (no link),
      y la barra sigue adaptándose por rol.

---

### Apéndice — archivos clave para leer antes de empezar
- `lib/core/navigation/app_nav.dart` (NavTab, kPrimaryNavTabs, centerActionFor)
- `lib/core/widgets/floating_pill_nav_bar.dart` (render de tabs y botón central)
- `lib/core/navigation/role_task.dart` + `lib/features/*/presentation/*_routes.dart`
- `lib/features/home/presentation/widgets/big_action_tile.dart`, `hero_task_card.dart`
- `lib/core/brand/` (paleta, logo) y memoria `distrack-rebrand`
- `lib/core/theme/app_theme.dart` (ColorScheme claro/oscuro, para tintar)
- El splash Lottie ya integrado como referencia de pipeline de animación.
