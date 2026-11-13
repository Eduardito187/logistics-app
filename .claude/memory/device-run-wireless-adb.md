---
name: device-run-wireless-adb
description: "Correr/instalar la app en teléfono físico por ADB inalámbrico desde WSL, con puente al backend de la PC; trampas de puertos y conexión."
metadata:
  node_type: memory
  type: project
  originSessionId: 09382079-47de-4656-9b51-88ca4bb40fff
  modified: 2026-11-13T14:54:18.882Z
---

El 2026-10-21 se dejó funcionando **instalar y correr la app en un teléfono físico por ADB INALÁMBRICO desde WSL** (sin cable, sin usbipd), accesible desde VS Code. Teléfono de prueba: **Honor Magic 5 Lite 5G**. Esto complementa el flujo USB de [[wsl-run-toolchain]].

**Montaje (una vez):**
- Copiar las llaves adb de Windows a WSL (`/mnt/c/Users/<user>/.android/adbkey{,.pub}` → `~/.android/`) para que el teléfono ya confíe en el adb de WSL y **no haya que re-emparejar** (igual que con el emulador).
- Activar mDNS openscreen: `export ADB_MDNS_OPENSCREEN=1` → `adb mdns services` lista los dispositivos emparejados que se anuncian, y `adb connect` reconecta solo.
- Emparejar un dispositivo nuevo: en el teléfono, **Depuración inalámbrica → Vincular con código** da un `IP:puerto` + código de 6 dígitos → `adb pair <ip>:<puerto_pairing> <codigo>`. El puerto de **pairing** es distinto del de **connect**.
- Scripts: `scripts/adb-wireless.sh` (WSL) y `scripts/adb-wireless.ps1` (Windows) con subcomandos connect/reconnect/mdns/usb/pair; al conectar hacen `adb reverse tcp:8110 tcp:8110` solos. Tareas de VS Code en `.vscode/tasks.json` (WiFi connect/pair/reverse) y la config de play "dev" tiene `preLaunchTask` del puente reverse. Guía: `docs/run-wireless.md`.

**Puente al backend (Docker en la PC) — clave:** el teléfono NO llega a la IP LAN de la PC (`192.168.1.79`) por firewall / aislamiento de AP. La solución que funciona: `adb reverse tcp:8110 tcp:8110` (túnel teléfono→PC) + `config/dev.json` con `API_BASE_URL=http://localhost:8110/api/v1`. Como `localhost` en el teléfono sale por el reverse, no hace falta tocar firewall ni la IP LAN. El `network_security_config` (debug/profile) ya permite cleartext solo a `10.0.2.2`/`localhost`/`127.0.0.1`.

**Trampas (ya vistas):**
- Los **puertos de depuración inalámbrica ROTAN** en Honor/OnePlus cada vez que el teléfono duerme o reconecta. Una dirección vieja da `Connection refused`. Hay que releer el `IP:puerto` actual (toggle de Depuración inalámbrica) o dejar que mDNS lo reconecte.
- Si el teléfono duerme durante una build larga, la instalación falla con `adb: device offline` (la build del APK igual termina OK). Reconectar y reinstalar el APK ya construido (`adb install` / `flutter install`), **no** reconstruir.
- **Ojo con mDNS:** puede listar dispositivos de OTROS en la red (una vez apareció un TV box `H96Max_H313` en `_adb._tcp`). Verificar `model:`/`product:` en `adb devices -l` antes de instalar; nunca instalar a ciegas en lo primero que conecte.
- **Una sola conexión:** si el usuario ya conectó el teléfono, no reconectar ni re-emparejar sin que lo pida; solo instalar y correr.

**WINDOWS NATIVO (nov 2026, OnePlus CPH2749, serial 3C15B2000RZ00000).** Ahora se
trabaja en Windows, no WSL. Claves:
- **El adb de Windows está en `$HOME/AppData/Local/Android/Sdk/platform-tools/adb.exe`**
  (desde Git Bash). WSL y Windows tienen **servidores adb SEPARADOS** (WSL2 es NAT):
  conectar el teléfono en uno NO lo pone en el otro. Para leer la DB / instalar desde
  esta sesión (Bash = Git Bash de Windows) hay que conectar con el **adb.exe de
  Windows**, aunque la tarea de VS Code lo haya conectado en WSL. Como es por WiFi,
  ambos pueden conectar a la MISMA `ip:puerto` en paralelo sin problema.
- **VS Code en modo WSL-remoto** hace que sus tareas corran `bash` = WSL → usan el adb
  de WSL (`/home/.../Android/Sdk/platform-tools/adb`). El script ahora imprime qué adb
  usa (`Conectando a X (adb: ...)`). Si el dueño quiere Windows, debe abrir VS Code en
  ventana de Windows (no WSL-remoto).
- **`scripts/adb-wireless.sh` autodetecta el adb** (WSL `~/Android/Sdk` vs Windows
  `~/AppData/Local/Android/Sdk/...adb.exe` vs PATH) y tolera que falte `timeout`.
- **`tasks.json` en Windows:** pasar la ruta del script **RELATIVA** (`scripts/adb-wireless.sh`)
  + `options.cwd=${workspaceFolder}`, NO `${workspaceFolder}/scripts/...`: con `\` de
  Windows, PowerShell→bash se come las barras (`C:Usersehhuallata...: No such file`).
- **Puerto estable:** tras conectar por el puerto TLS (rota), fijar `adb -s <dev> tcpip 5555`
  + `adb connect ip:5555` → 5555 (TCP plano) sobrevive reinicios del adb server. Sacar la
  entrada `offline` vieja con `adb disconnect`.
- **Redes corporativas/invitado (p. ej. 10.168.50.x) BLOQUEAN mDNS** (multicast) → `adb
  mdns services` no lista nada; ahí hay que pasar el `ip:puerto` a mano del toggle. En
  casa (192.168.x) mDNS sí autodescubre.
- **Leer la DB Drift del teléfono SIN depender de sqlite CLI:** `adb -s <dev> exec-out
  run-as bo.com.dismac.logistics_app cat app_flutter/logistics_app.sqlite{,-wal,-shm} >
  local` (los 3 archivos; el **-wal tiene las últimas escrituras**) y leer con **Python
  stdlib** (`import sqlite3`) — tabla `outbox_actions` (cols `kind, payload, status,
  attempts, last_error, label`). El `last_error` es la respuesta CRUDA del backend. Ver
  [[pod-scanner-vehicle-hardening]] (ahora la app además MUESTRA ese error en pantalla,
  así que esto es último recurso).

Ver toolchain base [[wsl-run-toolchain]], Windows [[windows-native-toolchain]], topes de
memoria [[wsl-gradle-memory-hang]], y el peso del APK [[apk-size-split-abi]].
