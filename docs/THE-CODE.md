# The code

**10,522 bytes of traced code** (64.2%) and **5,862 of data** (35.8%), adding
up to the cartridge's 16,384: **100% explained, zero bytes unassigned**. 663
routines, **22.1% of instructions carrying a comment** and **not one routine
below 10%**.

## How it gets inside the game

This is the central idea, and it lives at `0x4C76`.

1. It copies the game's **first 256 INIT bytes** to `0xD861`, reading them from
   the other slot with RDSLT.
2. It looks in that copy for the sequence `9B FD`, which is the operand of
   `ld (0xFD9B),hl` — the instruction a game uses to install its interrupt
   routine into the BIOS's H.KEYI hook.
3. It replaces it with the five bytes at `0x4CB9`. With the `22` opcode already
   in front, the instruction goes from

       22 9B FD        ld (0xFD9B),hl

   to

       22 30 D1        ld (0xD130),hl   ; the game's hook, saved
       CD 14 D8        call 0xD814      ; and control to the Game Master

4. And it runs **the patched copy, not the original**.

So it does not patch the game: it patches the **RAM copy of its start-up**. From
then on it runs once per frame inside the game and can poke its variables.

It works across the whole catalogue because every Konami cartridge starts the
same way. Checked over the 42 cartridge ROMs in the collection: **all 40 Konami
ones carry that instruction** in the 256 bytes of their INIT. The only two that
do not are Casio World Open — not a Konami title — and the Game Master itself.

## How it knows which game is next to it

Two routes, and the order matters (`0x5E64`):

**1. The second header.** It reads two bytes from `0x4010` of the neighbour and
compares them with `AB` and `CD`. If it is `AB` it takes 19 bytes as they come;
if `CD`, 21, and it distributes them according to a **flag byte**: each `rra`
pulls out one bit saying whether the next field is present, and any field that
is missing keeps the default from `0x6034`. Only five of the 42 ROMs in the
collection carry that header.

**2. The signature table.** For everything else — which is most of the
catalogue — `0x5EF5` **adds up the 256 bytes from `0x5000` to `0x50FF`** of the
neighbour's ROM and looks that 16-bit sum up in the table at `0x5F3A`: 62
four-byte entries pointing at 29 stand-in headers of 19 bytes, for 28 games. It
is 29 and not 28 because Antarctic Adventure needs two, one per pair of its own
builds, and they differ in **a single byte**.

Either way the result ends up at `0xD300` onwards in the same format: the two
BCD pairs of the catalogue number, then pointers to the game's variables in its
RAM.

## The cheats

The table at `0x5B02` has twenty-one three-byte entries — catalogue number and
routine — and it is where whatever each game needs in particular lives. Nearly
all of them end by jumping to `0x5D13`, the universal three-instruction cheat.

What changes is the arithmetic. `0x5E0F` divides by C through subtraction and
shifts, and that C is **how many stages the game has**:

| game | by | what it writes |
|---|---|---|
| RC-701 Antarctic Adventure | 10 | the track, at `0xE0E2`, **with two tables** |
| RC-710 / RC-711 Hyper Olympic | 4 | the event, and eight bytes per cartridge |
| RC-713 Magical Tree | 9 | the level and **the starting score** |
| RC-717 Hyper Sports 2 | 3 | the event |
| RC-718 Hyper Rally | 13 | the stage and its pair of bytes |
| RC-721 Sky Jaguar | 8 | not a stage: **a position** along the run |
| RC-727 King's Valley | 15 | the room, the lap and a pair from the table |
| RC-730 Road Fighter | 6 | the course, and it clears the screen |

And two pairs **share a routine**: RC-710 with RC-711 — told apart inside by
their number — and **RC-700 with RC-716**, that is Athletic Land and Cabbage
Patch Kids.

## The menus: three pieces, always the same

Thirteen menus, all built alike:

    ld hl,<labels>       and `call 0x6294` paints them
    ld hl,<slots>        where the cursor may sit, one row per line
    ld b,<N>             how many lines it has
    call 0x6581          picks one, and returns it in A
    ...
    call 0x6368          dispatches
    <table of N pointers>    ← GLUED to the call, inside the flow

`0x6368` does a `pop hl` to grab the return address — which is the byte after
the CALL — and reads word number A from there. **The table sits inside the
code.** There are fourteen of them, and their sizes are not eyeballed: each one
comes from the `ld b,N` that precedes the `call 0x6581`. `tools/menus.py` reads
them.

## The font and the formats

- **The labels** (`0x6294`): `[VRAM address][characters]0xFE`, and `0xFF`
  closes. The letters sit where ASCII puts them, but **the blank is not
  `0x20`**: `0x00` separates words and `0x40` is the highlighted blank that
  frames the titles (`@@MENU@@`).
- **The decompressor** (`0x62F7`): RLE writing **straight to the VDP port**,
  bypassing the BIOS. Seven-bit count, bit 7 set means literals and clear means
  a repeat; a zero count closes, and if the byte was not zero outright, **another
  VRAM address and more runs follow**. That last case is easy to miss and leaves
  the decompression cut off at the first chunk.
- The `push hl / pop hl` pairs in between do nothing: they are the wait the VDP
  needs between bytes.

## Code nobody reaches

Four fragments — `0x6445`, `0x6787`, `0x6904` and `0x6938` — disassemble to
correct, well-fitted Z80: they start right after a `ret` and end right where a
label that *is* used begins. But **there is not one 16-bit reference nor one
relative jump landing on them**, searched across all 16,384 bytes.

Plus two two-byte doors (`0x5022` and `0x6FB5`), each a `ld b,N` put there to
enter the neighbouring routine with a different value, that nobody jumps to.

It is not the mirage of reading an operand as an opcode, because they do not
fall inside another instruction. They are leftovers from an earlier build:
there are three of this cartridge.
