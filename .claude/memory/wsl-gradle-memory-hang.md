---
name: wsl-gradle-memory-hang
description: Las builds de Gradle colgaron WSL al 100% ~20 min (nada respondía ni en cmd/PowerShell); causa fue heap 8G + builds apiladas. Topes puestos; nunca apilar builds pesadas.
metadata:
  node_type: memory
  type: feedback
  originSessionId: b09fb122-a063-448a-9f98-c86b13899a10
  modified: 2026-10-16T05:07:02.639Z
---

El 2026-10-14 una build colgó **todo el equipo** ~20 min (VmmemWSL ~15 GB, CPU 100%, ningún comando WSL respondía ni desde cmd/PowerShell admin). El dueño lo marcó como **crítico** y quedó muy molesto.

**Why:** dos causas combinadas — (1) `android/gradle.properties` tenía `-Xmx8G -XX:MaxMetaspaceSize=4G` → un solo Gradle podía pedir ~12 GB en un WSL de ~15 GB; (2) yo había lanzado **varias `flutter run` en background que se apilaron** compitiendo por RAM, más el NDK compilando. Se saturó swap y se colgó Windows entero.

**How to apply:**
- Dejar `org.gradle.jvmargs=-Xmx2G -XX:MaxMetaspaceSize=1G` (ya está). Nunca volver a subirlo a varios GB.
- `.wslconfig` (`C:\Users\ehhuallata\.wslconfig`) limita WSL a `memory=10GB` + `swap=6GB` + `processors=4`. Aplica tras `wsl --shutdown`.
- **Una sola build a la vez.** Antes de lanzar otra, matar la anterior. No apilar `flutter run`/`flutter build` en background.
- En builds largas, correr con un **vigilante de memoria** que haga `pkill -9 gradle/java` si `MemAvailable` baja de ~700 MB.
- Si WSL se cuelga: `pkill -9 -f gradle; pkill -9 java; pkill -9 -f build_runner; pkill -9 dart` libera la RAM sin matar la extensión Dart de VS Code. En último caso `wsl --shutdown` desde Windows.

**Optimización de RAM (2026-10-16):** VmmemWSL llegó a ~11 GB en reposo. Culpables y fixes:
- **Daemons de Gradle/Kotlin huérfanos** tras cada build (~1.6 GB + ~0.5 GB, quedan reparentados a `/init`). Fix permanente en `android/gradle.properties`: `org.gradle.daemon=false` + `kotlin.compiler.execution.strategy=in-process` + `org.gradle.caching=false` (el build cache además rompe en el FS de WSL con "Could not get file mode"). Matar los vivos: `pkill -9 java`.
- **Extensiones PHP de VS Code** (`devsense.php.ls` ~1.3 GB, `intelliphp`) corriendo en el workspace Flutter: **se re-lanzan solas** si solo se matan. Fix real: deshabilitarlas en el workspace (Extensiones → DEVSENSE → Disable Workspace).
- **VmmemWSL no baja aunque Linux libere RAM**: WSL2 no la devuelve a Windows solo. Agregado `[experimental] autoMemoryReclaim=gradual` en `.wslconfig`. El número en Windows solo baja de verdad con `wsl --shutdown` (aplica cap + reclaim; también desconecta el teléfono usbipd).

Ver [[wsl-run-toolchain]].
