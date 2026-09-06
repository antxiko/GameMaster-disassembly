# Konami's Game Master (Konami, MSX1) - desensamblado
#
# El orden de las cosas: trazar el flujo -> generar el listado -> comprobar que
# vuelve a dar la ROM byte a byte -> las comprobaciones que el reensamblado NO
# cubre.
#
# La ROM no se distribuye. Hace falta en la raiz como gamemaster.rom, y
# `make comprueba` verifica el sha256.

ROM      = gamemaster.rom
SHA      = 3160911ae025207c80c40630f8ce94f857e7e820c97a437152124def25b0f7ee
SRC      = src
WORK     = work
ORG      = 0x4000
TITULO   = KONAMI'S GAME MASTER - Konami - MSX1 - cartucho RC-735 de 16 KB en la pagina 1

all: listado verify sanity test

$(ROM):
	@echo "=================================================================="
	@echo " Falta $(ROM), y este repositorio NO lo distribuye."
	@echo ""
	@echo " Es Konami's Game Master (RC-735) para MSX, la European Version"
	@echo " de 1986, 16384 bytes exactos. Ponlo aqui con ese nombre."
	@echo " Para comprobar que es el mismo:"
	@echo "     shasum -a 256 $(ROM)"
	@echo "     $(SHA)"
	@echo "=================================================================="
	@false

comprueba: $(ROM)
	@echo "$(SHA)  $(ROM)" | shasum -a 256 -c -

# El trazado sigue el flujo desde los puntos de entrada. Los que no se pueden
# deducir estaticamente -ganchos de interrupcion, destinos de saltos
# indirectos- estan declarados en el .entries, cada uno con su justificacion.
$(WORK)/gamemaster.trace.json: $(ROM) $(SRC)/gamemaster.entries $(SRC)/gamemaster.nocode
	@mkdir -p $(WORK)
	python3 tools/z80trace.py $(ROM) $(ORG) $(SRC)/gamemaster.entries \
	        $(WORK)/gamemaster $(SRC)/gamemaster.nocode

trace: $(WORK)/gamemaster.trace.json

listado: $(WORK)/gamemaster.trace.json $(SRC)/gamemaster.notes
	python3 tools/mkasm.py $(ROM) $(ORG) $(WORK)/gamemaster.trace.json \
	        $(SRC)/gamemaster.notes work/msx.sym $(SRC)/gamemaster.asm "$(TITULO)"

# La prueba que decide si el desensamblado es fiable.
verify: $(SRC)/gamemaster.asm $(ROM)
	@sh tools/verify_build.sh $(SRC)/gamemaster.asm $(ROM) $(ORG)

# Lo que el reensamblado NO puede cazar: que unos datos se esten leyendo como
# codigo. El binario sale identico igual, porque los bytes no cambian; lo unico
# que cambia es lo que decimos de ellos.
sanity: $(WORK)/gamemaster.trace.json
	@echo "=================================================================="
	@echo " ningun byte declarado como datos puede salir como codigo"
	@echo "=================================================================="
	@python3 tools/check_trace.py $(WORK)/gamemaster.trace.json $(SRC)/gamemaster.nocode
	@python3 tools/check_datos_como_codigo.py $(WORK) $(SRC)
	@echo "=================================================================="
	@echo " ningun punto de entrada puede caer dentro de una zona de datos"
	@echo "=================================================================="
	@python3 tools/check_entradas.py $(SRC)/gamemaster.entries $(SRC)/gamemaster.notes \
	        $(SRC)/gamemaster.nocode
	@echo "=================================================================="
	@echo " ni un byte del cartucho sin asignar"
	@echo "=================================================================="
	@python3 tools/presupuesto.py $(WORK) $(SRC)

densidad:
	@python3 tools/densidad.py $(SRC)/gamemaster.asm

test:
	@echo "=================================================================="
	@echo " Tests"
	@echo "=================================================================="
	@python3 -m unittest discover -s tests -v

# Las pantallas, montadas ejecutando en Python los pasos del cartucho: el
# descompresor de 0x62F7, el pintor de rectangulos de 0x7852 y el de rotulos de
# 0x6294. No hay ni una captura de pantalla en este repositorio.
imagenes: $(ROM)
	@mkdir -p work/gfx
	python3 tools/graficos.py $(ROM) $(ORG) work/gfx

# Y la comprobacion de que esas pantallas son las de verdad: se deja correr el
# cartucho en openMSX, se vuelca su VRAM y se compara BYTE A BYTE. Mirar el
# dibujo no basta.
OPENMSX = C:/Program Files/openMSX/openmsx.exe
vram: $(ROM)
	@rm -rf work/omsx && mkdir -p work/omsx
	GM_SALIDA=work/omsx "$(OPENMSX)" -machine Philips_VG_8020 \
	    -cart $(ROM) -script tools/omsx_vram.tcl
	@python3 tools/coteja_vram.py $(ROM) $(ORG) work/omsx

# LA WEB
#
# Bilingue: el ingles en docs/ y el castellano en docs/es/. Las paginas se
# escriben en markdown y se convierten con md2html.py; la portada la monta
# make_web.py, que declara las cifras medidas de ESTE cartucho.
web: $(ROM)
	python3 tools/graficos.py $(ROM) $(ORG) docs/imagenes
	python3 tools/md2html.py docs en
	python3 tools/md2html.py docs/es es
	python3 tools/make_web.py docs/imagenes docs/index.html en
	python3 tools/make_web.py docs/imagenes docs/es/index.html es
	python3 tools/check_enlaces.py docs

clean:
	rm -rf $(WORK)/gamemaster.trace.json $(WORK)/gamemaster.blocks

.PHONY: all comprueba trace listado verify sanity test densidad imagenes vram web clean
