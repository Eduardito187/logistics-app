# Live Update congelada, foto de productos y tamaño de la isla (pruebas en terreno)

**Fecha:** 2026-11-13 · **Pide:** app interna (chofer) · **Para:** backend `logistics`
**Prioridad:** media (depende del mismo deploy de tracking ya pedido).

De las pruebas del dueño en el teléfono (3 capturas). Separo lo accionable del backend de lo
que es del sistema operativo.

## 4. 🔴 (backend) Live Update "Parada 1 de 7" congelada + "solo 4 puntos" estando en 6/7

La notificación en vivo (Android 16 Live Update) muestra la parada y el avance equivocados: dice
"Parada 1 de 7 · Llega 08:15" y 4 puntos atendidos cuando el chofer ya entregó 6 de 7.

**Verificado:** el render nativo es correcto — dibuja `segmentos = stopCount` y
`puntos = completed` (tope 15, no es el límite). La app ya manda el avance **item por item**
(estado efectivo). La causa es de DATOS: al **reiniciar la app** se pierde el avance resuelto que
vive en memoria (la cola offline aún no sincronizó), y el **route sheet del backend —sin el deploy
de #1/#2— devuelve todo pendiente, `current_stop` = parada 1 y `completed_stops` desfasado**. Así,
tras un restart, tanto la pantalla como la Live Update vuelven al estado del backend (parada 1).

**Acción backend:** entra con el **deploy de [tracking-entrega-conteo-reruteo](2026-11-13-tracking-entrega-conteo-reruteo.md)**
(#1 el POD avanza el tracking, #2 `completed_stops` = sólo entregadas). Con el route sheet
reflejando las entregas, el restart ya no revierte y la Live Update muestra la parada/avance
reales. No hace falta nada nuevo: **confirmar que va en el mismo deploy.** (Alternativa del lado
app, no hecha por ser redundante tras el deploy: persistir el avance local para que sobreviva al
restart.)

## 6. (backend/catálogo) Fotos de producto vacías en el detalle del pedido

`DriverRouteStop.items[].image_url` (y `ShipmentLine.image_url`) vienen **null** para varios SKU
(ej. `COL-QUEEN-ORT` "Colchón ortopédico Queen", `BAS-QUEEN` "Base box Queen") → en la app salen
cuadros grises (placeholder). El contrato ya tiene `image_url`; falta **poblarlo desde el catálogo
/ SAP**.

**Acción backend/ops:** poblar `image_url` de esos productos, o confirmar que es gap del catálogo
(no es código del app; la app ya muestra la foto cuando la URL llega).

## 5. (NO backend — sistema operativo) Tamaño de la "isla"/pastilla alrededor de la cámara

El dueño pide que la pastilla alrededor de la cámara sea más compacta ("muy grande y vacía"). Esa
pastilla la **dibuja el sistema operativo** (Android 16 Live Update / Dynamic Island de iOS) a
partir de nuestra notificación; **ni el backend ni la app controlan su tamaño ni cómo envuelve la
cámara** (lo decide el fabricante/SO). La pastilla PROPIA de DisTrack (`IslandOverlay`, overlay)
sí es ajustable, pero las capturas eran la del sistema (se ve por la barra de progreso con puntos
del `ProgressStyle` del SO). **No hay acción de backend acá**; se deja anotado para que quede claro
que no es un pendiente del servidor.

## Lado app (ya hecho)

Conteo de la Live Update item por item; distancia de la notificación a 10 s ("tiempo real");
evidencia del cliente deduplicada por tipo (el backend grababa una por unidad → firma/documento
repetidos); leyenda del mapa quitada (los colores ya están en los marcadores).
