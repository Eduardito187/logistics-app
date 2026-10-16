#!/usr/bin/env python3
# Preprocesa el contrato OpenAPI del backend para que swagger_parser lo digiera.
#
# Por qué existe este paso:
#   - swagger_parser tropieza con los anchors/aliases YAML -> al cargar con PyYAML
#     y volcar a JSON quedan expandidos.
#   - swagger_parser no soporta `parameters` a nivel de path -> los inyectamos en
#     cada operacion (get/post/put/patch/delete) que no los defina ya, y luego
#     borramos la clave del nivel path.
#   - cualquier `servers` a nivel de path tambien se elimina (swagger_parser no lo usa).
#
# Uso (siempre con interprete aislado para no cargar modulos del cwd):
#   python3 -I scripts/preprocess_openapi.py <entrada.yaml> <salida.json>

import json
import sys

import yaml

# Metodos HTTP que son operaciones dentro de un path item.
HTTP_METHODS = ("get", "post", "put", "patch", "delete")


def preprocess(spec):
    """Aplana parameters/servers de nivel path dentro del dict del spec."""
    paths = spec.get("paths")
    if not isinstance(paths, dict):
        return spec

    for path_item in paths.values():
        if not isinstance(path_item, dict):
            continue

        # Parametros declarados a nivel de path: aplican a todas las operaciones.
        path_params = path_item.get("parameters")

        if path_params:
            for method in HTTP_METHODS:
                operation = path_item.get(method)
                if not isinstance(operation, dict):
                    continue
                # Solo inyectamos si la operacion no trae sus propios parametros;
                # si ya los tiene, respetamos lo que define la operacion.
                if not operation.get("parameters"):
                    operation["parameters"] = list(path_params)

        # Quitamos las claves de nivel path que swagger_parser no maneja.
        path_item.pop("parameters", None)
        path_item.pop("servers", None)

    return spec


def main(argv):
    if len(argv) != 3:
        print(
            "Uso: python3 -I scripts/preprocess_openapi.py <entrada.yaml> <salida.json>",
            file=sys.stderr,
        )
        return 2

    input_path, output_path = argv[1], argv[2]

    with open(input_path, "r", encoding="utf-8") as fh:
        # safe_load expande anchors y aliases YAML a estructuras planas.
        spec = yaml.safe_load(fh)

    if not isinstance(spec, dict):
        print(f"El spec {input_path} no es un documento OpenAPI valido.", file=sys.stderr)
        return 1

    preprocess(spec)

    with open(output_path, "w", encoding="utf-8") as fh:
        json.dump(spec, fh, ensure_ascii=False, indent=2)
        fh.write("\n")

    print(f"OpenAPI preprocesado: {input_path} -> {output_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
