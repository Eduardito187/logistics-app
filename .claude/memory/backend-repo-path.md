---
name: backend-repo-path
description: El backend vigente está en C:\Users\ehhuallata\Documents\APP\logistics (Windows); ~/dismac/logistics de WSL es una copia VIEJA (13-oct) — no usarla
metadata:
  type: reference
---

Repo backend vigente (nov 2026, migrado a Windows): `C:\Users\ehhuallata\Documents\APP\logistics` (WSL: `/mnt/c/Users/ehhuallata/Documents/APP/logistics`). Spec para regenerar el cliente: `openapi/v1.yaml` de ahí (`scripts/regen_api_client.ps1 -Spec <ruta>`).

`~/dismac/logistics` en WSL es la copia anterior a la migración (HEAD 56ee7b9, 13-oct): NO usarla para leer código ni contratos. Staging corre en OCI (ver [[staging-server-access]]).

**How to apply:** la sesión del backend (`logistics-2d` o su nombre vigente) trabaja en ese árbol con cambios sin commitear: solo LECTURA desde la app, nunca editarlo.
