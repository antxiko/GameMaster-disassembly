# Las pantallas

Ninguna de estas imágenes es una captura. Todas salen de ejecutar en Python los
mismos pasos que ejecuta el Z80, y están **cotejadas byte a byte contra la VRAM
de openMSX**.

## Lo que dice el cotejo

`make vram` deja correr el cartucho, vuelca los 16.384 bytes de VRAM en cinco
instantes y los compara con los que montamos nosotros. El mejor volcado cae a
**un solo byte distinto**, y ese byte no es un error:

| zona | distintos |
|---|---|
| tabla de color, `0x0000`–`0x17FF` | 0 de 6.144 |
| patrones de sprite, `0x1800`–`0x1FFF` | 0 de 2.048 |
| tabla de patrones, `0x2000`–`0x37FF` | 0 de 6.144 |
| tabla de nombres, `0x3800`–`0x3AFF` | **1** de 768 |
| atributos de sprite, `0x3B00`–`0x3B7F` | 0 de 128 |

Ese byte es `0x39A9`: el emulador tiene `0xF5` y nosotros `0xAC`. Son los dos
estados del **cursor parpadeando**, que `0x527C` alterna cada `0x8000` vueltas
del contador de `0xD147`.

Y en otros instantes discrepan **dieciocho** bytes, que son la otra cosa que se
mueve: `0x3B08`–`0x3B17` con los atributos de sprite de `0x798F` en vez de los
de `0x797F`, más las casillas que los acompañan. Es **el adorno del menú**, que
`0x52C3` cambia con el bit 0 de `0xD144`. Un volcado cualquiera cae en uno de
los dos fotogramas.

El emulador confirmó además los siete registros del VDP de `0x6284`, R3=`0x7F`
y R4=`0x07` incluidos.

## La pantalla de título

![La pantalla de título](../imagenes/titulo.png)

Seis piezas, en este orden (`0x77D6` y `0x7805`): los cuatro bloques
comprimidos del fondo, dos rectángulos de caracteres, el bloque de rótulos con
el `© KONAMI 1986` que fecha la compilación, otros dos comprimidos y los 24
bytes de atributos de sprite.

Montarla tiene una trampa de orden. El fondo del modo RANKING se carga **antes**
que el título, y su tabla de color va apareciendo poco a poco: `0x533B` la pinta
de `0xF0` a razón de 21 bytes por pasada, seis pasadas, `0x0880`–`0x0C6F`
clavado. Puesto al final, ese relleno se come el `0xFC` que `0x780D` deja en
`0x0980` y los colores que `0x77E4` suelta en `0x0C00`: 448 bytes de diferencia
contra el emulador.

## Los tres punteros del menú de arranque

![Señalando GAME](../imagenes/arranque-0.png)
![Señalando MODIFY](../imagenes/arranque-1.png)
![Señalando SELF](../imagenes/arranque-2.png)

`0x4FA9`, `0x4FB5` y `0x4FC1`: doce casillas cada uno, tres filas de cuatro
—el `bc,0x0304` de `0x4F91`—, pintadas siempre en el mismo sitio, la VRAM
`0x39AB`. **Leídos como bytes no dicen nada.** Dibujados se ve lo que son: un
puntero de tiza que cambia de inclinación para señalar GAME, MODIFY o SELF en
la pizarra.

## Los menús que montan pantalla propia

![MODIFY MODE](../imagenes/menu-modify.png)
![SELF MODE](../imagenes/menu-self.png)
![Modo RANKING](../imagenes/menu-modo-ranking.png)
![Cargar pantalla](../imagenes/menu-cargar-pantalla.png)
![Modo pantalla](../imagenes/menu-modo-pantalla.png)

Éstos borran `0x200` bytes desde `0x3880` y pintan las bandas de colores de
arriba y abajo. Las bandas no son un dibujo guardado: las escribe el bucle de
`0x504E`, que repite cada casilla **dos veces** y avanza, con B=`0x10`, o sea
32 bytes —una fila entera— por vuelta; como A empieza en 1 y da la vuelta con
`and 0x0F`, la fila sale `1,1,2,2,…,15,15,0,0`. El `dec c` de `0x505F` la
repite cuatro veces, y `0x503C` hace todo eso dos veces: las filas 0 a 3 y las
20 a 23.

## Los menús que se abren sobre el juego

![El menú de disco y cinta](../imagenes/menu-principal.png)
![Qué dato se guarda](../imagenes/menu-guardar.png)
![Qué dato se carga](../imagenes/menu-cargar.png)
![El modo ranking](../imagenes/menu-ranking.png)
![Elegir impresora](../imagenes/menu-impresora.png)

Éstos sólo borran `0x100` bytes desde `0x3A00`, las ocho filas de abajo. **En
la máquina real la mitad de arriba es la partida corriendo**: `0x4275` llama
antes a la rutina que se lleva la VRAM del juego a la RAM para poder
devolverla. Aquí salen sobre negro porque no hay juego que poner.

Que el menú de cargar no tenga SCREEN DATA no es un descuido: en cinta no cabe.
