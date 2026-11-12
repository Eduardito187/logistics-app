---
name: pod-scanner-vehicle-hardening
description: "nov 2026 — fixes de entrega/escáner/asignación: scanner no-negro, sin \"QR del cliente\", bulto validado vs envío, selector de vehículos reales; binding al backend pendiente"
metadata:
  node_type: memory
  type: project
  originSessionId: 9a85d4dc-6dee-4d1d-8426-868a6db4e45d
  modified: 2026-11-12T04:26:46.579Z
---

Batch de endurecimiento del reparto (nov 2026, probado en staging con el teléfono):

- **Login mostraba el error anterior** en el siguiente intento (AsyncLoading conserva el error vía copyWithPrevious): el listener ahora ignora el error mientras `isLoading`. Test de regresión en `login_screen_test`.
- **Teclado quedaba abierto al navegar**: `KeyboardDismissObserver` en el router suelta el foco en cada push/pop/replace. Los diálogos con `autofocus` lo reabren después del push.
- **Escáner en negro/colgado** (`scanner_screen.dart`, mobile_scanner 7.2.0): no arrancaba explícito ni manejaba errores → se agregó `_startCamera()` en initState + `errorBuilder`/overlay con "Reintentar" (permiso/cámara en uso). Antes: pantalla negra sin feedback.
- **"QR del cliente" NO existe** en reparto a domicilio: se quitó el botón de `pod_screen.dart`; la confirmación es **solo firma** (FIRMA_DIGITAL). Pendiente confirmar si tienda/transportista (recojo) sí tienen código de recojo (ver doc).
- **Cerrar un pedido que no corresponde**: `scanVerifiedUnit` devolvía el bulto de CUALQUIER etiqueta. El POD ahora valida que el bulto pertenezca al `shipment_id` de la parada (`driverShipmentUnitsProvider`); si es de otro pedido, rechaza con aviso. Sin red o **lista VACÍA** → no bloquea (el backend aún no puebla bultos por parada; nunca rechazar por lista vacía).
- **POD multi-bulto (nov 2026)**: el POD cerraba con UN SOLO bulto (`_unitId`). Ahora acumula TODOS los bultos del pedido (`_unitIds`), muestra "Escaneados X de N" (N = `driverShipmentUnitsProvider`), no deja repetir, y al registrar manda **un POD por bulto** (outcome combinado: falló/encolado/enviado). Si no se sabe N (backend sin datos) exige ≥1, no un total. Ver [[label-key-rotation-footgun]] (modelo abierto k:0).
- **Asignar vehículo = selector de flota real** (`availableVehiclesProvider` → `/app/fleet/vehicles`), no texto libre. `AssignLaneDialog` ahora es un picker buscable. El preparador SÍ puede listar `/app/fleet/vehicles`.

**Lo que depende del backend** (doc `docs/backend-requests/2026-11-11-asignacion-vehiculo-y-pod-validaciones.md`):
1. La asignación de vehículo es **estado LOCAL**: falta endpoint que **ate el envío al vehículo/ruta** (hoy el tracking no se liga de verdad). Ver [[labeling-order-multishipping]].
2. `POST /app/deliveries/proof-of-delivery` da **500** al cerrar directo por API (falta precondición/secuencia de scans; debería ser 422 con motivo).
3. `/app/vehicles/{id}/route` (SCZ-2611xx) y `/app/vehicles/{id}/deliveries` (SCZ-2610xx) **no coinciden** → el shipment de la parada no se resuelve por /deliveries.

Relacionado: [[windows-native-toolchain]], [[run-environments-config]] (footgun del `10.0.2.2` en debug físico).
