# En el emulador

## Arrancarlo solo

    "C:/Program Files/openMSX/openmsx.exe" -machine Philips_VG_8020 \
        -cart gamemaster.rom

Sin juego al lado, el cartucho se queda para él: monta su pantalla de título y
espera. `0x4079` lee la línea 7 del teclado y, si esa tecla está pulsada, no
entra al juego aunque lo haya.

## Arrancarlo con un juego

Que es para lo que sirve. Dos ranuras:

    openmsx.exe -machine Philips_VG_8020 \
        -cart gamemaster.rom -cartb <juego>.rom

El Game Master tiene que ir en la ranura **anterior** a la del juego: `0x402A`
calcula la del vecino sumándole 4 a la suya si está en una expandida, y 1 si
no.

## Volcar la VRAM y cotejar las imágenes

Es la comprobación que decide si las pantallas de esta web son las del
cartucho:

    make vram

Lo que hace por dentro:

    GM_SALIDA=work/omsx openmsx.exe -machine Philips_VG_8020 \
        -cart gamemaster.rom -script tools/omsx_vram.tcl
    python3 tools/coteja_vram.py gamemaster.rom 0x4000 work/omsx

`tools/omsx_vram.tcl` no pone ningún punto de ruptura: vuelca los 16.384 bytes
de VRAM y los ocho registros del VDP en cinco instantes por reloj emulado —a
los 8, 12, 16, 20 y 25 segundos—, porque **entre el arranque de la BIOS y el
barrido de ranuras que hace el cartucho, la pantalla de título tarda en
montarse**. El primer volcado que se probó, a los 6 segundos, salía negro
entero.

`tools/coteja_vram.py` compara byte a byte, elige el volcado que más se
parezca, comprueba los registros del VDP y separa las diferencias en dos
grupos: las de direcciones **animadas** —que están declaradas, con quién las
mueve— y las que no. Si aparece una que no está en la lista, sale en rojo con
su dirección.

## Los dos fotogramas

La pantalla de título no está quieta, y por eso un cotejo no puede dar cero
siempre:

- **`0x39A9`**, el cursor: `0x527C` alterna entre `0xAC` y `0xF5` cada `0x8000`
  vueltas del contador de `0xD147`.
- **`0x3B08`–`0x3B17`** y las casillas que los acompañan: `0x52C3` copia los
  atributos de sprite de `0x797F` o los de `0x798F` según el bit 0 de `0xD144`,
  que sube en cada vuelta del bucle del menú. Es el adorno moviéndose.

Un volcado cualquiera cae en uno de los dos fotogramas. Lo que se exige es que
todo lo demás esté a cero.

## Mirar por dentro mientras corre

Las variables que más dicen, en la consola de openMSX:

    debug read memory 0xD12E    ; mi ranura
    debug read memory 0xD12F    ; la del vecino
    debug read memory 0xD301    ; el número de catálogo reconocido
    debug read memory 0xD317    ; qué trucos hay pedidos
    debug read memory 0xD31A    ; la fase pedida
    debug read memory 0xD31B    ; las vidas pedidas

Si `0xD301` está a `0xFF`, el cartucho no ha reconocido nada: o no hay juego al
lado, o su suma no está en la tabla.

Y para ver el momento en el que se cuela:

    debug set_bp 0x4C8F         ; justo antes del cpir que busca el 0x9B
    debug set_bp 0x4C9B         ; y cuando ya lo ha encontrado

Entre esos dos puntos, `0xD861` y siguientes tienen la copia en RAM del
arranque del juego, todavía sin parchear.
