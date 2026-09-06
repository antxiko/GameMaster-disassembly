; ==========================================================================
; KONAMI'S GAME MASTER - Konami - MSX1 - cartucho RC-735 de 16 KB en la pagina 1
; ==========================================================================
; Generado por tools/mkasm.py a partir del trazado de flujo real.
; Los comentarios provienen de tools/../src/*.notes y estan anclados a
; direccion, de modo que sobreviven a un retrazado.
; ==========================================================================

	org 0x04000


; ----------------------------------------------------------------------
; DATOS cabecera_cartucho: AB y el puntero INIT (0x4010); STATEMENT, DEVICE y
;   TEXT a cero
;   0x4000..0x4010  (16 bytes)
DATA_cabecera_cartucho:
	defb 041h,042h	; 4000
	defw 04010h,00000h,00000h,00000h	; 4002  -> INIT 0x0000 0x0000 0x0000
	defw 00000h,00000h,00000h	; 400a

; ======================================================================
; CODIGO 0x4010..0x4226  (534 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ARRANQUE. La BIOS entra aqui por la cabecera del cartucho.
; ----------------------------------------------------------------------
INIT:
	di			;4010
	ld hl,0c000h		;4011
	ld de,0c001h		;4014
	ld (hl),000h		;4017   ; borra los 8 KB de 0xC000 a 0xDFFF, que son la RAM de trabajo
	ld bc,01fffh		;4019
	ldir		;401c
	ld a,0ffh		;401e
	ld (0d13bh),a		;4020
	call mi_ranura		;4023   ; en que ranura estoy yo: se guarda en 0xD12E
	ld (0d12eh),a		;4026
	or a			;4029
	ld b,004h		;402a   ; la ranura de al lado: la mia mas 4 si estoy en una expandida, mas 1 si no
	jp m,L_4031		;402c
	ld b,001h		;402f
L_4031:
	add a,b			;4031
	ld (0d12fh),a		;4032
	call L_419A		;4035   ; monta el cargador en 0xC000 y salta alli; vuelve con carry si no hay juego
	jr nc,L_4049		;4038
	jp L_422F		;403a

; ----------------------------------------------------------------------
; REGRESO DESDE EL JUEGO. Aqui no se llega por el flujo: se entra desde 0xC800, y a 0xC800 se llega por el gancho H.TIMI que 0x4253 dejo plantado.
; ----------------------------------------------------------------------
L_403D:
	di			;403d
	ld hl,0e280h		;403e   ; devuelve a su sitio los 4352 bytes de RAM que el juego habia machacado
	ld de,0c000h		;4041
	ld bc,01100h		;4044   ; son los 0x1100 que se salvaron en 0xE280, que es donde este cartucho aparca su RAM mientras el juego corre
	ldir		;4047
L_4049:
	di			;4049
	ld sp,0df80h		;404a   ; la pila propia, en 0xDF80: la del juego ya no vale
	call L_40D0		;404d   ; busca por las ranuras un cartucho que no sea este
	jp nc,L_4089		;4050
	ld hl,04002h		;4053   ; hay juego: se le lee el puntero INIT de 0x4002
	call lee_palabra_del_vecino		;4056
	jp z,L_4089		;4059
	ex de,hl			;405c
	ld (0d132h),hl		;405d   ; y se guarda en 0xD132, que es de donde saldra la direccion a la que saltar
L_4060:
	ld hl,0f100h		;4060   ; salva los 0x314 bytes de la zona de trabajo de la BIOS (0xF100) en 0xD500, porque el juego los va a machacar
	ld de,0d500h		;4063
	ld bc,00314h		;4066
	ldir		;4069
	call L_4C76		;406b   ; la maniobra: parchear el gancho de interrupcion del juego
	jp nz,L_4089		;406e
	call L_4CBE		;4071
	call L_5E40		;4074   ; e identificar que juego es
	ld a,007h		;4077
	call 00141h		;4079   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix | la linea 7 del teclado, bit 2: si esa tecla esta pulsada no se entra al juego, se queda en el menu
	and 004h		;407c
	jr z,L_4093		;407e
	ld hl,0d13ch		;4080
	ld a,(hl)			;4083
	or a			;4084
	jr nz,L_4093		;4085
	dec a			;4087
	ld (hl),a			;4088
L_4089:
	xor a			;4089
	ld (0d129h),a		;408a
	ld (0d13dh),a		;408d
	jp L_4F43		;4090   ; sin juego que tocar, el cartucho se queda para el solo
L_4093:
	di			;4093
	ld a,0ffh		;4094
	ld (0d13dh),a		;4096
	xor a			;4099
	ld (0d13bh),a		;409a
	ld (0d33ah),a		;409d
	jp 0d83bh		;40a0   ; y con juego, a 0xD83B: el bloque de 0x4CF1 ya copiado a la RAM

; ----------------------------------------------------------------------
; EN QUE RANURA ESTOY. El truco clasico del MSX: RSLREG, quedarse con los dos bits de la pagina 1, y mezclarles el bit 7 de EXPTBL y los de subranura de SLTTBL.
; ----------------------------------------------------------------------
mi_ranura:
	call 00138h		;40a3   ; BIOS RSLREG - Reads the primary slot register
	rrca			;40a6   ; RSLREG da los cuatro pares de bits; los de la pagina 1 son el segundo
	rrca			;40a7
	and 003h		;40a8
	ld c,a			;40aa
	ld b,000h		;40ab
	ld hl,0fcc1h		;40ad   ; EXPTBL, cuyo bit 7 dice si la ranura primaria esta expandida
	add hl,bc			;40b0
	or (hl)			;40b1
	ld c,a			;40b2
	inc hl			;40b3
	inc hl			;40b4
	inc hl			;40b5   ; y tres mas alla esta SLTTBL, de donde salen los dos bits de subranura
	inc hl			;40b6
	ld a,(hl)			;40b7
	and 00ch		;40b8
	or c			;40ba
	ret			;40bb

; ----------------------------------------------------------------------
; LEER DOS BYTES DEL CARTUCHO DE AL LADO. Deja el valor en DE y pone Z si los dos son cero. Con HL=0x4002 dice si hay cartucho; con HL=0x4010, si trae segunda cabecera.
; ----------------------------------------------------------------------
lee_palabra_del_vecino:
	ld a,(0d12fh)		;40bc   ; la ranura del vecino, que 0x4032 dejo en 0xD12F
	ld c,a			;40bf
L_40C0:
	call L_40C4		;40c0   ; dos veces: la primera deja el byte bajo en E y la segunda el alto en D
	ld e,d			;40c3
L_40C4:
	ld a,c			;40c4
	push bc			;40c5
	push de			;40c6
	call 0000ch		;40c7   ; BIOS RDSLT - Reads the value of an address in another slot | RDSLT es la unica forma de leer una ranura que no esta puesta
	pop de			;40ca
	pop bc			;40cb
	ld d,a			;40cc
	or e			;40cd
	inc hl			;40ce
	ret			;40cf

; ----------------------------------------------------------------------
; Copia el buscador de ranura a 0xDA00 y salta alli. Tiene que correr desde la RAM porque va a conmutar la pagina 1, que es donde vive este cartucho.
; ----------------------------------------------------------------------
L_40D0:
	ld hl,L_40DE		;40d0
	ld de,0da00h		;40d3
	ld bc,000bch		;40d6   ; 0xBC bytes, que es justo lo que mide el bloque de 0x40DE
	ldir		;40d9
	jp 0da00h		;40db

; ----------------------------------------------------------------------
; ESTO CORRE EN 0xDA00, NO AQUI. Busca por las ranuras un cartucho que no sea este. Un `jp 0xDAxx` de aqui dentro es un salto a este mismo bloque: restale 0x9922 para saber a que linea.
; ----------------------------------------------------------------------
L_40DE:
	ld bc,00400h		;40de   ; cuatro ranuras, y EXPTBL para saber cuales estan expandidas
	ld hl,0fcc1h		;40e1
L_40E4:
	push bc			;40e4
	push hl			;40e5
	ld a,(hl)			;40e6
	bit 7,a		;40e7   ; con el bit 7 puesto, la ranura esta expandida y hay que mirar sus cuatro subranuras
	jr nz,L_4108		;40e9
	ld b,c			;40eb
	call 0dab7h		;40ec   ; 0xDAB7 es 0x4195: ¿es esta mi propia ranura? Entonces se salta
	jr z,L_40F5		;40ef
	ld a,c			;40f1
	call 0da46h		;40f2   ; y si no, se mira si tiene un juego que valga
L_40F5:
	pop hl			;40f5
	pop bc			;40f6
	jr c,L_40FD		;40f7
	inc hl			;40f9   ; la ranura siguiente
	inc c			;40fa
	djnz L_40E4		;40fb
L_40FD:
	push af			;40fd   ; encontrado o no, hay que volver a meterse a uno mismo en la pagina 1
	ld a,(0d12eh)		;40fe
	ld h,040h		;4101
	call 00024h		;4103   ; BIOS ENASLT - Switches to specified slot and page definitively
	pop af			;4106
	ret			;4107
L_4108:
	call 0da2fh		;4108   ; 0xDA2F es 0x410D: la vuelta por las cuatro subranuras
	jr L_40F5		;410b
L_410D:
	and 080h		;410d   ; el bit 7 marca "expandida" y los bits 2 y 3, la subranura
	or c			;410f
	ld b,004h		;4110   ; las cuatro subranuras, de cuatro en cuatro
L_4112:
	push bc			;4112
	ld b,a			;4113
	call 0dab7h		;4114   ; 0xDAB7 es 0x4195: ¿es la mia?
	jr z,L_411D		;4117
	ld a,b			;4119
	call 0da46h		;411a
L_411D:
	pop bc			;411d
	ret c			;411e
	add a,004h		;411f   ; cuatro mas: la subranura siguiente
	djnz L_4112		;4121
	ret			;4123

; ----------------------------------------------------------------------
; RECONOCER EL CARTUCHO DE LA OTRA RANURA. Corre en 0xDA46. Cuatro pruebas en cadena, y basta con que pase una: que tenga cabecera de cartucho, que instale el gancho de interrupcion como lo instala Konami, que traiga la segunda cabecera de 0x4010, o que su suma de comprobacion este en la tabla.
; ----------------------------------------------------------------------
L_4124:
	push af			;4124
	ld h,040h		;4125
	call 00024h		;4127   ; BIOS ENASLT - Switches to specified slot and page definitively | se mete la ranura candidata en la pagina 1
	ld hl,(04000h)		;412a   ; ¿empieza por "AB"? Si no, ahi no hay cartucho
	ld de,04241h		;412d
	rst 20h			;4130
	jr nz,L_418C		;4131
	ld hl,(04002h)		;4133   ; su INIT, y 256 bytes por delante
	ld bc,00100h		;4136
L_4139:
	ld a,09bh		;4139   ; busca un 0x9B con cpir
	cpir		;413b
	jr nz,L_418C		;413d
	jp po,0daaeh		;413f
	ld a,0fdh		;4142   ; y comprueba que detras va un 0xFD: juntos son el operando del `ld (0xFD9B),hl` con el que un juego de Konami instala su gancho H.KEYI. De las 40 ROM de Konami que hay a mano, 40 lo llevan
	cp (hl)			;4144
	jr nz,L_4139		;4145
	ld hl,(INIT)		;4147   ; la SEGUNDA cabecera, la de 0x4010: "AB" son 19 bytes de punteros y "CD", 21
	ld de,04241h		;414a
	rst 20h			;414d
	jr z,L_418F		;414e
	ld de,04443h		;4150
	rst 20h			;4153
	jr z,L_418F		;4154
	ld de,00000h		;4156   ; y si tampoco, el ultimo recurso: sumar los 256 bytes de 0x5000 a 0x50FF
	ld hl,05000h		;4159
	ld b,000h		;415c
L_415E:
	ld a,(hl)			;415e   ; la suma es de 16 bits, con el acarreo a D
	add a,e			;415f
	ld e,a			;4160
	jr nc,L_4164		;4161
	inc d			;4163
L_4164:
	inc hl			;4164
	djnz L_415E		;4165
	push de			;4167
	ld a,(0d12eh)		;4168   ; antes de mirar la tabla hay que volver a ponerse uno mismo, que la tabla esta AQUI
	ld h,040h		;416b
	call 00024h		;416d   ; BIOS ENASLT - Switches to specified slot and page definitively
	pop de			;4170
	ld ix,05f3ah		;4171   ; la tabla de firmas, 62 entradas de cuatro bytes
L_4175:
	ld l,(ix+000h)		;4175
	ld h,(ix+001h)		;4178
	ld a,l			;417b
	or h			;417c
	jr z,L_418C		;417d
	rst 20h			;417f   ; DCOMPR: la suma contra la firma
	jr z,L_418F		;4180
	inc ix		;4182   ; y si no, cuatro bytes mas alla, a la siguiente
	inc ix		;4184
	inc ix		;4186
	inc ix		;4188
	jr L_4175		;418a
L_418C:
	pop af			;418c   ; ninguna prueba paso: no vale
	and a			;418d
	ret			;418e
L_418F:
	pop af			;418f
	ld (0d12fh),a		;4190   ; vale: se guarda la ranura y se sale con carry
	scf			;4193
	ret			;4194
L_4195:
	ld a,(0d12eh)		;4195
	cp b			;4198
	ret			;4199
L_419A:
	ld hl,L_41A8		;419a
	ld de,0c000h		;419d
	ld bc,00087h		;41a0
	ldir		;41a3
	jp 0c000h		;41a5

; ----------------------------------------------------------------------
; ESTO CORRE EN 0xC000, NO AQUI. Lo copia y lo llama 0x419A. Restale 0x7E58 para saber a que linea salta.
; ----------------------------------------------------------------------
L_41A8:
	ld bc,00400h		;41a8
	ld hl,0fcc1h		;41ab
L_41AE:
	push bc			;41ae
	push hl			;41af
	ld a,(hl)			;41b0   ; la entrada de EXPTBL de esta ranura
	bit 7,a		;41b1   ; con el bit 7 puesto, esta expandida
	jr nz,L_41D2		;41b3
	ld b,c			;41b5
	call 0c02fh		;41b6   ; 0xC02F es 0x41D7: ¿es la mia?
	jr z,L_41BF		;41b9
	ld a,c			;41bb
	call 0c04bh		;41bc   ; y si no, se mira si tiene juego
L_41BF:
	pop hl			;41bf
	pop bc			;41c0
	jr c,L_41C7		;41c1
	inc hl			;41c3   ; la ranura siguiente
	inc c			;41c4
	djnz L_41AE		;41c5
L_41C7:
	push af			;41c7
	ld a,(0d12eh)		;41c8
	ld h,040h		;41cb
	call 00024h		;41cd   ; BIOS ENASLT - Switches to specified slot and page definitively
	pop af			;41d0
	ret			;41d1
L_41D2:
	call 0c034h		;41d2
	jr L_41BF		;41d5
L_41D7:
	ld a,(0d12eh)		;41d7
	cp b			;41da
	ret			;41db
L_41DC:
	and 080h		;41dc
	or c			;41de
	ld b,004h		;41df
L_41E1:
	push bc			;41e1
	ld b,a			;41e2
	call 0c02fh		;41e3   ; 0xC02F es 0x4187: ¿es la mia?
	jr z,L_41EC		;41e6
	ld a,b			;41e8
	call 0c04bh		;41e9   ; y si no, se mira si tiene juego
L_41EC:
	pop bc			;41ec
	ret c			;41ed
	add a,004h		;41ee
	djnz L_41E1		;41f0
	ret			;41f2
L_41F3:
	push af			;41f3
	ld h,040h		;41f4
	call 00024h		;41f6   ; BIOS ENASLT - Switches to specified slot and page definitively
	ld hl,04000h		;41f9
	ld de,0c07eh		;41fc
	ld bc,04000h		;41ff
L_4202:
	ld a,044h		;4202   ; busca una "D" con cpir
	cpir		;4204
	jr nz,L_4223		;4206
	jp po,0c07bh		;4208
	push bc			;420b
	push de			;420c
	push hl			;420d
	ld b,009h		;420e   ; y detras tienen que ir las nueve letras de "isk BASIC"
L_4210:
	ld a,(de)			;4210
	cp (hl)			;4211   ; se comparan una a una
	jr nz,L_4218		;4212
	inc hl			;4214
	inc de			;4215
	djnz L_4210		;4216
L_4218:
	pop hl			;4218
	pop de			;4219
	pop bc			;421a
	jr nz,L_4202		;421b   ; si falla, se sigue buscando otra "D"
	pop af			;421d
	ld (0d33bh),a		;421e   ; encontrada: se apunta y se sale con carry
	scf			;4221
	ret			;4222
L_4223:
	pop af			;4223
	and a			;4224
	ret			;4225

; ----------------------------------------------------------------------
; DATOS texto_isk_basic: "isk BASIC", las nueve letras con las que el cartucho
;   reconoce la ROM de disco. NO se lee desde aqui: este trozo esta dentro del
;   bloque que 0x419A copia a 0xC000, asi que quien la carga es el `ld
;   de,0C07Eh` de 0x41FC. La "D" no esta porque la comparacion arranca en la
;   segunda letra
;   0x4226..0x422f  (9 bytes)
DATA_texto_isk_basic:
	defb 069h,073h,06bh,020h,042h,041h,053h,049h,043h	; 4226  isk BASIC

; ======================================================================
; CODIGO 0x422f..0x4292  (99 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ARRANCAR EL JUEGO. Antes de irse deja puesto el camino de vuelta: 0xC800 y el gancho.
; ----------------------------------------------------------------------
L_422F:
	ld a,001h		;422f
	ld (0f3ebh),a		;4231
	call 00062h		;4234   ; BIOS CHGCLR - Changes the screen colors
	ld a,(0d33bh)		;4237
	ld c,a			;423a
	ld hl,04002h		;423b   ; lee el INIT del vecino, que es a donde hay que saltar
	call L_40C0		;423e
	ld iy,(0d33ah)		;4241   ; IY = ranura e IX = direccion, que es lo que pide CALSLT
	push de			;4245
	pop ix		;4246
	ld hl,L_4264		;4248   ; planta en 0xC800 el trozo que sabe volver
	ld de,0c800h		;424b
	ld bc,0000bh		;424e
	ldir		;4251
	ld hl,L_426F		;4253   ; y en el gancho de la BIOS, un salto a el
	ld de,0fedah		;4256
	ld bc,00003h		;4259
	ldir		;425c
	call 0001ch		;425e   ; BIOS CALSLT - Executes inter-slot call | y arranca el juego en su ranura
	jp 0fecbh		;4261

; ----------------------------------------------------------------------
; ESTO CORRE EN 0xC800, NO AQUI. Once bytes: vuelve a meter este cartucho en la pagina 1 con ENASLT y salta a 0x403D. Es el camino de vuelta desde el juego.
; ----------------------------------------------------------------------
L_4264:
	ld a,(0d12eh)		;4264
	ld h,040h		;4267
	call 00024h		;4269   ; BIOS ENASLT - Switches to specified slot and page definitively
	jp L_403D		;426c

; ----------------------------------------------------------------------
; ESTO CORRE EN 0xFEDA, NO AQUI. Tres bytes: un `jp 0xC800` plantado en un gancho de la BIOS.
; ----------------------------------------------------------------------
L_426F:
	jp 0c800h		;426f
L_4272:
	call L_42A4		;4272
L_4275:
	call salva_la_pantalla		;4275
L_4278:
	call L_44F0		;4278   ; pinta el menu
	ld hl,04575h		;427b   ; y sus seis sitios
	ld b,006h		;427e
	call L_6581		;4280
	ld b,a			;4283
	ld hl,0429eh		;4284   ; la opcion elegida da el codigo de operacion
	call L_626E		;4287
	ld a,(hl)			;428a
	ld (0d136h),a		;428b   ; que se guarda en 0xD136, la variable que manda en todo lo que viene detras
	ld a,b			;428e

; ----------------------------------------------------------------------
; EL MENU PRINCIPAL. Seis opciones: DISK SAVE, DISK LOAD, TAPE SAVE, TAPE LOAD, RANKING MODE y END. La sexta es END y no PRINTER: lo dicen los rotulos de 0x4525, que es lo que se pinta, y el 0x00 con el que 0x429E la marca. "PRINTER" solo existe como encabezado, en los rotulos de 0x4636.
; ----------------------------------------------------------------------
	call L_6368		;428f   ; y se salta a la rutina de esa opcion, con la tabla pegada detras

; ----------------------------------------------------------------------
; DATOS menu_principal_rutinas: Seis punteros, la tabla del despacho de
;   0x428F: 0x42B1 DISK SAVE, 0x4356 DISK LOAD, 0x43D4 TAPE SAVE, 0x442C TAPE
;   LOAD, 0x447F RANKING MODE y 0x44D8 END. Seis porque seis dice el ld b de
;   0x427E
;   0x4292..0x429e  (12 bytes)
DATA_menu_principal_rutinas:
	defb 0b1h,042h	; 4292
	defb 056h,043h	; 4294
	defb 0d4h,043h	; 4296
	defb 02ch,044h	; 4298
	defb 07fh,044h	; 429a
	defb 0d8h,044h	; 429c

; ----------------------------------------------------------------------
; DATOS menu_principal_codigos: Un byte por opcion -0x10, 0x20, 0x30, 0x40,
;   0x60 y 0x00- que 0x4284 mete en (0xD136). Ese byte es el que manda el
;   resto de la operacion: el nibble ALTO dice de que va -1 guardar en disco,
;   2 cargar de disco, 3 guardar en cinta, 4 cargar de cinta, 6 ranking- y el
;   BAJO, sobre que dato. Por eso los submenus hacen `add a,010h` (0x42CB) o
;   `add a,030h` (0x43E3) en vez de una tabla
;   0x429e..0x42a4  (6 bytes)
DATA_menu_principal_codigos:
	defb 010h,020h,030h,040h,060h,000h	; 429e

; ======================================================================
; CODIGO 0x42a4..0x42d4  (48 bytes)
; ======================================================================


L_42A4:
	ld hl,03a21h		;42a4
	ld (0d16ch),hl		;42a7
	ld hl,03a2ch		;42aa
	ld (0d16eh),hl		;42ad
	ret			;42b0

; ----------------------------------------------------------------------
; GUARDAR EN DISCO. Las cinco lineas hacen lo mismo con distinto dato, y las tres primeras siguen el mismo guion: comprobar que ese dato existe, pedir el nombre del fichero y escribirlo.
; ----------------------------------------------------------------------
L_42B1:
	call L_68FE		;42b1   ; espera a que haya unidad de disco
	jr z,$-60		;42b4
	ld hl,06addh		;42b6   ; monta la llamada entre ranuras que hace falta para leerle al juego
	call L_6AAA		;42b9
	call L_4586		;42bc
	call L_4616		;42bf
	ld hl,045d8h		;42c2
	ld b,005h		;42c5
	call L_6581		;42c7
	ld b,a			;42ca
	add a,010h		;42cb
	ld (0d136h),a		;42cd
	ld a,b			;42d0
	call L_6368		;42d1

; ----------------------------------------------------------------------
; DATOS guardar_en_disco_rutinas: Cinco punteros, la tabla del despacho de
;   0x42D1: las cinco lineas del menu de 0x459E (HI SCORE, SCREEN DATA, GAME
;   DATA, RANKING DATA y END). La segunda y la tercera son la misma, 0x42DE
;   0x42d4..0x42de  (10 bytes)
DATA_guardar_en_disco_rutinas:
	defb 0edh,042h	; 42d4
	defb 0deh,042h	; 42d6
	defb 0deh,042h	; 42d8
	defb 004h,043h	; 42da
	defb 078h,042h	; 42dc

; ======================================================================
; CODIGO 0x42de..0x4335  (87 bytes)
; ======================================================================


L_42DE:
	call L_431A		;42de   ; pide el nombre del fichero
	jp z,L_42B1		;42e1   ; sin nombre, se vuelve al menu
	call L_63E9		;42e4
	call L_660C		;42e7   ; y a escribir la pantalla
	jp L_4275		;42ea
L_42ED:
	ld hl,(0d30ch)		;42ed   ; este dato solo existe si el juego trae puntero en (0xD30C)
	ld a,h			;42f0
	or l			;42f1
	jp z,L_42B1		;42f2
	call L_431A		;42f5
	jp z,L_42B1		;42f8
	call L_63E9		;42fb
	call L_6692		;42fe   ; escribe los datos del juego
	jp L_4275		;4301
L_4304:
	ld a,(0d332h)		;4304   ; y el ranking, solo si hay (0xD332)
	or a			;4307
	jp z,L_42B1		;4308
	call L_431A		;430b
	jp z,L_42B1		;430e
	call L_63E9		;4311
	call L_6679		;4314
	jp L_4275		;4317
L_431A:
	call L_466E		;431a   ; pinta el encabezado y pide el nombre
	call L_4326		;431d
	ld hl,03a6ch		;4320
	jp monta_el_nombre		;4323
L_4326:
	ld hl,04335h		;4326   ; "INPUT FILE NAME" al guardar
	jr L_432E		;4329
L_432B:
	ld hl,04345h		;432b   ; y "SELECT FILE NAME" al cargar, que es la otra puerta
L_432E:
	ld de,(0d16eh)		;432e
	jp L_6290		;4332

; ----------------------------------------------------------------------
; DATOS texto_input_file_name: "INPUT FILE NAME". Lo pinta 0x4326
;   0x4335..0x4345  (16 bytes)
DATA_texto_input_file_name:
	defb 049h,04eh,050h,055h,054h,000h,046h,049h,04ch,045h,000h,04eh,041h,04dh,045h,0ffh	; 4335  INPUT.FILE.NAME.

; ----------------------------------------------------------------------
; DATOS texto_select_file_name: "SELECT FILE NAME". Lo pinta 0x432B, por la
;   otra puerta de la misma rutina
;   0x4345..0x4356  (17 bytes)
DATA_texto_select_file_name:
	defb 053h,045h,04ch,045h,043h,054h,000h,046h,049h,04ch,045h,000h,04eh,041h,04dh,045h,0ffh	; 4345  SELECT.FILE.NAME.

; ======================================================================
; CODIGO 0x4356..0x4379  (35 bytes)
; ======================================================================


L_4356:
	call L_68FE		;4356   ; CARGAR DE DISCO: lo primero, mirar si hay unidad
	jp z,L_4278		;4359   ; sin disco no hay nada que hacer
	call L_4592		;435c
	call L_4616		;435f
	ld hl,0460eh		;4362
	ld b,004h		;4365
	call L_6581		;4367
	ld b,a			;436a
	ld hl,04381h		;436b
	call L_626E		;436e
	ld a,(hl)			;4371
	ld (0d136h),a		;4372
	ld a,b			;4375
	call L_6368		;4376

; ----------------------------------------------------------------------
; DATOS cargar_de_disco_rutinas: Cuatro punteros, la tabla del despacho de
;   0x4376
;   0x4379..0x4381  (8 bytes)
DATA_cargar_de_disco_rutinas:
	defb 093h,043h	; 4379
	defb 085h,043h	; 437b
	defb 0a9h,043h	; 437d
	defb 078h,042h	; 437f

; ----------------------------------------------------------------------
; DATOS cargar_de_disco_codigos: 0x20, 0x22, 0x23 y 0x00: el codigo que 0x436B
;   mete en (0xD136) por cada linea del menu de 0x45E2. El nibble alto 2 es
;   "cargar de disco" y el bajo dice el dato; el 0x00 de END no es un dato, es
;   salir
;   0x4381..0x4385  (4 bytes)
DATA_cargar_de_disco_codigos:
	defb 020h,022h,023h,000h	; 4381

; ======================================================================
; CODIGO 0x4385..0x43ec  (103 bytes)
; ======================================================================


L_4385:
	call L_43BE		;4385
	jr c,$-50		;4388
	call L_63E9		;438a
	call L_66A8		;438d
	jp L_4275		;4390
L_4393:
	ld hl,(0d30ch)		;4393   ; solo si el juego trae puntero en (0xD30C)
	ld a,h			;4396
	or l			;4397
	jp z,L_4356		;4398
	call L_43BE		;439b
	jr c,$-72		;439e   ; si el fichero no aparece, se vuelve a preguntar
	call L_63E9		;43a0
	call L_6712		;43a3   ; y se carga
	jp L_4275		;43a6
L_43A9:
	ld a,(0d332h)		;43a9   ; solo si hay ranking
	or a			;43ac
	jp z,L_4356		;43ad
	call L_43BE		;43b0
	jr c,$-93		;43b3
	call L_63E9		;43b5
	call L_66FC		;43b8
	jp L_4275		;43bb
L_43BE:
	ld hl,06af6h		;43be   ; antes de leer hay que dejar puesta la llamada entre ranuras
	call L_6AAA		;43c1
	call L_466E		;43c4
	call L_46B2		;43c7   ; pinta el nombre del dato
	call L_6BCC		;43ca   ; y busca el fichero en el disco
	ret c			;43cd   ; si no esta, se vuelve con carry
	ld hl,06addh		;43ce
	jp L_6AAA		;43d1
L_43D4:
	call L_4586		;43d4   ; GUARDAR EN CINTA: el mismo menu de cinco que el disco
	call L_4616		;43d7
	ld hl,045d8h		;43da
	ld b,005h		;43dd
	call L_6581		;43df
	ld b,a			;43e2
	add a,030h		;43e3   ; con el codigo de operacion a 3, que es "guardar en cinta"
	ld (0d136h),a		;43e5
	ld a,b			;43e8
	call L_6368		;43e9

; ----------------------------------------------------------------------
; DATOS guardar_en_cinta_rutinas: Cinco punteros, la tabla del despacho de
;   0x43E9
;   0x43ec..0x43f6  (10 bytes)
DATA_guardar_en_cinta_rutinas:
	defb 008h,044h	; 43ec
	defb 0ffh,043h	; 43ee
	defb 0f6h,043h	; 43f0
	defb 01ch,044h	; 43f2
	defb 078h,042h	; 43f4

; ======================================================================
; CODIGO 0x43f6..0x4449  (83 bytes)
; ======================================================================


L_43F6:
	call L_466E		;43f6
	call L_6E76		;43f9
	jp L_4275		;43fc
L_43FF:
	call L_466E		;43ff
	call L_6E95		;4402
	jp L_4275		;4405
L_4408:
	ld hl,(0d30ch)		;4408   ; el dato del juego, si lo trae
	ld a,h			;440b
	or l			;440c
	jp z,L_43D4		;440d
	call L_466E		;4410
	call L_6EC0		;4413
	call L_63E9		;4416
	jp L_4275		;4419
L_441C:
	ld a,(0d332h)		;441c   ; y el ranking, si lo hay
	or a			;441f
	jp z,L_43D4		;4420
	call L_466E		;4423
	call L_6EA9		;4426
	jp L_4275		;4429
L_442C:
	call L_4592		;442c   ; CARGAR DE CINTA: el menu de cuatro
	call L_4616		;442f
	ld hl,0460eh		;4432
	ld b,004h		;4435
	call L_6581		;4437
	ld b,a			;443a
	ld hl,04451h		;443b
	call L_626E		;443e
	ld a,(hl)			;4441
	ld (0d136h),a		;4442   ; con el codigo 4 en el nibble alto
	ld a,b			;4445
	call L_6368		;4446

; ----------------------------------------------------------------------
; DATOS cargar_de_cinta_rutinas: Cuatro punteros, la tabla del despacho de
;   0x4446
;   0x4449..0x4451  (8 bytes)
DATA_cargar_de_cinta_rutinas:
	defb 05eh,044h	; 4449
	defb 055h,044h	; 444b
	defb 06fh,044h	; 444d
	defb 078h,042h	; 444f

; ----------------------------------------------------------------------
; DATOS cargar_de_cinta_codigos: 0x40, 0x42, 0x43 y 0x00, los mismos datos que
;   en disco con el nibble alto a 4
;   0x4451..0x4455  (4 bytes)
DATA_cargar_de_cinta_codigos:
	defb 040h,042h,043h,000h	; 4451

; ======================================================================
; CODIGO 0x4455..0x4497  (66 bytes)
; ======================================================================


L_4455:
	call L_466E		;4455
	call L_6ED4		;4458
	jp L_4275		;445b
L_445E:
	ld hl,(0d30ch)		;445e   ; los datos del juego, si los trae
	ld a,h			;4461
	or l			;4462
	jp z,L_442C		;4463
	call L_466E		;4466
	call L_6F25		;4469
	jp L_4275		;446c
L_446F:
	ld a,(0d332h)		;446f   ; y el ranking, si lo hay
	or a			;4472
	jp z,L_442C		;4473
	call L_466E		;4476
	call L_6F11		;4479
	jp L_4275		;447c
L_447F:
	ld a,(0d332h)		;447f   ; RANKING MODE: sin ranking no hay nada que ver
	or a			;4482
	jp z,L_4278		;4483
	call L_46C8		;4486
	call L_4616		;4489
	ld hl,04704h		;448c   ; las cuatro lineas de su menu
	ld b,004h		;448f
	call L_6581		;4491
	call L_6368		;4494

; ----------------------------------------------------------------------
; DATOS ranking_opciones_rutinas: Cuatro punteros, la tabla del despacho de
;   0x4494: las cuatro lineas del menu de 0x46D4 (DISPLAY DATA, CHANGE NAME,
;   PRINT DATA y END)
;   0x4497..0x449f  (8 bytes)
DATA_ranking_opciones_rutinas:
	defb 0aeh,044h	; 4497
	defb 09fh,044h	; 4499
	defb 0b7h,044h	; 449b
	defb 078h,042h	; 449d

; ======================================================================
; CODIGO 0x449f..0x44c6  (39 bytes)
; ======================================================================


L_449F:
	call L_644F		;449f
	call L_44F9		;44a2
	call L_4616		;44a5
	call L_5592		;44a8
	jp L_4278		;44ab
L_44AE:
	call L_56F5		;44ae
	call L_57E8		;44b1
	jp L_4278		;44b4
L_44B7:
	call L_56F5		;44b7
	call L_63E9		;44ba
	call L_5968		;44bd
	call salva_la_pantalla		;44c0
	jp L_4278		;44c3

; ----------------------------------------------------------------------
; DATOS texto_print_ranking: "@@PRINT RANKING@@", con el hueco resaltado a los
;   dos lados
;   0x44c6..0x44d8  (18 bytes)
DATA_texto_print_ranking:
	defb 040h,040h,050h,052h,049h,04eh,054h,000h,052h,041h,04eh,04bh,049h,04eh,047h,040h,040h,0ffh	; 44c6  @@PRINT.RANKING@@.

; ======================================================================
; CODIGO 0x44d8..0x4525  (77 bytes)
; ======================================================================


L_44D8:
	call L_63E9		;44d8
	xor a			;44db
	ld (0d135h),a		;44dc
	ld (0d136h),a		;44df
	ld a,006h		;44e2
	call 00141h		;44e4   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	and 003h		;44e7
	ret nz			;44e9
	ld (0d13ch),a		;44ea
	jp L_4FF2		;44ed
L_44F0:
	call L_644F		;44f0
	ld hl,04525h		;44f3
	call pinta_rotulos		;44f6
L_44F9:
	ld hl,(0d16ch)		;44f9
	ld bc,000a0h		;44fc
	add hl,bc			;44ff
	ex de,hl			;4500

; ----------------------------------------------------------------------
; EL "RC 7xx" DEL JUEGO RECONOCIDO. Sale en todas las pantallas del cartucho para que se vea cual se ha detectado.
; ----------------------------------------------------------------------
L_4501:
	ld a,(0d301h)		;4501
	inc a			;4504
	ret z			;4505   ; sin juego reconocido no se pinta nada
	ld hl,04581h		;4506   ; el "RC 7" fijo
	push de			;4509
	call L_6290		;450a
	ld a,(0d301h)		;450d
	ld hl,0da00h		;4510
	call bcd_a_dos_letras		;4513   ; y detras, el numero en decimal
	pop hl			;4516
	ld bc,00004h		;4517
	add hl,bc			;451a
	ld de,0da00h		;451b
	ex de,hl			;451e
	ld bc,00002h		;451f   ; que son sus dos cifras
	jp 0005ch		;4522   ; BIOS LDIRVM - Block transfers to VRAM from memory

; ----------------------------------------------------------------------
; DATOS rotulos_menu_principal: MENU / DISK SAVE / DISK LOAD / TAPE SAVE /
;   TAPE LOAD / RANKING MODE / END. Lo pinta el ld hl de 0x44F3
;   0x4525..0x4575  (80 bytes)
DATA_rotulos_menu_principal:
	defb 021h,03ah,040h,040h,04dh,045h,04eh,055h,040h,040h,0feh,02ch,03ah,044h,049h,053h	; 4525  !:@@MENU@@.,:DIS
	defb 04bh,000h,053h,041h,056h,045h,0feh,04ch,03ah,044h,049h,053h,04bh,000h,04ch,04fh	; 4535  K.SAVE.L:DISK.LO
	defb 041h,044h,0feh,06ch,03ah,054h,041h,050h,045h,000h,053h,041h,056h,045h,0feh,08ch	; 4545  AD.l:TAPE.SAVE..
	defb 03ah,054h,041h,050h,045h,000h,04ch,04fh,041h,044h,0feh,0ach,03ah,052h,041h,04eh	; 4555  :TAPE.LOAD..:RAN
	defb 04bh,049h,04eh,047h,000h,04dh,04fh,044h,045h,0feh,0cch,03ah,045h,04eh,044h,0ffh	; 4565  KING.MODE..:END.

; ----------------------------------------------------------------------
; DATOS sitios_menu_principal: Las SEIS filas del menu de 0x4525, en
;   direcciones de la tabla de nombres: 0x3A2B, 0x3A4B, 0x3A6B, 0x3A8B, 0x3AAB
;   y 0x3ACB. Van de 0x20 en 0x20, o sea una fila de pantalla cada una
;   0x4575..0x4581  (12 bytes)
DATA_sitios_menu_principal:
	defb 02bh,03ah	; 4575
	defb 04bh,03ah	; 4577
	defb 06bh,03ah	; 4579
	defb 08bh,03ah	; 457b
	defb 0abh,03ah	; 457d
	defb 0cbh,03ah	; 457f

; ----------------------------------------------------------------------
; DATOS rotulo_rc: "RC 7" y el 0xFF de cierre, con el 0x40 que aqui hace de
;   espacio. 0x4506 lo pinta con 0x6290 -la puerta del pintor de rotulos a la
;   que la direccion de VRAM le llega en DE- y a continuacion 0x450D suelta
;   detras el numero de (0xD301): junto salen el "RC 7xx" del juego que se ha
;   reconocido en la otra ranura
;   0x4581..0x4586  (5 bytes)
DATA_rotulo_rc:
	defb 052h,043h,040h,037h,0ffh	; 4581

; ======================================================================
; CODIGO 0x4586..0x459e  (24 bytes)
; ======================================================================


L_4586:
	call L_644F		;4586
	ld hl,0459eh		;4589
	call pinta_rotulos		;458c
	jp L_44F9		;458f
L_4592:
	call L_644F		;4592
	ld hl,045e2h		;4595
	call pinta_rotulos		;4598
	jp L_44F9		;459b

; ----------------------------------------------------------------------
; DATOS rotulos_guardar_en_disco: HI SCORE / SCREEN DATA / GAME DATA / RANKING
;   DATA / END. Lo pinta el ld hl de 0x4589
;   0x459e..0x45d8  (58 bytes)
DATA_rotulos_guardar_en_disco:
	defb 02ch,03ah,048h,049h,000h,053h,043h,04fh,052h,045h,0feh,04ch,03ah,053h,043h,052h	; 459e  ,:HI.SCORE.L:SCR
	defb 045h,045h,04eh,000h,044h,041h,054h,041h,0feh,06ch,03ah,047h,041h,04dh,045h,000h	; 45ae  EEN.DATA.l:GAME.
	defb 044h,041h,054h,041h,0feh,08ch,03ah,052h,041h,04eh,04bh,049h,04eh,047h,000h,044h	; 45be  DATA..:RANKING.D
	defb 041h,054h,041h,0feh,0cch,03ah,045h,04eh,044h,0ffh	; 45ce  ATA..:END.

; ----------------------------------------------------------------------
; DATOS sitios_menu_guardar: Las CINCO filas del menu de 0x459E. Lo comparten
;   guardar en disco (0x42C7) y guardar en cinta (0x43DF): el menu se pinta
;   igual y lo que cambia es el codigo que cada uno suma
;   0x45d8..0x45e2  (10 bytes)
DATA_sitios_menu_guardar:
	defb 02bh,03ah	; 45d8
	defb 04bh,03ah	; 45da
	defb 06bh,03ah	; 45dc
	defb 08bh,03ah	; 45de
	defb 0cbh,03ah	; 45e0

; ----------------------------------------------------------------------
; DATOS rotulos_guardar_en_cinta: HI SCORE / GAME DATA / RANKING DATA / END.
;   Sin SCREEN DATA: en cinta no cabe. Lo pinta el ld hl de 0x4595
;   0x45e2..0x460e  (44 bytes)
DATA_rotulos_guardar_en_cinta:
	defb 02ch,03ah,048h,049h,000h,053h,043h,04fh,052h,045h,0feh,04ch,03ah,047h,041h,04dh	; 45e2  ,:HI.SCORE.L:GAM
	defb 045h,000h,044h,041h,054h,041h,0feh,06ch,03ah,052h,041h,04eh,04bh,049h,04eh,047h	; 45f2  E.DATA.l:RANKING
	defb 000h,044h,041h,054h,041h,0feh,0ach,03ah,045h,04eh,044h,0ffh	; 4602  .DATA..:END.

; ----------------------------------------------------------------------
; DATOS sitios_menu_cargar: Las CUATRO filas del menu de 0x45E2. Lo comparten
;   cargar de disco (0x4367) y cargar de cinta (0x4437)
;   0x460e..0x4616  (8 bytes)
DATA_sitios_menu_cargar:
	defb 02bh,03ah	; 460e
	defb 04bh,03ah	; 4610
	defb 06bh,03ah	; 4612
	defb 0abh,03ah	; 4614

; ======================================================================
; CODIGO 0x4616..0x4628  (18 bytes)
; ======================================================================


L_4616:
	ld hl,04628h		;4616   ; la tabla de rotulos de operacion
	ld a,(0d136h)		;4619
	and 0f0h		;461c   ; el nibble ALTO de (0xD136) dice de que va la operacion
	rrca			;461e
	rrca			;461f
	rrca			;4620
	rrca			;4621
	dec a			;4622   ; menos uno, porque la tabla empieza en el 1
	ld bc,00000h		;4623
	jr $+86		;4626

; ----------------------------------------------------------------------
; DATOS punteros_de_la_operacion: Siete punteros a los rotulos de aqui abajo.
;   0x4616 los indexa con el nibble ALTO de (0xD136) menos uno, que es de
;   donde sale lo que se esta haciendo. La quinta entrada es 0x0000: ese
;   indice no se usa
;   0x4628..0x4636  (14 bytes)
DATA_punteros_de_la_operacion:
	defb 036h,046h	; 4628
	defb 040h,046h	; 462a
	defb 04ah,046h	; 462c
	defb 054h,046h	; 462e
	defb 000h,000h	; 4630
	defb 05eh,046h	; 4632
	defb 066h,046h	; 4634

; ----------------------------------------------------------------------
; DATOS rotulos_de_la_operacion: Los seis nombres de operacion que van de
;   encabezado: DISK SAVE, DISK LOAD, TAPE SAVE, TAPE LOAD, RANKING y PRINTER.
;   Este es el unico sitio del cartucho donde sale "PRINTER": en el menu
;   principal la sexta linea es END
;   0x4636..0x466e  (56 bytes)
DATA_rotulos_de_la_operacion:
	defb 044h,049h,053h,04bh,040h,053h,041h,056h,045h,0ffh	; 4636  DISK@SAVE.
	defb 044h,049h,053h,04bh,040h,04ch,04fh,041h,044h,0ffh	; 4640  DISK@LOAD.
	defb 054h,041h,050h,045h,040h,053h,041h,056h,045h,0ffh	; 464a  TAPE@SAVE.
	defb 054h,041h,050h,045h,040h,04ch,04fh,041h,044h,0ffh	; 4654  TAPE@LOAD.
	defb 052h,041h,04eh,04bh,049h,04eh,047h,0ffh,050h,052h	; 465e  RANKING.PR
	defb 049h,04eh,054h,045h,052h,0ffh	; 4668

; ======================================================================
; CODIGO 0x466e..0x468d  (31 bytes)
; ======================================================================


L_466E:
	call L_635E		;466e
	ld a,(0d136h)		;4671
	and 00fh		;4674
	ld hl,0468dh		;4676
	ld bc,00040h		;4679

; ----------------------------------------------------------------------
; UN ROTULO DE UNA LISTA, EN SU SITIO. Suma el desplazamiento a la esquina que hay en (0xD16C) y saca de la tabla el rotulo numero A.
; ----------------------------------------------------------------------
L_467C:
	ex de,hl			;467c
	ld hl,(0d16ch)		;467d   ; la esquina de la pantalla
	add hl,bc			;4680
	ex de,hl			;4681
	add a,a			;4682   ; por dos: son punteros
	call L_626E		;4683
	ld a,(hl)			;4686
	inc hl			;4687
	ld h,(hl)			;4688
	ld l,a			;4689
	jp L_6290		;468a   ; y a pintarlo

; ----------------------------------------------------------------------
; DATOS punteros_del_dato: Cuatro punteros, que 0x4676 indexa con el nibble
;   BAJO de (0xD136): el dato sobre el que va la operacion
;   0x468d..0x4695  (8 bytes)
DATA_punteros_del_dato:
	defb 0a1h,046h	; 468d
	defb 09ah,046h	; 468f
	defb 095h,046h	; 4691
	defb 0aah,046h	; 4693

; ----------------------------------------------------------------------
; DATOS rotulos_del_dato: GAME, SCREEN, HI SCORE y RANKING. Con el de arriba
;   se compone el encabezado entero, "DISK SAVE" + "GAME", que es como el
;   cartucho dice en una linea que va a guardar la partida en disco
;   0x4695..0x46b2  (29 bytes)
DATA_rotulos_del_dato:
	defb 047h,041h,04dh,045h,0ffh,053h,043h,052h	; 4695  GAME.SCR
	defb 045h,045h,04eh,0ffh,048h,049h,000h,053h	; 469d  EEN.HI.S
	defb 043h,04fh,052h,045h,0ffh,052h,041h,04eh	; 46a5  CORE.RAN
	defb 04bh,049h,04eh,047h,0ffh	; 46ad

; ======================================================================
; CODIGO 0x46b2..0x46bc  (10 bytes)
; ======================================================================


L_46B2:
	ld de,(0d16eh)		;46b2
	ld hl,046bch		;46b6
	jp L_6290		;46b9

; ----------------------------------------------------------------------
; DATOS texto_search_file: "SEARCH FILE". Lo pinta 0x46B6
;   0x46bc..0x46c8  (12 bytes)
DATA_texto_search_file:
	defb 053h,045h,041h,052h,043h,048h,000h,046h,049h,04ch,045h,0ffh	; 46bc  SEARCH.FILE.

; ======================================================================
; CODIGO 0x46c8..0x46d4  (12 bytes)
; ======================================================================


L_46C8:
	call L_644F		;46c8
	ld hl,046d4h		;46cb
	call pinta_rotulos		;46ce
	jp L_44F9		;46d1

; ----------------------------------------------------------------------
; DATOS rotulos_ranking_opciones: DISPLAY DATA / CHANGE NAME / PRINT DATA /
;   END. Lo pinta el ld hl de 0x46CB
;   0x46d4..0x4704  (48 bytes)
DATA_rotulos_ranking_opciones:
	defb 02ch,03ah,044h,049h,053h,050h,04ch,041h,059h,000h,044h,041h,054h,041h,0feh,04ch	; 46d4  ,:DISPLAY.DATA.L
	defb 03ah,043h,048h,041h,04eh,047h,045h,000h,04eh,041h,04dh,045h,0feh,06ch,03ah,050h	; 46e4  :CHANGE.NAME.l:P
	defb 052h,049h,04eh,054h,000h,044h,041h,054h,041h,0feh,0cch,03ah,045h,04eh,044h,0ffh	; 46f4  RINT.DATA..:END.

; ----------------------------------------------------------------------
; DATOS sitios_menu_ranking: Las CUATRO filas del menu de 0x46D4
;   0x4704..0x470c  (8 bytes)
DATA_sitios_menu_ranking:
	defb 02bh,03ah	; 4704
	defb 04bh,03ah	; 4706
	defb 06bh,03ah	; 4708
	defb 0cbh,03ah	; 470a

; ======================================================================
; CODIGO 0x470c..0x472f  (35 bytes)
; ======================================================================


L_470C:
	ld hl,0d301h		;470c
	ld a,(hl)			;470f
	ld (hl),0ffh		;4710
	ld (0d141h),a		;4712
L_4715:
	call L_4755		;4715   ; SELF MODE, el menu de comprobaciones
	call L_503C		;4718
	call L_4C1F		;471b
	ld hl,0489ah		;471e   ; sus rotulos
	call pinta_rotulos		;4721
	ld hl,048ddh		;4724
	ld b,003h		;4727   ; tres lineas
	call L_6581		;4729
	call L_6368		;472c

; ----------------------------------------------------------------------
; DATOS menu_self_rutinas: Tres punteros, la tabla del despacho de 0x472C
;   0x472f..0x4735  (6 bytes)
DATA_menu_self_rutinas:
	defb 049h,047h	; 472f
	defb 062h,047h	; 4731
	defb 035h,047h	; 4733

; ======================================================================
; CODIGO 0x4735..0x4776  (65 bytes)
; ======================================================================


L_4735:
	ld hl,0d317h		;4735
	ld a,(hl)			;4738
	or a			;4739
	jr nz,L_473F		;473a
	ld (0d129h),a		;473c
L_473F:
	ld hl,0d301h		;473f
	ld a,(0d141h)		;4742
	ld (hl),a			;4745
	jp L_4F43		;4746
L_4749:
	call L_4BC8		;4749
	call L_4820		;474c
L_474F:
	call L_62AB		;474f
	jp L_4715		;4752
L_4755:
	ld hl,03921h		;4755
	ld (0d16ch),hl		;4758
	ld hl,0392ch		;475b
	ld (0d16eh),hl		;475e
	ret			;4761
L_4762:
	call L_4C1F		;4762   ; LOAD SCREEN: sus tres lineas
	ld hl,0477ch		;4765
	call pinta_rotulos		;4768
	ld hl,047b6h		;476b
	ld b,003h		;476e
	call L_6581		;4770
	call L_6368		;4773

; ----------------------------------------------------------------------
; DATOS cargar_pantalla_rutinas: Tres punteros, la tabla del despacho de
;   0x4773
;   0x4776..0x477c  (6 bytes)
DATA_cargar_pantalla_rutinas:
	defb 0bch,047h	; 4776
	defb 0fdh,047h	; 4778
	defb 015h,047h	; 477a

; ----------------------------------------------------------------------
; DATOS rotulos_cargar_pantalla: LOAD SCREEN / LOAD DISK DATA / LOAD TAPE DATA
;   / END. Lo pinta el ld hl de 0x4765
;   0x477c..0x47b6  (58 bytes)
DATA_rotulos_cargar_pantalla:
	defb 0c6h,038h,040h,040h,04ch,04fh,041h,044h,000h,053h,043h,052h,045h,045h,04eh,040h	; 477c  .8@@LOAD.SCREEN@
	defb 040h,0feh,027h,039h,04ch,04fh,041h,044h,000h,044h,049h,053h,04bh,000h,044h,041h	; 478c  @.'9LOAD.DISK.DA
	defb 054h,041h,0feh,067h,039h,04ch,04fh,041h,044h,000h,054h,041h,050h,045h,000h,044h	; 479c  TA.g9LOAD.TAPE.D
	defb 041h,054h,041h,0feh,0a7h,039h,045h,04eh,044h,0ffh	; 47ac  ATA..9END.

; ----------------------------------------------------------------------
; DATOS sitios_menu_cargar_pantalla: Las TRES filas del menu de 0x477C
;   0x47b6..0x47bc  (6 bytes)
DATA_sitios_menu_cargar_pantalla:
	defb 026h,039h	; 47b6
	defb 066h,039h	; 47b8
	defb 0a6h,039h	; 47ba

; ======================================================================
; CODIGO 0x47bc..0x4834  (120 bytes)
; ======================================================================


L_47BC:
	call L_68FE		;47bc   ; LOAD SCREEN DATA: espera a que haya unidad de disco
	jr z,$-93		;47bf
	ld a,021h		;47c1
	ld (0d136h),a		;47c3   ; codigo 0x21, o sea cargar de disco la pantalla
	call L_4B04		;47c6
	call L_6BE1		;47c9   ; elige el fichero
	jp c,L_4715		;47cc
	ld hl,06addh		;47cf
	call L_6AAA		;47d2   ; monta la llamada entre ranuras
	call L_4C1F		;47d5
	call L_66E3		;47d8   ; y lo carga
	jp c,L_4715		;47db
	ld a,0ffh		;47de
	ld (0d13dh),a		;47e0   ; marca que hay pantalla cargada
	call L_4820		;47e3
	ld a,006h		;47e6
	call 00141h		;47e8   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix | la linea 6 del teclado
	and 003h		;47eb
	jp nz,L_47F6		;47ed
	call L_42A4		;47f0
	call L_664C		;47f3   ; y con esas teclas, ademas, se imprime
L_47F6:
	xor a			;47f6
	ld (0d13dh),a		;47f7
	jp L_474F		;47fa
L_47FD:
	ld a,041h		;47fd   ; IMPRIMIR LA PANTALLA CARGADA: codigo 0x41
	ld (0d136h),a		;47ff
	call L_4C1F		;4802
	call L_4616		;4805
	call L_466E		;4808
	call L_6EFD		;480b   ; la carga de cinta
	jp c,L_4715		;480e
	ld a,0ffh		;4811
	ld (0d13dh),a		;4813   ; marca que hay pantalla
	call L_4820		;4816
	xor a			;4819
	ld (0d13dh),a		;481a
	jp L_474F		;481d
L_4820:
	call salva_la_pantalla		;4820   ; EL MODO PANTALLA: sus tres lineas
	ld hl,04850h		;4823
	call pinta_rotulos		;4826
	ld hl,04894h		;4829
	ld b,003h		;482c
	call L_6581		;482e
	call L_6368		;4831

; ----------------------------------------------------------------------
; DATOS modo_pantalla_rutinas: Tres punteros, la tabla del despacho de 0x4831
;   0x4834..0x483a  (6 bytes)
DATA_modo_pantalla_rutinas:
	defb 03ah,048h	; 4834
	defb 045h,048h	; 4836
	defb 04dh,048h	; 4838

; ======================================================================
; CODIGO 0x483a..0x4850  (22 bytes)
; ======================================================================


L_483A:
	call L_63E9		;483a
	call 00156h		;483d   ; BIOS KILBUF - Clears keyboard buffer
	call 0009fh		;4840   ; BIOS CHGET - One character input (waiting)
	jr $-35		;4843
L_4845:
	call L_63E9		;4845
	call L_720E		;4848
	jr $-43		;484b
L_484D:
	jp L_63E9		;484d

; ----------------------------------------------------------------------
; DATOS rotulos_modo_pantalla: SCREEN DISPLAY MODE / DISPLAY ALL SCREEN /
;   PRINT SCREEN / END. Lo pinta el ld hl de 0x4823
;   0x4850..0x4894  (68 bytes)
DATA_rotulos_modo_pantalla:
	defb 026h,03ah,040h,040h,053h,043h,052h,045h,045h,04eh,000h,044h,049h,053h,050h,04ch	; 4850  &:@@SCREEN.DISPL
	defb 041h,059h,000h,04dh,04fh,044h,045h,040h,040h,0feh,067h,03ah,044h,049h,053h,050h	; 4860  AY.MODE@@.g:DISP
	defb 04ch,041h,059h,000h,041h,04ch,04ch,000h,053h,043h,052h,045h,045h,04eh,0feh,087h	; 4870  LAY.ALL.SCREEN..
	defb 03ah,050h,052h,049h,04eh,054h,000h,053h,043h,052h,045h,045h,04eh,0feh,0a7h,03ah	; 4880  :PRINT.SCREEN..:
	defb 045h,04eh,044h,0ffh	; 4890

; ----------------------------------------------------------------------
; DATOS sitios_menu_modo_pantalla: Las TRES filas del menu de 0x4850
;   0x4894..0x489a  (6 bytes)
DATA_sitios_menu_modo_pantalla:
	defb 066h,03ah	; 4894
	defb 086h,03ah	; 4896
	defb 0a6h,03ah	; 4898

; ----------------------------------------------------------------------
; DATOS rotulos_menu_self: SELF MODE MENU / COLOR TEST PATTERN / LOAD SCREEN
;   DATA / END. El "SELF" del manual. Lo pinta el ld hl de 0x471E
;   0x489a..0x48dd  (67 bytes)
DATA_rotulos_menu_self:
	defb 0c6h,038h,040h,040h,053h,045h,04ch,046h,000h,04dh,04fh,044h,045h,000h,04dh,045h	; 489a  .8@@SELF.MODE.ME
	defb 04eh,055h,040h,040h,0feh,027h,039h,043h,04fh,04ch,04fh,052h,000h,054h,045h,053h	; 48aa  NU@@.'9COLOR.TES
	defb 054h,000h,050h,041h,054h,054h,045h,052h,04eh,0feh,067h,039h,04ch,04fh,041h,044h	; 48ba  T.PATTERN.g9LOAD
	defb 000h,053h,043h,052h,045h,045h,04eh,000h,044h,041h,054h,041h,0feh,0a7h,039h,045h	; 48ca  .SCREEN.DATA..9E
	defb 04eh,044h,0ffh	; 48da

; ----------------------------------------------------------------------
; DATOS sitios_menu_self: Las TRES filas del menu de 0x489A, el SELF MODE del
;   manual
;   0x48dd..0x48e3  (6 bytes)
DATA_sitios_menu_self:
	defb 026h,039h	; 48dd
	defb 066h,039h	; 48df
	defb 0a6h,039h	; 48e1

; ======================================================================
; CODIGO 0x48e3..0x4903  (32 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL MODIFY MODE: EL MENU DE LOS TRUCOS. Es a lo que se viene: elegir en que fase empezar y con cuantas vidas. Cinco lineas -MODIFY STAGE NUMBER, MODIFY PLAYER NUMBER, RANKING MODE, COLOR TEST PATTERN y START GAME- sobre los rotulos de 0x4B42.
; ----------------------------------------------------------------------
L_48E3:
	call L_4755		;48e3
	call L_503C		;48e6
	call L_4C1F		;48e9
	ld hl,04b42h		;48ec   ; los rotulos del menu
	call pinta_rotulos		;48ef
	ld de,0384dh		;48f2
	call L_4501		;48f5   ; y el "RC 7xx" del juego que se ha reconocido, para que se vea cual es
	ld hl,04bb7h		;48f8
	ld b,005h		;48fb
	call L_6581		;48fd   ; cinco lineas
	call L_6368		;4900   ; y a la rutina que toque

; ----------------------------------------------------------------------
; DATOS menu_modify_rutinas: Cinco punteros, la tabla del despacho de 0x4900:
;   las cinco lineas del menu de 0x4B42, que es el MODIFY MODE, o sea DONDE
;   ESTAN LOS TRUCOS
;   0x4903..0x490d  (10 bytes)
DATA_menu_modify_rutinas:
	defb 012h,049h	; 4903
	defb 08ch,049h	; 4905
	defb 000h,04ah	; 4907
	defb 02fh,04bh	; 4909
	defb 03eh,04bh	; 490b

; ======================================================================
; CODIGO 0x490d..0x4960  (83 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ¿HAY JUEGO? (0xD301) a 0xFF quiere decir que no se reconocio ninguno, y entonces no hay nada que modificar.
; ----------------------------------------------------------------------
L_490D:
	ld a,(0d301h)		;490d
	inc a			;4910
	ret			;4911
L_4912:
	call L_490D		;4912   ; MODIFY STAGE NUMBER
	jr z,$-50		;4915   ; sin juego, no se entra
	ld a,(0d302h)		;4917   ; (0xD302) a 0xFF: el juego no esta en ninguna tabla
	inc a			;491a
	jr nz,L_4926		;491b
	ld hl,(0d30ah)		;491d   ; pero si trae puntero de vidas en su cabecera, con eso basta
	ld a,h			;4920
	or l			;4921
	jr z,$-63		;4922
	jr L_492E		;4924
L_4926:
	ld hl,05b02h		;4926   ; y si esta en la tabla de trucos, se comprueba que tenga rutina
	call busca_apano		;4929
	jr nz,$-73		;492c
L_492E:
	call L_4C1F		;492e
	ld hl,04960h		;4931
	call pinta_rotulos		;4934
	ld hl,03974h		;4937
	call L_4BC1		;493a
	jp z,L_4B35		;493d
	ld hl,0d31ah		;4940   ; pide la FASE y la guarda en 0xD31A
	call L_4C29		;4943
	jp z,L_4B35		;4946
	ld hl,0d31bh		;4949   ; y las VIDAS, en 0xD31B. Esas dos son las que leen luego las veintiuna rutinas de truco
	call L_4C50		;494c
	ld hl,(0d314h)		;494f
	ld a,h			;4952
	or l			;4953
	ld hl,0d317h		;4954   ; y se marcan los bits de "hay truco pedido" en 0xD317
	jr z,L_495B		;4957
	set 2,(hl)		;4959
L_495B:
	set 1,(hl)		;495b
	jp L_4B35		;495d

; ----------------------------------------------------------------------
; DATOS rotulos_cambiar_fase: MODIFY STAGE NUMBER / STAGE NUMBER>. Lo pinta el
;   ld hl de 0x4931
;   0x4960..0x498c  (44 bytes)
DATA_rotulos_cambiar_fase:
	defb 0c5h,038h,040h,040h,040h,04dh,04fh,044h,049h,046h,059h,000h,053h,054h,041h,047h	; 4960  .8@@@MODIFY.STAG
	defb 045h,000h,04eh,055h,04dh,042h,045h,052h,040h,040h,040h,0feh,067h,039h,053h,054h	; 4970  E.NUMBER@@@.g9ST
	defb 041h,047h,045h,000h,04eh,055h,04dh,042h,045h,052h,03eh,0ffh	; 4980  AGE.NUMBER>.

; ======================================================================
; CODIGO 0x498c..0x49d4  (72 bytes)
; ======================================================================


L_498C:
	call L_490D		;498c   ; MODIFY PLAYER NUMBER, la misma forma con otra tabla
	jp z,L_48E3		;498f
	ld a,(0d302h)		;4992
	inc a			;4995
	jr nz,L_49A2		;4996
	ld hl,(0d308h)		;4998
	ld a,h			;499b
	or l			;499c
	jp z,L_48E3		;499d
	jr L_49AB		;49a0
L_49A2:
	ld hl,05ad1h		;49a2   ; aqui la tabla es la de apanos, 0x5AD1
	call busca_apano		;49a5
	jp nz,L_48E3		;49a8
L_49AB:
	call L_4C1F		;49ab
	ld hl,049d4h		;49ae
	call pinta_rotulos		;49b1
	ld hl,03975h		;49b4
	call L_4BC1		;49b7
	jp z,L_4B35		;49ba
	ld hl,0d318h		;49bd   ; los dos numeros van a 0xD318 y 0xD319
	call L_4C29		;49c0
	jp z,L_4B35		;49c3
	ld hl,0d319h		;49c6
	call L_4C50		;49c9
	ld hl,0d317h		;49cc
	set 0,(hl)		;49cf   ; y su propio bit en 0xD317
	jp L_4B35		;49d1

; ----------------------------------------------------------------------
; DATOS rotulos_cambiar_vidas: MODIFY PLAYER NUMBER / PLAYER NUMBER>. Lo pinta
;   el ld hl de 0x49AE
;   0x49d4..0x4a00  (44 bytes)
DATA_rotulos_cambiar_vidas:
	defb 0c6h,038h,040h,040h,04dh,04fh,044h,049h,046h,059h,000h,050h,04ch,041h,059h,045h	; 49d4  .8@@MODIFY.PLAYE
	defb 052h,000h,04eh,055h,04dh,042h,045h,052h,040h,040h,0feh,067h,039h,050h,04ch,041h	; 49e4  R.NUMBER@@.g9PLA
	defb 059h,045h,052h,000h,04eh,055h,04dh,042h,045h,052h,03eh,0ffh	; 49f4  YER.NUMBER>.

; ======================================================================
; CODIGO 0x4a00..0x4a22  (34 bytes)
; ======================================================================


L_4A00:
	call L_490D		;4a00   ; sin juego no hay ranking que ver
	jp z,L_48E3		;4a03
	ld hl,(0d30eh)		;4a06   ; ni sin puntero de marcador en la cabecera
	ld a,h			;4a09
	or l			;4a0a
	jp z,L_48E3		;4a0b
L_4A0E:
	call L_4C1F		;4a0e
	ld hl,04a3eh		;4a11   ; los rotulos del modo ranking
	call pinta_rotulos		;4a14
L_4A17:
	ld hl,04a8eh		;4a17
	ld b,004h		;4a1a
	call L_6581		;4a1c
	call L_6368		;4a1f

; ----------------------------------------------------------------------
; DATOS modo_ranking_rutinas: Cuatro punteros, la tabla del despacho de 0x4A1F
;   0x4a22..0x4a2a  (8 bytes)
DATA_modo_ranking_rutinas:
	defb 0c7h,04ah	; 4a22
	defb 0edh,04ah	; 4a24
	defb 02ah,04ah	; 4a26
	defb 035h,04bh	; 4a28

; ======================================================================
; CODIGO 0x4a2a..0x4a35  (11 bytes)
; ======================================================================


L_4A2A:
	call L_4A96		;4a2a
L_4A2D:
	ld hl,0d317h		;4a2d
	set 7,(hl)		;4a30
	jp L_4B35		;4a32

; ----------------------------------------------------------------------
; DATOS nombre_por_defecto: "KONAMI". 0x4AB3 lo copia a (0xD478) al borrar la
;   tabla de records: con el ranking a cero, los seis puestos llevan el nombre
;   de la casa
;   0x4a35..0x4a3b  (6 bytes)
DATA_nombre_por_defecto:
	defb 04bh,04fh,04eh,041h,04dh,049h	; 4a35

; ----------------------------------------------------------------------
; DATOS marcador_por_defecto: Los tres bytes que van con el nombre a (0xD459)
;   0x4a3b..0x4a3e  (3 bytes)
DATA_marcador_por_defecto:
	defb 000h,000h,001h	; 4a3b

; ----------------------------------------------------------------------
; DATOS rotulos_modo_ranking: RANKING MODE / LOAD DISK DATA / LOAD TAPE DATA /
;   CLEAR RANKING DATA / END. Lo pinta el ld hl de 0x4A11
;   0x4a3e..0x4a8e  (80 bytes)
DATA_rotulos_modo_ranking:
	defb 0c6h,038h,040h,040h,052h,041h,04eh,04bh,049h,04eh,047h,000h,04dh,04fh,044h,045h	; 4a3e  .8@@RANKING.MODE
	defb 040h,040h,0feh,027h,039h,04ch,04fh,041h,044h,000h,044h,049h,053h,04bh,000h,044h	; 4a4e  @@.'9LOAD.DISK.D
	defb 041h,054h,041h,0feh,067h,039h,04ch,04fh,041h,044h,000h,054h,041h,050h,045h,000h	; 4a5e  ATA.g9LOAD.TAPE.
	defb 044h,041h,054h,041h,0feh,0a7h,039h,043h,04ch,045h,041h,052h,000h,052h,041h,04eh	; 4a6e  DATA..9CLEAR.RAN
	defb 04bh,049h,04eh,047h,000h,044h,041h,054h,041h,0feh,0e7h,039h,045h,04eh,044h,0ffh	; 4a7e  KING.DATA..9END.

; ----------------------------------------------------------------------
; DATOS sitios_menu_modo_ranking: Las CUATRO filas del menu de 0x4A3E
;   0x4a8e..0x4a96  (8 bytes)
DATA_sitios_menu_modo_ranking:
	defb 026h,039h	; 4a8e
	defb 066h,039h	; 4a90
	defb 0a6h,039h	; 4a92
	defb 0e6h,039h	; 4a94

; ======================================================================
; CODIGO 0x4a96..0x4b42  (172 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; BORRAR LA TABLA DE RECORDS. Deja las puntuaciones a cero y los nombres a 0x3C, y luego le pone al primero el nombre de la casa.
; ----------------------------------------------------------------------
L_4A96:
	ld hl,0d459h		;4a96
	ld de,0d45ah		;4a99
	ld (hl),000h		;4a9c   ; las puntuaciones, a cero
	ld bc,0001dh		;4a9e
	ldir		;4aa1
	ld hl,0d477h		;4aa3
	ld de,0d478h		;4aa6
	ld (hl),03ch		;4aa9   ; los nombres, a 0x3C
	ld bc,00059h		;4aab
	ldir		;4aae
	ld de,0d478h		;4ab0
	ld hl,04a35h		;4ab3   ; y encima, "KONAMI": el ranking recien borrado sale con la casa en cabeza
	ld bc,00006h		;4ab6
	ldir		;4ab9
	ld de,0d459h		;4abb
	ld hl,04a3bh		;4abe
	ld bc,00003h		;4ac1
	ldir		;4ac4
	ret			;4ac6
L_4AC7:
	call L_68FE		;4ac7   ; CLEAR RANKING DATA: codigo 0x23
	jp z,L_4A17		;4aca
	ld a,023h		;4acd
	ld (0d136h),a		;4acf
	call L_4B04		;4ad2
	call L_6BE1		;4ad5   ; elige el fichero
	jp c,L_4A0E		;4ad8
	ld hl,06addh		;4adb
	call L_6AAA		;4ade
	call L_4C1F		;4ae1
	call L_66FC		;4ae4   ; y lo carga
	jp nc,L_4A2D		;4ae7
	jp L_4A0E		;4aea
L_4AED:
	ld a,043h		;4aed   ; CLEAR RANKING de cinta: codigo 0x43
	ld (0d136h),a		;4aef
	call L_4C1F		;4af2
	call L_4616		;4af5
	call L_466E		;4af8
	call L_6F11		;4afb
	jp nc,L_4A2D		;4afe
	jp L_4A0E		;4b01

; ----------------------------------------------------------------------
; PREPARAR UNA PANTALLA DE TECLEAR. Deja el marco, el encabezado con la operacion y el dato, y coloca el cursor. El tope se pone a 0x80 para que el cursor se pueda mover por toda la linea y no por un menu.
; ----------------------------------------------------------------------
L_4B04:
	call L_4C1F		;4b04
	call L_4755		;4b07
	call L_4616		;4b0a
	call L_466E		;4b0d   ; el nombre de la operacion
	call L_46B2		;4b10   ; y el del dato
	ld hl,06af6h		;4b13
	call L_6AAA		;4b16   ; la llamada entre ranuras, por si hay que leerle al juego
	xor a			;4b19
	ld (0d163h),a		;4b1a
	ld (0d165h),a		;4b1d
	ld hl,0396ch		;4b20
	ld (0d168h),hl		;4b23   ; donde va el cursor
	ld (0d16ah),hl		;4b26
	ld a,080h		;4b29
	ld (0d164h),a		;4b2b   ; y el tope, de 0x80: aqui no se elige entre lineas, se escribe
	ret			;4b2e
L_4B2F:
	call L_4BC8		;4b2f
	call L_4820		;4b32
L_4B35:
	call L_503C		;4b35
	call L_4C1F		;4b38
	jp L_48E3		;4b3b
L_4B3E:
	di			;4b3e
	jp L_4FDC		;4b3f

; ----------------------------------------------------------------------
; DATOS rotulos_menu_modify: MODIFY MODE MENU / MODIFY STAGE NUMBER / MODIFY
;   PLAYER NUMBER / RANKING MODE / COLOR TEST PATTERN / START GAME. El
;   "MODIFY" del manual, y el menu que da los trucos. Lo pinta el ld hl de
;   0x48EC
;   0x4b42..0x4bb7  (117 bytes)
DATA_rotulos_menu_modify:
	defb 0c6h,038h,040h,040h,04dh,04fh,044h,049h,046h,059h,000h,04dh,04fh,044h,045h,000h	; 4b42  .8@@MODIFY.MODE.
	defb 04dh,045h,04eh,055h,040h,040h,0feh,027h,039h,04dh,04fh,044h,049h,046h,059h,000h	; 4b52  MENU@@.'9MODIFY.
	defb 053h,054h,041h,047h,045h,000h,04eh,055h,04dh,042h,045h,052h,0feh,067h,039h,04dh	; 4b62  STAGE.NUMBER.g9M
	defb 04fh,044h,049h,046h,059h,000h,050h,04ch,041h,059h,045h,052h,000h,04eh,055h,04dh	; 4b72  ODIFY.PLAYER.NUM
	defb 042h,045h,052h,0feh,0a7h,039h,052h,041h,04eh,04bh,049h,04eh,047h,000h,04dh,04fh	; 4b82  BER..9RANKING.MO
	defb 044h,045h,0feh,0e7h,039h,043h,04fh,04ch,04fh,052h,000h,054h,045h,053h,054h,000h	; 4b92  DE..9COLOR.TEST.
	defb 050h,041h,054h,054h,045h,052h,04eh,0feh,027h,03ah,053h,054h,041h,052h,054h,000h	; 4ba2  PATTERN.':START.
	defb 047h,041h,04dh,045h,0ffh	; 4bb2

; ----------------------------------------------------------------------
; DATOS sitios_menu_modify: Las CINCO filas del menu de 0x4B42
;   0x4bb7..0x4bc1  (10 bytes)
DATA_sitios_menu_modify:
	defb 026h,039h	; 4bb7
	defb 066h,039h	; 4bb9
	defb 0a6h,039h	; 4bbb
	defb 0e6h,039h	; 4bbd
	defb 026h,03ah	; 4bbf

; ======================================================================
; CODIGO 0x4bc1..0x4bf5  (52 bytes)
; ======================================================================


L_4BC1:
	ld a,0ffh		;4bc1
	ld b,002h		;4bc3
	jp L_6459		;4bc5
L_4BC8:
	call L_62AB		;4bc8
	ld de,03800h		;4bcb
	ld b,010h		;4bce

; ----------------------------------------------------------------------
; EL PATRON DE PRUEBA DE COLOR. Copia la tira de 32 bytes a ocho filas de la VRAM y luego escribe "KONAMI" encima. Es la pantalla con la que se comprueba que el monitor saca bien los dieciseis colores.
; ----------------------------------------------------------------------
L_4BD0:
	push bc			;4bd0
	push de			;4bd1
	ld bc,00020h		;4bd2
	ld hl,04bffh		;4bd5
	call 0005ch		;4bd8   ; BIOS LDIRVM - Block transfers to VRAM from memory | la misma tira de 32 bytes, ocho veces
	pop hl			;4bdb
	ld bc,00020h		;4bdc
	add hl,bc			;4bdf   ; una fila mas abajo cada vez
	ex de,hl			;4be0
	pop bc			;4be1
	djnz L_4BD0		;4be2
	ld hl,03a07h		;4be4
	ld bc,00810h		;4be7
	ld a,00fh		;4bea
	call L_632B		;4bec   ; pinta el marco
	ld hl,04bf5h		;4bef   ; y el rotulo
	jp pinta_rotulos		;4bf2

; ----------------------------------------------------------------------
; DATOS rotulo_color_test: Un bloque de rotulos de los de 0x6294: la direccion
;   de VRAM 0x3AF8 y "KONAMI" con el 0xFF de cierre. Lo pinta el jp de 0x4BF2
;   0x4bf5..0x4bff  (10 bytes)
DATA_rotulo_color_test:
	defb 0f8h,03ah,088h,04bh,04fh,04eh,041h,04dh,049h,0ffh	; 4bf5  .:.KONAMI.

; ----------------------------------------------------------------------
; DATOS patron_de_prueba_de_color: El COLOR TEST PATTERN del menu SELF, que lo
;   carga 0x4BD5. Van en grupos que abre un byte con el bit 7 puesto -0x80 a
;   0x87- y detras los colores del MSX de esa franja: gris 0x0E, amarillo
;   0x0A, cian 0x07, verde 0x0C, magenta 0x0D, rojo 0x06 y azul 0x04
;   0x4bff..0x4c1f  (32 bytes)
DATA_patron_de_prueba_de_color:
	defb 080h,00eh,00eh,00eh,084h,00ah,00ah,00ah,00ah,081h,007h,007h,007h,085h,00ch,00ch	; 4bff  ................
	defb 00ch,00ch,082h,00dh,00dh,00dh,086h,006h,006h,006h,006h,083h,004h,004h,004h,087h	; 4c0f  ................

; ======================================================================
; CODIGO 0x4c1f..0x4cb9  (154 bytes)
; ======================================================================


L_4C1F:
	ld hl,03880h		;4c1f
	ld bc,00200h		;4c22
	xor a			;4c25
	jp 00056h		;4c26   ; BIOS FILVRM - Fills VRAM with value

; ----------------------------------------------------------------------
; RECOGER UN NUMERO TECLEADO. Con una sola cifra se toma tal cual; con dos, se juntan. Devuelve Z si no se tecleo nada, que es como se cancela.
; ----------------------------------------------------------------------
L_4C29:
	xor a			;4c29
	ld (hl),a			;4c2a   ; el resultado, a cero por si acaso
	ld a,(0d163h)		;4c2b
	or a			;4c2e
	ret z			;4c2f   ; sin cifras, se sale con Z: el usuario ha cancelado
	ld de,0d142h		;4c30
	cp 001h		;4c33   ; una sola cifra
	jr nz,L_4C3D		;4c35
	ld a,(de)			;4c37
	and 00fh		;4c38
	ld (hl),a			;4c3a
	or a			;4c3b
	ret			;4c3c

; ----------------------------------------------------------------------
; DOS CIFRAS TECLEADAS A UN NUMERO. Las teclas llegan como caracteres, asi que hay que quitarles el 0x30 -eso es el `and 0x0F`- y juntar las dos.
; ----------------------------------------------------------------------
L_4C3D:
	cp 002h		;4c3d   ; con menos de dos cifras no se hace nada
	ret nz			;4c3f
	ld a,(de)			;4c40
	and 00fh		;4c41
	add a,a			;4c43   ; la primera por DIEZ: por dos, por ocho y sumadas
	ld b,a			;4c44
	add a,a			;4c45
	add a,a			;4c46
	add a,b			;4c47
	ld b,a			;4c48
	inc de			;4c49
	ld a,(de)			;4c4a
	and 00fh		;4c4b
	add a,b			;4c4d   ; mas la segunda, y sale el numero
	ld (hl),a			;4c4e
	ret			;4c4f
L_4C50:
	xor a			;4c50   ; LO MISMO EN BCD, para los juegos que cuentan asi
	ld (hl),a			;4c51   ; el resultado, a cero por si acaso
	ld a,(0d163h)		;4c52
	or a			;4c55
	ret z			;4c56   ; sin cifras se sale con Z
	ld de,0d142h		;4c57
	cp 001h		;4c5a   ; una sola cifra
	jr nz,L_4C64		;4c5c
	ld a,(de)			;4c5e
	and 00fh		;4c5f
	ld (hl),a			;4c61
	or a			;4c62
	ret			;4c63

; ----------------------------------------------------------------------
; LO MISMO PERO EN BCD. La diferencia esta en el multiplicador: aqui la primera cifra se corre cuatro bits -por dieciseis- en vez de multiplicarse por diez, que es justo lo que distingue el BCD del binario.
; ----------------------------------------------------------------------
L_4C64:
	cp 002h		;4c64
	ret nz			;4c66
	ld a,(de)			;4c67
	and 00fh		;4c68
	add a,a			;4c6a   ; cuatro veces por dos: al nibble alto
	add a,a			;4c6b
	add a,a			;4c6c
	add a,a			;4c6d
	ld b,a			;4c6e
	inc de			;4c6f
	ld a,(de)			;4c70
	and 00fh		;4c71
	add a,b			;4c73   ; y la segunda cifra en el bajo
	ld (hl),a			;4c74
	ret			;4c75

; ----------------------------------------------------------------------
; COMO SE CUELA EN LA INTERRUPCION DEL JUEGO. Se trae 256 bytes del arranque del juego a la RAM, busca el `ld (0xFD9B),hl` con el que instala su gancho, y lo cambia por uno que guarda el gancho en 0xD130 y le pasa el control a este cartucho. Luego ejecuta la copia parcheada, no la original.
; ----------------------------------------------------------------------
L_4C76:
	ld hl,04ccah		;4c76
	ld de,0d814h		;4c79   ; primero se lleva a 0xD814 el trozo al que va a apuntar el parche
	ld bc,0004dh		;4c7c   ; 0x4D bytes
	ldir		;4c7f
	push de			;4c81
	ld hl,(0d132h)		;4c82
	ld bc,00100h		;4c85   ; los 256 primeros del arranque del juego
	call copia_del_vecino		;4c88   ; copia 256 bytes del INIT del vecino leyendolos de su ranura
	pop hl			;4c8b
	ld bc,00100h		;4c8c
L_4C8F:
	ld a,09bh		;4c8f   ; busca el 0x9B seguido de 0xFD: el operando de la instruccion del gancho
	cpir		;4c91   ; cpir hasta dar con el 0x9B
	ret nz			;4c93   ; si no aparece en 256 bytes, este cartucho no sirve
	ret po			;4c94
	ld a,0fdh		;4c95
	cp (hl)			;4c97
	jr nz,L_4C8F		;4c98
	dec hl			;4c9a   ; retrocede al 0x9B, que cpir se lo habia pasado
	ld de,04cb9h		;4c9b   ; y le encaja encima los cinco bytes de 0x4CB9
	ex de,hl			;4c9e
	ld bc,00005h		;4c9f   ; cinco bytes encima: la instruccion pasa a guardar el gancho del juego y llamarnos a nosotros
	ldir		;4ca2
	xor a			;4ca4
	ret			;4ca5

; ----------------------------------------------------------------------
; LDIR ENTRE RANURAS. Copia BC bytes de (HL) en la ranura del vecino a (DE) en la RAM, byte a byte con RDSLT.
; ----------------------------------------------------------------------
copia_del_vecino:
	push bc			;4ca6
	push de			;4ca7
	ld a,(0d12fh)		;4ca8   ; la ranura del vecino
	call 0000ch		;4cab   ; BIOS RDSLT - Reads the value of an address in another slot | RDSLT, un byte cada vez: no hay LDIR entre ranuras
	pop de			;4cae
	pop bc			;4caf
	ld (de),a			;4cb0   ; el byte leido, a la RAM
	inc hl			;4cb1
	inc de			;4cb2
	dec bc			;4cb3   ; y uno menos
	ld a,b			;4cb4
	or c			;4cb5
	jr nz,copia_del_vecino		;4cb6   ; hasta acabar
	ret			;4cb8

; ----------------------------------------------------------------------
; DATOS parche_del_gancho: Los cinco bytes: 22 9B FD (ld (0xFD9B),hl) pasa a
;   ser 22 30 D1 (ld (0xD130),hl) mas CD 14 D8 (call 0xD814)
;   0x4cb9..0x4cbe  (5 bytes)
DATA_parche_del_gancho:
	defb 030h,0d1h,0cdh,014h,0d8h	; 4cb9

; ======================================================================
; CODIGO 0x4cbe..0x4f9d  (735 bytes)
; ======================================================================


L_4CBE:
	ld hl,L_4D17		;4cbe
	ld de,0d170h		;4cc1
	ld bc,0014ah		;4cc4
	ldir		;4cc7
	ret			;4cc9

; ----------------------------------------------------------------------
; ESTO CORRE EN 0xD814, NO AQUI. Restale 0x8B4A para saber a que linea salta. Es a donde va a parar el `call 0xD814` que el parche dejo metido en el arranque del juego, o sea que se ejecuta DENTRO del juego, con su ranura puesta.
; ----------------------------------------------------------------------
L_4CCA:
	di			;4cca
	ld de,0fd00h		;4ccb   ; salva los 0x2CA bytes de la zona de trabajo de la BIOS que el juego acaba de montar
	ld hl,0d961h		;4cce
	ld bc,002cah		;4cd1
	ldir		;4cd4
	ld a,0c3h		;4cd6   ; y planta el gancho propio en H.KEYI: un `jp 0xD299`, que es el bloque de 0x4E40
	ld (0fd9ah),a		;4cd8
	ld hl,0d299h		;4cdb
	ld (0fd9bh),hl		;4cde
	pop hl			;4ce1   ; la direccion de retorno dice por donde iba el arranque del juego
	dec hl			;4ce2
	dec hl			;4ce3
	dec hl			;4ce4
	ld de,0d861h		;4ce5   ; se le resta el sitio de la copia y se le suma el de verdad
	and a			;4ce8
	sbc hl,de		;4ce9
	ld de,(0d132h)		;4ceb
	add hl,de			;4cef
	jp (hl)			;4cf0   ; y se vuelve al juego, a la instruccion de despues del parche, ya en la ROM y no en la copia
L_4CF1:
	ld hl,0fd00h		;4cf1   ; la otra puerta, esta llamada desde 0x40A0: la misma cuenta, pero entrando de nuevas
	ld de,0d961h		;4cf4
	ld bc,002cah		;4cf7
	ldir		;4cfa
	ld a,(0d12fh)		;4cfc
	ld hl,04000h		;4cff
	call 00024h		;4d02   ; BIOS ENASLT - Switches to specified slot and page definitively | se pone la ranura del juego en la pagina 1
	call 0d861h		;4d05   ; y se llama a la copia parcheada de su arranque
	ld hl,(0fedch)		;4d08
	ld de,(0d132h)		;4d0b
	and a			;4d0f
	sbc hl,de		;4d10
	ld de,0d861h		;4d12
	add hl,de			;4d15
	jp (hl)			;4d16

; ----------------------------------------------------------------------
; ESTO CORRE EN 0xD170, NO AQUI. Restale 0x8459. ES EL GANCHO DE INTERRUPCION, o sea el trozo que la maquina ejecuta cincuenta veces por segundo mientras el juego corre. Aqui es donde el Game Master vigila el teclado y le toca las variables al juego.
; ----------------------------------------------------------------------
L_4D17:
	di			;4d17
	ld a,(0d13bh)		;4d18   ; con (0xD13B) puesto no se hace nada: es el interruptor general
	or a			;4d1b
	ret nz			;4d1c
	call 0013eh		;4d1d   ; BIOS RDVDP - Reads VDP status register | hay que leer el estado del VDP igual que lo haria el juego
	call 0fd9fh		;4d20   ; y llamar al gancho ORIGINAL, el que se guardo: el juego no puede notar nada
	ld ix,(0d130h)		;4d23   ; IX, la rutina de interrupcion propia del juego
	ld iy,(0d12dh)		;4d27   ; IY, su ranura, que es lo que pide CALSLT
	ld a,007h		;4d2b
	call 00141h		;4d2d   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix | la linea 7 del teclado
	cpl			;4d30
	and 010h		;4d31   ; bit 4
	ld b,a			;4d33
	ld a,008h		;4d34
	call 00141h		;4d36   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix | y la linea 8
	cpl			;4d39
	rrca			;4d3a
	and 006h		;4d3b   ; bits 1 y 2, que con el otro hacen las tres teclas de truco
	or b			;4d3d
	ld hl,0d137h		;4d3e   ; y se comparan con las de la vuelta anterior, para cazar solo el momento en que se pulsan
	ld c,(hl)			;4d41   ; lo que habia antes
	ld (hl),a			;4d42
	xor c			;4d43   ; xor y and: se queda con las que ANTES no estaban y AHORA si. Sin esto una pulsacion contaria cincuenta veces por segundo
	and (hl)			;4d44
	ld c,a			;4d45
	di			;4d46
	bit 4,a		;4d47   ; la primera tecla: salir del juego y volver al Game Master
	jr z,L_4D52		;4d49
	ld ix,L_4E61		;4d4b   ; por CALSLT, porque el cartucho no esta puesto: hay que llamarse a uno mismo desde fuera
	jp 0001ch		;4d4f   ; BIOS CALSLT - Executes inter-slot call
L_4D52:
	ld a,(0d317h)		;4d52   ; ¿hay algun truco pedido?
	or a			;4d55
	jr z,L_4D70		;4d56
	ld hl,(0d304h)		;4d58   ; lee la variable de fase del juego, la que dijo la cabecera
	ld a,(hl)			;4d5b
	ld hl,0d316h		;4d5c
	cp (hl)			;4d5f   ; y la compara con la de la vuelta anterior: solo se actua cuando CAMBIA de fase
	jr z,L_4D70		;4d60
	ld (hl),a			;4d62
	ld a,(0d312h)		;4d63   ; y solo si la fase nueva es la que se pidio
	cp (hl)			;4d66
	jr nz,L_4D70		;4d67
	ld ix,054d1h		;4d69   ; entonces si, se le aplican los trucos
	jp 0001ch		;4d6d   ; BIOS CALSLT - Executes inter-slot call
L_4D70:
	ld a,(0d332h)		;4d70   ; el ranking: si el juego tiene marcador, se le sigue la pista
	or a			;4d73
	jr z,L_4D95		;4d74
	push bc			;4d76
	ld a,(0d339h)		;4d77   ; (0xD339) es la marca que 0x5E5E puso a los juegos de dos jugadores
	rra			;4d7a
	jr c,L_4D9D		;4d7b
	ld hl,(0d30eh)		;4d7d   ; los punteros a las dos puntuaciones
	ld de,(0d310h)		;4d80
L_4D84:
	push de			;4d84
	ld de,0d31eh		;4d85
	call 0d280h		;4d88   ; 0xD280 esta dentro de este mismo bloque: copia tres bytes de marcador
	ld de,0d321h		;4d8b
	pop hl			;4d8e
	ld a,h			;4d8f
	or l			;4d90
	call nz,0d280h		;4d91   ; y el segundo jugador solo si lo hay
	pop bc			;4d94
L_4D95:
	ld a,(0d134h)		;4d95
	rra			;4d98
	jr c,L_4DB7		;4d99
	jp (ix)		;4d9b   ; y se acaba devolviendole el control al juego, con IX ya cargado con su propia rutina
L_4D9D:
	ld hl,(0d30eh)		;4d9d   ; la otra forma de leer el marcador, para los juegos marcados
	ld de,0d335h		;4da0
	call 0d277h		;4da3
	ld hl,(0d310h)		;4da6
	ld de,0d338h		;4da9
	call 0d277h		;4dac
	ld hl,0d333h		;4daf
	ld de,0d336h		;4db2
	jr L_4D84		;4db5
L_4DB7:
	ld a,(0d135h)		;4db7   ; el modo en el que se esta
	cp 002h		;4dba
	jr z,L_4DC5		;4dbc
	ld ix,L_4EAD		;4dbe
	jp 0001ch		;4dc2   ; BIOS CALSLT - Executes inter-slot call
L_4DC5:
	ld hl,0d13ah		;4dc5
	ld de,0d139h		;4dc8
	bit 1,c		;4dcb   ; las otras dos teclas de truco
	jr z,L_4DF3		;4dcd
	ld a,(hl)			;4dcf
	or a			;4dd0
	ret z			;4dd1
	sub 00dh		;4dd2   ; trece pasos de golpe
	jr z,L_4DD8		;4dd4
	jr nc,L_4DEF		;4dd6
L_4DD8:
	push hl			;4dd8
	push de			;4dd9
	ld ix,L_4E85		;4dda
	call 0001ch		;4dde   ; BIOS CALSLT - Executes inter-slot call
	ld iy,(0d12dh)		;4de1
	ld ix,L_4E76		;4de5
	call 0001ch		;4de9   ; BIOS CALSLT - Executes inter-slot call
	pop de			;4dec
	pop hl			;4ded
	xor a			;4dee
L_4DEF:
	ld (hl),a			;4def
	xor a			;4df0
	ld (de),a			;4df1
	ret			;4df2
L_4DF3:
	bit 2,c		;4df3   ; la tercera tecla: sube el contador de trece en trece
	jr z,L_4E0D		;4df5
	ld a,00dh		;4df7
	add a,(hl)			;4df9
	jr nc,L_4DFE		;4dfa
	ld a,0ffh		;4dfc   ; y se topa en 0xFF, sin dar la vuelta
L_4DFE:
	ld (hl),a			;4dfe
	cp 00dh		;4dff
	jr nz,L_4E0A		;4e01
	ld ix,L_4EF8		;4e03
	call 0001ch		;4e07   ; BIOS CALSLT - Executes inter-slot call
L_4E0A:
	xor a			;4e0a
	ld (de),a			;4e0b
	ret			;4e0c
L_4E0D:
	ld a,(hl)			;4e0d
	or a			;4e0e
	jr z,L_4E17		;4e0f
	ld a,(de)			;4e11
	add a,(hl)			;4e12
	ld (de),a			;4e13
	ret nc			;4e14
	jp (ix)		;4e15   ; se le suma al de la RAM y, si desborda, se le devuelve el control al juego
L_4E17:
	ld ix,L_4E76		;4e17
	jp 0001ch		;4e1b   ; BIOS CALSLT - Executes inter-slot call
L_4E1E:
	ld b,003h		;4e1e   ; COPIAR UN MARCADOR de tres bytes, hacia atras
L_4E20:
	ld a,(hl)			;4e20
	ld (de),a			;4e21   ; hacia atras: se copia del byte alto al bajo
	inc hl			;4e22
	dec de			;4e23
	djnz L_4E20		;4e24   ; tres bytes
	ret			;4e26
L_4E27:
	inc hl			;4e27   ; COMPARAR DOS MARCADORES de tres bytes, del mas alto al mas bajo
	inc hl			;4e28
	push hl			;4e29
	push de			;4e2a
	ld b,003h		;4e2b
L_4E2D:
	ld a,(de)			;4e2d
	cp (hl)			;4e2e
	jr c,L_4E38		;4e2f   ; si el nuevo es mayor, se copia encima: asi se mantiene el record
	dec hl			;4e31
	dec de			;4e32
	djnz L_4E2D		;4e33
	pop de			;4e35
	pop hl			;4e36
	ret			;4e37
L_4E38:
	pop de			;4e38
	pop hl			;4e39
	ld bc,00003h		;4e3a
	lddr		;4e3d
	ret			;4e3f
L_4E40:
	ld hl,00000h		;4e40   ; EL GANCHO QUE SE REINSTALA. Corre en 0xD299
	add hl,sp			;4e43   ; se lleva 128 bytes de la pila de donde este a 0xDF80
	ld de,0df80h		;4e44
	ld bc,00080h		;4e47
	ldir		;4e4a
	ld sp,0df80h		;4e4c   ; y se cambia a esa
	ld hl,0d500h		;4e4f   ; devuelve a su sitio los 0x314 bytes de la zona de trabajo de la BIOS
	ld de,0f100h		;4e52
	ld bc,00314h		;4e55
	ldir		;4e58
	ld hl,0d170h		;4e5a
	ld (0fd9bh),hl		;4e5d   ; y vuelve a plantar el gancho, por si el juego lo habia pisado
	ret			;4e60
L_4E61:
	call 0013eh		;4e61   ; BIOS RDVDP - Reads VDP status register | LA TECLA DE CONGELAR
	ld hl,0d134h		;4e64
	inc (hl)			;4e67   ; un contador que cambia de paridad en cada pulsacion: par es "corriendo" e impar "congelado"
	ld a,(hl)			;4e68
	rra			;4e69
	jr nc,L_4E9E		;4e6a
	xor a			;4e6c
	ld (0d135h),a		;4e6d
	call 00132h		;4e70   ; BIOS CHGCAP - Alternates the CAPS lamp status | y el aviso al jugador NO es un rotulo en pantalla: es EL LED DE CAPS, que se enciende y se apaga. Asi el cartucho avisa sin pintar nada encima del juego
	call L_4E85		;4e73
L_4E76:
	ld e,000h		;4e76   ; CALLAR EL PSG. Los registros 8, 9 y 10 son los volumenes de los tres canales: a cero los tres, y el juego se queda mudo mientras esta congelado
	ld a,008h		;4e78
	call 00093h		;4e7a   ; BIOS WRTPSG - Writes data to PSG-register
	inc a			;4e7d
	call 00093h		;4e7e   ; BIOS WRTPSG - Writes data to PSG-register
	inc a			;4e81
	jp 00093h		;4e82   ; BIOS WRTPSG - Writes data to PSG-register
L_4E85:
	ld a,008h		;4e85   ; GUARDAR LOS TRES VOLUMENES antes de callarlos, para poder devolverlos
	call 00096h		;4e87   ; BIOS RDPSG - Reads value from PSG-register
	ld (0d12bh),a		;4e8a
	ld a,009h		;4e8d
	call 00096h		;4e8f   ; BIOS RDPSG - Reads value from PSG-register
	ld (0d12ch),a		;4e92
	ld a,00ah		;4e95
	call 00096h		;4e97   ; BIOS RDPSG - Reads value from PSG-register
	ld (0d12dh),a		;4e9a   ; y aqui hay un ahorro de Konami: el volumen del canal C se guarda en 0xD12D, que es TAMBIEN el byte bajo del IY con el que 0x4D27 llama por CALSLT. Se puede porque CALSLT solo mira IYh, que es 0xD12E y lleva la ranura
	ret			;4e9d
L_4E9E:
	ld (hl),000h		;4e9e   ; descongelar: contador a cero
	ld a,0ffh		;4ea0
	call 00132h		;4ea2   ; BIOS CHGCAP - Alternates the CAPS lamp status | el LED de CAPS, apagado
	call L_4EF8		;4ea5   ; y el sonido, devuelto
	xor a			;4ea8
	ld (0d135h),a		;4ea9
	ret			;4eac

; ----------------------------------------------------------------------
; MIENTRAS EL JUEGO ESTA CONGELADO. Sube (0xD13B) para que el gancho de interrupcion no se meta consigo mismo, hace lo suyo, y lo vuelve a bajar.
; ----------------------------------------------------------------------
L_4EAD:
	ld a,001h		;4ead
	ld (0d13bh),a		;4eaf   ; el interruptor: con esto puesto, el gancho de 0x4D17 se sale a la primera
	call L_4EBA		;4eb2
	xor a			;4eb5
	ld (0d13bh),a		;4eb6
	ret			;4eb9
L_4EBA:
	call L_4E76		;4eba   ; calla el PSG
	ld ix,(0d130h)		;4ebd   ; IX y la ranura del juego, para poder volver
	ld iy,(0d12eh)		;4ec1
	ld a,(0d135h)		;4ec5
	or a			;4ec8
	jp nz,L_4272		;4ec9
	call lee_las_teclas_de_truco		;4ecc   ; lee las teclas, ya sin el juego de por medio
	ld a,c			;4ecf
	rla			;4ed0   ; el bit de mas peso: seguir
	jr c,L_4EEC		;4ed1
	rla			;4ed3   ; el siguiente: entrar en el modo de mirar la memoria
	jr c,L_4EF2		;4ed4
	rla			;4ed6   ; y el siguiente: empezar a contar
	jr c,L_4EDF		;4ed7
	bit 2,c		;4ed9
	jp nz,L_720E		;4edb   ; y con el bit 2, a la impresora
	ret			;4ede
L_4EDF:
	ld a,002h		;4edf   ; el modo 2: contar
	ld (0d135h),a		;4ee1
	xor a			;4ee4
	ld (0d13ah),a		;4ee5   ; y los dos contadores, a cero
	ld (0d139h),a		;4ee8
	ret			;4eeb
L_4EEC:
	call L_4EF8		;4eec
	jp 0001ch		;4eef   ; BIOS CALSLT - Executes inter-slot call
L_4EF2:
	ld a,001h		;4ef2
	ld (0d135h),a		;4ef4
	ret			;4ef7
L_4EF8:
	ld a,(0d12bh)		;4ef8   ; DEVOLVER LOS TRES VOLUMENES del PSG, los que 0x4E85 guardo
	ld e,a			;4efb
	ld a,008h		;4efc
	call 00093h		;4efe   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,(0d12ch)		;4f01
	ld e,a			;4f04
	ld a,009h		;4f05
	call 00093h		;4f07   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,(0d12dh)		;4f0a
	ld e,a			;4f0d
	ld a,00ah		;4f0e
	jp 00093h		;4f10   ; BIOS WRTPSG - Writes data to PSG-register

; ----------------------------------------------------------------------
; LEER LAS TECLAS DE TRUCO. Tres lineas del teclado, cada una con su mascara, juntadas en un solo byte de banderas. Al final se compara con la lectura anterior para quedarse con las que ACABAN de pulsarse, igual que hace el gancho de interrupcion.
; ----------------------------------------------------------------------
lee_las_teclas_de_truco:
	ld a,001h		;4f13
	call 00141h		;4f15   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix | la linea 1
	cpl			;4f18   ; cpl porque el teclado del MSX da los bits al reves: cero es pulsada
	and 080h		;4f19
	ld d,a			;4f1b
	ld a,006h		;4f1c
	call 00141h		;4f1e   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix | la linea 6
	cpl			;4f21
	and 0e2h		;4f22
	bit 1,a		;4f24   ; y una tecla vale por dos: si esta el bit 1, se enciende ademas el 3
	jr z,L_4F2A		;4f26
	or 008h		;4f28
L_4F2A:
	and 0e8h		;4f2a
	ld e,a			;4f2c
	ld a,007h		;4f2d
	call 00141h		;4f2f   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix | la linea 7
	cpl			;4f32
	and 007h		;4f33
	or e			;4f35
	rlca			;4f36   ; tres desplazamientos para dejar cada bandera en su sitio
	rlca			;4f37
	rlca			;4f38
	or d			;4f39
	ld hl,0d138h		;4f3a
	ld c,(hl)			;4f3d   ; lo que habia en la vuelta anterior
	ld (hl),a			;4f3e
	xor c			;4f3f   ; xor y and: solo las nuevas
	and (hl)			;4f40
	ld c,a			;4f41
	ret			;4f42
L_4F43:
	ld a,002h		;4f43
	ld (0fcafh),a		;4f45
	ld hl,00000h		;4f48
	ld bc,04000h		;4f4b
	xor a			;4f4e
	call 00056h		;4f4f   ; BIOS FILVRM - Fills VRAM with value
	call L_6273		;4f52
	ld a,0ffh		;4f55
	call 00132h		;4f57   ; BIOS CHGCAP - Alternates the CAPS lamp status
	ld bc,00507h		;4f5a
	call 00047h		;4f5d   ; BIOS WRTVDP - Writes data in the VDP-register
	call L_62AB		;4f60
	call L_530D		;4f63
	call 00156h		;4f66   ; BIOS KILBUF - Clears keyboard buffer
L_4F69:
	ld hl,00120h		;4f69   ; espera antes de arrancar
	ld b,001h		;4f6c
	call L_5027		;4f6e
	jr nz,L_4F80		;4f71
	call L_533B		;4f73
	jr nz,L_4F69		;4f76
	ld b,001h		;4f78
	ld hl,00000h		;4f7a
	call L_5027		;4f7d
L_4F80:
	call L_62AB		;4f80   ; limpia la pantalla
	call L_5033		;4f83
	call L_77D6		;4f86   ; el fondo del menu
	call L_7805		;4f89   ; y encima, la pantalla de titulo
L_4F8C:
	ld a,003h		;4f8c
	ld hl,04fa3h		;4f8e   ; los tres rotulos del menu de arranque
	ld bc,00304h		;4f91   ; de tres filas por cuatro
	ld de,039abh		;4f94
	call L_5239		;4f97
	call L_6368		;4f9a   ; y a la rutina que se elija

; ----------------------------------------------------------------------
; DATOS menu_de_arranque_rutinas: Tres punteros, la tabla del despacho de
;   0x4F9A: 0x4FCD, 0x4FFB y 0x5006. Las dos ultimas dejan en (0xD129) un 1 o
;   un 2, y con eso 0x5017 se va al MODIFY MODE (0x48E3) o al SELF MODE
;   (0x470C)
;   0x4f9d..0x4fa3  (6 bytes)
DATA_menu_de_arranque_rutinas:
	defb 0cdh,04fh	; 4f9d
	defb 0fbh,04fh	; 4f9f
	defb 006h,050h	; 4fa1

; ----------------------------------------------------------------------
; DATOS menu_de_arranque_rotulos: Tres punteros a los tres rotulos de aqui
;   abajo, que 0x52A6 indexa por la linea elegida
;   0x4fa3..0x4fa9  (6 bytes)
DATA_menu_de_arranque_rotulos:
	defb 0a9h,04fh	; 4fa3
	defb 0b5h,04fh	; 4fa5
	defb 0c1h,04fh	; 4fa7

; ----------------------------------------------------------------------
; DATOS rotulos_del_menu_de_arranque: Tres rotulos de doce casillas, 3 filas
;   de 4: el bc,00304h que 0x4F91 guarda en (0xD142) y que 0x52B9 le pasa a
;   pinta_rectangulo. No son letras ASCII como el resto de menus, sino
;   casillas de la fuente grafica -0xAE, 0xAF, 0xB5..0xB8, 0xBE, 0xE4..0xEE-,
;   asi que para leerlos hay que dibujarlos
;   0x4fa9..0x4fcd  (36 bytes)
DATA_rotulos_del_menu_de_arranque:
	defb 000h,000h,0aeh,0afh,0b5h,0b6h,0b7h,0b8h,0beh,000h,00ch,00ch	; 4fa9  ............
	defb 000h,000h,00ch,00ch,0e4h,0e5h,0e7h,0e7h,0e6h,000h,00ch,00ch	; 4fb5  ............
	defb 000h,000h,00ch,00ch,0e8h,0e9h,0ech,00ch,0eah,0ebh,0edh,0eeh	; 4fc1  ............

; ======================================================================
; CODIGO 0x4fcd..0x5022  (85 bytes)
; ======================================================================


L_4FCD:
	ld a,(0d13ch)		;4fcd
	inc a			;4fd0
	jr nz,$-69		;4fd1
	ld bc,00107h		;4fd3
	call 00047h		;4fd6   ; BIOS WRTVDP - Writes data in the VDP-register
	call L_62AB		;4fd9
L_4FDC:
	di			;4fdc
	ld hl,0fd9ah		;4fdd
	ld a,0c9h		;4fe0
	ld b,003h		;4fe2
L_4FE4:
	ld (hl),a			;4fe4
	inc hl			;4fe5
	djnz L_4FE4		;4fe6
	xor a			;4fe8
	ld (0d134h),a		;4fe9   ; el contador de congelado, a cero
	ld (0d13bh),a		;4fec   ; y el interruptor general
	jp L_4060		;4fef
L_4FF2:
	xor a			;4ff2
	ld (0d317h),a		;4ff3   ; las banderas de truco, borradas
	ld (0d332h),a		;4ff6   ; y el ranking
	jr L_4FDC		;4ff9
L_4FFB:
	ld a,(0d13ch)		;4ffb
	inc a			;4ffe
	jp nz,L_4F8C		;4fff
	ld a,002h		;5002
	jr L_5008		;5004
L_5006:
	ld a,001h		;5006
L_5008:
	ld (0d129h),a		;5008
	ld bc,00107h		;500b
	call 00047h		;500e   ; BIOS WRTVDP - Writes data in the VDP-register
	call L_62AB		;5011
	call L_5033		;5014
	ld a,(0d129h)		;5017
	cp 002h		;501a
	jp z,L_48E3		;501c
	jp L_470C		;501f

; ----------------------------------------------------------------------
; DATOS entrada_muerta_1: `ld b,001h`. Dos bytes puestos para poder entrar a
;   la rutina de al lado con B a uno, a los que no salta nadie
;   0x5022..0x5024  (2 bytes)
DATA_entrada_muerta_1:
	defb 006h,001h	; 5022

; ======================================================================
; CODIGO 0x5024..0x509a  (118 bytes)
; ======================================================================


L_5024:
	ld hl,00000h		;5024
L_5027:
	dec hl			;5027
	call 0009ch		;5028   ; BIOS CHSNS - Tests the status of the keyboard buffer
	ret nz			;502b
	ld a,h			;502c
	or l			;502d
	jr nz,L_5027		;502e
	djnz L_5024		;5030
	ret			;5032
L_5033:
	call L_50C7		;5033
	call L_5063		;5036
	jp L_50B3		;5039
L_503C:
	ld hl,03800h		;503c
	ld b,002h		;503f
L_5041:
	push bc			;5041
	ld c,004h		;5042
	call L_504E		;5044   ; cuatro columnas
	pop bc			;5047
	ld hl,03a80h		;5048
	djnz L_5041		;504b
	ret			;504d
L_504E:
	ld b,010h		;504e   ; dieciseis filas
	ld a,001h		;5050
L_5052:
	call 0004dh		;5052   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;5055
	call 0004dh		;5056   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;5059
	inc a			;505a
	and 00fh		;505b
	djnz L_5052		;505d
	dec c			;505f
	jr nz,L_504E		;5060
	ret			;5062

; ----------------------------------------------------------------------
; MONTAR LA PANTALLA DEL CARTUCHO. Rellena dos tiras de patrones a mano, suelta el bloque comprimido y coloca las casillas.
; ----------------------------------------------------------------------
L_5063:
	ld hl,02400h		;5063
	ld bc,00020h		;5066
	ld a,03fh		;5069   ; una tira de 0x3F
	call L_62BD		;506b
	ld hl,02420h		;506e
	ld bc,00020h		;5071
	ld a,0fch		;5074   ; y otra de 0xFC, las dos por los tres tercios
	call L_62BD		;5076
	ld hl,0509ah		;5079
	ld de,00400h		;507c
	call L_62E4		;507f   ; y el bloque comprimido, tambien por los tres
	ld hl,050abh		;5082
	ld de,02440h		;5085
	ld bc,00008h		;5088
	call L_62CE		;508b
	ld hl,00440h		;508e
	ld bc,00008h		;5091
	ld a,0f0h		;5094
	call L_62BD		;5096
	ret			;5099

; ----------------------------------------------------------------------
; DATOS gfx_arranque_comprimido: Comprimido; 0x5079 lo suelta con 0x62E4 en la
;   VRAM 0x0400 por los tres tercios
;   0x509a..0x50ab  (17 bytes)
DATA_gfx_arranque_comprimido:
	defb 008h,0e0h,008h,07ah,008h,0dch,008h,046h,008h,0eah,008h,07ch,008h,0d6h,008h,040h	; 509a  ...z...F...|...@
	defb 000h	; 50aa

; ----------------------------------------------------------------------
; DATOS dibujo_de_ocho_bytes: Una casilla de 8x8 que 0x5082 lleva a la VRAM
;   0x2440 -patrones- por los tres tercios, con 0x62CE
;   0x50ab..0x50b3  (8 bytes)
DATA_dibujo_de_ocho_bytes:
	defb 038h,044h,09ah,0a2h,09ah,044h,038h,000h	; 50ab  8D...D8.

; ======================================================================
; CODIGO 0x50b3..0x50d0  (29 bytes)
; ======================================================================


L_50B3:
	ld hl,050d0h		;50b3   ; los patrones, a la VRAM 0x2180 por los tres tercios
	ld de,02180h		;50b6
	call L_62E4		;50b9
	ld a,0f0h		;50bc
	ld hl,00180h		;50be   ; y un relleno de 0xF0
	ld bc,00158h		;50c1
	jp L_62BD		;50c4
L_50C7:
	ld hl,05218h		;50c7   ; el color, a la VRAM 0x0000
	ld de,00000h		;50ca
	jp L_62E4		;50cd

; ----------------------------------------------------------------------
; DATOS gfx_patrones_comprimidos: Comprimido; lo suelta 0x50B3 en la VRAM
;   0x2180 por los tres tercios
;   0x50d0..0x5218  (328 bytes)
DATA_gfx_patrones_comprimidos:
	defb 08bh,000h,01ch,022h,063h,063h,063h,022h,01ch,000h,018h,038h,004h,018h,0f1h,07eh	; 50d0  ..."ccc"...8...~
	defb 000h,03eh,063h,003h,00eh,03ch,070h,07fh,000h,03eh,063h,003h,00eh,003h,063h,03eh	; 50e0  .>c..<p..>c...c>
	defb 000h,00eh,01eh,036h,066h,066h,07fh,006h,000h,07fh,060h,07eh,063h,003h,063h,03eh	; 50f0  ...6ff....`~c.c>
	defb 000h,03eh,063h,060h,07eh,063h,063h,03eh,000h,07fh,063h,006h,00ch,018h,018h,018h	; 5100  .>c`~cc>..c.....
	defb 000h,03eh,063h,063h,03eh,063h,063h,03eh,000h,03eh,063h,063h,03fh,003h,063h,03eh	; 5110  .>cc>cc>.>cc?.c>
	defb 000h,010h,018h,0fch,0feh,0fch,018h,010h,000h,000h,00ch,00ch,000h,000h,00ch,00ch	; 5120  ................
	defb 000h,000h,000h,000h,000h,000h,00ch,00ch,000h,036h,036h,036h,000h,000h,000h,000h	; 5130  .........666....
	defb 000h,000h,07eh,000h,000h,07eh,000h,000h,000h,01ch,022h,022h,00ch,008h,000h,008h	; 5140  ..~..~....""....
	defb 004h,000h,001h,07eh,004h,000h,0c1h,01ch,036h,063h,063h,07fh,063h,063h,000h,07eh	; 5150  ...~....6cc.cc.~
	defb 063h,063h,07eh,063h,063h,07eh,000h,03eh,063h,060h,060h,060h,063h,03eh,000h,07ch	; 5160  cc~cc~.>c```c>.|
	defb 066h,063h,063h,063h,066h,07ch,000h,07fh,060h,060h,07eh,060h,060h,07fh,000h,07fh	; 5170  fcccf|..``~``...
	defb 060h,060h,07eh,060h,060h,060h,000h,03eh,063h,060h,067h,063h,063h,03fh,000h,063h	; 5180  ``~```.>c`gcc?.c
	defb 063h,063h,07fh,063h,063h,063h,000h,03ch,005h,018h,083h,03ch,000h,01fh,004h,006h	; 5190  cc.ccc.<...<....
	defb 08bh,066h,03ch,000h,063h,066h,06ch,078h,07ch,06eh,067h,000h,006h,060h,093h,07fh	; 51a0  .f<.cflx|ng..`..
	defb 000h,063h,077h,07fh,07fh,06bh,063h,063h,000h,063h,073h,07bh,07fh,06fh,067h,063h	; 51b0  .cw..kcc.cs{.ogc
	defb 000h,03eh,005h,063h,0a3h,03eh,000h,07eh,063h,063h,063h,07eh,060h,060h,000h,03eh	; 51c0  .>.c.>.~ccc~``.>
	defb 063h,063h,063h,06fh,066h,03dh,000h,07eh,063h,063h,062h,07ch,066h,063h,000h,03eh	; 51d0  cccof=.~ccb|fc.>
	defb 063h,060h,03eh,003h,063h,03eh,000h,07eh,006h,018h,001h,000h,006h,063h,082h,03eh	; 51e0  c`>.c>.~.....c.>
	defb 000h,004h,063h,0a3h,036h,01ch,008h,000h,063h,063h,06bh,06bh,07fh,077h,022h,000h	; 51f0  ..c.6...cckk.w".
	defb 063h,076h,03ch,01ch,01eh,037h,063h,000h,066h,066h,07eh,03ch,018h,018h,018h,000h	; 5200  cv<..7c.ff~<....
	defb 07fh,007h,00eh,01ch,038h,070h,07fh,000h	; 5210  ....8p..

; ----------------------------------------------------------------------
; DATOS gfx_colores_comprimidos: Comprimido; lo suelta 0x50C7 en la VRAM
;   0x0000 por los tres tercios
;   0x5218..0x5239  (33 bytes)
DATA_gfx_colores_comprimidos:
	defb 008h,000h,008h,011h,008h,022h,008h,033h,008h,044h,008h,055h,008h,066h,008h,077h	; 5218  .....".3.D.U.f.w
	defb 008h,088h,008h,099h,008h,0aah,008h,0bbh,008h,0cch,008h,0ddh,008h,0eeh,008h,0ffh	; 5228  ................
	defb 000h	; 5238

; ======================================================================
; CODIGO 0x5239..0x52e7  (174 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL OTRO SELECTOR DE MENU. Es el del menu de arranque: en vez de una lista de sitios, el rotulo de cada linea se pinta como un rectangulo. Por eso lleva su propio bucle en vez de usar el de 0x6581.
; ----------------------------------------------------------------------
L_5239:
	dec a			;5239
	ld (0d164h),a		;523a   ; el tope
	ld (0d142h),bc		;523d   ; el tamano del rectangulo
	ld (0d16ah),hl		;5241   ; la tabla de rotulos
	ld (0d168h),de		;5244   ; y donde va el primero
	call L_52FF		;5248
L_524B:
	call 0009ch		;524b   ; BIOS CHSNS - Tests the status of the keyboard buffer
	jr z,L_526D		;524e
	call 0009fh		;5250   ; BIOS CHGET - One character input (waiting)
	cp 020h		;5253
	ld b,a			;5255
	jr nz,L_5260		;5256
	ld a,(0d165h)		;5258
	ld (0d163h),a		;525b
	or a			;525e
	ret			;525f
L_5260:
	ld c,0ffh		;5260
	cp 01eh		;5262   ; flecha arriba
	jr z,L_528E		;5264
	ld c,001h		;5266
	cp 01fh		;5268   ; y flecha abajo
	jp z,L_528E		;526a
L_526D:
	ld bc,(0d147h)		;526d   ; no hay tecla: se cuenta un cuadro mas
	inc bc			;5271
	ld (0d147h),bc		;5272
	ld a,b			;5276
	and 07fh		;5277   ; y cada 0x8000 vueltas...
	or c			;5279
	jr nz,L_524B		;527a
	ld hl,039a9h		;527c   ; ...se cambia la casilla del cursor entre 0xAC y 0xF5. Eso es el parpadeo
	ld a,0ach		;527f
	bit 7,b		;5281
	jr nz,L_5289		;5283
	ld a,0f5h		;5285
	ld b,07fh		;5287
L_5289:
	call 0004dh		;5289   ; BIOS WRTVRM - Writes data in VRAM
	ld c,000h		;528c
L_528E:
	ld hl,0d144h		;528e
	inc (hl)			;5291   ; el contador de vueltas, que hace que el adorno del menu alterne
	ld hl,0d164h		;5292
	ld de,0d165h		;5295
	ld a,(de)			;5298
	add a,c			;5299   ; la linea de ahora, mas o menos uno
	jp p,L_529E		;529a   ; si se pasa por arriba, a la ultima
	ld a,(hl)			;529d
L_529E:
	cp (hl)			;529e
	jr c,L_52A4		;529f
	jr z,L_52A4		;52a1
	xor a			;52a3
L_52A4:
	ld (de),a			;52a4
	ld b,a			;52a5   ; la linea elegida
	ld hl,(0d16ah)		;52a6   ; su rotulo, de la tabla de tres punteros
	add a,a			;52a9
	call L_626E		;52aa
	ld a,(hl)			;52ad
	inc hl			;52ae
	ld h,(hl)			;52af
	ld l,a			;52b0
	ld de,(0d168h)		;52b1
	ld bc,(0d142h)		;52b5   ; y el tamano del rectangulo, 3x4
	call pinta_rectangulo		;52b9
	ld de,03b08h		;52bc
	ld a,(0d144h)		;52bf   ; el contador de vueltas: su bit 0 alterna los dos juegos de sprites, y por eso el adorno del menu se mueve
	rra			;52c2
	ld hl,0797fh		;52c3
	jr nc,L_52CB		;52c6
	ld hl,0798fh		;52c8
L_52CB:
	push af			;52cb
	ld bc,00010h		;52cc
	call 0005ch		;52cf   ; BIOS LDIRVM - Block transfers to VRAM from memory
	pop af			;52d2
	ld hl,052e7h		;52d3
	jr nc,L_52DB		;52d6
	ld hl,052f3h		;52d8
L_52DB:
	ld de,03a05h		;52db
	ld bc,00403h		;52de
	call pinta_rectangulo		;52e1
	jp L_524B		;52e4

; ----------------------------------------------------------------------
; DATOS cursor_del_menu_1: Doce casillas, 4x3, que 0x52DB pinta en la VRAM
;   0x3A05: el cursor del menu. El bc,00403h de 0x52DE es el que dice que son
;   cuatro filas de tres
;   0x52e7..0x52f3  (12 bytes)
DATA_cursor_del_menu_1:
	defb 000h,0bfh,0c0h	; 52e7
	defb 0c3h,0c4h,0c5h	; 52ea
	defb 0cfh,0d0h,0d1h	; 52ed
	defb 0dah,0dbh,0dbh	; 52f0

; ----------------------------------------------------------------------
; DATOS cursor_del_menu_2: El otro cursor, 4x3 tambien. 0x52D3 elige uno u
;   otro con el carry que traiga de la eleccion, o sea que el cursor cambia de
;   dibujo segun por donde ande
;   0x52f3..0x52ff  (12 bytes)
DATA_cursor_del_menu_2:
	defb 000h,0efh,0c0h	; 52f3
	defb 000h,0f0h,0f1h	; 52f6
	defb 0f2h,0f3h,0f4h	; 52f9
	defb 0dah,0dbh,0dbh	; 52fc

; ======================================================================
; CODIGO 0x52ff..0x536f  (112 bytes)
; ======================================================================


L_52FF:
	call 00156h		;52ff   ; BIOS KILBUF - Clears keyboard buffer
	xor a			;5302
	ld (0d163h),a		;5303
	ld (0d165h),a		;5306
	ld (0d166h),a		;5309
	ret			;530c

; ----------------------------------------------------------------------
; LA PANTALLA DEL MODO RANKING. Descomprime su fondo y monta a mano la rejilla de la tabla: seis columnas de 21 casillas.
; ----------------------------------------------------------------------
L_530D:
	ld hl,00000h		;530d
	ld (0da01h),hl		;5310
	ld hl,0536fh		;5313
	call descomprime_a_vram		;5316   ; el fondo, comprimido
	ld hl,00880h		;5319
	ld bc,003f0h		;531c
	xor a			;531f
	call 00056h		;5320   ; BIOS FILVRM - Fills VRAM with value | borra la zona de la tabla
	ld hl,03907h		;5323
	ld a,010h		;5326
	ld c,006h		;5328   ; seis columnas
	ld de,0000bh		;532a
L_532D:
	ld b,015h		;532d   ; de 21 casillas cada una
L_532F:
	call 0004dh		;532f   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;5332
	inc a			;5333
	djnz L_532F		;5334
	add hl,de			;5336
	dec c			;5337
	jr nz,L_532D		;5338
	ret			;533a
L_533B:
	ld bc,(0da01h)		;533b
	ld a,0ebh		;533f
	inc b			;5341

; ----------------------------------------------------------------------
; LA BARRA DE PROGRESO. Mientras se guarda o se carga, va pintando casillas 0xF0 de veintiuna en veintiuna. Es lo unico que se mueve en pantalla durante una operacion de disco.
; ----------------------------------------------------------------------
L_5342:
	add a,015h		;5342   ; veintiuno por vuelta
	djnz L_5342		;5344
	ld l,a			;5346
	ld h,b			;5347
	add hl,hl			;5348   ; por ocho, que es lo que ocupa cada fila
	add hl,hl			;5349
	add hl,hl			;534a
	ld de,00880h		;534b   ; la base en la VRAM
	add hl,de			;534e
	ld a,c			;534f
	call L_626E		;5350
	ld b,015h		;5353   ; veintiuna casillas
	ld de,00008h		;5355
	ld a,0f0h		;5358   ; y la casilla llena
L_535A:
	call 0004dh		;535a   ; BIOS WRTVRM - Writes data in VRAM
	add hl,de			;535d   ; de ocho en ocho por la tabla
	djnz L_535A		;535e
	ld hl,0da01h		;5360
	ld a,(hl)			;5363
	inc a			;5364   ; el contador da la vuelta cada ocho
	and 007h		;5365
	ld (hl),a			;5367
	ret nz			;5368
	inc hl			;5369
	inc (hl)			;536a   ; y entonces sube la fila
	ld a,(hl)			;536b
	cp 006h		;536c   ; con seis filas se acabo la barra
	ret			;536e

; ----------------------------------------------------------------------
; DATOS gfx_pantalla_de_ranking: Comprimido; lo suelta 0x5313 al empezar el
;   modo RANKING
;   0x536f..0x54d1  (354 bytes)
DATA_gfx_pantalla_de_ranking:
	defb 080h,028h,018h,000h,002h,007h,003h,00fh,002h,01fh,081h,03fh,008h,0ffh,002h,0f8h	; 536f  .(.........?....
	defb 003h,0f0h,003h,0e0h,07fh,000h,00dh,000h,087h,001h,003h,00fh,07fh,03fh,07fh,07fh	; 537f  .............?..
	defb 00ah,0ffh,082h,0fch,0f0h,003h,0c0h,002h,080h,07fh,000h,083h,001h,003h,007h,003h	; 538f  ................
	defb 00fh,081h,03fh,009h,0ffh,087h,0feh,0fch,0f8h,0f8h,0f0h,0f8h,0c0h,00bh,000h,002h	; 539f  ..?.............
	defb 001h,083h,003h,07fh,07fh,00bh,0ffh,002h,0feh,083h,0fch,080h,080h,006h,000h,002h	; 53af  ................
	defb 03ch,002h,078h,092h,079h,0f3h,0f7h,0ffh,01fh,03eh,07ch,0f9h,0f3h,0e3h,0c3h,087h	; 53bf  <.x.y....>|.....
	defb 01fh,07fh,0f8h,0f0h,0e0h,0e0h,003h,0c0h,084h,0f0h,0f8h,078h,078h,003h,079h,002h	; 53cf  ...........xx.y.
	defb 07fh,083h,0ffh,0f7h,0f7h,003h,0e7h,002h,00fh,003h,01eh,003h,03ch,088h,003h,007h	; 53df  ............<...
	defb 00fh,00eh,01eh,03ch,038h,078h,005h,0e0h,003h,0e1h,002h,07eh,083h,0feh,0f6h,0f6h	; 53ef  ...<8x.....~....
	defb 003h,0eeh,002h,00fh,088h,01fh,01dh,03dh,03bh,07bh,073h,0f1h,0f1h,003h,0e3h,003h	; 53ff  .......=;{s.....
	defb 0c7h,002h,0e0h,003h,0c0h,003h,080h,008h,000h,003h,01fh,003h,03fh,002h,07fh,008h	; 540f  ............?...
	defb 0ffh,083h,0f0h,0e0h,0e0h,003h,0c0h,002h,080h,007h,000h,087h,007h,003h,007h,007h	; 541f  ................
	defb 00fh,01fh,03fh,009h,0ffh,089h,0f8h,0fch,0f8h,0f8h,0f0h,0e0h,0c0h,000h,000h,003h	; 542f  ..?.............
	defb 001h,003h,003h,002h,007h,088h,0efh,0e7h,0e7h,0c7h,0c7h,0c3h,083h,083h,003h,087h	; 543f  ................
	defb 003h,0c7h,092h,0e3h,0e0h,080h,080h,081h,081h,083h,0c7h,0ffh,0feh,0fbh,0f3h,0f3h	; 544f  ................
	defb 0f7h,0e7h,0c7h,08fh,00fh,003h,0c7h,003h,087h,002h,007h,002h,078h,088h,079h,0f1h	; 545f  ............x.y.
	defb 0f3h,0f7h,0e7h,0efh,070h,0f0h,003h,0ffh,002h,081h,081h,001h,003h,0e3h,003h,0e7h	; 546f  ....p...........
	defb 002h,0efh,002h,0ceh,081h,0cfh,003h,08fh,002h,00fh,088h,0f7h,0e7h,0c7h,0cfh,08fh	; 547f  ................
	defb 08fh,01eh,01eh,003h,08fh,003h,01eh,002h,03ch,090h,007h,008h,017h,014h,017h,014h	; 548f  ........<.......
	defb 008h,007h,080h,040h,020h,0a0h,020h,0a0h,040h,080h,011h,000h,085h,003h,00fh,01fh	; 549f  ...@ . .@.......
	defb 03fh,07fh,00bh,0ffh,086h,0fch,0f0h,0e0h,0c0h,080h,080h,07fh,000h,00ah,000h,003h	; 54af  ?...............
	defb 001h,003h,003h,002h,007h,009h,0ffh,002h,0feh,003h,0fch,002h,0f8h,07fh,000h,009h	; 54bf  ................
	defb 000h,000h	; 54cf

; ======================================================================
; CODIGO 0x54d1..0x5616  (325 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL PORTERO DE LOS TRUCOS. Mira uno a uno los bits de (0xD317) -que son lo que el usuario pidio en el MODIFY MODE- y llama a la parte que toque; luego decide si ademas hay que meterse con la fase.
; ----------------------------------------------------------------------
L_54D1:
	ld a,(0d317h)		;54d1
	ld b,a			;54d4
	bit 0,b		;54d5   ; bit 0: lo del MODIFY PLAYER NUMBER
	call nz,L_553B		;54d7
	bit 1,b		;54da   ; bit 1: lo del MODIFY STAGE NUMBER
	call nz,L_554C		;54dc
	bit 2,b		;54df   ; bit 2: el tercero
	call nz,L_5561		;54e1
	ld a,b			;54e4
	and 0f8h		;54e5   ; los cinco bits de arriba se guardan aparte
	ld d,a			;54e7
	call hay_partida		;54e8   ; ¿esta el juego en marcha de verdad?
	jr z,L_54FD		;54eb
	ld a,(0d301h)		;54ed
	cp 015h		;54f0   ; RC-715 Hyper Sports 1 se salta esta parte
	jr z,L_54FD		;54f2
	ld hl,0d33ah		;54f4
	inc (hl)			;54f7   ; y un contador que deja pasar una de cada dos: sin esto el truco se aplicaria dos veces en el mismo cambio de fase
	bit 1,(hl)		;54f8
	jr nz,L_54FD		;54fa
	ld d,b			;54fc

; ----------------------------------------------------------------------
; APLICAR LOS TRUCOS PEDIDOS. La llama el gancho de interrupcion cuando ve que el juego acaba de cambiar de fase. (0xD317) trae los bits de lo que se ha pedido, y el bit 7 es el que dispara todo.
; ----------------------------------------------------------------------
L_54FD:
	ld hl,0d317h		;54fd
	ld (hl),d			;5500   ; se guardan las banderas
	bit 7,d		;5501   ; sin el bit 7 no hay nada que hacer
	ret z			;5503
	res 7,(hl)		;5504   ; y se apaga, para que no se repita
	ld a,0ffh		;5506
	ld (0d13bh),a		;5508   ; sube el interruptor: mientras se toca al juego, el gancho no debe entrar otra vez
	ld hl,0d322h		;550b   ; quince bytes a 0x3C
	ld de,0d323h		;550e
	ld (hl),03ch		;5511
	ld bc,0000fh		;5513
	ldir		;5516
	ld hl,0d31ch		;5518   ; y otros cinco a cero
	ld de,0d31dh		;551b
	ld (hl),000h		;551e
	ld bc,00005h		;5520
	ldir		;5523
	call L_4E76		;5525   ; calla el sonido mientras dura la maniobra
	call salva_la_pantalla		;5528
	call L_5592		;552b   ; y a buscar la rutina del juego en su tabla
	call L_63E9		;552e
	xor a			;5531
	ld (0d13bh),a		;5532
	ld a,0ffh		;5535
	ld (0d332h),a		;5537
	ret			;553a
L_553B:
	ld a,(0d302h)		;553b
	inc a			;553e
	jr z,L_5546		;553f
	ld hl,05ad1h		;5541
	jr L_5555		;5544
L_5546:
	push bc			;5546
	call L_5B5A		;5547
	pop bc			;554a
	ret			;554b
L_554C:
	ld a,(0d302h)		;554c
	inc a			;554f
	jr z,L_555B		;5550
	ld hl,05b02h		;5552
L_5555:
	push bc			;5555
	call L_556F		;5556
	pop bc			;5559
	ret			;555a
L_555B:
	push bc			;555b
	call L_5B6C		;555c
	pop bc			;555f
	ret			;5560
L_5561:
	push bc			;5561
	ld ix,(0d314h)		;5562
	ld iy,(0d12eh)		;5566
	call 0001ch		;556a   ; BIOS CALSLT - Executes inter-slot call
	pop bc			;556d
	ret			;556e

; ----------------------------------------------------------------------
; RECORRER UNA TABLA DE JUEGO. Filas de tres bytes -numero de catalogo y rutina- hasta el 0xFF. Sirve para las dos tablas, la de apanos y la de trucos.
; ----------------------------------------------------------------------
L_556F:
	ld a,(hl)			;556f
	inc a			;5570   ; 0xFF cierra la tabla: el juego no esta
	ret z			;5571
	ld a,(0d301h)		;5572   ; el numero que se averiguo
	cp (hl)			;5575
	inc hl			;5576
	jr z,L_557D		;5577
	inc hl			;5579   ; no es: tres bytes mas alla
	inc hl			;557a
	jr L_556F		;557b
L_557D:
	ld e,(hl)			;557d
	inc hl			;557e
	ld d,(hl)			;557f
	ex de,hl			;5580
	jp (hl)			;5581

; ----------------------------------------------------------------------
; BUSCAR EL JUEGO EN LA TABLA DE APANOS. Recorre 0x5AD1 comparando el numero de catalogo contra el que se averiguo, y se sale por la rutina que encuentre.
; ----------------------------------------------------------------------
busca_apano:
	ld a,(hl)			;5582   ; el numero de catalogo de esta fila
	inc a			;5583   ; 0xFF cierra la tabla
	jr z,L_5590		;5584
	ld a,(0d301h)		;5586   ; el juego que se averiguo
	cp (hl)			;5589
	ret z			;558a   ; si cuadra, se sale con Z
	inc hl			;558b   ; y si no, tres bytes mas alla
	inc hl			;558c
	inc hl			;558d
	jr busca_apano		;558e
L_5590:
	inc a			;5590
	ret			;5591

; ----------------------------------------------------------------------
; PEDIR EL NOMBRE DEL JUGADOR PARA EL RANKING. Primero el del jugador 1 y, si el juego es de dos, el del 2.
; ----------------------------------------------------------------------
L_5592:
	ld hl,03a8ch		;5592
	ld bc,00312h		;5595
	xor a			;5598
	call L_632B		;5599   ; borra la zona de la pantalla donde va a escribir
	ld hl,056a0h		;559c   ; "RANKING / INPUT 1P NAME"
	call pinta_rotulos		;559f
	call L_566E		;55a2
	ld hl,03acch		;55a5
	call L_561B		;55a8   ; y espera a que teclee
	jr z,L_55C6		;55ab
	ld hl,0d142h		;55ad   ; lo tecleado, a su sitio
	ld de,0d322h		;55b0
	ld bc,00008h		;55b3
	ldir		;55b6
	ld hl,0d31ch		;55b8
	call borra_el_marcador		;55bb
	ld a,031h		;55be   ; el "1" que marca de quien es
	call L_565A		;55c0
	call L_566E		;55c3
L_55C6:
	call hay_partida		;55c6   ; y ahora el segundo jugador
	jr z,L_55FB		;55c9   ; si el juego no es de dos, aqui se acaba
	ld hl,056bah		;55cb   ; "INPUT 2P NAME"
	call pinta_rotulos		;55ce
	ld hl,03acch		;55d1
	push hl			;55d4
	ld bc,0000ah		;55d5
	xor a			;55d8
	call 00056h		;55d9   ; BIOS FILVRM - Fills VRAM with value
	pop hl			;55dc
	call L_561B		;55dd
	jr z,L_55FB		;55e0
	ld hl,0d142h		;55e2
	ld de,0d32ah		;55e5
	ld bc,00008h		;55e8
	ldir		;55eb
	ld hl,0d31fh		;55ed
	call borra_el_marcador		;55f0
	ld a,032h		;55f3   ; y el "2"
	call L_565A		;55f5
	call L_566E		;55f8
L_55FB:
	ld hl,03a8ch		;55fb   ; borra el recuadro
	ld bc,00312h		;55fe
	xor a			;5601
	call L_632B		;5602
	ld hl,056e4h		;5605   ; "OK / RETRY"
	call pinta_rotulos		;5608
	ld hl,056f1h		;560b
	ld b,002h		;560e   ; dos lineas
	call L_6581		;5610
	call L_6368		;5613   ; y a la que se elija

; ----------------------------------------------------------------------
; DATOS ok_retry_rutinas: Dos punteros, la tabla del despacho de 0x5613
;   0x5616..0x561a  (4 bytes)
DATA_ok_retry_rutinas:
	defb 01ah,056h	; 5616
	defb 092h,055h	; 5618

; ======================================================================
; CODIGO 0x561a..0x56a0  (134 bytes)
; ======================================================================


L_561A:
	ret			;561a
L_561B:
	ld a,0feh		;561b
	ld b,008h		;561d
	jp L_6459		;561f

; ----------------------------------------------------------------------
; BORRAR UN MARCADOR. Tres bytes a cero, que es lo que ocupa una puntuacion.
; ----------------------------------------------------------------------
borra_el_marcador:
	xor a			;5622
	ld (hl),a			;5623   ; los tres bytes de un marcador
	inc hl			;5624
	ld (hl),a			;5625
	inc hl			;5626
	ld (hl),a			;5627   ; el ultimo
	ret			;5628

; ----------------------------------------------------------------------
; ¿ESTA EL JUEGO JUGANDOSE? Distingue "partida en curso" de "pantalla de titulo o demostracion", que es donde no hay que tocar nada. Cada familia de juegos lo dice de una forma, y por eso hay tres caminos.
; ----------------------------------------------------------------------
hay_partida:
	ld hl,(0d310h)		;5629   ; sin los dos punteros de la cabecera no se puede saber, asi que se dice que no
	ld a,h			;562c
	or l			;562d
	ret z			;562e
	ld hl,(0d306h)		;562f
	ld a,h			;5632
	or l			;5633
	ret z			;5634
	ld a,(0d301h)		;5635
	ld c,a			;5638
	sub 003h		;5639   ; RC-703 y RC-704 -Time Pilot y Frogger- lo dicen con el bit 0, y AL REVES: por eso el `cpl`
	cp 002h		;563b
	jr c,L_564F		;563d
	ld a,c			;563f
	sub 010h		;5640   ; RC-710 y RC-711 -los Hyper Olympic-, igual
	cp 002h		;5642
	jr nc,L_564B		;5644
	ld a,(hl)			;5646
	cpl			;5647
	and 001h		;5648
	ret			;564a
L_564B:
	ld a,(hl)			;564b   ; y los demas, con el bit 5
	bit 5,a		;564c
	ret			;564e
L_564F:
	ld a,(hl)			;564f
	and 001h		;5650
	ret			;5652
L_5653:
	ld a,031h		;5653
	call L_565A		;5655
	ld a,032h		;5658
L_565A:
	ld hl,0d477h		;565a
	ld b,00ah		;565d
	ld c,a			;565f
L_5660:
	ld a,c			;5660
	cp (hl)			;5661
	jr nz,L_5666		;5662
	ld (hl),000h		;5664
L_5666:
	ld a,009h		;5666
	call L_626E		;5668
	djnz L_5660		;566b
	ret			;566d
L_566E:
	ld hl,03a2ch		;566e
	ld bc,00212h		;5671
	xor a			;5674
	call L_632B		;5675
	ld hl,056cah		;5678
	call pinta_rotulos		;567b
	ld hl,0d322h		;567e
	ld de,03a36h		;5681
	ld bc,00008h		;5684
	call 0005ch		;5687   ; BIOS LDIRVM - Block transfers to VRAM from memory
	call hay_partida		;568a
	ret z			;568d
	ld hl,056d7h		;568e
	call pinta_rotulos		;5691
	ld hl,0d32ah		;5694
	ld de,03a56h		;5697
	ld bc,00008h		;569a
	jp 0005ch		;569d   ; BIOS LDIRVM - Block transfers to VRAM from memory

; ----------------------------------------------------------------------
; DATOS rotulos_ranking_1p: RANKING / INPUT 1P NAME. Lo pinta el ld hl de
;   0x559C
;   0x56a0..0x56ba  (26 bytes)
DATA_rotulos_ranking_1p:
	defb 021h,03ah,052h,041h,04eh,04bh,049h,04eh,047h,0feh,08ch,03ah,049h,04eh,050h,055h	; 56a0  !:RANKING..:INPU
	defb 054h,000h,031h,050h,000h,04eh,041h,04dh,045h,0ffh	; 56b0  T.1P.NAME.

; ----------------------------------------------------------------------
; DATOS rotulos_ranking_2p: INPUT 2P NAME. Lo pinta el ld hl de 0x55CB
;   0x56ba..0x56ca  (16 bytes)
DATA_rotulos_ranking_2p:
	defb 08ch,03ah,049h,04eh,050h,055h,054h,000h,032h,050h,000h,04eh,041h,04dh,045h,0ffh	; 56ba  .:INPUT.2P.NAME.

; ----------------------------------------------------------------------
; DATOS rotulos_nombre_1p: 1P NAME >. Lo pinta el ld hl de 0x5678
;   0x56ca..0x56d7  (13 bytes)
DATA_rotulos_nombre_1p:
	defb 02ch,03ah,031h,050h,000h,04eh,041h,04dh,045h,000h,03eh,000h,0ffh	; 56ca  ,:1P.NAME.>..

; ----------------------------------------------------------------------
; DATOS rotulos_nombre_2p: 2P NAME >. Lo pinta el ld hl de 0x568E
;   0x56d7..0x56e4  (13 bytes)
DATA_rotulos_nombre_2p:
	defb 04ch,03ah,032h,050h,000h,04eh,041h,04dh,045h,000h,03eh,000h,0ffh	; 56d7  L:2P.NAME.>..

; ----------------------------------------------------------------------
; DATOS rotulos_ok_retry: OK / RETRY. Lo pinta el ld hl de 0x5605
;   0x56e4..0x56f1  (13 bytes)
DATA_rotulos_ok_retry:
	defb 08ch,03ah,04fh,04bh,0feh,0cch,03ah,052h,045h,054h,052h,059h,0ffh	; 56e4  .:OK..:RETRY.

; ----------------------------------------------------------------------
; DATOS sitios_menu_ok_retry: Las DOS filas del menu de 0x56E4: 0x3A8B y
;   0x3ACB
;   0x56f1..0x56f5  (4 bytes)
DATA_sitios_menu_ok_retry:
	defb 08bh,03ah	; 56f1
	defb 0cbh,03ah	; 56f3

; ======================================================================
; CODIGO 0x56f5..0x594d  (600 bytes)
; ======================================================================


L_56F5:
	ld hl,0d31eh		;56f5   ; el marcador del jugador 1
	ld a,031h		;56f8
	call L_5706		;56fa
	call hay_partida		;56fd   ; si no hay partida, no se apunta nada
	ret z			;5700
	ld hl,0d321h		;5701   ; y el del 2
	ld a,032h		;5704
L_5706:
	ld de,0d477h		;5706
	ex de,hl			;5709
	ld c,a			;570a
	ld b,00ah		;570b
L_570D:
	ld a,c			;570d   ; busca el puesto que le toca a esta puntuacion
	cp (hl)			;570e
	jr z,L_571C		;570f
	ld a,009h		;5711
	call L_626E		;5713   ; nueve bytes por puesto
	djnz L_570D		;5716
	ld b,009h		;5718
	jr L_5723		;571a
L_571C:
	ld a,00ah		;571c   ; encontrado: se calcula cuantos hay que correr hacia abajo
	sub b			;571e
	ld b,a			;571f
	jp z,L_5757		;5720
L_5723:
	ld a,c			;5723
	ld c,000h		;5724
	ld hl,0d45bh		;5726
L_5729:
	push af			;5729
	push bc			;572a
	push hl			;572b
	push de			;572c
	ld b,003h		;572d   ; tres bytes de marcador
	ex de,hl			;572f
L_5730:
	ld a,(de)			;5730
	cp (hl)			;5731   ; se comparan del byte mas alto al mas bajo
	jr c,L_573A		;5732
	jr nz,L_5747		;5734
	dec de			;5736
	dec hl			;5737
	djnz L_5730		;5738   ; tres bytes
L_573A:
	pop de			;573a
	pop hl			;573b
	pop bc			;573c
	pop af			;573d
	call L_575C		;573e   ; entra en la tabla: se hace hueco
	call L_57A1		;5741   ; y se guardan la puntuacion y el nombre
	jp L_57C2		;5744
L_5747:
	pop de			;5747
	pop hl			;5748
	pop bc			;5749
	pop af			;574a
	inc hl			;574b   ; tres bytes por marcador
	inc hl			;574c
	inc hl			;574d
	inc c			;574e
	djnz L_5729		;574f   ; hasta acabar los puestos
	call L_57A1		;5751   ; y se guardan la puntuacion y el nombre
	jp L_57C2		;5754
L_5757:
	ld a,c			;5757
	ld c,b			;5758
	jp L_57A1		;5759

; ----------------------------------------------------------------------
; CORRER LA TABLA UNA LINEA HACIA ABAJO. Dos veces: la de puntuaciones y la de nombres, cada una con su base y su paso.
; ----------------------------------------------------------------------
L_575C:
	ld ix,0d458h		;575c   ; las puntuaciones
	ld iy,0d45bh		;5760
	ld d,000h		;5764
	call L_5773		;5766
	ld ix,0d476h		;5769   ; y los nombres
	ld iy,0d47fh		;576d
	ld d,001h		;5771

; ----------------------------------------------------------------------
; EL SITIO DE UNA LINEA DE LA TABLA. Multiplica por tres y, si hace falta, otra vez por tres: nueve. Es la misma cuenta que 0x57C2, escrita aparte.
; ----------------------------------------------------------------------
L_5773:
	push af			;5773
	push bc			;5774
	ld e,b			;5775
	ld a,c			;5776
	add a,b			;5777
	ld b,a			;5778
	add a,a			;5779   ; por tres
	add a,b			;577a
	bit 0,d		;577b
	jr z,L_5782		;577d
	ld b,a			;577f
	add a,a			;5780   ; y por tres otra vez, cuando el dato lo pide
	add a,b			;5781

; ----------------------------------------------------------------------
; EL SITIO EN LAS DOS TABLAS A LA VEZ. Corre IX por la de nombres e IY por la de puntuaciones, cada una con su paso.
; ----------------------------------------------------------------------
L_5782:
	ld c,a			;5782
	ld b,000h		;5783
	add ix,bc		;5785   ; IX, los nombres
	add iy,bc		;5787   ; IY, las puntuaciones
	ld a,e			;5789
	add a,a			;578a   ; por tres
	add a,e			;578b
	bit 0,d		;578c
	jr z,L_5793		;578e
	ld b,a			;5790
	add a,a			;5791   ; y por tres otra vez si el dato lo pide
	add a,b			;5792
L_5793:
	ld c,a			;5793   ; lddr, de atras adelante: al mover una fila hacia abajo, los dos trozos se pisan
	ld b,000h		;5794
	push ix		;5796
	pop hl			;5798
	push iy		;5799
	pop de			;579b
	lddr		;579c
	pop bc			;579e
	pop af			;579f
	ret			;57a0

; ----------------------------------------------------------------------
; GUARDAR UNA PUNTUACION EN LA TABLA. Tres bytes por puesto, asi que el indice se multiplica por tres.
; ----------------------------------------------------------------------
L_57A1:
	push af			;57a1
	push bc			;57a2
	push af			;57a3
	ld a,c			;57a4
	ld b,a			;57a5
	add a,a			;57a6   ; por tres: tres bytes por marcador
	add a,b			;57a7
	ld hl,0d459h		;57a8
	call L_626E		;57ab
	pop af			;57ae
	ld de,0d31ch		;57af
	cp 032h		;57b2   ; el 0x32 es el "2": el segundo jugador tiene su propio sitio
	jr nz,L_57B9		;57b4
	ld de,0d31fh		;57b6
L_57B9:
	ex de,hl			;57b9
	ld bc,00003h		;57ba   ; tres bytes de puntuacion
	ldir		;57bd
	pop bc			;57bf
	pop af			;57c0
	ret			;57c1

; ----------------------------------------------------------------------
; GUARDAR UN NOMBRE EN LA TABLA DE RECORDS. Cada puesto ocupa nueve bytes, y por eso el indice se multiplica por nueve: por tres y otra vez por tres.
; ----------------------------------------------------------------------
L_57C2:
	push af			;57c2
	push bc			;57c3
	push af			;57c4
	ld a,c			;57c5
	ld b,a			;57c6
	add a,a			;57c7   ; por tres
	add a,b			;57c8
	ld b,a			;57c9
	add a,a			;57ca   ; y otra vez por tres: nueve bytes por puesto
	add a,b			;57cb
	ld hl,0d477h		;57cc
	call L_626E		;57cf
	pop af			;57d2
	ld de,0d322h		;57d3
	cp 032h		;57d6   ; el 0x32 es el "2": el segundo jugador guarda en otro sitio
	jr nz,L_57DD		;57d8
	ld de,0d32ah		;57da
L_57DD:
	ex de,hl			;57dd
	ld (de),a			;57de
	inc de			;57df
	ld bc,00008h		;57e0   ; los ocho caracteres del nombre
	ldir		;57e3
	pop bc			;57e5
	pop af			;57e6
	ret			;57e7

; ----------------------------------------------------------------------
; TECLEAR UN NOMBRE. No se escribe con el teclado: se elige LETRA A LETRA con las flechas, como en los recreativos. El tope 0xC0 marca que aqui el cursor se mueve por caracteres y no por lineas.
; ----------------------------------------------------------------------
L_57E8:
	ld hl,03a29h		;57e8
	ld bc,00616h		;57eb
	xor a			;57ee
	call L_632B		;57ef   ; borra el recuadro donde se va a escribir
	call L_65F4		;57f2
	xor a			;57f5
	ld (0d163h),a		;57f6
	ld (0d165h),a		;57f9
	ld hl,03a29h		;57fc
	ld (0d16ah),hl		;57ff   ; el sitio donde se escribe
	inc hl			;5802
	ld (0d168h),hl		;5803
	ld a,0c0h		;5806
	ld (0d164h),a		;5808   ; el tope, 0xC0
	call L_6569		;580b   ; y el cursor, puesto
L_580E:
	call L_587A		;580e
	call 00156h		;5811   ; BIOS KILBUF - Clears keyboard buffer
L_5814:
	ld hl,0d163h		;5814
	ld de,0d165h		;5817
	call 0009fh		;581a   ; BIOS CHGET - One character input (waiting)
	cp 01eh		;581d
	jr z,L_5864		;581f
	cp 01fh		;5821
	jr z,L_582A		;5823
	cp 020h		;5825
	jr nz,L_5814		;5827
	ret			;5829
L_582A:
	ld a,009h		;582a
	cp (hl)			;582c   ; nueve caracteres como mucho
	jr z,L_5814		;582d
	inc (hl)			;582f
	ld a,(de)			;5830
	ld b,a			;5831
	ld a,(hl)			;5832
	sub b			;5833
	cp 005h		;5834   ; y a partir de cinco, la lista de letras se desplaza en vez de seguir bajando
	jr c,L_5840		;5836
	inc b			;5838
	ld a,b			;5839
	ld (de),a			;583a
	ld bc,00000h		;583b
	jr L_5843		;583e
L_5840:
	ld bc,00020h		;5840
L_5843:
	ld a,(hl)			;5843
	cp 009h		;5844
	jr nz,L_5849		;5846
	dec bc			;5848

; ----------------------------------------------------------------------
; ELEGIR LETRA CON LAS FLECHAS. Mueve el cursor y comprueba con DCOMPR que no se pase del final de la linea.
; ----------------------------------------------------------------------
L_5849:
	call L_6571		;5849   ; borra el cursor de donde estaba
	add hl,bc			;584c
	push hl			;584d
	ld de,(0d16ah)		;584e
	and a			;5852
	sbc hl,de		;5853   ; cuanto se ha avanzado
	ld a,(0d164h)		;5855
	ld d,000h		;5858
	ld e,a			;585a
	rst 20h			;585b   ; DCOMPR contra el tope
	pop hl			;585c
	jr nc,L_5862		;585d
	ld (0d168h),hl		;585f   ; y solo si cabe, se mueve
L_5862:
	jr L_580E		;5862
L_5864:
	ld a,(hl)			;5864   ; subir en la lista de letras
	or a			;5865
	jr z,L_5814		;5866
	dec (hl)			;5868   ; una menos
	ex de,hl			;5869
	ld a,(de)			;586a
	cp (hl)			;586b
	jr nc,L_586F		;586c
	dec (hl)			;586e
L_586F:
	ld bc,0ffe0h		;586f   ; 0xFFE0 es "una fila para arriba"
	ld a,(de)			;5872
	cp 008h		;5873
	jr nz,L_5878		;5875
	inc bc			;5877
L_5878:
	jr L_5849		;5878

; ----------------------------------------------------------------------
; PINTAR LA TABLA DE RECORDS. Cinco puestos, cada uno con su numero, su nombre y su puntuacion. El numero sale de sumarle 0x31 al indice, o sea el "1" en ASCII.
; ----------------------------------------------------------------------
L_587A:
	ld a,(0d165h)		;587a
	call sitio_del_nombre		;587d   ; donde estan los nombres
	push hl			;5880
	pop ix		;5881
	ld a,(0d165h)		;5883
	call L_595E		;5886   ; y donde las puntuaciones
	push hl			;5889
	pop iy		;588a
	ld hl,(0d16ah)		;588c
	inc hl			;588f
	ld a,(0d165h)		;5890
	add a,031h		;5893   ; mas 0x31: el "1", el "2"... el numero del puesto
	ld c,a			;5895
	ld b,005h		;5896   ; cinco puestos
L_5898:
	push bc			;5898
	push hl			;5899
	push hl			;589a
	push bc			;589b
	xor a			;589c
	ld bc,00015h		;589d
	call 00056h		;58a0   ; BIOS FILVRM - Fills VRAM with value
	call L_6569		;58a3
	pop bc			;58a6
	pop hl			;58a7
	ld a,c			;58a8
	cp 03ah		;58a9
	jr z,L_58B3		;58ab
	inc hl			;58ad
	call 0004dh		;58ae   ; BIOS WRTVRM - Writes data in VRAM
	jr L_58BE		;58b1
L_58B3:
	ld a,031h		;58b3
	call 0004dh		;58b5   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;58b8
	ld a,030h		;58b9
	call 0004dh		;58bb   ; BIOS WRTVRM - Writes data in VRAM

; ----------------------------------------------------------------------
; UNA LINEA DEL RANKING EN PANTALLA. El puesto, el nombre y la puntuacion, separados por las casillas 0x3B y 0x3E.
; ----------------------------------------------------------------------
L_58BE:
	inc hl			;58be
	ld a,03bh		;58bf   ; el separador de delante
	call 0004dh		;58c1   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;58c4
	push ix		;58c5
	pop de			;58c7
	ex de,hl			;58c8
	ld bc,00008h		;58c9
	push de			;58cc
	push bc			;58cd
	call 0005ch		;58ce   ; BIOS LDIRVM - Block transfers to VRAM from memory | los ocho caracteres del nombre
	ld hl,0da00h		;58d1
	ld a,(iy+002h)		;58d4   ; y los tres bytes del marcador, de mayor a menor
	call bcd_a_dos_letras		;58d7
	inc hl			;58da
	ld a,(iy+001h)		;58db
	call bcd_a_dos_letras		;58de
	inc hl			;58e1
	ld a,(iy+000h)		;58e2
	call bcd_a_dos_letras		;58e5
	pop bc			;58e8
	pop hl			;58e9
	add hl,bc			;58ea
	ld a,03eh		;58eb   ; y el separador del final
	call 0004dh		;58ed   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;58f0
	ld de,0da00h		;58f1
	ld bc,00600h		;58f4
	ld a,(0d301h)		;58f7
	cp 029h		;58fa
	jr nz,L_5901		;58fc
	inc de			;58fe
	dec b			;58ff
	inc c			;5900
L_5901:
	ld a,(de)			;5901   ; mientras salgan ceros, no se pintan
	cp 030h		;5902
	jr nz,L_5915		;5904
	inc hl			;5906
	inc de			;5907
	djnz L_5901		;5908
	bit 0,c		;590a   ; salvo el ultimo, que si
	jr nz,L_590F		;590c
	dec hl			;590e
L_590F:
	call 0004dh		;590f   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;5912
	jr L_592D		;5913
L_5915:
	push bc			;5915
	ld c,b			;5916
	ld b,000h		;5917
	ex de,hl			;5919
	push bc			;591a
	push de			;591b
	call 0005ch		;591c   ; BIOS LDIRVM - Block transfers to VRAM from memory
	pop hl			;591f
	pop bc			;5920
	add hl,bc			;5921
	pop bc			;5922
	bit 0,c		;5923
	jr z,L_592D		;5925
	ld a,030h		;5927
	call 0004dh		;5929   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;592c
L_592D:
	ld de,0594dh		;592d   ; el "PT" detras de la puntuacion, en pantalla esta vez
	ex de,hl			;5930
	ld bc,00003h		;5931
	call 0005ch		;5934   ; BIOS LDIRVM - Block transfers to VRAM from memory
	ld bc,00009h		;5937   ; nueve bytes por puesto de la tabla
	add ix,bc		;593a
	ld bc,00003h		;593c   ; y tres del marcador
	add iy,bc		;593f
	pop hl			;5941
	ld bc,00020h		;5942   ; una fila de pantalla mas abajo
	add hl,bc			;5945
	pop bc			;5946
	inc c			;5947
	dec b			;5948   ; hasta acabar los puestos
	jp nz,L_5898		;5949
	ret			;594c

; ----------------------------------------------------------------------
; DATOS sufijo_pt: Los tres caracteres que 0x592D pega detras de cada
;   puntuacion del ranking
;   0x594d..0x5950  (3 bytes)
DATA_sufijo_pt:
	defb 050h,054h,053h	; 594d

; ======================================================================
; CODIGO 0x5950..0x59b6  (102 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL SITIO DE UN NOMBRE EN LA TABLA. Nueve bytes por puesto, por tres y otra vez por tres, mas la base 0xD477.
; ----------------------------------------------------------------------
sitio_del_nombre:
	ld b,a			;5950
	add a,a			;5951
	add a,b			;5952   ; por tres
	ld b,a			;5953
	add a,a			;5954
	add a,b			;5955   ; y por tres otra vez: nueve
	ld hl,0d477h		;5956
	call L_626E		;5959
	inc hl			;595c
	ret			;595d
L_595E:
	ld b,a			;595e   ; EL SITIO DE UNA PUNTUACION, la misma cuenta con otra base
	add a,a			;595f
	add a,b			;5960
	ld hl,0d459h		;5961
	call L_626E		;5964
	ret			;5967

; ----------------------------------------------------------------------
; IMPRIMIR EL RANKING. Monta la hoja en la RAM -0x3BF caracteres, que es lo que cabe- y la manda entera a la impresora.
; ----------------------------------------------------------------------
L_5968:
	ld (0d127h),sp		;5968
	ld hl,0d9b1h		;596c
	ld de,0d9b2h		;596f
	ld (hl),020h		;5972   ; la hoja, llena de espacios
	ld bc,003bfh		;5974
	ldir		;5977
	call L_7289		;5979
	ld a,0e0h		;597c
	ld (0dd76h),a		;597e   ; la anchura y el margen
	ld a,078h		;5981
	ld (0dd75h),a		;5983
	ld hl,059b6h		;5986   ; el encabezado con el nombre del juego
	call L_59A5		;5989
	ld a,(0d301h)		;598c   ; y el numero de catalogo, metido en el hueco que el encabezado dejo
	ld hl,0d9b9h		;598f
	call bcd_a_dos_letras		;5992
	xor a			;5995
	ld (0d165h),a		;5996
	ld hl,0da41h		;5999
	ld (0d16ah),hl		;599c
	call L_5A0C		;599f   ; las lineas, una por puesto
	jp L_7707		;59a2   ; y a imprimir

; ----------------------------------------------------------------------
; EL TEXTO QUE SE MANDA A LA IMPRESORA. Es el mismo formato de rotulos de 0x6294, pero escribiendo en la RAM con `ld (de),a` en vez de en la VRAM: por eso hay dos rutinas casi iguales.
; ----------------------------------------------------------------------
L_59A5:
	ld e,(hl)			;59a5
	inc hl			;59a6
	ld d,(hl)			;59a7
	inc hl			;59a8
L_59A9:
	ld a,(hl)			;59a9
	ld b,a			;59aa
	inc hl			;59ab
	inc a			;59ac   ; 0xFF cierra el bloque
	ret z			;59ad
	inc a			;59ae   ; 0xFE quiere decir que hay otro trozo detras
	jr z,L_59A5		;59af
	ld a,b			;59b1
	ld (de),a			;59b2   ; y cualquier otro byte es un caracter, que aqui va a la RAM y no a la VRAM
	inc de			;59b3
	jr L_59A9		;59b4

; ----------------------------------------------------------------------
; DATOS encabezado_del_listado: Las tres lineas que encabezan el ranking
;   impreso: "*** RC-7   SCORE RANKING ***", "Rank.  Name.   Score." y una
;   raya de veintiun guiones. El hueco detras de "RC-7" lo rellena 0x598C con
;   el numero del juego que se ha reconocido. Es el UNICO texto del cartucho
;   con minusculas: todo lo que va a la pantalla esta en mayusculas porque la
;   fuente no tiene otra cosa, y aqui manda la impresora
;   0x59b6..0x5a0c  (86 bytes)
DATA_encabezado_del_listado:
	defb 0b1h,0d9h,02ah,02ah,02ah,020h,052h,043h,02dh,037h,020h,020h,020h,053h,043h,04fh	; 59b6  ..*** RC-7   SCO
	defb 052h,045h,020h,052h,041h,04eh,04bh,049h,04eh,047h,020h,02ah,02ah,02ah,0feh,0ebh	; 59c6  RE RANKING ***..
	defb 0d9h,052h,061h,06eh,06bh,02eh,020h,020h,04eh,061h,06dh,065h,02eh,020h,020h,020h	; 59d6  .Rank.  Name.   
	defb 053h,063h,06fh,072h,065h,02eh,0feh,005h,0dah,02dh,02dh,02dh,02dh,02dh,02dh,02dh	; 59e6  Score....-------
	defb 02dh,02dh,02dh,02dh,02dh,02dh,02dh,02dh,02dh,02dh,02dh,02dh,02dh,02dh,02dh,02dh	; 59f6  ----------------
	defb 02dh,02dh,02dh,02dh,02dh,0ffh	; 5a06

; ======================================================================
; CODIGO 0x5a0c..0x5ad1  (197 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LA TABLA DE RECORDS PARA IMPRIMIR. Lo mismo que 0x587A pero en la RAM y con DIEZ puestos en vez de cinco: en papel caben mas.
; ----------------------------------------------------------------------
L_5A0C:
	ld a,(0d165h)		;5a0c
	call sitio_del_nombre		;5a0f
	push hl			;5a12
	pop ix		;5a13
	ld a,(0d165h)		;5a15
	call L_595E		;5a18
	push hl			;5a1b
	pop iy		;5a1c
	ld hl,(0d16ah)		;5a1e
	ld a,(0d165h)		;5a21
	add a,031h		;5a24   ; el numero del puesto
	ld c,a			;5a26
	ld b,00ah		;5a27   ; diez puestos, el doble que en pantalla
L_5A29:
	push bc			;5a29
	push hl			;5a2a
	ld a,c			;5a2b
	cp 03ah		;5a2c   ; el 0x3A marca el puesto que se acaba de hacer
	jr z,L_5A34		;5a2e
	inc hl			;5a30
	ld (hl),a			;5a31
	jr L_5A3B		;5a32
L_5A34:
	ld a,031h		;5a34   ; y ese sale con un "1" delante
	ld (hl),a			;5a36
	inc hl			;5a37
	ld a,030h		;5a38
	ld (hl),a			;5a3a
L_5A3B:
	inc hl			;5a3b
	ld a,03ah		;5a3c   ; el 0x3A separa el puesto del nombre
	ld (hl),a			;5a3e
	inc hl			;5a3f
	push ix		;5a40
	pop de			;5a42
	ex de,hl			;5a43
	push de			;5a44
	ld b,008h		;5a45   ; ocho caracteres de nombre
L_5A47:
	ld a,(hl)			;5a47
	cp 03ch		;5a48   ; el 0x3C es el hueco: los nombres cortos van rellenos con el
	jr nz,L_5A4E		;5a4a
	ld a,02eh		;5a4c

; ----------------------------------------------------------------------
; UNA LINEA DEL RANKING IMPRESO. Junta el puesto, el nombre y la puntuacion, y le quita los ceros de delante al numero para que no salga "000450".
; ----------------------------------------------------------------------
L_5A4E:
	ld (de),a			;5a4e
	inc hl			;5a4f
	inc de			;5a50
	djnz L_5A47		;5a51   ; ocho caracteres de nombre
	ld hl,0d142h		;5a53
	ld a,(iy+002h)		;5a56   ; los tres bytes del marcador, del mas alto al mas bajo
	call bcd_a_dos_letras		;5a59
	inc hl			;5a5c
	ld a,(iy+001h)		;5a5d
	call bcd_a_dos_letras		;5a60
	inc hl			;5a63
	ld a,(iy+000h)		;5a64
	call bcd_a_dos_letras		;5a67
	pop hl			;5a6a
	ld a,008h		;5a6b
	call L_626E		;5a6d   ; ocho bytes mas alla va la puntuacion
	ld a,03dh		;5a70   ; el 0x3D es el "=" que separa
	ld (hl),a			;5a72
	inc hl			;5a73
	ld de,0d142h		;5a74
	ld bc,00600h		;5a77   ; seis cifras de marcador
	ld a,(0d301h)		;5a7a
	cp 029h		;5a7d   ; RC-729 Pippols cuenta con un digito menos, y por eso se le corre el principio
	jr nz,L_5A84		;5a7f
	inc de			;5a81
	dec b			;5a82
	inc c			;5a83
L_5A84:
	ld a,(de)			;5a84
	cp 030h		;5a85   ; mientras salgan ceros, se van saltando
	jr nz,L_5A96		;5a87
	inc hl			;5a89
	inc de			;5a8a
	djnz L_5A84		;5a8b
	bit 0,c		;5a8d   ; salvo que sea el ultimo: un marcador a cero tiene que salir como "0", no como nada
	jr nz,L_5A92		;5a8f
	dec hl			;5a91
L_5A92:
	ld (hl),a			;5a92
	inc hl			;5a93
	jr L_5AAB		;5a94
L_5A96:
	push bc			;5a96
	ld c,b			;5a97
	ld b,000h		;5a98
	ex de,hl			;5a9a
	push bc			;5a9b
	push de			;5a9c
	ldir		;5a9d   ; copia el nombre
	pop hl			;5a9f
	pop bc			;5aa0
	add hl,bc			;5aa1
	pop bc			;5aa2
	bit 0,c		;5aa3   ; y si la puntuacion es de las cortas, le pone un "0" delante
	jr z,L_5AAB		;5aa5
	ld a,030h		;5aa7
	ld (hl),a			;5aa9
	inc hl			;5aaa
L_5AAB:
	ld de,0594dh		;5aab   ; pega el "PT" detras de la puntuacion
	ex de,hl			;5aae
	ld bc,00003h		;5aaf
	ldir		;5ab2
	ld bc,00009h		;5ab4   ; nueve bytes por fila de la tabla
	add ix,bc		;5ab7
	ld bc,00003h		;5ab9   ; y tres del marcador
	add iy,bc		;5abc
	pop hl			;5abe
	ld a,(0dd76h)		;5abf   ; la anchura de la hoja, entre ocho
	and 0f8h		;5ac2
	rrca			;5ac4
	rrca			;5ac5
	rrca			;5ac6
	call L_626E		;5ac7
	pop bc			;5aca
	inc c			;5acb
	dec b			;5acc   ; hasta acabar los puestos
	jp nz,L_5A29		;5acd
	ret			;5ad0

; ----------------------------------------------------------------------
; DATOS tabla_de_apanos: Los 16 juegos que necesitan un apano aparte: numero
;   de catalogo en BCD y rutina. Termina en 0xFF
;   0x5ad1..0x5b02  (49 bytes)
DATA_tabla_de_apanos:
	defb 000h,052h,05bh	; 5ad1
	defb 002h,052h,05bh	; 5ad4
	defb 003h,052h,05bh	; 5ad7
	defb 004h,052h,05bh	; 5ada
	defb 005h,052h,05bh	; 5add
	defb 006h,052h,05bh	; 5ae0
	defb 012h,052h,05bh	; 5ae3
	defb 013h,052h,05bh	; 5ae6
	defb 014h,052h,05bh	; 5ae9
	defb 016h,052h,05bh	; 5aec
	defb 025h,042h,05bh	; 5aef
	defb 021h,052h,05bh	; 5af2
	defb 027h,052h,05bh	; 5af5
	defb 028h,05fh,05bh	; 5af8
	defb 029h,05ah,05bh	; 5afb
	defb 037h,05ah,05bh	; 5afe
	defb 0ffh	; 5b01

; ----------------------------------------------------------------------
; DATOS tabla_de_trucos_por_juego: Veintiuna entradas de tres bytes -numero de
;   catalogo en BCD y la rutina que le toca-, cerradas por un 0xFF, que
;   recorre 0x5582 por encargo de 0x4926. Es la segunda de las dos tablas de
;   juego, y la que importa: aqui hay casi una rutina por cartucho, o sea que
;   es DONDE ESTAN LOS TRUCOS. Dos parejas comparten rutina: RC-700 con RC-716
;   y RC-710 con RC-711
;   0x5b02..0x5b42  (64 bytes)
DATA_tabla_de_trucos_por_juego:
	defb 000h,07bh,05bh	; 5b02
	defb 001h,0a0h,05bh	; 5b05
	defb 010h,0dbh,05bh	; 5b08
	defb 011h,0dbh,05bh	; 5b0b
	defb 012h,024h,05ch	; 5b0e
	defb 013h,03ah,05ch	; 5b11
	defb 014h,08ch,05ch	; 5b14
	defb 015h,08fh,05ch	; 5b17
	defb 016h,07bh,05bh	; 5b1a
	defb 017h,096h,05ch	; 5b1d
	defb 018h,0a2h,05ch	; 5b20
	defb 021h,0dah,05ch	; 5b23
	defb 025h,0ebh,05ch	; 5b26
	defb 027h,01bh,05dh	; 5b29
	defb 028h,06ch,05dh	; 5b2c
	defb 029h,087h,05dh	; 5b2f
	defb 030h,09ah,05dh	; 5b32
	defb 032h,0b9h,05dh	; 5b35
	defb 033h,0c2h,05dh	; 5b38
	defb 036h,0cbh,05dh	; 5b3b
	defb 037h,0f1h,05dh	; 5b3e
	defb 0ffh	; 5b41

; ======================================================================
; CODIGO 0x5b42..0x5bc7  (133 bytes)
; ======================================================================


L_5B42:
	ld a,0ffh		;5b42   ; el apano de doce juegos: 0xFF en 0xE052
	ld (0e052h),a		;5b44
	ld a,(0d318h)		;5b47
	cp 00bh		;5b4a   ; y el numero pedido, topado en diez
	jr c,L_5B50		;5b4c
	ld a,00ah		;5b4e
L_5B50:
	jr L_5B55		;5b50
L_5B52:
	ld a,(0d318h)		;5b52
L_5B55:
	ld hl,(0d308h)		;5b55
	ld (hl),a			;5b58
	ret			;5b59
L_5B5A:
	ld a,(0d319h)		;5b5a
	jr L_5B55		;5b5d
L_5B5F:
	ld a,(0d318h)		;5b5f
	ld (0e050h),a		;5b62
	ld a,(0d319h)		;5b65
	ld (0e051h),a		;5b68
	ret			;5b6b
L_5B6C:
	ld a,(0d313h)		;5b6c   ; el numero de fases lo dice la propia cabecera del juego, en (0xD313)
	ld c,a			;5b6f
	ld a,(0d31ah)		;5b70
	call divide_a_entre_c		;5b73   ; y se divide por el
	ld a,l			;5b76
	inc a			;5b77
	jp L_5D16		;5b78

; ----------------------------------------------------------------------
; LOS TRUCOS, UNO POR JUEGO.
; ----------------------------------------------------------------------
L_5B7B:
	ld a,(0d31ah)		;5b7b   ; RC-700 y RC-716: la fase pedida
	dec a			;5b7e
	ld l,a			;5b7f
	ld h,000h		;5b80
	add hl,hl			;5b82   ; por diez, sumando x2 y x8
	ld b,h			;5b83
	ld c,l			;5b84
	add hl,hl			;5b85
	add hl,hl			;5b86
	add hl,bc			;5b87
	call a_bcd		;5b88   ; a BCD, que es como lleva Athletic Land el marcador
	ld a,e			;5b8b
	ld (0e059h),a		;5b8c   ; y se le planta: saltar de fase te pone tambien la puntuacion
	push af			;5b8f
	add a,010h		;5b90   ; mas diez en BCD para el byte de arriba
	daa			;5b92
	ld (0e05ah),a		;5b93
	pop af			;5b96
	call a_binario		;5b97
	ld (0e054h),a		;5b9a   ; y la fase en binario a su 0xE054
	jp pon_las_vidas		;5b9d
L_5BA0:
	ld a,(0d31ah)		;5ba0   ; RC-701 Antarctic Adventure: la fase pedida
	ld c,00ah		;5ba3   ; entre DIEZ, que son las pistas que tiene el juego: de la once en adelante es la segunda vuelta
	call divide_a_entre_c		;5ba5
	ld a,l			;5ba8
	ld (0e0e1h),a		;5ba9   ; la pista va a dos sitios a la vez
	ld (0e0e8h),a		;5bac
	ld b,a			;5baf
	ld a,(0d303h)		;5bb0   ; y aqui esta el detalle: (0xD303) dice CUAL de las dos compilaciones de Antarctic es la de al lado
	or a			;5bb3
	ld hl,05bc7h		;5bb4
	jr z,L_5BBC		;5bb7
	ld hl,05bd1h		;5bb9
L_5BBC:
	ld a,b			;5bbc
	call L_626E		;5bbd
	ld a,(hl)			;5bc0
	ld (0e0e2h),a		;5bc1   ; porque la variable no vale lo mismo en las dos
	jp pon_las_vidas		;5bc4

; ----------------------------------------------------------------------
; DATOS fases_de_antarctic_1: RC-701 Antarctic Adventure: los diez valores que
;   hay que meterle en su (0xE0E2) para empezar en cada etapa. 0x5BB4 elige
;   esta tabla cuando (0xD303) esta a cero
;   0x5bc7..0x5bd1  (10 bytes)
DATA_fases_de_antarctic_1:
	defb 000h,006h,00dh,013h,01ah,022h,027h,02dh,033h,035h	; 5bc7  ....."'-35

; ----------------------------------------------------------------------
; DATOS fases_de_antarctic_2: Los mismos diez para la OTRA compilacion de
;   RC-701, la de la cabecera postiza de 0x606D. Que las dos listas sean
;   distintas -0x0D contra 0x0F en la tercera, 0x35 contra 0x3C en la ultima-
;   es la prueba de que Konami sabia que habia dos compilaciones circulando y
;   de que la variable no cae en el mismo sitio
;   0x5bd1..0x5bdb  (10 bytes)
DATA_fases_de_antarctic_2:
	defb 000h,007h,00fh,014h,01ah,020h,022h,02fh,035h,03ch	; 5bd1  ..... "/5<

; ======================================================================
; CODIGO 0x5bdb..0x5c14  (57 bytes)
; ======================================================================


L_5BDB:
	ld a,(0d31ah)		;5bdb   ; RC-710 y RC-711: la prueba pedida
	ld c,004h		;5bde   ; entre cuatro, que son las pruebas de cada Hyper Olympic
	call divide_a_entre_c		;5be0
	ld a,l			;5be3
	inc a			;5be4
	ld hl,(0d30ah)		;5be5   ; la primera va a la variable que dijo la cabecera
	ld (hl),a			;5be8
	ld (0e015h),a		;5be9
	dec a			;5bec
	push af			;5bed
	add a,a			;5bee
	ld b,a			;5bef
	ld hl,05c14h		;5bf0
	ld a,(0d301h)		;5bf3
	cp 010h		;5bf6   ; y aqui se distinguen los dos cartuchos, por el numero de catalogo
	jr z,L_5BFD		;5bf8
	ld hl,05c1ch		;5bfa
L_5BFD:
	ld a,b			;5bfd
	call L_626E		;5bfe
	ex de,hl			;5c01   ; la pareja de bytes
	pop af			;5c02
	ld b,a			;5c03
	add a,a			;5c04   ; por tres: tres bytes por prueba
	add a,b			;5c05
	ld hl,0e050h		;5c06   ; la marca de cada prueba va en 0xE050, tres bytes por prueba
	call L_626E		;5c09
	ex de,hl			;5c0c
	inc de			;5c0d
	ld bc,00002h		;5c0e   ; dos bytes, copiados
	ldir		;5c11
	ret			;5c13

; ----------------------------------------------------------------------
; DATOS pruebas_de_hyper_olympic_1: RC-710: cuatro palabras que 0x5BF0 copia a
;   la RAM del juego, una por prueba
;   0x5c14..0x5c1c  (8 bytes)
DATA_pruebas_de_hyper_olympic_1:
	defb 014h,000h	; 5c14
	defb 006h,000h	; 5c16
	defb 080h,000h	; 5c18
	defb 055h,000h	; 5c1a

; ----------------------------------------------------------------------
; DATOS pruebas_de_hyper_olympic_2: Lo mismo para RC-711. La eleccion la hace
;   el cp 0x10 de 0x5BF6 sobre (0xD301), que es el numero de catalogo: la
;   unica diferencia entre los dos cartuchos, para el Game Master, son estos
;   ocho bytes
;   0x5c1c..0x5c24  (8 bytes)
DATA_pruebas_de_hyper_olympic_2:
	defb 015h,000h	; 5c1c
	defb 075h,000h	; 5c1e
	defb 002h,030h	; 5c20
	defb 004h,030h	; 5c22

; ======================================================================
; CODIGO 0x5c24..0x5c71  (77 bytes)
; ======================================================================


L_5C24:
	call pon_las_vidas		;5c24   ; RC-712 Circus Charlie: primero las vidas
	ld a,(0d31ah)		;5c27
	ld l,a			;5c2a
	sub 005h		;5c2b   ; de la sexta en adelante hay que dar la vuelta: son cinco numeros
	jr c,L_5C35		;5c2d
	inc a			;5c2f
	ld c,005h		;5c30
	call divide_a_entre_c		;5c32
L_5C35:
	ld a,l			;5c35
	ld (0e052h),a		;5c36
	ret			;5c39
L_5C3A:
	call pon_las_vidas		;5c3a   ; RC-713 Magical Tree: vidas, y luego lo demas
	ld a,(0d31ah)		;5c3d
	ld b,a			;5c40
	dec a			;5c41
	ld (0e05ch),a		;5c42   ; el nivel, contando desde cero
	cp 008h		;5c45   ; pero para la tabla se topa en ocho
	jr c,L_5C4B		;5c47
	ld a,008h		;5c49
L_5C4B:
	ld hl,05c71h		;5c4b
	call L_626E		;5c4e
	ld a,(hl)			;5c51
	ld (0e05dh),a		;5c52
	ld a,08ah		;5c55   ; 0x8A fijo, sea cual sea el nivel
	ld (0e056h),a		;5c57
	ld a,b			;5c5a
	ld c,009h		;5c5b   ; entre nueve, que son los niveles
	call divide_a_entre_c		;5c5d
	ld a,l			;5c60
	add a,a			;5c61
	ld hl,05c7ah		;5c62
	call L_626E		;5c65
	ld de,0e054h		;5c68   ; y el marcador de partida, dos bytes, para que no empieces a cero
	ld bc,00002h		;5c6b
	ldir		;5c6e
	ret			;5c70

; ----------------------------------------------------------------------
; DATOS niveles_de_magical_tree: RC-713: nueve valores para su (0xE05D), uno
;   por nivel, que 0x5C4B mete indexando por el que se pida
;   0x5c71..0x5c7a  (9 bytes)
DATA_niveles_de_magical_tree:
	defb 077h,033h,0bbh,0eeh,011h,0bbh,0eeh,011h,011h	; 5c71  w3.......

; ----------------------------------------------------------------------
; DATOS marcador_de_magical_tree: Las nueve puntuaciones de partida, de dos
;   bytes, que 0x5C62 copia a (0xE054): el marcador con el que empiezas si te
;   saltas al nivel N, para que no quede en cero
;   0x5c7a..0x5c8c  (18 bytes)
DATA_marcador_de_magical_tree:
	defb 000h,000h	; 5c7a
	defb 070h,00ch	; 5c7c
	defb 020h,01ah	; 5c7e
	defb 050h,028h	; 5c80
	defb 030h,036h	; 5c82
	defb 0e0h,043h	; 5c84
	defb 040h,052h	; 5c86
	defb 0c0h,061h	; 5c88
	defb 0d0h,06eh	; 5c8a

; ======================================================================
; CODIGO 0x5c8c..0x5cc0  (52 bytes)
; ======================================================================


L_5C8C:
	jp pon_las_vidas		;5c8c   ; RC-714 Comic Bakery: solo las vidas, nada mas
L_5C8F:
	ld a,(0d31ah)		;5c8f   ; RC-715 Hyper Sports 1: la prueba, contando desde cero, en la variable de la cabecera
	dec a			;5c92
	jp L_5D16		;5c93
L_5C96:
	ld a,(0d31ah)		;5c96   ; RC-717 Hyper Sports 2: la prueba pedida
	ld c,003h		;5c99   ; entre TRES, que son las pruebas que trae este cartucho
	call divide_a_entre_c		;5c9b
	ld a,l			;5c9e
	jp L_5D16		;5c9f
L_5CA2:
	ld a,(0d31ah)		;5ca2   ; RC-718 Hyper Rally: la etapa pedida
	ld c,00dh		;5ca5   ; entre TRECE, que son las etapas del recorrido
	call divide_a_entre_c		;5ca7
	ld a,l			;5caa
	inc a			;5cab
	ld (0e060h),a		;5cac   ; la etapa, contando desde uno
	dec a			;5caf
	add a,a			;5cb0
	ld hl,05cc0h		;5cb1   ; y su pareja de bytes de la tabla, a 0xE05B
	call L_626E		;5cb4
	ld de,0e05bh		;5cb7
	ld bc,00002h		;5cba
	ldir		;5cbd
	ret			;5cbf

; ----------------------------------------------------------------------
; DATOS etapas_de_hyper_rally: RC-718: trece palabras que 0x5CB1 copia a su
;   (0xE05B)
;   0x5cc0..0x5cda  (26 bytes)
DATA_etapas_de_hyper_rally:
	defb 006h,080h	; 5cc0
	defb 006h,070h	; 5cc2
	defb 006h,070h	; 5cc4
	defb 006h,070h	; 5cc6
	defb 006h,060h	; 5cc8
	defb 006h,050h	; 5cca
	defb 006h,050h	; 5ccc
	defb 006h,050h	; 5cce
	defb 006h,060h	; 5cd0
	defb 006h,060h	; 5cd2
	defb 006h,050h	; 5cd4
	defb 006h,050h	; 5cd6
	defb 000h,080h	; 5cd8

; ======================================================================
; CODIGO 0x5cda..0x5d4c  (114 bytes)
; ======================================================================


L_5CDA:
	ld a,(0d31ah)		;5cda   ; RC-721 Sky Jaguar: la fase pedida
	ld c,008h		;5cdd   ; entre OCHO. Sky Jaguar no tiene fases separadas -es un solo recorrido continuo-, y lo que se escribe no es un numero de fase sino una POSICION: el resto por 256, o sea de 0x0000 a 0x0700 en saltos de 0x100
	call divide_a_entre_c		;5cdf
	ld h,l			;5ce2
	ld l,000h		;5ce3
	ld (0e1b8h),hl		;5ce5   ; la posicion dentro del recorrido
	jp pon_las_vidas		;5ce8
L_5CEB:
	call pon_las_vidas		;5ceb   ; RC-725 Yie Ar Kung-Fu: primero las vidas
	ld a,(0d31ah)		;5cee
	push af			;5cf1
	ld c,005h		;5cf2   ; el rival, entre cinco
	call divide_a_entre_c		;5cf4
	ld a,l			;5cf7
	ld (0e054h),a		;5cf8
	pop af			;5cfb
	cp 006h		;5cfc   ; de la sexta en adelante hay ademas una segunda vuelta que contar
	ret c			;5cfe
	ld b,a			;5cff
	sub 005h		;5d00
	cp 004h		;5d02   ; topada en tres
	jr c,L_5D08		;5d04
	ld a,003h		;5d06
L_5D08:
	ld (0e056h),a		;5d08
	ld a,b			;5d0b
	dec a			;5d0c
	and 003h		;5d0d   ; y los dos bits bajos del combate a 0xE059
	ld (0e059h),a		;5d0f
	ret			;5d12

; ----------------------------------------------------------------------
; PONER LAS VIDAS. Tres instrucciones, y es el truco que vale para todos: coge las vidas que ha pedido el usuario en (0xD31B) y las escribe en la direccion que dice (0xD30A), que es el puntero a la variable de vidas del juego y sale de su cabecera postiza. Por eso casi todas las rutinas de trucos acaban saltando aqui.
; ----------------------------------------------------------------------
pon_las_vidas:
	ld a,(0d31bh)		;5d13   ; las vidas que se han pedido
L_5D16:
	ld hl,(0d30ah)		;5d16   ; y el sitio donde el juego las guarda, que lo dijo la cabecera
	ld (hl),a			;5d19   ; escritas: ese es el truco entero
	ret			;5d1a
L_5D1B:
	ld a,(0d31ah)		;5d1b   ; RC-727 King's Valley: la sala pedida
	ld c,00fh		;5d1e   ; entre QUINCE, que son las piramides del juego
	call divide_a_entre_c		;5d20
	ld a,e			;5d23   ; el cociente es la vuelta
	ld (0e058h),a		;5d24
	ld a,l			;5d27
	inc a			;5d28
	ld (0e055h),a		;5d29   ; y el resto, la sala, contada desde uno en un sitio y desde cero en otro
	dec a			;5d2c
	ld (0e054h),a		;5d2d
	ld hl,05d4ch		;5d30   ; mas su pareja de la tabla de dieciseis
	add a,a			;5d33
	call L_626E		;5d34
	ld a,(hl)			;5d37
	ld (0e056h),a		;5d38
	inc hl			;5d3b
	ld a,(hl)			;5d3c
	ld (0e057h),a		;5d3d
	ld a,(0e055h)		;5d40   ; y solo en la sala 1 se conserva el valor; en las demas, cero
	cp 001h		;5d43
	jr z,L_5D48		;5d45
	xor a			;5d47
L_5D48:
	ld (0e051h),a		;5d48
	ret			;5d4b

; ----------------------------------------------------------------------
; DATOS salas_de_kings_valley: RC-727: dieciseis parejas que 0x5D30 reparte
;   entre (0xE056) y (0xE057)
;   0x5d4c..0x5d6c  (32 bytes)
DATA_salas_de_kings_valley:
	defb 008h,000h	; 5d4c
	defb 004h,008h	; 5d4e
	defb 004h,008h	; 5d50
	defb 001h,008h	; 5d52
	defb 008h,004h	; 5d54
	defb 008h,004h	; 5d56
	defb 004h,004h	; 5d58
	defb 004h,008h	; 5d5a
	defb 001h,008h	; 5d5c
	defb 008h,004h	; 5d5e
	defb 008h,004h	; 5d60
	defb 004h,004h	; 5d62
	defb 004h,008h	; 5d64
	defb 004h,008h	; 5d66
	defb 001h,002h	; 5d68
	defb 008h,004h	; 5d6a

; ======================================================================
; CODIGO 0x5d6c..0x5ee6  (378 bytes)
; ======================================================================


L_5D6C:
	ld a,(0d31ah)		;5d6c   ; RC-728 Mopi Ranger: la fase pedida, en BCD
	cp 033h		;5d6f   ; de la 33 en adelante se le restan 32: el juego solo cuenta hasta ahi
	jr c,L_5D75		;5d71
	sub 032h		;5d73
L_5D75:
	dec a			;5d75
	ld (0e053h),a		;5d76
	ld a,(0d31bh)		;5d79   ; y las vidas, tambien en BCD
	cp 051h		;5d7c   ; con el mismo tope, a partir de 51 se restan 50, y el `daa` arregla el BCD
	jr c,L_5D83		;5d7e
	sub 050h		;5d80
	daa			;5d82
L_5D83:
	ld (0e052h),a		;5d83
	ret			;5d86
L_5D87:
	ld a,(0d31ah)		;5d87   ; RC-729 Pippols: la fase pedida
	ld c,008h		;5d8a   ; entre OCHO
	call divide_a_entre_c		;5d8c
	ld a,l			;5d8f
	ld (0e103h),a		;5d90
	ld hl,000c0h		;5d93   ; y la posicion del recorrido, siempre a 0xC0
	ld (0e1b8h),hl		;5d96
	ret			;5d99
L_5D9A:
	ld a,(0d31ah)		;5d9a   ; RC-730 Road Fighter: la fase pedida
	ld c,006h		;5d9d   ; entre SEIS, que son los recorridos
	call divide_a_entre_c		;5d9f
	ld a,e			;5da2
	ld (0e042h),a		;5da3   ; la vuelta a 0xE042
	ld a,l			;5da6
	ld hl,(0d30ah)		;5da7   ; y el recorrido donde diga la cabecera
	ld (hl),a			;5daa
	call limpia_la_pantalla		;5dab   ; limpia la pantalla, que si no se queda la del menu
	ld a,004h		;5dae
	ld (0e001h),a		;5db0   ; dos valores fijos para arrancar la carrera
	ld a,008h		;5db3
	ld (0e000h),a		;5db5
	ret			;5db8
L_5DB9:
	call limpia_la_pantalla		;5db9   ; RC-732 Konami's Soccer: solo limpia y escribe un 7 donde diga (0xD304)
	ld hl,(0d304h)		;5dbc
	ld (hl),007h		;5dbf
	ret			;5dc1
L_5DC2:
	ld a,(0d31ah)		;5dc2   ; RC-733 Hyper Sports 3: la prueba menos uno, y ya
	dec a			;5dc5
	ld hl,(0d30ah)		;5dc6
	ld (hl),a			;5dc9
	ret			;5dca
L_5DCB:
	ld a,(0d31ah)		;5dcb   ; RC-736: la fase menos uno
	dec a			;5dce
	ld (0e206h),a		;5dcf
	call pon_las_vidas		;5dd2
	ld a,(0d31ah)		;5dd5
	ld c,003h		;5dd8   ; y ademas la parte con la vuelta en el nibble alto y la fase en el bajo
	call divide_a_entre_c		;5dda
	ld a,e			;5ddd
	and 00fh		;5dde
	rrca			;5de0
	rrca			;5de1
	rrca			;5de2
	rrca			;5de3
	add a,l			;5de4
	ld (0e207h),a		;5de5
	ld a,009h		;5de8
	ld hl,(0d304h)		;5dea   ; un 9 en la variable que dijo la cabecera
	ld (hl),a			;5ded
	jp limpia_la_pantalla		;5dee
L_5DF1:
	ld a,(0d31ah)		;5df1   ; RC-737 Yie Ar Kung-Fu 2: la fase pedida
	ld c,008h		;5df4   ; entre OCHO
	call divide_a_entre_c		;5df6
	ld a,l			;5df9
	ld hl,(0d30ah)		;5dfa
	ld (hl),a			;5dfd   ; el resto donde diga la cabecera
	ld a,e			;5dfe
	cp 002h		;5dff   ; y la vuelta, topada en dos
	jr c,L_5E05		;5e01
	ld a,002h		;5e03
L_5E05:
	ld (0e06ah),a		;5e05
	ld a,(0d31bh)		;5e08   ; aqui las vidas no pasan por pon_las_vidas: van directas a 0xE053
	ld (0e053h),a		;5e0b
	ret			;5e0e

; ----------------------------------------------------------------------
; DIVIDIR PARA SABER LA VUELTA Y LA PISTA. Divide (A-1) entre C por restas y desplazamientos, dieciseis vueltas, y deja el cociente en E y el resto en L. Sirve para los juegos cuyas fases se repiten en ciclos: pedir la 15 de un juego de diez pistas es la vuelta 1, pista 5.
; ----------------------------------------------------------------------
divide_a_entre_c:
	dec a			;5e0f
	ld e,a			;5e10
	ld d,000h		;5e11
	ld b,d			;5e13
	ld hl,00000h		;5e14
	exx			;5e17
	ld b,010h		;5e18   ; dieciseis vueltas, una por bit
L_5E1A:
	exx			;5e1a
	sla e		;5e1b   ; saca el bit de arriba del dividendo
	rl d		;5e1d
	adc hl,hl		;5e1f
	sbc hl,bc		;5e21   ; y prueba a restar: si no cabe, se devuelve
	jr c,L_5E28		;5e23
	inc e			;5e25
	jr L_5E29		;5e26
L_5E28:
	add hl,bc			;5e28
L_5E29:
	exx			;5e29
	djnz L_5E1A		;5e2a
	exx			;5e2c
	ret			;5e2d

; ----------------------------------------------------------------------
; DEJAR LA PANTALLA LIMPIA ANTES DE SOLTAR EL JUEGO. Borra las 768 casillas de la tabla de nombres y esconde los sprites poniendo 0xD0 en el primer byte de sus atributos, que es la marca de "aqui se acaba la lista". La llaman los trucos que dibujan algo antes de devolver el control.
; ----------------------------------------------------------------------
limpia_la_pantalla:		; La tabla de 0x5B02 manda aqui: veintiuna entradas de tres bytes -numero de catalogo en BCD y rutina- y cada rutina sabe DONDE tiene ese juego sus variables y QUE hay que escribirles. Dos juegos comparten rutina con otro y las dos veces por un motivo: RC-716 Cabbage Patch Kids usa la misma que RC-700 Athletic Land (0x5B7B) porque ES Athletic Land recompilado, y RC-711 Hyper Olympic 2 la misma que RC-710 (0x5BDB), que se distinguen dentro comparando (0xD301) con 0x10.
	ld hl,03800h		;5e2e
	xor a			;5e31
	ld bc,00300h		;5e32
	call 00056h		;5e35   ; BIOS FILVRM - Fills VRAM with value
	ld hl,03b00h		;5e38
	ld a,0d0h		;5e3b
	jp 0004dh		;5e3d   ; BIOS WRTVRM - Writes data in VRAM

; ----------------------------------------------------------------------
; IDENTIFICAR EL CARTUCHO DE AL LADO. Y detras, los tres arreglos por numero de catalogo que no caben en ninguna tabla.
; ----------------------------------------------------------------------
L_5E40:
	call L_5E64		;5e40
	ld a,(0d301h)		;5e43   ; el numero que acaba de averiguar
	ld b,a			;5e46
	cp 036h		;5e47   ; RC-736 lleva cuatro de algo, y se acabo
	jr nz,L_5E51		;5e49
	ld a,004h		;5e4b
	ld (0d312h),a		;5e4d
	ret			;5e50
L_5E51:
	ld a,b			;5e51
	sub 003h		;5e52   ; RC-703 y RC-704 -Time Pilot y Frogger-
	cp 002h		;5e54
	jr c,L_5E5E		;5e56
	ld a,b			;5e58
	sub 010h		;5e59   ; y RC-710 y RC-711 -los dos Hyper Olympic-
	cp 002h		;5e5b
	ret nc			;5e5d
L_5E5E:
	ld a,001h		;5e5e   ; llevan puesta la misma marca en 0xD339
	ld (0d339h),a		;5e60
	ret			;5e63

; ----------------------------------------------------------------------
; Primero por la segunda cabecera de 0x4010, "AB" o "CD"; y si no la lleva, por la suma de comprobacion.
; ----------------------------------------------------------------------
L_5E64:
	ld hl,06034h		;5e64   ; empieza por poner los 22 bytes POR DEFECTO de 0x6034: si el juego no dice nada, valen esos
	ld de,0d300h		;5e67
	ld bc,00016h		;5e6a
	ldir		;5e6d
	ld a,0ffh		;5e6f
	ld (0d313h),a		;5e71   ; y 0xFF en 0xD313, que es la marca de "no hay"
	ld hl,04010h		;5e74   ; lee 0x4010 del vecino
	call lee_palabra_del_vecino		;5e77
	ld hl,04241h		;5e7a   ; DCOMPR contra los bytes 41 42, o sea "AB": la cabecera vieja, 19 bytes
	rst 20h			;5e7d
	jr nz,L_5E8C		;5e7e
	ld hl,04012h		;5e80   ; con "AB" se traen 19 bytes tal cual a 0xD300: la cabecera vieja es un volcado, sin mas
	ld de,0d300h		;5e83
	ld bc,00013h		;5e86
	jp copia_del_vecino		;5e89
L_5E8C:
	ld hl,04443h		;5e8c   ; y si no, contra 43 44, o sea "CD": la nueva, 21 bytes
	rst 20h			;5e8f
	jr nz,$+98		;5e90
	ld hl,04012h		;5e92   ; con "CD" son 21, y NO van directos: se dejan aparte, en 0xD351, y se reparten
	ld de,0d351h		;5e95
	ld bc,00015h		;5e98
	call copia_del_vecino		;5e9b
	ld hl,0d352h		;5e9e   ; el numero de catalogo, que ese si va siempre
	ld de,0d301h		;5ea1
	ldi		;5ea4
	ld a,0ffh		;5ea6   ; 0xFF de relleno en el hueco de al lado
	ld (de),a			;5ea8
	inc de			;5ea9
	inc de			;5eaa
	ld a,(hl)			;5eab   ; y aqui esta la gracia del formato nuevo: un byte de BANDERAS, y cada `rra` saca un bit que dice si el campo que viene esta o no
	rra			;5eac
	jr c,L_5EBA		;5ead
	inc hl			;5eaf   ; el primer bit: dos bytes mas uno
	ld bc,00002h		;5eb0
	ldir		;5eb3
	ld de,0d312h		;5eb5
	ldi		;5eb8
L_5EBA:
	rra			;5eba   ; el segundo: el puntero de las vidas y uno mas
	jr c,L_5EC9		;5ebb
	ld de,0d30ah		;5ebd
	ldi		;5ec0
	ldi		;5ec2
	ld de,0d313h		;5ec4
	ldi		;5ec7
L_5EC9:
	ld ix,05ee6h		;5ec9   ; y los seis ultimos, uno por cada direccion de la lista de 0x5EE6
	ld b,006h		;5ecd
L_5ECF:
	push bc			;5ecf
	rra			;5ed0   ; bit puesto, campo que no viene: se deja el valor por defecto
	jr c,L_5EDE		;5ed1
	ld e,(ix+000h)		;5ed3   ; bit a cero, se copia el que trae el juego
	ld d,(ix+001h)		;5ed6
	ld bc,00002h		;5ed9
	ldir		;5edc
L_5EDE:
	pop bc			;5ede
	inc ix		;5edf
	inc ix		;5ee1
	djnz L_5ECF		;5ee3
	ret			;5ee5

; ----------------------------------------------------------------------
; DATOS variables_que_se_guardan: Seis direcciones de la RAM del propio Game
;   Master -0xD308, 0xD30C, 0xD30E, 0xD310, 0xD306 y 0xD314-. 0x5EC9 las
;   recorre con IX y va copiando dos bytes de cada una, o no, segun los bits
;   que le lleguen en A: el `rra` de 0x5ED0 saca uno por vuelta y el `ld
;   b,006h` de 0x5ECD dice que son seis
;   0x5ee6..0x5ef2  (12 bytes)
DATA_variables_que_se_guardan:
	defb 008h,0d3h	; 5ee6
	defb 00ch,0d3h	; 5ee8
	defb 00eh,0d3h	; 5eea
	defb 010h,0d3h	; 5eec
	defb 006h,0d3h	; 5eee
	defb 014h,0d3h	; 5ef0

; ======================================================================
; CODIGO 0x5ef2..0x5f3a  (72 bytes)
; ======================================================================


L_5EF2:
	ld a,(0d12fh)		;5ef2

; ----------------------------------------------------------------------
; LA FIRMA. Si no hay cabecera, suma los 256 bytes que van de 0x5000 a 0x50FF de la ROM del vecino y busca esa suma en la tabla de 0x5F3A.
; ----------------------------------------------------------------------
	ld de,00000h		;5ef5
	ld hl,05000h		;5ef8
	ld b,000h		;5efb
L_5EFD:
	push af			;5efd
	push bc			;5efe
	push de			;5eff
	call 0000ch		;5f00   ; BIOS RDSLT - Reads the value of an address in another slot | RDSLT byte a byte de la ranura del vecino
	pop de			;5f03
	pop bc			;5f04
	add a,e			;5f05   ; y los va sumando en DE, con el acarreo a D
	ld e,a			;5f06
	jr nc,L_5F0A		;5f07
	inc d			;5f09
L_5F0A:
	pop af			;5f0a
	inc hl			;5f0b
	djnz L_5EFD		;5f0c
	ld ix,05f3ah		;5f0e
L_5F12:
	ld l,(ix+000h)		;5f12   ; el siguiente par de la tabla de firmas
	ld h,(ix+001h)		;5f15
	ld a,l			;5f18
	or h			;5f19
	ret z			;5f1a   ; un cero cierra la tabla: se acabo sin encontrarlo
	rst 20h			;5f1b   ; DCOMPR de la suma contra cada firma de la tabla
	jr z,L_5F28		;5f1c
	inc ix		;5f1e
	inc ix		;5f20
	inc ix		;5f22
	inc ix		;5f24
	jr L_5F12		;5f26
L_5F28:
	push de			;5f28
	ld l,(ix+002h)		;5f29   ; acertada, coge el puntero a los 19 bytes de cabecera postiza
	ld h,(ix+003h)		;5f2c
	ld de,0d300h		;5f2f
	ld bc,00013h		;5f32
	ldir		;5f35
	pop de			;5f37
	scf			;5f38
	ret			;5f39

; ----------------------------------------------------------------------
; DATOS tabla_de_firmas: 62 compilaciones de 28 juegos: la suma de sus bytes
;   0x5000-0x50FF y el puntero a su cabecera. Termina en la palabra 0000
;   0x5f3a..0x6034  (250 bytes)
DATA_tabla_de_firmas:
	defw 05850h,06047h	; 5f3a
	defw 055a4h,06047h	; 5f3e
	defw 06aa9h,0605ah	; 5f42
	defw 06649h,0605ah	; 5f46
	defw 06cd5h,0606dh	; 5f4a
	defw 06661h,0605ah	; 5f4e
	defw 06803h,0606dh	; 5f52
	defw 065c5h,06080h	; 5f56
	defw 06640h,06080h	; 5f5a
	defw 05f17h,06080h	; 5f5e
	defw 05b7eh,06093h	; 5f62
	defw 05ce8h,06093h	; 5f66
	defw 05be9h,06093h	; 5f6a
	defw 06a4ch,060a6h	; 5f6e
	defw 05e17h,060b9h	; 5f72
	defw 05e0fh,060b9h	; 5f76  -> divide_a_entre_c 0x60b9
	defw 077bch,060cch	; 5f7a
	defw 07a37h,060cch	; 5f7e
	defw 07894h,060cch	; 5f82  -> DATA_titulo_rectangulo_3x20 0x60cc
	defw 06d5bh,060dfh	; 5f86
	defw 0774bh,060f2h	; 5f8a
	defw 07917h,060f2h	; 5f8e
	defw 07889h,060f2h	; 5f92
	defw 0766bh,06105h	; 5f96
	defw 0779fh,06105h	; 5f9a
	defw 077d5h,06105h	; 5f9e
	defw 06776h,06118h	; 5fa2
	defw 05b72h,0612bh	; 5fa6
	defw 05e21h,0612bh	; 5faa
	defw 04c65h,0612bh	; 5fae
	defw 06761h,0613eh	; 5fb2
	defw 06614h,0613eh	; 5fb6
	defw 068c6h,0613eh	; 5fba
	defw 047d4h,06151h	; 5fbe
	defw 083a4h,06164h	; 5fc2
	defw 06c2ch,06177h	; 5fc6
	defw 072a2h,0618ah	; 5fca
	defw 0711ch,0618ah	; 5fce
	defw 071a3h,0618ah	; 5fd2
	defw 076dch,0619dh	; 5fd6
	defw 04695h,061b0h	; 5fda  -> DATA_rotulos_del_dato 0x61b0
	defw 05e1eh,061c3h	; 5fde
	defw 05e35h,061c3h	; 5fe2
	defw 05eb0h,061c3h	; 5fe6
	defw 06876h,061d6h	; 5fea
	defw 057d8h,061d6h	; 5fee
	defw 057edh,061d6h	; 5ff2
	defw 06d85h,061e9h	; 5ff6
	defw 06ab8h,061e9h	; 5ffa
	defw 05d62h,061fch	; 5ffe
	defw 0643bh,061fch	; 6002
	defw 06518h,061fch	; 6006
	defw 0719ch,0620fh	; 600a
	defw 06b48h,0620fh	; 600e
	defw 068adh,06222h	; 6012
	defw 0678dh,06222h	; 6016
	defw 0682eh,06222h	; 601a
	defw 07402h,06235h	; 601e  -> L_7402 0x6235
	defw 06504h,06248h	; 6022
	defw 06907h,06248h	; 6026
	defw 06b22h,06248h	; 602a
	defw 087b8h,0625bh	; 602e
	defw 00000h	; 6032

; ----------------------------------------------------------------------
; DATOS cabecera_por_defecto: Los 22 bytes que se copian a 0xD300 cuando no se
;   sabe que juego hay: 0xD301 se queda en 0xFF, que no casa con ninguna
;   entrada
;   0x6034..0x604a  (22 bytes)
DATA_cabecera_por_defecto:
	defb 000h,0ffh,000h,000h,000h,000h,000h,000h	; 6034  ........
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 603c  ........
	defb 000h,000h,000h,007h,000h,000h	; 6044

; ----------------------------------------------------------------------
; DATOS cabeceras_postizas: Las 29 cabeceras de 19 bytes, en orden de numero
;   de catalogo, de RC-700 a RC-733. Los dos primeros bytes son el RC en BCD y
;   detras van los punteros a las variables del juego
;   0x604a..0x626e  (548 bytes)
DATA_cabeceras_postizas:
	defb 000h,000h,0e0h,002h,0e0h,050h,0e0h,051h,0e0h,040h,0e0h,043h,0e0h,046h,0e0h,009h,007h,001h,000h	; 604a  .....P.Q.@.C.F.....
	defb 000h,000h,0e0h,000h,000h,000h,000h,0e0h,0e0h,040h,0e0h,043h,0e0h,000h,000h,009h,007h,001h,000h	; 605d  .........@.C.......
	defb 001h,000h,0e0h,000h,000h,000h,000h,0e0h,0e0h,040h,0e0h,043h,0e0h,000h,000h,009h,007h,002h,000h	; 6070  .........@.C.......
	defb 000h,000h,0e0h,002h,0e0h,050h,0e0h,051h,0e0h,040h,0e0h,043h,0e0h,046h,0e0h,009h,007h,003h,000h	; 6083  .....P.Q.@.C.F.....
	defb 000h,002h,0e0h,000h,0e0h,002h,0e0h,000h,000h,011h,0e0h,00bh,0e0h,00eh,0e0h,003h,007h,004h,000h	; 6096  ...................
	defb 000h,002h,0e0h,000h,0e0h,002h,0e0h,000h,000h,011h,0e0h,00bh,0e0h,00eh,0e0h,003h,007h,005h,000h	; 60a9  ...................
	defb 000h,000h,0e0h,002h,0e0h,050h,0e0h,000h,000h,040h,0e0h,046h,0e0h,043h,0e0h,009h,007h,006h,000h	; 60bc  .....P...@.F.C.....
	defb 000h,000h,0e0h,002h,0e0h,050h,0e0h,000h,000h,040h,0e0h,043h,0e0h,046h,0e0h,009h,007h,007h,000h	; 60cf  .....P...@.C.F.....
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,007h,010h,000h	; 60e2  ...................
	defb 000h,062h,0e1h,01bh,0e0h,000h,000h,016h,0e0h,080h,0e0h,083h,0e0h,086h,0e0h,096h,007h,011h,000h	; 60f5  .b.................
	defb 000h,062h,0e1h,01bh,0e0h,000h,000h,016h,0e0h,080h,0e0h,083h,0e0h,086h,0e0h,09fh,007h,012h,000h	; 6108  .b.................
	defb 000h,000h,0e0h,002h,0e0h,050h,0e0h,051h,0e0h,043h,0e0h,049h,0e0h,046h,0e0h,009h,007h,013h,000h	; 611b  .....P.Q.C.I.F.....
	defb 000h,000h,0e0h,002h,0e0h,050h,0e0h,051h,0e0h,043h,0e0h,049h,0e0h,046h,0e0h,009h,007h,014h,000h	; 612e  .....P.Q.C.I.F.....
	defb 000h,000h,0e0h,002h,0e0h,050h,0e0h,051h,0e0h,043h,0e0h,049h,0e0h,046h,0e0h,009h,007h,015h,000h	; 6141  .....P.Q.C.I.F.....
	defb 000h,000h,0e0h,002h,0e0h,000h,000h,052h,0e0h,044h,0e0h,04ah,0e0h,047h,0e0h,009h,007h,016h,000h	; 6154  .......R.D.J.G.....
	defb 000h,000h,0e0h,002h,0e0h,050h,0e0h,051h,0e0h,046h,0e0h,049h,0e0h,04ch,0e0h,009h,007h,017h,000h	; 6167  .....P.Q.F.I.L.....
	defb 000h,000h,0e0h,000h,000h,000h,000h,080h,0e0h,060h,0e0h,063h,0e0h,000h,000h,004h,007h,018h,000h	; 617a  .........`.c.......
	defb 000h,000h,0e0h,000h,000h,000h,000h,060h,0e0h,055h,0e0h,058h,0e0h,000h,000h,004h,007h,020h,000h	; 618d  .......`.U.X..... .
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,007h,021h,000h	; 61a0  .................!.
	defb 000h,000h,0e0h,000h,000h,050h,0e0h,051h,0e0h,043h,0e0h,049h,0e0h,000h,000h,004h,007h,023h,000h	; 61b3  .....P.Q.C.I.....#.
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,007h,024h,000h	; 61c6  .................$.
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,007h,025h,000h	; 61d9  .................%.
	defb 000h,000h,0e0h,000h,000h,050h,0e0h,051h,0e0h,043h,0e0h,049h,0e0h,000h,000h,004h,007h,027h,000h	; 61ec  .....P.Q.C.I.....'.
	defb 000h,000h,0e0h,000h,000h,050h,0e0h,051h,0e0h,043h,0e0h,049h,0e0h,000h,000h,004h,007h,028h,000h	; 61ff  .....P.Q.C.I.....(.
	defb 000h,000h,0e0h,001h,0e0h,050h,0e0h,053h,0e0h,047h,0e0h,04dh,0e0h,000h,000h,004h,007h,029h,000h	; 6212  .....P.S.G.M.....).
	defb 000h,000h,0e0h,000h,000h,050h,0e0h,051h,0e0h,043h,0e0h,046h,0e0h,000h,000h,004h,007h,030h,000h	; 6225  .....P.Q.C.F.....0.
	defb 000h,000h,0e0h,002h,0e0h,000h,000h,043h,0e0h,03ch,0e0h,03fh,0e0h,000h,000h,003h,007h,031h,000h	; 6238  .......C.<.?.....1.
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,007h,033h,000h	; 624b  .................3.
	defb 000h,000h,0e0h,002h,0e0h,000h,000h,06ah,0e0h,060h,0e0h,066h,0e0h,063h,0e0h,004h	; 625e  .......j.`.f.c..

; ======================================================================
; CODIGO 0x626e..0x6284  (22 bytes)
; ======================================================================


L_626E:
	add a,l			;626e
	ld l,a			;626f
	ret nc			;6270
	inc h			;6271
	ret			;6272
L_6273:
	ld hl,06284h		;6273
	ld bc,00800h		;6276
L_6279:
	push bc			;6279
	ld b,(hl)			;627a
	call 00047h		;627b   ; BIOS WRTVDP - Writes data in the VDP-register
	pop bc			;627e
	inc hl			;627f
	inc c			;6280
	djnz L_6279		;6281
	ret			;6283

; ----------------------------------------------------------------------
; DATOS registros_del_vdp: Los ocho primeros registros del VDP, que 0x6273
;   escribe seguidos empezando por el 0: 0x02 modo grafico 2, 0xE2 pantalla y
;   sprites de 16x16, 0x0E nombres en 0x3800, 0x7F color, 0x07 patrones, 0x76
;   atributos de sprite en 0x3B00, 0x03 patrones de sprite en 0x1800 y 0xE1 el
;   borde. Son ocho porque ocho dice el ld bc,00800h de 0x6276, cuya B es la
;   cuenta. OJO con el 3 y el 4: no son direcciones sino base y mascara, y
;   salen AL REVES de lo que parece -el color acaba en 0x0000 y los patrones
;   en 0x2000-, que es lo que coloca los cuatro bloques comprimidos del menu
;   0x6284..0x628c  (8 bytes)
DATA_registros_del_vdp:
	defb 002h,0e2h,00eh,07fh,007h,076h,003h,0e1h	; 6284  .....v..

; ----------------------------------------------------------------------
; DATOS cuatro_bytes_sin_dueno: 0x0E, 0x00, 0x18 y 0x06, pegados detras de los
;   registros del VDP. El bucle de 0x6279 no llega a ellos -para a los ocho- y
;   nadie mas los carga: buscados los cuatro bytes por todo el cartucho, no
;   hay ni una referencia. Parecen dos registros mas de otra version
;   0x628c..0x6290  (4 bytes)
DATA_cuatro_bytes_sin_dueno:
	defb 00eh,000h,018h,006h	; 628c

; ======================================================================
; CODIGO 0x6290..0x6445  (437 bytes)
; ======================================================================


L_6290:
	ld c,0ffh		;6290
	jr L_629A		;6292

; ----------------------------------------------------------------------
; PINTAR UN BLOQUE DE ROTULOS. Lee la direccion de VRAM, escribe caracteres hasta un 0xFE y vuelve a empezar; el 0xFF cierra.
; LA FUENTE NO USA EL 0x20. Las letras estan donde el ASCII, pero el hueco entre palabras es el 0x00 y el 0x40 es el hueco RESALTADO con el que se enmarcan los titulos: "@@MENU@@" sale como un rotulo con fondo. Los mensajes los cierra un 0xFF, salvo los que se copian con una longitud fija en BC. tools/cadenas.py los recorre y comprueba que la ultima de cada grupo acaba justo donde el presupuesto cierra el hueco.
; ----------------------------------------------------------------------
pinta_rotulos:
	ld c,0ffh		;6294
L_6296:
	ld e,(hl)			;6296
	inc hl			;6297
	ld d,(hl)			;6298
	inc hl			;6299
L_629A:
	ld a,(hl)			;629a
	inc hl			;629b
	ld b,a			;629c   ; el byte leido
	inc b			;629d   ; con 0xFF se acabo el bloque
	ret z			;629e
	inc b			;629f   ; y con 0xFE, hay otro trozo detras
	jr z,L_6296		;62a0
	and c			;62a2   ; la mascara, que es lo que distingue las dos puertas de esta rutina
	ex de,hl			;62a3
	call 0004dh		;62a4   ; BIOS WRTVRM - Writes data in VRAM
	ex de,hl			;62a7
	inc de			;62a8
	jr L_629A		;62a9
L_62AB:
	ld hl,03800h		;62ab
	ld bc,00300h		;62ae
	xor a			;62b1
	call 00056h		;62b2   ; BIOS FILVRM - Fills VRAM with value
	ld hl,03b00h		;62b5
	ld a,0d0h		;62b8
	jp 0004dh		;62ba   ; BIOS WRTVRM - Writes data in VRAM
L_62BD:
	ld d,003h		;62bd
L_62BF:
	push bc			;62bf
	push de			;62c0
	call 00056h		;62c1   ; BIOS FILVRM - Fills VRAM with value
	ld bc,00800h		;62c4
	add hl,bc			;62c7
	pop de			;62c8
	pop bc			;62c9
	dec d			;62ca
	jr nz,L_62BF		;62cb
	ret			;62cd
L_62CE:
	ld a,003h		;62ce

; ----------------------------------------------------------------------
; COPIAR A LOS TRES TERCIOS. Suma 0x800 al destino en cada vuelta, que es lo que separa los tercios de SCREEN 2. Casi todo lo que este cartucho pinta pasa por aqui.
; ----------------------------------------------------------------------
a_los_tres_tercios:
	push af			;62d0
	push bc			;62d1
	push hl			;62d2
	push de			;62d3
	call 0005ch		;62d4   ; BIOS LDIRVM - Block transfers to VRAM from memory | el bloque, a la VRAM
	pop de			;62d7
	ld hl,00800h		;62d8   ; y 0x800 mas: el tercio siguiente
	add hl,de			;62db
	ex de,hl			;62dc
	pop hl			;62dd
	pop bc			;62de
	pop af			;62df
	dec a			;62e0   ; tres veces
	jr nz,a_los_tres_tercios		;62e1
	ret			;62e3

; ----------------------------------------------------------------------
; CARGAR LOS TRES TERCIOS. Llama al descompresor tres veces, sumando 0x800 al destino: los tres tercios de SCREEN 2.
; ----------------------------------------------------------------------
L_62E4:
	ld b,003h		;62e4

; ----------------------------------------------------------------------
; DESCOMPRIMIR A LOS TRES TERCIOS. Igual que 0x62D0 pero con el descompresor: el MISMO bloque se suelta tres veces, sumando 0x800. Los tres tercios de SCREEN 2 quedan identicos, que es como Konami monta casi todas sus pantallas.
; ----------------------------------------------------------------------
descomprime_tres_tercios:
	push bc			;62e6
	push hl			;62e7
	push de			;62e8
	call L_62FB		;62e9   ; la puerta del descompresor a la que el destino le llega en DE
	pop de			;62ec
	ld hl,00800h		;62ed   ; y 0x800 mas para el tercio siguiente
	add hl,de			;62f0
	ex de,hl			;62f1
	pop hl			;62f2
	pop bc			;62f3
	djnz descomprime_tres_tercios		;62f4
	ret			;62f6

; ----------------------------------------------------------------------
; EL DESCOMPRESOR. Lee del bloque la direccion de VRAM, y va soltando tiradas por el puerto de datos: bit 7 puesto, tantos bytes literales; a cero, un byte repetido. Cuenta cero, se acabo.
; ----------------------------------------------------------------------
descomprime_a_vram:
	ld e,(hl)			;62f7
	inc hl			;62f8
	ld d,(hl)			;62f9
	inc hl			;62fa
L_62FB:
	ex de,hl			;62fb
	call 00053h		;62fc   ; BIOS SETWRT - Enables VDP to write
	ex de,hl			;62ff
	ld a,(00006h)		;6300
	ld c,a			;6303
L_6304:
	ld a,(hl)			;6304
	and 07fh		;6305   ; los siete bits bajos son la cuenta
	ld b,a			;6307
	ld a,(hl)			;6308
	inc hl			;6309
	jr nz,L_6310		;630a   ; cuenta cero: o se acabo el bloque, o viene otro destino detras
	cp b			;630c
	jr nz,descomprime_a_vram		;630d
	ret			;630f
L_6310:
	cp b			;6310   ; comparar el byte entero con la cuenta dice si el bit 7 estaba puesto: si son iguales, no lo estaba
	jr z,L_631E		;6311
L_6313:
	ld a,(hl)			;6313
	inc hl			;6314
	out (c),a		;6315   ; out (c),a: los bytes van DIRECTOS al puerto del VDP, sin pasar por la BIOS. Por eso este descompresor es tan rapido
	inc de			;6317
	push hl			;6318   ; el push/pop no hace nada: es la espera que el VDP necesita entre byte y byte
	pop hl			;6319
	djnz L_6313		;631a
	jr L_6304		;631c
L_631E:
	ld a,(hl)			;631e
	inc hl			;631f
L_6320:
	out (c),a		;6320   ; out (c),a: el byte repetido, directo al puerto del VDP
	inc de			;6322
	push ix		;6323   ; y el push/pop de espera, aqui con IX
	pop ix		;6325
	djnz L_6320		;6327
	jr L_6304		;6329
L_632B:
	push bc			;632b
	ld b,000h		;632c
	push af			;632e
	call 00056h		;632f   ; BIOS FILVRM - Fills VRAM with value
	pop af			;6332
	ld bc,00020h		;6333
	add hl,bc			;6336
	pop bc			;6337
	djnz L_632B		;6338
	ret			;633a

; ----------------------------------------------------------------------
; BINARIO A BCD. Doble dabble de dieciseis vueltas: cada `daa` detras del `adc a,a` arregla el acarreo de nibble. Hace falta porque los marcadores de los juegos van en BCD y las fases se cuentan en binario.
; ----------------------------------------------------------------------
a_bcd:
	ld b,010h		;633b
	ld de,00000h		;633d
L_6340:
	add hl,hl			;6340   ; la cifra de arriba
	ld a,e			;6341
	adc a,a			;6342
	daa			;6343   ; el `daa` detras del `adc` es lo que arregla el acarreo de nibble: sin el, el resultado no seria BCD
	ld e,a			;6344
	ld a,d			;6345
	adc a,a			;6346
	daa			;6347
	ld d,a			;6348
	djnz L_6340		;6349   ; dieciseis vueltas, una por bit
	ret			;634b

; ----------------------------------------------------------------------
; BCD A BINARIO. El camino de vuelta, para un solo byte: el nibble alto por diez -a+a por cuatro mas a+a, que es lo mismo- mas el bajo.
; ----------------------------------------------------------------------
a_binario:
	ld c,a			;634c
	and 0f0h		;634d   ; el nibble alto
	rrca			;634f
	rrca			;6350
	rrca			;6351
	rrca			;6352
	add a,a			;6353   ; por dos
	ld b,a			;6354
	add a,a			;6355   ; por ocho
	add a,a			;6356
	add a,b			;6357   ; y sumados: por diez
	ld b,a			;6358
	ld a,c			;6359
	and 00fh		;635a
	add a,b			;635c   ; mas el nibble bajo
	ret			;635d
L_635E:
	ld bc,00613h		;635e
	ld hl,(0d16eh)		;6361
	xor a			;6364
	jp L_632B		;6365

; ----------------------------------------------------------------------
; DESPACHAR. `pop hl` recoge la direccion de retorno, que es el byte de DESPUES del CALL, y de ahi lee la palabra numero A y salta. O sea que la tabla de punteros va PEGADA al `call 0x6368`, dentro del flujo de codigo: son catorce, y las declara el .entries con !tabla.
; ----------------------------------------------------------------------
L_6368:
	pop hl			;6368   ; la direccion de retorno ES la tabla
	add a,a			;6369   ; por dos, que son punteros
	add a,l			;636a
	ld l,a			;636b
	jr nc,L_636F		;636c
	inc h			;636e
L_636F:
	ld e,(hl)			;636f
	inc hl			;6370
	ld d,(hl)			;6371
	ex de,hl			;6372
	jp (hl)			;6373   ; y se salta

; ----------------------------------------------------------------------
; GUARDARSE LA PANTALLA DEL JUEGO. Antes de pintar nada encima hay que llevarse a la RAM lo que habia: patrones, color, casillas y el primer atributo de sprite. Es la pareja de 0x63E9, que la devuelve. (0xD12A) marca que hay algo guardado, para no guardarlo dos veces.
; ----------------------------------------------------------------------
salva_la_pantalla:
	ld hl,0d12ah		;6374
	ld a,(hl)			;6377
	or a			;6378   ; si ya hay una guardada, no se toca
	ret nz			;6379
	dec a			;637a
	ld (hl),a			;637b   ; y se marca
	ld de,0d8b1h		;637c
	ld hl,01000h		;637f
	ld bc,00080h		;6382   ; los patrones, 0x80 bytes por tercio
	call L_63D6		;6385
	ld de,0d500h		;6388
	ld hl,01180h		;638b
	ld bc,00158h		;638e   ; el color, 0x158
	call L_63D6		;6391
	ld hl,03a00h		;6394
	ld de,0d7b0h		;6397
	ld bc,00100h		;639a
	call 00059h		;639d   ; BIOS LDIRMV - Block transfers to memory from VRAM | las 256 casillas
	ld hl,03b00h		;63a0
	ld de,0d8b0h		;63a3
	ld bc,00001h		;63a6
	call 00059h		;63a9   ; BIOS LDIRMV - Block transfers to memory from VRAM | y un byte de atributos: el que esconde los sprites
	ld hl,01000h		;63ac
	ld bc,00008h		;63af
	ld a,055h		;63b2   ; y encima se deja un 0x55 de trama, que es el fondo del cartucho
	call 00056h		;63b4   ; BIOS FILVRM - Fills VRAM with value
	call L_644F		;63b7
	ld hl,050d0h		;63ba
	ld de,03180h		;63bd
	call L_62FB		;63c0
	ld hl,01180h		;63c3
	ld a,0f5h		;63c6
	ld bc,00158h		;63c8
	call 00056h		;63cb   ; BIOS FILVRM - Fills VRAM with value
	ld hl,03b00h		;63ce
	ld a,0d0h		;63d1
	jp 0004dh		;63d3   ; BIOS WRTVRM - Writes data in VRAM
L_63D6:
	push bc			;63d6
	push de			;63d7
	push hl			;63d8
	call 00059h		;63d9   ; BIOS LDIRMV - Block transfers to memory from VRAM
	pop hl			;63dc
	ld bc,02000h		;63dd
	add hl,bc			;63e0
	pop de			;63e1
	pop bc			;63e2
	ex de,hl			;63e3
	add hl,bc			;63e4
	ex de,hl			;63e5
	jp 00059h		;63e6   ; BIOS LDIRMV - Block transfers to memory from VRAM

; ----------------------------------------------------------------------
; DEVOLVER LA PANTALLA DEL CARTUCHO. Vuelve a poner en la VRAM lo que estaba antes: los patrones, el color, las casillas y el primer atributo de sprite. Solo hace algo si (0xD12A) dice que hay algo que devolver.
; ----------------------------------------------------------------------
L_63E9:
	ld hl,0d12ah		;63e9
	ld a,(hl)			;63ec
	or a			;63ed
	ret z			;63ee   ; si no hay nada guardado, no se toca la VRAM
	xor a			;63ef
	ld (hl),a			;63f0   ; y se marca que ya se devolvio
	call L_644F		;63f1
	ld hl,0d8b1h		;63f4   ; los patrones, 0x80 bytes por tercio
	ld de,01000h		;63f7
	ld bc,00080h		;63fa
	call L_6424		;63fd
	ld hl,0d500h		;6400   ; el color, 0x158
	ld de,01180h		;6403
	ld bc,00158h		;6406
	call L_6424		;6409
	ld hl,0d7b0h		;640c   ; las 256 casillas de la tabla de nombres
	ld de,03a00h		;640f
	ld bc,00100h		;6412
	call 0005ch		;6415   ; BIOS LDIRVM - Block transfers to VRAM from memory
	ld hl,0d8b0h		;6418   ; y un solo byte de atributos: el que esconde los sprites
	ld de,03b00h		;641b
	ld bc,00001h		;641e
	jp 0005ch		;6421   ; BIOS LDIRVM - Block transfers to VRAM from memory
L_6424:
	push bc			;6424   ; COPIAR A LOS TRES TERCIOS, sumando 0x2000 cada vez
	push hl			;6425
	push de			;6426
	call 0005ch		;6427   ; BIOS LDIRVM - Block transfers to VRAM from memory
	pop hl			;642a
	ld bc,02000h		;642b
	add hl,bc			;642e
	pop de			;642f
	pop bc			;6430
	ex de,hl			;6431
	add hl,bc			;6432
	jp 0005ch		;6433   ; BIOS LDIRVM - Block transfers to VRAM from memory
L_6436:
	ld a,(0d13dh)		;6436
	or a			;6439
	ret z			;643a
	jp salva_la_pantalla		;643b
L_643E:
	ld a,(0d13dh)		;643e
	or a			;6441
	ret z			;6442
	jr L_63E9		;6443

; ----------------------------------------------------------------------
; DATOS codigo_muerto_1: `ld a,(0D16Dh) / cp 03Ah / ld hl,03900h / jr c,...`:
;   elegia una direccion de la tabla de nombres segun una variable
;   0x6445..0x644f  (10 bytes)

; ----------------------------------------------------------------------
; CODIGO AL QUE NO LLEGA NADIE. Cuatro trozos que desensamblan a Z80 correcto y encajado -empiezan justo detras de un `ret` y acaban justo donde arranca una etiqueta que si se usa-, pero a los que no apunta nada: buscadas sus direcciones por los 16384 bytes del cartucho, no aparece ni una referencia de 16 bits ni un salto relativo que caiga en ellos. No es el espejismo de leer un operando como opcode, porque no caen dentro de otra instruccion; son restos de una compilacion anterior. De este cartucho hay tres.
; ----------------------------------------------------------------------
DATA_codigo_muerto_1:
	defb 03ah,06dh,0d1h,0feh,03ah,021h,000h,039h,038h,003h	; 6445  :m..:!.98.

; ======================================================================
; CODIGO 0x644f..0x6561  (274 bytes)
; ======================================================================


L_644F:
	ld hl,03a00h		;644f
	ld bc,00100h		;6452
	xor a			;6455
	jp 00056h		;6456   ; BIOS FILVRM - Fills VRAM with value
L_6459:
	ld (0d167h),a		;6459
	or a			;645c
	ld a,b			;645d
	jr nz,L_6462		;645e
	ld a,008h		;6460
L_6462:
	ld (0d164h),a		;6462
	ld (0d168h),hl		;6465
	ld (0d16ah),hl		;6468
	call L_6569		;646b
	call L_652B		;646e
L_6471:
	call 0009fh		;6471   ; BIOS CHGET - One character input (waiting)
	cp 00dh		;6474
	ld b,a			;6476
	jr nz,L_6481		;6477
	ld a,(0d165h)		;6479
	ld (0d163h),a		;647c
	or a			;647f
	ret			;6480
L_6481:
	cp 01dh		;6481
	jr z,L_6489		;6483
	cp 008h		;6485
	jr nz,L_64AE		;6487
L_6489:
	call L_6578		;6489
	ld a,(0d165h)		;648c   ; lo que hay escrito
	ld hl,0d141h		;648f
	call L_626E		;6492
	ld a,(hl)			;6495
	sub 03ch		;6496   ; el 0x3C es el hueco: si lo que se borra era un hueco, se apunta
	jr nz,L_649D		;6498
	ld (0d166h),a		;649a
L_649D:
	ld hl,0d165h		;649d
	dec (hl)			;64a0   ; y el cursor retrocede
	call L_6571		;64a1
	dec hl			;64a4
	ld (0d168h),hl		;64a5
	call L_6569		;64a8
	jp L_6471		;64ab

; ----------------------------------------------------------------------
; EL PUNTO Y LA MARCA DE FINAL. Al teclear, el 0x2E -el punto- se trata aparte: solo vale si lo anterior era el separador, y se convierte en la casilla 0x3C.
; ----------------------------------------------------------------------
L_64AE:
	cp 02eh		;64ae   ; el punto
	jr nz,L_64C9		;64b0
	ld a,(0d167h)		;64b2
	cp 0feh		;64b5   ; solo despues del separador
	jp nz,L_6471		;64b7
	call L_6578		;64ba
	ld a,03ch		;64bd   ; la casilla 0x3C es como se dibuja
	ld hl,0d166h		;64bf
	cp (hl)			;64c2
	jp z,L_6471		;64c3   ; y no se admiten dos seguidos
	ld (hl),a			;64c6
	jr L_64F3		;64c7
L_64C9:
	ld c,a			;64c9
	sub 030h		;64ca   ; las cifras
	cp 00ah		;64cc
	jr nc,L_64D3		;64ce
	ld a,c			;64d0
	jr L_64F3		;64d1
L_64D3:
	ld a,c			;64d3
	sub 041h		;64d4   ; y las mayusculas
	cp 01ah		;64d6
	jr nc,L_64E6		;64d8
	ld a,c			;64da
L_64DB:
	ex af,af'			;64db
	ld a,(0d167h)		;64dc   ; con 0xFF en 0xD167 no se admite mas
	inc a			;64df
	jp z,L_6471		;64e0
	ex af,af'			;64e3
	jr L_64F3		;64e4
L_64E6:
	ld a,c			;64e6
	sub 061h		;64e7   ; las minusculas
	cp 01ah		;64e9
	jp nc,L_6471		;64eb
	ld a,c			;64ee
	sub 020h		;64ef   ; menos 0x20: pasadas a mayusculas, que es lo unico que tiene la fuente
	jr L_64DB		;64f1

; ----------------------------------------------------------------------
; UNA LETRA MAS EN LO QUE SE ESCRIBE. Avanza el cursor y, la primera vez, borra los catorce caracteres de la linea para que no quede lo de antes.
; ----------------------------------------------------------------------
L_64F3:
	ld b,a			;64f3
	ld hl,0d165h		;64f4
	ld a,(0d164h)		;64f7
	cp (hl)			;64fa   ; con el tope alcanzado no se admite mas
	jp z,L_6471		;64fb
	inc (hl)			;64fe
	ld a,(hl)			;64ff
	cp 001h		;6500
	jr nz,L_6510		;6502
	push bc			;6504
	ld hl,(0d16ah)		;6505
	ld bc,0000eh		;6508
	xor a			;650b
	call 00056h		;650c   ; BIOS FILVRM - Fills VRAM with value | catorce caracteres borrados, solo al escribir el primero
	pop bc			;650f
L_6510:
	ld hl,(0d168h)		;6510   ; donde va la letra
	ld a,b			;6513
	call 0004dh		;6514   ; BIOS WRTVRM - Writes data in VRAM | se escribe
	inc hl			;6517
	ld (0d168h),hl		;6518   ; y el cursor avanza
	call L_6569		;651b
	ld a,(0d165h)		;651e
	ld hl,0d141h		;6521   ; ademas se guarda en 0xD141, que es el buffer de lo tecleado
	call L_626E		;6524
	ld (hl),b			;6527
	jp L_6471		;6528

; ----------------------------------------------------------------------
; EMPEZAR A TECLEAR DE CERO. Borra los 32 bytes del buffer, pinta el cursor y vacia el teclado, que si no se cuela la tecla con la que se llego aqui.
; ----------------------------------------------------------------------
L_652B:
	ld hl,0d142h		;652b
	ld de,0d143h		;652e
	ld (hl),000h		;6531   ; los 32 bytes del buffer, a cero
	ld bc,0001fh		;6533
	ldir		;6536
	call L_6549		;6538
	call 00156h		;653b   ; BIOS KILBUF - Clears keyboard buffer | vacia el buffer del teclado
	xor a			;653e
	ld (0d163h),a		;653f   ; y los tres contadores de escritura
	ld (0d165h),a		;6542
	ld (0d166h),a		;6545
	ret			;6548
L_6549:
	ld hl,06561h		;6549   ; los ocho bytes del cursor van a la VRAM 0x21D0 o a la 0x31D0 segun (0xD13D), que dice si hay juego al lado o no
	ld bc,00008h		;654c
	ld a,(0d13dh)		;654f
	or a			;6552
	jr nz,L_655B		;6553
	ld de,021d0h		;6555
	jp L_62CE		;6558
L_655B:
	ld de,031d0h		;655b
	jp 0005ch		;655e   ; BIOS LDIRVM - Block transfers to VRAM from memory

; ----------------------------------------------------------------------
; DATOS ocho_bytes_de_borrado: Un cero y siete 0x7F, que 0x6549 lleva con
;   bc=0x0008 a un sitio u otro segun (0xD13D)
;   0x6561..0x6569  (8 bytes)
DATA_ocho_bytes_de_borrado:
	defb 000h,07fh,07fh,07fh,07fh,07fh,07fh,07fh	; 6561  ........

; ======================================================================
; CODIGO 0x6569..0x6676  (269 bytes)
; ======================================================================


L_6569:
	ld hl,(0d168h)		;6569   ; PINTAR EL CURSOR: la casilla 0x3A en el sitio que dice (0xD168)
	ld a,03ah		;656c
	jp 0004dh		;656e   ; BIOS WRTVRM - Writes data in VRAM
L_6571:
	ld hl,(0d168h)		;6571   ; Y BORRARLO: la misma casilla a cero
	xor a			;6574
	jp 0004dh		;6575   ; BIOS WRTVRM - Writes data in VRAM
L_6578:
	ld a,(0d165h)		;6578
	or a			;657b
	ret nz			;657c
	pop hl			;657d
	jp L_6471		;657e

; ----------------------------------------------------------------------
; ELEGIR UNA OPCION. Recibe en HL la lista de SITIOS del menu -una direccion de la tabla de nombres por linea- y en B cuantas lineas tiene. Guarda B-1 como tope en (0xD164), mueve el cursor con las flechas y devuelve en A la linea elegida al pulsar ESPACIO. Las trece llamadas de este cartucho son las que dan el tamano de cada bloque de sitios: tools/menus.py las lee.
; ----------------------------------------------------------------------
L_6581:
	ld a,b			;6581
	dec a			;6582
	ld (0d164h),a		;6583   ; el tope, que es una linea menos que las que hay
	ld (0d16ah),hl		;6586   ; la lista de sitios, guardada
	ld a,(hl)			;6589   ; y el primero, que es donde arranca el cursor
	inc hl			;658a
	ld h,(hl)			;658b
	ld l,a			;658c
	ld (0d168h),hl		;658d
	call L_6569		;6590   ; se pinta
	call L_65E3		;6593
L_6596:
	call 0009fh		;6596   ; BIOS CHGET - One character input (waiting) | y a esperar tecla
	cp 020h		;6599   ; ESPACIO elige
	ld b,a			;659b
	jr nz,L_65A9		;659c
	call L_6571		;659e   ; se borra el cursor
	ld a,(0d165h)		;65a1
	ld (0d163h),a		;65a4   ; y la linea elegida se deja en 0xD163 y en A
	or a			;65a7
	ret			;65a8
L_65A9:
	ld c,0ffh		;65a9   ; arriba: menos uno
	cp 01eh		;65ab
	jr z,L_65B6		;65ad
	ld c,001h		;65af   ; abajo: mas uno
	cp 01fh		;65b1
	jp nz,L_6596		;65b3   ; cualquier otra tecla no hace nada
L_65B6:
	ld hl,0d164h		;65b6
	ld de,0d165h		;65b9
	ld a,(de)			;65bc
	add a,c			;65bd   ; la linea de ahora, mas o menos uno
	jp p,L_65C2		;65be   ; si se pasa por abajo, se va a la ultima
	ld a,(hl)			;65c1
L_65C2:
	cp (hl)			;65c2   ; y si se pasa por arriba, a la primera: el menu da la vuelta por los dos lados
	jr c,L_65C8		;65c3
	jr z,L_65C8		;65c5
	xor a			;65c7
L_65C8:
	ld (de),a			;65c8
	ld b,a			;65c9
	ld hl,(0d16ah)		;65ca   ; se busca el sitio de la linea nueva
	add a,a			;65cd
	call L_626E		;65ce
	ld a,(hl)			;65d1
	inc hl			;65d2
	ld h,(hl)			;65d3
	ld l,a			;65d4
	push hl			;65d5
	call L_6571		;65d6   ; se borra el cursor de donde estaba
	pop hl			;65d9
	ld (0d168h),hl		;65da
	call L_6569		;65dd   ; y se pinta donde va ahora
	jp L_6596		;65e0
L_65E3:
	call L_65F4		;65e3
	call 00156h		;65e6   ; BIOS KILBUF - Clears keyboard buffer
	xor a			;65e9
	ld (0d163h),a		;65ea
	ld (0d165h),a		;65ed
	ld (0d166h),a		;65f0
	ret			;65f3
L_65F4:
	ld hl,05120h		;65f4
	ld bc,00008h		;65f7
	ld a,(0d13dh)		;65fa   ; con juego al lado el cursor va a un sitio, y sin el, a otro
	or a			;65fd
	jr nz,L_6606		;65fe
	ld de,021d0h		;6600
	jp L_62CE		;6603
L_6606:
	ld de,031d0h		;6606
	jp 0005ch		;6609   ; BIOS LDIRVM - Block transfers to VRAM from memory

; ----------------------------------------------------------------------
; CARGAR UNA PANTALLA DE DISCO. Las diez rutinas de esta zona siguen todas el mismo guion: guardar la pila en (0xD127), pedir sitio al disco, hacer la operacion, y devolver el sitio. Lo que cambia es la funcion del BDOS y cuantos bytes.
; ----------------------------------------------------------------------
L_660C:
	ld (0d127h),sp		;660c   ; la pila, aparcada: el BDOS va a usar la suya
	call sitio_para_el_disco		;6610
	call L_6967		;6613   ; crea el fichero
	call L_691B		;6616
	call L_6725		;6619   ; y le mete la pantalla
	call L_67CB		;661c
	di			;661f
	ld hl,00000h		;6620   ; se copian los 0x82 bytes de la propia pila a 0xC000, que es lo unico que queda a salvo
	add hl,sp			;6623
	push hl			;6624
	ld hl,00000h		;6625
	add hl,sp			;6628
	ld de,0c000h		;6629
	ld bc,00082h		;662c
	ldir		;662f
	pop hl			;6631
	ei			;6632
	ld hl,00082h		;6633
	call lee_del_disco		;6636   ; y se leen los 0x82 del fichero
	pop hl			;6639
	call L_6977		;663a   ; cerrado
	call L_68F0		;663d
	call L_6957		;6640   ; y borrado el temporal
	call L_691B		;6643
	call L_6756		;6646
	jp sitio_recuperado		;6649   ; el disco ya no hace falta

; ----------------------------------------------------------------------
; GUARDAR EL RANKING EN DISCO. La unica que le pone al nombre la extension VRM a mano, porque el ranking no es un dato del juego sino del cartucho.
; ----------------------------------------------------------------------
L_664C:
	ld (0d127h),sp		;664c
	call sitio_para_el_disco		;6650
	ld hl,0d100h		;6653
	ld (0d125h),hl		;6656   ; el bloque de control
	call L_68F0		;6659
	ld de,0d109h		;665c
	ld hl,06676h		;665f   ; y la extension VRM
	ld bc,00003h		;6662
	ldir		;6665
	call L_6967		;6667
	call L_691B		;666a
	call L_67F5		;666d
	call L_6977		;6670
	jp sitio_recuperado		;6673

; ----------------------------------------------------------------------
; DATOS extension_vrm: "VRM", la extension de los ficheros que guarda el
;   cartucho. 0x665F la copia a (0xD109), justo detras de la inicial
;   0x6676..0x6679  (3 bytes)
DATA_extension_vrm:
	defb 056h,052h,04dh	; 6676

; ======================================================================
; CODIGO 0x6679..0x6787  (270 bytes)
; ======================================================================


L_6679:
	ld (0d127h),sp		;6679   ; GUARDAR EL RANKING
	call sitio_para_el_disco		;667d
	call L_6967		;6680
	call L_691B		;6683
	call L_56F5		;6686   ; se recogen los datos
	call L_6733		;6689   ; y se escriben
	call L_6977		;668c
	jp sitio_recuperado		;668f
L_6692:
	ld (0d127h),sp		;6692   ; GUARDAR LOS DATOS DEL JUEGO
	call sitio_para_el_disco		;6696
	call L_6967		;6699
	call L_691B		;669c
	call L_6741		;669f
	call L_6977		;66a2
	jp sitio_recuperado		;66a5
L_66A8:
	ld (0d127h),sp		;66a8   ; GUARDAR LA PANTALLA Y LA PILA. Es la unica que ademas salva 0x80 bytes de la pila del juego
	call sitio_para_el_disco		;66ac
	call L_6957		;66af
	call L_691B		;66b2
	ld hl,01100h		;66b5
	call L_694A		;66b8   ; 0x1100 bytes de trabajo
	call L_67A3		;66bb
	ld hl,00082h		;66be
	call escribe_en_disco		;66c1   ; al disco
	ld hl,(0c000h)		;66c4
	ld sp,hl			;66c7   ; y la pila se recupera de 0xC000, donde 0x6620 la habia dejado
	ld de,0c002h		;66c8
	ex de,hl			;66cb
	ld bc,00080h		;66cc
	ldir		;66cf
	ld hl,00000h		;66d1
	call L_694A		;66d4
	call L_6756		;66d7
	call L_4E76		;66da   ; calla el PSG y guarda los volumenes: al volver, el juego sigue como estaba
	call L_4E85		;66dd
	jp sitio_recuperado		;66e0
L_66E3:
	ld (0d127h),sp		;66e3   ; CARGAR LA PANTALLA, 0x1100 bytes
	call sitio_para_el_disco		;66e7
	call L_6957		;66ea
	call L_691B		;66ed
	ld hl,01100h		;66f0
	call L_694A		;66f3
	call L_67A3		;66f6
	jp sitio_recuperado		;66f9
L_66FC:
	ld (0d127h),sp		;66fc   ; CARGAR EL RANKING
	call sitio_para_el_disco		;6700
	call L_6957		;6703
	call L_691B		;6706
	call L_6764		;6709
	call L_5653		;670c
	jp sitio_recuperado		;670f
L_6712:
	ld (0d127h),sp		;6712   ; y cargar los datos del juego
	call sitio_para_el_disco		;6716
	call L_6957		;6719
	call L_691B		;671c
	call L_6772		;671f
	jp sitio_recuperado		;6722
L_6725:
	ld de,0c000h		;6725
	ld c,01ah		;6728
	call 0f37dh		;672a
	ld hl,01100h		;672d
	jp lee_del_disco		;6730
L_6733:
	ld de,0d459h		;6733
	ld c,01ah		;6736
	call 0f37dh		;6738
	ld hl,00078h		;673b
	jp lee_del_disco		;673e
L_6741:
	ld hl,(0d30ch)		;6741   ; los datos del juego, 0x2000 mas abajo de donde dice su cabecera
	ld bc,02000h		;6744
	and a			;6747
	sbc hl,bc		;6748
	ex de,hl			;674a
	ld c,01ah		;674b
	call 0f37dh		;674d   ; el buffer, al BDOS
	ld hl,00003h		;6750
	jp lee_del_disco		;6753   ; y se leen
L_6756:
	ld de,0c000h		;6756
	ld c,01ah		;6759
	call 0f37dh		;675b
	ld hl,01100h		;675e
	jp escribe_en_disco		;6761
L_6764:
	ld de,0d459h		;6764
	ld c,01ah		;6767
	call 0f37dh		;6769
	ld hl,00078h		;676c
	jp escribe_en_disco		;676f
L_6772:
	ld hl,(0d30ch)		;6772   ; lo mismo para escribir
	ld bc,02000h		;6775
	and a			;6778
	sbc hl,bc		;6779
	ex de,hl			;677b
	ld c,01ah		;677c
	call 0f37dh		;677e
	ld hl,00003h		;6781
	jp escribe_en_disco		;6784

; ----------------------------------------------------------------------
; DATOS codigo_muerto_2: Dos copias casi iguales de `ld de,0C000h / ld c,01Ah
;   / call 0F37Dh / ld hl,01000h / jp ...`, o sea dos llamadas al BDOS del
;   disco que acaban saltando a 0x6997 y a 0x6987, que si son codigo vivo
;   0x6787..0x67a3  (28 bytes)
DATA_codigo_muerto_2:
	defb 011h,000h,0c0h,00eh,01ah,0cdh,07dh,0f3h,021h,000h,010h,0c3h,097h,069h	; 6787  ......}.!....i
	defb 011h,000h,0c0h,00eh,01ah,0cdh,07dh,0f3h,021h,000h,010h,0c3h,087h,069h	; 6795  ......}.!....i

; ======================================================================
; CODIGO 0x67a3..0x68da  (311 bytes)
; ======================================================================


L_67A3:
	ld de,00000h		;67a3

; ----------------------------------------------------------------------
; GUARDAR LA PANTALLA ENTERA EN DISCO. Ocho pasadas de 0x800 bytes, que son los 16 KB de VRAM.
; ----------------------------------------------------------------------
L_67A6:
	push de			;67a6
	call L_69CF		;67a7
	push hl			;67aa
	ld de,0c000h		;67ab
	ld c,01ah		;67ae   ; le dice al BDOS donde esta el buffer
	call 0f37dh		;67b0
	pop hl			;67b3
	call escribe_en_disco		;67b4   ; y escribe el bloque
	pop de			;67b7
	ld hl,0c000h		;67b8
	push de			;67bb
	call L_62FB		;67bc   ; de paso lo descomprime a la VRAM, para que se vea lo que se esta guardando
	pop de			;67bf
	ld a,008h		;67c0
	add a,d			;67c2
	ld d,a			;67c3
	cp 040h		;67c4   ; hasta 0x40, que por 0x800 son los 16 KB enteros
	jr nz,L_67A6		;67c6
	jp L_6273		;67c8   ; y al acabar, los registros del VDP otra vez
L_67CB:
	ld hl,00000h		;67cb

; ----------------------------------------------------------------------
; Y LEERLA DE VUELTA. La misma cuenta al reves: 0x800 bytes cada vez hasta completar la VRAM.
; ----------------------------------------------------------------------
L_67CE:
	push hl			;67ce
	ld de,0c802h		;67cf
	ld bc,00800h		;67d2
	call 00059h		;67d5   ; BIOS LDIRMV - Block transfers to memory from VRAM | LDIRMV saca de la VRAM a la RAM
	call L_6DBA		;67d8
	ld de,0c000h		;67db
	ld c,01ah		;67de
	call 0f37dh		;67e0
	ld hl,(0c000h)		;67e3
	inc hl			;67e6
	inc hl			;67e7
	call lee_del_disco		;67e8   ; y se lee el bloque del disco
	pop hl			;67eb
	ld a,008h		;67ec
	add a,h			;67ee
	ld h,a			;67ef
	cp 040h		;67f0
	jr nz,L_67CE		;67f2
	ret			;67f4

; ----------------------------------------------------------------------
; GUARDAR SOLO LO QUE IMPORTA DE LA VRAM. En vez de los 16 KB enteros, las cuatro zonas que de verdad llevan algo: color, nombres, patrones y patrones de sprite.
; ----------------------------------------------------------------------
L_67F5:
	ld a,0feh		;67f5
	call L_69AC		;67f7
	ld hl,00000h		;67fa
	call L_69C6		;67fd
	ld hl,03fffh		;6800
	call L_69C6		;6803
	ld hl,00000h		;6806
	call L_69C6		;6809
	ld hl,02000h		;680c   ; el color, tres tercios
	ld b,003h		;680f
	call L_6829		;6811
	ld hl,03800h		;6814   ; la tabla de nombres, uno
	ld b,001h		;6817
	call L_6829		;6819
	ld hl,00000h		;681c   ; los patrones, tres
	ld b,003h		;681f
	call L_6829		;6821
	ld hl,01800h		;6824   ; y los de sprite, uno
	ld b,001h		;6827

; ----------------------------------------------------------------------
; UNA ZONA DE VRAM AL DISCO, de 0x800 en 0x800 y B veces.
; ----------------------------------------------------------------------
L_6829:
	push bc			;6829
	push hl			;682a
	ld de,0c000h		;682b
	ld bc,00800h		;682e
	push bc			;6831
	push de			;6832
	call 00059h		;6833   ; BIOS LDIRMV - Block transfers to memory from VRAM | se saca de la VRAM
	pop de			;6836
	ld c,01ah		;6837
	call 0f37dh		;6839   ; se le pasa al BDOS
	pop hl			;683c
	call lee_del_disco		;683d   ; y al disco
	pop hl			;6840
	ld a,008h		;6841
	add a,h			;6843
	ld h,a			;6844
	pop bc			;6845
	djnz L_6829		;6846
	ret			;6848

; ----------------------------------------------------------------------
; HACERLE SITIO AL DISCO. El Disk BASIC vive en la pagina 3, justo donde este cartucho tiene su RAM, asi que antes de tocar el disco hay que apartarse: se bajan 0x1100 bytes con LDDR -de atras adelante, porque los dos trozos se solapan- y se intercambia el bloque de trabajo. Todas las rutinas de disco empiezan por aqui y acaban en 0x6860.
; ----------------------------------------------------------------------
sitio_para_el_disco:
	di			;6849
	call intercambia_bloques		;684a   ; intercambia el bloque de trabajo con el de 0xC000
	ld hl,0f0ffh		;684d
	ld de,0f37fh		;6850
	ld bc,01100h		;6853
	lddr		;6856   ; LDDR y no LDIR: el origen y el destino se pisan
	ld hl,00000h		;6858
	ld (0f1c0h),hl		;685b   ; y la variable de error, a cero
	ei			;685e
	ret			;685f

; ----------------------------------------------------------------------
; Y DEVOLVERLE EL SITIO. Trae de vuelta los 0x1100 bytes que estaban aparcados en 0xE280 y deshace el intercambio.
; ----------------------------------------------------------------------
sitio_recuperado:
	di			;6860
	ld hl,0e280h		;6861   ; los 0x1100 bytes que estaban aparcados
	ld de,0e000h		;6864
	ld bc,01100h		;6867
	ldir		;686a
	call intercambia_bloques		;686c   ; y se deshace el intercambio
	ei			;686f
	ret			;6870

; ----------------------------------------------------------------------
; INTERCAMBIAR DOS BLOQUES DE 0x1100 BYTES sin usar memoria de mas: byte a byte, guardando uno en B mientras se escribe el otro. Es lo que permite tener a la vez la RAM del cartucho y la del Disk BASIC en las mismas direcciones.
; ----------------------------------------------------------------------
intercambia_bloques:
	ld hl,0e000h		;6871
	ld de,0c000h		;6874
	ld bc,01100h		;6877
L_687A:
	push bc			;687a
	ld b,(hl)			;687b   ; el truco para intercambiar sin memoria de mas: uno se guarda en B mientras se escribe el otro
	ld a,(de)			;687c
	ld (hl),a			;687d
	ld a,b			;687e
	ld (de),a			;687f
	pop bc			;6880
	inc hl			;6881
	inc de			;6882
	dec bc			;6883   ; hasta acabar los 0x1100
	ld a,b			;6884
	or c			;6885
	jr nz,L_687A		;6886
	ret			;6888

; ----------------------------------------------------------------------
; MONTAR EL NOMBRE DEL FICHERO. Lo deja en 0xD100 con el formato que pide el BDOS: ocho caracteres de nombre, tres de extension y el resto del bloque de control a cero. El nombre no lo teclea entero el usuario: la primera letra la pone el cartucho segun el dato, y la extension es siempre VRM.
; ----------------------------------------------------------------------
monta_el_nombre:
	xor a			;6889
	call L_6459		;688a
	ld a,(0d163h)		;688d
	or a			;6890
	ret z			;6891
	ld hl,0d100h		;6892
	ld (0d125h),hl		;6895
	ld d,h			;6898
	ld e,l			;6899
	ld (hl),020h		;689a   ; rellena de espacios los ocho del nombre
	inc de			;689c
	ld bc,00008h		;689d
	ldir		;68a0
	xor a			;68a2
	ld (de),a			;68a3   ; y de ceros los 0x1B siguientes, que es el resto del bloque de control
	inc hl			;68a4
	inc de			;68a5
	ld bc,0001bh		;68a6
	ldir		;68a9
	ld de,0d100h		;68ab
	ld (de),a			;68ae
	inc de			;68af
	ld a,(0d163h)		;68b0   ; lo que haya tecleado el usuario
	ld c,a			;68b3
	ld b,000h		;68b4
	ld hl,0d142h		;68b6
	ldir		;68b9
	call L_68C2		;68bb   ; y delante, la inicial y la extension
	ld a,0ffh		;68be
	or a			;68c0
	ret			;68c1
L_68C2:
	ld de,0d109h		;68c2
	ld hl,068dah		;68c5
	ld a,(0d136h)		;68c8
	and 00fh		;68cb
	call L_626E		;68cd
	ldi		;68d0   ; la inicial: H, S, G o R segun el dato
	ld a,(0d301h)		;68d2   ; y detras, el numero de catalogo del juego, para que dos juegos no se pisen los ficheros
	ex de,hl			;68d5
	call bcd_a_dos_letras		;68d6
	ret			;68d9

; ----------------------------------------------------------------------
; DATOS iniciales_del_dato: H, S, G y R: la inicial con la que empieza el
;   nombre del fichero segun el dato -HI SCORE, SCREEN, GAME y RANKING-.
;   0x68C5 la elige con el nibble bajo de (0xD136) y la mete en (0xD109) con
;   un `ldi`, y detras va la extension VRM
;   0x68da..0x68de  (4 bytes)
DATA_iniciales_del_dato:
	defb 048h,053h,047h,052h	; 68da

; ======================================================================
; CODIGO 0x68de..0x6904  (38 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; UN BYTE BCD A DOS CARACTERES. Le pega un 0x30 a cada nibble, que es lo que convierte una cifra en su letra. Es lo que hace que los numeros del cartucho se puedan escribir en pantalla.
; ----------------------------------------------------------------------
bcd_a_dos_letras:
	ld d,a			;68de
	and 0f0h		;68df
	rrca			;68e1
	rrca			;68e2
	rrca			;68e3
	rrca			;68e4
	or 030h		;68e5   ; el nibble alto, mas 0x30
	ld (hl),a			;68e7
	inc hl			;68e8
	ld a,d			;68e9
	and 00fh		;68ea
	or 030h		;68ec   ; y el bajo
	ld (hl),a			;68ee
	ret			;68ef

; ----------------------------------------------------------------------
; LIMPIAR EL RESTO DEL BLOQUE DE CONTROL. Los 0x18 bytes que van detras del nombre, a cero: el BDOS los quiere asi.
; ----------------------------------------------------------------------
L_68F0:
	ld hl,0d10ch		;68f0
	ld de,0d10dh		;68f3   ; los 0x18 bytes que van detras del nombre
	ld (hl),000h		;68f6
	ld bc,00018h		;68f8   ; y a cero
	ldir		;68fb
	ret			;68fd
L_68FE:
	ld a,(0ffa7h)		;68fe
	cp 0c9h		;6901
	ret			;6903

; ----------------------------------------------------------------------
; DATOS codigo_muerto_3: Guardaba DE en (0xD125) y borraba un bloque; su
;   ultima instruccion, `ld (0D125h),hl`, encadena con 0x691B, que si se llama
;   desde ocho sitios
;   0x6904..0x691b  (23 bytes)
DATA_codigo_muerto_3:
	defb 0edh,053h,025h,0d1h,0afh,012h,013h,001h,00bh,000h,0edh,0b0h	; 6904  .S%.........
	defb 0afh,006h,019h,012h,013h,010h,0fch,0c9h,022h,025h,0d1h	; 6910  ........"%.

; ======================================================================
; CODIGO 0x691b..0x6938  (29 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; PREPARAR EL BLOQUE DE CONTROL DEL FICHERO. Rellena los campos que el BDOS mira: el tamano de registro a 1 y los cinco del final a cero.
; ----------------------------------------------------------------------
L_691B:
	ld hl,(0d125h)		;691b
	ld bc,0000ch		;691e
	add hl,bc			;6921
	ld (hl),b			;6922   ; los dos bytes de extension, a cero
	inc hl			;6923
	ld (hl),b			;6924
	inc hl			;6925
	ld bc,00001h		;6926
	ld (hl),c			;6929   ; tamano de registro: uno
	inc hl			;692a
	ld (hl),b			;692b
	ld bc,00011h		;692c
	add hl,bc			;692f
	ld b,005h		;6930   ; y los cinco ultimos, a cero
	xor a			;6932
L_6933:
	ld (hl),a			;6933
	inc hl			;6934
	djnz L_6933		;6935
	ret			;6937

; ----------------------------------------------------------------------
; DATOS codigo_muerto_4: Leia por (0xD125) mas 0x10 y devolvia lo que hubiera
;   alli; acaba en un `jr` que cae dentro de codigo vivo
;   0x6938..0x694a  (18 bytes)
DATA_codigo_muerto_4:
	defb 02ah,025h,0d1h,001h,010h,000h,009h,07eh,023h,066h,06fh,0c9h	; 6938  *%.....~#fo.
	defb 0edh,053h,025h,0d1h,018h,004h	; 6944

; ======================================================================
; CODIGO 0x694a..0x6a08  (190 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL TAMANO DEL FICHERO. Lo escribe en el byte 0x21 del bloque de control, que es donde el BDOS lo espera.
; ----------------------------------------------------------------------
L_694A:
	ld de,(0d125h)		;694a
	ex de,hl			;694e
	ld bc,00021h		;694f
	add hl,bc			;6952   ; el desplazamiento 0x21 dentro del bloque de control
	ld (hl),e			;6953
	inc hl			;6954
	ld (hl),d			;6955
	ret			;6956

; ----------------------------------------------------------------------
; BORRAR UN FICHERO. Funcion 0x0F del BDOS. Los tres codigos de error que salen de aqui -0, 1 y 2- son los que 0x6A19 usa para elegir mensaje.
; ----------------------------------------------------------------------
L_6957:
	ld de,(0d125h)		;6957
	ld c,00fh		;695b   ; la funcion 0x0F
	call 0f37dh		;695d
	ld c,000h		;6960
	inc a			;6962   ; con 0xFF, error
	jp z,L_69DA		;6963
	ret			;6966

; ----------------------------------------------------------------------
; CREARLO. Funcion 0x16, y el codigo de error es el 1.
; ----------------------------------------------------------------------
L_6967:
	ld de,(0d125h)		;6967
	ld c,016h		;696b
	call 0f37dh		;696d
	ld c,001h		;6970   ; y el codigo de error 1, por si falla
	inc a			;6972
	jp z,L_69DA		;6973
	ret			;6976

; ----------------------------------------------------------------------
; Y CERRARLO. Funcion 0x10, con el codigo 2.
; ----------------------------------------------------------------------
L_6977:
	ld de,(0d125h)		;6977
	ld c,010h		;697b
	call 0f37dh		;697d
	ld c,002h		;6980   ; aqui el codigo es el 2
	inc a			;6982
	jp z,L_69DA		;6983
	ret			;6986

; ----------------------------------------------------------------------
; ESCRIBIR EN EL DISCO. Funcion 0x27 del BDOS -escritura aleatoria-, llamada por 0xF37D, que es la puerta del Disk BASIC. Con error, se sale por 0x69DA con el codigo 3.
; ----------------------------------------------------------------------
escribe_en_disco:
	ld de,(0d125h)		;6987   ; el bloque de control
	ld c,027h		;698b   ; la funcion 0x27 del BDOS
	call 0f37dh		;698d
	ld c,003h		;6990   ; y el codigo de error 3
	or a			;6992
	jp nz,L_69DA		;6993
	ret			;6996

; ----------------------------------------------------------------------
; LEER DEL DISCO. La funcion 0x26, la hermana de la de arriba. El codigo de error es el 4.
; ----------------------------------------------------------------------
lee_del_disco:
	ld de,(0d125h)		;6997   ; el bloque de control
	ld c,026h		;699b   ; la funcion 0x26
	call 0f37dh		;699d
	ld c,004h		;69a0   ; y el codigo 4
	or a			;69a2
	jp nz,L_69DA		;69a3
	ret			;69a6
L_69A7:
	ld bc,escribe_en_disco		;69a7
	jr L_69AF		;69aa
L_69AC:
	ld bc,lee_del_disco		;69ac
L_69AF:
	push af			;69af
	ld hl,00001h		;69b0
	add hl,sp			;69b3   ; el buffer, que aqui es la propia pila
	push bc			;69b4
	ex de,hl			;69b5
	ld c,01ah		;69b6   ; antes de cada operacion hay que decirle al BDOS donde esta el buffer: funcion 0x1A
	call 0f37dh		;69b8
	pop bc			;69bb
	call L_69C1		;69bc   ; y la operacion que toque, leer o escribir
	pop af			;69bf
	ret			;69c0
L_69C1:
	ld hl,00001h		;69c1
	push bc			;69c4
	ret			;69c5
L_69C6:
	push hl			;69c6
	ld a,l			;69c7   ; el byte bajo
	call L_69AC		;69c8
	pop hl			;69cb
	ld a,h			;69cc   ; y el alto
	jr L_69AC		;69cd

; ----------------------------------------------------------------------
; LEER DOS BYTES DEL FICHERO, uno detras de otro, y juntarlos en HL: es como se lee el tamano de lo guardado.
; ----------------------------------------------------------------------
L_69CF:
	call L_69A7		;69cf
	ld l,a			;69d2
	push hl			;69d3
	call L_69A7		;69d4
	pop hl			;69d7
	ld h,a			;69d8   ; juntos en HL
	ret			;69d9

; ----------------------------------------------------------------------
; EL AVISO DE ERROR DE DISCO. Se le devuelve el sitio al cartucho, se repinta el marco y se saca el mensaje que toque segun el codigo que haya dejado el BDOS.
; ----------------------------------------------------------------------
L_69DA:
	push bc			;69da
	call sitio_recuperado		;69db   ; lo primero, recuperar la RAM propia
	call L_6436		;69de
	call L_4616		;69e1
	call L_466E		;69e4
	call L_44F9		;69e7
	ld hl,06a08h		;69ea   ; "@@DISK ERROR@@" de titulo
	ld de,(0d16eh)		;69ed
	push de			;69f1
	call L_6290		;69f2
	pop hl			;69f5
	ld bc,00040h		;69f6
	add hl,bc			;69f9
	ex de,hl			;69fa
	pop bc			;69fb
	call L_6A17		;69fc   ; y debajo, el error concreto
	call L_643E		;69ff
L_6A02:
	ld sp,(0d127h)		;6a02   ; la pila que 0x6849 habia guardado, y se sale con carry
	scf			;6a06
	ret			;6a07

; ----------------------------------------------------------------------
; DATOS texto_disk_error: "@@DISK ERROR@@", el titulo del aviso. Lo pintan
;   0x69EA y 0x6B17
;   0x6a08..0x6a17  (15 bytes)
DATA_texto_disk_error:
	defb 040h,040h,044h,049h,053h,04bh,000h,045h,052h,052h,04fh,052h,040h,040h,0ffh	; 6a08  @@DISK.ERROR@@.

; ======================================================================
; CODIGO 0x6a17..0x6a3f  (40 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL MENSAJE DEL ERROR CONCRETO. C trae el codigo, la tabla de 0x6A4E da el texto, y debajo va siempre "HIT RETURN KEY".
; ----------------------------------------------------------------------
L_6A17:
	ld a,c			;6a17
	add a,a			;6a18   ; el codigo por dos, que son punteros
	ld hl,06a4eh		;6a19
	call L_626E		;6a1c
	ld a,(hl)			;6a1f
	inc hl			;6a20
	ld h,(hl)			;6a21
	ld l,a			;6a22
	push de			;6a23
	call L_6290		;6a24
	pop hl			;6a27
	ld bc,00040h		;6a28
	add hl,bc			;6a2b
	ld de,06a3fh		;6a2c   ; y el pie, siempre el mismo
	ex de,hl			;6a2f
	call L_6290		;6a30
	call 00156h		;6a33   ; BIOS KILBUF - Clears keyboard buffer | vacia el buffer del teclado
L_6A36:
	ld a,007h		;6a36   ; y espera a que pulsen
	call 00141h		;6a38   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	rla			;6a3b
	jr c,L_6A36		;6a3c
	ret			;6a3e

; ----------------------------------------------------------------------
; DATOS texto_hit_return_key: "HIT RETURN KEY", el pie del aviso. Lo pinta
;   0x6A2C
;   0x6a3f..0x6a4e  (15 bytes)
DATA_texto_hit_return_key:
	defb 048h,049h,054h,000h,052h,045h,054h,055h,052h,04eh,000h,04bh,045h,059h,0ffh	; 6a3f  HIT.RETURN.KEY.

; ----------------------------------------------------------------------
; DATOS punteros_de_errores_de_disco: Seis punteros a los cinco mensajes de
;   abajo. 0x6A19 los indexa por el codigo de error que devuelve la ROM de
;   disco, y la tercera y la quinta apuntan al mismo: dos codigos distintos
;   dan "DISK FULL"
;   0x6a4e..0x6a5a  (12 bytes)
DATA_punteros_de_errores_de_disco:
	defb 05ah,06ah	; 6a4e
	defb 06bh,06ah	; 6a50
	defb 07ch,06ah	; 6a52
	defb 088h,06ah	; 6a54
	defb 07ch,06ah	; 6a56
	defb 09ah,06ah	; 6a58

; ----------------------------------------------------------------------
; DATOS errores_de_disco: =FILE NOT FOUND=, =TOO MANY FILES=, =DISK FULL=,
;   =DISK READ ERROR= y =DISK IO ERROR=. Los cinco cierran con 0xFF y el
;   ultimo acaba clavado en 0x6AAA, que es donde el presupuesto cierra el
;   hueco: esa es la comprobacion de que el formato es este y no otro
;   0x6a5a..0x6aaa  (80 bytes)
DATA_errores_de_disco:
	defb 03dh,046h,049h,04ch,045h,000h,04eh,04fh,054h,000h,046h,04fh,055h,04eh,044h,03dh,0ffh	; 6a5a  =FILE.NOT.FOUND=.
	defb 03dh,054h,04fh,04fh,000h,04dh,041h,04eh,059h,000h,046h,049h,04ch,045h,053h,03dh,0ffh	; 6a6b  =TOO.MANY.FILES=.
	defb 03dh,044h,049h,053h,04bh,000h,046h,055h,04ch,04ch,03dh,0ffh,03dh,044h,049h,053h,04bh	; 6a7c  =DISK.FULL=.=DISK
	defb 000h,052h,045h,041h,044h,000h,045h,052h,052h,04fh,052h,03dh,0ffh,03dh,044h,049h,053h	; 6a8d  .READ.ERROR=.=DIS
	defb 04bh,000h,049h,04fh,000h,045h,052h,052h,04fh,052h,03dh,0ffh	; 6a9e  K.IO.ERROR=.

; ======================================================================
; CODIGO 0x6aaa..0x6b86  (220 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; MONTAR LA LLAMADA ENTRE RANURAS. Se copia la plantilla de trece bytes a 0xD33E y se le rellenan los huecos: la ranura propia y la direccion a la que hay que ir. Hace falta porque con el juego puesto en la pagina 1 este cartucho no esta, y para llamarse a si mismo tiene que hacerlo desde la RAM.
; MONTAR LA LLAMADA ENTRE RANURAS. Copia la plantilla de 0x6AD0 a la RAM y le rellena la ranura y la direccion que llega en HL.
; ----------------------------------------------------------------------
L_6AAA:
	ex de,hl			;6aaa
	ld hl,0d33eh		;6aab
	push hl			;6aae
	ld (0d33ch),hl		;6aaf   ; el enganche del RST 30h, que la BIOS lee de 0xD0A3
	ld hl,0d33ch		;6ab2
	ld (0d0a3h),hl		;6ab5
	pop hl			;6ab8
	push de			;6ab9
	ld de,L_6AD0		;6aba
	ld bc,0000dh		;6abd   ; trece bytes de plantilla
	ex de,hl			;6ac0
	ldir		;6ac1
	ld hl,0d343h		;6ac3   ; y se le encajan la ranura...
	ld a,(0d12eh)		;6ac6
	ld (hl),a			;6ac9
	inc hl			;6aca
	pop de			;6acb
	ld (hl),e			;6acc   ; ...y la direccion, que son los tres ceros que la plantilla dejo en medio
	inc hl			;6acd
	ld (hl),d			;6ace
	ret			;6acf
L_6AD0:
	push iy		;6ad0   ; se salvan los dos indices
	push ix		;6ad2
	rst 30h			;6ad4   ; RST 30h es la llamada entre ranuras de la BIOS: se come los tres bytes de detras
	nop			;6ad5   ; y esos tres ceros son justo lo que 0x6AC3 rellena con la ranura y la direccion
	nop			;6ad6
	nop			;6ad7
	pop ix		;6ad8
	pop iy		;6ada
	ret			;6adc

; ----------------------------------------------------------------------
; LO QUE SE HACE DESPUES DE UN ERROR. Devuelve la RAM del cartucho, saca el aviso, y si hay que reintentar vuelve a pedirle sitio al disco.
; ----------------------------------------------------------------------
L_6ADD:
	push bc			;6add
	call sitio_recuperado		;6ade   ; primero, recuperar la RAM propia
	call L_6436		;6ae1
	pop bc			;6ae4
	call L_6B0D		;6ae5   ; el aviso, con su mensaje
	push af			;6ae8
	call L_643E		;6ae9
	pop af			;6aec
	jp c,L_6A02		;6aed
	call sitio_para_el_disco		;6af0   ; y si se reintenta, otra vez sitio al disco
	ld c,001h		;6af3
	ret			;6af5
L_6AF6:
	push bc			;6af6
	call sitio_recuperado		;6af7   ; devuelve la RAM del cartucho
	pop bc			;6afa
	call L_6B0D		;6afb   ; el aviso de error
	jp c,L_6A02		;6afe
	call L_635E		;6b01
	call L_432B		;6b04   ; vuelve a pedir el nombre
	call sitio_para_el_disco		;6b07   ; y otra vez sitio al disco
	ld c,001h		;6b0a
	ret			;6b0c

; ----------------------------------------------------------------------
; EL ERROR DE DISCO, CLASIFICADO. Con el codigo en C se decide de que grupo es: los dos primeros llevan mensaje propio, del 2 al 5 van a otra pantalla, y el resto comparten uno.
; ----------------------------------------------------------------------
L_6B0D:
	push bc			;6b0d
	call L_4616		;6b0e
	call L_466E		;6b11
	call L_44F9		;6b14
	ld hl,06a08h		;6b17   ; el titulo, siempre el mismo
	ld de,(0d16eh)		;6b1a
	call L_6290		;6b1e
	pop bc			;6b21
	ld a,c			;6b22
	and 00eh		;6b23   ; se queda con los bits 1, 2 y 3 del codigo
	rrca			;6b25
	cp 002h		;6b26   ; los dos primeros codigos
	jr c,L_6B30		;6b28
	cp 006h		;6b2a   ; y del segundo al quinto, otra pantalla
	jr c,L_6B74		;6b2c
	jr L_6B36		;6b2e
L_6B30:
	ld hl,06b86h		;6b30
	rrca			;6b33
	jr nc,L_6B39		;6b34
L_6B36:
	ld hl,06b97h		;6b36
L_6B39:
	ex de,hl			;6b39   ; el mensaje de error, diecisiete bytes, una fila mas abajo
	ld hl,(0d16eh)		;6b3a
	ld bc,00040h		;6b3d
	add hl,bc			;6b40
	ex de,hl			;6b41
	ld bc,00011h		;6b42
	push de			;6b45
	call 0005ch		;6b46   ; BIOS LDIRVM - Block transfers to VRAM from memory
	pop hl			;6b49
	ld bc,00040h		;6b4a   ; y otra fila
	add hl,bc			;6b4d
	ex de,hl			;6b4e
	ld hl,06ba8h		;6b4f   ; "RETURN KEY RETRY"
	push de			;6b52
	call L_6290		;6b53
	pop hl			;6b56
	ld bc,00020h		;6b57   ; media fila mas
	add hl,bc			;6b5a
	ld de,06bbah		;6b5b   ; y "SPACE KEY ABORT"
	ex de,hl			;6b5e
	call L_6290		;6b5f
	call 00156h		;6b62   ; BIOS KILBUF - Clears keyboard buffer | se vacia el buffer del teclado, que si no se cuela la tecla que causo el error
L_6B65:
	call 0009fh		;6b65   ; BIOS CHGET - One character input (waiting)
	cp 00dh		;6b68
	jr z,L_6B72		;6b6a
	cp 020h		;6b6c
	jr z,L_6B81		;6b6e
	jr L_6B65		;6b70
L_6B72:
	and a			;6b72
	ret			;6b73
L_6B74:
	ld hl,(0d16eh)		;6b74   ; el aviso, una fila mas abajo
	ld bc,00040h		;6b77
	add hl,bc			;6b7a
	ex de,hl			;6b7b
	ld c,005h		;6b7c   ; el codigo 5
	call L_6A17		;6b7e
L_6B81:
	call L_635E		;6b81
	scf			;6b84
	ret			;6b85

; ----------------------------------------------------------------------
; DATOS texto_write_protected: "=WRITE PROTECTED=", diecisiete bytes exactos:
;   no lleva 0xFF porque 0x6B42 lo copia con bc=0x0011
;   0x6b86..0x6b97  (17 bytes)
DATA_texto_write_protected:
	defb 03dh,057h,052h,049h,054h,045h,000h,050h,052h,04fh,054h,045h,043h,054h,045h,044h,03dh	; 6b86  =WRITE.PROTECTED=

; ----------------------------------------------------------------------
; DATOS texto_disk_offline: "=DISK OFFLINE=" y tres ceros de relleno hasta
;   completar los mismos diecisiete
;   0x6b97..0x6ba8  (17 bytes)
DATA_texto_disk_offline:
	defb 03dh,044h,049h,053h,04bh,000h,04fh,046h,046h,04ch,049h,04eh,045h,03dh,000h,000h,000h	; 6b97  =DISK.OFFLINE=...

; ----------------------------------------------------------------------
; DATOS texto_return_key_retry: "RETURN KEY@@RETRY". Lo pinta 0x6B4F
;   0x6ba8..0x6bba  (18 bytes)
DATA_texto_return_key_retry:
	defb 052h,045h,054h,055h,052h,04eh,000h,04bh,045h,059h,040h,040h,052h,045h,054h,052h,059h,0ffh	; 6ba8  RETURN.KEY@@RETRY.

; ----------------------------------------------------------------------
; DATOS texto_space_key_abort: "SPACE KEY @@ABORT". Con el anterior forman las
;   dos salidas del aviso de error: reintentar o dejarlo
;   0x6bba..0x6bcc  (18 bytes)
DATA_texto_space_key_abort:
	defb 053h,050h,041h,043h,045h,000h,04bh,045h,059h,000h,040h,040h,041h,042h,04fh,052h,054h,0ffh	; 6bba  SPACE.KEY.@@ABORT.

; ======================================================================
; CODIGO 0x6bcc..0x6ca7  (219 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; PEDIR UN NOMBRE DE FICHERO. Como 0x4B04, pone el tope a 0x80 para que el cursor recorra la linea entera.
; ----------------------------------------------------------------------
L_6BCC:
	xor a			;6bcc
	ld (0d163h),a		;6bcd
	ld (0d165h),a		;6bd0
	ld hl,03a6ch		;6bd3
	ld (0d168h),hl		;6bd6   ; donde va el cursor
	ld (0d16ah),hl		;6bd9
	ld a,080h		;6bdc
	ld (0d164h),a		;6bde   ; y el tope, de linea y no de menu
L_6BE1:
	call L_65F4		;6be1
	ld (0d127h),sp		;6be4
	call L_6D0A		;6be8   ; monta el bloque de control
	call L_6D34		;6beb   ; busca el primer fichero
	jp z,L_6C83		;6bee   ; si no hay ninguno, "NO FILE"
	call L_432B		;6bf1   ; pide el nombre
	call L_6569		;6bf4
L_6BF7:
	call L_6CBE		;6bf7
	call 00156h		;6bfa   ; BIOS KILBUF - Clears keyboard buffer

; ----------------------------------------------------------------------
; ELEGIR FICHERO DE LA LISTA. Las flechas mueven por los nombres que se leyeron del directorio y ESPACIO se queda con uno.
; ----------------------------------------------------------------------
L_6BFD:
	ld hl,0d163h		;6bfd
	ld de,0d165h		;6c00
	call 0009fh		;6c03   ; BIOS CHGET - One character input (waiting)
	cp 01eh		;6c06   ; flecha arriba
	jr z,L_6C73		;6c08
	cp 01fh		;6c0a   ; flecha abajo
	jr z,L_6C3B		;6c0c
	cp 020h		;6c0e   ; y ESPACIO elige
	jr nz,L_6BFD		;6c10
	ld a,(0d163h)		;6c12
	ld hl,0d34eh		;6c15
	cp (hl)			;6c18   ; no se puede elegir mas alla de los que hay
	ccf			;6c19
	ret c			;6c1a
	call L_6D9C		;6c1b
	push hl			;6c1e
	call L_6D17		;6c1f
	pop hl			;6c22
	ld de,0d100h		;6c23
	ld (0d125h),de		;6c26
	inc de			;6c2a
	ld a,(0d129h)		;6c2b
	cp 001h		;6c2e
	ld bc,00008h		;6c30   ; ocho caracteres de nombre, u once si hace falta la extension
	jr nz,L_6C37		;6c33
	ld c,00bh		;6c35
L_6C37:
	ldir		;6c37
	or a			;6c39
	ret			;6c3a

; ----------------------------------------------------------------------
; BAJAR EN LA LISTA DE FICHEROS. Igual que la de teclear nombres: a partir de tres, la lista se desplaza en vez de bajar el cursor.
; ----------------------------------------------------------------------
L_6C3B:
	ld a,(0d34eh)		;6c3b
	cp (hl)			;6c3e   ; si ya esta en el ultimo, no se mueve
	jr z,L_6BFD		;6c3f
	inc (hl)			;6c41
	ld a,(de)			;6c42
	ld b,a			;6c43
	ld a,(hl)			;6c44
	sub b			;6c45
	cp 003h		;6c46   ; y de tres en adelante, se desplaza la lista
	jr c,L_6C52		;6c48
	inc b			;6c4a
	ld a,b			;6c4b
	ld (de),a			;6c4c
	ld bc,00000h		;6c4d
	jr L_6C55		;6c50
L_6C52:
	ld bc,00020h		;6c52

; ----------------------------------------------------------------------
; MOVER EL CURSOR POR LA LISTA DE FICHEROS. La misma cuenta que 0x5849, con DCOMPR para no pasarse del ultimo.
; ----------------------------------------------------------------------
L_6C55:
	call L_6571		;6c55   ; borra el cursor
	add hl,bc			;6c58
	push hl			;6c59
	ld de,(0d16ah)		;6c5a
	and a			;6c5e
	sbc hl,de		;6c5f
	ld a,(0d164h)		;6c61
	ld d,000h		;6c64
	ld e,a			;6c66
	rst 20h			;6c67   ; DCOMPR contra el tope
	pop hl			;6c68
	jr nc,L_6C6E		;6c69
	ld (0d168h),hl		;6c6b   ; y solo si cabe, se mueve
L_6C6E:
	call L_6569		;6c6e
	jr L_6BF7		;6c71
L_6C73:
	ld a,(hl)			;6c73   ; subir en la lista de ficheros
	or a			;6c74
	jr z,L_6BFD		;6c75
	dec (hl)			;6c77
	ex de,hl			;6c78
	ld a,(de)			;6c79
	cp (hl)			;6c7a
	jr nc,L_6C7E		;6c7b
	dec (hl)			;6c7d
L_6C7E:
	ld bc,0ffe0h		;6c7e   ; 0xFFE0: una fila para arriba
	jr L_6C55		;6c81
L_6C83:
	ld hl,06ca7h		;6c83
	ld de,(0d16ah)		;6c86
	call L_6290		;6c8a
	ld de,06cafh		;6c8d
	ld hl,(0d16ah)		;6c90
	ld bc,00040h		;6c93
	add hl,bc			;6c96
	ex de,hl			;6c97
	call L_6290		;6c98
	call 00156h		;6c9b   ; BIOS KILBUF - Clears keyboard buffer
L_6C9E:
	call 0009fh		;6c9e   ; BIOS CHGET - One character input (waiting)
	cp 00dh		;6ca1
	jr nz,L_6C9E		;6ca3
	scf			;6ca5
	ret			;6ca6

; ----------------------------------------------------------------------
; DATOS texto_no_file: "NO FILE"
;   0x6ca7..0x6caf  (8 bytes)
DATA_texto_no_file:
	defb 04eh,04fh,000h,046h,049h,04ch,045h,0ffh	; 6ca7  NO.FILE.

; ----------------------------------------------------------------------
; DATOS texto_hit_return_key_2: "HIT RETURN KEY" otra vez, el mismo texto
;   repetido en el binario
;   0x6caf..0x6cbe  (15 bytes)
DATA_texto_hit_return_key_2:
	defb 048h,049h,054h,000h,052h,045h,054h,055h,052h,04eh,000h,04bh,045h,059h,0ffh	; 6caf  HIT.RETURN.KEY.

; ======================================================================
; CODIGO 0x6cbe..0x6d7c  (190 bytes)
; ======================================================================


L_6CBE:
	ld a,(0d165h)		;6cbe
	call L_6D9C		;6cc1   ; el sitio de este nombre
	ld de,(0d16ah)		;6cc4
	inc de			;6cc8
	inc de			;6cc9
	ex de,hl			;6cca
	ld b,003h		;6ccb   ; tres lineas de la lista a la vez
L_6CCD:
	push bc			;6ccd
	push hl			;6cce
	push hl			;6ccf
	xor a			;6cd0
	ld bc,0000ch		;6cd1
	call 00056h		;6cd4   ; BIOS FILVRM - Fills VRAM with value
	pop hl			;6cd7
	ld b,008h		;6cd8
L_6CDA:
	ld a,(de)			;6cda
	cp 020h		;6cdb
	jr z,L_6CE3		;6cdd
	call 0004dh		;6cdf   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;6ce2
L_6CE3:
	inc de			;6ce3
	djnz L_6CDA		;6ce4
	ld a,(0d129h)		;6ce6
	cp 001h		;6ce9   ; segun el modo, se pinta un separador
	jr nz,L_6D01		;6ceb
	ld a,(de)			;6ced
	or a			;6cee
	jr z,L_6CF3		;6cef
	ld a,03ch		;6cf1   ; el 0x3C, que es el punto del nombre
L_6CF3:
	call 0004dh		;6cf3   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;6cf6
	ld b,003h		;6cf7
L_6CF9:
	ld a,(de)			;6cf9
	call 0004dh		;6cfa   ; BIOS WRTVRM - Writes data in VRAM
	inc de			;6cfd
	inc hl			;6cfe
	djnz L_6CF9		;6cff
L_6D01:
	pop hl			;6d01
	ld bc,00020h		;6d02   ; una fila mas abajo
	add hl,bc			;6d05
	pop bc			;6d06
	djnz L_6CCD		;6d07   ; hasta acabar la lista
	ret			;6d09
L_6D0A:
	ld hl,0d351h		;6d0a
	ld de,0d352h		;6d0d
	ld (hl),000h		;6d10
	ld bc,00107h		;6d12
	ldir		;6d15

; ----------------------------------------------------------------------
; EL BLOQUE DE CONTROL PARA BUSCAR. Lo pone a cero y luego llena de 0x3F -la interrogacion- los once del nombre: asi la busqueda vale para cualquier fichero.
; ----------------------------------------------------------------------
L_6D17:
	ld hl,0d100h		;6d17
	ld de,0d101h		;6d1a
	ld (hl),000h		;6d1d   ; los 0x24 bytes, a cero
	ld bc,00024h		;6d1f
	ldir		;6d22
	ld hl,0d101h		;6d24
	ld de,0d102h		;6d27
	ld (hl),03fh		;6d2a   ; interrogaciones: el comodin que vale por cualquier caracter
	ld bc,0000ah		;6d2c   ; once, que son ocho de nombre y tres de extension
	ldir		;6d2f
	jp L_68C2		;6d31

; ----------------------------------------------------------------------
; BUSCAR EL PRIMER FICHERO. Funcion 0x11 del BDOS. Devuelve 0xFF cuando no hay ninguno.
; ----------------------------------------------------------------------
L_6D34:
	call sitio_para_el_disco		;6d34
	xor a			;6d37
	ld (0d34eh),a		;6d38
	ld de,0d351h		;6d3b
	ld c,01ah		;6d3e   ; el buffer de resultados
	call 0f37dh		;6d40
	ld de,0d100h		;6d43
	ld c,011h		;6d46   ; la funcion 0x11, "buscar primero"
	call 0f37dh		;6d48
	inc a			;6d4b   ; y con 0xFF no hay nada
	jr z,L_6D77		;6d4c

; ----------------------------------------------------------------------
; RECORRER EL DIRECTORIO DEL DISCO. Funcion 0x12 del BDOS -buscar siguiente-, hasta veinte ficheros o hasta que no queden.
; ----------------------------------------------------------------------
L_6D4E:
	ld hl,0d34eh		;6d4e
	inc (hl)			;6d51   ; uno mas
	push hl			;6d52
	call L_6D87		;6d53
	pop hl			;6d56
	ld a,(hl)			;6d57
	cp 014h		;6d58   ; veinte como mucho: es lo que cabe en la pantalla
	jr z,L_6D67		;6d5a
	ld de,0d100h		;6d5c
	ld c,012h		;6d5f   ; la funcion 0x12, "buscar siguiente"
	call 0f37dh		;6d61
	inc a			;6d64   ; y con 0xFF ya no quedan
	jr nz,L_6D4E		;6d65
L_6D67:
	ld a,(0d34eh)		;6d67
	push af			;6d6a
	ld de,06d7ch		;6d6b   ; "@@END@@": no hay mas ficheros
	call L_6D8E		;6d6e
	call sitio_recuperado		;6d71   ; y se le devuelve el sitio al cartucho
	pop af			;6d74
	or a			;6d75
	ret			;6d76
L_6D77:
	call sitio_recuperado		;6d77
	xor a			;6d7a
	ret			;6d7b

; ----------------------------------------------------------------------
; DATOS texto_end: "@@END@@" y cuatro ceros: once bytes, los que 0x6D97 copia
;   con bc=0x000B
;   0x6d7c..0x6d87  (11 bytes)
DATA_texto_end:
	defb 040h,040h,045h,04eh,044h,040h,040h,000h,000h,000h,000h	; 6d7c  @@END@@....

; ======================================================================
; CODIGO 0x6d87..0x6f79  (498 bytes)
; ======================================================================


L_6D87:
	ld de,0d352h		;6d87
	ld a,(0d34eh)		;6d8a
	dec a			;6d8d
L_6D8E:
	call L_6D9C		;6d8e
	ex de,hl			;6d91
	ld bc,00008h		;6d92
	jr z,L_6D99		;6d95
	ld c,00bh		;6d97
L_6D99:
	ldir		;6d99
	ret			;6d9b

; ----------------------------------------------------------------------
; EL SITIO DE UN NOMBRE EN LA LISTA. Ocho bytes por fichero, u once cuando ademas se guarda la extension: el `ld a,(0D129h)` de arriba es el que decide.
; ----------------------------------------------------------------------
L_6D9C:
	ld l,a			;6d9c
	ld h,000h		;6d9d
	ld a,(0d129h)		;6d9f
	cp 001h		;6da2
	jr z,L_6DAB		;6da4
	add hl,hl			;6da6
	add hl,hl			;6da7
	add hl,hl			;6da8   ; por ocho
	jr L_6DB4		;6da9
L_6DAB:
	ld b,h			;6dab   ; o por once, segun el modo
	ld c,l			;6dac
	add hl,hl			;6dad
	add hl,bc			;6dae
	add hl,hl			;6daf
	add hl,hl			;6db0
	and a			;6db1
	sbc hl,bc		;6db2
L_6DB4:
	ld bc,0d372h		;6db4
	add hl,bc			;6db7
	or a			;6db8
	ret			;6db9
L_6DBA:
	ld hl,0c802h		;6dba
	ld de,0c002h		;6dbd

; ----------------------------------------------------------------------
; COMPARAR NOMBRES DE FICHERO CON COMODINES. Recorre el nombre pedido y el del directorio a la vez; el asterisco vale por lo que queda y la interrogacion por un caracter.
; ----------------------------------------------------------------------
L_6DC0:
	ld a,081h		;6dc0
	ld (0d13eh),a		;6dc2   ; la marca de "sigue comparando"
	ld c,(hl)			;6dc5
	ld (0d13fh),de		;6dc6
	inc de			;6dca
	ld a,c			;6dcb
	ld (de),a			;6dcc
	inc hl			;6dcd
	inc de			;6dce
	call L_6E43		;6dcf   ; mira si el caracter es un comodin
	jp z,L_6E62		;6dd2
	ld a,c			;6dd5
	cp (hl)			;6dd6   ; y si no, tienen que ser iguales
	jr z,L_6E16		;6dd7
	ld a,001h		;6dd9
	ld (0d13eh),a		;6ddb
L_6DDE:
	ld c,(hl)			;6dde
	inc hl			;6ddf
	ld a,c			;6de0   ; el caracter, copiado
	ld (de),a			;6de1
	inc de			;6de2
	call L_6E43		;6de3   ; ¿se paso del buffer?
	jp z,L_6E59		;6de6
	cp (hl)			;6de9   ; y se compara con el que se esperaba
	jr nz,L_6E09		;6dea
	inc hl			;6dec
	call L_6E43		;6ded
	jr z,L_6E4E		;6df0
	cp (hl)			;6df2
	dec hl			;6df3
	jr nz,L_6E09		;6df4
L_6DF6:
	dec hl			;6df6
	dec de			;6df7
	push hl			;6df8
	ld hl,(0d13fh)		;6df9
	ld a,(0d13eh)		;6dfc
	set 7,a		;6dff   ; el bit 7 marca el final de la cadena
	ld (hl),a			;6e01
	pop hl			;6e02
	ld (0d13fh),de		;6e03   ; y se apunta donde se quedo
	jr L_6DC0		;6e07
L_6E09:
	ld a,(0d13eh)		;6e09
	cp 07fh		;6e0c   ; con 0x7F ya no cabe mas
	jr z,L_6DF6		;6e0e
	inc a			;6e10
	ld (0d13eh),a		;6e11   ; y uno mas de cuenta
	jr L_6DDE		;6e14
L_6E16:
	ld a,002h		;6e16
	ld (0d13eh),a		;6e18
L_6E1B:
	inc hl			;6e1b
	call L_6E43		;6e1c   ; ¿se paso del buffer?
	jr z,L_6E62		;6e1f
	ld a,c			;6e21
	cp (hl)			;6e22   ; y si el caracter cuadra, se sigue
	jr z,L_6E36		;6e23
L_6E25:
	ld de,(0d13fh)		;6e25
	ld a,(0d13eh)		;6e29
	ld (de),a			;6e2c   ; se apunta la marca
	inc de			;6e2d
	inc de			;6e2e
	ld (0d13fh),de		;6e2f   ; y donde se quedo
	jp L_6DC0		;6e33
L_6E36:
	ld a,(0d13eh)		;6e36
	cp 07fh		;6e39   ; con 0x7F no cabe mas
	jr z,L_6E25		;6e3b
	inc a			;6e3d
	ld (0d13eh),a		;6e3e
	jr L_6E1B		;6e41

; ----------------------------------------------------------------------
; ¿SE HA PASADO DEL BUFFER? Resta 0xD002 a la posicion: es el tope de la zona donde se van montando los nombres.
; ----------------------------------------------------------------------
L_6E43:
	push hl			;6e43
	push de			;6e44
	ld de,0d002h		;6e45
	and a			;6e48
	sbc hl,de		;6e49   ; el tope, 0xD002
	pop de			;6e4b
	pop hl			;6e4c
	ret			;6e4d
L_6E4E:
	dec hl			;6e4e
	ld a,(hl)			;6e4f   ; el ultimo caracter
	ld (de),a			;6e50
	inc de			;6e51
	ld a,(0d13eh)		;6e52
	inc a			;6e55
	ld (0d13eh),a		;6e56   ; y uno mas de cuenta
L_6E59:
	ld a,(0d13eh)		;6e59
	inc a			;6e5c
	set 7,a		;6e5d
	ld (0d13eh),a		;6e5f
L_6E62:
	xor a			;6e62
	ld (de),a			;6e63   ; cierra la cadena con un cero
	ld a,(0d13eh)		;6e64
	ld hl,(0d13fh)		;6e67
	ld (hl),a			;6e6a
	ex de,hl			;6e6b
	ld de,0c001h		;6e6c
	and a			;6e6f
	sbc hl,de		;6e70
	ld (0c000h),hl		;6e72   ; y en 0xC000 se deja cuanto se leyo
	ret			;6e75

; ----------------------------------------------------------------------
; CARGAR DE CINTA. Se guarda la pila propia antes de nada, porque la BIOS de cinta usa la suya.
; ----------------------------------------------------------------------
L_6E76:
	ld hl,00000h		;6e76
	add hl,sp			;6e79
	push hl			;6e7a
	ld (0d127h),hl		;6e7b   ; la pila, aparcada
	ld hl,07028h		;6e7e   ; la cabecera del fichero
	call L_6FD1		;6e81
	call L_7045		;6e84
	call L_7057		;6e87
	call L_704D		;6e8a
	pop hl			;6e8d
	call L_6FC4		;6e8e   ; y se recupera al acabar
	call L_7040		;6e91
	ret			;6e94
L_6E95:
	ld (0d127h),sp		;6e95   ; CARGAR EL RANKING DE CINTA
	ld hl,0702eh		;6e99
	call L_6FD1		;6e9c
	call L_7057		;6e9f
	call L_6FC4		;6ea2
	call L_7040		;6ea5
	ret			;6ea8
L_6EA9:
	ld (0d127h),sp		;6ea9   ; GUARDAR EL RANKING EN CINTA
	ld hl,0703ah		;6ead   ; la cabecera
	call L_6FD1		;6eb0
	call L_56F5		;6eb3   ; se recogen los datos
	call L_7090		;6eb6
	call L_6FC4		;6eb9
	call L_7040		;6ebc
	ret			;6ebf
L_6EC0:
	ld (0d127h),sp		;6ec0   ; y esta guarda los datos del juego
	ld hl,07034h		;6ec4
	call L_6FD1		;6ec7
	call L_7098		;6eca
	call L_6FC4		;6ecd
	call L_7040		;6ed0
	ret			;6ed3

; ----------------------------------------------------------------------
; GUARDAR EN CINTA. El mismo guion que el disco: cabecera, bloques y la pila del juego aparte.
; ----------------------------------------------------------------------
L_6ED4:
	ld (0d127h),sp		;6ed4
	ld hl,07028h		;6ed8   ; la cabecera del fichero
	call L_70C8		;6edb
	call L_71A6		;6ede
	call L_71AE		;6ee1
	ld hl,0c000h		;6ee4
	ld bc,00082h		;6ee7
	call L_71EA		;6eea   ; los 0x82 bytes que llevan la pila
	ld de,0c002h		;6eed
	ld hl,(0c000h)		;6ef0   ; y se recupera la pila de donde se guardo
	ld sp,hl			;6ef3
	ex de,hl			;6ef4
	ld bc,00080h		;6ef5
	ldir		;6ef8
	jp L_71A1		;6efa
L_6EFD:
	ld (0d127h),sp		;6efd   ; GUARDAR LA PANTALLA EN CINTA
	ld hl,0702eh		;6f01
	call L_70C8		;6f04
	call L_6FC0		;6f07
	call L_71AE		;6f0a
	call L_71A1		;6f0d
	ret			;6f10
L_6F11:
	ld (0d127h),sp		;6f11   ; y guardar el ranking
	ld hl,0703ah		;6f15
	call L_70C8		;6f18
	call L_71DA		;6f1b
	call L_5653		;6f1e
	call L_71A1		;6f21
	ret			;6f24
L_6F25:
	ld (0d127h),sp		;6f25   ; y los datos del juego
	ld hl,07034h		;6f29
	call L_70C8		;6f2c
	call L_71E2		;6f2f
	call L_71A1		;6f32
	ret			;6f35
L_6F36:
	xor a			;6f36
	jr L_6F3B		;6f37
L_6F39:
	ld a,001h		;6f39
L_6F3B:
	push af			;6f3b
	ld a,0ffh		;6f3c
	call 000f3h		;6f3e   ; BIOS STMOTR - Sets the cassette motor action | STMOTR con 0xFF para el motor del cassette
	call L_6436		;6f41
	call L_4616		;6f44
	call L_466E		;6f47
	pop af			;6f4a
	or a			;6f4b
	ld hl,06f79h		;6f4c   ; "TAPE IO ERROR"
	jr z,L_6F54		;6f4f
	ld hl,06f89h		;6f51   ; o "SUM CHECK ERROR", segun el que sea
L_6F54:
	ld de,(0d16eh)		;6f54
	push de			;6f58
	call L_6290		;6f59   ; el titulo del error
	pop hl			;6f5c
	ld bc,00040h		;6f5d
	add hl,bc			;6f60
	ld de,06f99h		;6f61   ; y debajo, "HIT RETURN KEY"
	ex de,hl			;6f64
	call L_6290		;6f65
L_6F68:
	ld a,007h		;6f68
	call 00141h		;6f6a   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix | a esperar tecla
	rla			;6f6d
	jr c,L_6F68		;6f6e
	call L_643E		;6f70
	ld sp,(0d127h)		;6f73
	scf			;6f77
	ret			;6f78

; ----------------------------------------------------------------------
; DATOS texto_tape_io_error: "TAPE IO ERROR"
;   0x6f79..0x6f89  (16 bytes)
DATA_texto_tape_io_error:
	defb 054h,041h,050h,045h,000h,049h,04fh,000h,045h,052h,052h,04fh,052h,000h,000h,0ffh	; 6f79  TAPE.IO.ERROR...

; ----------------------------------------------------------------------
; DATOS texto_sum_check_error: "SUM CHECK ERROR". 0x6F4C elige entre este y el
;   anterior
;   0x6f89..0x6f99  (16 bytes)
DATA_texto_sum_check_error:
	defb 053h,055h,04dh,000h,043h,048h,045h,043h,04bh,000h,045h,052h,052h,04fh,052h,0ffh	; 6f89  SUM.CHECK.ERROR.

; ----------------------------------------------------------------------
; DATOS texto_hit_return_key_3: "HIT RETURN KEY", la tercera copia
;   0x6f99..0x6fa8  (15 bytes)
DATA_texto_hit_return_key_3:
	defb 048h,049h,054h,000h,052h,045h,054h,055h,052h,04eh,000h,04bh,045h,059h,0ffh	; 6f99  HIT.RETURN.KEY.

; ======================================================================
; CODIGO 0x6fa8..0x6fb5  (13 bytes)
; ======================================================================


L_6FA8:
	ld a,0ffh		;6fa8
	call 000eah		;6faa   ; BIOS TAPOON - Turns on the cassette motor and writes the header
	jp c,L_6F36		;6fad
	ret			;6fb0
L_6FB1:
	ld b,00fh		;6fb1
	jr $+4		;6fb3

; ----------------------------------------------------------------------
; DATOS entrada_muerta_2: `ld b,005h`, el mismo caso: 0x6FB1 entra con B a
;   quince y se los salta con el `jr $+4` de 0x6FB3, y la puerta de los cinco
;   no la usa nadie
;   0x6fb5..0x6fb7  (2 bytes)
DATA_entrada_muerta_2:
	defb 006h,005h	; 6fb5

; ======================================================================
; CODIGO 0x6fb7..0x700f  (88 bytes)
; ======================================================================


L_6FB7:
	push bc			;6fb7
	ld a,001h		;6fb8
	call 000f3h		;6fba   ; BIOS STMOTR - Sets the cassette motor action
	pop bc			;6fbd
	jr L_6FC6		;6fbe
L_6FC0:
	ld b,003h		;6fc0
	jr L_6FC6		;6fc2
L_6FC4:
	ld b,005h		;6fc4
L_6FC6:
	ld de,00000h		;6fc6
L_6FC9:
	dec de			;6fc9
	ld a,d			;6fca   ; una espera a base de dar vueltas: la cinta necesita su tiempo entre bloques
	or e			;6fcb
	jr nz,L_6FC9		;6fcc
	djnz L_6FC6		;6fce   ; y B veces
	ret			;6fd0
L_6FD1:
	call L_7018		;6fd1
	ld hl,0d351h		;6fd4   ; el nombre del fichero
	ld de,0700fh		;6fd7
	ld bc,00009h		;6fda
	call L_7177		;6fdd
	call L_6FB1		;6fe0
	call L_6FA8		;6fe3
	ld b,00ah		;6fe6   ; diez bytes 0x0B de cabecera, que es lo que el MSX espera al principio de un fichero de cinta
L_6FE8:
	ld a,00bh		;6fe8
	push bc			;6fea
	call 000edh		;6feb   ; BIOS TAPOUT - Writes data on the tape
	pop bc			;6fee
	jp c,L_6F36		;6fef
	djnz L_6FE8		;6ff2
	ld hl,0d351h		;6ff4
	ld b,008h		;6ff7
L_6FF9:
	ld a,(hl)			;6ff9
	push bc			;6ffa
	push hl			;6ffb
	call 000edh		;6ffc   ; BIOS TAPOUT - Writes data on the tape
	pop hl			;6fff
	pop bc			;7000
	jp c,L_6F36		;7001
	inc hl			;7004
	djnz L_6FF9		;7005
	call L_643E		;7007
	xor a			;700a
	call 000eah		;700b   ; BIOS TAPOON - Turns on the cassette motor and writes the header
	ret			;700e

; ----------------------------------------------------------------------
; DATOS texto_file_name: "FILE NAME", nueve bytes exactos: los del bc=0x0009
;   de 0x6FDA
;   0x700f..0x7018  (9 bytes)
DATA_texto_file_name:
	defb 046h,049h,04ch,045h,000h,04eh,041h,04dh,045h	; 700f  FILE.NAME

; ======================================================================
; CODIGO 0x7018..0x7028  (16 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL NOMBRE DEL FICHERO DE CINTA. Seis caracteres, y detras el numero de catalogo del juego pasado a letras: asi la cinta de un juego no se confunde con la de otro.
; ----------------------------------------------------------------------
L_7018:
	ld de,0d351h		;7018
	ld bc,00006h		;701b   ; seis caracteres
	ldir		;701e
	ex de,hl			;7020
	ld a,(0d301h)		;7021
	call bcd_a_dos_letras		;7024   ; y el numero del juego, en letras
	ret			;7027

; ----------------------------------------------------------------------
; DATOS nombres_de_fichero: GAMEDT, SCREEN, HISCOR y RANKDT, de seis letras
;   cada uno: las extensiones .Gxx, .Sxx, .Hxx y .Rxx del manual
;   0x7028..0x7040  (24 bytes)
DATA_nombres_de_fichero:
	defb 047h,041h,04dh,045h,044h,054h	; 7028
	defb 053h,043h,052h,045h,045h,04eh	; 702e
	defb 048h,049h,053h,043h,04fh,052h	; 7034
	defb 052h,041h,04eh,04bh,044h,054h	; 703a

; ======================================================================
; CODIGO 0x7040..0x7159  (281 bytes)
; ======================================================================


L_7040:
	call 000f0h		;7040   ; BIOS TAPOOF - Stops writing on the tape
	xor a			;7043
	ret			;7044
L_7045:
	ld hl,0e000h		;7045
	ld bc,01100h		;7048
	jr L_70A0		;704b
L_704D:
	ld hl,(0d127h)		;704d
	dec hl			;7050
	dec hl			;7051
	ld bc,00082h		;7052
	jr L_70A0		;7055
L_7057:
	ld hl,00000h		;7057
L_705A:
	push hl			;705a
	ld de,0c802h		;705b   ; se saca la pantalla de la VRAM en trozos de 0x800
	ld bc,00800h		;705e
	call 00059h		;7061   ; BIOS LDIRMV - Block transfers to memory from VRAM
	call L_6DBA		;7064
	xor a			;7067
	call 000eah		;7068   ; BIOS TAPOON - Turns on the cassette motor and writes the header | TAPOON arranca el motor y escribe la cabecera
	ld hl,(0c000h)		;706b
	push hl			;706e
	ld a,l			;706f
	call 000edh		;7070   ; BIOS TAPOUT - Writes data on the tape | el tamano, byte bajo primero
	pop hl			;7073
	ld a,h			;7074
	call 000edh		;7075   ; BIOS TAPOUT - Writes data on the tape
	ld hl,0c002h		;7078
	ld bc,(0c000h)		;707b
	call L_70A0		;707f   ; y el bloque
	pop hl			;7082
	ld bc,00800h		;7083
	add hl,bc			;7086
	ld a,h			;7087
	cp 040h		;7088   ; hasta 0x40, que por 0x800 son los 16 KB de VRAM
	jr nz,L_705A		;708a
	xor a			;708c
	jp 000eah		;708d   ; BIOS TAPOON - Turns on the cassette motor and writes the header
L_7090:
	ld hl,0d459h		;7090
	ld bc,00078h		;7093
	jr L_70A0		;7096
L_7098:
	ld hl,(0d30ch)		;7098
	ld bc,00003h		;709b
	jr L_70A0		;709e
L_70A0:
	ld d,000h		;70a0

; ----------------------------------------------------------------------
; ESCRIBIR UN BLOQUE EN LA CINTA. La hermana de 0x71EC: byte a byte con TAPOUT, sumandolos, y al final la suma.
; ----------------------------------------------------------------------
escribe_en_la_cinta:
	ld a,(hl)			;70a2
	ld e,a			;70a3
	push bc			;70a4
	push hl			;70a5
	push de			;70a6
	call 000edh		;70a7   ; BIOS TAPOUT - Writes data on the tape | TAPOUT saca un byte a la cinta
	pop de			;70aa
	pop hl			;70ab
	pop bc			;70ac
	jp c,L_6F36		;70ad
	ld a,e			;70b0
	add a,d			;70b1   ; y se va sumando lo escrito
	ld d,a			;70b2
	inc hl			;70b3
	dec bc			;70b4
	ld a,b			;70b5
	or c			;70b6
	jr nz,escribe_en_la_cinta		;70b7
	ld a,d			;70b9
	call 000edh		;70ba   ; BIOS TAPOUT - Writes data on the tape | la suma, detras del bloque: es lo que 0x7209 comprobara al leer
	jp c,L_6F36		;70bd
	ret			;70c0
L_70C1:
	call 000e1h		;70c1   ; BIOS TAPION - Reads the header block after turning the cassette motor on
	jp c,L_6F36		;70c4
	ret			;70c7
L_70C8:
	call L_7018		;70c8
	call L_635E		;70cb
L_70CE:
	ld de,(0d16eh)		;70ce
	ld hl,07166h		;70d2
	call L_6290		;70d5
	call L_70C1		;70d8
	ld b,00ah		;70db

; ----------------------------------------------------------------------
; ESPERAR LA CABECERA DE LA CINTA. Los ficheros de cinta del MSX empiezan por diez bytes 0x0B; hasta que no llegan los diez seguidos, no hay fichero.
; ----------------------------------------------------------------------
L_70DD:
	push bc			;70dd
	call 000e4h		;70de   ; BIOS TAPIN - Reads data from the tape | un byte de la cinta
	pop bc			;70e1
	cp 00bh		;70e2   ; tiene que ser 0x0B
	jr nz,L_70CE		;70e4
	djnz L_70DD		;70e6   ; y diez seguidos
	ld hl,0d351h		;70e8
	ld de,0da00h		;70eb
	ld a,(0d129h)		;70ee
	cp 001h		;70f1   ; seis bytes de nombre, u ocho segun el modo
	ld b,006h		;70f3
	jr z,L_70F9		;70f5
	ld b,008h		;70f7
L_70F9:
	ld c,000h		;70f9

; ----------------------------------------------------------------------
; LEER Y COMPARAR DE LA CINTA. Lee B bytes y los va comparando con lo que se esperaba; a la primera diferencia deja C a 0xFF y sigue leyendo, porque el bloque hay que consumirlo entero.
; ----------------------------------------------------------------------
L_70FB:
	push bc			;70fb
	push hl			;70fc
	push de			;70fd
	call 000e4h		;70fe   ; BIOS TAPIN - Reads data from the tape | un byte de la cinta
	jp c,L_6F36		;7101   ; cortada, error de entrada y salida
	pop de			;7104
	pop hl			;7105
	pop bc			;7106
	ld (de),a			;7107
	ld a,c			;7108
	or a			;7109
	jr nz,L_7112		;710a
	ld a,(de)			;710c
	cp (hl)			;710d   ; si no es el que se esperaba
	jr z,L_7112		;710e
	ld c,0ffh		;7110   ; se marca, pero se sigue leyendo hasta el final
L_7112:
	inc hl			;7112
	inc de			;7113
	djnz L_70FB		;7114
	ld a,(0d129h)		;7116
	cp 001h		;7119
	jr nz,L_712C		;711b
	push bc			;711d
	push de			;711e
	call 000e4h		;711f   ; BIOS TAPIN - Reads data from the tape
	pop de			;7122
	ld (de),a			;7123
	inc de			;7124
	push de			;7125
	call 000e4h		;7126   ; BIOS TAPIN - Reads data from the tape
	pop de			;7129
	ld (de),a			;712a
	pop bc			;712b
L_712C:
	ld a,c			;712c
	or a			;712d   ; con C a cero no hubo diferencias: la carga fue bien
	jr nz,L_7148		;712e
	ld a,(0d129h)		;7130
	cp 001h		;7133   ; segun el modo
	jr z,L_7143		;7135
	ld a,(0d13dh)		;7137
	or a			;713a
	jr z,L_7143		;713b
	call L_643E		;713d   ; se devuelve la pantalla del cartucho
L_7140:
	jp L_70C1		;7140
L_7143:
	call L_4C1F		;7143
	jr L_7140		;7146
L_7148:
	ld de,07159h		;7148
	ld a,040h		;714b   ; el 0x40, que aqui es el hueco
	ld bc,0000dh		;714d   ; trece bytes: "SKIP FILE" y su relleno
	call L_7172		;7150
	call L_70C1		;7153
	jp L_70CE		;7156

; ----------------------------------------------------------------------
; DATOS texto_skip_file: "SKIP FILE" y cuatro ceros: trece bytes, los del
;   bc=0x000D de 0x714D
;   0x7159..0x7166  (13 bytes)
DATA_texto_skip_file:
	defb 053h,04bh,049h,050h,000h,046h,049h,04ch,045h,000h,000h,000h,000h	; 7159  SKIP.FILE....

; ----------------------------------------------------------------------
; DATOS texto_search_file_2: "SEARCH FILE", que carga 0x70D2
;   0x7166..0x7172  (12 bytes)
DATA_texto_search_file_2:
	defb 053h,045h,041h,052h,043h,048h,000h,046h,049h,04ch,045h,0ffh	; 7166  SEARCH.FILE.

; ======================================================================
; CODIGO 0x7172..0x7231  (191 bytes)
; ======================================================================


L_7172:
	ld hl,0da00h		;7172
	jr L_7178		;7175
L_7177:
	xor a			;7177
L_7178:
	push hl			;7178
	ld hl,(0d16eh)		;7179
	call L_626E		;717c
	ex de,hl			;717f
	push de			;7180
	call 0005ch		;7181   ; BIOS LDIRVM - Block transfers to VRAM from memory
	pop hl			;7184
	ld bc,00040h		;7185
	add hl,bc			;7188
	pop de			;7189
	ld a,03dh		;718a
	call 0004dh		;718c   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;718f
	ex de,hl			;7190
	ld bc,00008h		;7191
	push bc			;7194
	push de			;7195
	call 0005ch		;7196   ; BIOS LDIRVM - Block transfers to VRAM from memory
	pop hl			;7199
	pop bc			;719a
	add hl,bc			;719b
	ld a,03dh		;719c
	jp 0004dh		;719e   ; BIOS WRTVRM - Writes data in VRAM
L_71A1:
	call 000e7h		;71a1   ; BIOS TAPIOF - Stops reading from the tape
	xor a			;71a4
	ret			;71a5
L_71A6:
	ld hl,0e000h		;71a6
	ld bc,01100h		;71a9
	jr L_71EA		;71ac
L_71AE:
	ld de,00000h		;71ae
L_71B1:
	push de			;71b1
	call 000e1h		;71b2   ; BIOS TAPION - Reads the header block after turning the cassette motor on
	call 000e4h		;71b5   ; BIOS TAPIN - Reads data from the tape
	ld c,a			;71b8
	push bc			;71b9
	call 000e4h		;71ba   ; BIOS TAPIN - Reads data from the tape
	pop bc			;71bd
	ld b,a			;71be
	ld hl,0c002h		;71bf
	call L_71EA		;71c2
	pop de			;71c5
	push de			;71c6
	ld hl,0c002h		;71c7
	call L_62FB		;71ca
	pop hl			;71cd
	ld bc,00800h		;71ce
	add hl,bc			;71d1
	ld a,h			;71d2
	cp 040h		;71d3
	jr nz,L_71B1		;71d5
	jp 000e1h		;71d7   ; BIOS TAPION - Reads the header block after turning the cassette motor on
L_71DA:
	ld hl,0d459h		;71da
	ld bc,00078h		;71dd
	jr L_71EA		;71e0
L_71E2:
	ld hl,(0d30ch)		;71e2
	ld bc,00003h		;71e5
	jr L_71EA		;71e8
L_71EA:
	ld d,000h		;71ea

; ----------------------------------------------------------------------
; LEER UN BLOQUE DE LA CINTA. Byte a byte con TAPIN, sumandolos en D, y al final se lee UN BYTE MAS que es la suma de comprobacion y se compara.
; ----------------------------------------------------------------------
lee_de_la_cinta:
	push bc			;71ec
	push hl			;71ed
	push de			;71ee
	call 000e4h		;71ef   ; BIOS TAPIN - Reads data from the tape | TAPIN da un byte de la cinta, o carry si se corta
	pop de			;71f2
	pop hl			;71f3
	pop bc			;71f4
	jp c,L_6F36		;71f5   ; cortada: error de entrada y salida
	ld (hl),a			;71f8
	add a,d			;71f9   ; se va sumando lo leido
	ld d,a			;71fa
	inc hl			;71fb
	dec bc			;71fc
	ld a,b			;71fd
	or c			;71fe
	jr nz,lee_de_la_cinta		;71ff
	push de			;7201
	call 000e4h		;7202   ; BIOS TAPIN - Reads data from the tape | y detras del bloque viene la suma
	pop de			;7205
	jp c,L_6F36		;7206
	cp d			;7209   ; si no cuadra, error de suma. Es la unica comprobacion que lleva el formato
	jp c,L_6F39		;720a
	ret			;720d
L_720E:
	ld a,070h		;720e   ; IMPRIMIR: codigo 0x70
	ld (0d136h),a		;7210
	call L_42A4		;7213
	call salva_la_pantalla		;7216
	call L_721F		;7219
	jr c,L_720E		;721c   ; y si falla, se vuelve a preguntar
	ret			;721e
L_721F:
	ld (0d127h),sp		;721f
	call L_7313		;7223   ; pinta la pantalla de elegir impresora
	ld hl,07357h		;7226   ; sus tres sitios
	ld b,003h		;7229
	call L_6581		;722b
	call L_6368		;722e   ; y a la que se elija

; ----------------------------------------------------------------------
; DATOS impresora_rutinas: Tres punteros, la tabla del despacho de 0x722E
;   0x7231..0x7237  (6 bytes)
DATA_impresora_rutinas:
	defb 03ch,072h	; 7231
	defb 040h,072h	; 7233
	defb 037h,072h	; 7235

; ======================================================================
; CODIGO 0x7237..0x731f  (232 bytes)
; ======================================================================


L_7237:
	call L_63E9		;7237
	xor a			;723a
	ret			;723b
L_723C:
	ld a,070h		;723c
	jr L_724D		;723e
L_7240:
	ld a,006h		;7240
	call 00141h		;7242   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	and 002h		;7245
	ld a,072h		;7247
	jr z,L_724D		;7249
	ld a,071h		;724b
L_724D:
	ld (0d136h),a		;724d
	call L_63E9		;7250   ; devuelve la pantalla del cartucho
	call L_7267		;7253   ; se copia la pantalla a la RAM
	call L_748A		;7256
	call L_7289		;7259
	ld a,(0d136h)		;725c
	cp 070h		;725f   ; con el codigo 0x70 se imprime el ranking
	jp z,L_7402		;7261
	jp L_7626		;7264   ; y si no, la pantalla

; ----------------------------------------------------------------------
; BORRAR LA COPIA DE LA PANTALLA. 0x3BF bytes a cero en 0xD9B1, que es donde se monta lo que va a la impresora.
; ----------------------------------------------------------------------
L_7267:
	ld hl,0d9b1h		;7267
	ld de,0d9b2h		;726a
	ld bc,003bfh		;726d
	ld (hl),000h		;7270   ; a cero
	ldir		;7272   ; los 0x3BF que caben
	ret			;7274
L_7275:
	ld a,007h		;7275
	call 00141h		;7277   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	and 010h		;727a
	ret nz			;727c
	ld a,006h		;727d
	call 00141h		;727f   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	and 002h		;7282
	ret nz			;7284
	ld c,001h		;7285
	jr L_729F		;7287
L_7289:
	ld h,001h		;7289
L_728B:
	ld c,000h		;728b
L_728D:
	ld b,000h		;728d
L_728F:
	call 000a8h		;728f   ; BIOS LPTSTT - Tests printer status
	jr z,L_7297		;7292
	cp 0ffh		;7294
	ret z			;7296
L_7297:
	djnz L_728F		;7297
	dec c			;7299
	jr nz,L_728D		;729a
	dec h			;729c
	jr nz,L_728B		;729d
L_729F:
	push bc			;729f
	call salva_la_pantalla		;72a0   ; limpia
	call L_4616		;72a3
	call L_735D		;72a6   ; pinta el marco
	pop bc			;72a9
	ld a,c			;72aa
	cp 001h		;72ab   ; segun el codigo, una pantalla u otra
	jr z,L_72B5		;72ad
	call L_7366		;72af
	jp L_72F8		;72b2
L_72B5:
	call L_73B5		;72b5
	call 00156h		;72b8   ; BIOS KILBUF - Clears keyboard buffer | y se vacia el teclado
L_72BB:
	call 0009fh		;72bb   ; BIOS CHGET - One character input (waiting)
	cp 00dh		;72be
	jr z,L_72C8		;72c0
	cp 020h		;72c2
	jr z,L_72CC		;72c4
	jr L_72BB		;72c6
L_72C8:
	call L_63E9		;72c8
	ret			;72cb
L_72CC:
	call L_63E9		;72cc
L_72CF:
	call 000a8h		;72cf   ; BIOS LPTSTT - Tests printer status
	jr z,L_72CF		;72d2
	cp 0ffh		;72d4
	jr nz,L_72CF		;72d6
	ld hl,00200h		;72d8
L_72DB:
	xor a			;72db
	call 000a5h		;72dc   ; BIOS LPTOUT - Sends one character to printer
	dec hl			;72df
	ld a,h			;72e0
	or l			;72e1
	jr nz,L_72DB		;72e2
	ld b,008h		;72e4
L_72E6:
	ld a,00dh		;72e6
	call 000a5h		;72e8   ; BIOS LPTOUT - Sends one character to printer
	ld a,00ah		;72eb
	call 000a5h		;72ed   ; BIOS LPTOUT - Sends one character to printer
	djnz L_72E6		;72f0
L_72F2:
	ld sp,(0d127h)		;72f2
	scf			;72f6
	ret			;72f7
L_72F8:
	call 00156h		;72f8   ; BIOS KILBUF - Clears keyboard buffer
L_72FB:
	call 0009fh		;72fb   ; BIOS CHGET - One character input (waiting)
	cp 00dh		;72fe
	jr z,L_730D		;7300
	cp 020h		;7302
	jr z,L_7308		;7304
	jr L_72FB		;7306
L_7308:
	call L_63E9		;7308
	jr L_72F2		;730b
L_730D:
	call L_63E9		;730d
	jp L_7289		;7310
L_7313:
	call L_4616		;7313
	call L_735D		;7316
	ld hl,0731fh		;7319
	jp pinta_rotulos		;731c

; ----------------------------------------------------------------------
; DATOS rotulos_elegir_impresora: SELECT PRINTER / EPSON=PI 40= / MSX PRINTER
;   / END. Lo pinta el jp de 0x731C
;   0x731f..0x7357  (56 bytes)
DATA_rotulos_elegir_impresora:
	defb 02ch,03ah,040h,040h,053h,045h,04ch,045h,043h,054h,000h,050h,052h,049h,04eh,054h	; 731f  ,:@@SELECT.PRINT
	defb 045h,052h,040h,040h,0feh,06ch,03ah,045h,050h,053h,04fh,04eh,03dh,050h,049h,040h	; 732f  ER@@.l:EPSON=PI@
	defb 034h,030h,03dh,0feh,08ch,03ah,04dh,053h,058h,000h,050h,052h,049h,04eh,054h,045h	; 733f  40=..:MSX.PRINTE
	defb 052h,0feh,0cch,03ah,045h,04eh,044h,0ffh	; 734f  R..:END.

; ----------------------------------------------------------------------
; DATOS sitios_menu_impresora: Las TRES filas del menu de 0x731F, pegadas
;   detras de sus rotulos
;   0x7357..0x735d  (6 bytes)
DATA_sitios_menu_impresora:
	defb 06bh,03ah	; 7357
	defb 08bh,03ah	; 7359
	defb 0cbh,03ah	; 735b

; ======================================================================
; CODIGO 0x735d..0x736c  (15 bytes)
; ======================================================================


L_735D:
	ld a,(0d301h)		;735d
	cp 0ffh		;7360
	ret z			;7362
	jp L_44F9		;7363
L_7366:
	ld hl,0736ch		;7366
	jp pinta_rotulos		;7369

; ----------------------------------------------------------------------
; DATOS rotulos_impresora_no_lista: PRINTER MODE / =NOT READY= / RETURN KEY
;   RETRY / SPACE KEY ABORT. Lo pinta el jp de 0x7369
;   0x736c..0x73b5  (73 bytes)
DATA_rotulos_impresora_no_lista:
	defb 02ch,03ah,040h,040h,050h,052h,049h,04eh,054h,045h,052h,000h,04dh,04fh,044h,045h	; 736c  ,:@@PRINTER.MODE
	defb 040h,040h,0feh,06ch,03ah,03dh,04eh,04fh,054h,000h,052h,045h,041h,044h,059h,03dh	; 737c  @@.l:=NOT.READY=
	defb 0feh,0ach,03ah,052h,045h,054h,055h,052h,04eh,000h,04bh,045h,059h,040h,040h,052h	; 738c  ..:RETURN.KEY@@R
	defb 045h,054h,052h,059h,0feh,0cch,03ah,053h,050h,041h,043h,045h,000h,04bh,045h,059h	; 739c  ETRY..:SPACE.KEY
	defb 000h,040h,040h,041h,042h,04fh,052h,054h,0ffh	; 73ac  .@@ABORT.

; ======================================================================
; CODIGO 0x73b5..0x73bb  (6 bytes)
; ======================================================================


L_73B5:
	ld hl,073bbh		;73b5
	jp pinta_rotulos		;73b8

; ----------------------------------------------------------------------
; DATOS rotulos_impresora_en_pausa: PRINTER MODE / =PAUSING= / RETURN KEY
;   START / SPACE KEY ABORT. Lo pinta el jp de 0x73B8
;   0x73bb..0x7402  (71 bytes)
DATA_rotulos_impresora_en_pausa:
	defb 02ch,03ah,040h,040h,050h,052h,049h,04eh,054h,045h,052h,000h,04dh,04fh,044h,045h	; 73bb  ,:@@PRINTER.MODE
	defb 040h,040h,0feh,06ch,03ah,03dh,050h,041h,055h,053h,049h,04eh,047h,03dh,0feh,0ach	; 73cb  @@.l:=PAUSING=..
	defb 03ah,052h,045h,054h,055h,052h,04eh,000h,04bh,045h,059h,040h,040h,053h,054h,041h	; 73db  :RETURN.KEY@@STA
	defb 052h,054h,0feh,0cch,03ah,053h,050h,041h,043h,045h,000h,04bh,045h,059h,000h,040h	; 73eb  RT..:SPACE.KEY.@
	defb 040h,041h,042h,04fh,052h,054h,0ffh	; 73fb

; ======================================================================
; CODIGO 0x7402..0x7473  (113 bytes)
; ======================================================================


L_7402:
	call L_742B		;7402
	call L_7435		;7405
	call L_7478		;7408
	xor a			;740b
	ret			;740c

; ----------------------------------------------------------------------
; SACAR UN BYTE A LA IMPRESORA. Antes de cada byte se mira el teclado -para poder abortar- y se comprueba con LPTSTT que la impresora este lista.
; ----------------------------------------------------------------------
a_la_impresora:
	push ix		;740d
	push hl			;740f   ; se salvan todos los registros: la impresora es lenta y por medio pasa de todo
	push de			;7410
	push bc			;7411
	push af			;7412
	push af			;7413
L_7414:
	call L_7275		;7414   ; el teclado, por si se aborta
	call 000a8h		;7417   ; BIOS LPTSTT - Tests printer status | y LPTSTT, que dice si la impresora esta lista
	jr z,L_7414		;741a   ; si no esta lista, se vuelve a mirar
	cp 0ffh		;741c
	jr nz,L_7414		;741e
	pop af			;7420
	call 000a5h		;7421   ; BIOS LPTOUT - Sends one character to printer
	pop af			;7424
	pop bc			;7425
	pop de			;7426
	pop hl			;7427
	pop ix		;7428
	ret			;742a
L_742B:
	ld b,004h		;742b
L_742D:
	ld a,020h		;742d
	call a_la_impresora		;742f
	djnz L_742D		;7432
	ret			;7434
L_7435:
	ld b,000h		;7435
	ld h,000h		;7437
L_7439:
	push bc			;7439
	push hl			;743a
	call L_7462		;743b
	ld b,0c0h		;743e
L_7440:
	push bc			;7440   ; IMPRIMIR UNA COLUMNA DE PUNTOS, de abajo arriba: el cabezal de la impresora va al reves que la pantalla
	ld l,b			;7441
	dec l			;7442
	ld (0dd71h),hl		;7443   ; la posicion, que baja de una en una
	call L_751A		;7446   ; se lee el punto de la pantalla
	call a_la_impresora		;7449   ; y se manda
	ld hl,(0dd71h)		;744c
	pop bc			;744f
	djnz L_7440		;7450
	pop hl			;7452
	inc h			;7453   ; columna siguiente
	pop bc			;7454
	djnz L_7439		;7455
	ld a,00dh		;7457   ; acabada la banda, retorno de carro...
	call a_la_impresora		;7459
	ld a,00ah		;745c   ; ...y salto de linea
	call a_la_impresora		;745e
	ret			;7461
L_7462:
	push hl			;7462
	push bc			;7463
	ld hl,07473h		;7464
	ld b,005h		;7467
L_7469:
	ld a,(hl)			;7469
	inc hl			;746a
	call a_la_impresora		;746b   ; saca los bytes uno a uno a la impresora
	djnz L_7469		;746e
	pop bc			;7470
	pop hl			;7471
	ret			;7472

; ----------------------------------------------------------------------
; DATOS escape_i192: ESC "I192", cinco bytes que 0x7464 saca de uno en uno con
;   el ld b,005h de 0x7467. Es una orden de la impresora, no un texto para
;   leer
;   0x7473..0x7478  (5 bytes)
DATA_escape_i192:
	defb 01bh,049h,031h,039h,032h	; 7473

; ======================================================================
; CODIGO 0x7478..0x76be  (582 bytes)
; ======================================================================


L_7478:
	ld b,008h		;7478
L_747A:
	call L_7480		;747a
	djnz L_747A		;747d
	ret			;747f
L_7480:
	ld a,00dh		;7480
	call a_la_impresora		;7482
	ld a,00ah		;7485
	jp a_la_impresora		;7487
L_748A:
	ld b,020h		;748a
	ld c,000h		;748c
L_748E:
	push bc			;748e
	ld a,c			;748f
	call L_74E8		;7490   ; mira que casilla es
	cp 0d2h		;7493   ; las 0xD2 y 0xD1 tienen trato aparte
	jr z,L_74B5		;7495
	cp 0d1h		;7497
	jr z,L_74BA		;7499
	call L_74BC		;749b
	ld b,010h		;749e   ; dieciseis bits por casilla

; ----------------------------------------------------------------------
; APUNTAR UN COLOR QUE SE HA VISTO. Guarda hasta cuatro colores distintos por franja, que es lo que la impresora puede distinguir.
; ----------------------------------------------------------------------
L_74A0:
	ld a,(hl)			;74a0
	cp 004h		;74a1   ; cuatro como mucho
	jr nc,L_74AE		;74a3
	inc a			;74a5
	ld (hl),a			;74a6
	ld e,a			;74a7
	ld d,000h		;74a8
	push hl			;74aa
	add hl,de			;74ab
	ld (hl),c			;74ac   ; y se apunta el nuevo
	pop hl			;74ad
L_74AE:
	ld a,005h		;74ae
	call L_626E		;74b0
	djnz L_74A0		;74b3
L_74B5:
	pop bc			;74b5
	inc c			;74b6
	djnz L_748E		;74b7
	ret			;74b9
L_74BA:
	pop bc			;74ba
	ret			;74bb

; ----------------------------------------------------------------------
; DONDE EMPIEZA UNA FILA EN LA COPIA DE LA PANTALLA. Multiplica por cinco -por cuatro mas uno- y suma 0xD9B1, que es donde vive la copia.
; ----------------------------------------------------------------------
L_74BC:
	push de			;74bc
	push bc			;74bd
	ld l,a			;74be
	ld h,000h		;74bf
	ld b,h			;74c1
	ld c,l			;74c2
	add hl,hl			;74c3   ; por cuatro
	add hl,hl			;74c4
	add hl,bc			;74c5   ; mas uno: por cinco
	ld de,0d9b1h		;74c6   ; y la base de la copia
	add hl,de			;74c9
	pop bc			;74ca
	pop de			;74cb
	ret			;74cc

; ----------------------------------------------------------------------
; DONDE ESTA EL ATRIBUTO DE UN SPRITE. Por cuatro -que es lo que ocupa cada atributo- mas 0x3B00, que es donde este cartucho pone la tabla.
; ----------------------------------------------------------------------
L_74CD:
	push de			;74cd
	ld l,a			;74ce
	ld h,000h		;74cf
	add hl,hl			;74d1   ; por cuatro: fila, columna, patron y color
	add hl,hl			;74d2
	ld de,03b00h		;74d3   ; y la base de los atributos
	add hl,de			;74d6
	pop de			;74d7
	ret			;74d8

; ----------------------------------------------------------------------
; DONDE ESTA EL DIBUJO DE UNA CASILLA. La casilla por ocho, redondeando a cuatro, mas 0x1800: la base de la tabla de patrones que este cartucho declara.
; ----------------------------------------------------------------------
L_74D9:
	push de			;74d9
	and 0fch		;74da   ; redondea a cuatro
	ld l,a			;74dc
	ld h,000h		;74dd
	add hl,hl			;74df   ; por ocho: lo que ocupa cada dibujo
	add hl,hl			;74e0
	add hl,hl			;74e1
	ld de,01800h		;74e2   ; y la base de los patrones
	add hl,de			;74e5
	pop de			;74e6
	ret			;74e7
L_74E8:
	push hl			;74e8
	call L_74CD		;74e9
	call 0004ah		;74ec   ; BIOS RDVRM - Reads the content of VRAM
	inc a			;74ef
	pop hl			;74f0
	ret			;74f1
L_74F2:
	push hl			;74f2
	push bc			;74f3
	call L_74CD		;74f4
	inc hl			;74f7
	call 0004ah		;74f8   ; BIOS RDVRM - Reads the content of VRAM
	pop bc			;74fb
	pop hl			;74fc
	ret			;74fd
L_74FE:
	push hl			;74fe
	push af			;74ff
	call L_74CD		;7500
	call 0004ah		;7503   ; BIOS RDVRM - Reads the content of VRAM
	inc a			;7506
	ld c,a			;7507
	inc hl			;7508
	call 0004ah		;7509   ; BIOS RDVRM - Reads the content of VRAM
	ld b,a			;750c
	inc hl			;750d
	call 0004ah		;750e   ; BIOS RDVRM - Reads the content of VRAM
	ld e,a			;7511
	inc hl			;7512
	call 0004ah		;7513   ; BIOS RDVRM - Reads the content of VRAM
	ld d,a			;7516
	pop af			;7517
	pop hl			;7518
	ret			;7519

; ----------------------------------------------------------------------
; EL PUNTO, EN TRES PASOS. Primero mira los colores de la franja, luego lee el punto del dibujo, y por ultimo decide si contrasta. Cualquiera de los tres puede cortar.
; ----------------------------------------------------------------------
L_751A:
	call L_7528		;751a
	or a			;751d   ; si la franja no tiene colores apuntados, no hay punto
	ret nz			;751e
	call L_75B6		;751f
	or a			;7522
	ret nz			;7523
	call L_75AB		;7524
	ret			;7527
L_7528:
	ld hl,(0dd71h)		;7528   ; EL COLOR DE UNA FRANJA: cuantos distintos se apuntaron y cuales
	ld a,l			;752b
	call L_74BC		;752c
	ld a,(hl)			;752f
	or a			;7530   ; sin ninguno apuntado, nada que imprimir
	ret z			;7531
	ld b,a			;7532
	inc hl			;7533
	ld a,010h		;7534
	dec a			;7536

; ----------------------------------------------------------------------
; SI UN PUNTO SE VE O NO. Con el color de la casilla en la mano decide si el punto contrasta con el fondo: lo que se imprime es la forma, y un dibujo del mismo color que el fondo no se imprime.
; ----------------------------------------------------------------------
L_7537:
	push bc			;7537
	push af			;7538
	ld b,a			;7539
	ld a,(hl)			;753a
	call L_74F2		;753b   ; el color de esta casilla
	ld c,a			;753e
	add a,b			;753f
	ld b,a			;7540
	ld de,(0dd71h)		;7541
	jr c,L_755D		;7545
	ld a,d			;7547
	cp c			;7548   ; se compara con el de al lado
	jr c,L_7556		;7549
	ld a,b			;754b
	cp d			;754c
	jr c,L_7556		;754d
L_754F:
	ld a,(hl)			;754f
	call L_756A		;7550   ; y si contrasta, se saca el punto
	or a			;7553
	jr nz,L_7567		;7554
L_7556:
	pop af			;7556
	pop bc			;7557
	inc hl			;7558
	djnz L_7537		;7559   ; hasta acabar la franja
	xor a			;755b
	ret			;755c
L_755D:
	ld a,d			;755d
	cp c			;755e   ; se compara con los colores apuntados
	jr nc,L_754F		;755f
	ld a,b			;7561
	cp d			;7562   ; por los dos lados
	jr nc,L_754F		;7563
	jr L_7556		;7565
L_7567:
	pop hl			;7567
	pop hl			;7568
	ret			;7569

; ----------------------------------------------------------------------
; UN PUNTO DE LA PANTALLA, SI O NO. Con la casilla ya localizada, saca el bit que toca y ademas mira el color: un punto solo se imprime si su tinta se distingue del fondo.
; ----------------------------------------------------------------------
L_756A:
	push hl			;756a
	push de			;756b
	push bc			;756c
	call L_74FE		;756d   ; localiza la casilla
	push de			;7570
	push de			;7571
	call corrige_el_desplazamiento		;7572   ; y por si la pantalla esta desplazada, la corrige
	pop de			;7575
	ld a,e			;7576
	push hl			;7577
	call L_74D9		;7578
	pop de			;757b
	push de			;757c
	ld d,000h		;757d
	add hl,de			;757f
	call 0004ah		;7580   ; BIOS RDVRM - Reads the content of VRAM | RDVRM: el byte del dibujo
	pop bc			;7583
	inc b			;7584
L_7585:
	add a,a			;7585   ; y se van sacando bits por arriba
	djnz L_7585		;7586
	jr c,L_7590		;7588
	pop af			;758a
	xor a			;758b
L_758C:
	pop bc			;758c
	pop de			;758d
	pop hl			;758e
	ret			;758f
L_7590:
	pop af			;7590
	and 00fh		;7591
	jr L_758C		;7593

; ----------------------------------------------------------------------
; CORREGIR EL DESPLAZAMIENTO DE LA PANTALLA. Resta el desplazamiento y, si se sale por arriba, da la vuelta ocho filas abajo y dieciseis columnas a la derecha.
; ----------------------------------------------------------------------
corrige_el_desplazamiento:
	ld hl,(0dd71h)		;7595
	ld a,h			;7598
	sub b			;7599   ; se le resta el desplazamiento
	ld h,a			;759a
	ld a,l			;759b
	sub c			;759c
	ld l,a			;759d
	ld a,h			;759e
	cp 008h		;759f   ; si no se sale por arriba, ya esta
	ret c			;75a1
	ld a,h			;75a2
	sub 008h		;75a3   ; y si se sale, se da la vuelta: ocho filas abajo
	ld h,a			;75a5
	ld a,l			;75a6
	add a,010h		;75a7   ; y dieciseis columnas a la derecha
	ld l,a			;75a9
	ret			;75aa

; ----------------------------------------------------------------------
; EL ANCHO DEL MODO DE PANTALLA. La BIOS guarda el modo en 0xF3E6; el 4 va de una forma y todo lo demas, de otra.
; ----------------------------------------------------------------------
L_75AB:
	ld a,(0f3e6h)		;75ab   ; el modo, que la BIOS deja en 0xF3E6
	and 00fh		;75ae
	cp 004h		;75b0   ; el 4 tiene su propio ancho
	ret z			;75b2
	ld a,001h		;75b3
	ret			;75b5

; ----------------------------------------------------------------------
; DE DONDE SALE UN PUNTO DE LA PANTALLA. Traduce una posicion de pantalla a la casilla que hay alli, y de la casilla al punto concreto de su dibujo. Es lo que permite imprimir la pantalla sin tenerla en la RAM: se le pregunta a la VRAM punto por punto.
; ----------------------------------------------------------------------
L_75B6:
	ld hl,(0dd71h)		;75b6
	call posicion_a_vram		;75b9   ; la direccion de la casilla en la tabla de nombres
	call 0004ah		;75bc   ; BIOS RDVRM - Reads the content of VRAM | RDVRM: que casilla hay ahi
	ld h,000h		;75bf
	ld l,a			;75c1
	add hl,hl			;75c2   ; por ocho, que es lo que ocupa cada dibujo
	add hl,hl			;75c3
	add hl,hl			;75c4
	ld de,(0dd71h)		;75c5
	ld a,e			;75c9
	and 007h		;75ca   ; mas la fila dentro de la casilla
	ld e,a			;75cc
	ld d,000h		;75cd
	add hl,de			;75cf
	ld de,(0dd71h)		;75d0
	ld a,e			;75d4
	ld de,00000h		;75d5
	cp 040h		;75d8   ; y el tercio de pantalla, que en SCREEN 2 tiene su propio juego de dibujos
	jr c,L_75E5		;75da
	ld d,008h		;75dc
	cp 080h		;75de
	jr c,L_75E4		;75e0
	ld d,010h		;75e2
L_75E4:
	add hl,de			;75e4
L_75E5:
	ld de,(0dd71h)		;75e5
	ld a,d			;75e9
	push hl			;75ea
	ld de,02000h		;75eb
	add hl,de			;75ee
	and 007h		;75ef
	inc a			;75f1
	ld b,a			;75f2
	call 0004ah		;75f3   ; BIOS RDVRM - Reads the content of VRAM

; ----------------------------------------------------------------------
; EL COLOR DE UN PUNTO. Saca el bit que toca del byte del dibujo y, segun salga uno o cero, devuelve la tinta o el fondo de esa casilla.
; ----------------------------------------------------------------------
L_75F6:
	add a,a			;75f6   ; se desplaza hasta el bit que toca
	djnz L_75F6		;75f7
	pop hl			;75f9
	push af			;75fa
	ld de,00000h		;75fb
	add hl,de			;75fe
	call 0004ah		;75ff   ; BIOS RDVRM - Reads the content of VRAM | y se lee el byte de color
	ld b,a			;7602
	pop af			;7603
	jr c,L_760A		;7604
	ld a,b			;7606
	and 00fh		;7607   ; el nibble bajo es el fondo; el alto, la tinta
	ret			;7609
L_760A:
	ld a,b			;760a
	and 0f0h		;760b   ; el nibble ALTO del byte de color es la tinta
	rrca			;760d
	rrca			;760e
	rrca			;760f
	rrca			;7610
	ret			;7611

; ----------------------------------------------------------------------
; UNA POSICION DE PANTALLA A DIRECCION DE VRAM. Nueve desplazamientos a la derecha encadenados entre H y L: es una division entre ocho de un valor de dieciseis bits, hecha a mano porque el Z80 no divide.
; ----------------------------------------------------------------------
posicion_a_vram:
	ld a,l			;7612
	rra			;7613   ; cuatro desplazamientos de A
	rra			;7614
	rra			;7615
	rra			;7616
	rr h		;7617   ; encadenados con H, que es lo que hace que la division sea de dieciseis bits
	rra			;7619
	rr h		;761a
	rra			;761c
	rr h		;761d
	ld l,h			;761f
	and 003h		;7620   ; y los dos bits que quedan dicen el tercio
	add a,038h		;7622
	ld h,a			;7624
	ret			;7625
L_7626:
	call L_76AF		;7626
	ld b,040h		;7629
	ld h,000h		;762b
L_762D:
	push bc			;762d
	ld de,076c5h		;762e   ; la orden de la impresora
	ld a,(0d136h)		;7631
	cp 071h		;7634   ; con el codigo 0x71 va una, y si no, otra
	jr z,L_763B		;7636
	ld de,076cch		;7638
L_763B:
	call L_76B4		;763b
	ld b,0c0h		;763e   ; 0xC0 filas de pantalla
L_7640:
	push bc			;7640
	push hl			;7641
	ld l,b			;7642   ; la fila de la que se parte
	dec l			;7643
	ld (0dd71h),hl		;7644
	ld ix,0dd73h		;7647   ; IX apunta a los dos bytes que se van montando
	xor a			;764b
	ld (ix+000h),a		;764c   ; los dos, a cero
	ld (ix+001h),a		;764f
	ld bc,00403h		;7652   ; cuatro filas de tres

; ----------------------------------------------------------------------
; VOLCAR LA PANTALLA A LA IMPRESORA. Este es el trabajo gordo del modo PRINTER: leer la VRAM y convertirla en columnas de puntos. La impresora imprime en vertical -ocho puntos por golpe de cabezal-, asi que hay que girar lo que se lee.
; ----------------------------------------------------------------------
L_7655:
	push bc			;7655
	call L_751A		;7656   ; saca las casillas de una fila
	call L_76DA		;7659   ; y las convierte a los bytes de puntos, que salen en DE
	pop bc			;765c
	ld a,d			;765d
	and c			;765e   ; la mascara de este par de bits
	or (ix+000h)		;765f   ; se van juntando sobre lo que ya habia
	ld (ix+000h),a		;7662
	ld a,e			;7665
	and c			;7666
	or (ix+001h)		;7667
	ld (ix+001h),a		;766a
	rlc c		;766d   ; y la mascara se corre dos bits: cada casilla aporta dos
	rlc c		;766f
	ld hl,(0dd71h)		;7671   ; la posicion en la VRAM avanza una fila entera
	inc h			;7674
	ld (0dd71h),hl		;7675
	djnz L_7655		;7678
	ld a,(ix+000h)		;767a
	call a_la_impresora		;767d   ; y los dos bytes montados se le mandan a la impresora
	call L_769F		;7680
	ld a,(ix+001h)		;7683
	call a_la_impresora		;7686
	call L_769F		;7689
	pop hl			;768c
	pop bc			;768d
	djnz L_7640		;768e
	call L_7480		;7690   ; al acabar la banda, salto de linea
	ld a,004h		;7693
	add a,h			;7695   ; y cuatro filas mas abajo
	ld h,a			;7696
	pop bc			;7697
	djnz L_762D		;7698
	call L_7478		;769a   ; y al final del todo, el cierre
	xor a			;769d
	ret			;769e
L_769F:
	ld b,a			;769f
	ld a,(0d136h)		;76a0   ; solo con el codigo 0x72 se saca este byte
	cp 072h		;76a3
	ld a,b			;76a5
	jp z,a_la_impresora		;76a6
	ret			;76a9
L_76AA:
	ld de,076d3h		;76aa
	jr L_76B4		;76ad
L_76AF:
	ld de,076beh		;76af
	jr L_76B4		;76b2

; ----------------------------------------------------------------------
; MANDAR UNA ORDEN A LA IMPRESORA. Saca bytes hasta el 0xFF, que es lo que cierra cada secuencia de escape de 0x76BE.
; ----------------------------------------------------------------------
L_76B4:
	ld a,(de)			;76b4
	inc a			;76b5   ; 0xFF cierra la orden
	ret z			;76b6
	dec a			;76b7
	call a_la_impresora		;76b8
	inc de			;76bb
	jr L_76B4		;76bc

; ----------------------------------------------------------------------
; DATOS escapes_de_grafico: Cuatro ordenes de impresora, cada una cerrada por
;   0xFF: ESC "T16" con su salto de linea, y ESC "S0384", ESC "S0768" y ESC
;   "S0240", que son los tres anchos de volcado grafico. 0x762E elige entre
;   las dos primeras comparando (0xD136) con 0x71
;   0x76be..0x76da  (28 bytes)
DATA_escapes_de_grafico:
	defb 01bh,054h,031h,036h,00dh,00ah,0ffh	; 76be
	defb 01bh,053h,030h,033h,038h,034h,0ffh	; 76c5
	defb 01bh,053h,030h,037h,036h,038h,0ffh	; 76cc
	defb 01bh,053h,030h,032h,034h,030h,0ffh	; 76d3

; ======================================================================
; CODIGO 0x76da..0x76e7  (13 bytes)
; ======================================================================


L_76DA:
	push hl			;76da
	ld hl,076e7h		;76db
	add a,a			;76de   ; por dos: son palabras
	call L_626E		;76df
	ld d,(hl)			;76e2   ; y salen los dos bytes de la trama
	inc hl			;76e3
	ld e,(hl)			;76e4
	pop hl			;76e5
	ret			;76e6

; ----------------------------------------------------------------------
; DATOS tramas_de_impresion: Dieciseis palabras que 0x76DB indexa con `add
;   a,a`: los pares de bytes con los que se imprime cada combinacion de
;   puntos. Solo salen cuatro valores -0x00, 0x55, 0xAA y 0xFF-, que son el
;   vacio, las dos medias tramas alternas y el lleno
;   0x76e7..0x7707  (32 bytes)
DATA_tramas_de_impresion:
	defb 0ffh,0ffh	; 76e7
	defb 0ffh,0ffh	; 76e9
	defb 055h,0aah	; 76eb
	defb 000h,055h	; 76ed
	defb 0aah,0ffh	; 76ef
	defb 0aah,0aah	; 76f1
	defb 0ffh,0aah	; 76f3
	defb 000h,0aah	; 76f5
	defb 0aah,055h	; 76f7
	defb 0aah,000h	; 76f9
	defb 0ffh,000h	; 76fb
	defb 000h,055h	; 76fd
	defb 0ffh,055h	; 76ff
	defb 000h,0ffh	; 7701
	defb 055h,000h	; 7703
	defb 000h,000h	; 7705

; ======================================================================
; CODIGO 0x7707..0x7868  (353 bytes)
; ======================================================================


L_7707:
	call L_76AF		;7707
	ld a,(0dd76h)		;770a
	srl a		;770d   ; entre cuatro: cada golpe del cabezal cubre cuatro columnas
	srl a		;770f
	ld b,a			;7711
	ld h,000h		;7712
L_7714:
	push bc			;7714
	call L_76AA		;7715
	ld a,(0dd75h)		;7718
	ld b,a			;771b
L_771C:
	push bc			;771c
	push hl			;771d
	ld l,b			;771e   ; la fila, igual que en la otra
	dec l			;771f
	ld (0dd71h),hl		;7720
	ld ix,0dd73h		;7723   ; los mismos dos bytes de trabajo
	xor a			;7727
	ld (ix+000h),a		;7728
	ld (ix+001h),a		;772b
	ld bc,00403h		;772e   ; y el mismo cuatro por tres
L_7731:
	push bc			;7731   ; LA OTRA FORMA DE VOLCAR, la misma cuenta con otro lector
	call L_776F		;7732   ; el lector, que aqui saca de la copia en RAM y no de la VRAM
	pop bc			;7735
	ld a,d			;7736
	and c			;7737   ; la mascara del par de bits que toca
	or (ix+000h)		;7738
	ld (ix+000h),a		;773b
	ld a,e			;773e
	and c			;773f
	or (ix+001h)		;7740
	ld (ix+001h),a		;7743
	rlc c		;7746   ; y se corre dos, igual que en la otra
	rlc c		;7748
	ld hl,0dd72h		;774a
	inc (hl)			;774d   ; aqui la posicion avanza de uno en uno, no de fila en fila
	djnz L_7731		;774e
	ld a,(ix+000h)		;7750
	call a_la_impresora		;7753   ; los dos bytes montados, a la impresora
	ld a,(ix+001h)		;7756
	call a_la_impresora		;7759
	pop hl			;775c
	pop bc			;775d
	djnz L_771C		;775e
	call L_7480		;7760   ; salto de linea al acabar la banda
	ld a,004h		;7763
	add a,h			;7765
	ld h,a			;7766
	pop bc			;7767
	djnz L_7714		;7768
	call L_7478		;776a   ; y el cierre al final
	xor a			;776d
	ret			;776e

; ----------------------------------------------------------------------
; LEER UN PUNTO DE LA COPIA EN RAM. La hermana de 0x756A, pero mirando la copia de la pantalla que hay en 0xD9B1 en vez de la VRAM.
; ----------------------------------------------------------------------
L_776F:
	ld hl,(0dd71h)		;776f
	call L_7798		;7772   ; localiza la casilla
	ld a,(hl)			;7775
	call L_77C9		;7776   ; y de ahi, su dibujo
	ld de,(0dd71h)		;7779
	ld a,e			;777d
	and 007h		;777e   ; la fila dentro de la casilla
	ld e,a			;7780
	ld d,000h		;7781
	add hl,de			;7783
	ld a,(0dd72h)		;7784
	and 007h		;7787   ; y la columna, para saber que bit
	inc a			;7789
	ld b,a			;778a
	ld a,(hl)			;778b
L_778C:
	add a,a			;778c   ; se saca desplazando
	djnz L_778C		;778d
	ld de,00000h		;778f
	jr nc,L_7797		;7792
	ld de,0ffffh		;7794
L_7797:
	ret			;7797

; ----------------------------------------------------------------------
; LO MISMO CON LOS EJES CAMBIADOS. Divide entre ocho la columna y la fila -tres desplazamientos a la derecha- y compone la direccion, sumandole 0xD9B1, que es donde esta la copia de la pantalla en RAM.
; ----------------------------------------------------------------------
L_7798:
	push hl			;7798
	ld a,l			;7799   ; la columna: dividida entre ocho con tres desplazamientos
	and 0f8h		;779a
	rrca			;779c
	rrca			;779d
	rrca			;779e
	ld h,a			;779f
	ld a,(0dd76h)		;77a0   ; y la anchura de la hoja, tambien entre ocho
	and 0f8h		;77a3
	rrca			;77a5
	rrca			;77a6
	rrca			;77a7
	call L_77BB		;77a8   ; multiplica por el ancho
	pop hl			;77ab
	ld a,h			;77ac   ; la fila, igual
	and 0f8h		;77ad
	rrca			;77af
	rrca			;77b0
	rrca			;77b1
	ex de,hl			;77b2
	call L_626E		;77b3
	ld bc,0d9b1h		;77b6   ; y la base de la copia en RAM
	add hl,bc			;77b9
	ret			;77ba
L_77BB:
	ld e,a			;77bb   ; MULTIPLICAR POR EL ANCHO, ocho vueltas de sumas y desplazamientos
	ld d,000h		;77bc
	ld l,d			;77be
	ld b,008h		;77bf
L_77C1:
	add hl,hl			;77c1
	jr nc,L_77C5		;77c2
	add hl,de			;77c4
L_77C5:
	djnz L_77C1		;77c5
	ex de,hl			;77c7
	ret			;77c8

; ----------------------------------------------------------------------
; DONDE EMPIEZA EL DIBUJO DE UNA CASILLA EN LA ROM DE LA BIOS. La casilla por ocho, mas la direccion que la BIOS guarda en 0x0004: la tabla de caracteres. Asi el volcado a la impresora puede sacar las letras del sistema.
; ----------------------------------------------------------------------
L_77C9:
	ld h,000h		;77c9
	ld l,a			;77cb
	add hl,hl			;77cc   ; por ocho
	add hl,hl			;77cd
	add hl,hl			;77ce
	ld b,h			;77cf
	ld c,l			;77d0
	ld hl,(00004h)		;77d1   ; y la tabla de caracteres, que la BIOS deja apuntada en 0x0004
	add hl,bc			;77d4
	ret			;77d5

; ----------------------------------------------------------------------
; EL FONDO DEL MENU.
; EL FONDO DEL MENU. Cuatro bloques comprimidos y un relleno, con los destinos de VRAM de ESTE cartucho: color en 0x0000, patrones en 0x2000, nombres en 0x3800, patrones de sprite en 0x1800 y sus atributos en 0x3B00. Lo dicen los ocho registros de 0x6284, no la disposicion de siempre.
; ----------------------------------------------------------------------
L_77D6:
	ld a,0f0h		;77d6
	ld hl,00300h		;77d8
	ld bc,001d8h		;77db
	call 00056h		;77de   ; BIOS FILVRM - Fills VRAM with value | rellena de 0xF0 los 0x1D8 bytes de la VRAM 0x0300
	ld de,02300h		;77e1
	ld hl,07b90h		;77e4
	call L_62E4		;77e7   ; los patrones, primera mitad
	ld de,02508h		;77ea
	ld hl,07ccfh		;77ed
	call L_62E4		;77f0   ; y segunda
	ld de,00508h		;77f3
	ld hl,0799fh		;77f6
	call L_62E4		;77f9   ; el color
	ld de,01800h		;77fc
	ld hl,07b43h		;77ff
	jp L_62FB		;7802   ; y los patrones de sprite, que van una sola vez

; ----------------------------------------------------------------------
; LA PANTALLA DE TITULO. Seis piezas: dos rectangulos de caracteres, un bloque de rotulos, dos bloques comprimidos y los atributos de los sprites.
; ----------------------------------------------------------------------
L_7805:
	ld a,0fch		;7805
	ld hl,00980h		;7807
	ld bc,00180h		;780a
	call 00056h		;780d   ; BIOS FILVRM - Fills VRAM with value | rellena de 0xFC los 0x180 bytes de la VRAM 0x0980
	ld hl,07920h		;7810
	ld de,03865h		;7813
	ld bc,00316h		;7816
	call pinta_rectangulo		;7819   ; el rectangulo grande: tres filas de 22 casillas
	ld hl,07962h		;781c
	ld de,0389ah		;781f
	ld bc,00302h		;7822
	call pinta_rectangulo		;7825   ; y otro de tres por dos
	ld hl,07968h		;7828
	call pinta_rotulos		;782b   ; los rotulos, entre ellos el (C) KONAMI 1986
	ld hl,07868h		;782e
	call descomprime_a_vram		;7831   ; el primer bloque comprimido
	ld hl,07894h		;7834
	ld de,039a6h		;7837
	ld bc,00314h		;783a
	call pinta_rectangulo		;783d   ; otro rectangulo, tres por 20
	ld hl,078d0h		;7840
	call descomprime_a_vram		;7843   ; el segundo comprimido
	ld de,03b00h		;7846
	ld hl,07977h		;7849   ; y los 24 bytes de atributos de sprite
	ld bc,00018h		;784c
	jp 0005ch		;784f   ; BIOS LDIRVM - Block transfers to VRAM from memory

; ----------------------------------------------------------------------
; PINTAR UN RECTANGULO DE CARACTERES. B filas por C columnas, saltando de 32 en 32 por la tabla de nombres.
; ----------------------------------------------------------------------
pinta_rectangulo:
	push bc			;7852
	push hl			;7853
	ld b,000h		;7854   ; B a cero: cada fila se copia con la C que llego, no con BC entero
	push bc			;7856
	push de			;7857
	call 0005ch		;7858   ; BIOS LDIRVM - Block transfers to VRAM from memory | una fila a la VRAM
	pop hl			;785b
	ld bc,00020h		;785c   ; y 0x20 mas alla: la siguiente fila de la pantalla
	add hl,bc			;785f
	ex de,hl			;7860
	pop bc			;7861
	pop hl			;7862
	add hl,bc			;7863   ; mientras el origen avanza lo ancho que sea el bloque
	pop bc			;7864
	djnz pinta_rectangulo		;7865   ; tantas filas como diga B
	ret			;7867

; ----------------------------------------------------------------------
; DATOS gfx_titulo_1: Comprimido; lo suelta 0x782E
;   0x7868..0x7894  (44 bytes)
DATA_gfx_titulo_1:
	defb 04dh,039h,00ch,00ch,001h,0a1h,080h,067h,039h,084h,0a2h,0a3h,0a4h,0a5h,002h,000h	; 7868  M9.....g9.......
	defb 003h,00ch,086h,040h,04dh,045h,04eh,055h,040h,003h,00ch,001h,0a1h,080h,087h,039h	; 7878  ...@MENU@......9
	defb 084h,0a6h,0a7h,0a8h,0a9h,002h,000h,00ch,00ch,001h,0a1h,000h	; 7888  ............

; ----------------------------------------------------------------------
; DATOS titulo_rectangulo_3x20: 60 caracteres, 3 filas de 20, a la VRAM 0x39A6
;   desde 0x7834
;   0x7894..0x78d0  (60 bytes)
DATA_titulo_rectangulo_3x20:
	defb 000h,0aah,0abh,0ach,0adh,000h,000h,0aeh,0afh,00ch,047h,041h,04dh,045h,00ch,00ch,00ch,00ch,00ch,0a1h	; 7894  ..........GAME......
	defb 0b0h,0b1h,0b2h,0b3h,0b4h,0b5h,0b6h,0b7h,0b8h,00ch,04dh,04fh,044h,049h,046h,059h,00ch,00ch,00ch,0a1h	; 78a8  ..........MODIFY....
	defb 0b9h,0bah,0bbh,0bch,0bdh,0beh,000h,00ch,00ch,00ch,053h,045h,04ch,046h,00ch,00ch,00ch,00ch,00ch,0a1h	; 78bc  ..........SELF......

; ----------------------------------------------------------------------
; DATOS gfx_titulo_2: Comprimido; lo suelta 0x7840
;   0x78d0..0x7920  (80 bytes)
DATA_gfx_titulo_2:
	defb 006h,03ah,087h,0bfh,0c0h,00fh,00fh,0c1h,0c2h,000h,00ch,00ch,001h,0a1h,080h,025h	; 78d0  .:.............%
	defb 03ah,08ah,0c3h,0c4h,0c5h,0c6h,00fh,0c7h,0c8h,0c9h,0cah,0cbh,008h,0cah,083h,0cch	; 78e0  :...............
	defb 0cah,0cdh,080h,040h,03ah,005h,0ceh,08ah,0cfh,0d0h,0d1h,0d2h,0d3h,0d4h,0d5h,0d6h	; 78f0  ...@:...........
	defb 0ceh,0d7h,008h,0ceh,001h,0d8h,008h,0ceh,005h,0d9h,001h,0dah,006h,0dbh,083h,0dch	; 7900  ................
	defb 0ddh,0deh,008h,0dfh,082h,0e0h,0e1h,007h,0d9h,020h,0e2h,020h,0e2h,020h,0e3h,000h	; 7910  ......... . . ..

; ----------------------------------------------------------------------
; DATOS titulo_rectangulo_3x22: 66 caracteres, 3 filas de 22, a la VRAM 0x3865
;   desde 0x7810
;   0x7920..0x7962  (66 bytes)
DATA_titulo_rectangulo_3x22:
	defb 060h,061h,062h,063h,064h,065h,066h,063h,067h,07ah,065h,07bh,07ch,07dh,060h,07eh,063h,061h,063h,07fh,063h,080h	; 7920  `abcdefcgze{|}`~cac.c.
	defb 068h,069h,06ah,06bh,06ch,06dh,06eh,06fh,070h,081h,06dh,077h,082h,083h,084h,085h,086h,087h,088h,089h,088h,08ah	; 7936  hijklmnop.mw..........
	defb 071h,072h,073h,074h,075h,076h,077h,078h,079h,08ch,076h,08dh,08eh,08fh,090h,091h,08ch,092h,093h,094h,095h,096h	; 794c  qrstuvwxy.v...........

; ----------------------------------------------------------------------
; DATOS titulo_rectangulo_3x2: 6 caracteres, 3 filas de 2, a la VRAM 0x389A
;   desde 0x781C
;   0x7962..0x7968  (6 bytes)
DATA_titulo_rectangulo_3x2:
	defb 08ah,08bh	; 7962
	defb 096h,097h	; 7964
	defb 098h,099h	; 7966

; ----------------------------------------------------------------------
; DATOS rotulos_copyright: El (c) KONAMI 1986 de la pantalla de titulo, que es
;   lo que fecha esta compilacion. Lo pinta el ld hl de 0x7828
;   0x7968..0x7977  (15 bytes)
DATA_rotulos_copyright:
	defb 0eah,038h,09ah,04bh,04fh,04eh,041h,04dh,049h,000h,031h,039h,038h,036h,0ffh	; 7968  .8.KONAMI.1986.

; ----------------------------------------------------------------------
; DATOS titulo_sprites: 24 bytes a la VRAM 0x3B00, que es la tabla de
;   atributos de sprite: seis sprites de cuatro bytes (fila, columna, patron,
;   color)
;   0x7977..0x798f  (24 bytes)
DATA_titulo_sprites:
	defb 067h,050h,000h,00fh	; 7977
	defb 05fh,030h,010h,00fh	; 797b
	defb 08ah,034h,00ch,00fh	; 797f
	defb 093h,060h,008h,00ah	; 7983
	defb 08bh,04dh,014h,001h	; 7987
	defb 086h,032h,004h,001h	; 798b

; ----------------------------------------------------------------------
; DATOS menu_sprites_alternos: Los otros cuatro atributos de sprite del menu,
;   que 0x52C8 copia a la VRAM 0x3B08. Se turnan con los CUATRO ULTIMOS de
;   titulo_sprites -0x797F, que carga 0x52C3-: el bit 0 de (0xD144), que
;   0x5291 incrementa en cada vuelta del bucle de eleccion, elige una tanda u
;   otra. O sea que el adorno del menu se mueve
;   0x798f..0x799f  (16 bytes)
DATA_menu_sprites_alternos:
	defb 08eh,02eh,018h,001h	; 798f
	defb 08eh,02eh,01ch,00ah	; 7993
	defb 08bh,04dh,014h,001h	; 7997
	defb 093h,060h,008h,00ah	; 799b

; ----------------------------------------------------------------------
; DATOS gfx_menu_color: Comprimido. 0x77F6 lo suelta con 0x62E4, que repite el
;   MISMO bloque tres veces sumando 0x800: 680 bytes en la VRAM 0x0508, 0x0D08
;   y 0x1508, o sea la tabla de COLOR de los tres tercios (R3=0x7F, base
;   0x0000)
;   0x799f..0x7b43  (420 bytes)
DATA_gfx_menu_color:
	defb 008h,0b0h,004h,000h,007h,010h,003h,041h,005h,010h,003h,041h,002h,010h,004h,000h	; 799f  .......A...A....
	defb 005h,010h,082h,000h,040h,007h,010h,003h,041h,002h,0f1h,083h,0f4h,010h,010h,003h	; 79af  ....@...A.......
	defb 041h,002h,0f1h,084h,0f4h,010h,000h,040h,00dh,010h,002h,0f0h,003h,0f1h,085h,0f0h	; 79bf  A......@........
	defb 0fah,0fah,0f0h,0f0h,003h,0f1h,083h,0f0h,0fah,0fah,008h,010h,005h,0c0h,003h,0fch	; 79cf  ................
	defb 081h,0c0h,005h,0fch,082h,0c0h,0c1h,003h,000h,008h,010h,004h,0a1h,083h,041h,0fah	; 79df  ..............A.
	defb 0a1h,003h,0a0h,003h,0a1h,082h,0fah,0a1h,003h,0a0h,003h,0a1h,002h,010h,081h,041h	; 79ef  ...............A
	defb 004h,0a1h,082h,041h,010h,005h,041h,003h,010h,081h,0f1h,004h,010h,002h,0c0h,002h	; 79ff  ...A..A.........
	defb 0fch,005h,0c1h,081h,0c0h,003h,0c1h,005h,0c0h,008h,010h,008h,0f1h,003h,0fah,005h	; 7a0f  ................
	defb 0f0h,002h,0eah,083h,0fah,0feh,0feh,003h,0f0h,002h,0e1h,006h,0f1h,00fh,010h,081h	; 7a1f  ................
	defb 0a0h,00ch,0f1h,004h,0f0h,008h,010h,006h,000h,007h,0a0h,003h,0a1h,008h,0fah,008h	; 7a2f  ................
	defb 0f1h,004h,0feh,081h,0f1h,003h,0feh,004h,010h,004h,0e0h,081h,0f0h,003h,0e0h,004h	; 7a3f  ................
	defb 000h,084h,0fah,0feh,0e0h,0e0h,004h,000h,084h,0fah,0feh,0e0h,010h,004h,0e0h,084h	; 7a4f  ................
	defb 0fah,0feh,0e0h,010h,004h,0e0h,081h,0f0h,003h,0e0h,004h,000h,094h,054h,000h,054h	; 7a5f  .............T.T
	defb 000h,054h,000h,000h,054h,0a4h,000h,054h,000h,054h,010h,010h,041h,0a4h,0a0h,0a4h	; 7a6f  .T..T..T.T..A...
	defb 0a0h,003h,0a1h,081h,010h,003h,0fah,004h,0eah,081h,010h,003h,0f0h,002h,0feh,003h	; 7a7f  ................
	defb 0e0h,003h,0f0h,004h,0feh,082h,0e1h,0feh,006h,0eah,084h,0a1h,0e4h,0a0h,0a4h,005h	; 7a8f  ................
	defb 0a1h,09bh,054h,000h,054h,000h,054h,010h,010h,041h,0e4h,0e0h,0e4h,0e0h,0e4h,0e0h	; 7a9f  ..T.T.T..A......
	defb 0e0h,0e4h,0e4h,0e0h,0e4h,0e0h,0e4h,0e0h,0e0h,0e4h,000h,000h,054h,003h,000h,08ah	; 7aaf  ............T...
	defb 054h,000h,010h,010h,041h,010h,000h,000h,054h,050h,005h,041h,08eh,000h,054h,050h	; 7abf  T...A...TP.A..TP
	defb 010h,010h,041h,010h,000h,000h,054h,050h,010h,010h,051h,003h,000h,082h,054h,000h	; 7acf  ..A...TP..Q...T.
	defb 003h,0e1h,088h,010h,000h,000h,054h,000h,010h,010h,051h,003h,000h,082h,054h,000h	; 7adf  ......T...Q...T.
	defb 003h,0e1h,088h,010h,000h,000h,054h,000h,010h,010h,051h,003h,000h,081h,054h,004h	; 7aef  ......T...Q...T.
	defb 000h,081h,054h,00bh,000h,081h,054h,00ah,010h,081h,01fh,00dh,010h,002h,0c0h,081h	; 7aff  ..T...T.........
	defb 0f0h,004h,0c0h,00fh,010h,081h,01fh,011h,010h,007h,0c0h,082h,0fch,0cfh,007h,01ch	; 7b0f  ................
	defb 006h,0cfh,002h,01ch,00ch,010h,004h,0e0h,004h,0efh,081h,01fh,003h,0efh,005h,040h	; 7b1f  ...............@
	defb 002h,010h,084h,041h,0e4h,0a0h,0a4h,005h,01ah,002h,0feh,005h,0aeh,081h,0e1h,006h	; 7b2f  ...A............
	defb 01fh,002h,0afh,000h	; 7b3f

; ----------------------------------------------------------------------
; DATOS gfx_menu_patrones_de_sprite: Comprimido. 0x77FF entra por 0x62FB -la
;   puerta en la que el destino llega en DE- y suelta 256 bytes en la VRAM
;   0x1800 UNA sola vez: son los patrones de sprite (R6=0x03), ocho dibujos de
;   16x16
;   0x7b43..0x7b90  (77 bytes)
DATA_gfx_menu_patrones_de_sprite:
	defb 002h,080h,005h,0c0h,081h,080h,019h,000h,087h,001h,021h,012h,01ch,020h,000h,000h	; 7b43  ..........!.. ..
	defb 003h,080h,011h,000h,002h,004h,082h,008h,030h,003h,080h,020h,000h,081h,010h,003h	; 7b53  ........0.. ....
	defb 030h,081h,010h,02dh,000h,085h,002h,004h,000h,009h,001h,005h,003h,081h,001h,008h	; 7b63  0..-............
	defb 000h,083h,001h,006h,008h,009h,000h,084h,038h,040h,080h,080h,01ah,000h,087h,0c0h	; 7b73  ........8@......
	defb 020h,010h,008h,008h,004h,002h,00dh,000h,003h,040h,017h,000h,000h	; 7b83   ........@...

; ----------------------------------------------------------------------
; DATOS gfx_menu_patrones_1: Comprimido. 0x77E4, otra vez por los tres
;   tercios: 472 bytes en la VRAM 0x2300, 0x2B00 y 0x3300, que es la tabla de
;   PATRONES (R4=0x07, base 0x2000)
;   0x7b90..0x7ccf  (319 bytes)
DATA_gfx_menu_patrones_1:
	defb 005h,000h,083h,00fh,01fh,03fh,005h,000h,083h,0fch,0feh,0feh,006h,000h,082h,001h	; 7b90  .....?..........
	defb 003h,005h,000h,003h,0ffh,005h,000h,083h,09fh,0dfh,0dfh,005h,000h,083h,0c0h,0e1h	; 7ba0  ................
	defb 0f3h,005h,000h,003h,0fdh,005h,000h,085h,0f0h,0f8h,0f8h,07fh,0ffh,006h,0fch,084h	; 7bb0  ................
	defb 0feh,03eh,000h,000h,004h,0ffh,083h,007h,00fh,01fh,005h,03fh,083h,0ffh,0cfh,08fh	; 7bc0  .>.........?....
	defb 004h,00fh,082h,0ffh,0dfh,007h,0cfh,003h,0ffh,082h,0deh,0cch,003h,0c0h,081h,0fdh	; 7bd0  ................
	defb 007h,0fch,081h,0ffh,003h,0fch,004h,0ffh,084h,0f8h,078h,000h,000h,004h,0e0h,004h	; 7be0  ..........x.....
	defb 0fch,084h,0ffh,07fh,03fh,01fh,003h,03fh,081h,07fh,003h,0ffh,081h,0efh,004h,03fh	; 7bf0  ....?..?.......?
	defb 004h,07fh,003h,0ffh,005h,00fh,008h,0cfh,004h,0c0h,004h,0c1h,00ch,0fch,004h,0ffh	; 7c00  ................
	defb 002h,000h,002h,03eh,003h,0feh,081h,0fch,005h,000h,003h,01fh,005h,000h,003h,0fch	; 7c10  ...>............
	defb 005h,000h,083h,003h,007h,00fh,005h,000h,083h,0feh,0ffh,0ffh,005h,000h,083h,0f8h	; 7c20  ................
	defb 0fdh,0fdh,005h,000h,083h,0f8h,0fch,0fch,005h,000h,084h,0f8h,0fch,0feh,01fh,007h	; 7c30  ................
	defb 00fh,083h,01fh,03fh,07eh,004h,0fch,002h,0ffh,006h,03fh,093h,0ffh,07fh,07eh,07ch	; 7c40  ...?~.....?...~|
	defb 07eh,07fh,03fh,01fh,00fh,0fdh,03dh,000h,000h,0f8h,0fch,0feh,0ffh,0ffh,0efh,006h	; 7c50  ~.?...=.........
	defb 00fh,082h,0feh,0deh,006h,0c0h,081h,0ffh,003h,07eh,004h,07fh,084h,0fch,03ch,000h	; 7c60  .........~....<.
	defb 000h,004h,0f0h,085h,0ffh,03fh,01fh,03fh,0feh,003h,0ffh,006h,000h,002h,080h,008h	; 7c70  .....?.?........
	defb 00fh,004h,0fch,004h,0fdh,003h,0ffh,005h,0fch,003h,0ffh,005h,03fh,002h,000h,002h	; 7c80  ............?...
	defb 07ch,003h,07fh,089h,03fh,07fh,03fh,03fh,07fh,0ffh,0feh,0fch,0f8h,008h,0c0h,004h	; 7c90  |...?.??........
	defb 07eh,004h,07fh,002h,000h,002h,01fh,003h,0ffh,081h,0feh,008h,07eh,081h,03fh,006h	; 7ca0  ~...........~.?.
	defb 01fh,081h,00fh,004h,080h,004h,0c0h,002h,000h,081h,0fbh,003h,022h,004h,000h,081h	; 7cb0  ............"...
	defb 060h,003h,0a0h,002h,000h,088h,000h,01ch,022h,049h,051h,049h,022h,01ch,000h	; 7cc0  `......."IQI"..

; ----------------------------------------------------------------------
; DATOS gfx_menu_patrones_2: Comprimido. 0x77ED, tres tercios: 680 bytes en la
;   VRAM 0x2508, 0x2D08 y 0x3508. Es la segunda mitad de los patrones, y con
;   el anterior tapa 0x2300..0x27AF de cada tercio
;   0x7ccf..0x7eda  (523 bytes)
DATA_gfx_menu_patrones_2:
	defb 008h,080h,004h,000h,087h,003h,00fh,03fh,00fh,003h,00fh,03fh,003h,000h,085h,0bfh	; 7ccf  .......?...?....
	defb 07fh,0c0h,0f0h,0fch,003h,000h,082h,0fdh,0feh,004h,000h,08eh,0c0h,0f0h,0fch,0f0h	; 7cdf  ................
	defb 003h,000h,000h,003h,007h,007h,00fh,00fh,040h,03fh,003h,000h,085h,01ch,07eh,0ffh	; 7cef  ........@?....~.
	defb 002h,0fch,003h,000h,08dh,038h,07eh,0ffh,0c0h,000h,000h,0c0h,0e0h,0e0h,0f0h,0f0h	; 7cff  .....8~.........
	defb 01fh,01fh,006h,03fh,002h,0ffh,003h,0fdh,085h,0ffh,0fch,0f8h,0ffh,0ffh,003h,0bfh	; 7d0f  ...?............
	defb 085h,0ffh,03fh,01fh,0f8h,0f8h,006h,0fch,005h,0ffh,08bh,001h,006h,018h,0ffh,000h	; 7d1f  ..?.............
	defb 006h,018h,060h,080h,0ffh,0f9h,003h,000h,088h,001h,003h,007h,00fh,01fh,03fh,03fh	; 7d2f  ..`...........??
	defb 07fh,004h,001h,083h,000h,0f0h,07fh,003h,0ffh,085h,0f7h,0ebh,0fch,00fh,0feh,003h	; 7d3f  ................
	defb 0ffh,086h,0dfh,0afh,07fh,0fch,0feh,000h,004h,080h,082h,000h,00fh,005h,000h,095h	; 7d4f  ................
	defb 0feh,0f8h,0f8h,001h,0feh,0feh,0f0h,0c0h,000h,000h,060h,080h,0feh,0f9h,0e7h,09fh	; 7d5f  ..........`.....
	defb 07fh,0ffh,0e7h,09fh,07fh,005h,0ffh,081h,01fh,003h,03fh,089h,07fh,07dh,07eh,07eh	; 7d6f  ..........?..}~~
	defb 001h,007h,00fh,01fh,01fh,003h,03fh,083h,0c0h,0f0h,0f8h,005h,0ffh,083h,001h,00fh	; 7d7f  ......?.........
	defb 01fh,005h,0ffh,085h,080h,0e0h,0f0h,0f8h,0f8h,003h,0fch,081h,0e0h,003h,0c0h,004h	; 7d8f  ................
	defb 080h,084h,07dh,03dh,01fh,007h,004h,003h,004h,07fh,004h,0ffh,004h,0feh,004h,0ffh	; 7d9f  ..}=............
	defb 008h,0c0h,006h,000h,002h,001h,090h,007h,037h,07bh,078h,077h,0afh,0cfh,0dfh,07fh	; 7daf  ........7{xw....
	defb 01fh,007h,003h,001h,001h,0c0h,0e0h,004h,0ffh,081h,0feh,003h,0ffh,006h,0feh,002h	; 7dbf  ................
	defb 0fch,002h,0c0h,002h,080h,081h,0c0h,003h,0e0h,003h,00fh,005h,000h,083h,0ffh,000h	; 7dcf  ................
	defb 0ffh,005h,000h,083h,0ffh,000h,0ffh,004h,018h,084h,034h,0ffh,000h,0ffh,004h,018h	; 7ddf  ..........4.....
	defb 081h,02ch,003h,0f0h,00dh,000h,081h,001h,004h,000h,092h,007h,01fh,0c0h,0dfh,09fh	; 7def  .,..............
	defb 01fh,00fh,00fh,007h,001h,0ffh,0e0h,0e0h,0c0h,001h,001h,003h,007h,004h,0ffh,082h	; 7dff  ................
	defb 07fh,007h,006h,0ffh,095h,0fch,080h,000h,000h,0fch,0f0h,0feh,0fch,0f8h,0f8h,0e0h	; 7e0f  ................
	defb 0c0h,001h,0c0h,0f0h,0feh,0fbh,09dh,0eeh,0f6h,0f6h,005h,000h,083h,0e0h,0f8h,003h	; 7e1f  ................
	defb 003h,034h,004h,066h,081h,0c3h,003h,02ch,004h,066h,081h,0c3h,008h,000h,002h,03fh	; 7e2f  .4.f...,.f.....?
	defb 082h,0e0h,007h,00ch,000h,002h,0fch,082h,007h,0e0h,004h,000h,082h,00fh,03fh,006h	; 7e3f  ..............?.
	defb 000h,082h,0c3h,0c0h,006h,000h,002h,0ffh,006h,000h,082h,0c3h,003h,006h,000h,082h	; 7e4f  ................
	defb 0f0h,0fch,016h,000h,082h,003h,07fh,005h,0ffh,083h,0feh,0e0h,0fch,003h,0feh,088h	; 7e5f  ................
	defb 0f0h,080h,000h,0f8h,0e0h,0e0h,0c0h,0c0h,003h,080h,008h,0ffh,002h,000h,081h,0f8h	; 7e6f  ................
	defb 005h,0ffh,003h,000h,08ah,080h,0f0h,0fch,0feh,0feh,0ffh,0feh,0f0h,0c0h,0c0h,003h	; 7e7f  ................
	defb 080h,081h,0fch,007h,000h,007h,0ffh,002h,0f0h,003h,000h,087h,0f0h,00fh,000h,000h	; 7e8f  ................
	defb 0ffh,00fh,0f0h,003h,0ffh,086h,0f0h,00fh,07dh,03dh,01fh,007h,006h,003h,002h,001h	; 7e9f  ........}=......
	defb 081h,003h,003h,007h,006h,080h,002h,0c0h,098h,0ffh,000h,0ffh,000h,0ffh,007h,01fh	; 7eaf  ................
	defb 0c0h,001h,00fh,07fh,020h,046h,088h,090h,090h,01fh,007h,080h,0c0h,0c0h,0e0h,0f8h	; 7ebf  .... F..........
	defb 001h,088h,000h,000h,030h,060h,030h,000h,0c0h,0e0h,000h	; 7ecf  ....0`0....

; ----------------------------------------------------------------------
; DATOS relleno: 272 bytes a 0xFF hasta la marca. Es lo que sobro del
;   cartucho: no lo lee nadie
;   0x7eda..0x7fea  (272 bytes)
DATA_relleno:
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7eda  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7eea  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7efa  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f0a  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f1a  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f2a  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f3a  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f4a  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f5a  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f6a  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f7a  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f8a  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f9a  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7faa  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7fba  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7fca  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7fda  ................

; ----------------------------------------------------------------------
; DATOS marca_oculta_de_konami: Los ultimos veintidos bytes del cartucho:
;   "RC-735" y, en katakana, 10バイタノシムカートリッジ -"el cartucho para disfrutar diez
;   veces mas"-, que era el eslogan. La descubrio Manuel Pazos. Aqui, ademas,
;   sirvio para confirmar que el 0xBA es el alargamiento ー, que estaba sin
;   cerrar
;   0x7fea..0x8000  (22 bytes)
DATA_marca_oculta_de_konami:
	defb 0b7h,08bh,0b5h,0a7h,093h,0bah,085h,000h,0a0h,08bh,098h	; 7fea  ...........
	defb 08fh,000h,081h,0b7h,099h,000h,030h,031h,013h,035h,0aah	; 7ff5  ......01.5.
