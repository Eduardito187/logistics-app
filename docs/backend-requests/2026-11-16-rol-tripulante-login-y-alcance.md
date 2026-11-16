# Rol TRIPULANTE: login de solo lectura + alcance por cuadrilla

**Fecha:** 2026-11-16 · **Pide:** app (logistics-app-98) · **Para:** backend (logistics-e8)
**Prioridad:** Alta · nuevo (decisión del dueño)

## Qué decidió el dueño

Crear un rol **tripulante** (ayudante que va en el camión con el chofer). Es un **rol de login** de
**SOLO LECTURA**. Sus accesos son exactamente:

1. **Avisos / notificaciones** y **perfil** (como todos los roles).
2. **Escanear una etiqueta** para ver los productos / consultar un pedido (ya abierto a todos los roles
   vía `GET /app/orders/lookup` + `/app/labels/{id}/resolve`).
3. **Ver la información de los envíos del camión en el que participa** — los que tiene **programados** o
   **en curso**. Sin acciones: no carga, no entrega, no asigna (eso es del chofer).

## Lo que YA hizo la app (desplegable hoy, queda dormido hasta que exista el rol)

- `UserRole.crewMember` con `backendKey: 'tripulante'` (mapea login y `/app/auth/me`). Sin el rol en el
  backend, **nadie puede loguearse como tripulante** → no hay regresión para los demás roles.
- Inicio del tripulante: tarjetas **Mis envíos** (acción principal), **Consultar pedido**, **Ajustes**, y
  la pestaña de **Avisos** del shell. Pantalla nueva `CrewShipmentsScreen` (`lib/features/crew/`), solo
  lectura: cabecera con el camión/cuadrilla + lista de paradas (pedido, cliente, dirección, productos,
  estado), selector de fecha (hoy = en curso; otra fecha = programados), y botón para consultar/escanear.
- **Reutiliza los MISMOS endpoints de lectura del chofer** (no suma llamadas nuevas):
  `GET /app/fleet/my-crew?date=` (el camión del día) → `GET /app/vehicles/{id}/route?date=` (las paradas).

## Lo que necesita del backend

### 1. Rol de login `tripulante` (solo lectura) — `app/Enums/Role.php`
- `case Tripulante = 'tripulante';`
- `label()` → `'Crew member'` (o lo que prefieran para Filament/API).
- `abilities()` → **solo lectura**, sin ningún `*_WRITE`:
  `SHIPMENTS_READ, PLANNING_READ, EXECUTION_READ, TRACKING_READ, NETWORK_READ, NOTIFICATIONS_READ`.
  (El tripulante NO lleva `EXECUTION_WRITE` ni `TRACKING_WRITE`: no registra entregas ni GPS.)
- Sembrarlo (`AccessSeeder`/`access_roles`) y dejarlo **asignable desde el admin** (select de roles del
  personal / `RoleResource`), igual que los demás.

### 2. `GET /app/fleet/my-crew` debe resolver por **miembro de la cuadrilla**, no solo por chofer
Hoy `my-crew` devuelve la cuadrilla del **chofer** autenticado. El tripulante es un **ayudante**
(`helper_ids` de `fleet_crews`). Necesitamos que, para un usuario con rol `tripulante`, `my-crew`
resuelva la cuadrilla del día donde él figura como **ayudante** y devuelva el **mismo shape** (vehicle,
driver, helpers, shift). Si no está en ninguna cuadrilla ese día → **404** (la app ya lo muestra como
"No estás asignado a un camión", sin error rojo).

### 3. Alcance de lectura por vehículo para el ayudante
`EnsureVehicleCrew` ya deja pasar a "chofer/ayudante de ESE vehículo el día" (403
`out_of_scope_assignment` si no). Confirmar que un usuario **rol `tripulante`** que es ayudante de la
cuadrilla del vehículo pasa en **GET** de solo lectura:
- `GET /app/vehicles/{id}/route?date=` (la hoja de ruta / paradas — es lo que consume la pantalla).
- `GET /app/fleet/my-crew`.
Solo lectura; no necesita ninguno de los POST de ejecución.

### 4. "Programados" (fechas futuras)
La app pide `my-crew?date=` y `vehicles/{id}/route?date=` con la fecha elegida. Para que el tripulante vea
un viaje **programado** basta con que la cuadrilla de esa fecha exista (el **auto-crew al publicar** ya la
arma para la fecha del plan). Confirmar que `my-crew?date=<futuro>` devuelve la cuadrilla assemblada de
ese día (no solo "hoy"). Si hoy `my-crew` ignora `date` y asume hoy, agregar el filtro por fecha.

### 5. (Opcional, para que el dueño pueda probar) usuario de prueba
`tripulante@dismac.test` / `password123`, sembrado como **ayudante** de una cuadrilla del
`TodayScenarioSeeder` (día de Santa Cruz), para ver la lista de envíos sin tener que asignarlo a mano.

## Notas de contrato
- **Sin cambios de shape de API** previstos: `my-crew` y `vehicles/{id}/route` ya tienen el shape que la
  app consume; el cambio es de **resolución/alcance** (quién puede leer) + el **enum de rol**. Si no
  cambia ningún `required`, **no hace falta regenerar el cliente** por este pedido.
- El tripulante **no asigna cuadrillas** (eso sigue siendo planner/chofer/admin/supervisor, pedido aparte).
  Ver [[crew-contract-and-route-visibility]] y `2026-11-14-ciudades-alcance-por-rol-y-consulta.md`.
