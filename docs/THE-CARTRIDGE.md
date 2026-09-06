# The cartridge

16 KB in page 1 (`0x4000`–`0x7FFF`), MSX1. The `AB` header declares **only
INIT** (`0x4010`); STATEMENT, DEVICE and TEXT are all zero.

## The problem it has to solve

And it is the whole design of the cartridge.

**The Game Master lives in page 1. The game it is cheating lives in page 1 as
well**, in another slot. The two cannot be switched in at once: the moment you
switch the slot to read something from the game, the Game Master vanishes from
the memory map — and with it the instruction that was executing.

Everything else follows from that:

1. **Six blocks of code are copied into RAM and executed there.** Switching the
   slot from ROM would be sawing off the branch you are sitting on.
2. Whatever lives in ROM and has to be called with the other slot in is called
   through **CALSLT** (`0x001C`) with the slot in IY, or through the `RST 30h`
   template that `0x6AAA` assembles at `0xD33E`.
3. To read a byte from the neighbour it uses **RDSLT** (`0x000C`). `0x4CA6` is
   the inter-slot LDIR: it copies BC bytes one at a time, because there is no
   other way.

When reading the listing, bear in mind that **the absolute addresses inside
those blocks point at where they run, not where they are stored**. A
`jp 0xDA4C` in the first block is a jump to its own byte `0x4C`. The tracer has
a directive, `!reubica`, that gives it that mapping; with it the trace went from
52.9% to 60.0%, and with the CALSLT entries it uncovered, to 64.2%.

The six blocks:

| in the listing | runs at | what it is |
|---|---|---|
| `0x40DE`–`0x419A` | `0xDA00` | the slot sweep looking for a cartridge |
| `0x41A8`–`0x422F` | `0xC000` | the one that also recognises the disk ROM |
| `0x4264`–`0x426F` | `0xC800` | eleven bytes: the way back from the game |
| `0x426F`–`0x4272` | `0xFEDA` | three bytes: a `jp 0xC800` in a BIOS hook |
| `0x4CCA`–`0x4D17` | `0xD814` | where the patch planted in the game jumps to |
| `0x4D17`–`0x4E61` | `0xD170` | **the interrupt hook** |

## The VRAM map

It is not the usual one, and reading it wrong throws the whole screen out. The
eight registers are at `0x6284` and `0x6273` writes them:

| register | value | what it places |
|---|---|---|
| R0 | `0x02` | graphics mode 2 |
| R1 | `0xE2` | display on, 16x16 sprites |
| R2 | `0x0E` | name table at `0x3800` |
| R3 | `0x7F` | **colour table at `0x0000`** |
| R4 | `0x07` | **pattern table at `0x2000`** |
| R5 | `0x76` | sprite attributes at `0x3B00` |
| R6 | `0x03` | sprite patterns at `0x1800` |
| R7 | `0xE1` | the border |

**R3 and R4 are not addresses: they are base and mask**, and they come out the
opposite way round from what they look like. Colour ends up at the bottom, at
`0x0000`, and patterns at the top, at `0x2000`. That is what places the four
compressed blocks of the menu background, and it is confirmed against the
registers the emulator actually holds.

Behind those eight there are **four more bytes** (`0x628C`: `0E 00 18 06`) that
nobody reads: the loop at `0x6279` stops at eight, and searching for their
addresses across all 16,384 bytes of the cartridge turns up not one reference.

## The RAM

The cartridge clears the 8 KB from `0xC000` to `0xDFFF` at boot and uses them
as workspace. The variables that matter most:

| address | what it holds |
|---|---|
| `0xD12E` | my slot · `0xD12F` the neighbour's |
| `0xD130` | the game's **own** interrupt hook, saved by the patch |
| `0xD136` | the operation code: high nibble what, low nibble on what |
| `0xD300`–`0xD31x` | the header of the game that was recognised |
| `0xD31A`, `0xD31B` | the stage and the lives the user asked for |
| `0xD317` | which cheats are pending |

And one that does two jobs: **`0xD12D` holds the PSG's channel C volume and is
also the low byte of the IY** used for inter-slot calls. It works because
CALSLT only looks at IYh.

## The hidden mark

In the last 22 bytes, `0x7FEA`–`0x7FFF`: **RC-735** and 19 katakana bytes
reading 10バイタノシムカートリッジ — "the cartridge for ten times the fun" —
which was the slogan.

The format was discovered by **Manuel Pazos**
([@ManuelPazosMSX](https://twitter.com/ManuelPazosMSX)): the title reversed,
its length, the catalogue number in BCD and a closing `0xAA`. As a bonus, this
mark **confirms that `0xBA` is the ー lengthener**, which had been left open
until now.

Before the mark there are 272 filler bytes of `0xFF` (`0x7EDA`–`0x7FEA`): what
was left over of the cartridge.
