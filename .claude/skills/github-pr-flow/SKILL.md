---
name: github-pr-flow
description: Branch, commit, push, PR and CI workflow for the Dismac logistics repos (logistics, logistics-app) on GitHub from this Windows+WSL machine, where there is no gh CLI. Use it whenever the user asks to commit, push, open/retitle a PR, check or debug CI ("el pipeline falla", "crea el PR", "sube esto", "por qué falló el check"), promote dev → staging → production, or when a commit/PR text contains accents or ñ.
---

# Flujo de ramas, commits, PRs y CI — logistics

## Reglas que no se negocian

1. **No commitear ni pushear sin que el usuario lo pida en ese turno.**
2. **Flujo de ramas** (lo vigila `.github/workflows/branch-policy.yml`):
   ```
   feature/* | fix/* | chore/*  ──PR──▶  dev  ──PR──▶  staging  ──PR──▶  production
   hotfix/*  ──PR──▶  production (luego se baja a staging y dev)
   ```
   Nunca push directo a `dev`, `staging` o `production`.
3. **Mensajes:** `DIS-XXXX | Descripción en español` (DIS-0000 si no hay ticket), cuerpo con viñetas
   y la línea `Co-Authored-By` que indique el sistema.
4. **UTF-8 de punta a punta.** Acentos y ñ nunca como literal dentro de un `.ps1`: PowerShell 5.1 lee
   los scripts sin BOM como Windows-1252 y "logística" llega a GitHub como "logÃ­stica". Con squash
   merge ese título se vuelve el mensaje del commit. Todo texto va en archivos UTF-8.

## Entorno de esta máquina

- No hay `gh`. La credencial de GitHub vive en **Git Credential Manager de Windows**.
- El Git de WSL no tiene credenciales → **commits desde WSL, push con el Git de Windows**:
  ```bash
  # WSL: commit con mensaje desde archivo UTF-8
  git -C /dismac/logistics-app commit -F /ruta/mensaje.txt
  ```
  ```powershell
  # Windows: push sobre la ruta UNC
  git -C "\\wsl.localhost\Ubuntu-22.04\dismac\logistics-app" push -u origin feature/x
  ```
- Si no hay credencial guardada, el push no puede pedir login (las herramientas no son interactivas):
  pedirle al usuario que haga **un** `git push` en su propia terminal y autorice en el navegador.

## Crear un PR

1. Escribir el título en `title.txt` y la descripción en `body.md` (UTF-8). La descripción sigue
   `.github/PULL_REQUEST_TEMPLATE.md`: Contexto, Cambios, Cómo probar, Tests (con números), Impacto.
   Terminar el cuerpo con la línea de atribución que indique el sistema.
2. Ejecutar:
   ```powershell
   & .claude\skills\github-pr-flow\scripts\create-pr.ps1 -Repo logistics-app -Head feature/x -Base dev -TitleFile title.txt -BodyFile body.md
   ```
   El script lee los textos como UTF-8, envía bytes UTF-8 y **falla si GitHub guardó mojibake**.
3. Corregir solo el título: `-Number <n> -TitleFile title.txt`.

## Revisar el CI

- Estado (una sola lectura, sin loops ni polling):
  ```powershell
  & .claude\skills\github-pr-flow\scripts\ci-status.ps1 -Repo logistics-app -Branch feature/x
  ```
- Log del job fallido (muestra el paso anterior a `##[error]`, que es donde está la causa):
  ```powershell
  & .claude\skills\github-pr-flow\scripts\ci-log.ps1 -Repo logistics-app -Branch feature/x
  ```
- Antes de culpar al CI, reproducir con un **clon limpio**: lo que no está versionado no existe en el
  runner. Caso real: `tests/Unit` vacío no viaja en git y Pest corta con
  `Test directory ".../tests/Unit" not found` (exit 2) aunque en local pase todo.

## Promover entre entornos

PR `dev → staging` y luego `staging → production`, con el mismo `create-pr.ps1` (`-Head dev -Base staging`).
Un `hotfix/*` que entra a production se baja después con PRs `production → staging` y `staging → dev`
(o merge directo de production en dev vía PR).

## Pendiente (requiere OK explícito del usuario)

- Protección de ramas (`dev`, `staging`, `production`): solo vía PR y con CI verde.
- Rama por defecto: hoy es `production` (fue la primera en subirse); lo usual con este flujo es `dev`.
