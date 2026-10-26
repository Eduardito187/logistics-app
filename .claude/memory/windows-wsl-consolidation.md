---
name: windows-wsl-consolidation
description: Oct 2026 - se consolidó el proyecto en el repo WSL /dismac/logistics-app; el checkout de Windows (C:\...\APP\logistics-app) se borró a pedido del dueño
metadata:
  node_type: memory
  type: project
  originSessionId: 09382079-47de-4656-9b51-88ca4bb40fff
  modified: 2026-10-26T05:24:44.044Z
---

El 2026-10-26 se unificaron las dos copias divergidas de `feature/initial-scaffold`:
- **WSL `ee13a0f`** (rebrand DisTrack + rediseño de navegación flotante + padding).
- **Windows `ff6be51`** ("APP flutter": clientes API, feature de productos, 2FA+reset, fase de performance/prefetch/escáner continuo, filtro GPS plausible, paginación de avisos, plataforma `windows/`).

Merge-**unión** hecho en WSL (commit `8b4c04a`, padres `ee13a0f`+`ff6be51`) + limpieza de 6 huérfanos pre-existentes (`071d253`). En los 22 conflictos reales ganó WSL en lo visual/branding y se preservó la funcionalidad de Windows (regla del dueño: "respetar este repo" + "sin perder funcionalidades"). `flutter analyze` limpio, **1946 tests verdes**. Pusheado a `origin` (ver [[git-push-from-wsl]]).

A pedido del dueño se **borró por completo el checkout de Windows** `C:\Users\ehhuallata\Documents\APP\logistics-app`. El trabajo de Windows quedó preservado en `origin` (ff6be51 es padre del merge). El estado no commiteado de Windows (su intento de merge a medias, ~50 archivos híbridos) se archivó en `~/.claude/projects/-dismac-logistics-app/windows-merge-backup-20261026/` (patch + copias). Desde entonces, trabajar SOLO en el repo WSL; si se quiere Windows de nuevo, re-clonar de `origin`.

Relacionado: [[windows-native-toolchain]], [[git-push-from-wsl]], [[parallel-agents-method]].
