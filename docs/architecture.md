# Arquitectura — logistics-app

## Qué es

La app interna de la plataforma logística. Una sola app; la vista depende del rol con el que se inicia
sesión. Se distribuye por Managed Google Play (app privada), no en la tienda pública.

| Rol | Qué hace en la app |
| --- | --- |
| Chofer | Checklist pre-salida, ruta del día, navegación con un toque, descarga guiada, prueba de entrega, entregas fallidas |
| Preparador / andén | Escanear EAN → imprimir etiqueta → carril; carga validada del camión |
| Tienda | Recepción contra manifiesto, ubicación en estante, entrega en mostrador (recojo) |
| Transportista externo | Escanear al recoger y al entregar con las mismas etiquetas |
| Supervisor | Vista de ruta y alertas en campo |

## Principios

1. **Offline-first.** Cada escaneo se guarda en la base local (SQLite) con un ID idempotente y se
   sincroniza cuando hay red. Nunca se bloquea un escaneo por falta de señal.
2. **Etiquetas verificadas sin internet.** La app trae las claves públicas Ed25519 y valida la firma
   del QR en el momento (ver `lib/core/labels/`).
3. **Contrato generado.** El cliente de la API sale de `openapi/v1.yaml` del backend.
4. **Hardware de campo.** Impresión ZPL a Zebra (ZQ630 Plus) por Bluetooth o WiFi; escaneo con cámara
   o con pistola Zebra (DataWedge).

## Stack

| Pieza | Elección |
| --- | --- |
| Estado | Riverpod (Notifier) |
| Navegación | go_router, con redirección por rol |
| HTTP | Dio |
| Base local | Drift (SQLite) — se agrega con el primer flujo offline |
| Credenciales | flutter_secure_storage |
| Firma | cryptography (Ed25519) |
| Escaneo | mobile_scanner + intents de DataWedge — se agrega con el flujo de preparación |
| GPS en segundo plano | flutter_background_geolocation (licencia paga) — se agrega con la ruta del chofer |
| Impresión | Zebra Link-OS SDK vía platform channel, o ZPL por Bluetooth / TCP 9100 |
| Push interno | Firebase Cloud Messaging (proyecto Firebase propio, distinto al de la app de clientes) |

## Estructura

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── config/      # AppConfig: URL de la API, claves públicas (por --dart-define)
│   ├── auth/        # UserRole, sesión
│   ├── router/      # go_router + redirección por rol
│   ├── theme/       # tema con objetivos táctiles grandes
│   └── labels/      # QR firmado: payload, parseo, verificación Ed25519
└── features/
    ├── auth/        # inicio de sesión
    └── home/        # pantalla de inicio de cada rol
```

Los features de cada flujo (picking, loading, route, delivery, store_reception) se crean cuando se
construye ese flujo, cada uno con `data/`, `domain/` y `presentation/`.
