# Odómetro: valor `arrival` en `RecordOdometerRequestSource`

**Fecha:** 2026-11-11 · **Pedido por:** app (sesión `logistics-app-f4`) · **Backend:** `logistics-1a`
**Estado:** **ENTREGADO** por `logistics-1a` (enum + validación derivada del enum + OpenAPI + admin).
App: `arrival` agregado al enum generado (parche quirúrgico, idéntico a lo que daría el regen) y el
flujo "Finalizar ruta" ya usa `source: arrival`.

## Contexto

Por decisión del dueño, el odómetro del camión se captura SOLO en dos momentos de la ruta:

1. **Salida del almacén** (al empezar la ruta): ya cableado en la app dentro del **checklist
   pre-salida**, con `source: departure` (ese valor YA existe en el enum). ✅
2. **Llegada al centro de distribución** (cierre de la ruta): nuevo flujo "Finalizar ruta" en la app.

El enum `RecordOdometerRequestSource` hoy tiene: `manual`, `telemetry`, `refuel`, `maintenance`,
`departure`. **Falta el simétrico de `departure` para la llegada.**

## Pedido

Agregar el valor **`arrival`** (llegada/cierre de ruta) a `RecordOdometerRequestSource` (y, si les
sirve para reportes, dejar expuesto que `departure`+`arrival` de un mismo día = km recorridos de la
ruta). Es aditivo y backward-compatible.

Mientras tanto la app registra la lectura de llegada como `source: manual` con la nota **"Llegada al
CD"**. Cuando agreguen `arrival` + regeneremos el cliente, se cambia ese único `source`.

## Nada más del backend para esto

El resto es app-side. La **inspección diaria del camión** (agua/refrigerante, frenos, motor, aceite,
fugas, etc.) reutiliza los endpoints de checklist pre-salida que YA existen:
`POST /app/fleet/pre-trip-checklists` (registrar) y `GET /app/fleet/pre-trip-checklists?vehicle_id=…`
(historial por camión). No se pide nada nuevo para mantenimiento diario / historial.
