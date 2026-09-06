#!/usr/bin/env python3
"""Dibuja las pantallas del Game Master a partir de la ROM, no de capturas.

Monta la VRAM haciendo lo mismo que hace el cartucho -las cargas van copiadas
del listado, cada una con la direccion desde la que se hace- y luego pinta esos
16 KB como SCREEN 2.

La disposicion de la VRAM sale de los registros que el cartucho le da al VDP, y
es la de siempre en los Konami:

    0x0000-0x17FF  tabla de colores
    0x1800-0x1FFF  patrones de sprite
    0x2000-0x37FF  tabla de patrones
    0x3800-0x3AFF  tabla de nombres
    0x3B00-0x3B7F  atributos de sprite

Uso: graficos.py <rom> <org> <directorio de salida>
"""
import os
import struct
import sys
import zlib

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rle import descomprime, tres_tercios                       # noqa: E402

ORG = 0x4000

# La paleta del TMS9918, en RGB. La 0 es transparente y se ve como el borde.
PALETA = [
    (0, 0, 0), (0, 0, 0), (33, 200, 66), (94, 220, 120),
    (84, 85, 237), (125, 118, 252), (212, 82, 77), (66, 235, 245),
    (252, 85, 84), (255, 121, 120), (212, 193, 84), (230, 206, 128),
    (33, 176, 59), (201, 91, 186), (204, 204, 204), (255, 255, 255),
]


def png(w, h, px, fn):
    """Escribe un PNG en color verdadero sin depender de nada de fuera."""
    raw = b"".join(b"\x00" + bytes(v for x in range(w) for v in px[y][x])
                   for y in range(h))

    def chunk(t, d):
        return (struct.pack(">I", len(d)) + t + d
                + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF))

    with open(fn, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n"
                + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
                + chunk(b"IDAT", zlib.compress(raw))
                + chunk(b"IEND", b""))


class VRAM:
    """Los 16 KB, y lo que el cartucho va metiendo en ellos."""

    def __init__(self, rom):
        self.v = bytearray(0x4000)
        self.rom = rom

    def rellena(self, destino, valor, n):
        """FILVRM (0x0056)."""
        for i in range(n):
            self.v[destino + i] = valor

    def rellena3(self, destino, valor, n):
        """0x62BD: el mismo FILVRM tres veces, +0x800 cada vez.

        Es el hermano de 0x62E4 para rellenos, y se pasa por alto con
        facilidad: dejarlo fuera descuadraba 1384 bytes de la tabla de colores
        contra la VRAM del emulador.

        El que se hace desde 0x50C4 -0x0180, 0x158 bytes de 0xF0- es ademas el
        que da color a media fuente: el de la 'K' vive en 0x0258, dentro de ese
        tramo. Sin el, el "(c) KONAMI 1986" de la pantalla de titulo esta en la
        tabla de nombres y NO SE VE, porque le queda tinta negra sobre fondo
        negro. Fue asi como salio la primera vez, y mirar el PNG fue lo unico
        que lo delato.
        """
        for i in range(3):
            self.rellena(destino + 0x800 * i, valor, n)

    def copia3(self, origen, destino, n):
        """0x62CE: el mismo LDIRVM tres veces, +0x800 cada vez."""
        for i in range(3):
            self.copia(origen, destino + 0x800 * i, n)

    def copia(self, origen, destino, n):
        """LDIRVM (0x005C), y tambien el 0x7852 cuando va de corrido."""
        self.v[destino:destino + n] = self.rom[origen - ORG:origen - ORG + n]

    def suelta(self, trozos):
        for destino, datos in trozos:
            self.v[destino:destino + len(datos)] = datos

    def rectangulo(self, origen, destino, filas, columnas):
        """0x7852: filas x columnas saltando de 32 en 32 por la de nombres."""
        o = origen - ORG
        for f in range(filas):
            for c in range(columnas):
                self.v[destino + f * 32 + c] = self.rom[o]
                o += 1

    def rotulos(self, a):
        """0x6294: [direccion][caracteres]0xFE ... 0xFF."""
        d = self.rom
        while d[a - ORG] != 0xFF:
            destino = d[a - ORG] | (d[a - ORG + 1] << 8)
            a += 2
            while d[a - ORG] not in (0xFE, 0xFF):
                self.v[destino] = d[a - ORG]
                destino += 1
                a += 1
            if d[a - ORG] == 0xFE:
                a += 1


def pinta_screen2(v, con_sprites=True):
    """Los 16 KB de VRAM, en una rejilla de 256x192 pixeles."""
    px = [[(0, 0, 0)] * 256 for _ in range(192)]
    for fila in range(24):
        tercio = fila // 8
        for col in range(32):
            car = v[0x3800 + fila * 32 + col]
            base = 0x2000 + tercio * 0x800 + car * 8
            cbase = 0x0000 + tercio * 0x800 + car * 8
            for y in range(8):
                linea, color = v[base + y], v[cbase + y]
                tinta, fondo = PALETA[color >> 4], PALETA[color & 15]
                for x in range(8):
                    px[fila * 8 + y][col * 8 + x] = \
                        tinta if linea & (0x80 >> x) else fondo
    if con_sprites:
        pinta_sprites(v, px)
    return px


def pinta_sprites(v, px):
    """Los 32 sprites de 16x16 de la tabla de atributos, de atras adelante.

    El VDP los pinta por prioridad -el 0 el primero-, asi que para que quede
    igual hay que recorrerlos AL REVES y dejar que el de menor numero tape.
    """
    entradas = []
    for i in range(32):
        a = 0x3B00 + i * 4
        y = v[a]
        if y == 0xD0:                      # el 0xD0 corta la lista
            break
        entradas.append((v[a], v[a + 1], v[a + 2], v[a + 3]))
    for y, x, patron, color in reversed(entradas):
        c = PALETA[color & 15]
        if (color & 15) == 0:
            continue
        if color & 0x80:                   # el bit EC corre el sprite 32 a la izda
            x -= 32
        y = (y + 1) & 0xFF
        base = 0x1800 + (patron & 0xFC) * 8
        for cuarto in range(4):            # 16x16 son cuatro bloques de 8x8
            dx, dy = (cuarto // 2) * 8, (cuarto % 2) * 8
            for f in range(8):
                linea = v[base + cuarto * 8 + f]
                for b in range(8):
                    if not linea & (0x80 >> b):
                        continue
                    py, pxx = y + dy + f, x + dx + b
                    if 0 <= py < 192 and 0 <= pxx < 256:
                        px[py][pxx] = c


def fondo_de_trabajo(rom, v=None):
    """0x5033: la fuente y sus colores, que es el fondo de TODOS los menus.

    Es lo que llaman 0x4F83 -antes de montar el titulo- y 0x5014, que es por
    donde se entra al MODIFY MODE y al SELF MODE. Y ahi esta la diferencia que
    importa: **los menus NO se pintan encima de la pantalla de titulo**. El
    cartucho vuelve a montar este fondo, que solo trae la fuente, y encima pone
    los rotulos.

    Dibujar un menu sobre el titulo deja restos que se ven a simple vista: en
    el MODIFY MODE salian manchas sobre la "RANKING MODE" y el "START GAME" en
    blanco en vez de en verde, porque la tabla de COLOR seguia siendo la del
    pollo y la pizarra.
    """
    if v is None:
        v = VRAM(rom)
        v.rellena(0x0000, 0x00, 0x4000)                  # 0x4F4F, borra la VRAM
    v.rellena(0x3800, 0x00, 0x0300)                      # 0x62AB
    v.v[0x3B00] = 0xD0                                   # 0x62B5, corta sprites
    v.suelta(tres_tercios(rom, 0x5218, 0x0000)[0])       # 0x50C7
    #     0x5063
    v.rellena3(0x2400, 0x3F, 0x20)                       # 0x506B
    v.rellena3(0x2420, 0xFC, 0x20)                       # 0x5076
    v.suelta(tres_tercios(rom, 0x509A, 0x0400)[0])       # 0x507F
    v.copia3(0x50AB, 0x2440, 0x08)                       # 0x508B
    v.rellena3(0x0440, 0xF0, 0x08)                       # 0x5096
    #     0x50B3
    v.suelta(tres_tercios(rom, 0x50D0, 0x2180)[0])       # 0x50B9
    v.rellena3(0x0180, 0xF0, 0x158)                      # 0x50C4
    return v


def pantalla_de_titulo(rom):
    """Lo mismo que hacen 0x77D6 y 0x7805, en el mismo orden.

    Cada linea lleva la direccion desde la que el cartucho hace esa carga, para
    poder cotejarla contra el listado.
    """
    v = VRAM(rom)
    # --- 0x4F43, que es donde se entra cuando no hay juego al lado
    v.rellena(0x0000, 0x00, 0x4000)                      # 0x4F4F, borra la VRAM
    v.rellena(0x3800, 0x00, 0x0300)                      # 0x62AB desde 0x4F60
    v.v[0x3B00] = 0xD0                                   # 0x62B5, corta los sprites
    v.suelta(descomprime(rom, 0x536F)[0])                # 0x530D desde 0x4F63
    # LA APARICION. Lo que se acaba de cargar no sale de golpe: sus patrones
    # estan puestos, pero su tabla de colores esta a cero -negro sobre negro,
    # invisible- y 0x533B la va pintando de 0xF0 poco a poco, 21 bytes de ocho
    # en ocho por pasada, llevando la cuenta en 0xDA01 (que 0x530D deja a
    # cero). 0x4F73 la llama en bucle hasta que acaba o se pulsa una tecla.
    #
    # 21 bytes x 8 lineas x 6 pasadas = 1008, o sea 0x0880..0x0C6F clavado.
    # Aqui se pone el estado FINAL de un golpe.
    #
    # EL SITIO IMPORTA: esto pasa ANTES de montar el titulo, no despues. Puesto
    # al final se comia el 0xFC que 0x780D deja en 0x0980 y los colores que
    # 0x77E4 suelta en 0x0C00: 448 bytes de diferencia contra el emulador.
    v.rellena(0x0880, 0xF0, 0x03F0)                      # 0x5358, estado final
    # --- 0x62AB otra vez y 0x5033 desde 0x4F83: la fuente y sus colores
    fondo_de_trabajo(rom, v)
    # --- 0x77D6
    v.rellena(0x0300, 0xF0, 0x01D8)                      # 0x77DE, FILVRM
    v.suelta(tres_tercios(rom, 0x7B90, 0x2300)[0])       # 0x77E4
    v.suelta(tres_tercios(rom, 0x7CCF, 0x2508)[0])       # 0x77ED
    v.suelta(tres_tercios(rom, 0x799F, 0x0508)[0])       # 0x77F6
    v.suelta(descomprime(rom, 0x7B43, 0x1800)[0])        # 0x77FF, una sola vez
    # 0x7805
    v.rellena(0x0980, 0xFC, 0x0180)                      # 0x780D, FILVRM
    v.rectangulo(0x7920, 0x3865, 3, 22)                  # 0x7810
    v.rectangulo(0x7962, 0x389A, 3, 2)                   # 0x781C
    v.rotulos(0x7968)                                    # 0x7828
    v.suelta(descomprime(rom, 0x7868)[0])                # 0x782E
    v.rectangulo(0x7894, 0x39A6, 3, 20)                  # 0x7834
    v.suelta(descomprime(rom, 0x78D0)[0])                # 0x7840
    v.copia(0x7977, 0x3B00, 0x18)                        # 0x7849, LDIRVM
    return v


def rejilla(v):
    """0x503C: las bandas decorativas de arriba y de abajo.

    Leida instruccion a instruccion, porque a ojo se lee mal: el bucle de
    0x5052 escribe A DOS VECES y avanza, con B=0x10, o sea 32 bytes -una fila
    entera de la tabla de nombres- por vuelta; y como A empieza en 1 y da la
    vuelta con `and 0x0F`, la fila sale 1,1,2,2,...,15,15,0,0. El `dec c` de
    0x505F la repite CUATRO veces, y 0x503C hace todo eso dos veces: una desde
    0x3800 -las filas 0 a 3- y otra desde 0x3A80 -las filas 20 a 23-.

    La primera version de esto pintaba 16 filas de cuatro columnas y dejaba la
    pantalla del MODIFY con el rotulo del titulo asomando por arriba.
    """
    for base in (0x3800, 0x3A80):
        for f in range(4):
            a = 1
            for i in range(0x10):
                v.v[base + f * 32 + i * 2] = a
                v.v[base + f * 32 + i * 2 + 1] = a
                a = (a + 1) & 0x0F


def con_menu(rom, rotulos, borra_desde=0x3A00, cuanto=0x100, marco=False):
    """Un menu sobre el fondo de trabajo, como lo monta el cartucho.

    El guion es siempre el mismo: el fondo de 0x5033, las bandas de colores de
    0x503C si las lleva, el borrado del trozo que va a ocupar -0x644F borra
    0x100 bytes desde 0x3A00 y 0x4C1F borra 0x200 desde 0x3880- y encima los
    rotulos.
    """
    v = fondo_de_trabajo(rom)
    if marco:
        rejilla(v)
    v.rellena(borra_desde, 0x00, cuanto)
    v.rotulos(rotulos)
    return v


# Las pantallas que se dibujan. Los rangos de borrado salen de la rutina que
# pinta cada una, y el marco de si llama o no a 0x503C.
#
# LOS DOS TIPOS DE MENU, y la diferencia no es de estilo. Los que solo borran
# 0x100 bytes desde 0x3A00 -las ocho filas de abajo- **se abren encima de lo que
# hubiera en pantalla**: 0x4275 llama antes a `salva_la_pantalla`, que se lleva
# la VRAM del juego a la RAM para poder devolverla. O sea que en la maquina real
# la mitad de arriba es EL JUEGO CORRIENDO, no un fondo del cartucho. Aqui salen
# sobre negro porque no hay juego que poner, y eso hay que decirlo en el pie.
#
# Los otros borran 0x200 desde 0x3880 y pintan las bandas de 0x503C: esos si
# montan pantalla propia.
PANTALLAS = [
    ("menu-principal", 0x4525, 0x3A00, 0x100, False,
     "0x44F0: seis lineas, ENCIMA DEL JUEGO"),
    ("menu-guardar", 0x459E, 0x3A00, 0x100, False,
     "0x4586: que dato se guarda, encima del juego"),
    ("menu-cargar", 0x45E2, 0x3A00, 0x100, False,
     "0x4592: lo mismo al cargar, sin SCREEN DATA"),
    ("menu-ranking", 0x46D4, 0x3A00, 0x100, False,
     "0x46CB: las cuatro del modo ranking"),
    ("menu-impresora", 0x731F, 0x3A00, 0x100, False,
     "0x7319: elegir impresora"),
    ("menu-modify", 0x4B42, 0x3880, 0x200, True,
     "0x48EC: el MODIFY MODE, donde estan los trucos"),
    ("menu-self", 0x489A, 0x3880, 0x200, True,
     "0x471E: el SELF MODE"),
    ("menu-modo-ranking", 0x4A3E, 0x3880, 0x200, True,
     "0x4A11: cargar, borrar o ver el ranking"),
    ("menu-cargar-pantalla", 0x477C, 0x3880, 0x200, True,
     "0x4765: de donde se carga la pantalla"),
    ("menu-modo-pantalla", 0x4850, 0x3880, 0x200, True,
     "0x4823: que hacer con la pantalla cargada"),
]


def rotulos_del_arranque(rom):
    """Los tres rotulos de 0x4FA9, uno al lado de otro y con su sitio.

    No son texto: son doce casillas cada uno, 3 filas de 4, que 0x4F8E pinta en
    la VRAM 0x39AB -fila 13, columna 11-. Para saber que dicen no vale leerlos,
    hay que DIBUJARLOS, que es lo que se hace aqui: se monta la pantalla de
    titulo entera y se pinta cada uno en su sitio, uno por imagen.
    """
    fuera = []
    for i, a in enumerate((0x4FA9, 0x4FB5, 0x4FC1)):
        v = pantalla_de_titulo(rom)
        v.rectangulo(a, 0x39AB, 3, 4)                    # 0x52B9 con bc=0x0304
        fuera.append((i, v))
    return fuera


def main(argv):
    if len(argv) < 3:
        print(__doc__)
        return 2
    with open(argv[0], "rb") as f:
        rom = f.read()
    salida = argv[2]
    os.makedirs(salida, exist_ok=True)

    v = pantalla_de_titulo(rom)
    fn = os.path.join(salida, "titulo.png")
    png(256, 192, pinta_screen2(v.v), fn)
    print("  %s" % fn)

    # EL ROTULO, para la cabecera de la web. No es un montaje ni una captura:
    # es el trozo de la pantalla de titulo donde el cartucho pinta su nombre,
    # recortado de lo que ya esta cotejado contra la VRAM del emulador. Las
    # filas 1 a 6 y las columnas 2 a 30, que es lo que ocupan el "GAME MASTER"
    # y el "(C) KONAMI 1986" de debajo.
    full = pinta_screen2(v.v, con_sprites=False)
    f0, f1, c0, c1 = 1, 7, 2, 30
    recorte = [[full[f0 * 8 + y][c0 * 8 + x] for x in range((c1 - c0) * 8)]
               for y in range((f1 - f0) * 8)]
    fn = os.path.join(salida, "rotulo.png")
    png((c1 - c0) * 8, (f1 - f0) * 8, recorte, fn)
    print("  %-26s el rotulo, recortado de la pantalla de titulo"
          % os.path.basename(fn))

    for nombre, rot, desde, cuanto, marco, que in PANTALLAS:
        w = con_menu(rom, rot, desde, cuanto, marco)
        fn = os.path.join(salida, nombre + ".png")
        png(256, 192, pinta_screen2(w.v), fn)
        print("  %-26s %s" % (os.path.basename(fn), que))

    for i, w in rotulos_del_arranque(rom):
        fn = os.path.join(salida, "arranque-%d.png" % i)
        png(256, 192, pinta_screen2(w.v), fn)
        print("  %-26s el rotulo %d de 0x4FA9, en la VRAM 0x39AB"
              % (os.path.basename(fn), i))

    # La misma pantalla sin sprites, para ver que pone cada capa.
    fn = os.path.join(salida, "titulo-sin-sprites.png")
    png(256, 192, pinta_screen2(v.v, con_sprites=False), fn)
    print("  %s" % fn)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
