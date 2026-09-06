# El juego

No es un juego.

![La pantalla de título](../imagenes/titulo.png)

*La pantalla de título, montada desde la ROM. De los 16.384 bytes de VRAM, el
único que discrepa del emulador es `0x39A9`: el cursor parpadeando.*

Konami's Game Master es un **cartucho de trucos**. Se enchufa en una ranura y
el juego en la otra, y a partir de ahí el Game Master te deja empezar en la
fase que quieras, con las vidas que quieras, congelar la partida, guardar la
pantalla en disco o en cinta e imprimirla.

Lo interesante no es lo que hace, sino **que pueda hacerlo**. El Game Master no
sabe nada del juego que tiene al lado hasta que arranca.

## Los tres modos

![El menú de arranque](../imagenes/arranque-1.png)

*El menú de arranque, con el puntero de tiza señalando la opción. Los tres
punteros son doce casillas cada uno —`0x4FA9`, `0x4FB5` y `0x4FC1`— pintadas en
el mismo sitio de la pantalla.*

- **GAME** arranca el juego con los trucos ya puestos.
- **MODIFY** abre el menú de los trucos.
- **SELF** abre el de comprobaciones: el patrón de prueba de color y la carga
  de pantallas guardadas.

## MODIFY MODE: los trucos

![El menú MODIFY](../imagenes/menu-modify.png)

Aquí es a lo que se viene. **MODIFY STAGE NUMBER** y **MODIFY PLAYER NUMBER**
piden dos números y los guardan en `0xD31A` y `0xD31B`. Esas dos direcciones
son lo que leen las veintiuna rutinas de truco, una por juego.

El truco que vale para todos son tres instrucciones, en `0x5D13`:

    ld a,(0D31Bh)     ; las vidas que se han pedido
    ld hl,(0D30Ah)    ; y dónde las guarda el juego
    ld (hl),a

`0xD30A` es un puntero a una variable **del juego**, y sale de su cabecera. El
resto de cada rutina es lo que ese juego necesita de particular: cuántas fases
tiene, si hay que dar la vuelta al contador, si además hay que poner el
marcador.

## Las teclas, mientras juegas

El Game Master no se va cuando arranca el juego: se queda **dentro de su
interrupción**, ejecutándose cincuenta veces por segundo. Tres teclas, leídas
en `0x4F13` de las líneas 1, 6 y 7 del teclado:

- una **vuelve al menú** del cartucho;
- otra **congela** la partida;
- la tercera **cuenta de trece en trece** (`0x4DF3`).

Y el aviso de que está congelado no es un rótulo en pantalla —eso estropearía
el dibujo del juego— sino **la luz de CAPS**: `0x4E70` llama a CHGCAP. Al
congelar, además, calla el PSG de verdad: `0x4E85` se guarda los volúmenes de
los tres canales antes de ponerlos a cero, y `0x4EF8` los devuelve.

## Los menús se abren encima del juego

![El menú de disco y cinta](../imagenes/menu-principal.png)

*En la máquina real, la mitad de arriba de esta pantalla es la partida
corriendo.*

Los menús de disco y cinta sólo borran **`0x100` bytes desde `0x3A00`**, o sea
las ocho filas de abajo. Lo demás se queda como estaba, y antes `0x4275` ha
llamado a la rutina que se lleva la VRAM del juego a la RAM para poder
devolverla al salir.

## Guardar, cargar e imprimir

![El modo RANKING](../imagenes/menu-modo-ranking.png)

El cartucho guarda cuatro clases de dato —la pantalla, los datos del juego, el
récord y la tabla de puntuaciones— en disco o en cinta, y el nombre del fichero
no lo escribes entero: la primera letra la pone él según el dato (`H`, `S`, `G`
o `R`, de `0x68DA`), la extensión es siempre `VRM`, y detrás va el número de
catálogo del juego para que dos juegos no se pisen los ficheros.

La tabla de récords, recién borrada, sale con los seis puestos a nombre de la
casa: `KONAMI` (`0x4A35`).

Y sabe imprimir. `0x7655` lee la VRAM punto por punto y la gira, porque la
impresora imprime en vertical —ocho puntos por golpe de cabezal— y la pantalla
va en horizontal. Un punto sólo se imprime si su tinta se distingue del fondo
(`0x7537`): lo que sale en papel es la forma, no el color.
