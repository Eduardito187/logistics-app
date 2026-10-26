---
name: github-pr-flow
description: Branch, commit, push, PR and CI workflow for the Dismac logistics repos on GitHub (logistics-app on Windows at C:\Users\ehhuallata\Documents\APP\logistics-app; backend logistics in WSL), where there is no gh CLI. Use it whenever the user asks to commit, push, open/retitle a PR, check or debug CI ("el pipeline falla", "crea el PR", "sube esto", "ordená los commits", "por qué falló el check"), promote dev → staging → production, set up release signing secrets, or when a commit/PR text contains accents or ñ.
---

# Flujo de ramas, commits, PRs y CI — logistics

## Reglas que no se negocian

1. **No commitear ni pushear sin que el usuario lo pida en ese turno** (un OK anterior no vale para los
   cambios siguientes; pedir "cerrá todo / ordená commits y PR" sí cuenta como pedido). **Avisar SIEMPRE
   toda acción de git apenas se hace, con el hash corto** — nada de commits silenciosos: el dueño perdió
   confianza por eso una vez. Ante la duda, preguntar primero.
2. **Flujo de ramas** (lo vigila `.github/workflows/branch-policy.yml`):
   ```
   feature/* | fix/* | chore/*  ──PR──▶  dev  ──PR──▶  staging  ──PR──▶  production
   hotfix/*  ──PR──▶  production (luego se baja a staging y dev)
   ```
   Nunca push directo a `dev`, `staging` o `production`.
3. **Mensajes:** `DIS-XXXX | Descripción en español` (DIS-0000 si no hay ticket), cuerpo con viñetas
   y la línea `Co-Authored-By` que indique el sistema.
4. **UTF-8 de punta a punta.** Mensajes y textos de PR SIEMPRE en archivos UTF-8 (`git commit -F archivo`).
   Nunca acentos/ñ literales dentro de un `.ps1`: PowerShell 5.1 lee los scripts sin BOM como Windows-1252 y
   "logística" llega como "logÃ­stica" (con squash merge eso queda en el historial).
5. **Secretos nunca al repo.** Antes de cada commit:
   ```bash
   git status --porcelain --untracked-files=all | grep -iE "key\.properties|\.jks|keystore|\.p12|\.p8|google-services|GoogleService|\.env"
   git ls-files | grep -ciE 'key\.properties|\.jks$|keystore/|\.p12$'   # debe dar 0
   ```
   `android/key.properties` y `android/keystore/` están en `.gitignore`. Si algo aparece: frenar y avisar.

## Entorno de esta máquina

- **logistics-app vive en Windows** (`C:\Users\ehhuallata\Documents\APP\logistics-app`): commits y push con el
  Git de Windows (Git Credential Manager tiene la credencial). No hay `gh`.
- **logistics (backend) vive en WSL** (`/dismac/logistics`, `\\wsl.localhost\Ubuntu-22.04\dismac\logistics`): commits
  desde WSL (`git -C /dismac/logistics commit -F /ruta/msg.txt`) y push con el Git de Windows sobre la ruta UNC
  (el Git de WSL no tiene credenciales).
- **El push puede quedar bloqueado por el modo de permisos de Claude Code** (publicación externa). No buscar
  atajos: dejar los commits hechos, escribir título/descripción del PR en archivos y darle al usuario los
  comandos exactos (`git push …` + `create-pr.ps1 …`). Si no hay credencial guardada, el usuario hace UN
  `git push` en su terminal y autoriza en el navegador.

## Ordenar muchos cambios en commits

Cuando hay cientos de archivos sin commitear, agrupar por área (un commit por grupo, en este orden):
plataforma (`android ios linux pubspec.* config .github .gitignore Makefile third_party tool`), cliente API
(`lib/core/api openapi`), núcleo (`lib/core lib/main.dart lib/app.dart test/core test/support`), features
(`lib/features test/features test/widget_test.dart`), e2e (`integration_test`), docs/tooling (`docs scripts .claude CLAUDE.md README.md`).
Hacerlo con un script (Python con `git add -A -- <rutas>` + `git commit -F <tmp UTF-8>`) y terminar con
`git status` limpio y `git log --oneline` para verificar los acentos.

## Crear un PR

1. Título en un `.txt` y descripción en un `.md` (UTF-8, fuera del repo, p. ej. `%TEMP%`). La descripción sigue
   `.github/PULL_REQUEST_TEMPLATE.md`: Contexto, Cambios, Cómo probar, Tests (con números), Impacto. Terminar con
   la línea de atribución que indique el sistema.
2. Ejecutar (PowerShell, desde la raíz del repo):
   ```powershell
   & .claude\skills\github-pr-flow\scripts\create-pr.ps1 -Repo logistics-app -Head feature/x -Base dev -TitleFile "$env:TEMP\pr_title.txt" -BodyFile "$env:TEMP\pr_body.md"
   ```
   El script lee UTF-8, envía bytes UTF-8 y **falla si GitHub guardó mojibake**. Corregir solo el título:
   `-Number <n> -TitleFile …`. Si da ExecutionPolicy: `powershell -NoProfile -ExecutionPolicy Bypass -File …`.
   Para el backend (repo en WSL) pasar rutas Windows absolutas a los textos, no rutas UNC (`Resolve-Path` falla).

## CI de logistics-app (`.github/workflows/ci.yml`)

| Job | Cuándo | Qué hace |
|---|---|---|
| `analyze-test` | push/PR | Flutter **3.32.0**: `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test` |
| `build-apk` | tras analyze-test | APK debug como artefacto |
| `release-apk` | push a `main`/tags `v*` | Reconstruye keystore desde secrets, `--split-per-abi` (main→staging, tag→production), verifica firma con apksigner |
| `ios-build` | push/PR | macOS, `flutter build ios --release --no-codesign` |

Secrets para `release-apk`: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` (`upload`),
`ANDROID_KEY_PASSWORD` (cómo generarlos: `docs/release.md`). Si `dart format` falla en CI pero no en local: se
formateó con otro Dart (usar `C:\flutter`, 3.32).

## Revisar el CI

- Estado (una lectura, sin polling): `& .claude\skills\github-pr-flow\scripts\ci-status.ps1 -Repo logistics-app -Branch feature/x`
- Log del job fallido: `& .claude\skills\github-pr-flow\scripts\ci-log.ps1 -Repo logistics-app -Branch feature/x`
- Antes de culpar al CI, reproducir con un **clon limpio**: lo no versionado no existe en el runner (caso real:
  `tests/Unit` vacío no viaja en git y Pest corta con exit 2).

## Promover entre entornos

PR `dev → staging` y luego `staging → production` con el mismo `create-pr.ps1` (`-Head dev -Base staging`).
Un `hotfix/*` en production se baja con PRs `production → staging` y `staging → dev`.

## Pendiente (requiere OK explícito del usuario)

- Protección de ramas (`dev`, `staging`, `production`): solo vía PR y con CI verde.
- Rama por defecto: hoy es `production`; lo usual con este flujo es `dev`.
