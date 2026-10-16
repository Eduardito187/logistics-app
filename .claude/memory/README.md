# Memorias del proyecto (espejo versionado)

Las memorias de Claude Code viven FUERA del repo, en `~/.claude/projects/<slug>/memory/`
(`<slug>` = ruta absoluta del proyecto con los separadores vueltos `-`). Por eso NO son
portables: al mover el proyecto a otra ruta u OS, el slug cambia y "desaparecen".

Esta carpeta es un **espejo versionado** de esas memorias (viaja con git). Las skills
(`.claude/skills/`) ya son portables de por sí; esto resuelve solo las memorias.

## Al mover/clonar el proyecto (p. ej. a Windows nativo)

Correr el instalador UNA vez; calcula el slug de la ruta actual y copia las memorias al
dir del usuario de esa máquina:

- Windows (PowerShell):  `.\.claude\memory\install.ps1`
- Linux / WSL / macOS:   `bash .claude/memory/install.sh`

## Si editás las memorias (vía Claude) y querés versionarlas

Re-exportá del dir del usuario a este espejo y commiteá:

- Windows:  `.\.claude\memory\install.ps1 -Export`
- Linux/WSL/macOS:  `bash .claude/memory/install.sh --export`
