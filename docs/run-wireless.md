# Correr DisTrack en un teléfono por WiFi (ADB inalámbrico)

El teléfono y la PC deben estar en la **misma red WiFi**. VS Code usa el Flutter de Windows
(`C:/flutter`), así que se usa el **adb de Windows** (el que alimenta la lista de dispositivos de
VS Code). Atajo: `scripts/adb-wireless.ps1` + tareas de VS Code (Terminal → Run Task).

## La primera vez: USB → WiFi (lo más confiable, 30 s)

1. Teléfono: Opciones de desarrollador → **Depuración por USB: ON**. Enchufá un **cable con datos**.
2. Al conectar, bajá la cortina de notificaciones y poné el USB en **"Transferir archivos"** (NO "Solo
   carga"), y aceptá el pop-up **"¿Permitir depuración USB?"** (marcá "Permitir siempre").
   - Verificá que la PC lo ve: Run Task → **adb: iniciar servidor de Windows (USB)** y luego
     `adb devices` debe listar un equipo en estado `device`.
3. Run Task → **adb WiFi: USB → WiFi (una vez)** (o `./scripts/adb-wireless.ps1 usb`). Pasa el teléfono
   a WiFi en el puerto **5555**, detecta su IP y conecta. Cuando diga "LISTO", **desenchufá el cable**.
4. Aparece en el selector de dispositivos de VS Code → F5 / `flutter run --dart-define-from-file=config/dev.json`.

El 5555 **no rota**: queda abierto hasta que reinicies el teléfono o apagues la WiFi.

## Las siguientes veces

- **Reconectar** (mismo teléfono, no reinició): Run Task → **adb WiFi: reconectar (último)**
  (o `./scripts/adb-wireless.ps1 reconnect`). Usa el último `ip:puerto` guardado.
- **Por ip:puerto**: Run Task → **adb WiFi: conectar (ip:puerto)**, pegás `192.168.1.42:5555`
  (o `./scripts/adb-wireless.ps1 connect 192.168.1.42:5555`).

## Vinculación por QR (Android 11+)

Android genera el QR del lado de la **PC** y el teléfono lo escanea; eso necesita un servicio mDNS de
"pairing" que hoy solo levanta **Android Studio** de forma confiable:
1. Android Studio → **Device Manager** → **Pair Devices Using Wi‑Fi** → pestaña **Pair with QR code**.
2. En el teléfono: Depuración inalámbrica → **Vincular dispositivo con código QR** → escaneá el QR.
3. Queda vinculado y conectado; VS Code (Windows Flutter) lo ve.
Después, para las próximas, alcanza con `reconnect` / `connect <ip:puerto>` (no hace falta re‑vincular).

> Vinculación por **código** (sin QR), si preferís CLI:
> `./scripts/adb-wireless.ps1 pair <ip:puertoVinculación> <código> <ip:puertoConexión>`
> El puerto de **vinculación** sale del diálogo "Vincular con código"; el de **conexión** es el de la
> pantalla principal de Depuración inalámbrica. En algunos equipos (p. ej. Honor/Magic OS) ese puerto
> **rota** al salir de la pantalla: por eso conviene el método USB→WiFi (5555 estable).

## Si no aparece por USB

Si `adb devices` y `usbipd list` no muestran el teléfono (solo periféricos), el teléfono **no está
enumerando como dispositivo de datos**: cable de solo carga, USB en "Solo carga", o depuración USB sin
aceptar. Cambiá el modo USB a "Transferir archivos", probá otro cable/puerto, y aceptá el pop-up.
