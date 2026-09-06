#!/usr/bin/env python3
"""Mira un trozo de la ROM: desensamblado (-d) o volcado hexadecimal (-x).

Un ayudante para el trabajo a mano, no parte de la cadena de montaje. El
fichero temporal va al directorio work/ del propio proyecto y NO a /tmp, que en
Windows no existe.

Uso: ver.py [-d|-x] <dir> <n> [<rom>]
"""
import os
import subprocess
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TMP = os.path.join(RAIZ, "work", "ver.bin")


def volcado(d, a, n):
    for r in range(0, n, 16):
        o = a - 0x4000 + r
        tr = "".join(chr(b) if 32 <= b < 127 else "." for b in d[o:o + 16])
        print("  %04X  %-47s  |%s|" % (a + r, " ".join("%02X" % b for b in d[o:o + 16]), tr))


def desensamblado(d, a, n):
    os.makedirs(os.path.dirname(TMP), exist_ok=True)
    with open(TMP, "wb") as f:
        f.write(d[a - 0x4000:a - 0x4000 + n])
    r = subprocess.run(["z80dasm", "-a", "-t", "-g", hex(a), TMP],
                       capture_output=True, text=True)
    print(r.stdout)
    if r.returncode:
        print(r.stderr, file=sys.stderr)


def main(argv):
    modo = "-d"
    if argv and argv[0] in ("-d", "-x"):
        modo, argv = argv[0], argv[1:]
    if len(argv) < 2:
        print(__doc__)
        return 2
    a = int(argv[0], 0)
    n = int(argv[1], 0)
    rom = argv[2] if len(argv) > 2 else os.path.join(RAIZ, "gamemaster.rom")
    with open(rom, "rb") as f:
        d = f.read()
    (volcado if modo == "-x" else desensamblado)(d, a, n)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
