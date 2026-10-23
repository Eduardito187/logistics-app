#!/usr/bin/env bash
# DisTrack — ADB inalámbrico desde WSL (Linux). VS Code en Remote-WSL usa el
# Flutter de WSL, así que el teléfono debe estar en el adb de WSL (este).
#
# La clave ~/.android/adbkey se copió desde Windows, así que el teléfono YA
# confía en este adb (no hace falta re-vincular).
#
# Uso (el subcomando es opcional si pasás ip:puerto):
#   ./scripts/adb-wireless.sh 192.168.1.42:5555          # conecta (atajo de 'connect')
#   ./scripts/adb-wireless.sh 192.168.1.50:37123 123456  # vincula (atajo de 'pair'): ip:puertoVinculacion codigo
#   ./scripts/adb-wireless.sh connect 192.168.1.42:5555  # conecta y lo recuerda
#   ./scripts/adb-wireless.sh reconnect                  # reconecta al último (def. 192.168.1.42:5555)
#   ./scripts/adb-wireless.sh reverse                    # (re)arma el puente al backend (tcp:8110)
#   ./scripts/adb-wireless.sh usb                        # con cable: tcpip 5555 + connect (5555 estable)
#   ./scripts/adb-wireless.sh mdns                       # autodescubre por mDNS (openscreen)
#   ./scripts/adb-wireless.sh pair 192.168.1.50:37123 123456 [192.168.1.50:40777]
set -euo pipefail

ADB="${ADB:-$HOME/Android/Sdk/platform-tools/adb}"
# OJO: mDNS openscreen (ADB_MDNS_OPENSCREEN) NO se activa por defecto. En redes
# que dejan pasar multicast (casa) autodescubre bien, pero en redes corporativas
# (trabajo) el multicast suele estar BLOQUEADO: el dispositivo se auto-conecta
# por mDNS como una entrada FANTASMA (serial 'adb-XXXX._adb-tls-connect._tcp',
# con espacios) que figura en la lista pero no responde → Flutter la elige y
# tira "device not found". Por eso solo lo prendemos en el subcomando 'mdns'.
LAST="$HOME/.distrack-adb-last"
DEFAULT="192.168.1.4:5555"
PORT=8110   # backend local (Docker) al que el teléfono llega por 'adb reverse'

# adb con TIMEOUT para las llamadas de red (connect/reverse): si el teléfono
# está dormido o el puerto rotó, 'adb connect' puede colgarse indefinidamente y
# deja la tarea de VS Code "pensando" para siempre. Con esto nunca bloquea.
NET_TIMEOUT=7
adb_net() { timeout "$NET_TIMEOUT" "$ADB" "$@"; }

# ¿Hay entradas fantasma de mDNS? (serial que NO es ip:puerto).
has_ghost() { "$ADB" devices | awk 'NR>1 && $1 !~ /^[0-9.]+:[0-9]+$/ && NF>=2 {f=1} END{exit f?0:1}'; }

# Deja el adb LIMPIO para conectar por IP: si hay fantasmas mDNS pegados,
# reinicia el server con mDNS apagado (la única forma fiable de sacarlos,
# porque su serial lleva espacios y 'adb disconnect <serial>' no los toma).
clean_server() {
  if has_ghost; then
    echo "Limpiando entradas fantasma de mDNS (reinicio adb sin mDNS) ..."
    "$ADB" kill-server >/dev/null 2>&1 || true
  fi
  ADB_MDNS_OPENSCREEN=0 "$ADB" start-server >/dev/null 2>&1 || true
}

# (Re)establece un puerto ESTABLE 5555. Clave del asunto: en Android 11+ los
# puertos de "Depuración inalámbrica" ROTAN y los que anuncia mDNS se niegan a
# 'adb connect' directo; además el serial de mDNS lleva espacios/sufijo que
# Flutter NO sabe direccionar ("Error retrieving device properties" → "device
# not found"). La salida: autoconectar por mDNS, fijar 'tcpip 5555' (TCP plano,
# sobrevive a apagar mDNS y Flutter SÍ lo direcciona) y reconectar por IP:5555.
# Queda estable hasta que el teléfono se reinicie. Requiere red con mDNS (casa);
# en redes sin multicast (trabajo) no aplica: ahí se pasa el ip:puerto a mano.
establish_stable() {
  echo "Reestableciendo puerto estable 5555 vía mDNS ..."
  "$ADB" kill-server >/dev/null 2>&1 || true
  ADB_MDNS_OPENSCREEN=1 "$ADB" start-server >/dev/null 2>&1
  sleep 3
  local serial ip
  serial="$("$ADB" devices | awk -F'\t' 'NR>1 && $2=="device"{print $1; exit}')"
  if [ -z "$serial" ]; then
    echo "mDNS no autoconectó el teléfono (red sin multicast o depuración inalámbrica apagada)."
    echo "Abrí 'Depuración inalámbrica' y pasá el ip:puerto:  $0 <ip:puerto>"
    ADB_MDNS_OPENSCREEN=0 "$ADB" start-server >/dev/null 2>&1 || true
    return 1
  fi
  ip="$(ADB_MDNS_OPENSCREEN=1 "$ADB" mdns services 2>/dev/null \
        | grep -m1 -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' || true)"
  [ -n "$ip" ] || ip="$(cut -d: -f1 <<<"$([ -f "$LAST" ] && cat "$LAST" || echo "$DEFAULT")")"
  if ! timeout 12 "$ADB" -s "$serial" tcpip 5555 >/dev/null 2>&1; then
    echo "no pude fijar 5555 (tcpip)"; return 1
  fi
  sleep 3
  # Apagar mDNS saca el fantasma; el 5555 (TCP plano) reconecta igual.
  "$ADB" kill-server >/dev/null 2>&1 || true
  ADB_MDNS_OPENSCREEN=0 "$ADB" start-server >/dev/null 2>&1
  adb_net connect "$ip:5555" >/dev/null 2>&1 || true
  printf '%s' "$ip:5555" > "$LAST"
  echo "Puerto estable listo en $ip:5555 (hasta reiniciar el teléfono)."
  pick_serial >/dev/null 2>&1
}

# Elige UN serial real para los comandos que no admiten ambigüedad (reverse).
# El teléfono suele figurar dos veces: por ip:puerto y por el servicio mDNS
# (adb-XXXX._adb-tls-connect._tcp). Preferimos el serial ip:puerto (estable);
# si está el último destino conectado, ese; si no, el primero que aparezca.
pick_serial() {
  local devs ip_serial
  # -F'\t': 'adb devices' separa serial<TAB>estado; los seriales de mDNS llevan
  # espacios, así que NO se puede partir por espacio.
  devs="$("$ADB" devices | awk -F'\t' 'NR>1 && $2=="device"{print $1}')"
  [ -n "$devs" ] || return 1
  if [ -f "$LAST" ] && grep -qxF "$(cat "$LAST")" <<<"$devs"; then
    cat "$LAST"; return 0
  fi
  ip_serial="$(grep -m1 -E '^[0-9.]+:[0-9]+$' <<<"$devs" || true)"
  [ -n "$ip_serial" ] && { printf '%s' "$ip_serial"; return 0; }
  head -n1 <<<"$devs"
}

# Arma el túnel teléfono→PC del backend, apuntando a un serial concreto (nunca
# falla por "more than one device": el fantasma mDNS no es ip:puerto y se
# ignora). Nunca bloquea ni devuelve error: si no hay device, avisa y sigue.
bridge() {
  local s
  s="$(pick_serial || true)"
  if [ -z "$s" ]; then
    echo "sin teléfono conectado; el puente se armará cuando conectes ($0 reconnect)"
    return 0
  fi
  if adb_net -s "$s" reverse "tcp:$PORT" "tcp:$PORT" >/dev/null 2>&1; then
    echo ">>> puente backend $PORT listo (en $s)"
  else
    echo "no pude armar el puente $PORT en $s (¿el teléfono se desconectó?)"
  fi
  return 0
}

connect() {
  local t="$1"
  clean_server            # saca fantasmas mDNS antes de conectar por IP
  echo "Conectando (WSL) a $t ..."
  adb_net connect "$t" >/dev/null 2>&1 || true   # con timeout: no se cuelga
  printf '%s' "$t" > "$LAST"
  bridge || true
  "$ADB" devices -l
  echo "Guardado como último destino ($t). La próxima: reconnect."
}

ADB_MDNS_OPENSCREEN=0 "$ADB" start-server >/dev/null 2>&1 || true

cmd="${1:-}"
# Atajo: si el primer argumento parece ip:puerto, deducimos el subcomando.
#   ip:puerto           -> connect
#   ip:puerto  codigo   -> pair (codigo = 6 dígitos de vinculación)
if [[ "$cmd" =~ ^[0-9.]+:[0-9]+$ ]]; then
  if [[ "${2:-}" =~ ^[0-9]{6}$ ]]; then
    set -- pair "$@"
  else
    set -- connect "$@"
  fi
  cmd="$1"
fi

case "$cmd" in
  connect)   connect "${2:?Falta ip:puerto}";;
  reconnect) connect "$([ -f "$LAST" ] && cat "$LAST" || echo "$DEFAULT")";;
  reverse|bridge)
    # preLaunch del play. A prueba de cuelgues (timeouts) y de FANTASMA. Deja un
    # ÚNICO device ip:puerto limpio (5555) que Flutter sabe direccionar:
    #   1. Reinicia adb SIN mDNS (saca cualquier fantasma). El 5555 es TCP plano
    #      y reconecta al instante.
    #   2. Conecta al último destino (5555) con timeout.
    #   3. Si no hay device (teléfono reiniciado → 5555 perdido, o nueva red),
    #      reestablece el 5555 estable vía mDNS.
    #   4. Arma el puente al backend. Siempre termina y no traba el play.
    tgt="$([ -f "$LAST" ] && cat "$LAST" || echo "$DEFAULT")"
    "$ADB" kill-server >/dev/null 2>&1 || true
    ADB_MDNS_OPENSCREEN=0 "$ADB" start-server >/dev/null 2>&1
    adb_net connect "$tgt" >/dev/null 2>&1 || true
    pick_serial >/dev/null 2>&1 || establish_stable || true
    bridge
    ;;
  stable)
    # Reestablece a mano el puerto estable 5555 (p. ej. tras reiniciar el
    # teléfono) y arma el puente.
    establish_stable || true
    bridge
    ;;
  clean)     clean_server; "$ADB" devices -l; echo "adb limpio (sin fantasmas mDNS).";;
  mdns)      # Solo acá se prende mDNS openscreen (sirve en WiFi que deja pasar multicast, p. ej. casa).
             "$ADB" kill-server || true; ADB_MDNS_OPENSCREEN=1 "$ADB" start-server; sleep 3; ADB_MDNS_OPENSCREEN=1 "$ADB" mdns services; "$ADB" devices -l;;
  pair)
    tgt="${2:?Falta ip:puertoVinculacion}"; code="${3:?Falta codigo de vinculacion}"
    echo "Vinculando dispositivo nuevo en $tgt ..."
    "$ADB" pair "$tgt" "$code"
    if [ -n "${4:-}" ] && [ "${4}" != "$tgt" ]; then
      # Solo si dieron un puerto de CONEXIÓN distinto del de vinculación.
      connect "$4"
    else
      # El puerto de vinculación NO sirve para conectar (se cierra al terminar).
      # mDNS (openscreen) suele reconectar solo por el puerto real; esperamos y
      # armamos el puente con el serial que aparezca.
      echo "Vinculado. Buscando el dispositivo por mDNS ..."
      sleep 3
      "$ADB" devices -l
      if bridge; then
        echo "Listo: ya podés darle play a la app."
      else
        echo "Si no apareció, abrí 'Depuración inalámbrica' y pasá el ip:puertoConexion de la pantalla principal:"
        echo "  $0 connect <ip:puertoConexion>"
      fi
    fi
    ;;
  usb)
    echo "Esperando teléfono por USB (debe estar atado a WSL con usbipd)..."
    "$ADB" wait-for-device
    "$ADB" tcpip 5555; sleep 2
    ip=$("$ADB" shell ip -f inet addr show wlan0 2>/dev/null | grep -oE 'inet [0-9.]+' | awk '{print $2}' | head -1)
    [ -n "$ip" ] || { echo "No pude leer la IP WiFi; usá: connect <ip>:5555"; exit 1; }
    connect "$ip:5555"
    echo "LISTO: desenchufá el cable. Queda en $ip:5555 hasta reiniciar el teléfono."
    ;;
  *) echo "Uso: $0 {<ip:puerto> [codigo] | connect <ip:puerto> | reconnect | reverse | stable | clean | usb | mdns | pair <ip:pair> <codigo> [ip:conexion]}"; exit 2;;
esac
