---
name: backend-coordination
description: Coordinate work between the Dismac logistics app (this repo) and its backend — hand a need to the backend session, define an API or event contract, implement the app against a contract that is not deployed yet, diagnose whether a bug is in the app or in the backend's data, and report what is done vs. waiting on the backend. Use it whenever the user says "derivá esto al backend", "comunicate con el backend", "pedile al backend", "lo que necesites del backend", "eso es del backend", when a screen shows data that looks wrong ("no coincide", "sale duplicado", "dice 2 de 31"), or when a feature needs an endpoint, field or socket event that does not exist yet.
---

# Trabajar con el backend — logistics-app

La app **solo consume** el backend (`/api/v1/app/*`). Cuando falta un endpoint, un campo o un evento, o
cuando los datos llegan mal, el arreglo se **deriva al backend** y la app se completa de su lado contra un
contrato claro. El dueño quiere las dos cosas a la vez: "derivale al backend lo que necesites, pero vos
completá de tu lado al 100%".

## Dónde está cada cosa

- Backend vigente (SOLO LECTURA): `C:\Users\ehhuallata\Documents\APP\logistics` — spec en `openapi\v1.yaml`,
  rutas en `routes/api/*.php`. Puede tener cambios sin commit de la sesión del backend.
- La sesión del backend es otro Claude en esta PC. `ListAgents` la muestra; se le escribe con `SendMessage`
  (cargar la herramienta con `ToolSearch` → `select:SendMessage`). Responde sola cuando termina.
- Pedidos por escrito: `docs/backend-requests/AAAA-MM-DD-tema.md` + fila en su `README.md`.
- Staging: los datos reales que ve el teléfono. El acceso está en la memoria de la PC
  (`staging-server-access`), no en el repo.

## Derivar un pedido

1. **Contrato primero, concreto.** Endpoint, método, cuerpo, respuesta con nombres de campo, códigos de
   error, y qué hace la app con cada uno. Para eventos: tema, nombre, payload, cuándo se emite.
2. **Con evidencia** si es un bug: ids reales, cantidades, lo que se esperaba. "La ruta X tiene 31 paradas
   y el plan Y tiene 7; las 8–31 no tienen coordenadas" vale más que "la ruta está mal".
3. **Mandarlo por `SendMessage`** (la primera línea es lo único que ve el humano en la vista previa: que
   diga de qué se trata) y dejarlo en `docs/backend-requests/`.
4. **Decir qué hace la app mientras tanto** (oculta la sección, usa respaldo, parche provisorio).
5. **Si el dueño da una instrucción para el backend** ("que lance un agente", "con Opus medium", "que no lo
   deje en cola"), se la paso TEXTUAL en el mensaje. No decido yo cómo trabaja el backend.
6. Cuando responde con nombres finales distintos, ajusto la app y actualizo doc y memoria.

No pedirle a la sesión del backend algo que a mí me fue negado o que mis permisos bloquean; eso vuelve al
dueño.

## Implementar contra un contrato que todavía no existe

- La app tiene que **degradar bien**: endpoint que da 404/405 → la sección no se muestra; tema que no viene
  en `channels` → la pantalla sigue como antes. Nunca una pantalla rota por algo sin desplegar.
- **Endpoint nuevo aparte, no un campo en uno existente**, cuando un backend viejo que ignore el campo haría
  algo peligroso. Caso real: bloquear una HORA mandando `time_slot` a `/delivery-calendar/blocked` habría
  bloqueado el día entero → se pidió `/blocked-slots`.
- Llamadas a endpoints que aún no están en el cliente generado: Dio directo en el `data source`, leyendo el
  mapa a un tipo de dominio (no un DTO a mano). Cuando el spec los traiga, regenerar el cliente.
- Tests con fakes del `data source`: el contrato queda probado aunque el backend no exista.
- **UN SOLO regen coordinado** cuando el backend tiene mucho spec en vuelo: regenerar el cliente trae TODO lo
  acumulado de una (acopla trabajo no desplegado, puede renumerar tipos anónimos). Acordar con el backend una
  señal **"SPEC ESTABLE"**: él avisa cuando su openapi deja de moverse (o cuando el dueño va a commitear/
  desplegar) y pasa el resumen de todo lo que entró desde el último regen; recién ahí se regenera una vez y se
  cablea todo junto. Mientras, consumir lo nuevo con Dio directo o esperar. Un campo que el backend hizo
  **requerido** rompe la app contra el staging viejo (parseo) → desplegar backend + app juntos, o pedir que
  sea nullable. Detalle del regen en el skill **flutter-feature**.

## ¿Es de la app o del backend? Medir antes de tocar

1. Mirar el dato real. En staging, **solo lectura** (`SET default_transaction_read_only = on`); tablas
   útiles: `fleet_crews`, `execution_driver_routes`, `execution_driver_route_stops`, `planning_plans`,
   `planning_plan_stops`. La base local de Docker NO es la que usa el teléfono.
2. Si el dato ya viene mal del servidor, **la app no lo "arregla" escondiéndolo**: se deriva. Lo que sí
   puede hacer la app es un parche que evite generar más datos malos (p. ej. borrar la tripulación de hoy
   antes de asignar otra), dicho como parche.
3. No hacer login de diagnóstico con una cuenta que el dueño está usando en el teléfono: hay una sesión
   activa por tipo de cliente y lo desloguea.
4. **Nunca mutar** datos de staging ni etiquetas (ver memoria `no-label-mutations-rule`).

## Reportarle al dueño

Separar siempre tres cosas, con el estado real de cada una:

- **Hecho en la app** (y verificado: `flutter analyze` + `flutter test` con números).
- **Espera al backend:** qué pidió, qué respondió (aceptado / en curso / pausado / terminado sin deploy).
- **Tuyo:** el deploy a staging lo hace el dueño; lo que no se probó en el teléfono.

"La app ya lo tiene" no es "ya funciona": si el backend no lo emite o no está desplegado, decirlo en la
primera frase. No repetir como pendiente algo que el dueño descartó.

## Gotchas

| Situación | Qué hacer |
| --- | --- |
| El backend "aceptó" y lo puso en cola | Avisarle al dueño; si quiere, reenviar con su instrucción de prioridad |
| La sesión del backend avisa que el dueño PAUSÓ el trabajo | Mantener el parche de la app y decirlo; no dar por hecho el arreglo |
| El backend cambió nombres de canal/evento respecto del pedido | Tomar los suyos (los canales salen de `channels`), ajustar tests y doc |
| Staging no tiene lo último | Normal: el backend no despliega, despliega el dueño |
| Un 404 nuevo viene como `application/problem+json` | La app ya lee `detail ?? error.message`; ramificar por `code` |
