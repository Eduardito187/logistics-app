---
name: carrier-corridor-slugs
description: "Los corredores de tarifas/liquidaciones usan SLUGS (cd-santa-cruz), que NO son los códigos de nodo de la red; verificado contra staging"
metadata:
  node_type: memory
  type: reference
  originSessionId: 9a85d4dc-6dee-4d1d-8426-868a6db4e45d
  modified: 2026-11-12T08:45:10.971Z
---

**Nov 2026.** En tarifas y liquidaciones del transportista conviven **tres vocabularios distintos** y es muy fácil usar el equivocado:

| Dónde | Ejemplo | Sirve para la tarifa |
|---|---|---|
| **Slug de corredor** (tarifas/liquidaciones) | `cd-santa-cruz`, `cd-la-paz`, `store-scz-centro` | **SÍ → 200** |
| Código de nodo (`GET /app/network/nodes`) | `CD-SCZ-01`, `T-SCZ-01` | **NO → 404** |
| El hint del formulario viejo | "Ej. LPB" | no corresponde a ninguno |

Verificado contra staging: `GET /app/carriers/tariffs/cheapest?corridor_from=cd-santa-cruz&corridor_to=cd-la-paz&corridor_type=cd_to_cd` → **200 con tarifa**; con `CD-SCZ-01`/`CD-LP-01` → **404**. El backend confirmó que **los slugs no van a migrar** a ids de nodo.

**No existe endpoint que liste esos slugs**: `carriers_client` solo tiene `getCarrierTariff` y `cheapestCarrierTariff`, que ya exigen el corredor, y no hay "listar tarifas". `GET /app/network/nodes` y `/network/legs` son de la red (otro vocabulario) y NO sirven. Pedido abierto al backend: `GET /app/carriers/corridors` → `[{from, to, from_label, to_label, corridor_type, vehicle_classes[]}]` con los slugs + etiqueta legible (el backend lo iba a consultar con el dueño).

**Mientras tanto:** los corredores reales del transportista se derivan de **sus liquidaciones** (`GET /app/carriers/settlements` trae `corridor_from`/`corridor_to`/`corridor_type`). Limitación: un transportista sin liquidaciones no tiene de dónde elegir.

Datos que SÍ son enums del contrato y nunca deben escribirse a mano: **`CorridorType`** (cd_to_customer, cd_to_cd, cd_to_store, store_to_store, store_to_cd, store_pickup) y **`VehicleClass`** (trailer, truck, third_party). Ojo: `Settlement.vehicle_class` llega `null` porque el backend **no lo guarda** (pedido abierto).

Ver [[backend-audit-2026-11-12]].
