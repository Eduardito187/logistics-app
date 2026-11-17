---
name: patch-scripts-and-shell-traps
description: "En esta PC los heredocs de Git Bash se rompen con comillas/backticks: los scripts de parche se escriben con la herramienta Write al scratchpad y se corren con python; el crash 'add_item ... errno 1' de bash es transitorio"
metadata:
  type: feedback
---

Para cambios en muchos archivos uso un script de Python (reemplazos exactos con `assert count == 1`,
conservando CRLF). Ese script se escribe con la herramienta **Write** en el scratchpad y se corre con
`python <ruta>`; NO por heredoc de Bash.

**Why:** varias veces (15-nov-2026) el heredoc falló con "unexpected EOF while looking for matching `'`" por
las comillas y `$` del código Dart, y hubo que rehacer el envío entero. Además Git Bash a veces muere con
`fatal error - add_item ("\\??\\C:\\...\\Git", "/", ...) failed, errno 1`: es transitorio, alcanza con
repetir el comando (verificar antes si el paso anterior llegó a aplicarse).

**How to apply:** scripts de parche y consultas SQL largas → archivo en el scratchpad. La suite completa se
corre con `flutter test --no-pub --reporter json > $TEMP/flutter_test.json` y se resume con Python (un solo
proceso de Flutter a la vez). `pumpAndSettle` NO avanza timers: tras un evento con debounce hay que hacer
`tester.pump(Duration(...))` primero. Ver [[test-battery-and-infra]].
