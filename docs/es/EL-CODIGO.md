# El código

**10.522 bytes de código** trazado (64,2 %) y **5.862 de datos** (35,8 %), que
suman los 16.384 del cartucho: **el 100 % explicado, cero bytes sin asignar**.
663 rutinas, **22,1 % de las instrucciones comentadas** y **ninguna rutina por
debajo del 10 %**.

## Cómo se cuela dentro del juego

Es la idea central, y está en `0x4C76`.

1. Copia los **256 primeros bytes del INIT** del juego a `0xD861`, leyéndolos
   de la otra ranura con RDSLT.
2. Busca en esa copia la secuencia `9B FD`, que es el operando de
   `ld (0xFD9B),hl` —la instrucción con la que el juego instala su rutina de
   interrupción en el gancho H.KEYI de la BIOS—.
3. La sustituye por los cinco bytes de `0x4CB9`. Con el opcode `22` que ya
   había delante, la instrucción pasa de

       22 9B FD        ld (0xFD9B),hl

   a

       22 30 D1        ld (0xD130),hl   ; el gancho del juego, guardado
       CD 14 D8        call 0xD814      ; y el control, para el Game Master

4. Y ejecuta **la copia parcheada, no la original**.

O sea que no parchea el juego: parchea la **copia en RAM de su arranque**. A
partir de ahí se ejecuta una vez por fotograma dentro del juego y puede tocarle
las variables.

Funciona con todo el catálogo porque todos los cartuchos de Konami arrancan
igual. Comprobado sobre las 42 ROM de cartucho de la colección: **las 40 de
Konami llevan esa instrucción** en los 256 bytes de su INIT. Las dos únicas que
no son Casio World Open —que no es de Konami— y el propio Game Master.

## Cómo sabe qué juego tiene al lado

Dos caminos, y el orden importa (`0x5E64`):

**1. La segunda cabecera.** Lee dos bytes de `0x4010` del vecino y los compara
con `AB` y con `CD`. Si es `AB` se trae 19 bytes tal cual; si es `CD`, 21, y
los reparte según un **byte de banderas**: cada `rra` saca un bit que dice si
el campo que viene está o no, y el que no viene se queda con el valor por
defecto de `0x6034`. De las 42 ROM de la colección sólo cinco llevan esa
cabecera.

**2. La tabla de firmas.** Para todo lo demás —que es casi todo el catálogo—,
`0x5EF5` **suma los 256 bytes que van de `0x5000` a `0x50FF`** de la ROM del
vecino y busca esa suma de 16 bits en la tabla de `0x5F3A`: 62 entradas de
cuatro bytes que apuntan a 29 cabeceras postizas de 19 bytes, para 28 juegos.
Son 29 y no 28 porque Antarctic Adventure necesita dos, una por cada pareja de
compilaciones suyas, y se diferencian en **un solo byte**.

En los dos casos el resultado acaba en `0xD300` y siguientes, en el mismo
formato: las dos parejas BCD del número de catálogo y detrás los punteros a las
variables del juego en su RAM.

## Los trucos

La tabla de `0x5B02` tiene veintiuna entradas de tres bytes —número de catálogo
y rutina— y es donde vive lo que cada juego necesita de particular. Casi todas
acaban saltando a `0x5D13`, que es el truco universal de tres instrucciones.

Lo que cambia es la cuenta. `0x5E0F` divide entre C por restas y
desplazamientos, y ese C es **cuántas fases tiene el juego**:

| juego | entre | qué escribe |
|---|---|---|
| RC-701 Antarctic Adventure | 10 | la pista, en `0xE0E2`, **con dos tablas** |
| RC-710 / RC-711 Hyper Olympic | 4 | la prueba, y ocho bytes por cartucho |
| RC-713 Magical Tree | 9 | el nivel y **el marcador de partida** |
| RC-717 Hyper Sports 2 | 3 | la prueba |
| RC-718 Hyper Rally | 13 | la etapa y su pareja de bytes |
| RC-721 Sky Jaguar | 8 | no una fase: **una posición** del recorrido |
| RC-727 King's Valley | 15 | la sala, la vuelta y una pareja de la tabla |
| RC-730 Road Fighter | 6 | el recorrido, y limpia la pantalla |

Y dos parejas **comparten rutina**: RC-710 con RC-711 —se distinguen dentro
comparando el número—, y **RC-700 con RC-716**, o sea Athletic Land y Cabbage
Patch Kids.

## Los menús: tres piezas y siempre las mismas

Trece menús, todos montados igual:

    ld hl,<rótulos>      y `call 0x6294` los pinta
    ld hl,<sitios>       dónde puede ponerse el cursor, una fila por línea
    ld b,<N>             cuántas líneas tiene
    call 0x6581          elige, y devuelve en A la elegida
    ...
    call 0x6368          despacha
    <tabla de N punteros>    ← PEGADA al call, dentro del flujo

`0x6368` hace `pop hl` para recoger la dirección de retorno —que es el byte de
después del CALL— y de ahí lee la palabra número A. **La tabla va dentro del
código.** Son catorce, y su tamaño no está contado a ojo: sale del `ld b,N` que
precede al `call 0x6581`. `tools/menus.py` las lee.

## La fuente y los formatos

- **Los rótulos** (`0x6294`): `[dirección de VRAM][caracteres]0xFE`, y `0xFF`
  cierra. Las letras están donde el ASCII, pero **el hueco no es el `0x20`**:
  el `0x00` separa palabras y el `0x40` es el hueco resaltado con el que se
  enmarcan los títulos (`@@MENU@@`).
- **El descompresor** (`0x62F7`): RLE que escribe **directo al puerto del
  VDP**, sin pasar por la BIOS. Cuenta de siete bits, bit 7 puesto son
  literales y a cero una repetición; cuenta cero cierra, y si el byte no era
  cero entero, detrás viene **otra dirección de VRAM y más tiradas**. Ese
  último caso es fácil de pasar por alto y deja la descompresión cortada a la
  primera.
- Los `push hl / pop hl` de en medio no hacen nada: son la espera que el VDP
  necesita entre byte y byte.

## Código al que no llega nadie

Cuatro trozos —`0x6445`, `0x6787`, `0x6904` y `0x6938`— desensamblan a Z80
correcto y encajado: empiezan justo detrás de un `ret` y acaban justo donde
arranca una etiqueta que sí se usa. Pero **no hay ni una referencia de 16 bits
ni un salto relativo que caiga en ellos**, buscados por los 16.384 bytes.

Más dos puertas de dos bytes (`0x5022` y `0x6FB5`), cada una un `ld b,N` puesto
para poder entrar a la rutina de al lado con otro valor, a las que no salta
nadie.

No es el espejismo de leer un operando como opcode, porque no caen dentro de
otra instrucción. Son restos de una compilación anterior: de este cartucho hay
tres.
