# Konami's Game Master (RC-735) — desensamblado comentado

*(Also available [in English](README.md).)*

**[→ Leerlo en la web](https://antxiko.github.io/GameMaster-disassembly/es/)**

Desensamblado completo y comentado de Konami's Game Master para MSX1 — la
European Version de 1986, RC-735, 16 KB.

No es un juego. Es el **cartucho de trucos** de Konami: se enchufa en la ranura
de al lado, reconoce el juego que tiene enfrente y le parchea el arranque en la
RAM para quedarse con su interrupción. Es el único cartucho comercial de MSX
cuyo trabajo entero consiste en leer y modificar otro cartucho.

| | |
|---|---|
| binario explicado | **100 %** — 16.384 de 16.384 bytes |
| código trazado | 10.522 bytes (64,2 %) |
| datos identificados | 5.862 bytes (35,8 %) |
| rutinas | 663, **ninguna por debajo del 10 %** |
| densidad de comentario | **22,1 %** |
| juegos que reconoce | 28 |
| tests | 44 |

## Cómo se cuela

Copia a la RAM los 256 primeros bytes del arranque del cartucho vecino y busca
ahí `9B FD` — el operando de `ld (0xFD9B),hl`, la instrucción con la que un
juego de Konami instala su rutina de interrupción—. La cambia por cinco bytes,
con lo que el gancho del juego queda guardado y el control pasa al Game Master,
y ejecuta la copia parcheada.

Comprobado sobre las 42 ROM de cartucho de la colección: **las 40 de Konami
llevan esa instrucción**.

## Reproducirlo

El cartucho no se distribuye. Pon tu copia en la raíz como `gamemaster.rom`
(sha256 `3160911ae025…`) y:

    make comprueba   # comprueba que es el mismo volcado
    make             # traza, genera, reensambla y compara
    make imagenes    # dibuja las pantallas desde la ROM
    make vram        # las cotea contra la VRAM de openMSX

`make verify` reensambla el listado y lo compara con el original byte a byte.

## Las imágenes

Ninguna imagen de aquí es una captura. Se montan ejecutando en Python los
mismos pasos que ejecuta el Z80, y están cotejadas byte a byte contra la VRAM
del emulador: de los 16.384 bytes, el único que discrepa es el cursor
parpadeando.

## Créditos

La marca oculta de Konami de los últimos 22 bytes —el número de catálogo y el
título en katakana— la descubrió **Manuel Pazos**
([@ManuelPazosMSX](https://twitter.com/ManuelPazosMSX)).

Ver [AVISO-LEGAL.md](AVISO-LEGAL.md) y [LICENSE](LICENSE).
