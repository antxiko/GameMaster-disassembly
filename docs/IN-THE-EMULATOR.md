# In the emulator

## Running it on its own

    "C:/Program Files/openMSX/openmsx.exe" -machine Philips_VG_8020 \
        -cart gamemaster.rom

With no game beside it, the cartridge keeps to itself: it builds its title
screen and waits. `0x4079` reads row 7 of the keyboard and, if that key is
held, it will not enter the game even if there is one.

## Running it with a game

Which is what it is for. Two slots:

    openmsx.exe -machine Philips_VG_8020 \
        -cart gamemaster.rom -cartb <game>.rom

The Game Master has to sit in the slot **before** the game's: `0x402A` works
out the neighbour's by adding 4 to its own if it is in an expanded slot, and 1
if not.

## Dumping the VRAM and checking the pictures

This is the check that decides whether the screens on this site are the
cartridge's:

    make vram

What it does underneath:

    GM_SALIDA=work/omsx openmsx.exe -machine Philips_VG_8020 \
        -cart gamemaster.rom -script tools/omsx_vram.tcl
    python3 tools/coteja_vram.py gamemaster.rom 0x4000 work/omsx

`tools/omsx_vram.tcl` sets no breakpoints: it dumps the 16,384 bytes of VRAM
and the eight VDP registers at five moments on the emulated clock — at 8, 12,
16, 20 and 25 seconds — because **between the BIOS booting and the slot sweep
the cartridge performs, the title screen takes a while to appear**. The first
dump we tried, at 6 seconds, came out entirely black.

`tools/coteja_vram.py` compares byte for byte, picks whichever dump is closest,
checks the VDP registers and splits the differences into two groups: those at
**animated** addresses — declared, with whatever moves them — and the rest. If
one turns up that is not on the list, it comes out in red with its address.

## The two frames

The title screen is not still, which is why a check cannot always give zero:

- **`0x39A9`**, the cursor: `0x527C` alternates `0xAC` and `0xF5` every `0x8000`
  turns of the counter at `0xD147`.
- **`0x3B08`–`0x3B17`** and the tiles that go with them: `0x52C3` copies the
  sprite attributes from `0x797F` or from `0x798F` according to bit 0 of
  `0xD144`, which goes up on every turn of the menu loop. That is the ornament
  moving.

Any given dump lands on one of the two frames. What is required is that
everything else be zero.

## Looking inside while it runs

The variables that say the most, in openMSX's console:

    debug read memory 0xD12E    ; my slot
    debug read memory 0xD12F    ; the neighbour's
    debug read memory 0xD301    ; the catalogue number recognised
    debug read memory 0xD317    ; which cheats are pending
    debug read memory 0xD31A    ; the stage asked for
    debug read memory 0xD31B    ; the lives asked for

If `0xD301` is `0xFF`, the cartridge has recognised nothing: either there is no
game beside it, or its sum is not in the table.

And to watch the moment it gets in:

    debug set_bp 0x4C8F         ; just before the cpir looking for the 0x9B
    debug set_bp 0x4C9B         ; and once it has found it

Between those two points, `0xD861` onwards holds the RAM copy of the game's
start-up, still unpatched.
