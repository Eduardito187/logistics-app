---
name: app-scope-backend-consumer
description: La app Flutter SOLO consume el backend; nunca integra servicios externos ni depende de deploy/credenciales/hardware.
metadata:
  node_type: memory
  type: feedback
  originSessionId: 09382079-47de-4656-9b51-88ca4bb40fff
  modified: 2026-10-15T06:42:01.834Z
---

El dueño corrigió con énfasis: el ÚNICO trabajo de `logistics-app` es **consumir la API `/app/*` del backend**. La app **nunca** conecta SMS, Telegram, SAP, Magento, tiles, etc. — eso es responsabilidad del backend y de su despliegue.

**Why:** listar "credenciales de servicios externos / deploy / datos de Fase 0 / hardware" como si fueran faltantes de la app es un error de encuadre que lo frustra. Esos son desbloqueos del backend/ops, no de la app.

**How to apply:** al evaluar si la app está "completa", medí **cobertura de endpoints `/app/*` consumidos**, no servicios externos. Para "completo" el dueño quiere **cobertura total de la API**, no un MVP ni un piloto. Lo único que la app legítimamente NO consume es `verifyLabel` (la etiqueta se verifica **offline** Ed25519 por diseño). Ver [[app-api-coverage-state]].
