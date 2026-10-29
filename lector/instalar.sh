#!/data/data/com.termux/files/usr/bin/bash
# Rinde, lector de Venezuela. Paso 1 de 2: instala lo necesario y crea las llaves.
#
# Se corre UNA vez, pegando en Termux:
#   curl -fsSL https://raw.githubusercontent.com/hosmer-glow/sobrevive-precios/main/lector/instalar.sh | bash
#
# Qué hace: instala programas, mantiene el teléfono despierto, crea DOS llaves SSH que se quedan en
# este teléfono (la parte privada nunca sale), te muestra las partes públicas para que se las mandes
# a quien administra Rinde, y deja listo el arranque automático. Se puede correr otra vez sin problema.
# NO usa VPN ni la necesita: el teléfono tiene que salir a internet desde Venezuela.
set -euo pipefail

BASE="https://raw.githubusercontent.com/hosmer-glow/sobrevive-precios/main/lector"
RINDE="$HOME/.rinde"
SSH="$HOME/.ssh"
PREFIJO="${PREFIX:-/data/data/com.termux/files/usr}"

mensaje() { printf '\n== %s\n' "$*"; }
fallo() { printf '\nNo se pudo seguir: %s\n' "$*" >&2; exit 1; }

case "$PREFIJO" in
  *com.termux*) ;;
  *) fallo "esto hay que correrlo dentro de la app Termux (instalada desde F-Droid), no en otra terminal." ;;
esac

mensaje "1 de 6. Instalando programas (puede tardar unos minutos)"
pkg update -y
pkg install -y nodejs-lts git openssh cronie termux-services curl

mensaje "2 de 6. Manteniendo el teléfono despierto"
termux-wake-lock || echo "(Si no aparece la notificación de Termux con 'wake lock', no pasa nada: revisa la batería en el README.)"

mkdir -p "$RINDE" "$SSH" "$HOME/.termux/boot"
chmod 700 "$SSH"

mensaje "3 de 6. Contacto del lector"
if [ ! -s "$RINDE/contacto" ]; then
  echo "Las tiendas pueden querer avisarnos si algo les molesta. ¿Qué correo o número de WhatsApp"
  echo "de Rinde pongo como contacto? (por ejemplo: contacto@tudominio.com o +58 412 000 0000)"
  printf '> '
  read -r CONTACTO < /dev/tty
  [ -n "$CONTACTO" ] || fallo "hace falta un contacto."
  printf '%s\n' "$CONTACTO" > "$RINDE/contacto"
fi
echo "Contacto guardado: $(cat "$RINDE/contacto")"

mensaje "4 de 6. Creando las dos llaves (se quedan en este teléfono)"
crear_llave() { # nombre, comentario
  if [ ! -f "$SSH/$1" ]; then
    ssh-keygen -t ed25519 -N "" -C "$2" -f "$SSH/$1" -q
  fi
  chmod 600 "$SSH/$1"
}
crear_llave rinde_leer "rinde-lector-leer-$(date +%Y%m%d)"
crear_llave rinde_escribir "rinde-lector-escribir-$(date +%Y%m%d)"

# Dos "nombres" de GitHub, uno por llave: una deploy key solo sirve para un repositorio.
if ! grep -q "rinde-lector" "$SSH/config" 2>/dev/null; then
  cat >> "$SSH/config" <<'CONF'

# rinde-lector: llave de solo lectura para el código
Host github-app
  HostName github.com
  User git
  IdentityFile ~/.ssh/rinde_leer
  IdentitiesOnly yes
  StrictHostKeyChecking accept-new

# rinde-lector: llave con permiso de escribir solo en el repositorio de precios
Host github-precios
  HostName github.com
  User git
  IdentityFile ~/.ssh/rinde_escribir
  IdentitiesOnly yes
  StrictHostKeyChecking accept-new
CONF
fi
chmod 600 "$SSH/config"

mensaje "5 de 6. Guardando los programas del lector y el arranque automático"
for archivo in activar.sh correr.sh estado.sh; do
  curl -fsSL "$BASE/$archivo" -o "$RINDE/$archivo"
  chmod +x "$RINDE/$archivo"
done
# Comandos cortos para escribir en Termux.
printf '#!%s/bin/bash\nexec bash "$HOME/.rinde/estado.sh" "$@"\n' "$PREFIJO" > "$PREFIJO/bin/rinde-estado"
printf '#!%s/bin/bash\nexec bash "$HOME/.rinde/activar.sh" "$@"\n' "$PREFIJO" > "$PREFIJO/bin/rinde-activar"
printf '#!%s/bin/bash\nexec bash "$HOME/.rinde/correr.sh" "$@"\n' "$PREFIJO" > "$PREFIJO/bin/rinde-correr"
chmod +x "$PREFIJO/bin/rinde-estado" "$PREFIJO/bin/rinde-activar" "$PREFIJO/bin/rinde-correr"

# Termux:Boot ejecuta esto cada vez que se prende el teléfono.
cat > "$HOME/.termux/boot/rinde-lector" <<BOOT
#!$PREFIJO/bin/sh
export PATH="$PREFIJO/bin:\$PATH"
termux-wake-lock
pgrep -x crond > /dev/null || crond
# Si el teléfono estuvo apagado a las 5:30, se pone al día (solo corre si hoy todavía no salió bien).
( sleep 90; bash "\$HOME/.rinde/correr.sh" --si-falta >> "\$HOME/rinde-lector.log" 2>&1 ) &
BOOT
chmod +x "$HOME/.termux/boot/rinde-lector"
pgrep -x crond > /dev/null || crond || true

mensaje "6 de 6. Listo. Estas son las DOS llaves PÚBLICAS"
echo "Son como el número de un candado: se pueden mandar sin problema. Las privadas NO salen de aquí."
{
  echo
  echo "LLAVE 1 (leer el código, solo lectura):"
  cat "$SSH/rinde_leer.pub"
  echo
  echo "LLAVE 2 (escribir los precios):"
  cat "$SSH/rinde_escribir.pub"
  echo
} | tee "$HOME/rinde-llaves-publicas.txt"
echo "(También quedaron guardadas en el archivo rinde-llaves-publicas.txt)"
echo
echo "Ahora:"
echo "  1. Mándale las dos llaves a quien administra Rinde (cópialas con el dedo y pégalas en WhatsApp)."
echo "  2. Cuando te avise que ya las agregó, escribe aquí:   rinde-activar"
echo "  3. Quítale el ahorro de batería a Termux (mira el README) y no uses VPN en este equipo."
