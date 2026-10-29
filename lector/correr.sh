#!/data/data/com.termux/files/usr/bin/bash
# Rinde, lector de Venezuela. Es lo que corre solo a las 5:30 (y lo que puedes correr a mano).
#
#   rinde-correr              lee y publica (lo mismo que hace el programa de las 5:30)
#   rinde-correr --prueba     lee pero NO publica nada (solo para ver que funciona)
#   rinde-correr --si-falta   solo corre si hoy todavía no salió bien (lo usa el arranque del teléfono)
#
# Solo escribe en la carpeta venezuela/ del repositorio de precios. Nada más.
set -uo pipefail
export PATH="${PREFIX:-/data/data/com.termux/files/usr}/bin:/system/bin:$PATH"

RINDE="$HOME/.rinde"
APP="$HOME/app-sobrevive"
PRECIOS="$HOME/sobrevive-precios"
ULTIMA="$RINDE/ultima"
RAMA="${RINDE_RAMA:-main}"
PRUEBA=0
SI_FALTA=0
for a in "$@"; do
  case "$a" in
    --prueba) PRUEBA=1 ;;
    --si-falta) SI_FALTA=1 ;;
  esac
done

ahora() { date '+%Y-%m-%dT%H:%M:%S%z'; }
registrar() { printf '[%s] %s\n' "$(ahora)" "$*"; }
guardar_estado() { # resultado, detalle (una sola línea)
  local detalle="${2//$'\n'/ }"
  {
    echo "inicio=$INICIO"
    echo "fin=$(ahora)"
    echo "fin_epoch=$(date +%s)"
    echo "resultado=$1"
    echo "detalle=$detalle"
    echo "prueba=$PRUEBA"
  } > "$ULTIMA.tmp" && mv "$ULTIMA.tmp" "$ULTIMA"
}
# Lee un valor de ~/.rinde/ultima sin ejecutarlo (el archivo trae texto libre).
valor() { grep -m1 "^$1=" "$ULTIMA" 2> /dev/null | cut -d= -f2-; }
INICIO="$(ahora)"

# Si hoy ya salió bien, el arranque del teléfono no repite.
if [ "$SI_FALTA" = 1 ] && [ -f "$ULTIMA" ]; then
  if [ "$(valor resultado)" = "ok" ] && [ "$(valor prueba)" = "0" ] && [ "$(date -d "$(valor fin)" +%F 2> /dev/null)" = "$(date +%F)" ]; then
    registrar "ya salió bien hoy; no se repite"
    exit 0
  fi
  # Antes de las 5:30 todavía no toca.
  [ "$(date +%H%M)" -lt 0530 ] && exit 0
fi

# Una sola corrida a la vez.
LOCK="$RINDE/corriendo"
if ! mkdir "$LOCK" 2> /dev/null; then
  if [ -n "$(find "$LOCK" -maxdepth 0 -mmin +180 2> /dev/null)" ]; then
    rmdir "$LOCK" 2> /dev/null; mkdir "$LOCK" 2> /dev/null || exit 0
  else
    registrar "ya hay una corrida en marcha"; exit 0
  fi
fi
trap 'rmdir "$LOCK" 2> /dev/null' EXIT

termux-wake-lock 2> /dev/null || true
if [ "$PRUEBA" = 1 ]; then registrar "=== inicio (prueba, no publica nada) ==="; else registrar "=== inicio ==="; fi
guardar_estado corriendo "en marcha"

[ -s "$RINDE/contacto" ] || { registrar "ERROR falta ~/.rinde/contacto"; guardar_estado error "falta el contacto"; exit 1; }
export RINDE_CONTACTO="$(cat "$RINDE/contacto")"
[ -d "$APP/.git" ] && [ -d "$PRECIOS/.git" ] || { registrar "ERROR falta activar (corre rinde-activar)"; guardar_estado error "falta activar"; exit 1; }
case "$(date +%z)" in -0400) ;; *) registrar "AVISO la zona horaria no es la de Venezuela ($(date +%z))" ;; esac

# 1. Al día con el código (la llave 1 solo puede leer).
if git -C "$APP" fetch --depth 1 origin "$RAMA" > /dev/null 2>&1 && git -C "$APP" reset --hard FETCH_HEAD > /dev/null 2>&1; then
  nuevo="$(sha256sum "$APP/precios/package-lock.json" | cut -d' ' -f1)"
  if [ "$nuevo" != "$(cat "$RINDE/lock.hash" 2> /dev/null)" ]; then
    registrar "dependencias nuevas: npm ci"
    ( cd "$APP/precios" && npm ci --omit=dev --no-audit --no-fund ) && echo "$nuevo" > "$RINDE/lock.hash"
  fi
else
  registrar "AVISO no pude actualizar el código; sigo con el que hay"
fi

# 2. Al día con lo ya publicado (para el guarda de "no publicar uno roto").
git -C "$PRECIOS" fetch --depth 1 origin main > /dev/null 2>&1 && git -C "$PRECIOS" reset --hard FETCH_HEAD > /dev/null 2>&1 \
  || registrar "AVISO no pude actualizar el repositorio de precios"

# 3. Lectura.
SALIDA_LOG="$RINDE/salida-diario.log"
SALIDA="$PRECIOS/venezuela"
extra=()
if [ "$PRUEBA" = 1 ]; then
  # La prueba lee solo una muestra (unos cientos de productos) y escribe en otra carpeta: no publica nada.
  extra=(--incluir-sin-revisar --limite "${RINDE_LIMITE_PRUEBA:-600}")
  SALIDA="$RINDE/prueba/venezuela"
fi
( cd "$APP/precios" && node src/diario.ts --solo-venezuela ${extra[@]+"${extra[@]}"} --salida "$SALIDA" ) > "$SALIDA_LOG" 2>&1
codigo=$?
cat "$SALIDA_LOG"

if grep -q "No hay cadenas de Venezuela para leer" "$SALIDA_LOG"; then
  registrar "=== fin: todavía no hay ninguna tienda autorizada para leer ==="
  guardar_estado sin-cadenas "no hay tiendas autorizadas todavía"
  exit 0
fi

resumen="$(node -e '
  try {
    const m = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
    console.log(Object.entries(m.cadenas).map(([c, e]) => c + ": " + e.productos + " productos" + (e.atrasado ? " (ATRASADO: " + (e.error || "") + ")" : "")).join("; "));
  } catch (e) { console.log("sin manifiesto"); }
' "$SALIDA/manifiesto-venezuela.json" 2> /dev/null)"

if [ "$codigo" -ne 0 ]; then
  registrar "ERROR la lectura falló. $resumen"
  guardar_estado error "$resumen"
  exit 1
fi

if [ "$PRUEBA" = 1 ]; then
  registrar "=== fin de la prueba: salió bien y NO se publicó nada. $resumen ==="
  guardar_estado ok "prueba: $resumen"
  exit 0
fi

# 4. Publicar: solo venezuela/, con reintentos si alguien más escribió en el repositorio mientras tanto.
publicar() {
  cd "$PRECIOS" || return 1
  rm -rf /tmp/rinde-venezuela && cp -r venezuela /tmp/rinde-venezuela
  for intento in 1 2 3; do
    git add venezuela
    fuera="$(git diff --cached --name-only | grep -v '^venezuela/' || true)"
    if [ -n "$fuera" ]; then registrar "ERROR se iba a tocar algo fuera de venezuela/: $fuera"; git reset -q; return 1; fi
    if git diff --cached --quiet; then registrar "sin cambios que publicar"; return 0; fi
    git commit -q -m "Lector de Venezuela: $(date +%F)" || return 1
    git push -q origin HEAD:main && return 0
    registrar "AVISO el push falló (intento $intento); reintento partiendo de lo último del repositorio"
    git fetch --depth 1 origin main && git reset -q --hard FETCH_HEAD || return 1
    rm -rf venezuela && cp -r /tmp/rinde-venezuela venezuela
    sleep 5
  done
  return 1
}
if publicar; then
  registrar "=== fin: publicado. $resumen ==="
  guardar_estado ok "$resumen"
else
  registrar "ERROR no pude publicar. $resumen"
  guardar_estado error "no pude publicar. $resumen"
  exit 1
fi
