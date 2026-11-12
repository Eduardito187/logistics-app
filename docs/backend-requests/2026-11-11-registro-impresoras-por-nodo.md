# Registro central de impresoras de red por nodo (sede/andén/tienda)

**Fecha:** 2026-11-11 · **Pedido por:** app (sesión `logistics-app-f4`) · **Backend:** sesión vigente
**Prioridad:** alta (sin esto, en redes corporativas el WiFi no "ve" las impresoras)
**Estado:** pendiente

## Contexto

La app imprime etiquetas ZPL en Zebra por Bluetooth, USB o WiFi (socket TCP 9100). Para WiFi tiene
búsqueda automática (barrido de la subred real + Bonjour/mDNS + WS-Discovery) e ingreso manual por IP.

Caso real del dueño: el teléfono está en el WiFi `10.168.50.x`; la impresora en la red cableada
`192.168.2.x`. Windows la tiene porque **sistemas la cargó a mano por IP**, no porque la descubra. En
redes con WiFi y cable separados (VLANs), ningún descubrimiento desde el teléfono puede encontrarla: el
multicast/broadcast no cruza de red. Lo que escala a todas las sedes es que la impresora esté
**registrada una vez** y la app la ofrezca.

## Pedido

Catálogo de impresoras administrado en el panel (Filament) por nodo, y endpoint de lectura para la app.

```yaml
# GET /api/v1/app/printers  (token de app; filtra por el nodo del usuario si lo tiene, si no todas las activas)
200:
  data:
    - id: string (uuid)
      name: string            # "Zebra Andén 2"
      model: string|null      # "ZD421-300dpi"
      host: string            # IP o hostname
      port: integer           # default 9100
      language: zpl|other     # la app solo ofrece por defecto las zpl
      node_id: integer|null
      location: string|null   # "Andén 2, junto a la balanza"
```

- Panel: alta/baja/edición (nombre, modelo, host, puerto, lenguaje, nodo, ubicación, activo).
- Que quede en `openapi/v1.yaml` para regenerar el cliente (regla #5 de la app).

## Criterio de aceptación

- Un usuario de un nodo ve sus impresoras; supervisor/admin ve todas.
- Cambiar la IP en el panel se refleja en la app sin reinstalar (la app re-lee al abrir Ajustes →
  Impresora).

## Lado app (cuando esté)

Sección "Impresoras de tu sede" arriba de la búsqueda WiFi: tocar = guardar como activa. La búsqueda
automática y la IP manual siguen como alternativa. Nota de red: si el WiFi no tiene ruta a la red de la
impresora, sistemas debe habilitarla (firewall/ACL al puerto 9100) — la app lo diagnostica en
"Probar conexión".
