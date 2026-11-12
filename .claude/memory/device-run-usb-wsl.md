---
name: device-run-usb-wsl
description: "Correr en el OnePlus 15 (CPH2749) por USB desde WSL: usbipd se cae, el fix real es registrar el GUID de interfaz ADB en Windows + instalar/abrir con el adb de Windows (WSL es NAT)."
metadata:
  node_type: memory
  type: project
  originSessionId: 09382079-47de-4656-9b51-88ca4bb40fff
  modified: 2026-11-11T16:07:21.860Z
---

Nov 2026. El dueño insistió en **USB** (no inalámbrico) para compilar/correr en su **OnePlus 15
(CPH2749, VID:PID 22d9:2765)** desde WSL. Qué NO funciona y qué sí:

**usbipd passthrough SE CAE con este teléfono.** `usbipd attach --wsl --busid <n>` reporta éxito pero
dmesg muestra `Device attached` → inmediatamente `connection closed`/`disconnect device` (high-speed, el
socket USB/IP se cierra). usbipd 5.3.0 (la última), kernel WSL con vhci_hcd/usbip_core OK → igual se cae.
No perder tiempo acá. (Antes se usó WiFi, ver [[device-run-wireless-adb]], pero el dueño quería cable.)

**El picker de dispositivos de VS Code corre en WSL** → NUNCA muestra el teléfono USB (que está en
Windows); solo "Linux desktop". No es el indicador. El indicador real: `adb.exe devices` de Windows.

**El bug que lo ocultaba: usbipd le deja al "ADB Interface" (MI_01) WinUSB SIN el GUID de interfaz ADB.**
Tras compartir/liberar con usbipd, Windows reinstala winusb.inf genérico pero sin registrar el device
interface GUID que busca adb → `adb.exe devices` sale **vacío** (no "unauthorized", vacío). Fix (elevado,
una vez; persiste):
```
reg add "HKLM\SYSTEM\CurrentControlSet\Enum\USB\VID_22D9&PID_2765&MI_01\<instancia>\Device Parameters" \
  /v DeviceInterfaceGUIDs /t REG_MULTI_SZ /d "{F72FE0D4-CBCB-407d-8814-9ED673D0DD6B}" /f
# luego Disable-PnpDevice + Enable-PnpDevice de esa instancia
```
Antes de eso, si quedó "Shared" en usbipd y nadie lo usa: `usbipd unbind --busid <n>` (requiere **admin**,
salta UAC). Driver correcto esperado: `DEVPKEY_Device_Service = WINUSB`.

**WSL está en NAT** (`wslinfo --networking-mode` = nat), así que NO se puede puentear el server adb de
Windows a WSL sin exponerlo: `adb -a` (listen all-interfaces) lo bloquea el clasificador; `ADB_SERVER_SOCKET
=tcp:127.0.0.1:5037` solo sirve en **mirrored**. Por eso Flutter en WSL no puede manejar el teléfono directo.

**Ruta que SÍ funciona (install+run por cable):**
1. Compilar en WSL: `flutter build apk --profile --dart-define-from-file=config/<env>.json`
   (profile, NO release: release bloquea el http en claro de staging; ver [[run-environments-config]]).
2. Copiar el APK a un temp de Windows (evita problemas de UNC con adb.exe).
3. `adb.exe install -r -d <apk-windows>` + lanzar: `adb.exe shell monkey -p bo.com.dismac.logistics_app
   -c android.intent.category.LAUNCHER 1`. Paquete real: **`bo.com.dismac.logistics_app`** (MainActivity).
4. adb de Windows: `C:\Users\ehhuallata\AppData\Local\Android\Sdk\platform-tools\adb.exe`. Serial del
   teléfono: `3C15B2000RZ00000`.

**Caveats:** el teléfono se cae del USB si duerme / cable de solo-carga / modo "Solo carga" (poner
"Transferencia de archivos"). Al reconectar basta `adb kill-server && start-server`; el fix del GUID
persiste. Hot reload en vivo NO (requiere exponer puerto o pasar WSL a mirrored = `wsl --shutdown`).
Ver [[windows-native-toolchain]], [[git-push-from-wsl]].
