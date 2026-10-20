# Release Android: firma, CI y seguridad

## Identidad de la app

| Campo | Valor | Nota |
|---|---|---|
| `applicationId` / `namespace` | `bo.com.dismac.logistics_app` | Definitivo. Cambiarlo = otra app (MDM, Firebase y datos locales no la reconocen). |
| `versionName` / `versionCode` | `version: x.y.z+N` de `pubspec.yaml` | Subir **N** en cada publicación. Con `--split-per-abi` Flutter suma 1000×ABI al código (armeabi-v7a 1xxx, arm64-v8a 2xxx, x86_64 4xxx). |

## Firma (keystore de subida)

`android/app/build.gradle.kts` lee `android/key.properties`:

```properties
storePassword=…
keyPassword=…
keyAlias=upload
storeFile=../keystore/upload-keystore.jks   # relativo a android/app
```

- `android/key.properties` y `android/keystore/` están en `.gitignore` (también `*.jks`, `*.keystore`).
  Verificar con `git check-ignore -v android/key.properties android/keystore/upload-keystore.jks`.
- **Sin `key.properties`** el release se firma con la clave de **debug** y Gradle avisa
  (`AVISO: no existe android/key.properties…`). Sirve para probar localmente, **no para distribuir**.
- Con `REQUIRE_RELEASE_SIGNING=true` (lo pone el job `release-apk` de CI) la falta de
  `key.properties` es un error, para que nunca salga un release firmado con debug.

### El keystore actual

Generado el 2026-10-16 en la PC de desarrollo:

- Archivo: `android/keystore/upload-keystore.jks` (PKCS12, RSA 4096, validez 10 000 días, alias `upload`).
- Contraseña: en `android/key.properties` (misma para el store y la clave).

> **Respaldarlo YA** (jks + key.properties) en un gestor de contraseñas/bóveda de la empresa,
> fuera de esta PC. Si se pierde, las actualizaciones ya instaladas no aceptan un APK firmado
> con otra clave: hay que desinstalar y reinstalar la app en cada equipo (se pierde la cola offline
> pendiente). Con Managed Google Play + Play App Signing, este es solo el *upload key* y se puede
> resetear desde la consola; con distribución directa/MDM es **la** clave de la app.

Huella SHA-256 del certificado: `65:EE:23:41:57:B1:B7:E8:C5:B8:D0:9F:F8:86:E9:28:2B:5F:39:A9:12:E9:16:D0:0C:2B:B9:76:26:66:AD:B5`.

Ver la huella (para Firebase / MDM):

```bash
keytool -list -v -keystore android/keystore/upload-keystore.jks -alias upload
```

### Generar uno nuevo (solo si no existe)

```bash
keytool -genkeypair -v -keystore android/keystore/upload-keystore.jks -storetype PKCS12 \
  -alias upload -keyalg RSA -keysize 4096 -validity 10000
```

y escribir `android/key.properties` como arriba.

## Compilar

```bash
make apk ENV=production          # = flutter build apk --release --split-per-abi --dart-define-from-file=config/production.json
# minSdk 24 => firma solo v2: keytool -printcert -jarfile no la ve, usar apksigner (build-tools)
apksigner verify --print-certs build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
#   Signer #1 certificate DN: CN=Dismac Logistica, OU=Tecnologia, O=Dismac, L=Santa Cruz, C=BO
#   Signer #1 certificate SHA-256 digest: 65ee234157b1b7e8c5b8d09ff886e9282b5f39a912e916d00c2bb9762666adb5
```

Una sola build a la vez (la RAM de la PC es justa, ver memoria de Gradle).

## CI (`.github/workflows/ci.yml`)

| Job | Cuándo | Qué hace |
|---|---|---|
| `analyze-test` | PRs y push | formato + analyze + tests |
| `build-apk` | PRs y push | APK **debug** (no necesita secrets) |
| `release-apk` | **solo push a `main` o tags `v*`** | APK release firmado, `--split-per-abi`. `main` → `config/staging.json`, tag `v*` → `config/production.json`. Verifica la firma con `apksigner` (falla si quedó la clave de debug) y sube los 3 APK como artefacto. |
| `ios-build` | PRs y push | `flutter build ios --no-codesign` en macOS (ver `docs/ios.md`) |

### Secrets a cargar en GitHub (Settings → Secrets and variables → Actions)

| Secret | Valor |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | el `.jks` en base64 (ver abajo) |
| `ANDROID_KEYSTORE_PASSWORD` | `storePassword` de `key.properties` |
| `ANDROID_KEY_ALIAS` | `upload` |
| `ANDROID_KEY_PASSWORD` | `keyPassword` de `key.properties` |

Base64 del keystore:

```powershell
# Windows (PowerShell) -> copia al portapapeles
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android\keystore\upload-keystore.jks")) | Set-Clipboard
```

```bash
# Linux/macOS/Git Bash
base64 -w0 android/keystore/upload-keystore.jks
```

El job reconstruye `android/keystore/upload-keystore.jks` y `android/key.properties` desde los
secrets y los borra al terminar (`if: always()`).

## Seguridad del APK

- **Sin backup**: `android:allowBackup="false"` + `res/xml/backup_rules.xml` (Android ≤ 11) y
  `res/xml/data_extraction_rules.xml` (Android 12+, nube y transferencia entre equipos) excluyen
  todo. La cola offline (Drift), los tokens (secure storage) y las fotos POD no salen del equipo
  ni se restauran en otro.
- **Solo HTTPS en release**: `res/xml/network_security_config.xml` prohíbe `http://` a cualquier
  host. Las variantes `src/debug` y `src/profile` lo reemplazan para permitir `http://` solo a
  `10.0.2.2`, `localhost` y `127.0.0.1` (backend local del `config/dev.json`).
  Consecuencia: un **release con `config/dev.json`** compila, pero no llega al backend local por
  http; para probar en release usar staging/production (https).
- R8 + `shrinkResources` (ver `docs/rendimiento-y-pantallas.md`).
