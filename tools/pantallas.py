#!/usr/bin/env python3
"""Decodifica los rotulos de pantalla del Game Master y los enseña colocados.

EL FORMATO. Lo pinta 0x6294, y es una lista de trozos:

    [direccion de VRAM, 2 bytes] [caracteres...] 0xFE     <- otro trozo detras
    [direccion de VRAM, 2 bytes] [caracteres...] 0xFE
    ...
    0xFF                                                  <- y se acabo

Cada caracter se escribe con WRTVRM en la direccion que toca y la direccion se
incrementa, asi que un trozo es una linea horizontal. Las direcciones caen en
la tabla de nombres, que en este cartucho empieza en 0x3800: de ahi salen fila
y columna, (dir - 0x3800) / 32 y % 32.

LA FUENTE NO ES ASCII. El 0x40 es el espacio y no la arroba, y las letras van
corridas. La correspondencia sale de la propia tabla de patrones y esta abajo
en TABLA; con ella los rotulos se leen tal cual salen en pantalla.

Uso: pantallas.py <rom> [<direccion> ...]
Sin direcciones, busca todos los bloques que alguien pinta con 0x6294.
"""
import re
import sys

ORG = 0x4000
NOMBRES = 0x3800          # base de la tabla de nombres, de los registros del VDP
ANCHO = 32

FIN, SALTO = 0xFF, 0xFE


def caracter(v):
    """Un byte de la fuente del cartucho, en algo que se pueda leer.

    Las letras y las cifras estan donde el ASCII, asi que se leen tal cual.

    HAY DOS CODIGOS QUE SALEN COMO HUECO, y no esta comprobado en que se
    diferencian: el 0x00, que es el que separa las palabras de las opciones
    ('DISK' 0x00 'SAVE'), y el 0x40, que es el que rellena a los lados de los
    titulos (0x40 0x40 'MENU' 0x40 0x40). La sospecha -SIN COMPROBAR- es que el
    0x40 sea el hueco de los titulos, que van resaltados. Para saberlo hay que
    volcar la tabla de patrones del emulador y mirar los dos.
    """
    if v in (0x00, 0x40):
        return " "
    if 0x20 <= v < 0x7F:
        return chr(v)
    return "."


def bloque(d, a):
    """Lee un bloque de rotulos. Devuelve (trozos, direccion de despues)."""
    trozos = []
    while True:
        if a - ORG + 1 >= len(d):
            return trozos, a
        if d[a - ORG] == FIN:
            return trozos, a + 1
        destino = d[a - ORG] | (d[a - ORG + 1] << 8)
        a += 2
        texto = bytearray()
        while a - ORG < len(d) and d[a - ORG] not in (FIN, SALTO):
            texto.append(d[a - ORG])
            a += 1
        if a - ORG < len(d) and d[a - ORG] == SALTO:
            a += 1
        trozos.append((destino, bytes(texto)))
        # Un 0xFF justo detras cierra el bloque.
        if a - ORG < len(d) and d[a - ORG] == FIN:
            return trozos, a + 1


def pinta(trozos):
    """Coloca los trozos en una rejilla, como se ven en la pantalla."""
    celdas = {}
    for destino, texto in trozos:
        for i, v in enumerate(texto):
            o = destino - NOMBRES + i
            if 0 <= o < 24 * ANCHO:
                celdas[(o // ANCHO, o % ANCHO)] = caracter(v)
    if not celdas:
        return []
    f0, f1 = min(f for f, _ in celdas), max(f for f, _ in celdas)
    c0, c1 = min(c for _, c in celdas), max(c for _, c in celdas)
    return ["".join(celdas.get((f, c), " ") for c in range(c0, c1 + 1))
            for f in range(f0, f1 + 1)]


def quien_los_pinta(d):
    """Los `ld hl,nnnn` seguidos de `call 0x6294`, que son los que los usan."""
    out = []
    for m in re.finditer(rb"\x21(..)\xcd\x94\x62", d, re.S):
        out.append((ORG + m.start(), m.group(1)[0] | (m.group(1)[1] << 8)))
    return out


def main(argv):
    if not argv:
        print(__doc__)
        return 2
    with open(argv[0], "rb") as f:
        d = f.read()
    if len(argv) > 1:
        sitios = [(None, int(x, 0)) for x in argv[1:]]
    else:
        sitios = quien_los_pinta(d)
        print("%d bloques de rotulos, cada uno con su `ld hl` y su call 0x6294\n"
              % len(sitios))
    for desde, a in sitios:
        trozos, fin = bloque(d, a)
        cab = "0x%04X..0x%04X  (%d bytes, %d trozos)" % (a, fin - 1, fin - a,
                                                         len(trozos))
        if desde is not None:
            cab += "   <- ld hl en 0x%04X" % desde
        print(cab)
        for ln in pinta(trozos):
            print("      |%s|" % ln)
        print()
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
