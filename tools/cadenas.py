#!/usr/bin/env python3
"""Recorre los mensajes del Game Master y mide donde acaba cada uno.

Los avisos del cartucho -los errores de disco, los de cinta, los de la
impresora- son cadenas sueltas que cierra un 0xFF, y delante de un grupo suele
haber una tabla de punteros que 0x626E indexa. Contar esos bytes a mano es la
forma de equivocarse; aqui se leen.

LA FUENTE. Las letras estan donde el ASCII, pero el hueco NO es el 0x20: el
0x00 separa palabras y el 0x40 rellena a los lados de los titulos. Los dos se
enseñan como espacio, con el 0x40 en gris, para que se vea cual es cual.

LA COMPROBACION QUE VALE. Si se recorre un grupo entero de cadenas y la ultima
acaba EXACTAMENTE donde el presupuesto dice que se acaba el hueco, el formato
es ese. Y si sobra o falta un byte, no lo es. Por eso `--encaja` compara el
final medido con el que se le pida, en vez de dar por bueno lo que salga.

Uso: cadenas.py <rom> <ini> [<fin>]        una tirada de cadenas
     cadenas.py <rom> --tabla <ini> <n>    n punteros y las cadenas a las que van
"""
import sys

ORG = 0x4000
FIN = 0xFF


def legible(b):
    """El texto de una cadena, con los dos huecos distinguidos."""
    fuera = []
    for c in b:
        if c == 0x00:
            fuera.append(" ")
        elif c == 0x40:
            fuera.append("_")
        elif 32 <= c < 127:
            fuera.append(chr(c))
        else:
            fuera.append("<%02X>" % c)
    return "".join(fuera)


def cadena(d, a):
    """Los bytes de la cadena que empieza en `a` y la direccion de despues."""
    i = a - ORG
    while i < len(d) and d[i] != FIN:
        i += 1
    return d[a - ORG:i], ORG + i + 1


def tirada(d, ini, fin=None):
    """Todas las cadenas seguidas desde `ini`, hasta `fin` si se da."""
    fuera, a = [], ini
    while a - ORG < len(d):
        b, sig = cadena(d, a)
        fuera.append((a, sig, b))
        a = sig
        if fin is not None and a >= fin:
            break
        if fin is None and len(fuera) > 64:
            break
    return fuera


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    with open(argv[0], "rb") as f:
        d = f.read()

    if argv[1] == "--tabla":
        ini, n = int(argv[2], 0), int(argv[3], 0)
        print("tabla de %d punteros en 0x%04X..0x%04X" % (n, ini, ini + 2 * n))
        destinos = []
        for i in range(n):
            p = d[ini - ORG + 2 * i] | (d[ini - ORG + 2 * i + 1] << 8)
            destinos.append(p)
            print("  [%d] -> 0x%04X" % (i, p))
        print()
        for a in sorted(set(destinos)):
            b, sig = cadena(d, a)
            print("  0x%04X..0x%04X  (%2d)  |%s|" % (a, sig, sig - a, legible(b)))
        print("\n  la ultima acaba en 0x%04X"
              % max(cadena(d, a)[1] for a in destinos))
        return 0

    ini = int(argv[1], 0)
    fin = int(argv[2], 0) if len(argv) > 2 else None
    for a, sig, b in tirada(d, ini, fin):
        print("  0x%04X..0x%04X  (%2d)  |%s|" % (a, sig, sig - a, legible(b)))
    if fin is not None:
        ultima = tirada(d, ini, fin)[-1][1]
        print("\n  medido hasta 0x%04X, pedido hasta 0x%04X: %s"
              % (ultima, fin, "ENCAJA" if ultima == fin else "NO ENCAJA"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
