---
name: api-client-generation
description: Cómo se regenera el cliente Dart del API (swagger_parser) y los gotchas que hacen fallar la generación.
metadata:
  node_type: memory
  type: reference
  originSessionId: 09382079-47de-4656-9b51-88ca4bb40fff
  modified: 2026-10-15T06:42:27.742Z
---

El cliente del API vive en `lib/core/api/` y se **genera** (regla #5, nunca DTOs a mano) desde `openapi/v1.yaml` (copia del backend `/dismac/logistics/openapi/v1.yaml`). Pipeline en `scripts/regen_api_client.sh` + `scripts/preprocess_openapi.py`; `Makefile` target `gen`.

**Gotchas que SÍ o SÍ hay que aplicar (sin esto, falla):**
1. `swagger_parser` tropieza con los **anchors YAML** (`*id001`) y con `parameters` a **nivel de path**. Por eso el preprocesado Python: carga el YAML (expande anchors), inyecta los `parameters` de path en cada operación, y escribe `openapi/v1.json`; `swagger_parser.yaml` apunta a ese `.json`.
2. El generado usa **retrofit**: fijar par compatible `retrofit: ^4.10.0` + `retrofit_generator: ^10.2.12` (versiones viejas rompen por el enum `Parser.DartMappable` y por analyzer/_macros).
3. `analysis_options.yaml` excluye `lib/core/api/**`, `**/*.g.dart`, `**/*.freezed.dart` (el generado tira warnings `unnecessary_cast`).
4. Tras `dart run swagger_parser` correr `dart run build_runner build --delete-conflicting-outputs`. El generado NO está en formato canónico de `dart format`; correr `dart format lib` antes de validar con `--set-exit-if-changed` (CI).

**Forma de uso:** `ref.read(logisticsApiProvider)` → `api.<module>.<operationId>(...)`; respuestas envuelven el payload en `.data`; errores `on DioException catch(e){ throw ApiException.fromDio(e); }`. Si el backend cambia el spec, re-copiar + regenerar. Ver [[app-api-coverage-state]].

**En Windows con Flutter 3.32 / Dart 3.8 (desde 2026-10-16):** el backend vive en WSL: `\\wsl.localhost\Ubuntu-22.04\dismac\logistics\openapi\v1.yaml` (puede tener cambios sin push; GitHub `Eduardito187/logistics` puede ir atrasado). La Python de Windows no tiene PyYAML → preprocesar con `wsl.exe -d Ubuntu-22.04 -- python3 -I /mnt/c/.../scripts/preprocess_openapi.py <yaml> <json>`. `dart run swagger_parser` funciona; después `dart format lib/core/api` (sin eso todo aparece como cambiado). **`retrofit_generator` NO compila con Dart 3.8**: ninguna versión ≤10.2.5 contempla `Parser.DartMappable` y ≥10.2.6 exige Dart 3.9. Si el cambio del spec es solo de modelos: quitar temporalmente `retrofit_generator` del pubspec, correr `build_runner build`, restaurar pubspec/lock y hacer `git checkout -- lib/core/api/clients/` (build_runner borra los `.g.dart` de los clientes). Si cambian endpoints, hay que generar con un Flutter ≥3.35 (Dart 3.9).

**Regenerar con endpoints nuevos (probado 2026-10-16):** generar en una COPIA con el Flutter 3.47 que quedó en `C:\sdk\flutter` (Dart 3.13, donde `retrofit_generator ^10.2.12` sí compila): carpeta temporal con `openapi/`, `swagger_parser.yaml`, `analysis_options.yaml`, `third_party/` y el pubspec/lock de Dart 3.13 (respaldo en el scratchpad `backup-dart313/`), `pub get` + `dart run swagger_parser` + parche `MetaSealed?` + `build_runner build`, y copiar SOLO `lib/core/api` al proyecto; luego `C:\flutter\bin\dart format lib/core/api` y `flutter analyze` con 3.32 (el código generado compila en Dart 3.8). Trampa: swagger_parser numera los objetos anónimos (`Data4`, `Data6`, `Data21`…) y un endpoint nuevo CORRE la numeración → renombrar las referencias de la app/tests (y los imports `models/dataN.dart`) comparando campos viejo vs nuevo.
