#!/usr/bin/env python3
"""El descompresor del Game Master, el de 0x62F7, rehecho en Python.

EL FORMATO, leido de la rutina instruccion a instruccion:

    [direccion de VRAM, 2 bytes]        <- se le pasa a SETWRT
    [cuenta]  [byte(s)]                 <- una tirada
    [cuenta]  [byte(s)]
    ...

De cada byte de cuenta se toman los siete bits bajos (`and 0x7F` en 0x6305), y
el bit 7 dice de que tirada se trata. La rutina lo distingue comparando el byte
entero con la cuenta (`cp b` en 0x6310): si son iguales el bit 7 estaba a cero.

    bit 7 puesto -> los `cuenta` bytes de detras van tal cual
    bit 7 a cero -> el byte de detras se repite `cuenta` veces

Y la cuenta cero es la que manda (0x630A-0x630F):

    0x00 -> se acabo el bloque
    otro -> se acabo ESTE destino, y detras viene OTRA direccion de VRAM y mas
            tiradas. Asi un solo bloque llena varios sitios de la VRAM.

Ese ultimo caso es facil de pasar por alto y deja la descompresion cortada a la
primera: sin el, el bloque de la pantalla de titulo solo suelta su primer
pedazo.

Uso: rle.py <rom> <direccion> [<direccion> ...]
"""
import sys

ORG = 0x4000


def descomprime(d, a, destino=None):
    """Devuelve [(direccion de VRAM, bytes)] y la direccion de despues.

    `d` es la ROM entera y `a`, una direccion del cartucho.

    LA RUTINA TIENE DOS ENTRADAS, y confundirlas descoloca el bloque entero:

      0x62F7 - la direccion de VRAM va DENTRO del bloque, en sus dos primeros
               bytes. La usan 0x5316, 0x7831 y 0x7843. Aqui: destino=None.
      0x62FB - cuatro bytes mas adelante, saltandose esa lectura: la direccion
               llega en DE de quien llama. La usan 0x62E9 (o sea 0x62E4),
               0x63C0, 0x67BC, 0x71CA y 0x7802. Aqui: destino=la que sea.

    Con destino=None sobre un bloque de los de la segunda clase, sus dos
    primeros bytes -que son datos- se leen como direccion y todo lo demas sale
    corrido.
    """
    salida = []
    primera = True
    while True:
        if a - ORG + 1 >= len(d):
            return salida, a
        if primera and destino is not None:
            primera = False
        else:
            destino = d[a - ORG] | (d[a - ORG + 1] << 8)
            a += 2
            primera = False
        trozo = bytearray()
        while True:
            if a - ORG >= len(d):
                salida.append((destino, bytes(trozo)))
                return salida, a
            b = d[a - ORG]
            cuenta = b & 0x7F
            a += 1
            if cuenta == 0:
                salida.append((destino, bytes(trozo)))
                if b == 0:
                    return salida, a          # fin del bloque
                break                         # otro destino detras
            if b == cuenta:                   # bit 7 a cero: repeticion
                trozo += bytes([d[a - ORG]] * cuenta)
                a += 1
            else:                             # bit 7 puesto: literales
                trozo += d[a - ORG:a - ORG + cuenta]
                a += cuenta


def tres_tercios(d, a, destino):
    """Lo que hace 0x62E4: el mismo bloque tres veces, +0x800 cada vez.

    No descomprime tres bloques distintos, sino EL MISMO otra vez sumandole
    0x800 al destino. Los tres tercios de SCREEN 2 quedan iguales, que es como
    Konami monta casi todas sus pantallas.
    """
    salida = []
    for i in range(3):
        trozos, fin = descomprime(d, a, destino + 0x800 * i)
        salida += trozos
    return salida, fin


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    with open(argv[0], "rb") as f:
        d = f.read()
    for x in argv[1:]:
        a = int(x, 0)
        trozos, fin = descomprime(d, a)
        total = sum(len(t) for _, t in trozos)
        print("0x%04X..0x%04X  %d bytes comprimidos -> %d descomprimidos "
              "en %d destino(s)" % (a, fin - 1, fin - a, total, len(trozos)))
        for destino, datos in trozos:
            print("      VRAM 0x%04X  %5d bytes   %s..."
                  % (destino, len(datos),
                     " ".join("%02X" % b for b in datos[:12])))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
