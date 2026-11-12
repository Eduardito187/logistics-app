---
name: wifi-printer-discovery
description: "Impresoras WiFi: búsqueda tipo Windows (máscara real/22, mDNS, WS-Discovery, redes extra, No-Zebra, diagnóstico). Oficina: Zebra ZPL/9100, o Ricoh/láser por PDF DIRECTO sobre 9100 con código de usuario (texto claro). Cómo diagnosticar una Ricoh desde la PC."
metadata:
  node_type: memory
  type: project
  originSessionId: 9a85d4dc-6dee-4d1d-8426-868a6db4e45d
  modified: 2026-11-11T20:41:16.347Z
---

Nov 2026, pedido del dueño ("que lea las impresoras de la red como la PC"). Todo Dart puro + canales nativos propios, SIN paquetes de pub nuevos. Doc: `docs/impresion-oficina.md`, `docs/pedido-sistemas-ricoh.md`.

## Búsqueda de impresoras (Ajustes → Impresora → WiFi)

`lib/core/printing/wifi_printer_scanner.dart` (`wifiPrinterScannerProvider`), 4 caminos en paralelo, dedupe por `ip:puerto` (`WifiPrinterHit.merge`: nombre mDNS gana al `<title>` web), Zebra primero:
1. **Barrido con máscara real**: `NetworkInfoChannel` (canal nativo `bo.com.dismac/network`, método `interfaces` → `[{name,ip,prefixLength}]`; sin canal → `dart:io`+/24). `LocalNetwork`: ≥/22 barre completa, /16-/20 solo el /22 de la IP propia. Concurrencia 96, probe 700 ms. `ipv4.dart`/`ipv4_subnet.dart`.
2. **Redes agregadas** por el usuario (`extraNetworksProvider`, `ExtraNetworkInput.parse`): "192.168.2"→/24, tope /22, solo privadas. UI `WifiExtraNetworks`.
3. **mDNS/Bonjour** (mismo canal, `discoverServices`): `_pdl-datastream._tcp`/`_printer._tcp`/`_ipp._tcp`, 4 s.
4. **WS-Discovery** (`ws_discovery.dart` Dart puro): Probe SOAP a 239.255.255.250:3702.
- **Nunca manda bytes al 9100 al buscar** (abrir/cerrar socket). Búsqueda solo a pedido, autoDispose cancela al salir.
- **No-Zebra**: hit con nombre y no-Zebra → pastilla "No es Zebra" + `NonZebraPrinterDialog` (imprimiría ZPL como texto).
- **Probar conexión**: `scanner.diagnose()` → `PrinterReachability` por errno (refused/noRoute/timeout). Si la IP no está en ninguna red del teléfono, lo avisa.
- **Guardar avisa siempre** (`PrinterSection._save` → `PrinterSaveResult`): guardada / ya estaba activa / error.
- iOS: `NSLocalNetworkUsageDescription` + `NSBonjourServices` en Info.plist.

## UI (queja del dueño: "tantos inputs, no intuitivo")

Tarjeta de Ajustes = SOLO la impresora activa (ícono, nombre, "Zebra · WiFi · IP", pastilla Lista/No responde) + "Imprimir prueba" y "Cambiar"; sin impresora → "Conectar impresora". Asistente `printer_setup_screen.dart` en 3 pasos de UNA decisión (Bluetooth/WiFi/USB → elegir → Listo). Todo lo técnico (tipo, protocolo, dominio, código, redes, Olvidar) en "Opciones avanzadas" colapsado (`PrinterAccessSection`). `LabelPrinter.selectedKey` público.

## Impresión de oficina (Ricoh/láser, no Zebra)

**Credenciales por impresora** (Android 10+/iOS NO dejan leer el usuario del WiFi/dominio): `PrinterCredentials {username,password?,userCode?,domain?,secureToken?}` (`toString` sin secretos) en `PrinterCredentialsStore` (clave `printer_credentials_<ip:puerto>` en secure storage). Perfil en `PrinterConfig`: `language` (zpl|office), `protocol` (raw9100|ipp).

**DOS caminos** (`OfficePrinter`):
- **IPP** (`lib/core/printing/ipp/`): codec RFC 8010 a mano, `IppClient` (Get-Printer-Attributes/Print-Job, 631 luego HTTPS; 401/0x0402/0x0403 → Basic/Digest MD5 propio). **Transporte socket crudo** (HTTP/1.1 propio), NO `HttpClient` (su política "solo HTTPS" de release bloquea `http://` a la LAN). `IppClient.trackJob` sigue el trabajo tras aceptarlo (Get-Job-Attributes) → `PrintOutcome.printed(9)/held(4)/accepted` o excepción con motivo. "Aceptado" NUNCA se muestra como éxito.
- **9100 (raw)**: **PDF DIRECTO**, no PCL. `PdfDirectJobWriter` = cabecera `OfficePjl` + `@PJL ENTER LANGUAGE=PDF` + `PdfImageWriter` (PDF 1.4 A4, imagen gris Flate). Las MFP modernas (Ricoh/HP/Xerox/Canon) soportan PDF Direct Print.

**Dibujo de la etiqueta fuera de pantalla**: `render/offscreen_widget_renderer.dart` (`renderWidgetToRaster`), `printableLabelRenderer` (4"×6", sin foto). `LabelPrinter.printLabel({zpl, render, jobName, to}) → PrintOutcome`.

## CLAVE: cómo imprime la Ricoh del dueño (RESUELTO, verificado en equipo)

Ricoh IM 550 en 192.168.2.154. Config del driver del dueño: **Tipo de trabajo "Impresión bloqueada" + Código de usuario 2468**. El error "sale en blanco" / "no imprime" se resolvió así:

1. **IPP CANCELA en esa Ricoh** (`uri-authentication-supported = requesting-user-name`; todo trabajo IPP → `job-canceled-at-device`). → Para Ricoh, la app usa **9100**, no IPP: `PrinterProfileDetector` detecta Ricoh (`looksLikeRicoh`) + `wantsUserName` + !requiresCredentials → `raw9100`+`needsUserCode`. Además `OfficePrinter`: si un trabajo IPP da `cancelledAtDevice` y hay código de usuario → reintenta solo por 9100 (cubre configs viejas en IPP).
2. **El código de usuario viaja en TEXTO CLARO** (`@PJL SET USERCODE="2468"` + `BILLINGCODE`). Con eso **imprime directo** (no hace falta token). El operario solo carga su código en avanzado.
3. **El PCL5 crudo salía EN BLANCO** (el driver real usa PCLXL). **PDF directo por 9100 SÍ imprime con contenido** → `PdfDirectJobWriter`.
4. **"Impresión bloqueada"** (opcional): `@PJL SECUREJOB` + `@PJL SET JOBPASSWORD5="<base64 16B>"` (FIJO entre trabajos → se copia opaco en `secureToken`, NO se descifra). El dueño NO lo necesita (usercode directo alcanza). La contraseña Windows/LDAP SÍ se cifra con algoritmo propietario del driver → NO replicable (solo IPP Basic o que sistemas lo habilite).

## Diagnóstico de una Ricoh desde la PC (solo lectura + 1 captura)

Scripts en el scratchpad de la sesión (borrar las capturas al terminar: tienen el código del usuario):
- **IPP de solo lectura** (PC en la red de la impresora): Get-Printer-Attributes / Get-Jobs / Get-Job-Attributes vía socket a `:631` con `application/ipp`. Muestra `uri-authentication-supported`, `document-format-supported` y el estado final de cada trabajo (`job-canceled-at-device`, etc.). Ojo: la Ricoh devuelve nombres como `nameWithLanguage` (tag 0x36) con bytes de idioma → no confundir con bug del codec.
- **Capturar la salida REAL del driver**: `System.Drawing.Printing.PrintDocument` con `PrinterSettings.PrintToFile=$true` + `PrintFileName` → genera el `.prn` con la cabecera PJL exacta SIN imprimir papel. Así se vio `SECUREJOB/USERID/USERCODE/JOBPASSWORD5`.
- **Reenviar al 9100** (`TcpClient` a `:9100`) un `.prn` o un PDF envuelto en PJL para probar qué imprime. El 9100 NO confirma → lo verifica el dueño en el panel.
- **NUNCA** poner el token/credencial real en el repo o tests (el clasificador lo bloquea = correcto; usar placeholder). Leer el registro de credenciales de Windows también se bloquea (bien).

## Tests

NINGÚN test imprime real: `OfficePrinter` con `raw` falso, IPP a `127.0.0.1` (HttpServer local), `labelPrinterProvider`/`wifiPrinterScannerProvider` overrideados, `FakeLabelPrinter` en e2e. Verificado.
