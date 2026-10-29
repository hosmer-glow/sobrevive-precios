#!/data/data/com.termux/files/usr/bin/bash
# Rinde, lector de Venezuela. Dice en una línea si la última corrida salió bien.   Se usa con:   rinde-estado
export PATH="${PREFIX:-/data/data/com.termux/files/usr}/bin:/system/bin:$PATH"
ULTIMA="$HOME/.rinde/ultima"

if [ ! -f "$ULTIMA" ]; then
  echo "TODAVÍA NO HA CORRIDO. Si ya activaste el lector, prueba:   rinde-correr --prueba"
  exit 2
fi
# Se lee sin ejecutar el archivo (trae texto libre).
valor() { grep -m1 "^$1=" "$ULTIMA" 2> /dev/null | cut -d= -f2-; }
fin="$(valor fin)"; fin_epoch="$(valor fin_epoch)"; inicio="$(valor inicio)"
resultado="$(valor resultado)"; detalle="$(valor detalle)"; prueba="$(valor prueba)"
cuando="$(date -d "${fin:-1970-01-01}" '+%d/%m %H:%M' 2> /dev/null || echo "${fin:-?}")"
hace=$(( $(date +%s) - ${fin_epoch:-0} ))
vieja=""
[ "$hace" -gt 93600 ] && vieja=" | OJO: hace más de un día que no corre (¿se apagó o se durmió el equipo?)"

crond_ok="crond activo"
pgrep -x crond > /dev/null || crond_ok="OJO: crond NO está activo (abre Termux y escribe: crond)"

case "${resultado:-}" in
  ok)
    [ "${prueba:-0}" = 1 ] && tipo="la PRUEBA" || tipo="la corrida"
    echo "BIEN: $tipo del $cuando salió bien. ${detalle:-}${vieja} | $crond_ok"; exit 0 ;;
  sin-cadenas)
    echo "BIEN, PERO SIN TRABAJO: el $cuando todo funcionó, pero todavía no hay ninguna tienda autorizada para leer.${vieja} | $crond_ok"; exit 0 ;;
  corriendo)
    echo "EN MARCHA: está corriendo ahora (empezó $(date -d "${inicio:-1970-01-01}" '+%H:%M' 2> /dev/null)).${vieja}"; exit 0 ;;
  *)
    echo "ERROR: la corrida del $cuando falló. ${detalle:-} Mira ~/rinde-lector.log y mándaselo a quien administra Rinde.${vieja} | $crond_ok"; exit 1 ;;
esac
