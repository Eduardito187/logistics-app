---
name: orphan-flutter-test-processes
description: "flutter test colgado 50 min = procesos `flutter test` huérfanos compitiendo; matarlos y correr con timeout, sin pipes"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 492c7f11-2580-4e33-b81b-40e2ffbb8541
  modified: 2026-11-12T00:21:52.750Z
---

Si `flutter test` tarda muchísimo o queda en "loading … [E]" (normal: ~6 min la suite completa), casi seguro hay procesos `flutter test` huérfanos (de agentes paralelos o de un TaskStop que mató solo el shell) peleando por CPU y `build/`. Revisar con `Get-CimInstance Win32_Process` (cmdline termina en ` test`) y matar esos + su `frontend_server_aot`; NO matar language-server/daemon de VS Code ni el `flutter run` de fvm 3.38 (otro proyecto).

**Why:** nov 2026 el usuario vio una corrida de 50 min ("esta porquería") por esto; con agentes en paralelo corriendo tests, algunos quedaron vivos.

**How to apply:** correr la suite con `Start-Process flutter test --reporter json -RedirectStandardOutput` + `WaitForExit(570000)` y resumir con python; nunca `flutter test | Select-String | Select-Object -First N` (deja el proceso colgado). Ver [[test-battery-and-infra]], [[parallel-agents-method]].
