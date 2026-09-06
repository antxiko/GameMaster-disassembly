# omsx_vram.tcl - Vuelca la VRAM de verdad del Game Master, para cotejar los PNG.
#
# Para que sirve: tools/graficos.py monta la pantalla de titulo ejecutando en
# Python los pasos del cartucho -el descompresor de 0x62F7, el pintor de
# rectangulos de 0x7852 y el de rotulos de 0x6294-. Mirar el dibujo NO basta:
# hay que comparar sus bytes con los que el VDP tiene de verdad.
#
# No pone ningun punto de ruptura: los volcados van por reloj emulado. La
# pantalla de titulo se monta una sola vez al arrancar y se queda quieta, asi
# que con esperar un par de segundos sobra.
#
# Variables de entorno:
#   GM_SALIDA  carpeta de salida (por defecto work/omsx)
#
#   "C:/Program Files/openMSX/openmsx.exe" -machine Philips_VG_8020 \
#       -cart gamemaster.rom -script tools/omsx_vram.tcl

proc opcion {nombre porDefecto} {
    global env
    if {[info exists env($nombre)]} { return $env($nombre) }
    return $porDefecto
}

set ::SALIDA [opcion GM_SALIDA {work/omsx}]
file mkdir $::SALIDA

proc vuelca {etiqueta} {
    # Los 16 KB de VRAM tal cual los tiene el VDP.
    set f [open [file join $::SALIDA "vram-$etiqueta.bin"] wb]
    fconfigure $f -translation binary
    puts -nonewline $f [debug read_block VRAM 0 16384]
    close $f

    # Y los ocho registros, que son los que dicen donde esta cada tabla.
    set g [open [file join $::SALIDA "vdp-$etiqueta.txt"] w]
    for {set i 0} {$i < 8} {incr i} {
        puts $g [format "R%d = 0x%02X" $i [debug read "VDP regs" $i]]
    }
    close $g
    puts "volcado $etiqueta"
}

# Varios instantes. El primer volcado a los 6 segundos salia NEGRO: entre el
# arranque de la BIOS y el barrido de ranuras que hace el cartucho, la pantalla
# de titulo tarda en montarse. Por eso se vuelca varias veces y se elige.
after time 8  { vuelca "t08" }
after time 12 { vuelca "t12" }
after time 16 { vuelca "t16" }
after time 20 { vuelca "t20" }
after time 25 { vuelca "t25" ; exit }
