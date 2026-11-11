---
name: portable-memory-skills
description: Cómo viajan skills y memorias al mover el proyecto (p. ej. a Windows fuera de WSL)
metadata:
  node_type: memory
  type: project
  originSessionId: 09382079-47de-4656-9b51-88ca4bb40fff
  modified: 2026-10-16T05:07:19.201Z
---

El dueño quiere poder mover el proyecto (incluido a Windows nativo, fuera de este WSL) y seguir teniendo skills + memorias.

**Skills: ya portables.** Viven en el repo (`.claude/skills/*`), viajan con git y Claude Code las lee desde cualquier OS. (Los scripts de `github-pr-flow` son `.ps1` de Windows a propósito.)

**Memorias: NO son portables por defecto.** Viven FUERA del repo en `~/.claude/projects/<slug>/memory/`, donde `<slug>` = ruta absoluta del proyecto con los separadores vueltos `-` (acá `/dismac/logistics-app` → `-dismac-logistics-app`). Al mover el proyecto a otra ruta/OS, el slug cambia y las memorias "desaparecen".

**Solución montada:** hay un espejo versionado en el repo `.claude/memory/` (copia de todos los `.md` + `MEMORY.md`) y un instalador que las copia al dir de memoria del usuario calculando el slug de la ruta actual:
- Windows (PowerShell): `.\.claude\memory\install.ps1`
- Linux/WSL/macOS: `bash .claude/memory/install.sh`

Flujo al mover el proyecto: clonar/mover → correr el instalador una vez → memorias disponibles en la nueva máquina. Si se agregan/editan memorias en `~/.claude/.../memory/`, re-sincronizar al repo con la bandera `--export` del mismo script (o copiar a mano) y commitear, para que el espejo no quede viejo. CLAUDE.md tiene el apuntador.
