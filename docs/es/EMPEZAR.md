# Empezar

Este repositorio no trae el cartucho. Trae **lo que hace falta para volver a
generar el listado desde tu propia copia** y comprobar que sale el mismo
binario, byte a byte.

## Lo que necesitas

- **La ROM**, en la raíz y con el nombre `gamemaster.rom`. Es la *European
  Version* de 1986, 16.384 bytes exactos. Su sha256:

      3160911ae025207c80c40630f8ce94f857e7e820c97a437152124def25b0f7ee

- **Python 3** y **pasmo** para reensamblar.
- **openMSX**, sólo si quieres cotejar las imágenes contra la VRAM de verdad.

## Los cuatro comandos

    make comprueba   # que tu ROM es la misma: compara el sha256
    make listado     # traza el flujo y escribe src/gamemaster.asm
    make verify      # reensambla y compara con el original, byte a byte
    make             # todo lo anterior, más sanity y los tests

`make verify` es la prueba que decide si el desensamblado es fiable. Si el
binario reensamblado no da el mismo sha256, el listado miente en alguna parte.

## Lo que el reensamblado NO comprueba

Que salga el mismo binario no dice nada sobre si los bytes están **leídos**
bien: unos gráficos marcados como código dan el mismo fichero, porque los
bytes no cambian, sólo cambia lo que decimos de ellos. Para eso está
`make sanity`, que corre cuatro comprobaciones:

- ninguna zona declarada como datos puede salir como código;
- ningún punto de entrada puede caer dentro de una zona de datos —si las dos
  cosas están declaradas a la vez, una es falsa—;
- **ni un byte del cartucho sin asignar**: los 16.384 tienen que ser código
  alcanzado por el trazado o un rango de datos con nombre y explicación;
- y los rangos declarados se cruzan contra el trazado.

## Las imágenes

    make imagenes    # dibuja las pantallas desde la ROM
    make vram        # las cotea contra la VRAM de openMSX, byte a byte

Ninguna imagen de esta web es una captura. Todas salen de ejecutar en Python
los mismos pasos que ejecuta el Z80: el descompresor de `0x62F7`, el pintor de
rectángulos de `0x7852` y el de rótulos de `0x6294`. `make vram` deja correr el
cartucho en el emulador, vuelca los 16 KB de VRAM y los compara uno a uno con
los que montamos nosotros.

## Cómo está organizado

    src/gamemaster.entries   los puntos de entrada al trazado, con su porqué
    src/gamemaster.nocode    los rangos que NO son código
    src/gamemaster.notes     las anotaciones: etiquetas, comentarios y datos
    src/gamemaster.asm       el listado, GENERADO — no se edita a mano
    tools/                   el trazador, el generador y las comprobaciones
    tests/                   lo que vigila que la documentación no mienta

El listado **se genera**. Todo lo que quieras cambiar va en el `.notes`, que
ancla cada comentario a una dirección: así sobreviven a un retrazado.

## Las herramientas propias de este cartucho

    tools/rle.py          el descompresor de 0x62F7, rehecho en Python
    tools/pantallas.py    decodifica los bloques de rótulos y los enseña
    tools/cadenas.py      recorre los mensajes y mide dónde acaban
    tools/menus.py        saca los trece menús midiendo sobre el código
    tools/graficos.py     monta las pantallas desde la ROM
    tools/coteja_vram.py  las compara con las del emulador
