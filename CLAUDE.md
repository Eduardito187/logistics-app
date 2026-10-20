# Guía para agentes — logistics-app (app interna Flutter)

App interna de la plataforma logística Dismac. Una sola app con vista según el rol del login:
chofer, preparador/andén, tienda, transportista externo y supervisor. No es la app de clientes.

Visión, decisiones y ADRs viven en el repo backend: https://github.com/Eduardito187/logistics
(`docs/vision.md`, `docs/architecture.md`, `docs/adr/`).

## Cómo correr cosas

SDK: Flutter 3.47.6 (Dart ^3.13.5). En Windows: `C:\sdk\flutter` (NO `C:\flutter`, que es 3.32 y
lo usa `dismac-app`). VS Code y `android/local.properties` ya apuntan ahí. Antes en WSL: `~/sdk/flutter`.

- Dependencias: `flutter pub get`
- Análisis: `flutter analyze`
- Tests: `flutter test`
- Formato: `dart format lib test`

En Windows el toolchain Android es nativo (SDK en `%LOCALAPPDATA%\Android\Sdk`, JDK 21 en
`~\jdk21`): `flutter run` / `flutter build apk` funcionan directo. Los scripts `scripts/*.sh` y
`docs/run-usb.md` (usbipd) son solo para WSL.

## Estructura

```
lib/
├── main.dart / app.dart     # arranque, ProviderScope, MaterialApp.router
├── core/                    # transversal: config, auth/roles, router, theme, labels, network
└── features/<feature>/      # una carpeta por flujo: auth, home, picking, loading, route...
    ├── data/                # repositorios, DTOs, fuentes locales/remotas
    ├── domain/              # modelos y reglas propias del feature
    └── presentation/        # pantallas y widgets
```

## Reglas

1. Terminado = `flutter analyze` sin issues + `flutter test` verde. Reportar números.
2. No hacer `git commit` ni `git push` sin que el usuario lo pida en ese turno.
3. UI en español (la usan choferes y personal de tienda). Código en inglés, comentarios en español.
4. Offline-first: un escaneo nunca espera a la red. Se guarda local con ID idempotente y se sincroniza.
5. El cliente de la API se genera desde `openapi/v1.yaml` del backend; no escribir DTOs de la API a mano.
6. Botones grandes y flujos mínimos: se usa con guantes, bajo el sol y con una mano.
7. Estado con Riverpod (Notifier); navegación con go_router.

## Etiquetas QR

`lib/core/labels/` replica la verificación Ed25519 del backend. El mensaje canónico debe ser idéntico
byte a byte a `LabelPayload::canonical()` del backend. `test/fixtures/label_test_vector.json` es una
copia exacta del vector del backend; si el backend lo regenera, se copia acá.

## Portabilidad (al mover/clonar el proyecto, incl. a Windows nativo)

Las **skills** (`.claude/skills/`) viajan con el repo y funcionan en cualquier OS. Las **memorias** de
Claude Code NO viajan (viven en `~/.claude/projects/<slug>/memory/`, con el slug ligado a la ruta). Por
eso hay un espejo versionado en `.claude/memory/` con un instalador: tras clonar o mover el proyecto,
correr **una vez** `.\.claude\memory\install.ps1` (Windows) o `bash .claude/memory/install.sh`
(Linux/WSL/macOS) para dejarlas disponibles. Detalle en `.claude/memory/README.md`.
