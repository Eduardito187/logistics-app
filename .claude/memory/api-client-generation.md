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
