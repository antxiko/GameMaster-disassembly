# El cartucho

16 KB en la página 1 (`0x4000`–`0x7FFF`), MSX1. La cabecera `AB` declara **sólo
INIT** (`0x4010`); STATEMENT, DEVICE y TEXT van a cero.

## El problema que tiene que resolver

Y es todo el diseño del cartucho.

**El Game Master vive en la página 1. El juego al que le hace trucos vive
también en la página 1**, en otra ranura. Los dos no pueden estar puestos a la
vez: en cuanto conmutas la ranura para leerle algo al juego, el Game Master
desaparece del mapa de memoria —y con él la instrucción que estaba
ejecutándose—.

Todo lo demás sale de ahí:

1. **Seis bloques de código se copian a la RAM y se ejecutan allí.** Conmutar
   la ranura desde la ROM sería serrar la rama en la que uno está sentado.
2. Lo que está en la ROM y hay que llamar con la otra ranura puesta se llama
   por **CALSLT** (`0x001C`) con la ranura en IY, o por la plantilla de
   `RST 30h` que `0x6AAA` monta en `0xD33E`.
3. Para leer un byte del vecino se usa **RDSLT** (`0x000C`). `0x4CA6` es el
   LDIR entre ranuras: copia BC bytes, uno a uno, porque no hay otra manera.

Al leer el listado hay que tener presente que **las direcciones absolutas de
esos bloques apuntan a donde se ejecutan, no a donde están guardadas**. Un
`jp 0xDA4C` del primer bloque es un salto a su propio byte `0x4C`. El trazador
lleva una directiva, `!reubica`, que le da esa correspondencia; con ella el
trazado pasó del 52,9 % al 60,0 %, y con las entradas de CALSLT que destapó,
al 64,2 %.

Los seis bloques:

| en el listado | se ejecuta en | qué es |
|---|---|---|
| `0x40DE`–`0x419A` | `0xDA00` | el barrido de ranuras buscando un cartucho |
| `0x41A8`–`0x422F` | `0xC000` | el que además reconoce la ROM de disco |
| `0x4264`–`0x426F` | `0xC800` | once bytes: el camino de vuelta desde el juego |
| `0x426F`–`0x4272` | `0xFEDA` | tres bytes: un `jp 0xC800` en un gancho de la BIOS |
| `0x4CCA`–`0x4D17` | `0xD814` | a donde salta el parche metido en el juego |
| `0x4D17`–`0x4E61` | `0xD170` | **el gancho de interrupción** |

## El mapa de la VRAM

No es el de siempre, y leerlo mal descoloca la pantalla entera. Los ocho
registros están en `0x6284` y los escribe `0x6273`:

| registro | valor | qué coloca |
|---|---|---|
| R0 | `0x02` | modo gráfico 2 |
| R1 | `0xE2` | pantalla y sprites de 16x16 |
| R2 | `0x0E` | tabla de nombres en `0x3800` |
| R3 | `0x7F` | **tabla de color en `0x0000`** |
| R4 | `0x07` | **tabla de patrones en `0x2000`** |
| R5 | `0x76` | atributos de sprite en `0x3B00` |
| R6 | `0x03` | patrones de sprite en `0x1800` |
| R7 | `0xE1` | el borde |

**R3 y R4 no son direcciones: son base y máscara**, y salen al revés de lo que
parece. El color acaba abajo, en `0x0000`, y los patrones arriba, en `0x2000`.
Es lo que coloca los cuatro bloques comprimidos del fondo del menú, y está
confirmado contra los registros que el emulador tiene de verdad.

Detrás de esos ocho hay **cuatro bytes más** (`0x628C`: `0E 00 18 06`) que no
lee nadie: el bucle de `0x6279` para a los ocho, y buscadas sus direcciones por
los 16.384 bytes del cartucho no aparece ni una referencia.

## La RAM

El cartucho borra los 8 KB de `0xC000` a `0xDFFF` al arrancar y los usa de
trabajo. Las variables que más importan:

| dirección | qué guarda |
|---|---|
| `0xD12E` | mi ranura · `0xD12F` la del vecino |
| `0xD130` | el gancho de interrupción **del juego**, guardado por el parche |
| `0xD136` | el código de operación: nibble alto qué se hace, bajo sobre qué |
| `0xD300`–`0xD31x` | la cabecera del juego reconocido |
| `0xD31A`, `0xD31B` | la fase y las vidas que ha pedido el usuario |
| `0xD317` | qué trucos hay pedidos |

Y una que hace dos trabajos: **`0xD12D` guarda el volumen del canal C del PSG y
a la vez es el byte bajo del IY** con el que se llama entre ranuras. Se puede
porque CALSLT sólo mira IYh.

## La marca oculta

En los últimos 22 bytes, `0x7FEA`–`0x7FFF`: **RC-735** y 19 bytes de katakana
que dicen 10バイタノシムカートリッジ —«el cartucho para disfrutar diez veces
más»—, que era el eslogan.

El formato lo descubrió **Manuel Pazos**
([@ManuelPazosMSX](https://twitter.com/ManuelPazosMSX)): el título invertido, su
longitud, el número de catálogo en BCD y un `0xAA` de cierre. Esta marca, de
paso, **confirma que el `0xBA` es el alargamiento ー**, que hasta ahora estaba
sin cerrar.

Delante de la marca hay 272 bytes de relleno a `0xFF` (`0x7EDA`–`0x7FEA`): lo
que sobró del cartucho.
