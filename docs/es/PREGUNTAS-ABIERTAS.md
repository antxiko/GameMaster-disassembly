# Preguntas abiertas

Lo que **no** se sabe. Está aquí y no disimulado en el resto de las páginas.

## Qué son RC-736 y RC-737

La tabla de trucos de `0x5B02` tiene rutina para los dos, así que el Game
Master sabe qué variables tocarles. Pero **no tenemos su ROM**, y el manual de
msxblue tampoco los lista.

De RC-737 se puede decir algo por lo que hace su rutina (`0x5DF1`): divide
entre ocho, topa la vuelta en dos y escribe las vidas directamente en `0xE053`
sin pasar por el truco universal. De RC-736 (`0x5DCB`) sólo que compone un byte
con la vuelta en el nibble alto y la fase en el bajo, y que `0x5E47` le da un
trato aparte —le mete un 4 en `0xD312`— que ningún otro juego tiene.

Con las ROM delante se cerraría en una tarde.

## Los cuatro bytes de `0x628C`

`0E 00 18 06`, pegados detrás de los ocho registros del VDP. El bucle de
`0x6279` para a los ocho y no los lee, y buscados los cuatro bytes por los
16.384 del cartucho no hay ni una referencia.

Parecen dos registros más de otra versión: el `0x0E` y el `0x18` encajarían
como R2 y R6 de una disposición distinta de la VRAM. **Es una suposición**, y
sin más versiones que mirar no pasa de ahí.

## Por qué esas cuatro rutinas están muertas

Se sabe que no las llama nadie —comprobado sobre los 16.384 bytes, buscando
referencias de 16 bits y saltos relativos— y qué hacían. No se sabe **de qué
compilación son restos**. De este cartucho hay tres, y las otras dos son las
japonesas de 1985, relocalizadas entre sí. Cotejarlas instrucción a instrucción
diría si esos trozos estaban vivos en alguna.

## El tercer truco

`0x54D1` mira tres bits de `0xD317`: el 0 lo pone MODIFY PLAYER NUMBER, el 1 lo
pone MODIFY STAGE NUMBER, y **el 2 no lo pone ninguno de los dos menús**. Su
rutina, `0x5561`, existe y hace algo.

O lo enciende un camino que no hemos recorrido, o es de una versión anterior.

## Las tres compilaciones

Están identificadas —dos japonesas de 1985 y la europea de 1986, que es la que
aquí se desensambla— y se sabe que son el mismo programa recompilado y
relocalizado, no versiones distintas. Lo que **no** se ha hecho es cotejarlas
instrucción a instrucción para saber qué cambió entre 1985 y 1986. La
traducción francesa y el parche de aficionado para MSX2 con memory mapper
derivan de la europea.

## El Game Master II

RC-755, 128 KB, y fuera de este desensamblado. Sabe más juegos y trae un editor
propio. Si el I identifica por una suma de 256 bytes, la pregunta obvia es qué
hace el II cuando se le enchufa un juego que no conoce.

## Qué pasa si le enchufas un cartucho que no es de Konami

`0x4124` prueba cuatro cosas en cadena y basta con que pase una: cabecera de
cartucho, el `ld (0xFD9B),hl` en los 256 primeros bytes, la segunda cabecera de
`0x4010`, o la suma en la tabla. Un cartucho ajeno que casualmente instale su
interrupción con esa misma instrucción **pasaría la segunda prueba** y el Game
Master intentaría hacerle trucos con la cabecera por defecto de `0x6034`.

Qué ocurre entonces no se ha probado, y merece probarse.
