# scripts/

Automatizaciones del app interna de logistica. Todas asumen el Flutter de WSL en
`~/sdk/flutter` (ver `CLAUDE.md`).

## Regenerar el cliente del API (`regen_api_client.sh`)

Regla #5: los DTOs del API no se escriben a mano, se generan desde el contrato
OpenAPI del backend.

```bash
# Spec por defecto: /dismac/logistics/openapi/v1.yaml
bash scripts/regen_api_client.sh

# O apuntando a otro spec:
bash scripts/regen_api_client.sh /ruta/a/v1.yaml
```

Pasos que reproduce (idempotente):

1. Copia `v1.yaml` del backend a `openapi/v1.yaml`.
2. Preprocesa a `openapi/v1.json` con `preprocess_openapi.py` (expande anchors YAML
   e inyecta los `parameters` de nivel path en cada operacion; swagger_parser no los
   soporta).
3. `dart run swagger_parser` (config en `swagger_parser.yaml`).
4. `dart run build_runner build --delete-conflicting-outputs`.

El cliente generado vive en `lib/core/api/` (excluido del analyzer).

> El preprocesado se puede correr suelto:
> `python3 -I scripts/preprocess_openapi.py openapi/v1.yaml openapi/v1.json`

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

Atajos que usan el Flutter de WSL:

| Target         | Que hace                                                     |
| -------------- | ------------------------------------------------------------ |
| `make format`  | `dart format lib test`                                       |
| `make analyze` | `flutter analyze`                                            |
| `make test`    | `flutter test`                                               |
| `make gen`     | corre `scripts/regen_api_client.sh`                          |
| `make ci`      | format check (`--set-exit-if-changed`) + analyze + test      |

`make ci` reproduce localmente lo que corre el workflow `.github/workflows/ci.yml`.
