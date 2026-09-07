# Hallazgos

## La instrucción que llevan los 40 cartuchos de Konami

El Game Master se cuela en el juego buscando `9B FD` en los 256 primeros bytes
de su arranque: el operando de `ld (0xFD9B),hl`, con el que un juego de Konami
instala su rutina de interrupción en el gancho H.KEYI.

Eso convierte una decisión de estilo de la casa en la llave de todo el
cartucho. Comprobado sobre las 42 ROM de cartucho de la colección: **las 40 de
Konami la llevan**. Las dos únicas que no son Casio World Open —que no es de
Konami— y el propio Game Master.

## La segunda cabecera, vista desde el otro lado

**Siete** de las ROM que hay aquí llevan en `0x4010` una segunda cabecera que
no hacía nada visible, y cinco de ellas están desensambladas en esta serie. El
marcador de delante no va por número de catálogo, va por **año**:

| marcador | año | cartuchos |
|---|---|---|
| `AB` | 1985 | Konami's Soccer y Football (RC-732), Konami's Boxing (RC-736), Yie Ar Kung-Fu II (RC-737) |
| `CD` | 1986-87 | The Goonies (RC-734), Knightmare (RC-739), Nemesis (RC-742), F-1 Spirit (RC-752) |

RC-734 es de 1986 y RC-736 y RC-737 de 1985, que es lo que descarta el número
como criterio. Se sabía que la cabecera estaba; no para qué.

Es para esto. **El Game Master la lee.** Los 17 bytes de `0x4014`–`0x4024` son
punteros a las variables del juego en su RAM: dónde guarda las vidas, dónde la
fase, dónde el marcador. Un juego que la traiga se explica solo; el resto
necesitan que el Game Master les invente una.

## La tabla de firmas: 62 entradas para 28 juegos

Para los juegos que no llevan cabecera —casi todo el catálogo— `0x5EF5` **suma
los 256 bytes de `0x5000` a `0x50FF`** de la ROM del vecino y busca esa suma de
16 bits en la tabla de `0x5F3A`. 62 entradas de cuatro bytes que apuntan a 29
cabeceras postizas de 19, para 28 juegos: la tabla lleva las compilaciones
alternativas de cada uno, hasta cuatro.

**La tabla está cotejada, no leída.** De los 28, 25 se han comprobado sumando
de verdad los bytes de sus ROM. Los otros tres —Circus Charlie, Magical Tree y
Comic Bakery— no tienen ROM aquí y salen del manual publicado en
[msxblue](http://www.msxblue.com/manual/gamemaster1_c.htm).

Y binario y manual coinciden **hasta en los huecos**: ni uno ni otro tienen
RC-719, RC-722 ni RC-726.

Un aviso sobre el cotejo: F-1 Spirit da la misma suma que Billiards (`0x7894`).
Es una colisión de una suma de 16 bits sobre 256 bytes, no una entrada de la
tabla: F-1 Spirit es un MegaROM y lleva su propia cabecera `CD`, así que el
Game Master nunca llega a sumarle nada.

## Konami dice desde dentro que dos de sus juegos son el mismo

La tabla de trucos de `0x5B02` da una rutina por juego, y hay dos parejas que
**comparten la suya**.

Una es RC-710 y RC-711, los dos Hyper Olympic, que se distinguen dentro
comparando el número de catálogo: la única diferencia entre los dos cartuchos,
para el Game Master, son ocho bytes.

La otra es **RC-700 y RC-716**. Para el Game Master, Athletic Land y Cabbage
Patch Kids son el mismo programa y se les tocan las mismas variables. Es
exactamente lo que se midió al desensamblar el segundo —arrastra 439 bytes del
primero que no lee nadie—, ahora dicho por la propia Konami desde dentro de su
cartucho de trucos.

## Antarctic Adventure necesita dos listas de fases

`0x5BC7` y `0x5BD1`, diez bytes cada una: los valores que hay que meterle en su
`0xE0E2` para empezar en cada etapa. `0x5BB4` elige una u otra según `0xD303`,
que dice cuál de las dos compilaciones de RC-701 es la de al lado.

Las dos listas son distintas —`0x0D` contra `0x0F` en la tercera, `0x35` contra
`0x3C` en la última—, y eso es la prueba de que Konami sabía que había dos
compilaciones circulando y de que la variable no cae en el mismo sitio en las
dos.

## Las fases que ofrece cuadran con lo medido en cada juego

El divisor de cada rutina de truco es cuántas fases tiene ese juego. Y coincide
con lo que se midió al desensamblarlos: **quince en King's Valley**, trece en
Hyper Rally, tres pruebas en Hyper Sports 2, diez pistas en Antarctic
Adventure.

Sky Jaguar es el caso interesante: divide entre ocho, pero lo que escribe **no
es un número de fase, es una posición**. El resto por 256, de `0x0000` a
`0x0700`. Encaja con lo que se sabía del juego: no tiene fases separadas, es un
solo recorrido continuo.

## El aviso de truco activo es el LED de CAPS

El cartucho no puede pintar en la pantalla del juego sin estropearla, así que
avisa con la luz del teclado: `0x4E70` llama a CHGCAP cada vez que se congela o
se descongela la partida.

Y al congelar calla el PSG de verdad: `0x4E85` se guarda los volúmenes de los
tres canales antes de ponerlos a cero, y `0x4EF8` los devuelve al reanudar. Sin
eso, la última nota se quedaría sonando.

## Un byte que hace dos trabajos

`0xD12D` guarda el volumen del canal C del PSG **y a la vez** es el byte bajo
del IY con el que se llama entre ranuras. Se puede porque CALSLT sólo mira
IYh, que es `0xD12E` y lleva la ranura.

## Los menús se abren encima del juego

Los de disco y cinta sólo borran `0x100` bytes desde `0x3A00`, las ocho filas
de abajo, y antes `0x4275` ha llamado a la rutina que se lleva la VRAM del
juego a la RAM. En la máquina real, la mitad de arriba de esas pantallas es la
partida corriendo.

## Cuatro rutinas y dos puertas a las que no llega nadie

`0x6445`, `0x6787`, `0x6904` y `0x6938` desensamblan a Z80 correcto, empiezan
justo detrás de un `ret` y acaban justo donde arranca una etiqueta que sí se
usa. Pero no hay ni una referencia de 16 bits ni un salto relativo que caiga en
ellos, buscados por los 16.384 bytes del cartucho.

Más dos puertas de dos bytes: `0x5022` y `0x6FB5`, cada una un `ld b,N` puesto
para entrar a la rutina de al lado con otro valor, a las que no salta nadie.

No es el espejismo de leer un operando como opcode —no caen dentro de otra
instrucción—. Son restos de una compilación anterior: de este cartucho hay tres.

Y hay cuatro bytes más en el mismo caso: `0x628C`, pegados detrás de los ocho
registros del VDP. El bucle que los escribe para a los ocho.

## Sí lleva la marca oculta, y confirma un carácter

En los últimos 22 bytes: **RC-735** y 19 bytes de katakana que dicen
10バイタノシムカートリッジ —«el cartucho para disfrutar diez veces más»—, que
era su eslogan.

El formato lo descubrió **Manuel Pazos**
([@ManuelPazosMSX](https://twitter.com/ManuelPazosMSX)). Esta marca, de paso,
**confirma que el `0xBA` es el alargamiento ー**, que en los desensamblados
anteriores de la serie estaba sin cerrar.

## El nombre del fichero lo escribe medio el cartucho

Al guardar en disco no tecleas el nombre entero: la primera letra la pone él
según el dato —`H`, `S`, `G` o `R`, de la tabla de `0x68DA`—, la extensión es
siempre `VRM`, y detrás va el número de catálogo del juego para que dos juegos
no se pisen los ficheros.

Y la tabla de récords, recién borrada, sale con los seis puestos a nombre de la
casa: `KONAMI`, en `0x4A35`.
