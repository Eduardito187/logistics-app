# Listado de planes/viajes: filtro por estado, búsqueda y estado de ejecución

- **De:** app interna (logistics-app)
- **Para:** backend (logistics)
- **Fecha:** 2026-11-17
- **Prioridad:** Media · no bloqueante (la app ya filtra client-side mientras tanto)

## Contexto

El dueño quiere no solo CREAR viajes/planes sino VERLOS y FILTRARLOS: "las
planificaciones creadas, cerradas o en curso por filtros select de estados y un
buscador". En el dominio un "viaje" y una "planificación" son la misma entidad
`Plan` (un viaje recién armado es un plan en borrador), así que el listado de
planes es también el de viajes.

## Qué hace hoy la app

- `GET /app/plans?date=Y-m-d` → planes del día (uno por camión). Es lo único que
  hay: el endpoint **solo** filtra por `date` (más `page`/`per_page`/`cursor`).
- La pantalla del planificador/supervisor ahora agrega, **client-side** sobre los
  planes del día ya cargados: un SELECT de estado (`PlanStatus`) y un buscador de
  texto (placa y chofer). Suficiente como primera versión, pero tiene dos límites
  que solo el backend puede levantar.

## Qué falta (lo que se pide)

### 1. Filtro server-side por estado y texto en `GET /app/plans`
Para que el filtro funcione sobre TODO (no solo la página del día cargada) y no
traer de más:
- `status`: uno o varios de `DRAFT|PROPOSED|PUBLISHED` (CSV o repetido).
- `q`: texto libre; matchea placa (`plate`), chofer (`driver_name`) y nombre del
  nodo destino.

### 2. Estado de EJECUCIÓN en el `Plan` (para "en curso" vs "cerrada")
`PlanStatus` solo tiene `DRAFT|PROPOSED|PUBLISHED`. El dueño piensa en "creadas /
en curso / cerradas": "en curso" y "cerrada" NO son estados del plan sino de la
**ruta** que lo ejecuta (`DriverRouteStatus`). Hoy el `Plan` que devuelve
`/app/plans` no trae ese dato, así que la app no puede separar un plan publicado
que está en curso de uno ya cerrado.

Pedido: agregar al proyección `Plan` un campo de ejecución, p. ej.:
- `route_status`: `DriverRouteStatus` de la ruta del plan (`null` si todavía no
  se ensambló la ruta), **o**
- `execution_status`: enum derivado y estable para la UI:
  `NOT_STARTED | IN_PROGRESS | COMPLETED`.

Con eso el SELECT puede ofrecer "Borrador", "Propuesta", "En curso" y "Cerrada".

### 3. (Opcional) Rango de fechas para viajes multi-día
Una entrega en curso puede cruzar la medianoche o durar varios días (mismo caso
del bug de my-crew que ya corrigieron). Para "ver los viajes en curso" sin tener
que adivinar el día, estaría bueno `date_from`/`date_to` (o un `scope=active` que
devuelva los planes con ruta abierta de cualquier día). No bloqueante.

## Propuesta de contrato (openapi/v1.yaml)

```yaml
/app/plans:
  get:
    parameters:
      - { name: date, in: query, required: false, schema: { type: string, format: date } }
      - name: status
        in: query
        required: false
        description: Filtra por estado del plan. CSV o repetido.
        schema:
          type: array
          items: { type: string, enum: [DRAFT, PROPOSED, PUBLISHED] }
        style: form
        explode: false
      - { name: q, in: query, required: false, schema: { type: string }, description: "Texto: placa, chofer o nodo destino" }
      - { name: date_from, in: query, required: false, schema: { type: string, format: date } }
      - { name: date_to, in: query, required: false, schema: { type: string, format: date } }
# Plan: agregar
Plan:
  properties:
    execution_status:
      type: string
      enum: [NOT_STARTED, IN_PROGRESS, COMPLETED]
      nullable: true
      description: Estado de ejecución de la ruta del plan. null si aún no se ensambló.
```

## Criterio de aceptación

- `GET /app/plans?status=PUBLISHED&q=1234` devuelve solo publicados cuyo plate/
  chofer/nodo contenga "1234".
- Cada `Plan` trae `execution_status` (o `route_status`) coherente con la ruta.
- Cambios reflejados en `openapi/v1.yaml` para regenerar el cliente.
- Sin romper el `?date` actual (lo usa la app y el admin).

## Mientras tanto (app, ya hecho)

Filtro client-side por `PlanStatus` + texto (placa/chofer) sobre los planes del
día. Cuando llegue el contrato, se mueve el filtro al servidor y se agregan "en
curso"/"cerrada" al SELECT. No requiere que la app bloquee nada.
