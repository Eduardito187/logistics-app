# Regla de presentación: productos con nombre + SKU (nunca "bulto")

**De:** backend (`logistics`) · **Para:** app interna (logistics-app)
**Fecha:** 2026-10-23 · **Prioridad:** media (es presentación; el contrato NO cambia)

## Contexto

Se está unificando el lenguaje de producto en toda la plataforma. En texto visible al usuario:

- **Nunca** usar la palabra **"bulto"** (ni "Bulto"/"bultos"). Usar **"producto"** para el artículo del
  pedido y **"unidad"** cuando se habla de la pieza física concreta.
- **Donde se liste un producto** (items de una parada, unidades de tracking, detalle de pedido, etc.) se
  muestra **nombre del producto + SKU**, nunca `null`, vacío ni un guion ("—").

El backend ya aplicó esto en su lado (traducciones y email transaccional, que ahora muestra
**nombre + SKU** de cada producto).

## Qué debe hacer la app

En **toda pantalla** donde se muestren items/unidades de un pedido o envío:

1. **Mostrar nombre del producto + su SKU**, juntos (p. ej. el nombre en negrita y debajo/al lado
   `SKU: <sku>`). No mostrar solo la cantidad o solo la imagen sin identificar el producto.
2. **Nunca mostrar `null`, cadena vacía ni "—"** como nombre o SKU. Aplicar fallback:
   - si falta el **nombre** → usar el **SKU** como etiqueta; si tampoco hay SKU → el literal
     **"Producto"**;
   - si falta el **SKU** → no pintar la línea de SKU (nunca `null`), mostrando al menos el nombre.
3. **No usar la palabra "bulto"** en ninguna etiqueta, placeholder o mensaje. Usar "producto"
   (o "unidad" para la pieza física).

## El contrato NO cambia

Esto es **solo presentación**. Los campos del contrato siguen igual:

- Items de la parada: `sku`, `name`, `quantity`, `image_url` (sin cambios).
- Detalle de unidades de tracking: sin cambios.

La app no necesita tocar modelos ni llamadas; solo ajustar los widgets que pintan estos datos para
cumplir la regla de nombre + SKU y eliminar cualquier texto "bulto".
