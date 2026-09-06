# Getting started

This repository does not carry the cartridge. It carries **what you need to
regenerate the listing from your own copy** and check that it produces the same
binary, byte for byte.

## What you need

- **The ROM**, in the root and named `gamemaster.rom`. It is the *European
  Version* of 1986, exactly 16,384 bytes. Its sha256:

      3160911ae025207c80c40630f8ce94f857e7e820c97a437152124def25b0f7ee

- **Python 3** and **pasmo** to reassemble.
- **openMSX**, only if you want to check the pictures against the real VRAM.

## The four commands

    make comprueba   # that your ROM is the same one: compares the sha256
    make listado     # traces the flow and writes src/gamemaster.asm
    make verify      # reassembles and compares with the original, byte for byte
    make             # all of the above, plus sanity and the tests

`make verify` is the test that decides whether the disassembly is trustworthy.
If the reassembled binary does not give the same sha256, the listing is lying
somewhere.

## What reassembling does NOT check

Getting the same binary says nothing about whether the bytes are **read**
correctly: graphics marked as code give you the same file, because the bytes do
not change — only what we say about them does. That is what `make sanity` is
for, and it runs four checks:

- no range declared as data may come out as code;
- no entry point may fall inside a data range — if both are declared at once,
  one of them is false;
- **not one byte of the cartridge left unassigned**: all 16,384 must be either
  code reached by the trace or a named data range with an explanation;
- and the declared ranges are cross-checked against the trace.

## The pictures

    make imagenes    # draws the screens from the ROM
    make vram        # checks them against openMSX's VRAM, byte for byte

Not one picture on this site is a capture. They all come from running in Python
the same steps the Z80 runs: the decompressor at `0x62F7`, the rectangle
painter at `0x7852` and the label painter at `0x6294`. `make vram` lets the
cartridge run in the emulator, dumps the 16 KB of VRAM and compares them one by
one with the ones we build.

## How it is laid out

    src/gamemaster.entries   the entry points for the trace, each with its why
    src/gamemaster.nocode    the ranges that are NOT code
    src/gamemaster.notes     the annotations: labels, comments and data ranges
    src/gamemaster.asm       the listing, GENERATED — not edited by hand
    tools/                   the tracer, the generator and the checks
    tests/                   what keeps the documentation from lying

The listing **is generated**. Anything you want to change goes into the
`.notes`, which anchors every comment to an address: that way they survive a
retrace.

## The tools this cartridge needed

    tools/rle.py          the decompressor at 0x62F7, redone in Python
    tools/pantallas.py    decodes the label blocks and shows them laid out
    tools/cadenas.py      walks the messages and measures where they end
    tools/menus.py        derives the thirteen menus by measuring on the code
    tools/graficos.py     builds the screens from the ROM
    tools/coteja_vram.py  compares them with the emulator's
