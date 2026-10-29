#!/data/data/com.termux/files/usr/bin/bash
# Rinde, lector de Venezuela. Paso 2 de 2: descarga el código, lo deja listo y programa la lectura de las 5:30.
# Se corre con:   rinde-activar      (solo después de que te avisen que las llaves ya están agregadas)
set -euo pipefail
export PATH="${PREFIX:-/data/data/com.termux/files/usr}/bin:$PATH"

RINDE="$HOME/.rinde"
APP="$HOME/app-sobrevive"
PRECIOS="$HOME/sobrevive-precios"
RAMA="${RINDE_RAMA:-main}"

mensaje() { printf '\n== %s\n' "$*"; }
fallo() { printf '\nNo se pudo seguir: %s\n' "$*" >&2; exit 1; }

[ -f "$HOME/.ssh/rinde_leer" ] && [ -f "$HOME/.ssh/rinde_escribir" ] || fallo "faltan las llaves. Primero corre el comando de instalación del README."

mensaje "1 de 5. Comprobando que GitHub conoce las llaves"
llave_ok() { # nombre del host en ~/.ssh/config
  ssh -o BatchMode=yes -o ConnectTimeout=25 -T "git@$1" 2>&1 | grep -q "successfully authenticated"
}
llave_ok github-app || fallo "GitHub todavía no reconoce la LLAVE 1. Avisa a quien administra Rinde y vuelve a intentar más tarde."
llave_ok github-precios || fallo "GitHub todavía no reconoce la LLAVE 2. Avisa a quien administra Rinde y vuelve a intentar más tarde."
echo "Las dos llaves funcionan."

mensaje "2 de 5. Revisando la versión de Node"
node -e 'const [a,b]=process.versions.node.split(".").map(Number); process.exit(a>22||(a===22&&b>=18)?0:1)' \
  || fallo "Node $(node -v) es muy viejo (hace falta 22.18 o más). Corre: pkg upgrade -y"

mensaje "3 de 5. Descargando el código (solo la parte de precios)"
if [ ! -d "$APP/.git" ]; then
  git clone --depth 1 --filter=blob:none --sparse --branch "$RAMA" "git@github-app:hosmer-glow/app-sobrevive.git" "$APP"
fi
git -C "$APP" sparse-checkout set precios app/src/motor
git -C "$APP" fetch --depth 1 origin "$RAMA"
git -C "$APP" reset --hard FETCH_HEAD
( cd "$APP/precios" && npm ci --omit=dev --no-audit --no-fund )
sha256sum "$APP/precios/package-lock.json" | cut -d' ' -f1 > "$RINDE/lock.hash"

mensaje "4 de 5. Descargando el repositorio donde se publican los precios"
if [ ! -d "$PRECIOS/.git" ]; then
  git clone --depth 1 "git@github-precios:hosmer-glow/sobrevive-precios.git" "$PRECIOS"
fi
git -C "$PRECIOS" config user.name "lector-venezuela"
git -C "$PRECIOS" config user.email "lector-venezuela@users.noreply.github.com"

mensaje "5 de 5. Programando la lectura de las 5:30 (hora del teléfono)"
echo "Hora actual del teléfono: $(date '+%F %H:%M %z'). Tiene que decir -0400 (hora de Venezuela)."
case "$(date +%z)" in
  -0400) ;;
  *) echo "AVISO: la zona horaria no es la de Venezuela. Cámbiala en Ajustes > Fecha y hora, o la lectura saldrá a otra hora." ;;
esac
( crontab -l 2>/dev/null | grep -v "rinde-lector" || true
  echo "30 5 * * * bash \$HOME/.rinde/correr.sh >> \$HOME/rinde-lector.log 2>&1  # rinde-lector"
) | crontab -
pgrep -x crond > /dev/null || crond || true
crontab -l | grep rinde-lector

mensaje "Prueba de funcionamiento (lee una muestra y no publica nada)"
bash "$RINDE/correr.sh" --prueba || true
echo
echo "Listo. Mira cómo salió con:   rinde-estado"
echo "Y manda el archivo ~/rinde-lector.log a quien administra Rinde si algo dice ERROR."
