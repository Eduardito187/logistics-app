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
#   - swagger_parser nombra la clase de un objeto INLINE con el nombre de su
#     propiedad: una propiedad `map` genera `class Map`, que tapa al `Map` de
#     dart:core y revienta json_serializable con "Stack Overflow" (paso con
#     AppConfig.data.map). Esos objetos se mueven a components.schemas con un
#     nombre seguro (`MapSettings`) y la propiedad pasa a ser un `$ref`.
#   - en un cuerpo multipart swagger_parser aplana cada propiedad a un parametro
#     del metodo; si el cuerpo repite un parametro que ya viene por header o por
#     path (`idempotency_key` + header `Idempotency-Key`, `shipment_id` + path
#     `{shipmentId}`) el metodo queda con DOS parametros del mismo nombre y no
#     compila. Se quita la copia del cuerpo: la app usa el header / el path.
#   - si una operacion acepta el mismo cuerpo como JSON y como multipart, se deja
#     el JSON (ver `prefer_json_bodies`).
#
# Uso (siempre con interprete aislado para no cargar modulos del cwd):
#   python3 -I scripts/preprocess_openapi.py <entrada.yaml> <salida.json>

import copy
import json
import re
import sys

import yaml

# Metodos HTTP que son operaciones dentro de un path item.
HTTP_METHODS = ("get", "post", "put", "patch", "delete")


# Nombres de clase que swagger_parser NO puede generar: tapan tipos de dart:core.
DART_CORE_TYPES = frozenset(
    # Solo los que el generador usa en el codigo que emite (colecciones y
    # primitivos). `Error`, `Type`, etc. ya se generaban bien: no se tocan, para
    # no renombrar clases que la app ya referencia.
    ("Map", "List", "Set", "Iterable", "String", "Object", "Future", "Stream",
     "DateTime", "Duration", "Null")
)


def _pascal(name):
    return "".join(part[:1].upper() + part[1:] for part in name.replace("-", "_").split("_"))


def hoist_core_type_collisions(spec):
    """Mueve a components.schemas los objetos inline cuya propiedad se llama
    como un tipo de dart:core (p. ej. `map`) y los reemplaza por un `$ref`."""
    schemas = spec.setdefault("components", {}).setdefault("schemas", {})
    hoisted = []

    def visit(node):
        if isinstance(node, list):
            for item in node:
                visit(item)
            return
        if not isinstance(node, dict):
            return
        props = node.get("properties")
        if isinstance(props, dict):
            for key in list(props.keys()):
                value = props[key]
                if (
                    isinstance(value, dict)
                    and "$ref" not in value
                    and isinstance(value.get("properties"), dict)
                    and _pascal(key) in DART_CORE_TYPES
                ):
                    name = _pascal(key) + "Settings"
                    n = 2
                    while name in schemas and schemas[name] is not value:
                        name = f"{_pascal(key)}Settings{n}"
                        n += 1
                    schemas[name] = value
                    props[key] = {"$ref": f"#/components/schemas/{name}"}
                    hoisted.append(name)
        for child in list(node.values()):
            visit(child)

    visit(spec)
    return hoisted


def _norm(name):
    return re.sub(r"[^a-z0-9]", "", str(name).lower())


def _resolve(spec, node):
    """Sigue un `$ref` local (#/components/...) y devuelve el nodo destino."""
    ref = node.get("$ref") if isinstance(node, dict) else None
    if not isinstance(ref, str) or not ref.startswith("#/"):
        return node
    target = spec
    for part in ref[2:].split("/"):
        if not isinstance(target, dict):
            return node
        target = target.get(part)
    return target if isinstance(target, dict) else node


def prefer_json_bodies(spec):
    """Si una operacion acepta el MISMO cuerpo como JSON y como multipart, deja
    solo el JSON y le quita al schema los campos binarios (archivos).

    La app manda esos cuerpos como JSON por la cola offline (el archivo viaja
    aparte, por la cola de fotos). Con las dos variantes swagger_parser elige el
    multipart, aplana el cuerpo a parametros sueltos y desaparece el modelo
    (`ProofOfDeliveryRequest`) que la app serializa."""
    changed = []
    dropped_refs = set()
    for path, path_item in (spec.get("paths") or {}).items():
        if not isinstance(path_item, dict):
            continue
        for method in HTTP_METHODS:
            operation = path_item.get(method)
            if not isinstance(operation, dict):
                continue
            content = (operation.get("requestBody") or {}).get("content")
            if not isinstance(content, dict):
                continue
            if "application/json" not in content or "multipart/form-data" not in content:
                continue
            dropped = content.pop("multipart/form-data")
            dropped_ref = (dropped.get("schema") or {}).get("$ref") if isinstance(dropped, dict) else None
            if isinstance(dropped_ref, str):
                dropped_refs.add(dropped_ref)
            schema = _resolve(spec, content["application/json"].get("schema") or {})
            props = schema.get("properties") if isinstance(schema, dict) else None
            if isinstance(props, dict):
                for key in [k for k, v in props.items()
                            if isinstance(v, dict) and v.get("format") == "binary"]:
                    props.pop(key)
                    if key in (schema.get("required") or []):
                        schema["required"].remove(key)
            changed.append(f"{method.upper()} {path}")
    # El esquema multipart que quedo sin uso se borra: suelto, swagger_parser lo
    # emite como modelo JSON y falla (tiene el archivo binario).
    schemas = (spec.get("components") or {}).get("schemas") or {}
    for ref in dropped_refs:
        if json.dumps(spec).count(f'"{ref}"') == 0:
            schemas.pop(ref.rsplit("/", 1)[-1], None)
    return changed


def drop_multipart_duplicates(spec):
    """En cuerpos multipart, quita las propiedades que repiten un parametro de
    header/path/query de la misma operacion (ver cabecera del archivo)."""
    dropped = []
    replaced_refs = set()
    for path, path_item in (spec.get("paths") or {}).items():
        if not isinstance(path_item, dict):
            continue
        for method in HTTP_METHODS:
            operation = path_item.get(method)
            if not isinstance(operation, dict):
                continue
            names = {
                _norm(_resolve(spec, param).get("name", ""))
                for param in operation.get("parameters") or []
                if isinstance(param, dict)
            }
            names.discard("")
            content = (operation.get("requestBody") or {}).get("content") or {}
            media = content.get("multipart/form-data")
            if not names or not isinstance(media, dict):
                continue
            original = media.get("schema") or {}
            schema = _resolve(spec, original)
            props = schema.get("properties") if isinstance(schema, dict) else None
            if not isinstance(props, dict):
                continue
            clashes = [key for key in props if _norm(key) in names]
            if not clashes:
                continue
            # Copia propia: el schema puede ser compartido por otras operaciones.
            schema = copy.deepcopy(schema)
            for key in clashes:
                schema["properties"].pop(key, None)
                if key in (schema.get("required") or []):
                    schema["required"].remove(key)
                dropped.append(f"{method.upper()} {path}: {key}")
            media["schema"] = schema
            ref = original.get("$ref") if isinstance(original, dict) else None
            if isinstance(ref, str):
                replaced_refs.add(ref)

    # Un schema de componentes que ya nadie referencia se borra: suelto,
    # swagger_parser lo emite como modelo JSON y falla (tiene campos binarios).
    schemas = (spec.get("components") or {}).get("schemas") or {}
    for ref in replaced_refs:
        if json.dumps(spec).count(f'"{ref}"') == 0:
            schemas.pop(ref.rsplit("/", 1)[-1], None)
    return dropped


def hoist_enum_name_collisions(spec):
    """Un enum INLINE cuya propiedad se llama igual que un schema de componentes
    con OTROS valores pisa en silencio la clase del componente: `channel`
    (retail/b2b/c2c, de comercio) reemplazaba a `Channel` (FCM/TELEGRAM/EMAIL/SMS,
    de notificaciones) y el canal de una notificacion pasaba a leerse como
    desconocido. Esos enums inline se mueven a un componente propio
    (`ChannelOption`); los que tienen los mismos valores comparten uno."""
    schemas = spec.setdefault("components", {}).setdefault("schemas", {})
    by_values = {}
    hoisted = []

    def visit(node):
        if isinstance(node, list):
            for item in node:
                visit(item)
            return
        if not isinstance(node, dict):
            return
        props = node.get("properties")
        if isinstance(props, dict):
            for key in list(props.keys()):
                value = props[key]
                if not isinstance(value, dict) or "$ref" in value:
                    continue
                values = value.get("enum")
                component = schemas.get(_pascal(key))
                if (
                    not isinstance(values, list)
                    or not isinstance(component, dict)
                    or component is value
                    or not isinstance(component.get("enum"), list)
                    # `null` en el enum inline solo marca "nullable": no cuenta.
                    or [v for v in values if v is not None] == component["enum"]
                ):
                    continue
                signature = (_pascal(key), json.dumps(values))
                name = by_values.get(signature)
                if name is None:
                    name = _pascal(key) + "Option"
                    n = 2
                    while name in schemas:
                        name = f"{_pascal(key)}Option{n}"
                        n += 1
                    schemas[name] = value
                    by_values[signature] = name
                    hoisted.append(name)
                props[key] = {"$ref": f"#/components/schemas/{name}"}
        # Un parametro (query/path) con enum inline tambien genera una clase con
        # el nombre del parametro.
        if isinstance(node.get("name"), str) and "in" in node:
            schema = node.get("schema")
            if isinstance(schema, dict) and "$ref" not in schema:
                holder = {node["name"]: schema}
                fake = {"properties": holder}
                visit_props_only(fake)
                node["schema"] = holder[node["name"]]
        for child in list(node.values()):
            visit(child)

    def visit_props_only(node):
        props = node["properties"]
        for key in list(props.keys()):
            value = props[key]
            values = value.get("enum")
            component = schemas.get(_pascal(key))
            if (
                not isinstance(values, list)
                or not isinstance(component, dict)
                or not isinstance(component.get("enum"), list)
                or [v for v in values if v is not None] == component["enum"]
            ):
                continue
            signature = (_pascal(key), json.dumps(values))
            name = by_values.get(signature)
            if name is None:
                name = _pascal(key) + "Option"
                n = 2
                while name in schemas:
                    name = f"{_pascal(key)}Option{n}"
                    n += 1
                schemas[name] = value
                by_values[signature] = name
                hoisted.append(name)
            props[key] = {"$ref": f"#/components/schemas/{name}"}

    visit(spec)
    return hoisted


def simplify_union_parameters(spec):
    """Un parametro de query con `oneOf` (texto O lista de un enum) se genera
    como `dynamic` y el cliente le llama `.toJson()` sin mirar si es null:
    `GET /app/shipments` sin `status` reventaba con NoSuchMethodError. Se deja
    UNA variante: el enum (un valor; el backend acepta uno o varios)."""
    changed = []

    def pick(variants):
        for v in variants:
            if isinstance(v, dict) and "$ref" in v:
                return v
        for v in variants:
            items = v.get("items") if isinstance(v, dict) else None
            if isinstance(items, dict) and "$ref" in items:
                return items
        return variants[0] if variants else None

    def visit(node):
        if isinstance(node, list):
            for item in node:
                visit(item)
            return
        if not isinstance(node, dict):
            return
        if isinstance(node.get("name"), str) and node.get("in") in ("query", "path", "header"):
            schema = node.get("schema")
            if isinstance(schema, dict):
                variants = schema.get("oneOf") or schema.get("anyOf")
                if isinstance(variants, list) and variants:
                    chosen = pick(variants)
                    if isinstance(chosen, dict):
                        node["schema"] = chosen
                        changed.append(node["name"])
        for child in list(node.values()):
            visit(child)

    visit(spec)
    return changed


def hoist_object_name_collisions(spec):
    """Lo mismo que con los enums, para OBJETOS: una propiedad inline `node`
    ({id, name, type, city} en la ficha del personal) pisaba al componente
    `Node` (la tienda completa, con `code`, `lat`, `lng`...) y media app dejaba
    de compilar. El objeto inline pasa a un componente propio (`NodeSummary`);
    los que tienen las mismas propiedades comparten uno."""
    schemas = spec.setdefault("components", {}).setdefault("schemas", {})
    by_shape = {}
    hoisted = []

    def visit(node):
        if isinstance(node, list):
            for item in node:
                visit(item)
            return
        if not isinstance(node, dict):
            return
        props = node.get("properties")
        if isinstance(props, dict):
            for key in list(props.keys()):
                value = props[key]
                if not isinstance(value, dict) or "$ref" in value:
                    continue
                inner = value.get("properties")
                component = schemas.get(_pascal(key))
                if (
                    not isinstance(inner, dict)
                    or not isinstance(component, dict)
                    or component is value
                    or not isinstance(component.get("properties"), dict)
                    or set(inner) == set(component["properties"])
                ):
                    continue
                signature = (_pascal(key), json.dumps(sorted(inner)))
                name = by_shape.get(signature)
                if name is None:
                    name = _pascal(key) + "Summary"
                    n = 2
                    while name in schemas:
                        name = f"{_pascal(key)}Summary{n}"
                        n += 1
                    schemas[name] = value
                    by_shape[signature] = name
                    hoisted.append(name)
                    visit(value)
                props[key] = {"$ref": f"#/components/schemas/{name}"}
        for child in list(node.values()):
            visit(child)

    visit(spec)
    return hoisted


def name_response_data(spec):
    """Da un nombre PROPIO y ESTABLE al objeto inline `data` de cada respuesta.

    swagger_parser llama `Data`, `Data2`, `Data3`... a esos objetos anonimos, en
    orden de aparicion: cada endpoint nuevo en el backend corria la numeracion
    (habia que renombrar a mano Data5 -> Data6 en la app) y, peor, dos respuestas
    distintas podian terminar compartiendo la clase `Data` sin numero (la foto de
    entrega se leia con el modelo de la plantilla de checklist). Ahora cada uno
    se llama por su operacion: `<OperationId>Data`."""
    schemas = spec.setdefault("components", {}).setdefault("schemas", {})
    named = []

    def hoist(owner, base):
        if not isinstance(owner, dict):
            return
        for media in (owner.get("content") or {}).values():
            schema = media.get("schema") if isinstance(media, dict) else None
            props = schema.get("properties") if isinstance(schema, dict) else None
            if not isinstance(props, dict):
                continue
            data = props.get("data")
            if not isinstance(data, dict) or "$ref" in data:
                continue
            if not isinstance(data.get("properties"), dict):
                continue
            name = base + "Data"
            n = 2
            while name in schemas and schemas[name] != data:
                name = f"{base}Data{n}"
                n += 1
            schemas[name] = data
            props["data"] = {"$ref": f"#/components/schemas/{name}"}
            named.append(name)

    for path_item in (spec.get("paths") or {}).values():
        if not isinstance(path_item, dict):
            continue
        for method in HTTP_METHODS:
            operation = path_item.get(method)
            if not isinstance(operation, dict):
                continue
            op_id = operation.get("operationId")
            if not isinstance(op_id, str) or not op_id:
                continue
            base = _pascal(re.sub(r"[^A-Za-z0-9]+", "_", op_id))
            for response in (operation.get("responses") or {}).values():
                hoist(response, base)
    for key, response in ((spec.get("components") or {}).get("responses") or {}).items():
        hoist(response, _pascal(re.sub(r"[^A-Za-z0-9]+", "_", key)))
    # Tambien los sobres declarados como componente (`AcceptedEnvelope.data`):
    # su `data` inline se numeraba igual (Data5, Data6...) y se corria.
    for key in list(schemas.keys()):
        schema = schemas[key]
        props = schema.get("properties") if isinstance(schema, dict) else None
        if not isinstance(props, dict):
            continue
        data = props.get("data")
        if (
            not isinstance(data, dict)
            or "$ref" in data
            or not isinstance(data.get("properties"), dict)
        ):
            continue
        name = key + "Data"
        n = 2
        while name in schemas and schemas[name] != data:
            name = f"{key}Data{n}"
            n += 1
        schemas[name] = data
        props["data"] = {"$ref": f"#/components/schemas/{name}"}
        named.append(name)
    return named


def preprocess(spec):
    """Aplana parameters/servers de nivel path dentro del dict del spec."""
    for name in hoist_enum_name_collisions(spec):
        print(f"Enum inline renombrado para no pisar un componente: {name}")
    for name in simplify_union_parameters(spec):
        print(f"Parametro con oneOf simplificado a un tipo: {name}")
    for name in hoist_object_name_collisions(spec):
        print(f"Objeto inline renombrado para no pisar un componente: {name}")
    named = name_response_data(spec)
    if named:
        print(f"Objetos `data` de respuesta con nombre propio: {len(named)}")
    for name in hoist_core_type_collisions(spec):
        print(f"Objeto inline renombrado para no tapar dart:core: {name}")
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

    for item in prefer_json_bodies(spec):
        print(f"Cuerpo JSON preferido sobre multipart: {item}")

    # Despues de aplanar los parametros de path (ya estan en cada operacion).
    for item in drop_multipart_duplicates(spec):
        print(f"Campo multipart duplicado quitado del cuerpo: {item}")

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
