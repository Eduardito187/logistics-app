# Dismac Logística — app interna

App Flutter de uso interno de la plataforma logística Dismac. Una sola app con vista según el rol:
chofer, preparador/andén, tienda, transportista externo y supervisor.

- Backend, visión y decisiones: [`logistics`](https://github.com/Eduardito187/logistics)
- Arquitectura de la app: [`docs/architecture.md`](docs/architecture.md)

## Requisitos

- Flutter stable (probado con 3.47.6). En WSL: `~/sdk/flutter`.
- Para compilar el APK: Android SDK (Android Studio en Windows) o el CI.

## Comandos

```bash
flutter pub get
flutter analyze
flutter test
dart format lib test
```

Correr contra el backend local (docker compose del repo `logistics`) desde el emulador:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8110/api/v1 --dart-define=LABEL_PUBLIC_KEYS=1:<clave-publica-base64>
```

La clave pública se obtiene en el backend con `php artisan logistics:labels:keygen`.

## Qué hay hoy

| Pieza | Estado |
| --- | --- |
| Navegación con redirección por sesión (go_router + Riverpod) | Listo |
| Login (entrada de desarrollo por rol en builds debug) | Listo; login real pendiente del endpoint de auth |
| Pantalla de inicio por rol con sus flujos planificados | Listo |
| Verificación offline de etiquetas QR firmadas (Ed25519) | Listo, verificado contra el vector del backend |
| Escaneo, impresión Zebra, ruta, POD, base local offline | Pendiente (Fase 1) |

## Contrato de etiquetas

`test/fixtures/label_test_vector.json` es una copia exacta del vector del backend
(`packages/logistics/labels/tests/Fixtures/label-test-vector.json`). Si el backend lo regenera,
se copia acá y los tests de `test/core/labels/` tienen que seguir pasando.
