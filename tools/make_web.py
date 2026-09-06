#!/usr/bin/env python3
"""Genera la portada de la web del Konami Game Master, en los dos idiomas.

El diseno es el compartido por la serie (tools/estilo_web.py) y la pagina sale
autocontenida, con las imagenes embebidas como data URI.

Las imagenes NO son ilustraciones ni capturas: las dibuja tools/graficos.py a
partir de los propios bytes de la ROM, ejecutando en Python los mismos
descompresores que corre el Z80, y estan comprobadas byte a byte contra la VRAM
de openMSX. Ninguna se ha retocado.

Uso: make_web.py <docs/imagenes> <salida.html> <idioma>
"""
import base64
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from estilo_web import ESTILO                                   # noqa: E402

# Las cifras salen de contar sobre el listado generado, no de escribirlas a ojo.
# CODIGO y DATOS los imprime tools/presupuesto.py (make sanity) y tienen que
# sumar los 16384 bytes del cartucho; RUTINAS y DENSIDAD, tools/densidad.py
# (make densidad). JUEGOS son los que reconoce la tabla de firmas de 0x5F3A,
# contados sobre el binario.
CODIGO = 10522
DATOS = 5862
RUTINAS = 663
DENSIDAD = 22.1
JUEGOS = 28


def mil(n, idioma):
    return f"{n:,}".replace(",", "." if idioma == "es" else ",")



TXT = {
    "es": dict(
        titulo="Konami's Game Master — desensamblado comentado",
        aviso="<b>Aquí no hay ninguna ilustración ni captura.</b> El rótulo y "
              "todas las pantallas están <b>dibujados desde los bytes de la "
              "ROM</b>, ejecutando en Python el mismo descompresor y los mismos "
              "pintores que corre el Z80, y <b>cotejados byte a byte contra la "
              "VRAM de openMSX</b>. El listado y las cifras salen del binario y "
              "se reproducen con <code>make</code>.",
        claim="No es un juego: es el cartucho de trucos de Konami. Se enchufa "
              "en la ranura de al lado, <b>reconoce el juego que tiene "
              "enfrente</b> y le parchea el arranque en la RAM para quedarse "
              "con su interrupción. Es el único cartucho comercial de MSX cuyo "
              "trabajo entero consiste en leer y modificar otro cartucho.",
        ficha=["Konami · <b>© Konami 1986</b>",
               "Cartucho <b>RC-735</b>, 16 KB",
               "MSX1 · <b>página 1</b>", "Volcado <b>3160911a…</b>"],
        nav=[("#numbers", "Las cifras"), ("#findings", "Hallazgos"),
             ("#screens", "Lo que dibuja")],
        docnav=[("EMPEZAR.html", "Empezar"), ("EL-JUEGO.html", "El juego"),
                ("LAS-PANTALLAS.html", "Las pantallas"),
                ("EL-CARTUCHO.html", "El cartucho"),
                ("EL-CODIGO.html", "El código"),
                ("HALLAZGOS.html", "Hallazgos"),
                ("EN-EL-EMULADOR.html", "En el emulador"),
                ("PREGUNTAS-ABIERTAS.html", "Preguntas abiertas")],
        otro=("../", "In English"),
        h_num="El cartucho en cifras", h_find="Lo que apareció al desmontarlo",
        h_scr="Lo que el cartucho dibuja",
        cifras=[("100 %", "del binario explicado"),
                (str(DENSIDAD) + " %", "de instrucciones comentadas"),
                (str(JUEGOS), "juegos que reconoce"),
                (mil(CODIGO, "es"), "bytes de código"),
                (mil(DATOS, "es"), "bytes de datos"),
                ("0", "rutinas sin explicar")],
        nota_scr="Debajo de cada imagen está de dónde sale y qué se está "
                 "viendo.",
        pie_leg="Esto es trabajo de documentación y preservación: el código "
                "sigue siendo de sus autores y de Konami, y la imagen del "
                "cartucho no se distribuye.",
    ),
    "en": dict(
        titulo="Konami's Game Master — a commented disassembly",
        aviso="<b>There is not one illustration or capture here.</b> The "
              "wordmark and every screen are <b>drawn from the bytes of the "
              "ROM</b>, by running in Python the same decompressor and the same "
              "painters the Z80 runs, and <b>checked byte for byte against "
              "openMSX's VRAM</b>. The listing and the numbers come from the "
              "binary and are reproducible with <code>make</code>.",
        claim="It is not a game: it is Konami's cheat cartridge. It plugs into "
              "the next slot, <b>works out which game is sitting opposite</b> "
              "and patches that game's start-up in RAM to take over its "
              "interrupt. It is the only commercial MSX cartridge whose entire "
              "job is to read and modify another cartridge.",
        ficha=["Konami · <b>© Konami 1986</b>",
               "An <b>RC-735</b> 16 KB cartridge",
               "MSX1 · <b>page 1</b>", "Dump <b>3160911a…</b>"],
        nav=[("#numbers", "The numbers"), ("#findings", "What turned up"),
             ("#screens", "What it draws")],
        docnav=[("GETTING-STARTED.html", "Getting started"),
                ("THE-GAME.html", "The game"),
                ("THE-SCREENS.html", "The screens"),
                ("THE-CARTRIDGE.html", "The cartridge"),
                ("THE-CODE.html", "The code"),
                ("FINDINGS.html", "Findings"),
                ("IN-THE-EMULATOR.html", "In the emulator"),
                ("OPEN-QUESTIONS.html", "Open questions")],
        otro=("es/", "En castellano"),
        h_num="The cartridge in numbers",
        h_find="What turned up when we took it apart",
        h_scr="What the cartridge draws",
        cifras=[("100%", "of the binary explained"),
                (str(DENSIDAD) + "%", "of instructions commented"),
                (str(JUEGOS), "games it recognises"),
                (mil(CODIGO, "en"), "bytes of code"),
                (mil(DATOS, "en"), "bytes of data"),
                ("0", "routines left unexplained")],
        nota_scr="Under each picture is where it comes from and what is on it.",
        pie_leg="This is documentation and preservation work: the code still "
                "belongs to its authors and to Konami, and the cartridge image "
                "is not distributed.",
    ),
}

HALLAZGOS = {
    "es": [
        ("Se cuela buscando una instrucción que llevan los 40 cartuchos de Konami",
         "<p>Copia a la RAM los <b>256 primeros bytes del arranque</b> del "
         "cartucho vecino, leyéndolos con RDSLT, y busca ahí la secuencia "
         "<code>9B FD</code>: es el operando de "
         "<code>ld (0xFD9B),hl</code>, la instrucción con la que un juego de "
         "Konami instala su rutina de interrupción en el gancho H.KEYI. La "
         "sustituye por cinco bytes (0x4CB9) y esa instrucción pasa a ser "
         "<code>ld (0xD130),hl</code> + <code>call 0xD814</code>: el gancho del "
         "juego queda guardado y el control es del Game Master. Luego ejecuta "
         "<b>la copia parcheada, no la original</b>.</p>"
         "<p>Funciona con todo el catálogo porque todos los cartuchos de "
         "Konami arrancan igual. Comprobado sobre las 42 ROM de cartucho de la "
         "colección: <b>las 40 de Konami llevan esa instrucción</b> en los 256 "
         "bytes de su INIT. Las dos únicas que no la llevan son Casio World "
         "Open —que no es de Konami— y el propio Game Master.</p>"),
        ("Reconoce 28 juegos, y no por el nombre: por una suma",
         "<p>Primero mira si el vecino trae la <b>segunda cabecera</b> de "
         "0x4010, la que empieza por <code>AB</code> o <code>CD</code>. De las "
         "42 ROM de la colección sólo la llevan cinco. Para todo lo demás "
         "<b>suma los 256 bytes que van de 0x5000 a 0x50FF</b> de la ROM del "
         "vecino y busca esa suma de 16 bits en la tabla de 0x5F3A: <b>62 "
         "entradas</b> que apuntan a <b>29 cabeceras postizas</b> de 19 bytes "
         "para <b>28 juegos</b> —la tabla lleva las compilaciones alternativas "
         "de cada uno—.</p>"
         "<p>La tabla está cotejada: de los 28, <b>25 se han comprobado "
         "sumando de verdad los bytes de sus ROM</b>. Los otros tres no tienen "
         "ROM aquí y salen del manual, y el binario y el manual coinciden "
         "<b>hasta en los huecos</b>: ni uno ni otro tienen RC-719, RC-722 ni "
         "RC-726.</p>"),
        ("Konami dice desde dentro que dos de sus juegos son el mismo",
         "<p>La tabla de trucos de 0x5B02 da una rutina por juego, y hay dos "
         "parejas que <b>comparten la suya</b>. Una es RC-710 y RC-711, los dos "
         "Hyper Olympic, que se distinguen dentro comparando el número de "
         "catálogo. La otra es <b>RC-700 y RC-716</b>: para el Game Master, "
         "Athletic Land y Cabbage Patch Kids son el mismo programa y se les "
         "tocan las mismas variables. Es exactamente lo que se midió al "
         "desensamblar el segundo, ahora dicho por la propia Konami.</p>"),
        ("El aviso de truco activo es el LED de CAPS",
         "<p>El cartucho no puede pintar en la pantalla del juego sin "
         "estropearla, así que <b>avisa con la luz del teclado</b>: 0x4E70 "
         "llama a CHGCAP cada vez que se congela o se descongela la partida. Y "
         "al congelar <b>calla el PSG de verdad</b>: 0x4E85 se guarda los "
         "volúmenes de los tres canales antes de ponerlos a cero, y 0x4EF8 los "
         "devuelve al reanudar.</p>"
         "<p>De paso, un ahorro de los que se ven poco: <b>0xD12D guarda el "
         "volumen del canal C y a la vez es el byte bajo del IY</b> con el que "
         "se llama entre ranuras. Se puede porque CALSLT sólo mira IYh.</p>"),
        ("Vive en la misma página que el juego, así que se copia a la RAM para poder moverse",
         "<p>El Game Master ocupa la página 1. El juego al que le hace trucos "
         "ocupa <b>también</b> la página 1, en otra ranura: los dos no pueden "
         "estar puestos a la vez. Todo el cartucho está construido alrededor de "
         "esa pelea. <b>Seis bloques de código se copian a la RAM y se ejecutan "
         "allí</b>, porque conmutar la ranura desde la ROM sería serrar la rama "
         "en la que uno está sentado.</p>"
         "<p>Eso obliga a leer el listado con cuidado: las direcciones "
         "absolutas de esos bloques apuntan a <b>donde se ejecutan</b>, no a "
         "donde están guardadas. El trazador lleva una directiva "
         "(<code>!reubica</code>) para seguirlos, y con ella el trazado pasó "
         "del 52,9 % al 60,0 %.</p>"),
        ("Los menús se abren encima del juego, sin cambiar de pantalla",
         "<p>Los menús de disco y cinta sólo borran <b>0x100 bytes desde "
         "0x3A00</b>, o sea las ocho filas de abajo: lo demás se queda como "
         "estaba. Y antes, 0x4275 llama a la rutina que se lleva la VRAM del "
         "juego a la RAM para poder devolverla. Así que en la máquina real "
         "<b>la mitad de arriba de esas pantallas es la partida corriendo</b>, "
         "no un fondo del cartucho.</p>"),
        ("Cuatro rutinas y dos puertas a las que no llega nadie",
         "<p>Cuatro trozos (0x6445, 0x6787, 0x6904 y 0x6938) desensamblan a Z80 "
         "correcto, empiezan justo detrás de un <code>ret</code> y acaban justo "
         "donde arranca una etiqueta que sí se usa. Pero <b>no hay ni una "
         "referencia de 16 bits ni un salto relativo que caiga en ellos</b>, "
         "buscados por los 16.384 bytes del cartucho. Más dos puertas de dos "
         "bytes (0x5022 y 0x6FB5), cada una un <code>ld b,N</code> puesto para "
         "poder entrar a la rutina de al lado con otro valor, a las que no "
         "salta nadie. Son restos de una compilación anterior: de este cartucho "
         "hay tres.</p>"),
        ("Sí lleva la marca oculta de Konami, y confirma un carácter que faltaba",
         "<p>En los últimos 22 bytes: <b>RC-735</b> y 19 bytes de katakana que "
         "dicen <b>10バイタノシムカートリッジ</b> —«el cartucho para disfrutar "
         "diez veces más»—, que era su eslogan. El formato lo descubrió "
         "<b>Manuel Pazos</b> "
         "(<a href=\"https://twitter.com/ManuelPazosMSX\">@ManuelPazosMSX</a>). "
         "De paso, esta marca <b>confirma que el 0xBA es el alargamiento ー</b>, "
         "que hasta ahora estaba sin cerrar.</p>"),
    ],
    "en": [
        ("It gets in by looking for one instruction that all 40 Konami cartridges carry",
         "<p>It copies the neighbouring cartridge's <b>first 256 start-up "
         "bytes</b> into RAM, reading them through RDSLT, and looks there for "
         "the sequence <code>9B FD</code>: the operand of "
         "<code>ld (0xFD9B),hl</code>, the instruction a Konami game uses to "
         "install its interrupt routine into the H.KEYI hook. It replaces that "
         "with five bytes (0x4CB9) and the instruction becomes "
         "<code>ld (0xD130),hl</code> + <code>call 0xD814</code>: the game's own "
         "hook is saved and the Game Master has the control. Then it runs "
         "<b>the patched copy, not the original</b>.</p>"
         "<p>It works across the whole catalogue because every Konami cartridge "
         "starts the same way. Checked over the 42 cartridge ROMs in the "
         "collection: <b>all 40 Konami ones carry that instruction</b> in the "
         "256 bytes of their INIT. The only two that do not are Casio World "
         "Open — not a Konami title — and the Game Master itself.</p>"),
        ("It recognises 28 games, and not by name: by a sum",
         "<p>First it checks whether the neighbour carries the <b>second "
         "header</b> at 0x4010, the one starting with <code>AB</code> or "
         "<code>CD</code>. Only five of the 42 ROMs in the collection have it. "
         "For everything else it <b>adds up the 256 bytes from 0x5000 to "
         "0x50FF</b> of the neighbour's ROM and looks that 16-bit sum up in the "
         "table at 0x5F3A: <b>62 entries</b> pointing at <b>29 stand-in "
         "headers</b> of 19 bytes for <b>28 games</b> — the table carries each "
         "game's alternative builds.</p>"
         "<p>The table has been checked: of the 28, <b>25 were verified by "
         "actually summing the bytes of their ROMs</b>. The other three have no "
         "ROM here and come from the manual, and binary and manual agree "
         "<b>even in the gaps</b>: neither has RC-719, RC-722 or RC-726.</p>"),
        ("Konami says from the inside that two of its games are the same one",
         "<p>The cheat table at 0x5B02 gives one routine per game, and two "
         "pairs <b>share theirs</b>. One is RC-710 and RC-711, the two Hyper "
         "Olympic titles, told apart inside by their catalogue number. The "
         "other is <b>RC-700 and RC-716</b>: as far as the Game Master is "
         "concerned, Athletic Land and Cabbage Patch Kids are the same program "
         "and get the same variables poked. That is exactly what was measured "
         "when the second one was disassembled — now said by Konami itself.</p>"),
        ("The \"cheat active\" light is the CAPS LED",
         "<p>The cartridge cannot paint on the game's screen without ruining "
         "it, so it <b>signals with the keyboard light</b>: 0x4E70 calls CHGCAP "
         "every time the game is frozen or resumed. And freezing <b>really does "
         "silence the PSG</b>: 0x4E85 saves the three channel volumes before "
         "zeroing them, and 0x4EF8 puts them back.</p>"
         "<p>There is a rarely seen saving in there too: <b>0xD12D holds the "
         "channel C volume and is also the low byte of the IY</b> used for "
         "inter-slot calls. It works because CALSLT only looks at IYh.</p>"),
        ("It lives in the same page as the game, so it copies itself into RAM to move",
         "<p>The Game Master sits in page 1. The game it is cheating sits in "
         "page 1 <b>as well</b>, in another slot: the two cannot be switched in "
         "at once. The whole cartridge is built around that fight. <b>Six blocks "
         "of code are copied into RAM and executed there</b>, because switching "
         "the slot from ROM would be sawing off the branch you are sitting "
         "on.</p>"
         "<p>That forces careful reading: the absolute addresses inside those "
         "blocks point at <b>where they run</b>, not where they are stored. The "
         "tracer carries a directive (<code>!reubica</code>) to follow them, and "
         "with it the trace went from 52.9% to 60.0%.</p>"),
        ("The menus open on top of the running game, without changing screen",
         "<p>The disk and tape menus only clear <b>0x100 bytes from 0x3A00</b>, "
         "that is the bottom eight rows: everything else stays as it was. And "
         "before that, 0x4275 calls the routine that carries the game's VRAM "
         "into RAM so it can be put back. So on a real machine <b>the top half "
         "of those screens is the game still running</b>, not a cartridge "
         "backdrop.</p>"),
        ("Four routines and two doors nobody reaches",
         "<p>Four fragments (0x6445, 0x6787, 0x6904 and 0x6938) disassemble to "
         "correct Z80, start right after a <code>ret</code> and end right where "
         "a label that <i>is</i> used begins. But <b>there is not one 16-bit "
         "reference nor one relative jump landing on them</b>, searched across "
         "all 16,384 bytes. Plus two two-byte doors (0x5022 and 0x6FB5), each a "
         "<code>ld b,N</code> put there to enter the neighbouring routine with a "
         "different value, that nobody jumps to. They are leftovers from an "
         "earlier build: there are three of this cartridge.</p>"),
        ("It does carry Konami's hidden mark, and it settles a character",
         "<p>In the last 22 bytes: <b>RC-735</b> and 19 katakana bytes reading "
         "<b>10バイタノシムカートリッジ</b> — \"the cartridge for ten times the "
         "fun\" — which was its slogan. The format was discovered by "
         "<b>Manuel Pazos</b> "
         "(<a href=\"https://twitter.com/ManuelPazosMSX\">@ManuelPazosMSX</a>). "
         "As a bonus, this mark <b>confirms that 0xBA is the ー lengthener</b>, "
         "which had been left open until now.</p>"),
    ],
}

GALERIA = [
    ("titulo.png",
     "<b>La pantalla de título</b>, montada paso a paso como la monta el "
     "cartucho: los cuatro bloques comprimidos del fondo, los dos rectángulos "
     "de caracteres, el bloque de rótulos con el <code>© KONAMI 1986</code> que "
     "fecha la compilación, y los seis atributos de sprite. Cotejada contra la "
     "VRAM de openMSX: de los 16.384 bytes, el único que discrepa es "
     "<b>0x39A9</b>, y no es un error — es el cursor parpadeando",
     "<b>The title screen</b>, built step by step the way the cartridge builds "
     "it: the four compressed background blocks, the two character rectangles, "
     "the label block with the <code>© KONAMI 1986</code> that dates the build, "
     "and the six sprite attributes. Checked against openMSX's VRAM: of the "
     "16,384 bytes the only one that differs is <b>0x39A9</b>, and it is not a "
     "mistake — it is the cursor blinking"),
    ("menu-modify.png",
     "<b>El MODIFY MODE</b>, que es a lo que se viene: elegir en qué fase "
     "empezar y con cuántas vidas. Las bandas de colores de arriba y abajo no "
     "son un dibujo guardado: las escribe un bucle (0x504E) que repite cada "
     "casilla dos veces, del 1 al 15 y vuelta a empezar, cuatro filas enteras "
     "por banda",
     "<b>The MODIFY MODE</b>, which is what you came for: pick the stage to "
     "start on and how many lives. The colour bands top and bottom are not a "
     "stored picture: a loop (0x504E) writes them, repeating each tile twice "
     "from 1 to 15 and round again, four whole rows per band"),
    ("arranque-1.png",
     "El menú de arranque, con <b>el puntero de tiza</b> señalando la opción "
     "elegida. Los tres punteros son doce casillas cada uno (0x4FA9, 0x4FB5 y "
     "0x4FC1) que se pintan en el mismo sitio de la pantalla, y para saber qué "
     "eran hubo que dibujarlos: leídos como bytes no dicen nada",
     "The start-up menu, with <b>the chalk pointer</b> aiming at the chosen "
     "line. The three pointers are twelve tiles each (0x4FA9, 0x4FB5 and "
     "0x4FC1) painted in the same spot on screen, and finding out what they "
     "were meant drawing them: read as bytes they say nothing"),
    ("menu-principal.png",
     "El menú de disco y cinta. En la máquina real <b>la mitad de arriba es el "
     "juego corriendo</b>: esta pantalla sólo borra las ocho filas de abajo, y "
     "antes se ha llevado la VRAM del juego a la RAM para devolverla al salir. "
     "Aquí sale sobre negro porque no hay juego que poner",
     "The disk and tape menu. On a real machine <b>the top half is the running "
     "game</b>: this screen only clears the bottom eight rows, and the game's "
     "VRAM has been carried into RAM beforehand so it can be restored on the "
     "way out. Here it shows on black because there is no game to put"),
    ("menu-self.png",
     "El <b>SELF MODE</b>, el menú de comprobaciones: el patrón de prueba de "
     "color y la carga de pantallas guardadas",
     "The <b>SELF MODE</b>, the test menu: the colour test pattern and loading "
     "saved screens"),
    ("menu-modo-ranking.png",
     "El modo <b>RANKING</b>. El cartucho guarda una tabla de récords por "
     "juego, la imprime si hay impresora, y cuando se borra deja los seis "
     "puestos con el nombre de la casa: <code>KONAMI</code>",
     "The <b>RANKING</b> mode. The cartridge keeps a high-score table per game, "
     "prints it if there is a printer, and when cleared leaves all six places "
     "under the house name: <code>KONAMI</code>"),
]



def img64(ruta):
    with open(ruta, "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode()


def main(argv):
    if len(argv) < 4:
        print(__doc__)
        return 2
    imgdir, salida, idioma = argv[1:4]
    t = TXT[idioma]

    # El "logotipo" de la cabecera no es un montaje ni una captura: es el rotulo
    # que el propio cartucho pinta en su pantalla de titulo, dibujado desde la
    # ROM por graficos.py. Si el PNG no esta, el trabajo NO esta hecho: se cae
    # al texto, y eso se ve.
    ruta_logo = os.path.join(imgdir, "rotulo.png")
    cabecera = (f'<img src="{img64(ruta_logo)}" alt="Game Master">'
                if os.path.exists(ruta_logo) else "<h1>Konami's Game Master</h1>")

    nav = "".join(f'<a href="{h}">{x}</a>' for h, x in t["nav"])
    nav += "".join(f'<a href="{h}">{x}</a>' for h, x in t["docnav"])
    nav += (f'<a href="{t["otro"][0]}" style="margin-left:auto;color:var(--oro)">'
            f'{t["otro"][1]}</a>')

    cifras = "".join(f'<div class="cifra"><b>{v}</b><span>{e}</span></div>'
                     for v, e in t["cifras"])
    halls = "".join(f'<div class="hall"><h3>{tit}</h3>{cuerpo}</div>'
                    for tit, cuerpo in HALLAZGOS[idioma])
    imgs = ""
    faltan = []
    for fich, es, en in GALERIA:
        ruta = os.path.join(imgdir, fich)
        if not os.path.exists(ruta):
            faltan.append(fich)
            continue
        pie = es if idioma == "es" else en
        imgs += (f'<figure><img src="{img64(ruta)}" alt="{pie}">'
                 f'<figcaption>{pie}</figcaption></figure>')
    if faltan:
        print("  (faltan %d imagenes: %s)" % (len(faltan), " ".join(faltan)))

    html = f"""<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{t['titulo']}</title>
<style>{ESTILO}</style>
<header class="top">
  {cabecera}
  <p class="claim">{t['claim']}</p>
  <p class="ficha">{' · '.join(t['ficha'])}</p>
</header>
<p class="ficha" style="border:1px solid var(--oro);padding:.8em 1em;margin:1.5em 0">
{t['aviso']}</p>
<nav>{nav}</nav>
<section id="numbers">
  <h2>{t['h_num']}</h2>
  <div class="cifras">{cifras}</div>
</section>
<section id="findings"><h2>{t['h_find']}</h2>{halls}</section>
<section id="screens">
  <h2>{t['h_scr']}</h2>
  <p class="n">{t['nota_scr']}</p>
  <div class="galeria">{imgs}</div>
</section>
<footer><p>{t['pie_leg']}</p></footer>
"""
    with open(salida, "w", encoding="utf-8") as f:
        f.write(html)
    print("  %s: %d KB (%s)" % (salida, len(html) // 1024, idioma))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
