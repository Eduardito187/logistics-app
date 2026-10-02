# Guía para agentes — logistics-app (app interna Flutter)

App interna de la plataforma logística Dismac. Una sola app con vista según el rol del login:
chofer, preparador/andén, tienda, transportista externo y supervisor. No es la app de clientes.

Visión, decisiones y ADRs viven en el repo backend: https://github.com/Eduardito187/logistics
(`docs/vision.md`, `docs/architecture.md`, `docs/adr/`).

## Cómo correr cosas

SDK: Flutter stable en `~/sdk/flutter` (WSL).

- Dependencias: `flutter pub get`
- Análisis: `flutter analyze`
- Tests: `flutter test`
- Formato: `dart format lib test`

En WSL no hay Android SDK: compilar el APK se hace desde Windows/Android Studio o en CI.
`flutter analyze` y `flutter test` sí corren en WSL.

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
