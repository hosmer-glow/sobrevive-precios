# Lector de Venezuela de Rinde

Algunas tiendas solo abren sus precios si quien pregunta está en Venezuela. Los servidores donde corre Rinde están fuera del país, así que hace falta un equipo **dentro de Venezuela** que lea esos precios todos los días y los entregue. Ese equipo es un **teléfono o una tablet Android** (puede ser viejo), con Termux instalado.

Esta guía es para alguien que **no es técnico**. Son unos 30 minutos la primera vez y después no hay que tocarlo.

## Lo que necesitas

- Un teléfono o tablet Android, con la **hora de Venezuela**.
- **Conectado a internet desde Venezuela, sin VPN** (más abajo se explica por qué).
- **Enchufado a la corriente** y con la pantalla apagada: tiene que quedarse prendido todo el día. Si es posible, déjalo siempre en el cargador.
- Tener a mano el WhatsApp de quien administra Rinde.

> **El equipo no lleva VPN.** Si tiene una VPN instalada, apágala y no la prendas. Con la VPN los sitios creen que estás fuera de Venezuela y el lector no sirve para nada.

## Paso 1. Instalar F-Droid

F-Droid es una tienda de aplicaciones distinta de Play Store. **Termux tiene que bajarse desde F-Droid, no de Play Store**: la versión de Play Store está vieja y no funciona.

1. Abre el navegador del equipo y entra a **f-droid.org**.
2. Toca el botón grande que dice **Descargar F-Droid**. Baja un archivo que termina en `.apk`.
3. Cuando termine, tócalo para abrirlo. Android te va a avisar algo como *"Por seguridad, tu teléfono no puede instalar apps de esta fuente"*. Toca **Ajustes** y activa **Permitir de esta fuente**, regresa y toca **Instalar**.
4. Abre F-Droid. La primera vez tarda unos minutos en cargar la lista: verás una pantalla blanca con una barra que se va llenando. Espera hasta que aparezca la lista de aplicaciones.

## Paso 2. Instalar Termux y Termux:Boot

Los dos se instalan **desde F-Droid** (si uno viene de otro lado, no se llevan bien).

1. En F-Droid toca la **lupa** (buscar) y escribe **Termux**. Toca el resultado que se llama simplemente **Termux** (tiene un icono negro con un `>_`). Toca **Instalar**.
2. Vuelve a buscar y escribe **Termux:Boot**. Toca **Instalar**.
3. Abre **Termux:Boot una sola vez** (toca su icono). Verás una pantalla casi vacía con un texto corto. No hace falta tocar nada más: abrirlo una vez le avisa a Android que puede arrancarlo cuando se prende el equipo.
4. Abre **Termux**. Verás una **pantalla negra con letras blancas** y un cursor parpadeando al final. Ahí es donde se pega el comando. La primera vez puede tardar un minuto preparando todo.

## Paso 3. Pegar el comando de instalación

1. Pega **este comando completo** en la pantalla negra de Termux (mantén el dedo apretado sobre la pantalla hasta que salga **Pegar**) y toca **Enter**:

```
curl -fsSL https://raw.githubusercontent.com/hosmer-glow/sobrevive-precios/main/lector/instalar.sh | bash
```

2. Van a pasar muchas líneas de letras: es normal. Tarda **entre 3 y 10 minutos**. No cierres Termux ni apagues la pantalla del todo (si se apaga sola, no pasa nada, solo no cierres la aplicación).
3. A la mitad te hace **una pregunta**: *"¿Qué correo o número de WhatsApp de Rinde pongo como contacto?"*. Escribe el correo o el WhatsApp que te diga quien administra Rinde y toca Enter. Es para que, si una tienda se molesta con la lectura, sepa a quién escribir.
4. Android puede mostrar una ventana pidiendo permiso para **notificaciones**. Acéptala: Termux muestra una notificación fija que dice que está activo, y esa notificación es la que lo mantiene despierto.
5. Al final verás un recuadro que dice **"Estas son las DOS llaves PÚBLICAS"** con dos líneas largas que empiezan con `ssh-ed25519`, una marcada **LLAVE 1** y otra **LLAVE 2**.

### Qué son las llaves

El lector crea **dos llaves** dentro del equipo. Cada llave es como un candado con su llave: la parte que ves en pantalla es la que se puede mandar (la "pública") y sirve para que GitHub sepa que ese equipo es quien dice ser. La parte privada **nunca sale del equipo**: no se copia, no se manda y no se muestra.

- **LLAVE 1:** sirve para **leer** el programa del lector. No puede cambiar nada.
- **LLAVE 2:** sirve para **escribir** los precios en un lugar específico y nada más.

## Paso 4. Mandar las dos llaves

1. Mantén el dedo sobre la **LLAVE 1** (la línea larga que empieza con `ssh-ed25519`) para seleccionarla. Si es más fácil, usa el archivo que se guardó: escribe `cat ~/rinde-llaves-publicas.txt` y toca Enter para verlas juntas.
2. Cópialas y pégalas en un mensaje de WhatsApp a quien administra Rinde. **Mándalas las dos.**
3. Espera a que te digan **"ya están agregadas"**. Mientras tanto no hace falta hacer nada más.

## Paso 5. Activar

Cuando te avisen, vuelve a abrir Termux y escribe:

```
rinde-activar
```

y toca Enter. Descarga el programa, lo deja listo, programa la lectura **todos los días a las 5:30 de la mañana** (hora del equipo) y hace una **prueba corta** que no publica nada. Tarda unos minutos.

Si al principio dice que *"GitHub todavía no reconoce la LLAVE"*, es que aún no las agregaron. Espera el aviso y vuelve a escribir `rinde-activar`.

## Paso 6. Quitarle el ahorro de batería a Termux

Este paso **es el más importante**. Los teléfonos están hechos para apagar las aplicaciones que no usas, y eso mataría al lector en medio de la noche. Hay que decirle a Android que a Termux **no** lo duerma.

**En cualquier Android** (los nombres cambian un poco según la marca):

1. Abre **Ajustes** y entra a **Aplicaciones** (a veces **Administrar aplicaciones**).
2. Busca **Termux** y tócalo.
3. Entra a **Batería** (a veces **Uso de la batería** o **Ahorro de batería**).
4. Elige **Sin restricciones** (o **No optimizar**, o **Permitir actividad en segundo plano**).
5. **Haz lo mismo con Termux:Boot.**

**Samsung:**
- *Ajustes > Aplicaciones > Termux > Batería > Sin restricciones.*
- *Ajustes > Cuidado del dispositivo > Batería > Límites de uso en segundo plano:* apaga **"Poner en suspensión las apps que no uses"** y, en **"Aplicaciones que nunca se suspenden"**, agrega **Termux** y **Termux:Boot**.

**Xiaomi, Redmi o Poco (MIUI o HyperOS):**
- *Ajustes > Aplicaciones > Administrar aplicaciones > Termux > Ahorro de batería > Sin restricciones.*
- En esa misma pantalla de Termux, activa **Inicio automático**.
- Abre la pantalla de **aplicaciones recientes** (el botón cuadrado), mantén el dedo sobre la tarjeta de Termux y toca el **candado**: así no se cierra solo.

**Motorola:**
- *Ajustes > Aplicaciones > Ver todas las aplicaciones > Termux > Batería > Sin restricciones.*
- *Ajustes > Batería:* apaga el **Ahorro de batería** y la **Batería adaptable** si están prendidos.

Además:
- No cierres Termux deslizándolo fuera de las aplicaciones recientes.
- Deja el equipo **enchufado**.
- Si el equipo tiene la opción **"Optimización de batería"** o **"Ahorro de energía"** a nivel general, apágala.

## Paso 7. Comprobar que todo salió bien

En Termux escribe:

```
rinde-estado
```

Responde en **una sola línea**. Por ejemplo:

- `BIEN: la corrida del 29/10 05:31 salió bien. ... | crond activo` → todo en orden.
- `BIEN, PERO SIN TRABAJO: ... todavía no hay ninguna tienda autorizada para leer.` → el lector funciona, pero a Rinde aún no le toca leer ninguna tienda. Es normal al principio.
- `TODAVÍA NO HA CORRIDO.` → escribe `rinde-correr --prueba` para ver que funciona.
- `ERROR: ...` → manda a quien administra Rinde el archivo `~/rinde-lector.log` (mira abajo cómo).
- `OJO: crond NO está activo` → abre Termux y escribe `crond`, luego Enter.

Hazlo al día siguiente de la instalación y después cuando quieras. **A las 5:30 de la mañana no hace falta que hagas nada.**

## Si algo sale mal

- **Para mandar el registro:** en Termux escribe `tail -n 80 ~/rinde-lector.log` y toca Enter. Copia lo que sale y mándalo por WhatsApp.
- **Si el equipo se apagó o se reinició:** al prenderlo, Termux:Boot arranca solo. Si pasó la hora de las 5:30, se pone al día a los 90 segundos. No tienes que abrir nada.
- **Si dejaste de ver la notificación de Termux:** abre Termux una vez; si te pidió permiso, acéptalo.
- **Lo que NO debes hacer:** instalar Termux desde Play Store, prender una VPN, desinstalar Termux, ni mandar archivos de la carpeta `.ssh` a nadie.

## Qué hace el lector, sin sorpresas

- **Cada día a las 5:30** abre las páginas públicas de las tiendas autorizadas, igual que lo haría una persona, **despacio** (una página cada 2 segundos o más) y respetando lo que cada sitio permite en su `robots.txt`. Si una tienda bloquea, pide una verificación o un captcha, **no insiste ni intenta saltarse nada**: lo anota y se detiene.
- Se presenta con el nombre **"Rinde (precios para app gratuita; contacto: …)"** y el contacto que pusiste.
- **Publica solo precios y nombres de productos**, en la carpeta `venezuela/` del repositorio público `sobrevive-precios`. No guarda ni manda datos personales, contraseñas ni nada del equipo.
- A las 6:00 un proceso automático de GitHub junta esa carpeta con el resto de los precios. **El teléfono escribe solo en `venezuela/`; el resto lo escribe GitHub.** Nunca escriben el mismo archivo.
- La prueba (`rinde-correr --prueba`) lee una muestra pequeña y **no publica nada**.

## Comandos que puedes usar en Termux

| Escribe | Para qué |
|---|---|
| `rinde-estado` | Dice en una línea si la última corrida salió bien |
| `rinde-correr --prueba` | Hace una prueba corta, sin publicar |
| `rinde-correr` | Lee y publica ahora mismo, sin esperar a las 5:30 |
| `rinde-activar` | Segundo paso de la instalación (solo hace falta una vez) |

---

## Para quien administra Rinde

1. Recibes las dos llaves públicas (`ssh-ed25519 …`). Guárdalas en dos archivos, `llave1.pub` y `llave2.pub`.
2. Agrégalas como deploy keys con `gh`:

```bash
# LLAVE 1: solo lectura, en el repo privado del código
gh repo deploy-key add llave1.pub --repo hosmer-glow/app-sobrevive --title "lector-venezuela (lectura)"

# LLAVE 2: con escritura, en el repo público de precios
gh repo deploy-key add llave2.pub --repo hosmer-glow/sobrevive-precios --title "lector-venezuela (escritura)" --allow-write
```

3. Avisa al creador que ya puede correr `rinde-activar`.
4. **Una tienda solo se lee si su conector está marcado `revisada: true`** en `precios/src/conectores/<tienda>.ts`, lo que se hace después de leer su `robots.txt` y sus términos de uso. Mientras esté en `false`, el lector no la toca y `rinde-estado` dice "sin tienda autorizada". La prueba corta (`--prueba`) sí la lee, pero solo una muestra y sin publicar.
5. Si cambias el código, el equipo lo toma solo en la siguiente corrida (`git fetch` de la rama `main`). Para otra rama, define `RINDE_RAMA` antes de correr.
6. Para ver de lejos si el lector está vivo, mira `venezuela/manifiesto-venezuela.json` en el repo de precios: trae `fecha` y `estado`. El proceso de las 6:00 marca la cadena `atrasado` si tiene más de 2 días.
