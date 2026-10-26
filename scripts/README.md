# scripts/

Automatizaciones del app interna de logistica. Los `.ps1` son para Windows (Flutter 3.32 en
`C:\flutter`); los `.sh` corren en Git Bash, Linux o WSL (ver `CLAUDE.md`).

## Regenerar el cliente del API (`regen_api_client.ps1` / `.sh`)

Regla #5: los DTOs del API no se escriben a mano. Guia completa (por que cada paso, trampa de
renumeracion `DataN`, problemas conocidos): **`docs/cliente-api.md`**.

```powershell
.\scripts\regen_api_client.ps1 -DryRun   # genera aparte y muestra el diff (no toca el proyecto)
.\scripts\regen_api_client.ps1           # aplica: lib/core/api/ + openapi/v1.{yaml,json}
```

```bash
bash scripts/regen_api_client.sh --dry-run          # Git Bash (Windows), Linux o WSL
bash scripts/regen_api_client.sh --spec /ruta/v1.yaml
```

Genera en una carpeta temporal con el pubspec minimo de `tool/api_gen/` y el Dart 3.13 de
`C:\sdk\flutter` (retrofit_generator no corre en el Dart 3.8 del proyecto), formatea con
`C:\flutter` y avisa si se renumeraron los tipos anonimos `DataN`.

> El preprocesado se puede correr suelto (necesita PyYAML; en Windows usar la Python de WSL):
> `python3 -I scripts/preprocess_openapi.py openapi/v1.yaml openapi/v1.json`

## Revisar credenciales de `config/*.json` (`check-config.ps1`)

```powershell
.\scripts\check-config.ps1 [-Env production] [-AllowEmptyDev]
```

Lista que claves faltan, estan vacias o tienen formato invalido en cada entorno **sin imprimir
valores**. Sale con 1 si falta alguna requerida. De donde sale cada valor: `docs/firebase-setup.md`.

## Sincronizar el vector de etiquetas (`sync_label_vector.sh`)

El vector Ed25519 de prueba es compartido con el backend y debe ser identico byte a
byte (seccion "Etiquetas QR" de `CLAUDE.md`).

```bash
# Origen por defecto en el backend:
bash scripts/sync_label_vector.sh

# O apuntando a otra ruta:
bash scripts/sync_label_vector.sh /ruta/a/label-test-vector.json
```

Copia el vector a `test/fixtures/label_test_vector.json` y muestra el diff si cambio.
Despues de un cambio, corre `flutter test` para validar la verificacion Ed25519.

## Makefile (raiz del repo)

Atajos (en Linux/WSL usan el Flutter del PATH):

| Target         | Que hace                                                     |
| -------------- | ------------------------------------------------------------ |
| `make format`  | `dart format lib test`                                       |
| `make analyze` | `flutter analyze`                                            |
| `make test`    | `flutter test`                                               |
| `make gen`     | corre `scripts/regen_api_client.sh` (aplica al proyecto)     |
| `make ci`      | format check (`--set-exit-if-changed`) + analyze + test      |

`make ci` reproduce localmente lo que corre el workflow `.github/workflows/ci.yml`.
