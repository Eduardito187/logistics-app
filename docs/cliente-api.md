# Cliente del API (`lib/core/api/`)

El cliente Dart del backend **se genera**; no se escribe a mano (regla #5 de `CLAUDE.md`). Sale del
contrato `openapi/v1.yaml` del repo backend (`logistics`) con
[swagger_parser](https://pub.dev/packages/swagger_parser) (Retrofit + json_serializable).

## TL;DR

```powershell
# 1. Probar sin tocar el proyecto (genera en %LOCALAPPDATA%\Temp\logistics-api-gen\... y muestra el diff)
.\scripts\regen_api_client.ps1 -DryRun

# 2. Aplicar (reemplaza lib/core/api/ y openapi/v1.{yaml,json})
.\scripts\regen_api_client.ps1

# 3. Validar con el Flutter del proyecto
C:\flutter\bin\flutter.bat analyze
C:\flutter\bin\flutter.bat test
```

Desde Git Bash, Linux o WSL: `bash scripts/regen_api_client.sh --dry-run` (mismas opciones:
`--spec <v1.yaml>`, `--out <dir>`, `--dry-run`, `--keep`). En Linux/WSL `make gen` llama al `.sh`.

| Parámetro (`.ps1`) | Default | Para qué |
|---|---|---|
| `-Spec` | `\\wsl.localhost\Ubuntu-22.04\dismac\logistics\openapi\v1.yaml` | spec del backend (el repo vive en WSL y puede tener cambios sin push) |
| `-DryRun` | – | genera en temporal y compara con `lib/core/api` (no toca el proyecto) |
| `-Out <dir>` | – | deja el resultado en `<dir>\lib\core\api` (no toca el proyecto) |
| `-GenFlutter` | `C:\sdk\flutter` | Flutter ≥ 3.35 (Dart ≥ 3.9) usado **solo para generar** |
| `-ProjectFlutter` | `C:\flutter` | Flutter 3.32 del proyecto, usado para `dart format` |
| `-WslDistro` | `Ubuntu-22.04` | Python de WSL con PyYAML si la de Windows no lo tiene |
| `-KeepWork` | – | no borra la carpeta temporal al aplicar |

## Qué hace el script (y por qué)

1. **Copia el spec** a una carpeta temporal. El proyecto no se toca hasta el final.
2. **Preprocesa YAML → JSON** con `scripts/preprocess_openapi.py`: swagger_parser falla con los
   anchors YAML (`*id001`) y con `parameters` a nivel de path. Usa la Python de Windows si tiene
   PyYAML; si no (caso actual), `wsl.exe -d Ubuntu-22.04 -e python3 -I ...` (`-I` = intérprete
   aislado).
3. **`pub get` con `tool/api_gen/`**: un pubspec **mínimo** versionado (`dio`, `json_annotation`,
   `retrofit`, `build_runner`, `json_serializable`, `retrofit_generator ^10.2.12`,
   `swagger_parser`; `sdk: ^3.13.5`) con su `pubspec.lock` (`--enforce-lockfile`). Motivo: la app
   está fijada a Flutter 3.32 / Dart 3.8 y **`retrofit_generator` no compila en Dart 3.8** (≤ 10.2.5
   no conoce `Parser.DartMappable`; ≥ 10.2.6 exige Dart 3.9). El código que genera **sí** compila en
   Dart 3.8. El `pubspec.yaml` del proyecto no se usa ni se modifica.
4. **`dart run swagger_parser`** (config `swagger_parser.yaml` de la raíz), **parche**
   `final MetaSealed meta;` → `final MetaSealed? meta;` (el generador lo deja no-nullable con
   constructor opcional y no compila; el arreglo de fondo es del backend) y
   **`dart run build_runner build`**.
5. **`dart format --language-version=3.8`** con el Dart del proyecto (`C:\flutter`). El formateador
   de 3.8 y el de 3.13 no producen lo mismo; CI corre `dart format --set-exit-if-changed` con 3.32.
6. **Revisa los tipos anónimos `DataN`** (ver abajo) y lista las referencias de `lib/` y `test/`
   fuera de `lib/core/api/` que haya que renombrar.
7. **Aplica** (borra y copia `lib/core/api/` + `openapi/v1.yaml` y `v1.json`) o, con
   `-DryRun`/`-Out`, deja el resultado aparte y muestra `git diff --no-index --stat`.

## Trampa: renumeración de `DataN`

swagger_parser nombra los objetos inline sin nombre del spec como `Data`, `Data2`…`Data28` (también
`MetaN`, `StatusN`, `ErrorN`, `TypeN`, `Items2/3`, `Load2`, `Stops2`, `Enum0`) **por orden de
aparición**. Un endpoint nuevo en el medio corre la numeración: lo que era `Data4` pasa a ser `Data5`
y el código de la app que lo usaba deja de compilar (o peor, compila con otro tipo).

El paso 6 compara la firma (campos `final Tipo nombre;`) de cada `DataN` viejo contra el nuevo e
imprime, por ejemplo:

```
AVISO: cambio la numeracion/contenido de: Data26
  Data26 { OrderSource source; Status8 status; String externalId } -> sin equivalente exacto (cambiaron los campos)
Ninguna referencia fuera de lib/core/api usa esos DataN.
```

Si un `DataN` sólo se movió, dice `-> ahora es DataM`; renombrar las referencias listadas (incluido
el import `models/dataN.dart`). Hoy la app usa `Data5` (checklist pre-viaje), `Data7` (ETA del
plan) y `Data22` (`AcceptedEnvelope`). El arreglo definitivo es que el backend **nombre esos
schemas** (pedido en `docs/backend-requests/2026-10-16-pendientes-consolidados.md`, punto 4).

## Verificación hecha (2026-10-16)

- `.\scripts\regen_api_client.ps1 -Spec .\openapi\v1.yaml -DryRun` → **idéntico** al
  `lib/core/api/` versionado (897 archivos, `diff -rq` sin diferencias). Mismo resultado con
  `bash scripts/regen_api_client.sh --spec openapi/v1.yaml --dry-run` desde Git Bash.
- Contra el spec actual del backend en WSL (trae el módulo *Sellers*, aún no consumido): 29 archivos
  nuevos/cambiados (`sellers_client`, modelos `seller*`, `status9`) y aviso de `Data26` (su `status`
  pasó de `Status8` a `Status9`); ninguna referencia de la app afectada. **No se aplicó.**

## Cómo se usa en la app

`ref.read(logisticsApiProvider)` → `api.<módulo>.<operationId>(...)`; las respuestas envuelven el
payload en `.data`; errores: `on DioException catch (e) { throw ApiException.fromDio(e); }`. El
generado está excluido del analyzer (`analysis_options.yaml`: `lib/core/api/**`, `**/*.g.dart`).

## Problemas conocidos

- **`Found duplicate object name: DataN`** en la salida de swagger_parser: es normal, así renumera.
- **`pub get` falla con `--enforce-lockfile`**: alguien cambió `tool/api_gen/pubspec.yaml` sin
  regenerar el lock. Correr `C:\sdk\flutter\bin\dart.bat pub get` dentro de `tool/api_gen/`, borrar
  su `.dart_tool/` y regenerar con `-DryRun` para ver si cambió la salida.
- **Subir versiones del generador** (`swagger_parser`, `retrofit_generator`, `json_serializable`)
  puede cambiar el código generado. Hacerlo en un cambio aparte y revisar el diff de `-DryRun`.
- **wslpath / WSL apagado**: el preprocesado necesita la distro `Ubuntu-22.04` con `python3-yaml`, o
  instalar PyYAML en la Python de Windows (`py -m pip install pyyaml`) y el script la usa sola.
- Si se borra `C:\sdk\flutter`, la generación con endpoints nuevos deja de funcionar: hace falta
  algún Flutter ≥ 3.35 en `-GenFlutter` (ver `docs/flutter-versiones.md`).
