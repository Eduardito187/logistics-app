# Widgets de pantalla de inicio — iOS (WidgetKit)

Seis widgets que muestran el día de trabajo sin abrir la app. Viven en la **misma extensión**
`RouteLiveActivity` que la Live Activity de la ruta (un solo target en Xcode; ver
[live-updates.md](live-updates.md) para crear ese target). No se puede compilar iOS en Windows: todo
lo de Xcode se hace en una Mac.

| Kind (Dart = WidgetKit) | Nombre en la galería | Familias | Payload (además de `state`, `updatedAt`, `route`) |
|---|---|---|---|
| `next_delivery` | Próxima entrega | small, medium, lock rectangular, lock circular | `stopIndex`, `stopCount`, `customer`, `etaText`, `progress` (0..1), `address`, `lat`, `lng` |
| `route_day` | Mi ruta de hoy | small, medium | `delivered`, `pending`, `failed`, `total` |
| `picking_pending` | Por preparar | small, medium (Link "Escanear") | `pending`, `inProgress`, `scanRoute` |
| `store_receptions` | Mi tienda | small, medium | `incoming`, `pickups` |
| `supervisor_summary` | Resumen del día | small, medium | `delivered`, `incidents`, `trucksOnRoute` |
| `quick_scan` | Escanear | small, lock circular | — |

`state`: `ok` · `signedOut` ("Iniciá sesión en DisTrack") · `notAllowed` ("No disponible para tu
rol") · `empty` (texto amable por widget). Pie "Actualizado HH:mm" desde `updatedAt` (epoch ms).

## Cómo fluye

```
Dart (lib/core/home_widgets/) ──MethodChannel "bo.com.dismac/widgets"──▶ Runner/WidgetsChannel.swift
   "update" {kind, payload} → UserDefaults(suiteName: "group.bo.com.dismac.logisticsApp")
                              clave "widget.<kind>" = JSON (Data) → WidgetCenter.reloadTimelines(ofKind:)
   "clearAll"               → cada kind = {"state":"signedOut"} → reloadAllTimelines()
   "isSupported"            → {"pinSupported": false}   "setEnabledKinds" → nil   "requestPin" → false

RouteLiveActivity/HomeWidgets/*.swift ──lee──▶ mismo App Group (WidgetData.swift → WidgetStore)
```

- Timelines con `policy: .never`: el widget **no** se despierta solo (batería). Solo se redibuja
  cuando la app manda datos. Sin datos todavía → se muestra "Iniciá sesión en DisTrack".
- Toque: `distrack://open?route=<ruta urlencoded>` → `WidgetsChannel.handle(url:)` →
  `AppShortcutsChannel.deliver(route:)` (mismo camino que los accesos del ícono: en frío queda
  pendiente hasta `consumeLaunchShortcut`; en caliente va por `launch`).
- Botón **Navegar** (medium de Próxima entrega): `distrack://navigate?daddr=lat,lng`. Un `Link` de
  widget siempre abre la app contenedora, por eso la app reenvía a `maps://?daddr=lat,lng` (Apple Maps).
- Los `Link` solo funcionan en medium/large; en small y pantalla bloqueada todo el widget es un toque.
- La galería de iOS muestra los 6 widgets a todos los roles (no se puede filtrar):
  `setEnabledKinds` es no-op y cada widget muestra "No disponible para tu rol" si no corresponde.

## Archivos

- `ios/Runner/WidgetsChannel.swift` — canal + `handle(url:)` (ya en el target Runner en el pbxproj).
- `ios/Runner/AppShortcutsChannel.swift` — `deliver(route:)` público (lo usan accesos y widgets).
- `ios/RouteLiveActivity/HomeWidgets/WidgetData.swift` — lector del App Group, proveedor de
  timeline, deep links, colores de marca y vistas compartidas.
- `ios/RouteLiveActivity/HomeWidgets/{NextDelivery,RouteDay,PickingPending,StoreReceptions,SupervisorSummary,QuickScan}Widget.swift`
- `ios/RouteLiveActivity/RouteLiveActivityBundle.swift` — Live Activity + 6 widgets.
- `ios/Runner/Runner.entitlements` y `ios/RouteLiveActivity/RouteLiveActivity.entitlements` — App
  Group `group.bo.com.dismac.logisticsApp`.

## Cableado del coordinador (AppDelegate / Info.plist)

`ios/Runner/AppDelegate.swift`, dentro de la clase `AppDelegate`:

```swift
  /// Deep link de los widgets de inicio (distrack://open?route=…, distrack://navigate?daddr=…).
  /// Lo que no es distrack:// sigue a super (plugins).
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if WidgetsChannel.handle(url: url) { return true }
    return super.application(app, open: url, options: options)
  }
```

`ios/Runner/Info.plist`, dentro del `<dict>` raíz:

```xml
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeRole</key>
			<string>Viewer</string>
			<key>CFBundleURLName</key>
			<string>bo.com.dismac.logisticsApp.widgets</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>distrack</string>
			</array>
		</dict>
	</array>
```

No poner `FlutterDeepLinkingEnabled = YES`: go_router recibiría `distrack://open?…` como ruta.

## Xcode (en una Mac), después de crear el target RouteLiveActivity (live-updates.md)

1. **Archivos de los widgets.** Arrastrar la carpeta `ios/RouteLiveActivity/HomeWidgets/` al grupo
   `RouteLiveActivity` del navegador: ✘ *Copy items if needed*, *Create groups*, Target Membership
   **solo ✔ RouteLiveActivity** (✘ Runner). Son 7 `.swift`. Verificar en *RouteLiveActivity → Build
   Phases → Compile Sources* que estén los 7 + `RouteLiveActivityBundle.swift`,
   `RouteLiveActivityWidget.swift` y `RouteActivityAttributes.swift`.
2. **`WidgetsChannel.swift`** ya está en el target Runner (pbxproj). Si Xcode lo muestra en rojo,
   *File inspector → Location* → `Runner/WidgetsChannel.swift`.
3. **App Groups en Runner.** *Runner → Signing & Capabilities → + Capability → App Groups* → ✔
   `group.bo.com.dismac.logisticsApp` (si no existe, **+** y crearlo con ese nombre exacto). Xcode
   reutiliza `Runner/Runner.entitlements` (ya trae la clave); no debe crear otro archivo.
4. **App Groups en la extensión.** *RouteLiveActivity → Signing & Capabilities → + Capability → App
   Groups* → ✔ el mismo grupo. Luego en *Build Settings* (Debug, Release y Profile):
   `CODE_SIGN_ENTITLEMENTS = RouteLiveActivity/RouteLiveActivity.entitlements`. Si Xcode generó un
   `RouteLiveActivityExtension.entitlements` propio, borrarlo (*Move to Trash*) y dejar el versionado.
5. **Portal de Apple / perfiles.** Los App IDs `bo.com.dismac.logisticsApp` y
   `bo.com.dismac.logisticsApp.RouteLiveActivity` deben tener la capability *App Groups* con el grupo
   asignado; regenerar los perfiles de aprovisionamiento (con *Automatically manage signing* lo hace
   Xcode). Sin esto, `UserDefaults(suiteName:)` devuelve un contenedor vacío y los widgets quedan
   en "Iniciá sesión en DisTrack".
6. **Info.plist / AppDelegate**: aplicar el cableado de arriba.
7. Compilar con el esquema **Runner**: `flutter build ios --release --dart-define-from-file=config/staging.json`.
   Para depurar un widget: esquema **RouteLiveActivity** → *Run* → elegir el widget.

## Qué probar (dispositivo real, iOS 16.1+; ideal también uno con iOS 17+)

1. Sin sesión: agregar cada widget desde la galería (mantener presionado el inicio → **+** →
   DisTrack) → muestran "Iniciá sesión en DisTrack" (la galería muestra datos de muestra).
2. Login chofer con ruta → "Próxima entrega" small: `3/7`, "Llega 08:15", barra roja, "Actualizado
   HH:mm". Medium: cliente, dirección y **Navegar** → abre la app y enseguida Apple Maps con el destino.
3. Registrar una entrega en la app → el widget cambia a la parada siguiente (sin esperar).
4. Pantalla bloqueada (iOS 16+): *Personalizar* → agregar Próxima entrega rectangular ("3/7 · 08:15")
   y circular (gauge) y Escanear circular.
5. Toque en cada widget con la app **cerrada** y con la app **en segundo plano** → abre la pantalla
   del `route` (una sola vez). "Escanear" (Por preparar medium / Escanear small) → abre el escáner.
6. Login preparador → "Próxima entrega" y "Mi ruta de hoy" dicen "No disponible para tu rol"; "Por
   preparar" muestra los conteos. Igual con tienda y supervisor en sus widgets.
7. Cerrar sesión → todos pasan a "Iniciá sesión en DisTrack".
8. iOS 17+: ningún widget muestra "Please adopt containerBackground API"; en iOS 16 el contenido
   tiene margen (no pegado al borde).
9. Batería: los widgets no se actualizan solos (policy `.never`); en *Ajustes → Batería* la extensión
   no debe aparecer con consumo propio relevante.
