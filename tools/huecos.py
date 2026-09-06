#!/usr/bin/env python3
"""Lista los huecos de datos del trazado, del mas grande al mas pequeno.

Sirve para saber por donde seguir: un hueco grande es, o un bloque de datos por
etiquetar, o codigo al que todavia no llega el trazado. Para distinguirlos, de
cada hueco se dice cuanto se parece a codigo Z80 (la proporcion de opcodes
frecuentes) y se ensenan sus primeros bytes.

Uso: huecos.py <rom> <org> <trace.json> [minimo]
"""
import json
import sys

# Los opcodes que salen a espuertas en el codigo de un juego y casi nunca en un
# bloque de graficos: saltos, llamadas, carga de registros y retornos.
TIPICOS = set([0xCD, 0xC3, 0xC9, 0x18, 0x20, 0x28, 0x30, 0x38, 0x21, 0x11,
               0x01, 0x3E, 0x06, 0x0E, 0x3A, 0x32, 0x7E, 0x77, 0x23, 0xEB,
               0xE5, 0xD5, 0xC5, 0xE1, 0xD1, 0xC1, 0xF5, 0xF1, 0xAF, 0xB7])


def parece_codigo(b):
    return sum(1 for x in b if x in TIPICOS) / len(b) if b else 0.0


def main(argv):
    if len(argv) < 3:
        print(__doc__)
        return 2
    rom, org, tr = argv[0], int(argv[1], 0), json.load(open(argv[2]))
    minimo = int(argv[3], 0) if len(argv) > 3 else 24
    d = open(rom, "rb").read()

    cubierto = bytearray(len(d))
    # Los bloques vienen como ['c'|'d', inicio, fin], con las direcciones ya
    # absolutas y el fin exclusivo.
    for tipo, ini, fin in tr["blocks"]:
        if tipo != "c":
            continue
        for i in range(ini - org, fin - org):
            if 0 <= i < len(d):
                cubierto[i] = 1

    huecos, i = [], 0
    while i < len(d):
        if not cubierto[i]:
            j = i
            while j < len(d) and not cubierto[j]:
                j += 1
            huecos.append((i, j))
            i = j
        else:
            i += 1

    huecos = [h for h in huecos if h[1] - h[0] >= minimo]
    print("%d huecos de %d bytes o mas, %d bytes en total"
          % (len(huecos), minimo, sum(f - i for i, f in huecos)))
    for i, f in sorted(huecos, key=lambda h: h[0] - h[1]):
        b = d[i:f]
        tr_ = "".join(chr(x) if 32 <= x < 127 else "." for x in b[:24])
        print("  0x%04X..0x%04X  %5d bytes  codigo?%3d%%  %s |%s|"
              % (org + i, org + f - 1, f - i, round(100 * parece_codigo(b)),
                 " ".join("%02X" % x for x in b[:12]), tr_))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
