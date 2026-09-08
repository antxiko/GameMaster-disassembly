# Findings

## The instruction all 40 Konami cartridges carry

The Game Master gets inside the game by looking for `9B FD` in the first 256
bytes of its start-up: the operand of `ld (0xFD9B),hl`, with which a Konami
game installs its interrupt routine into the H.KEYI hook.

That turns a house style decision into the key to the whole cartridge. Checked
over the 42 cartridge ROMs in the collection: **all 40 Konami ones carry it**.
The only two that do not are Casio World Open — not a Konami title — and the
Game Master itself.

## The second header, seen from the other side

**Eight** of the games here carry a second header at `0x4010` that did nothing
visible, and every one of them is disassembled in this series. The marker in
front does not follow the catalogue number, it follows the **year**:

| marker | year | cartridges |
|---|---|---|
| `AB` | 1985 | Konami's Soccer and Football (RC-732), Konami's Boxing (RC-736), Yie Ar Kung-Fu II (RC-737) |
| `CD` | 1986-87 | The Goonies (RC-734), Knightmare (RC-739), Twin Bee (RC-740), Nemesis (RC-742), F-1 Spirit (RC-752) |

RC-734 is from 1986 while RC-736 and RC-737 are from 1985, which is what rules
the number out as the criterion. We knew the header was there; not what for.

This is what for. **The Game Master reads it.** The 17 bytes at
`0x4014`–`0x4024` are pointers to the game's variables in its RAM: where it
keeps the lives, where the stage, where the score. A game that carries it
explains itself; the rest need the Game Master to invent one for them.

## The signature table: 62 entries for 28 games

For the games with no header — nearly the whole catalogue — `0x5EF5` **adds up
the 256 bytes from `0x5000` to `0x50FF`** of the neighbour's ROM and looks that
16-bit sum up in the table at `0x5F3A`. 62 four-byte entries pointing at 29
stand-in headers of 19 bytes, for 28 games: the table carries each game's
alternative builds, up to four.

**The table has been checked, not just read.** Of the 28, 25 were verified by
actually summing the bytes of their ROMs. The other three — Circus Charlie,
Magical Tree and Comic Bakery — have no ROM here and come from the manual
published at [msxblue](http://www.msxblue.com/manual/gamemaster1_c.htm).

And binary and manual agree **even in the gaps**: neither has RC-719, RC-722 or
RC-726.

A word of warning about the check: F-1 Spirit gives the same sum as Billiards
(`0x7894`). That is a collision of a 16-bit sum over 256 bytes, not a table
entry: F-1 Spirit is a MegaROM and carries its own `CD` header, so the Game
Master never gets as far as summing anything of it.

## Konami says from the inside that two of its games are one

The cheat table at `0x5B02` gives one routine per game, and two pairs **share
theirs**.

One is RC-710 and RC-711, the two Hyper Olympic titles, told apart inside by
their catalogue number: the only difference between the two cartridges, as far
as the Game Master is concerned, is eight bytes.

The other is **RC-700 and RC-716**. To the Game Master, Athletic Land and
Cabbage Patch Kids are the same program and get the same variables poked. That
is exactly what was measured when the second one was disassembled — it drags
along 439 bytes of the first that nobody reads — now said by Konami itself from
inside its own cheat cartridge.

## Antarctic Adventure needs two stage lists

`0x5BC7` and `0x5BD1`, ten bytes each: the values to poke into its `0xE0E2` to
start on each track. `0x5BB4` picks one or the other according to `0xD303`,
which says which of RC-701's two builds is sitting next door.

The two lists differ — `0x0D` against `0x0F` in the third, `0x35` against
`0x3C` in the last — and that is the proof that Konami knew two builds were in
circulation and that the variable does not land in the same place in both.

## The stage counts match what was measured in each game

Each cheat routine's divisor is how many stages that game has. And it matches
what was measured when they were disassembled: **fifteen in King's Valley**,
thirteen in Hyper Rally, three events in Hyper Sports 2, ten tracks in
Antarctic Adventure.

Sky Jaguar is the interesting one: it divides by eight, but what it writes **is
not a stage number, it is a position**. The remainder times 256, from `0x0000`
to `0x0700`. That fits what was already known about the game: it has no
separate stages, it is one continuous run.

## The "cheat active" light is the CAPS LED

The cartridge cannot paint on the game's screen without ruining it, so it
signals with the keyboard light: `0x4E70` calls CHGCAP every time the game is
frozen or resumed.

And freezing really silences the PSG: `0x4E85` saves the three channel volumes
before zeroing them, and `0x4EF8` puts them back on resume. Without that, the
last note would hang.

## One byte doing two jobs

`0xD12D` holds the PSG's channel C volume **and at the same time** is the low
byte of the IY used for inter-slot calls. It works because CALSLT only looks at
IYh, which is `0xD12E` and holds the slot.

## The menus open on top of the game

The disk and tape ones only clear `0x100` bytes from `0x3A00`, the bottom eight
rows, and before that `0x4275` has called the routine that carries the game's
VRAM into RAM. On a real machine, the top half of those screens is the game
still running.

## Four routines and two doors nobody reaches

`0x6445`, `0x6787`, `0x6904` and `0x6938` disassemble to correct Z80, start
right after a `ret` and end right where a label that *is* used begins. But there
is not one 16-bit reference nor one relative jump landing on them, searched
across all 16,384 bytes of the cartridge.

Plus two two-byte doors: `0x5022` and `0x6FB5`, each a `ld b,N` put there to
enter the neighbouring routine with a different value, that nobody jumps to.

It is not the mirage of reading an operand as an opcode — they do not fall
inside another instruction. They are leftovers from an earlier build: there are
three of this cartridge.

There are four more bytes in the same situation: `0x628C`, glued behind the
eight VDP registers. The loop that writes them stops at eight.

## It does carry the hidden mark, and it settles a character

In the last 22 bytes: **RC-735** and 19 katakana bytes reading
10バイタノシムカートリッジ — "the cartridge for ten times the fun" — which was
its slogan.

The format was discovered by **Manuel Pazos**
([@ManuelPazosMSX](https://twitter.com/ManuelPazosMSX)). As a bonus, this mark
**confirms that `0xBA` is the ー lengthener**, which was left open in the
earlier disassemblies in this series.

## Half the filename is written by the cartridge

Saving to disk you do not type the whole name: it supplies the first letter
according to the data — `H`, `S`, `G` or `R`, from the table at `0x68DA` — the
extension is always `VRM`, and the game's catalogue number goes behind so two
games do not overwrite each other's files.

And the score table, freshly cleared, comes out with all six places under the
house name: `KONAMI`, at `0x4A35`.
