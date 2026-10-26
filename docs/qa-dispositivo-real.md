# QA en dispositivo real

Checklist manual para aprobar una versión antes de entregarla a choferes y tiendas. Los tests
automáticos (`flutter test`, `integration_test/`, ver [e2e.md](e2e.md)) no reemplazan esto: acá se
prueba lo que solo existe en el teléfono (radio, GPS, cámara, Bluetooth/USB, batería, el sistema
matando la app).

## Equipos

| Equipo | Por qué | Mínimo |
|---|---|---|
| **Android Go de 1 GB** (p. ej. Android 11–13 Go, `armeabi-v7a`) | el peor caso de la flota: RAM, CPU y cámara justas | obligatorio |
| Android gama media (`arm64-v8a`, 3–4 GB) | el caso típico | obligatorio |
| **iPhone** (iOS 15+; idealmente uno viejo, p. ej. iPhone 8/SE 2) | supervisores y tiendas | obligatorio si se publica iOS |
| Impresora **Zebra** Bluetooth (ZQ/ZD con BT) y una por **USB OTG** | etiquetas del preparador | obligatorio |
| Teléfono del cliente con QR de confirmación (o impreso) | POD | obligatorio |

Anotar en cada corrida: modelo, versión de Android/iOS, ABI (`adb shell getprop ro.product.cpu.abi`),
RAM (`adb shell cat /proc/meminfo | head -1`), versión de la app y entorno (`dev`/`staging`/`production`).

## 0. Preparación

- [ ] APK **release por ABI** (no el debug, no el "fat APK"):
  ```bash
  make apk ENV=staging            # o: flutter build apk --release --split-per-abi --dart-define-from-file=config/staging.json
  # build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk  -> Android Go 1 GB (32 bits)
  # build/app/outputs/flutter-apk/app-arm64-v8a-release.apk    -> el resto
  adb install -r build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
  ```
- [ ] La ABI instalada coincide con la del equipo (un `arm64-v8a` en un Go de 32 bits no instala).
- [ ] Tamaño del APK anotado (referencia para la próxima versión; ver `docs/rendimiento-y-pantallas.md`).
- [ ] iPhone: build por TestFlight o `flutter build ipa` (ver `docs/ios.md`), con las credenciales de
      Firebase/APNs del entorno.
- [ ] Usuarios de prueba en el backend del entorno: uno por rol (chofer, preparador, tienda con
      tienda asignada, transportista, supervisor) y un admin sin rol de terreno.
- [ ] Datos en el backend: una ruta del día con ≥2 paradas para el chofer, un envío llegando a la
      tienda con ≥2 bultos etiquetados, un pedido por preparar con etiquetas emitidas.

## 1. Login y sesión

- [ ] Credenciales incorrectas → aviso "Usuario o contraseña incorrectos.", sigue en el login.
- [ ] Usuario sin rol de terreno (admin) → aviso y no entra.
- [ ] Cada rol entra a **su** inicio (tarjetas propias, ninguna de otro rol).
- [ ] Sin señal en el login → "No se pudo conectar con el servidor..." con "Reintentar".
- [ ] **Sesión persistente tras reinicio**: logueado → apagar y prender el teléfono (reinicio real,
      no solo cerrar la app) → abre directo en el inicio del rol, **sin pasar por el login y sin
      señal** (modo avión).
- [ ] Forzar detención (`adb shell am force-stop bo.com.dismac.logistics_app`) y abrir → sigue logueado.
- [ ] "Cerrar sesión" → vuelve al login; al reabrir la app sigue en el login.
- [ ] Token revocado desde el backend (o "Dispositivos" → revocar) → al primer request vuelve al login
      con "Tu sesión expiró, volvé a ingresar." una sola vez.

## 2. Push (requiere credenciales Firebase del entorno; ver `docs/push-fcm.md`)

- [ ] Ajustes → "Activar notificaciones" pide el permiso (Android 13+ / iOS) y queda activo.
- [ ] Notificación con la app **abierta** → se ve como notificación local (canal "Operación").
- [ ] Con la app **en segundo plano** y **cerrada** → llega; tocarla abre la bandeja.
- [ ] Topics por rol/tienda: un aviso a la tienda le llega solo a esa tienda.
- [ ] **Rotación de token push**:
  - [ ] Borrar datos de Google Play Services o reinstalar la app → el token cambia.
  - [ ] En el backend, el dispositivo queda con el token **nuevo** (acción `updateDevicePushToken`
        de la cola; sin señal se encola y sube al volver).
  - [ ] Un push enviado después llega al token nuevo; el viejo no recibe.
  - [ ] Cerrar sesión y entrar con otro usuario en el mismo teléfono → el usuario anterior ya no
        recibe pushes en este equipo.

## 3. Cámara: escaneo QR y código de barras

Probar en el **Go de 1 GB** y con luz de día (sol directo) y en un depósito con poca luz.

- [ ] QR de etiqueta firmada → bulto aceptado. QR adulterado → "Firma inválida...". QR de otra clave →
      "clave desconocida".
- [ ] EAN-13 de producto (preparador) y Code 128 (carril) se leen en < 2 s a 15–30 cm.
- [ ] 50 escaneos seguidos sin cerrar la pantalla: no se traba ni se cierra la app.
- [ ] Con guantes y una mano: los botones de escanear quedan al pie, a mano del pulgar.
- [ ] Minimizar la app con el escáner abierto y volver: la cámara se recupera (no queda negra).
- [ ] Llamada entrante durante el escaneo → al cortar, el escaneo sigue.
- [ ] Permiso de cámara denegado → mensaje claro y forma de ir a Ajustes.

## 4. Foto obligatoria

- [ ] POD sin foto: "Registrar entrega" deshabilitado aunque estén bulto y confirmación.
- [ ] Tomar foto → vista previa; "Volver a tomar" la reemplaza.
- [ ] Cancelar la cámara → sigue sin foto y sin registrar.
- [ ] En el Go de 1 GB la app **no se reinicia** al volver de la cámara. Si el sistema la mata,
      al volver debe seguir logueada; lo ya registrado no se pierde y la foto puede pedirse de nuevo.
- [ ] Foto con señal → sube; sin señal → se encola y sube al reconectar (ver pantalla de sync).
- [ ] La foto en el backend pesa < 400 KB (1600 px, calidad 70).
- [ ] Entrega fallida: motivo + foto se registran igual.

## 5. Impresión Zebra

### Bluetooth
- [ ] Emparejar la Zebra desde los Ajustes de Android; en la app → Ajustes → impresora → aparece y
      se selecciona.
- [ ] Preparador: "Escanear EAN e imprimir" imprime **una** etiqueta legible; el QR impreso se lee
      con la misma app (firma válida).
- [ ] "Imprimir todas las etiquetas" imprime el lote completo.
- [ ] Impresora apagada / fuera de alcance → aviso claro, la preparación queda registrada igual.
- [ ] Bluetooth del teléfono apagado → aviso claro (no se cierra la app).
- [ ] 30 etiquetas seguidas sin reconectar a mano.

### USB (OTG)
- [ ] Conectar la Zebra con cable OTG → Android pide permiso USB → aceptar → aparece en la lista.
- [ ] Imprime una etiqueta y el lote.
- [ ] Desconectar el cable a mitad → aviso claro; reconectar → vuelve a imprimir sin reiniciar la app.

## 6. GPS en segundo plano (1 hora)

- [ ] Primer uso del chofer: pide ubicación "Permitir siempre"; si se niega, la pantalla bloquea con
      "abrir ajustes" y no deja operar.
- [ ] Con una parada activa el rastreo arranca solo (notificación persistente del servicio).
- [ ] **1 hora** con la pantalla apagada y la app en segundo plano, moviéndose (auto o caminando):
  - [ ] En el backend/supervisor el camión se ve moverse durante toda la hora (sin cortes > 2 min).
  - [ ] ~1 posición cada ≥10 s y 20 m; no miles de puntos.
  - [ ] Ahorro de batería / "Optimización de batería" de Android activado: el rastreo **sigue**
        (si no, documentar el ajuste que hay que darle al equipo).
- [ ] Al terminar la ruta el rastreo se detiene y la notificación desaparece.
- [ ] Reiniciar el teléfono con la ruta en curso → al abrir la app el rastreo vuelve.

## 7. Un día sin señal y reconexión

Simular con modo avión (y Wi-Fi apagado) durante una jornada completa (o al menos 2–3 h de trabajo
real).

- [ ] Con modo avión: login ya hecho se mantiene; todas las pantallas de operación funcionan.
- [ ] Escanear bultos, POD con foto, recepción, preparación: el usuario ve **"Registrado."** igual que
      con señal (**cola invisible**: nunca aparece "sin conexión" ni errores de red).
- [ ] La pantalla de sincronización muestra lo pendiente (solo si se entra a buscarla).
- [ ] Cerrar y reabrir la app sin señal → lo pendiente **sigue** en la cola (no se pierde).
- [ ] Reiniciar el teléfono sin señal → lo pendiente sigue.
- [ ] Al volver la señal: aparece **"Sincronizando..."** una vez, la cola baja a 0 sola, sin tocar
      nada, y en el backend aparecen todas las acciones **una sola vez** (sin duplicados: misma
      `Idempotency-Key`).
- [ ] Las fotos encoladas suben después de las acciones y quedan ligadas a su envío.
- [ ] Señal intermitente (entrar y salir de modo avión varias veces durante la subida) → sin
      duplicados ni filas trabadas.
- [ ] Una acción rechazada por el backend (dato inválido, 4xx) queda como fallida en la pantalla de
      sync con su motivo y "Reintentar"; no bloquea al resto.

## 8. Memoria y batería

### RAM (Android)
```bash
PKG=bo.com.dismac.logistics_app
adb shell dumpsys meminfo $PKG | grep -E "TOTAL PSS|TOTAL RSS|Native Heap|Graphics|Java Heap"
# Muestreo cada 30 s durante un flujo (Git Bash / Linux):
while true; do date +%T; adb shell dumpsys meminfo $PKG | grep "TOTAL PSS"; sleep 30; done
```
Medir en el **Go de 1 GB**, en este orden, y anotar el `TOTAL PSS`:

| Momento | Objetivo (1 GB) |
|---|---|
| Inicio del rol en reposo | < 120 MB |
| Mapa de entrega en curso, 2 min paneando | < 220 MB |
| Escáner abierto, 50 escaneos | < 220 MB y no crece de forma sostenida |
| Tras 1 h de jornada (GPS + escaneos + fotos) | sin crecimiento sostenido (fuga) > 30 MB |

- [ ] Ver también si el sistema mata la app: `adb logcat -b events | grep am_kill` /
      `adb shell dumpsys activity processes | grep -i logistics`.
- [ ] iPhone: Xcode → Debug Navigator → Memory (o Instruments → Allocations) en los mismos momentos.

### Batería
```bash
adb shell dumpsys batterystats --reset        # al empezar la prueba de 1 h
# ... 1 h de jornada con GPS en segundo plano ...
adb shell dumpsys batterystats $PKG | grep -iE "Estimated power use|Uid .*: |wake lock|gps" | head -40
adb bugreport bugreport.zip                    # opcional: abrir en Battery Historian
```
- [ ] Consumo de la app en 1 h de jornada con GPS en segundo plano anotado (% de batería y mAh).
- [ ] Objetivo: **≤ 8 % por hora** en la gama media y ≤ 10 % en el Go (pantalla apagada salvo al operar).
- [ ] Sin wakelocks retenidos al terminar la ruta (rastreo detenido).

## 9. Varios

- [ ] Letra del sistema al máximo: nada se corta ni se superpone (la app limita a 1.3x).
- [ ] Rotar el teléfono / tablet en horizontal en cada pantalla de los 4 flujos.
- [ ] Modo oscuro del sistema: todo legible.
- [ ] Bajo el sol a pleno: contraste suficiente en botones y avisos.
- [ ] Botón atrás de Android en cada paso: no deja estados a medias (p. ej. POD a medio registrar).

## Criterios de aprobación

La versión **se aprueba** solo si:

1. Todos los ítems de las secciones **1, 3, 4, 7** pasan en el **Android Go de 1 GB** y en la gama
   media (y en iPhone si se publica iOS). Son bloqueantes: login/sesión, escaneo, foto obligatoria y
   offline.
2. **Ninguna pérdida ni duplicado** de datos en la prueba sin señal (sección 7): cantidad de acciones
   en el backend = cantidad registrada en el teléfono.
3. GPS en segundo plano (sección 6): cobertura ≥ 95 % de la hora sin huecos > 2 min.
4. Impresión (sección 5): Bluetooth y USB imprimen etiquetas cuyo QR verifica con la app.
5. Push (sección 2) funciona con las credenciales del entorno, incluida la rotación de token.
6. Memoria y batería (sección 8) dentro de los objetivos; ningún cierre por falta de memoria
   (`am_kill` / "La app se detuvo") durante la jornada.
7. Cero crashes en la jornada (Crashlytics del entorno sin eventos nuevos de esta versión).

Cualquier falla se registra con: equipo, versión, pasos, resultado esperado/obtenido y, si aplica,
`adb logcat -d > logcat.txt` y el `dumpsys meminfo` del momento. Un ítem no bloqueante (secciones 2,
5, 6, 8, 9) puede aprobarse con excepción documentada y fecha de corrección.
