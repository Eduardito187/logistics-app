---
name: api-client-generation
description: Cómo se regenera el cliente Dart del API (swagger_parser) y los gotchas que hacen fallar la generación.
metadata:
  node_type: memory
  type: reference
  originSessionId: 09382079-47de-4656-9b51-88ca4bb40fff
  modified: 2026-11-05T09:44:49.272Z
---

El cliente del API vive en `lib/core/api/` y se **genera** (regla #5, nunca DTOs a mano) desde `openapi/v1.yaml` (copia del backend `/dismac/logistics/openapi/v1.yaml`). Pipeline en `scripts/regen_api_client.sh` + `scripts/preprocess_openapi.py`; `Makefile` target `gen`.

**Gotchas que SÍ o SÍ hay que aplicar (sin esto, falla):**
1. `swagger_parser` tropieza con los **anchors YAML** (`*id001`) y con `parameters` a **nivel de path**. Por eso el preprocesado Python: carga el YAML (expande anchors), inyecta los `parameters` de path en cada operación, y escribe `openapi/v1.json`; `swagger_parser.yaml` apunta a ese `.json`.
2. El generado usa **retrofit**: fijar par compatible `retrofit: ^4.10.0` + `retrofit_generator: ^10.2.12` (versiones viejas rompen por el enum `Parser.DartMappable` y por analyzer/_macros).
3. `analysis_options.yaml` excluye `lib/core/api/**`, `**/*.g.dart`, `**/*.freezed.dart` (el generado tira warnings `unnecessary_cast`).
4. Tras `dart run swagger_parser` correr `dart run build_runner build --delete-conflicting-outputs`. El generado NO está en formato canónico de `dart format`; correr `dart format lib` antes de validar con `--set-exit-if-changed` (CI).

**Forma de uso:** `ref.read(logisticsApiProvider)` → `api.<module>.<operationId>(...)`; respuestas envuelven el payload en `.data`; errores `on DioException catch(e){ throw ApiException.fromDio(e); }`. Si el backend cambia el spec, re-copiar + regenerar. Ver [[app-api-coverage-state]].

**En Windows con Flutter 3.32 / Dart 3.8 (desde 2026-10-16):** el backend vive en WSL: `\\wsl.localhost\Ubuntu-22.04\dismac\logistics\openapi\v1.yaml` (puede tener cambios sin push; GitHub `Eduardito187/logistics` puede ir atrasado). La Python de Windows no tiene PyYAML → preprocesar con `wsl.exe -d Ubuntu-22.04 -- python3 -I /mnt/c/.../scripts/preprocess_openapi.py <yaml> <json>`. `dart run swagger_parser` funciona; después `dart format lib/core/api` (sin eso todo aparece como cambiado). **`retrofit_generator` NO compila con Dart 3.8**: ninguna versión ≤10.2.5 contempla `Parser.DartMappable` y ≥10.2.6 exige Dart 3.9. Si el cambio del spec es solo de modelos: quitar temporalmente `retrofit_generator` del pubspec, correr `build_runner build`, restaurar pubspec/lock y hacer `git checkout -- lib/core/api/clients/` (build_runner borra los `.g.dart` de los clientes). Si cambian endpoints, hay que generar con un Flutter ≥3.35 (Dart 3.9).

**En WSL (desde 2026-11-05, consolidado): hay Dart 3.13.7 standalone para generar.** El proyecto corre en Dart 3.8 (`~/sdk/flutter`), que NO compila `retrofit_generator ^10.2.12`. Se instaló un **Dart SDK 3.13.7 standalone** en `~/sdk/dartgen/dart-sdk/` (bajado de `storage.googleapis.com/dart-archive/.../3.13.7/sdk/dartsdk-linux-x64-release.zip`, ~228 MB; es solo SDK, sin Flutter — alcanza porque el generador `tool/api_gen` no depende de Flutter). El script `scripts/regen_api_client.sh` ya toma `GEN_DART`/`FMT_DART`: correr `GEN_DART=~/sdk/dartgen/dart-sdk/bin/dart FMT_DART=~/sdk/flutter/bin/dart bash scripts/regen_api_client.sh [--dry-run | --out DIR --keep]`. `--dry-run`/`--out` NO tocan el proyecto (ideal para revisar diff y el AVISO de renumeración DataN antes de aplicar). Lee el spec de `/dismac/logistics/openapi/v1.yaml` (backend, puede estar sin commitear). PyYAML local (5.4.1) OK para el preprocesado.

**AVISO al regenerar hoy: el cliente commiteado (26 oct) está ATRÁS ~10 días → un regen full trae drift mayor que ROMPE la app** (enum `Channel` repropósito a canales de venta, `Delivery.reference` requerido, `TwoFactor*` colisiona con auth, notifications `limit`…). Ver [[labeling-order-multishipping]] para el patrón de **regen QUIRÚRGICO** (aplicar solo los archivos de una feature nueva autocontenida y revertir el resto con `git checkout` + `git clean`).

**Regenerar con endpoints nuevos (probado 2026-10-16, Windows):** generar en una COPIA con el Flutter 3.47 que quedó en `C:\sdk\flutter` (Dart 3.13, donde `retrofit_generator ^10.2.12` sí compila): carpeta temporal con `openapi/`, `swagger_parser.yaml`, `analysis_options.yaml`, `third_party/` y el pubspec/lock de Dart 3.13 (respaldo en el scratchpad `backup-dart313/`), `pub get` + `dart run swagger_parser` + parche `MetaSealed?` + `build_runner build`, y copiar SOLO `lib/core/api` al proyecto; luego `C:\flutter\bin\dart format lib/core/api` y `flutter analyze` con 3.32 (el código generado compila en Dart 3.8). Trampa: swagger_parser numera los objetos anónimos (`Data4`, `Data6`, `Data21`…) y un endpoint nuevo CORRE la numeración → renombrar las referencias de la app/tests (y los imports `models/dataN.dart`) comparando campos viejo vs nuevo.

**Regen FULL hecho el 2026-11-14 (Windows, cliente al día con el backend).** Comando que funciona:
`powershell -ExecutionPolicy Bypass -File scripts\regen_api_client.ps1 -Spec C:\Users\ehhuallata\Documents\APP\logistics\openapi\v1.yaml [-DryRun]`
(el default del script apunta al backend VIEJO de WSL: pasar siempre `-Spec`). El generador producía código
roto o silenciosamente incorrecto; `scripts/preprocess_openapi.py` ahora lo corrige ANTES de generar (cada
arreglo imprime una línea al correr):
1. `prefer_json_bodies`: operación con el mismo cuerpo en JSON y multipart → deja JSON (si no, se aplanaba a
   parámetros sueltos, desaparecía `ProofOfDeliveryRequest` y quedaban parámetros DUPLICADOS que no compilan).
2. `drop_multipart_duplicates`: en multipart puro quita del cuerpo lo que ya viene por header/path.
3. `hoist_core_type_collisions`: propiedad `map` generaba `class Map` → "Stack Overflow" en json_serializable.
4. `hoist_enum_name_collisions` / `hoist_object_name_collisions`: un inline con el nombre de un componente lo
   PISABA en silencio (`channel` de comercio pisaba `Channel` de notificaciones → canal siempre $unknown;
   `node` del personal pisaba `Node` de la red). Ahora salen como `ChannelOption`, `NodeSummary`,
   `VehicleSummary`, `DriverSummary2` y el componente conserva su nombre (por eso `Vehicle`/`Driver` son ahora
   los completos y la tripulación usa los `*Summary`).
5. `name_response_data`: el `data` inline de cada respuesta se llama `<OperationId>Data` (estable). Antes
   `Data`, `Data2`… se renumeraban con cada endpoint nuevo y dos respuestas podían compartir `Data`.
6. `simplify_union_parameters`: query con `oneOf` salía `dynamic` y hacía `.toJson()` sobre null
   (`GET /app/shipments` sin `status` reventaba).
Y en `regen_api_client.ps1`: el parche de `meta` nullable es genérico (`final <Tipo> meta;` sin `required`).
**El cliente generado está EXCLUIDO del analyzer**: para ver si compila, comentar temporalmente las exclusiones
de `analysis_options.yaml`, `dart analyze lib/core/api`, y restaurar. Quedan numerados (inestables) los enums
inline `Type2/3/4`, `Status*`, `Stops*`: al regenerar, revisar esas referencias. `scripts/regen_api_client.sh`
(WSL) usa el mismo preprocesador. `Meta` de listas viejas es una clase vacía: paginación por heurística
(página completa = puede haber más); las nuevas traen `ListMeta` con `nextPage`.
