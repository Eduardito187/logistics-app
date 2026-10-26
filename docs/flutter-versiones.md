# Versiones de Flutter

## Decisión vigente

**Un solo Flutter en la PC: 3.32.0 / Dart 3.8.0 en `C:\flutter`** (el mismo que usa `dismac-app`).
Decisión del dueño del proyecto (2026-10-16): no subir la app a una versión mayor sin que lo pida.

Consecuencias que ya están resueltas en el proyecto:

- `pubspec.yaml` con `sdk: ^3.8.0` y paquetes fijados a versiones compatibles con Dart 3.8.
- CI (`.github/workflows/ci.yml`) fijada a `flutter-version: 3.32.0`.
- `.vscode/settings.json` apunta a `C:/flutter`.
- `dart format` siempre con `C:\flutter` (el formateador de 3.13 produce otra salida y CI falla).
- No usar APIs de Flutter > 3.32 (p. ej. `DropdownButtonFormField(initialValue:)`, `RadioGroup`).

### Excepción: `C:\sdk\flutter` (3.47.6 / Dart 3.13.5)

Sigue instalado **sólo para generar el cliente del API**: `retrofit_generator ^10.2.12` exige
Dart ≥ 3.9. Lo usa `scripts/regen_api_client.ps1` sobre una carpeta temporal con el pubspec mínimo
de `tool/api_gen/`; nunca toca el `pubspec.yaml` ni el `.dart_tool/` del proyecto. No ponerlo en el
`PATH` ni abrir el proyecto con él (un `pub get` con 3.47 reescribe el `pubspec.lock` pidiendo
Dart ≥ 3.11 y rompe la build con 3.32). Ver `docs/cliente-api.md`.

## Opción recomendada a futuro: FVM

Si se vuelve a necesitar más de una versión (otra app con otro Flutter, o subir esta sin romper
`dismac-app`), lo recomendable es [FVM](https://fvm.app/) en lugar de varias carpetas a mano.
**No está instalado ni configurado**: esto es sólo la evaluación.

Cómo quedaría:

1. Instalar FVM (Windows: `choco install fvm` o `dart pub global activate fvm`).
2. En cada proyecto, fijar su versión: `fvm use 3.32.0` → crea `.fvmrc`
   (`{ "flutter": "3.32.0" }`) que **sí se versiona**, y el symlink `.fvm/flutter_sdk` (no se versiona:
   agregar `.fvm/` al `.gitignore`).
3. Comandos con `fvm flutter ...` / `fvm dart ...` (o el symlink en `.vscode/settings.json`:
   `"dart.flutterSdkPath": ".fvm/flutter_sdk"`).
4. CI: `subosito/flutter-action` puede leer la versión del `.fvmrc`
   (`flutter-version-file: .fvmrc`), así local y CI no se desincronizan.
5. El generador del API pasaría a `fvm spawn 3.47.6 dart run ...` (o `-GenFlutter` apuntando al SDK
   que FVM cachea en `%LOCALAPPDATA%\fvm\versions\3.47.6`).

| | Un Flutter global (hoy) | FVM con `.fvmrc` |
|---|---|---|
| Simplicidad | máxima: un `C:\flutter` | una herramienta más |
| Varias apps con versiones distintas | no (todas en 3.32) | sí, cada repo la suya |
| Versión declarada en el repo | sólo en CI y docs | `.fvmrc` (fuente única) |
| Generar el cliente API (Dart ≥ 3.9) | `C:\sdk\flutter` aparte | `fvm spawn` |
| Symlinks en Windows | – | requiere modo desarrollador o consola admin |

Recomendación: mantener el Flutter único mientras sea sólo esta app + `dismac-app` en 3.32. Pasar a
FVM cuando haga falta subir una de las dos sin la otra, o cuando se sume un tercer proyecto Flutter.
