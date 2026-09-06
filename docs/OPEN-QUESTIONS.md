# Open questions

What is **not** known. It is here, not hidden away in the other pages.

## What RC-736 and RC-737 are

The cheat table at `0x5B02` has a routine for both, so the Game Master knows
which variables to poke. But **we do not have their ROMs**, and the msxblue
manual does not list them either.

Something can be said about RC-737 from what its routine does (`0x5DF1`): it
divides by eight, caps the lap at two and writes the lives straight into
`0xE053` without going through the universal cheat. About RC-736 (`0x5DCB`) only
that it assembles a byte with the lap in the high nibble and the stage in the
low one, and that `0x5E47` gives it special treatment — putting a 4 into
`0xD312` — that no other game gets.

With the ROMs to hand this would close in an afternoon.

## The four bytes at `0x628C`

`0E 00 18 06`, glued behind the eight VDP registers. The loop at `0x6279` stops
at eight and never reads them, and searching for those four bytes across all
16,384 of the cartridge turns up not one reference.

They look like two more registers from another version: the `0x0E` and the
`0x18` would fit as R2 and R6 of a different VRAM layout. **That is a guess**,
and with no other versions to look at it goes no further.

## Why those four routines are dead

We know nobody calls them — checked over all 16,384 bytes, looking for 16-bit
references and relative jumps — and what they used to do. What we do not know is
**which build they are left over from**. There are three of this cartridge, and
the other two are the 1985 Japanese ones, relocated with respect to each other.
Comparing them instruction by instruction would say whether those fragments were
alive in either.

## The third cheat

`0x54D1` looks at three bits of `0xD317`: bit 0 is set by MODIFY PLAYER NUMBER,
bit 1 by MODIFY STAGE NUMBER, and **bit 2 is set by neither menu**. Its routine,
`0x5561`, exists and does something.

Either some path we have not walked turns it on, or it belongs to an earlier
version.

## The three builds

They are identified — two Japanese ones from 1985 and the 1986 European one,
which is the one disassembled here — and they are known to be the same program
recompiled and relocated, not different versions. What has **not** been done is
comparing them instruction by instruction to find out what changed between 1985
and 1986. The French translation and the amateur MSX2 memory-mapper patch both
derive from the European one.

## The Game Master II

RC-755, 128 KB, and outside this disassembly. It knows more games and brings its
own editor. If the first one identifies by a 256-byte sum, the obvious question
is what the second does when a game it does not know is plugged in beside it.

## What happens with a cartridge that is not Konami's

`0x4124` tries four things in a chain and only one has to pass: a cartridge
header, the `ld (0xFD9B),hl` in the first 256 bytes, the second header at
`0x4010`, or the sum being in the table. A third-party cartridge that happened
to install its interrupt with that same instruction **would pass the second
test**, and the Game Master would try to cheat it using the default header at
`0x6034`.

What happens then has not been tried, and it is worth trying.
