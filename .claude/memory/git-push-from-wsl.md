---
name: git-push-from-wsl
description: WSL no tiene credenciales de GitHub; pushear usando el git.exe de Windows apuntado al repo WSL por ruta UNC (wslpath -w)
metadata:
  node_type: memory
  type: reference
  originSessionId: 09382079-47de-4656-9b51-88ca4bb40fff
  modified: 2026-10-26T05:24:28.581Z
---

El repo WSL `/dismac/logistics-app` tiene `origin` en HTTPS pero **WSL no tiene credenciales de GitHub** (no hay credential.helper, no hay `~/.git-credentials`, y la clave SSH `~/.ssh/id_ed25519.pub` NO está autorizada en GitHub → `Permission denied (publickey)`). Un `git push` desde WSL pide usuario y falla.

**Las credenciales viven en el Git Credential Manager de Windows.** El git.exe de Windows está en:
`/mnt/c/Users/ehhuallata/AppData/Local/Programs/Git/cmd/git.exe`

**Para pushear desde WSL sin tocar el working tree de Windows**, correr el git.exe de Windows apuntando al repo WSL por su ruta UNC:
```bash
GITEXE="/mnt/c/Users/ehhuallata/AppData/Local/Programs/Git/cmd/git.exe"
UNC=$(wslpath -w /dismac/logistics-app)   # -> \\wsl.localhost\Ubuntu-22.04\dismac\logistics-app
"$GITEXE" -C "$UNC" push origin feature/initial-scaffold
```
Usa el Credential Manager de Windows para autenticar. Verificado 2026-10-26.

Alternativa a futuro: registrar la clave SSH de WSL en GitHub y pasar `origin` a SSH.

Relacionado: [[git-communication-rule]], [[windows-native-toolchain]], [[windows-wsl-consolidation]].
