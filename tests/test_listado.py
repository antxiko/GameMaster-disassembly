#!/usr/bin/env python3
"""Comprobaciones sobre Konami's Game Master (RC-735).

No comprueban que el listado reensamble -de eso se encarga `make verify`, que
compara el binario byte a byte-, sino las AFIRMACIONES que hace el .notes y que
un reensamblado no puede cazar: que la tabla de firmas es la que decimos, que
las cabeceras postizas llevan el numero de catalogo que decimos, y que el
parche del gancho de interrupcion encaja de verdad en las ROM de los juegos.

Las ROM de los juegos no estan en el repositorio. Las pruebas que las necesitan
se saltan solas si no aparecen.
"""
import os
import glob
import re
import sys
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM = os.path.join(RAIZ, "gamemaster.rom")
ORG = 0x4000

# Donde estan las ROM de los juegos en esta maquina. Ninguna se distribuye.
COLECCIONES = [
    os.path.join(RAIZ, "..", "ROMS"),
    os.path.join(RAIZ, "roms"),
]


def rom():
    with open(ROM, "rb") as f:
        return f.read()


def roms_de_juegos():
    out = []
    for d in COLECCIONES:
        if os.path.isdir(d):
            out += sorted(glob.glob(os.path.join(d, "*.rom")))
    return out


class TestCartucho(unittest.TestCase):
    def setUp(self):
        self.d = rom()

    def test_tamano_y_cabecera(self):
        self.assertEqual(len(self.d), 16384)
        self.assertEqual(self.d[0:2], b"AB")
        # Solo declara INIT; STATEMENT, DEVICE y TEXT van a cero.
        self.assertEqual(self.d[2] | (self.d[3] << 8), 0x4010)
        self.assertEqual(self.d[4:16], b"\x00" * 12)

    def test_marca_oculta_de_konami(self):
        """Los ultimos 22 bytes: RC-735 y el titulo en katakana, del reves.

        El formato lo destapo Manuel Pazos en 2021: [titulo invertido][N][RC en
        BCD][0xAA]. Aqui N son 19 bytes y el RC, 0x35 -las dos cifras de
        RC-7_35.
        """
        self.assertEqual(self.d[-1], 0xAA)
        self.assertEqual(self.d[-2], 0x35)
        n = self.d[-3]
        self.assertEqual(n, 19)
        titulo = self.d[-3 - n:-3][::-1]
        # Cada byte es un espacio (0x00), un kana (>= 0x80) o un digito ASCII.
        for b in titulo:
            self.assertTrue(b == 0 or b >= 0x80 or 0x30 <= b <= 0x39,
                            "byte %02X fuera del alfabeto de la marca" % b)
        # Empieza por "10", que es el 10 de "10 veces mas divertido".
        self.assertEqual(titulo[0:2], b"10")


class TestTablaDeFirmas(unittest.TestCase):
    """La tabla de 0x5F3A: (suma de 16 bits, puntero a cabecera), fin en 0000."""

    def setUp(self):
        self.d = rom()
        self.tabla = []
        a = 0x5F3A
        while True:
            s = self.w(a)
            if s == 0:
                break
            self.tabla.append((s, self.w(a + 2)))
            a += 4
        self.fin = a

    def w(self, a):
        return self.d[a - ORG] | (self.d[a - ORG + 1] << 8)

    def test_tiene_62_entradas_y_acaba_donde_decimos(self):
        self.assertEqual(len(self.tabla), 62)
        self.assertEqual(self.fin, 0x6032)

    def test_las_cabeceras_van_seguidas_de_19_en_19(self):
        """29 cabeceras de 0x13 bytes, pegadas, de 0x6047 a 0x626D.

        29 cabeceras y no 28: son 28 juegos, pero Antarctic Adventure lleva
        dos, una por cada pareja de compilaciones suyas.
        """
        punteros = sorted(set(p for _, p in self.tabla))
        self.assertEqual(len(punteros), 29)
        self.assertEqual(punteros[0], 0x6047)
        for a, b in zip(punteros, punteros[1:]):
            self.assertEqual(b - a, 0x13, "hueco entre 0x%04X y 0x%04X" % (a, b))
        self.assertEqual(punteros[-1] + 0x13, 0x626E)

    def test_los_numeros_de_catalogo_son_bcd_y_van_en_orden(self):
        """Cada cabecera empieza por 07 xx, y las 28 estan ordenadas."""
        punteros = sorted(set(p for _, p in self.tabla))
        rcs = []
        for p in punteros:
            alto, bajo = self.d[p - ORG], self.d[p - ORG + 1]
            self.assertEqual(alto, 0x07, "0x%04X no empieza por 07" % p)
            for nib in (bajo >> 4, bajo & 0x0F):
                self.assertLessEqual(nib, 9, "0x%02X no es BCD" % bajo)
            rcs.append(700 + (bajo >> 4) * 10 + (bajo & 0x0F))
        self.assertEqual(rcs, sorted(rcs))
        # Antarctic Adventure (RC-701) aparece dos veces, con dos compilaciones
        # que se diferencian en un solo byte de la cabecera.
        self.assertEqual(rcs.count(701), 2)
        a, b = [p for p in punteros
                if self.d[p - ORG + 1] == 0x01]
        difs = [i for i in range(0x13)
                if self.d[a - ORG + i] != self.d[b - ORG + i]]
        self.assertEqual(difs, [3])

    def test_las_sumas_cuadran_con_las_ROM_de_la_coleccion(self):
        """La firma es la suma de 0x5000..0x50FF de la ROM del juego.

        Se comprueba al reves: de cada ROM de la coleccion se calcula la suma y
        se mira si esta en la tabla. Toda ROM de Konami de 16 o 32 KB que este
        en el catalogo RC-700..RC-733 tiene que aparecer.
        """
        ficheros = roms_de_juegos()
        if not ficheros:
            self.skipTest("no hay ROM de juegos en esta maquina")
        firmas = set(s for s, _ in self.tabla)
        aciertos = 0
        for f in ficheros:
            with open(f, "rb") as fh:
                g = fh.read()
            if len(g) < 0x1100:
                continue
            if sum(g[0x1000:0x1100]) & 0xFFFF in firmas:
                aciertos += 1
        # Medido: 30 de las ROM de la coleccion caen en la tabla.
        self.assertGreaterEqual(aciertos, 30)


class TestElParcheDelGancho(unittest.TestCase):
    """El corazon del cartucho: como se cuela en la interrupcion del juego."""

    def setUp(self):
        self.d = rom()

    def test_los_cinco_bytes_del_parche(self):
        """0x4CB9 convierte `ld (0xFD9B),hl` en `ld (0xD130),hl` + `call 0xD814`."""
        p = self.d[0x4CB9 - ORG:0x4CBE - ORG]
        self.assertEqual(p, bytes([0x30, 0xD1, 0xCD, 0x14, 0xD8]))
        # Con el opcode 22 que el juego ya tiene delante:
        self.assertEqual(p[0] | (p[1] << 8), 0xD130)   # donde guarda el gancho
        self.assertEqual(p[2], 0xCD)                   # call
        self.assertEqual(p[3] | (p[4] << 8), 0xD814)   # a su propia rutina

    def test_busca_9B_FD_y_copia_5_bytes(self):
        """0x4C8F..0x4CA3: cpir del 0x9B, cp 0xFD, y el ldir de cinco bytes."""
        c = self.d[0x4C8F - ORG:0x4CA4 - ORG]
        self.assertEqual(c[0:2], bytes([0x3E, 0x9B]))          # ld a,0x9B
        self.assertEqual(c[2:4], bytes([0xED, 0xB1]))          # cpir
        self.assertIn(bytes([0x3E, 0xFD, 0xBE]), c)            # ld a,0xFD / cp (hl)
        self.assertEqual(c[-2:], bytes([0xED, 0xB0]))          # ldir
        # ld bc,0x0005 justo antes del ldir
        self.assertEqual(c[-5:-2], bytes([0x01, 0x05, 0x00]))

    def test_las_ROM_de_konami_llevan_esa_instruccion(self):
        """Sin `ld (0xFD9B),hl` en los 256 bytes del INIT, el truco no entra.

        Es la razon por la que el Game Master funciona con todo el catalogo:
        los cartuchos de Konami arrancan todos igual.
        """
        ficheros = roms_de_juegos()
        if not ficheros:
            self.skipTest("no hay ROM de juegos en esta maquina")
        con = sin = 0
        for f in ficheros:
            with open(f, "rb") as fh:
                g = fh.read()
            # OJO: el corte no puede ser len(g) < 0x4020. Casi todos estos
            # cartuchos miden 0x4000 bytes justos, asi que ese filtro los
            # tiraba todos menos los de 32 KB y dejaba la prueba en ocho ROM.
            if len(g) < 0x20 or g[0:2] != b"AB":
                continue
            init = g[2] | (g[3] << 8)
            o = init - ORG
            if not (0 <= o < len(g) - 256):
                continue
            if g[o:o + 256].find(b"\x9b\xfd") >= 0:
                con += 1
            else:
                sin += 1
        # Medido sobre esta coleccion: 40 la llevan y 2 no -Casio World Open,
        # que no es de Konami, y el propio Game Master.
        self.assertGreaterEqual(con, 40)
        self.assertLessEqual(sin, 2)

    def test_el_game_master_no_se_parchea_a_si_mismo(self):
        init = self.d[2] | (self.d[3] << 8)
        o = init - ORG
        self.assertEqual(self.d[o:o + 256].find(b"\x9b\xfd"), -1)


class TestLaSegundaCabecera(unittest.TestCase):
    """0x5E64: busca "AB" o "CD" en 0x4010 del cartucho de al lado."""

    def setUp(self):
        self.d = rom()

    def test_compara_contra_AB_y_CD(self):
        # ld hl,0x4241 / rst 20h  -> los bytes 41 42, o sea "AB"
        self.assertEqual(self.d[0x5E7A - ORG:0x5E7E - ORG],
                         bytes([0x21, 0x41, 0x42, 0xE7]))
        # ld hl,0x4443 / rst 20h  -> los bytes 43 44, o sea "CD"
        self.assertEqual(self.d[0x5E8C - ORG:0x5E90 - ORG],
                         bytes([0x21, 0x43, 0x44, 0xE7]))

    def test_AB_trae_19_bytes_y_CD_trae_21(self):
        # ld hl,0x4012 / ld de,0xD300 / ld bc,0x0013
        self.assertEqual(self.d[0x5E80 - ORG:0x5E89 - ORG],
                         bytes([0x21, 0x12, 0x40, 0x11, 0x00, 0xD3,
                                0x01, 0x13, 0x00]))
        # ld hl,0x4012 / ld de,0xD351 / ld bc,0x0015
        self.assertEqual(self.d[0x5E92 - ORG:0x5E9B - ORG],
                         bytes([0x21, 0x12, 0x40, 0x11, 0x51, 0xD3,
                                0x01, 0x15, 0x00]))

    def test_la_cabecera_postiza_mide_lo_mismo_que_la_de_verdad(self):
        """Los 19 bytes de la tabla y los 19 que se leen de "AB" son lo mismo.

        Es lo que permite que el resto del cartucho no tenga que saber por cual
        de los dos caminos se identifico el juego.
        """
        self.assertEqual(0x605A - 0x6047, 0x13)

    def test_cotejo_con_los_juegos_que_si_la_llevan(self):
        """De la coleccion, solo cinco ROM traen segunda cabecera."""
        ficheros = roms_de_juegos()
        if not ficheros:
            self.skipTest("no hay ROM de juegos en esta maquina")
        vistas = {}
        for f in ficheros:
            with open(f, "rb") as fh:
                g = fh.read()
            if len(g) < 0x4020:
                continue
            if g[0x10:0x12] in (b"AB", b"CD"):
                vistas[os.path.basename(f)] = (g[0x10:0x12],
                                               g[0x12] * 100 + (g[0x13] >> 4) * 10
                                               + (g[0x13] & 15))
        rcs = sorted(set(v[1] for v in vistas.values()))
        self.assertEqual(rcs, [732, 734, 742, 752])
        # Soccer y Football usan el formato viejo; los tres de 1986-87, el nuevo.
        for nombre, (marca, rc) in vistas.items():
            self.assertEqual(marca, b"AB" if rc == 732 else b"CD", nombre)


class TestTablaDeApanos(unittest.TestCase):
    """La tabla de 0x5AD1: (numero de catalogo, rutina), terminada en 0xFF."""

    def setUp(self):
        self.d = rom()
        self.filas = []
        a = 0x5AD1
        while self.d[a - ORG] != 0xFF:
            self.filas.append((self.d[a - ORG],
                               self.d[a - ORG + 1] | (self.d[a - ORG + 2] << 8)))
            a += 3
        self.fin = a

    def test_son_dieciseis_y_acaban_en_FF(self):
        self.assertEqual(len(self.filas), 16)
        self.assertEqual(self.d[self.fin - ORG], 0xFF)

    def test_los_indices_son_BCD(self):
        for rc, _ in self.filas:
            self.assertLessEqual(rc >> 4, 9)
            self.assertLessEqual(rc & 15, 9)

    def test_solo_hay_cuatro_rutinas_para_dieciseis_juegos(self):
        rutinas = sorted(set(r for _, r in self.filas))
        self.assertEqual(rutinas, [0x5B42, 0x5B52, 0x5B5A, 0x5B5F])
        # Doce de los dieciseis comparten la misma.
        self.assertEqual(sum(1 for _, r in self.filas if r == 0x5B52), 12)

    def test_el_recorrido_compara_contra_D301(self):
        """0x5582: ld a,(hl) / inc a / jr z / ld a,(0xD301) / cp (hl)."""
        c = self.d[0x5582 - ORG:0x5590 - ORG]
        self.assertEqual(c[0:2], bytes([0x7E, 0x3C]))            # ld a,(hl) / inc a
        self.assertEqual(c[2], 0x28)                             # jr z -> fin
        self.assertEqual(c[4:7], bytes([0x3A, 0x01, 0xD3]))      # ld a,(0xD301)
        self.assertEqual(c[7], 0xBE)                             # cp (hl)
        self.assertEqual(c[9:12], bytes([0x23, 0x23, 0x23]))     # inc hl x3


class TestCodigoEnRAM(unittest.TestCase):
    """Los siete bloques que no se ejecutan donde estan.

    Cada uno se comprueba contra el LDIR que lo copia: origen, destino y
    longitud tienen que ser los que dice el .entries. La direccion NO se cuenta
    a mano, se lee de los bytes de la instruccion.
    """

    # (direccion del ld hl, origen, destino, longitud)
    COPIAS = [
        (0x40D0, 0x40DE, 0xDA00, 0x00BC),
        (0x419A, 0x41A8, 0xC000, 0x0087),
        (0x4248, 0x4264, 0xC800, 0x000B),
        (0x4253, 0x426F, 0xFEDA, 0x0003),
        (0x4C76, 0x4CCA, 0xD814, 0x004D),
        (0x4CBE, 0x4D17, 0xD170, 0x014A),
    ]

    def setUp(self):
        self.d = rom()

    def w(self, a):
        return self.d[a - ORG] | (self.d[a - ORG + 1] << 8)

    def test_cada_bloque_contra_su_ldir(self):
        for dir_ld, origen, destino, n in self.COPIAS:
            with self.subTest(hex(dir_ld)):
                self.assertEqual(self.d[dir_ld - ORG], 0x21)          # ld hl,nn
                self.assertEqual(self.w(dir_ld + 1), origen)
                self.assertEqual(self.d[dir_ld + 3 - ORG], 0x11)      # ld de,nn
                self.assertEqual(self.w(dir_ld + 4), destino)
                self.assertEqual(self.d[dir_ld + 6 - ORG], 0x01)      # ld bc,nn
                self.assertEqual(self.w(dir_ld + 7), n)
                self.assertEqual(self.d[dir_ld + 9 - ORG:dir_ld + 11 - ORG],
                                 bytes([0xED, 0xB0]))                 # ldir

    def test_los_bloques_declarados_coinciden_con_el_entries(self):
        """Lo que dice el .entries y lo que dicen los LDIR son lo mismo."""
        ruta = os.path.join(RAIZ, "src", "gamemaster.entries")
        declarados = []
        with open(ruta, encoding="utf-8") as f:
            for ln in f:
                ln = ln.split("#")[0].strip()
                if ln.lower().startswith("!reubica"):
                    _, a, b, e = ln.split()[:4]
                    declarados.append((int(a, 0), int(b, 0), int(e, 0)))
        porLDIR = [(o, o + n, d) for _, o, d, n in self.COPIAS]
        # La plantilla del RST 30h la copia 0x6AC1 con los registros puestos de
        # otra manera (ex de,hl), asi que va aparte.
        self.assertIn((0x6AD0, 0x6ADD, 0xD33E), declarados)
        for t in porLDIR:
            self.assertIn(t, declarados, "falta !reubica %s" % (t,))

    def test_la_plantilla_de_la_llamada_entre_ranuras(self):
        """0x6AD0: push iy / push ix / rst 30h / 3 ceros / pop ix / pop iy / ret."""
        c = self.d[0x6AD0 - ORG:0x6ADD - ORG]
        self.assertEqual(c, bytes([0xFD, 0xE5, 0xDD, 0xE5, 0xF7,
                                   0x00, 0x00, 0x00,
                                   0xDD, 0xE1, 0xFD, 0xE1, 0xC9]))
        self.assertEqual(len(c), 13)
        # 0x6AC3 rellena los tres ceros en 0xD343, que es 0xD33E + 5: el hueco
        # de detras del RST una vez copiada la plantilla.
        self.assertEqual(self.d[0x6AC3 - ORG:0x6AC6 - ORG],
                         bytes([0x21, 0x43, 0xD3]))
        self.assertEqual(0xD343 - 5, 0xD33E)


class TestTablasDeDespacho(unittest.TestCase):
    """Las 14 tablas pegadas al `call 0x6368`, y de donde sale su tamano."""

    # (call, tabla, entradas, de donde sale el tamano)
    TABLAS = [
        (0x428F, 0x4292, 6, 0x427E), (0x42D1, 0x42D4, 5, 0x42C5),
        (0x4376, 0x4379, 4, 0x4365), (0x43E9, 0x43EC, 5, 0x43DD),
        (0x4446, 0x4449, 4, 0x4435), (0x4494, 0x4497, 4, 0x448F),
        (0x472C, 0x472F, 3, 0x4727), (0x4773, 0x4776, 3, 0x476E),
        (0x4831, 0x4834, 3, 0x482C), (0x4900, 0x4903, 5, 0x48FB),
        (0x4A1F, 0x4A22, 4, 0x4A1A), (0x5613, 0x5616, 2, 0x560E),
        (0x722E, 0x7231, 3, 0x7229),
    ]

    def setUp(self):
        self.d = rom()

    def test_el_despachador(self):
        """0x6368: pop hl / add a,a / add a,l / ld l,a / ... / ex de,hl / jp (hl)."""
        c = self.d[0x6368 - ORG:0x6374 - ORG]
        self.assertEqual(c, bytes([0xE1, 0x87, 0x85, 0x6F, 0x30, 0x01,
                                   0x24, 0x5E, 0x23, 0x56, 0xEB, 0xE9]))

    def test_cada_tabla_va_pegada_a_su_call(self):
        for call, tabla, _, _ in self.TABLAS:
            with self.subTest(hex(call)):
                self.assertEqual(self.d[call - ORG:call + 3 - ORG],
                                 bytes([0xCD, 0x68, 0x63]))
                self.assertEqual(call + 3, tabla)

    def test_el_tamano_sale_del_ld_b_previo(self):
        """No esta contado a ojo: es el `ld b,N` que precede al `call 0x6581`."""
        for call, _, n, dir_b in self.TABLAS:
            with self.subTest(hex(call)):
                self.assertEqual(self.d[dir_b - ORG], 0x06, "no hay ld b,n")
                self.assertEqual(self.d[dir_b + 1 - ORG], n)
                # y entre el ld b,n y el call va la rutina de elegir opcion
                self.assertEqual(self.d[dir_b + 2 - ORG:dir_b + 5 - ORG],
                                 bytes([0xCD, 0x81, 0x65]))

    def test_todos_los_punteros_caen_dentro_del_cartucho(self):
        for call, tabla, n, _ in self.TABLAS:
            for k in range(n):
                a = tabla + 2 * k
                p = self.d[a - ORG] | (self.d[a - ORG + 1] << 8)
                with self.subTest("%s[%d]" % (hex(tabla), k)):
                    self.assertTrue(ORG <= p < ORG + 16384,
                                    "0x%04X fuera del cartucho" % p)

    def test_no_hay_mas_calls_al_despachador_de_los_declarados(self):
        """Si aparece uno nuevo, su tabla esta sin declarar y hay que mirarla."""
        hallados = []
        for i in range(len(self.d) - 2):
            if self.d[i:i + 3] == bytes([0xCD, 0x68, 0x63]):
                hallados.append(ORG + i)
        declarados = [c for c, _, _, _ in self.TABLAS]
        # 0x4F9A es el decimocuarto: no viene de un menu, asi que no esta en la
        # lista de arriba, que solo recoge los que se justifican por el ld b,n.
        self.assertEqual(sorted(hallados), sorted(declarados + [0x4F9A]))


class TestRotulos(unittest.TestCase):
    """Los diecisiete bloques de texto que pinta 0x6294."""

    def setUp(self):
        self.d = rom()
        import sys
        sys.path.insert(0, os.path.join(RAIZ, "tools"))

    def test_el_pintador(self):
        """0x6294: lee DE, escribe con WRTVRM, 0xFE corta y 0xFF cierra."""
        c = self.d[0x6294 - ORG:0x62AB - ORG]
        self.assertEqual(c[0:2], bytes([0x0E, 0xFF]))            # ld c,0xFF
        self.assertEqual(c[2:6], bytes([0x5E, 0x23, 0x56, 0x23]))  # ld e,(hl)...
        self.assertIn(bytes([0xCD, 0x4D, 0x00]), c)              # call WRTVRM

    def test_son_diecisiete_bloques(self):
        from pantallas import quien_los_pinta
        sitios = quien_los_pinta(self.d)
        self.assertEqual(len(sitios), 17)

    def test_los_rotulos_que_esperamos_estan_ahi(self):
        """Si el decodificador se rompe, estos textos dejan de salir."""
        from pantallas import bloque, pinta
        texto = []
        for a in (0x4525, 0x4B42, 0x489A, 0x7968):
            trozos, _ = bloque(self.d, a)
            texto += [l.strip() for l in pinta(trozos)]
        for esperado in ("MENU     DISK SAVE", "MODIFY MODE MENU",
                         "MODIFY PLAYER NUMBER", "SELF MODE MENU",
                         "START GAME"):
            self.assertTrue(any(esperado in l for l in texto),
                            "no aparece %r" % esperado)

    def test_el_copyright_dice_1986(self):
        """Lo que fecha esta compilacion."""
        from pantallas import bloque, pinta
        trozos, fin = bloque(self.d, 0x7968)
        self.assertEqual(fin, 0x7977)
        self.assertIn("KONAMI 1986", "".join(pinta(trozos)))

    def test_todos_los_bloques_cierran_con_FF(self):
        from pantallas import bloque, quien_los_pinta
        for _, a in quien_los_pinta(self.d):
            _, fin = bloque(self.d, a)
            with self.subTest(hex(a)):
                self.assertEqual(self.d[fin - 1 - ORG], 0xFF)


class TestDescompresor(unittest.TestCase):
    """0x62F7 y los bloques que suelta."""

    def setUp(self):
        self.d = rom()

    def test_lee_la_direccion_de_vram_y_llama_a_setwrt(self):
        c = self.d[0x62F7 - ORG:0x6304 - ORG]
        self.assertEqual(c[0:4], bytes([0x5E, 0x23, 0x56, 0x23]))  # ld e,(hl)..
        self.assertIn(bytes([0xCD, 0x53, 0x00]), c)                # call SETWRT
        self.assertIn(bytes([0x3A, 0x06, 0x00]), c)                # ld a,(0x0006)

    def test_la_cuenta_son_siete_bits(self):
        """`and 0x7F` es lo que deja el bit 7 como marca."""
        self.assertEqual(self.d[0x6305 - ORG:0x6307 - ORG],
                         bytes([0xE6, 0x7F]))

    def test_los_tres_tercios(self):
        """0x62E4 llama tres veces sumando 0x800, que es un tercio de SCREEN 2."""
        c = self.d[0x62E4 - ORG:0x62F7 - ORG]
        self.assertEqual(c[0:2], bytes([0x06, 0x03]))              # ld b,3
        self.assertIn(bytes([0x21, 0x00, 0x08]), c)                # ld hl,0x0800
        self.assertEqual(c[-3:-1], bytes([0x10, 0xF0]))            # djnz

    def test_la_direccion_de_vram_de_cada_bloque_es_creible(self):
        """Los dos primeros bytes de un bloque comprimido son su destino."""
        for a, destino in ((0x536F, None), (0x7868, None), (0x78D0, None)):
            w = self.d[a - ORG] | (self.d[a - ORG + 1] << 8)
            with self.subTest(hex(a)):
                self.assertLess(w, 0x4000, "0x%04X no cabe en la VRAM" % w)


class TestPantallaDeTitulo(unittest.TestCase):
    """El dibujo de tools/graficos.py contra la VRAM de verdad del emulador.

    Mirar el PNG no basta y este test es el que lo demuestra: el dibujo parecia
    correcto y le faltaba el "(c) KONAMI 1986", que salia negro sobre negro
    porque no se estaba reproduciendo la animacion de aparicion de 0x533B.

    El volcado se saca con:
        "C:/Program Files/openMSX/openmsx.exe" -machine Philips_VG_8020 \
            -cart gamemaster.rom -script tools/omsx_vram.tcl
    y no se distribuye, asi que si no esta, la prueba se salta.
    """

    VOLCADO = os.path.join(RAIZ, "work", "omsx", "vram-t20.bin")

    # Los bytes que cambian de un volcado a otro. NO es una animacion sola: es
    # Pentaro -el pinguino de Antarctic Adventure- moviendo la vara para
    # senalar una de las tres opciones del menu, y se mueve con los cursores.
    # Por eso cambian a la vez unas casillas de las filas 13 a 18 y cuatro
    # sprites: la vara es media casilla y medio sprite.
    #
    # La lista sale de comparar dos volcados separados en el tiempo (t16 contra
    # t20), no de escribirla a ojo.
    ANIMADOS = {0x39A9, 0x3A06, 0x3A25, 0x3A26, 0x3A27, 0x3A45, 0x3A46, 0x3A47,
                0x3B08, 0x3B09, 0x3B0A, 0x3B0B, 0x3B0C, 0x3B0D, 0x3B0E,
                0x3B14, 0x3B15, 0x3B16, 0x3B17}

    def setUp(self):
        if not os.path.exists(self.VOLCADO):
            self.skipTest("no hay volcado de VRAM; ver el docstring")
        import sys
        sys.path.insert(0, os.path.join(RAIZ, "tools"))
        from graficos import pantalla_de_titulo
        self.mia = pantalla_de_titulo(rom()).v
        with open(self.VOLCADO, "rb") as f:
            self.real = f.read()

    def test_cuadra_con_la_vram_de_verdad(self):
        """Fuera de los bytes animados, no puede sobrar ni faltar nada."""
        difs = [i for i in range(0x4000)
                if self.mia[i] != self.real[i] and i not in self.ANIMADOS]
        self.assertEqual(difs, [], "difieren %d bytes: %s"
                         % (len(difs), " ".join("%04X" % i for i in difs[:20])))

    def test_las_zonas_que_no_se_animan_cuadran_enteras(self):
        for nom, i, f in (("colores", 0x0000, 0x1800),
                          ("patrones de sprite", 0x1800, 0x2000),
                          ("patrones", 0x2000, 0x3800)):
            with self.subTest(nom):
                d = sum(1 for x in range(i, f) if self.mia[x] != self.real[x])
                self.assertEqual(d, 0)

    def test_el_copyright_se_ve(self):
        """Que los caracteres esten en la tabla de nombres NO basta.

        Este es el fallo que hubo: el (c) KONAMI 1986 estaba puesto y aun asi
        no se leia, porque su tabla de colores seguia a cero -tinta negra sobre
        fondo negro-. Asi que no se comprueba que el rotulo este, sino que cada
        uno de sus caracteres tenga un color con tinta y fondo distintos.

        Quien le da ese color es el relleno de tres tercios de 0x50C4, que
        cubre 0x0180..0x02D7: el color de la 'K' esta en 0x0258. Comprobado
        quitandolo: sin el, diez de los once caracteres salen invisibles.
        """
        import sys
        sys.path.insert(0, os.path.join(RAIZ, "tools"))
        from pantallas import bloque
        trozos, _ = bloque(rom(), 0x7968)
        self.assertTrue(trozos, "el bloque de rotulos esta vacio")
        mirados = 0
        for destino, texto in trozos:
            fila = (destino - 0x3800) // 32
            tercio = fila // 8
            for i, car in enumerate(texto):
                if car == 0x00:                      # los huecos dan igual
                    continue
                colores = self.mia[tercio * 0x800 + car * 8:
                                   tercio * 0x800 + car * 8 + 8]
                self.assertTrue(any(c >> 4 != c & 15 for c in colores),
                                "el caracter 0x%02X de la fila %d es invisible: "
                                "tinta y fondo iguales" % (car, fila))
                mirados += 1
        self.assertGreater(mirados, 8, "casi no se ha mirado ningun caracter")


class TestNombresDeFichero(unittest.TestCase):
    def test_los_cuatro_nombres_de_seis_letras(self):
        """0x7028: GAMEDT SCREEN HISCOR RANKDT, las .Gxx .Sxx .Hxx .Rxx."""
        d = rom()
        c = d[0x7028 - ORG:0x7028 + 24 - ORG]
        self.assertEqual(c, b"GAMEDTSCREENHISCORRANKDT")
        self.assertEqual([c[i:i + 6].decode() for i in range(0, 24, 6)],
                         ["GAMEDT", "SCREEN", "HISCOR", "RANKDT"])


class TestLoQueSeDIBUJA(unittest.TestCase):
    """Las cuentas con las que tools/graficos.py monta las pantallas.

    Las dos se equivocaron una vez y las dos se vieron MIRANDO EL PNG, no
    leyendo el codigo: la banda de colores salia como cuatro columnas en vez de
    cuatro filas, y los menus se dibujaban sobre la pantalla de titulo en vez
    de sobre el fondo de trabajo, con lo que el "START GAME" del MODIFY MODE
    salia blanco en vez de verde.
    """

    def setUp(self):
        if not os.path.exists(ROM):
            raise unittest.SkipTest("hace falta gamemaster.rom")
        sys.path.insert(0, os.path.join(RAIZ, "tools"))

    def test_la_banda_son_cuatro_filas_enteras_y_no_cuatro_columnas(self):
        """0x504E escribe A DOS VECES por vuelta con B=0x10: 32 bytes, o sea
        una fila entera. Y el `dec c` de 0x505F la repite cuatro veces."""
        import graficos as G
        v = G.VRAM(rom())
        G.rejilla(v)
        # las filas 0..3 y 20..23, llenas; y la 4 y la 19, intactas
        for base in (0x3800, 0x3A80):
            for f in range(4):
                fila = v.v[base + f * 32:base + f * 32 + 32]
                self.assertEqual(len(set(fila)), 16,
                                 "la fila lleva 1,1,2,2..15,15,0,0")
                self.assertEqual(list(fila[:4]), [1, 1, 2, 2])
                self.assertEqual(list(fila[-4:]), [15, 15, 0, 0])
        self.assertEqual(set(v.v[0x3880:0x38A0]), {0},
                         "la fila 4 no lleva banda")

    def test_los_menus_no_van_sobre_la_pantalla_de_titulo(self):
        """El fondo de un menu es el de 0x5033, que solo trae la fuente.

        Se comprueba donde se ve: en la tabla de COLOR. La de la pantalla de
        titulo y la del fondo de trabajo tienen que ser distintas, porque si
        fueran iguales dibujar el menu sobre una u otra daria lo mismo y este
        test no vigilaria nada.
        """
        import graficos as G
        d = rom()
        titulo = G.pantalla_de_titulo(d).v
        fondo = G.fondo_de_trabajo(d).v
        distintos = sum(1 for i in range(0x0000, 0x1800)
                        if titulo[i] != fondo[i])
        self.assertGreater(distintos, 500,
                           "las dos tablas de color tienen que diferir")
        # y el menu de verdad sale del fondo, no del titulo
        menu = G.con_menu(d, 0x4B42, 0x3880, 0x200, True).v
        self.assertEqual(list(menu[0x0000:0x1800]), list(fondo[0x0000:0x1800]))

    def test_los_tres_rotulos_del_arranque_son_tres_dibujos_distintos(self):
        """0x4FA9, 0x4FB5 y 0x4FC1: el puntero senalando GAME, MODIFY y SELF.

        Son doce casillas cada uno -3x4, el bc=0x0304 de 0x4F91- y los tres
        tienen que ser DISTINTOS: si dos fueran iguales, elegir no cambiaria
        nada en pantalla.
        """
        d = rom()
        tres = [d[a - ORG:a - ORG + 12] for a in (0x4FA9, 0x4FB5, 0x4FC1)]
        for t in tres:
            self.assertEqual(len(t), 12)
        self.assertEqual(len(set(bytes(t) for t in tres)), 3)

    def test_los_dos_juegos_de_atributos_del_menu_son_distintos(self):
        """0x797F y 0x798F, dieciseis bytes cada uno: cuatro sprites.

        0x52C3 y 0x52C8 eligen uno u otro con el bit 0 de (0xD144). Si fueran
        iguales el adorno no se moveria, y de hecho el cotejo contra la VRAM de
        openMSX cae unas veces en uno y otras en otro.
        """
        d = rom()
        a = d[0x797F - ORG:0x797F - ORG + 16]
        b = d[0x798F - ORG:0x798F - ORG + 16]
        self.assertEqual(len(a), 16)
        self.assertNotEqual(a, b)

    def test_los_registros_del_vdp_ponen_el_color_abajo(self):
        """0x6284: R3=0x7F y R4=0x07, o sea color en 0x0000 y patrones en
        0x2000. Es AL REVES de lo que parece, y es lo que coloca los cuatro
        bloques comprimidos del menu. Lo confirma el volcado del emulador."""
        d = rom()
        r = list(d[0x6284 - ORG:0x6284 - ORG + 8])
        self.assertEqual(r, [0x02, 0xE2, 0x0E, 0x7F, 0x07, 0x76, 0x03, 0xE1])
        self.assertEqual((r[3] & 0x80) << 6, 0x0000, "el color, en 0x0000")
        self.assertEqual((r[4] & 0x04) << 11, 0x2000, "los patrones, en 0x2000")
        self.assertEqual(r[2] * 0x400, 0x3800, "los nombres, en 0x3800")
        self.assertEqual(r[5] * 0x80, 0x3B00, "los atributos, en 0x3B00")
        self.assertEqual(r[6] * 0x800, 0x1800, "los sprites, en 0x1800")


# --------------------------------------------------------------------------
# LA WEB
# --------------------------------------------------------------------------
DOCS = os.path.join(RAIZ, "docs")

# Los demas juegos de la serie. Este cartucho es un caso aparte: RECONOCE 28
# juegos de Konami, asi que nombrarlos no es un resto de copia y pega, es el
# contenido. La excepcion se acota a eso y no mas: solo valen en las paginas
# donde se habla de lo que el cartucho reconoce, y solo si en esa pagina
# aparece la palabra que lo justifica.
OTROS_JUEGOS = (
    "Tennis", "Pitfall", "Temptations", "Stardust", "Ale Hop", "Colt 36",
    "Antarctic", "Athletic Land", "Monkey Academy", "F-1 Spirit", "Pippols",
    "Time Pilot", "Frogger", "Super Cobra", "Billiards", "Mahjong",
    "Hyper Rally", "Nemesis", "Demonia", "Cabbage", "Hole in One",
    "Casio World Open", "3D Golf", "Baseball", "Yie Ar Kung-Fu",
    "King's Valley", "Sky Jaguar", "Mopi Ranger", "Descubrimiento",
    "War in Middle Earth", "Ping Pong", "Soccer", "Football", "Road Fighter",
    "Hyper Sports", "Hyper Olympic", "Goonies", "Trailblazer",
    "Circus Charlie", "Magical Tree", "Comic Bakery",
)

# Y los que NUNCA pueden salir: los del andamiaje que se copio de otro
# proyecto. Ninguno de estos esta en el catalogo que el Game Master reconoce,
# asi que si aparece es un resto.
NUNCA = ("Trailblazer", "Gremlin", "Shaun Southern", "Mr Chip",
         "PingPong-disassembly", "SkyJaguar-disassembly",
         "HyperRally-disassembly", "HYPERRALLY_REPO")


class TestLaWebNoNombraOtroProyecto(unittest.TestCase):
    """Que no se cuele el nombre del juego anterior, que ya ha pasado.

    Todo el andamiaje de la web se copia del proyecto anterior, asi que llega
    con su nombre dentro: el pie legal de md2html.py, el titulo de cada pagina,
    la ficha de la portada. Aqui llego con Trailblazer en el pie y Sky Jaguar
    en la portada.
    """

    def ficheros(self):
        """Todo lo que se publica, menos este mismo fichero.

        Se excluye porque la lista NUNCA vive aqui: sin la excepcion, el test
        se caza a si mismo y no sirve para nada. Lo que hay en `tests/` no se
        publica, asi que un resto aqui no llega a nadie.
        """
        yo = os.path.abspath(__file__)
        for base, _, fs in os.walk(RAIZ):
            if any(x in base for x in (".git", "__pycache__", "work",
                                       ".forja")):
                continue
            for f in sorted(fs):
                p = os.path.join(base, f)
                if os.path.abspath(p) == yo:
                    continue
                if f.endswith((".py", ".md", ".html", ".tcl")) or f == "LICENSE":
                    yield p

    def test_ni_un_resto_del_andamiaje_de_otro_proyecto(self):
        malos = []
        for p in self.ficheros():
            t = open(p, encoding="utf-8", errors="ignore").read()
            for m in NUNCA:
                if m in t:
                    malos.append("%s: %s" % (os.path.relpath(p, RAIZ), m))
        self.assertEqual(malos, [], "restos de otro proyecto: %s" % malos)

    def test_los_juegos_solo_se_nombran_donde_son_el_contenido(self):
        """Nombrar un juego vale SI la pagina habla de los que reconoce.

        La palabra que lo justifica tiene que estar en esa misma pagina: si
        alguien pega ahi un texto de otro proyecto, no la llevara.
        """
        justifica = ("reconoce", "recognises", "catálogo", "catalogue",
                     "RC-7", "truco", "cheat")
        malos = []
        for p in self.ficheros():
            if os.sep + "docs" + os.sep not in p and                     os.path.dirname(p) != DOCS:
                continue
            t = open(p, encoding="utf-8", errors="ignore").read()
            nombrados = [j for j in OTROS_JUEGOS if j in t]
            if nombrados and not any(w in t for w in justifica):
                malos.append("%s: %s" % (os.path.relpath(p, RAIZ), nombrados))
        self.assertEqual(malos, [],
                         "juegos nombrados sin venir a cuento: %s" % malos)


class TestLasCifrasDeLaPortada(unittest.TestCase):
    """Las cifras publicadas tienen que ser las que da el listado.

    Se quedan viejas solas: se mide una vez, se escriben, y a la siguiente
    pasada de densidad la web miente sin que nada avise.
    """

    def setUp(self):
        sys.path.insert(0, os.path.join(RAIZ, "tools"))

    def test_la_suma_de_bytes_da_el_cartucho(self):
        import make_web as W
        self.assertEqual(W.CODIGO + W.DATOS, 16384,
                         "codigo + datos tienen que dar los 16384 del cartucho")

    def test_las_cifras_son_las_del_listado(self):
        """CODIGO sale del presupuesto y RUTINAS/DENSIDAD, de densidad.py."""
        import make_web as W
        asm = os.path.join(RAIZ, "src", "gamemaster.asm")
        if not os.path.exists(asm):
            self.skipTest("hace falta el listado; ejecuta make listado")
        etiquetas = 0
        instr = comentadas = 0
        for ln in open(asm, encoding="utf-8"):
            if re.match(r"^[A-Za-z_][A-Za-z0-9_]*:", ln):
                etiquetas += 1
            m = re.match(r"^	(.*?)	*;([0-9a-f]{4})", ln)
            if m and not m.group(1).startswith(("defb", "defw")):
                instr += 1
                if ln.count(";") > 1:
                    comentadas += 1
        densidad = round(100.0 * comentadas / instr, 1)
        self.assertEqual(W.DENSIDAD, densidad,
                         "la portada dice %s %% y el listado da %s %%"
                         % (W.DENSIDAD, densidad))
        self.assertEqual(W.JUEGOS, 28)


if __name__ == "__main__":
    unittest.main()
