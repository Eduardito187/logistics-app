---
name: wear-os-data-layer
description: "nov 2026 — DECISIÓN FIRME del dueño: NUNCA una app de reloj (ni tiles/widgets propios, ni módulo :wear). En el reloj SOLO la NOTIFICACIÓN espejada del teléfono (WearMirror), que el reloj dibuja en su estilo. Los tiles exigen app instalada = prohibido."
metadata:
  node_type: memory
  type: project
  originSessionId: 9a85d4dc-6dee-4d1d-8426-868a6db4e45d
  modified: 2026-11-17T05:17:59.796Z
---

**DECISIÓN FIRME Y REPETIDA del dueño (nov 2026): NO quiere una app de reloj.** Lo dijo varias veces
("no toda la app fea en modo circular/cuadrado", "quería compartir algunas pantallas no toda la app",
"es un asco"). Me equivoqué DOS veces construyendo un módulo `:wear` (tile + Data Layer) y hasta lo
instalé en su Galaxy Watch → lo odió. **Se eliminó TODO**: borrado `android/wear/`, `include(":wear")`,
`WearBridge.kt`, `WearChannel.kt`, `lib/core/watch/wear_link.dart`, la dep `play-services-wearable`, y
desinstalado del reloj. NO REINTRODUCIR nada de eso.

**Realidad técnica (por qué no hay punto medio):** en Wear OS, un **tile/widget con diseño propio
(circular/cuadrado) EXIGE una app instalada en el reloj**. NO existe "compartir una pantalla/widget" al
reloj sin instalar una app. La ÚNICA forma de mostrar algo en el reloj **sin instalar nada** es una
**notificación** del teléfono: el reloj la espeja y la dibuja en SU estilo (circular/cuadrado) por su
cuenta. No se puede personalizar su diseño. Si el dueño alguna vez pide un tile con diseño propio, hay que
decirle EXPLÍCITO que eso = instalar una app de reloj (lo que rechaza), y que la alternativa sin app es la
notificación.

**Lo que SÍ queda (único camino aceptado): `WearMirror.kt` (teléfono).** Postea una notificación NORMAL
(no-ongoing) con la parada en curso ("Parada N de M" + cliente), que el reloj espeja como las de WhatsApp.
- Por qué una notif aparte: la de la ruta es de **foreground service (ongoing)** y los relojes NO espejan
  las ongoing; la isla es un overlay del teléfono (nunca viaja). WearMirror es no-ongoing + no local-only +
  alerta ≥1 vez (una totalmente silenciosa puede filtrarse) + `setOnlyAlertOnce` para no re-sonar en cada
  update. Se postea en `LiveUpdatesChannel.show()` (automático, solo chofer con ruta) y se quita en `end()`.
- Requiere: reloj emparejado al teléfono (Galaxy Wearable) + en el reloj permitir notifs de DisTrack +
  "Notificaciones mientras se usa el teléfono" ON. Eso NO lo fuerza la app (es ajuste del reloj). El dueño
  confirmó que con eso la notificación SÍ llega.

**Conectar un Galaxy Watch por adb (histórico, por si hace falta para otra cosa, NO para instalar apps):**
el puerto de VINCULAR ≠ el de CONECTAR. Tras `adb pair <ip:portVincular> <codigo>`, descubrir el real por
mDNS: `ADB_MDNS_OPENSCREEN=1 adb mdns services | awk '/_adb-tls-connect/{print $NF}'` → `adb connect`.
`scripts/adb-wireless.sh pair` ya lo autodetecta. JDK del proyecto: `~/jdk21/jdk-21.0.12.1+1` (JAVA_HOME).

Ver [[owner-decisions-are-final]], [[product-ux-decisions]], [[driver-map-nav-cadence-batch]].
