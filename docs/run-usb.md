# Correr la app en un teléfono Android por USB (WSL + VS Code)

Guía para compilar y correr la app interna de logística en un **teléfono Android físico**
conectado por USB, trabajando desde **VS Code en WSL**.

## Cómo funciona (contexto, ya está montado)

No hace falta instalar nada: esta máquina ya tiene todo el toolchain listo.

- Flutter stable en `~/sdk/flutter`.
- Toolchain Android dentro de WSL: JDK 17 en `~/jdk`, Android SDK en `~/Android/Sdk`
  (platform-tools, android-36, build-tools 36, NDK). `flutter doctor` da Android ✓.
- **WSL no ve el USB directamente.** El truco: el teléfono se conecta al servidor **adb de
  Windows** (que sí ve el USB) y el adb de WSL le habla por `localhost`. Funciona porque la red
  de WSL está en modo `mirrored` (comparte localhost) y el adb de Windows y el de WSL son la
  **misma versión** (1.0.41 / 37.0.1). Está configurado en `~/.bashrc` con:
  `export ADB_SERVER_SOCKET=tcp:127.0.0.1:5037`.
- El adb de Windows vive en:
  `/mnt/c/Users/ehhuallata/AppData/Local/Android/Sdk/platform-tools/adb.exe`.

> ⚠️ **Regla crítica: UNA build a la vez.** Una build de Gradle ya colgó WSL una vez por
> consumir demasiada RAM (varias builds apiladas). **No lances varios `flutter run` en
> paralelo.** El heap de Gradle está acotado en `android/gradle.properties` (`-Xmx2G`) y WSL
> está limitado en `.wslconfig` (memoria 10GB, 4 procesadores). Si igual se cuelga, mirá
> [Solución de problemas](#4-solución-de-problemas).

---

## 1. Preparar el teléfono (una sola vez)

Esto se hace una vez por teléfono. Las rutas exactas de menú varían según la marca, pero el
flujo es siempre el mismo:

1. **Activar el Modo desarrollador:** abrí **Ajustes → Acerca del teléfono** y tocá **7 veces**
   seguidas sobre **"Número de compilación"**. Aparece el aviso "Ya eres desarrollador".
2. **Activar la Depuración por USB:** andá a **Ajustes → Opciones de desarrollador** y activá
   **"Depuración por USB"**.
3. **Autorizar esta computadora:** enchufá el teléfono por USB. En la pantalla del teléfono
   aparece el diálogo **"¿Permitir depuración USB?"**. **Tildá "Permitir siempre desde esta
   computadora"** y aceptá.

> Si no tildás "Permitir siempre", te va a volver a preguntar cada vez que enchufes.

---

## 2. Correr la app

Enchufá el teléfono por USB y usá **cualquiera** de estas dos opciones.

### Opción A — Script lanzador (terminal)

Desde la raíz del proyecto:

```bash
scripts/run-usb.sh            # entorno dev (por defecto)
scripts/run-usb.sh staging    # entorno staging
scripts/run-usb.sh production # entorno production
```

El script arranca el servidor adb de Windows, espera a que aparezca el teléfono (si lo ve
`unauthorized`, te avisa que aceptes el diálogo en el teléfono) y corre:

```
flutter run -d <telefono> --dart-define-from-file=config/<env>.json
```

### Opción B — Botón de play en VS Code

En el panel **Run and Debug** (Ejecutar y depurar), elegí la configuración
**"logistics-app · USB (dev)"** y apretá el botón de **play** (▶).

Ambas opciones hacen lo mismo; usá la que te resulte más cómoda.

> **Nota sobre el endpoint en `dev`:** `config/dev.json` apunta a
> `http://10.0.2.2:8110/api/v1`. Ese `10.0.2.2` es el **alias del emulador** de Android para
> llegar a la PC, y **no funciona desde un teléfono físico**. Si estás apuntando al backend
> local de tu PC desde el teléfono por USB, probablemente tengas que ajustar `API_BASE_URL` a
> la **IP de la PC en la LAN** (por ejemplo `http://192.168.x.x:8110/api/v1`). Para `staging` y
> `production` esto no aplica.

---

## 3. Comandos útiles

```bash
# Ver el teléfono detectado por adb (vía servidor adb de Windows):
~/Android/Sdk/platform-tools/adb devices

# Ver los dispositivos que ve Flutter:
flutter devices
```

---

## 4. Solución de problemas

| Síntoma | Qué hacer |
| --- | --- |
| **El teléfono no aparece** | Revisá el cable (que sea de datos, no solo de carga) y que la **Depuración por USB** esté activada. Probá listar desde Windows: `/mnt/c/Users/ehhuallata/AppData/Local/Android/Sdk/platform-tools/adb.exe devices`. Si ahí tampoco aparece, el problema es del lado de Windows/USB, no de WSL. |
| **Aparece como `unauthorized`** | Mirá la pantalla del teléfono y **aceptá el diálogo "¿Permitir depuración USB?"** (tildá "Permitir siempre desde esta computadora"). |
| **Aparece como `offline`** | **Desenchufá y volvé a enchufar** el cable USB. |
| **WSL se cuelga / build trabada** | Recordá la regla: **una build a la vez**, nunca varios `flutter run` en paralelo. Para liberar WSL, matá los procesos colgados: `pkill -9 -f gradle; pkill -9 java`. Luego volvé a correr una sola build. |

> Si WSL quedó inestable después de un cuelgue, cerrá todo con `wsl --shutdown` desde Windows y
> reabrí la terminal / VS Code (esto reaplica los límites de `.wslconfig`).
