#!/usr/bin/env python3
"""Compara la VRAM que monta graficos.py con la que el VDP tiene de verdad.

Mirar el dibujo no basta: un PNG puede parecer correcto y tener mal media tabla
de color. Aqui se comparan los 16384 bytes, uno a uno, contra los volcados que
tools/omsx_vram.tcl saca de openMSX.

LO QUE NO PUEDE CERRAR A CERO, y por que. La pantalla de titulo del Game Master
NO esta quieta: tiene dos cosas animadas, y las dos estan explicadas en el
listado, asi que sus bytes se cuentan aparte en vez de disimularse.

  - **el cursor que parpadea**: 0x527C escribe en la VRAM 0x39A9 un 0xAC o un
    0xF5 segun el bit 15 del contador de 0xD147. Un byte.
  - **el adorno del menu, que se mueve**: 0x52C3 copia a la VRAM 0x3B08 los
    cuatro atributos de sprite de 0x797F o los de 0x798F segun el bit 0 de
    (0xD144), que 0x5291 incrementa en cada vuelta. Sus casillas acompanan.
    Diecisiete bytes.

O sea que un volcado cualquiera cae en uno de los dos fotogramas. Lo que se
exige es que TODO LO DEMAS este a cero, y que las diferencias que salgan sean
justo esas direcciones y no otras.

Uso: coteja_vram.py <rom> <org> <carpeta de volcados>
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from graficos import pantalla_de_titulo                         # noqa: E402

ZONAS = [
    ("tabla de color", 0x0000, 0x1800),
    ("patrones de sprite", 0x1800, 0x2000),
    ("tabla de patrones", 0x2000, 0x3800),
    ("tabla de nombres", 0x3800, 0x3B00),
    ("atributos de sprite", 0x3B00, 0x3B80),
]

# Las direcciones que pueden discrepar por estar animadas, con quien las mueve.
ANIMADAS = {0x39A9: "el cursor que parpadea (0x527C)"}
for _i in range(0x3B08, 0x3B18):
    ANIMADAS[_i] = "el adorno del menu (0x52C3)"
for _i in (0x3A06,) + tuple(range(0x3A25, 0x3A28)) + tuple(range(0x3A45, 0x3A48)):
    ANIMADAS[_i] = "las casillas del adorno del menu"

# Los ocho registros que el cartucho le da al VDP (0x6284), que son los que
# colocan cada tabla. Si el emulador no los tiene asi, lo que se compara no es
# lo mismo y el resto del cotejo no significa nada.
REGISTROS = [0x02, 0xE2, 0x0E, 0x7F, 0x07, 0x76, 0x03]


def lee_registros(fn):
    fuera = []
    for ln in open(fn, encoding="utf-8"):
        if "=" in ln:
            fuera.append(int(ln.split("=")[1].strip(), 16))
    return fuera


def main(argv):
    if len(argv) < 3:
        print(__doc__)
        return 2
    with open(argv[0], "rb") as f:
        rom = f.read()
    carpeta = argv[2]
    mio = pantalla_de_titulo(rom).v

    volcados = sorted(fn for fn in os.listdir(carpeta)
                      if fn.startswith("vram-") and fn.endswith(".bin"))
    if not volcados:
        print("No hay volcados en %s. Antes hay que hacer `make vram`."
              % carpeta)
        return 2

    # Se elige el volcado que mas se parezca: los primeros salen antes de que
    # el cartucho acabe de montar la pantalla y son negros enteros.
    mejor, mejores = None, None
    for fn in volcados:
        with open(os.path.join(carpeta, fn), "rb") as f:
            real = f.read()
        d = [i for i in range(0x4000) if real[i] != mio[i]]
        print("  %-16s %5d bytes distintos" % (fn, len(d)))
        if mejores is None or len(d) < len(mejores):
            mejor, mejores = (fn, real), d

    fn, real = mejor
    print("\n  se coteja contra %s\n" % fn)

    reg = lee_registros(os.path.join(carpeta,
                                     fn.replace("vram-", "vdp-")
                                       .replace(".bin", ".txt")))
    for i, esperado in enumerate(REGISTROS):
        if reg[i] != esperado:
            print("  MAL: R%d es 0x%02X y el cartucho escribe 0x%02X"
                  % (i, reg[i], esperado))
            return 1
    print("  los siete primeros registros del VDP son los de 0x6284")

    sin_explicar = []
    for n, a, b in ZONAS:
        d = [i for i in range(a, b) if real[i] != mio[i]]
        raros = [i for i in d if i not in ANIMADAS]
        sin_explicar += raros
        print("  %-22s %4d de %5d distintos%s"
              % (n, len(d), b - a,
                 "" if not d else "  (%d animados, %d sin explicar)"
                 % (len(d) - len(raros), len(raros))))

    if sin_explicar:
        print("\n  BYTES SIN EXPLICAR:")
        for i in sin_explicar[:24]:
            print("    0x%04X  el VDP tiene %02X y nosotros %02X"
                  % (i, real[i], mio[i]))
        return 1

    animados = [i for i in range(0x4000) if real[i] != mio[i]]
    print("\n  OK: los %d bytes que discrepan son los animados, y ninguno mas"
          % len(animados))
    for i in animados:
        print("    0x%04X  %s" % (i, ANIMADAS[i]))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
