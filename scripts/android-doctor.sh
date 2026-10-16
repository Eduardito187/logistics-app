#!/usr/bin/env bash
# android-doctor.sh — Diagnóstico del entorno para compilar/correr la app
# interna de logística Dismac en WSL y en un teléfono Android por USB.
#
# SOLO DIAGNOSTICA: no instala ni cambia nada. Imprime qué falta y cómo
# arreglarlo. Sale con 0 si todo lo esencial está OK, 1 si falta algo esencial.
#
# Uso:  scripts/android-doctor.sh
set -uo pipefail

# --- Rutas reales de esta máquina ------------------------------------------
FLUTTER_BIN="$HOME/sdk/flutter/bin/flutter"
JDK_DIR="$HOME/jdk"
JAVA_BIN="$JDK_DIR/bin/java"
ANDROID_SDK="$HOME/Android/Sdk"
ADB_BIN="$ANDROID_SDK/platform-tools/adb"
WIN_ADB="/mnt/c/Users/ehhuallata/AppData/Local/Android/Sdk/platform-tools/adb.exe"
WSLCONFIG="/mnt/c/Users/ehhuallata/.wslconfig"
ADB_SOCKET="tcp:127.0.0.1:5037"

# Raíz del proyecto (este script vive en scripts/)
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# --- Colores (solo si hay terminal) ----------------------------------------
if [ -t 1 ]; then
  C_OK=$'\033[32m'; C_FAIL=$'\033[31m'; C_WARN=$'\033[33m'; C_DIM=$'\033[2m'; C_RST=$'\033[0m'
else
  C_OK=''; C_FAIL=''; C_WARN=''; C_DIM=''; C_RST=''
fi

# --- Contadores y helpers --------------------------------------------------
N_OK=0; N_WARN=0; N_FAIL=0

ok()   { N_OK=$((N_OK+1));     printf '%s✓%s %s\n' "$C_OK" "$C_RST" "$1"; }
warn() { N_WARN=$((N_WARN+1)); printf '%s⚠%s %s\n' "$C_WARN" "$C_RST" "$1"
         [ $# -gt 1 ] && printf '   %s↳ %s%s\n' "$C_DIM" "$2" "$C_RST"; return 0; }
fail() { N_FAIL=$((N_FAIL+1)); printf '%s✗%s %s\n' "$C_FAIL" "$C_RST" "$1"
         [ $# -gt 1 ] && printf '   %s↳ %s%s\n' "$C_DIM" "$2" "$C_RST"; return 0; }

section() { printf '\n%s== %s ==%s\n' "$C_DIM" "$1" "$C_RST"; }

printf '%sDiagnóstico del entorno Android/Flutter (WSL) — Dismac logistics-app%s\n' "$C_DIM" "$C_RST"
printf '%sProyecto: %s%s\n' "$C_DIM" "$PROJECT_ROOT" "$C_RST"

# ---------------------------------------------------------------------------
# 1. Flutter presente y versión
# ---------------------------------------------------------------------------
section "1. Flutter SDK"
if [ -x "$FLUTTER_BIN" ]; then
  FVER="$("$FLUTTER_BIN" --version 2>/dev/null | head -n1)"
  if [ -n "$FVER" ]; then
    ok "Flutter en ~/sdk/flutter — $FVER"
  else
    warn "Flutter existe pero 'flutter --version' no respondió" \
         "Probá: $FLUTTER_BIN --version"
  fi
else
  fail "No se encontró Flutter en ~/sdk/flutter/bin/flutter" \
       "Instalá Flutter stable en ~/sdk/flutter (ver CLAUDE.md)."
fi

# Verificar a qué 'flutter' resuelve el PATH (no debe ser Windows ni /dismac)
RESOLVED_FLUTTER="$(command -v flutter 2>/dev/null || true)"
if [ -n "$RESOLVED_FLUTTER" ]; then
  case "$RESOLVED_FLUTTER" in
    /mnt/c/*|*/mnt/c/*)
      fail "En el PATH, 'flutter' resuelve a Windows: $RESOLVED_FLUTTER" \
           "Antepuesto el de WSL: export PATH=\$HOME/sdk/flutter/bin:\$PATH" ;;
    /dismac/flutter/*)
      fail "En el PATH, 'flutter' resuelve a /dismac/flutter (pre-release de root)" \
           "Usá ~/sdk/flutter: export PATH=\$HOME/sdk/flutter/bin:\$PATH" ;;
    "$FLUTTER_BIN")
      ok "El PATH usa el Flutter correcto (~/sdk/flutter)" ;;
    *)
      warn "'flutter' en el PATH apunta a: $RESOLVED_FLUTTER" \
           "Lo esperado es $FLUTTER_BIN" ;;
  esac
else
  warn "'flutter' no está en el PATH" \
       "Agregá: export PATH=\$HOME/sdk/flutter/bin:\$PATH (los scripts ya lo anteponen)"
fi

# ---------------------------------------------------------------------------
# 2. JDK 17 en ~/jdk
# ---------------------------------------------------------------------------
section "2. JDK (Java)"
if [ -x "$JAVA_BIN" ]; then
  JVER="$("$JAVA_BIN" -version 2>&1 | head -n1)"
  if [ -n "$JVER" ]; then
    ok "JDK en ~/jdk — $JVER"
  else
    warn "~/jdk/bin/java existe pero 'java -version' no respondió" \
         "Probá: $JAVA_BIN -version"
  fi
else
  fail "No se encontró el JDK en ~/jdk/bin/java" \
       "Descomprimí un JDK 17 en ~/jdk (ver CLAUDE.md)."
fi

# ---------------------------------------------------------------------------
# 3. Android SDK
# ---------------------------------------------------------------------------
section "3. Android SDK"
if [ -d "$ANDROID_SDK" ]; then
  ok "Android SDK en ~/Android/Sdk"
else
  fail "No existe ~/Android/Sdk" \
       "Instalá el command-line tools + platform-tools en ~/Android/Sdk."
fi

if [ -x "$ADB_BIN" ]; then
  ok "adb (platform-tools) presente"
else
  fail "No se encontró adb en ~/Android/Sdk/platform-tools/adb" \
       "Instalá platform-tools en el SDK de WSL."
fi

if [ -d "$ANDROID_SDK/platforms/android-36" ]; then
  ok "Platform android-36 instalada"
else
  fail "Falta ~/Android/Sdk/platforms/android-36" \
       "Instalá: sdkmanager \"platforms;android-36\""
fi

if [ -d "$ANDROID_SDK/build-tools/36.0.0" ]; then
  ok "build-tools 36.0.0 instaladas"
else
  fail "Falta ~/Android/Sdk/build-tools/36.0.0" \
       "Instalá: sdkmanager \"build-tools;36.0.0\""
fi

# ---------------------------------------------------------------------------
# 4. flutter config apunta a android-sdk / jdk-dir correctos
# ---------------------------------------------------------------------------
section "4. flutter config (android-sdk / jdk-dir)"
CFG_SDK=""; CFG_JDK=""
if [ -x "$FLUTTER_BIN" ] && "$FLUTTER_BIN" config --machine >/dev/null 2>&1; then
  CFG_JSON="$("$FLUTTER_BIN" config --machine 2>/dev/null)"
  CFG_SDK="$(printf '%s' "$CFG_JSON" | sed -n 's/.*"android-sdk"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
  CFG_JDK="$(printf '%s' "$CFG_JSON" | sed -n 's/.*"jdk-dir"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
elif [ -f "$HOME/.config/flutter/settings" ]; then
  CFG_SDK="$(sed -n 's/.*"android-sdk"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$HOME/.config/flutter/settings")"
  CFG_JDK="$(sed -n 's/.*"jdk-dir"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$HOME/.config/flutter/settings")"
fi

if [ -z "$CFG_SDK" ] && [ -z "$CFG_JDK" ]; then
  warn "No se pudo leer la config de Flutter (settings / --machine)" \
       "Fijala: flutter config --android-sdk ~/Android/Sdk --jdk-dir ~/jdk"
else
  if [ "$CFG_SDK" = "$ANDROID_SDK" ]; then
    ok "android-sdk configurado correctamente ($CFG_SDK)"
  elif [ -z "$CFG_SDK" ]; then
    warn "android-sdk no está configurado en Flutter" \
         "Fijalo: flutter config --android-sdk ~/Android/Sdk"
  else
    fail "android-sdk apunta a '$CFG_SDK' (esperado $ANDROID_SDK)" \
         "Corregí: flutter config --android-sdk ~/Android/Sdk"
  fi

  if [ "$CFG_JDK" = "$JDK_DIR" ]; then
    ok "jdk-dir configurado correctamente ($CFG_JDK)"
  elif [ -z "$CFG_JDK" ]; then
    warn "jdk-dir no está configurado en Flutter" \
         "Fijalo: flutter config --jdk-dir ~/jdk"
  else
    fail "jdk-dir apunta a '$CFG_JDK' (esperado $JDK_DIR)" \
         "Corregí: flutter config --jdk-dir ~/jdk"
  fi
fi

# ---------------------------------------------------------------------------
# 5. Puente adb: ADB_SERVER_SOCKET + servidor de Windows + teléfonos
# ---------------------------------------------------------------------------
section "5. Puente adb WSL <-> Windows"
if [ "${ADB_SERVER_SOCKET:-}" = "$ADB_SOCKET" ]; then
  ok "ADB_SERVER_SOCKET está en el entorno ($ADB_SOCKET)"
elif grep -q "ADB_SERVER_SOCKET=$ADB_SOCKET" "$HOME/.bashrc" 2>/dev/null; then
  ok "ADB_SERVER_SOCKET definido en ~/.bashrc (abrí una shell nueva para aplicarlo)"
else
  fail "Falta ADB_SERVER_SOCKET ($ADB_SOCKET)" \
       "Agregá a ~/.bashrc: export ADB_SERVER_SOCKET=$ADB_SOCKET"
fi

# Arrancar el servidor adb de Windows (dueño del USB) y listar dispositivos.
export ADB_SERVER_SOCKET="$ADB_SOCKET"
if [ -x "$WIN_ADB" ] || [ -f "$WIN_ADB" ]; then
  "$WIN_ADB" start-server >/dev/null 2>&1 || true
  ok "Servidor adb de Windows arrancado (ve el USB)"
else
  warn "No se encontró el adb.exe de Windows" "$WIN_ADB"
fi

if [ -x "$ADB_BIN" ]; then
  ADB_OUT="$("$ADB_BIN" devices 2>/dev/null)"
  # Dispositivos 'device' físicos = no emulator-.
  N_PHONES="$(printf '%s\n' "$ADB_OUT" | awk 'NR>1 && $2=="device" && $1 !~ /^emulator-/' | grep -c . || true)"
  N_UNAUTH="$(printf '%s\n' "$ADB_OUT" | awk 'NR>1 && $2=="unauthorized"' | grep -c . || true)"
  if [ "${N_PHONES:-0}" -gt 0 ]; then
    ok "Teléfono(s) USB conectado(s): $N_PHONES"
  elif [ "${N_UNAUTH:-0}" -gt 0 ]; then
    warn "Hay un dispositivo 'unauthorized'" \
         "Aceptá '¿Permitir depuración USB?' en la pantalla del teléfono."
  else
    warn "Ningún teléfono USB (enchufá uno)" \
         "Activá Depuración por USB y conectá el cable; probá: $WIN_ADB devices"
  fi
else
  warn "No se pudo listar dispositivos (falta adb en WSL)" \
       "Ver chequeo 3 (Android SDK)."
fi

# ---------------------------------------------------------------------------
# 6. gradle.properties: heap acotado (<= 2G)
# ---------------------------------------------------------------------------
section "6. gradle.properties (heap JVM)"
GRADLE_PROPS="$PROJECT_ROOT/android/gradle.properties"
if [ -f "$GRADLE_PROPS" ]; then
  JVMARGS="$(grep -E '^[[:space:]]*org\.gradle\.jvmargs' "$GRADLE_PROPS" | head -n1)"
  XMX="$(printf '%s' "$JVMARGS" | grep -oE '\-Xmx[0-9]+[GgMm]' | head -n1)"
  if [ -z "$JVMARGS" ]; then
    warn "No hay org.gradle.jvmargs en gradle.properties" \
         "Fijá un heap acotado: org.gradle.jvmargs=-Xmx2G (NO 8G: cuelga WSL)."
  elif [ -z "$XMX" ]; then
    warn "org.gradle.jvmargs no define -Xmx" \
         "Agregá -Xmx2G para no saturar la RAM de WSL."
  else
    # Normalizar a MB para comparar.
    NUM="$(printf '%s' "$XMX" | grep -oE '[0-9]+')"
    UNIT="$(printf '%s' "$XMX" | grep -oiE '[GgMm]$')"
    case "$UNIT" in
      [Gg]) MB=$((NUM*1024)) ;;
      [Mm]) MB=$NUM ;;
      *)    MB=0 ;;
    esac
    if [ "$MB" -le 2048 ] && [ "$MB" -gt 0 ]; then
      ok "Heap Gradle acotado ($XMX)"
    else
      fail "CRÍTICO: heap Gradle demasiado grande ($XMX)" \
           "Un heap grande (4G/8G) cuelga WSL al saturar la RAM. Bajalo a -Xmx2G."
    fi
  fi
else
  fail "No existe android/gradle.properties" \
       "Debería existir con org.gradle.jvmargs=-Xmx2G."
fi

# ---------------------------------------------------------------------------
# 7. .wslconfig con memory=
# ---------------------------------------------------------------------------
section "7. .wslconfig (memoria de WSL)"
if [ -f "$WSLCONFIG" ]; then
  MEMLINE="$(grep -iE '^[[:space:]]*memory[[:space:]]*=' "$WSLCONFIG" | head -n1 | tr -d '[:space:]')"
  if [ -n "$MEMLINE" ]; then
    ok ".wslconfig define $MEMLINE"
  else
    warn ".wslconfig existe pero no define 'memory='" \
         "Recomendado: memory=10GB en [wsl2] (reiniciá WSL con 'wsl --shutdown')."
  fi
else
  warn "No se encontró $WSLCONFIG" \
       "Creá uno con [wsl2] y memory=10GB para acotar la RAM de WSL."
fi

# ---------------------------------------------------------------------------
# 8. Entornos (config/*.json) y run-usb.sh
# ---------------------------------------------------------------------------
section "8. Configs de entorno y run-usb.sh"
for env in dev staging production; do
  if [ -f "$PROJECT_ROOT/config/$env.json" ]; then
    ok "config/$env.json presente"
  else
    fail "Falta config/$env.json" "Debería existir el archivo de entorno '$env'."
  fi
done

if [ -f "$PROJECT_ROOT/scripts/run-usb.sh" ]; then
  if [ -x "$PROJECT_ROOT/scripts/run-usb.sh" ]; then
    ok "scripts/run-usb.sh presente y ejecutable"
  else
    warn "scripts/run-usb.sh existe pero no es ejecutable" \
         "Hacelo ejecutable: chmod +x scripts/run-usb.sh"
  fi
else
  fail "Falta scripts/run-usb.sh" "Es el script para correr la app por USB."
fi

# ---------------------------------------------------------------------------
# Resumen final
# ---------------------------------------------------------------------------
section "Resumen"
printf '%s%d OK%s, %s%d advertencias%s, %s%d faltantes%s\n' \
  "$C_OK" "$N_OK" "$C_RST" "$C_WARN" "$N_WARN" "$C_RST" "$C_FAIL" "$N_FAIL" "$C_RST"

if [ "$N_FAIL" -eq 0 ]; then
  printf '%s✓ Todo lo esencial está OK.%s\n' "$C_OK" "$C_RST"
  if [ "$N_WARN" -gt 0 ]; then
    printf '%s  (Hay advertencias; revisalas si algo no funciona, p. ej. el teléfono USB.)%s\n' "$C_DIM" "$C_RST"
  fi
  printf 'Para compilar y correr en el teléfono:  %sscripts/run-usb.sh [dev|staging|production]%s\n' "$C_DIM" "$C_RST"
  exit 0
else
  printf '%s✗ Falta algo esencial. Arreglá los ✗ de arriba y volvé a correr este diagnóstico.%s\n' "$C_FAIL" "$C_RST"
  exit 1
fi
