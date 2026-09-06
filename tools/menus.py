#!/usr/bin/env python3
"""Saca los menus del Game Master midiendo sobre el codigo, no a ojo.

Casi todo lo que hace este cartucho lo hace preguntando. Y todos sus menus
estan montados con las mismas tres piezas, siempre en el mismo orden:

    ld hl,<rotulos>     y `call 0x6294` los pinta: el formato de pantallas.py
    ld hl,<sitios>      la lista de donde puede ponerse el cursor
    ld b,<N>            cuantas lineas tiene
    call 0x6581         elige, y devuelve en A la linea elegida
    ...
    call 0x6368         despacha
    <tabla de N punteros>   <- PEGADA al call, dentro del flujo

De esas tres piezas salen tres bloques de datos, y los tres tienen su tamano
ESCRITO en el codigo que los usa:

  - los SITIOS son N palabras, N del `ld b`. Cada una es una direccion de la
    tabla de nombres (0x3800), asi que de ella salen la fila y la columna;
  - la TABLA DE DESPACHO son N palabras, la misma N;
  - y detras de algunas hay una tabla de BYTES, uno por linea, que es el codigo
    de operacion que la rutina deja en (0xD136).

Contar esos bytes a mano es justo la forma de equivocarse: por eso aqui se
leen. Lo que sale se compara con lo que el presupuesto da por sin explicar.

Uso: menus.py <listado.asm> [--notes]
     con --notes escribe las directivas D y F listas para el .notes.
"""
import re
import sys

ORG = 0x4000
NOMBRES = 0x3800
SELECTOR = 0x6581          # elegir opcion en un menu de B lineas
DESPACHADOR = 0x6368       # saltar a la entrada A de la tabla que sigue al CALL


def lee_listado(fn):
    """(direccion, texto de la instruccion) de cada linea de codigo."""
    fuera = []
    for ln in open(fn, encoding="utf-8"):
        m = re.match(r"^\t(.*?)\t*;([0-9a-f]{4})(?:\s|$)", ln)
        if m and not m.group(1).startswith(("defb", "defw")):
            fuera.append((int(m.group(2), 16), m.group(1).strip()))
    return fuera


def constante(txt, reg):
    m = re.match(r"ld %s,0([0-9a-f]{4})h$" % reg, txt)
    return int(m.group(1), 16) if m else None


def menus(codigo):
    """Cada `call 0x6581`, con el `ld b` y el `ld hl` que lo preceden.

    Se mira hacia atras desde el CALL y se para en el primer `ld b,N` y el
    primer `ld hl,NNNN` que aparezcan: son los que estan en curso. Diez
    instrucciones bastan de sobra -en el cartucho no hay ninguno a mas de
    cuatro- y asi no se cruza a la rutina de al lado.
    """
    fuera = []
    for i, (a, txt) in enumerate(codigo):
        if txt != "call L_%04X" % SELECTOR and txt != "call 0%04xh" % SELECTOR:
            continue
        cuantas, sitios = None, None
        for j in range(i - 1, max(-1, i - 11), -1):
            t = codigo[j][1]
            m = re.match(r"ld b,0([0-9a-f]{2})h$", t)
            if m and cuantas is None:
                cuantas = int(m.group(1), 16)
            if sitios is None:
                v = constante(t, "hl")
                if v is not None:
                    sitios = v
            if cuantas is not None and sitios is not None:
                break
        fuera.append((a, sitios, cuantas))
    return fuera


def despachos(codigo):
    """Cada `call 0x6368`: la tabla empieza en el byte de despues."""
    fuera = []
    for a, txt in codigo:
        if txt in ("call L_%04X" % DESPACHADOR, "call 0%04xh" % DESPACHADOR):
            fuera.append(a + 3)          # el CALL ocupa tres bytes
    return fuera


def main(argv):
    if not argv:
        print(__doc__)
        return 2
    codigo = lee_listado(argv[0])
    los_menus = menus(codigo)
    las_tablas = sorted(despachos(codigo))
    notas = "--notes" in argv

    if not notas:
        print("%d menus y %d tablas de despacho\n" % (len(los_menus),
                                                      len(las_tablas)))
        print("  call 0x6581  sitios          lineas   filas de la pantalla")
        for a, sitios, n in los_menus:
            print("  0x%04X       0x%04X..0x%04X    %-4s" % (
                a, sitios, sitios + 2 * n if n else 0, n))
        print("\n  tabla de despacho pegada al call 0x6368:")
        for a in las_tablas:
            print("    0x%04X" % a)
        return 0

    # Las directivas, para pegar en el .notes. El tamano de los sitios sale del
    # `ld b`; el de la tabla de despacho, del menu que la alimenta, y por eso
    # se emparejan por orden de aparicion.
    for a, sitios, n in los_menus:
        if not (sitios and n):
            continue
        print("D 0x%04X 0x%04X sitios_del_menu_de_0x%04X  Las %d filas en las "
              "que puede ponerse el cursor de este menu, en direcciones de la "
              "tabla de nombres. Las cuenta el ld b,0%02xh de 0x%04X"
              % (sitios, sitios + 2 * n, a, n, n, a))
        print("F 0x%04X 2" % sitios)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
