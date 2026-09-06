# Konami's Game Master (RC-735) — a commented disassembly

*(También [en castellano](README.es.md).)*

**[→ Read it on the web](https://antxiko.github.io/GameMaster-disassembly/)**

A complete, commented disassembly of Konami's Game Master for MSX1 — the 1986
European Version, RC-735, 16 KB.

It is not a game. It is Konami's **cheat cartridge**: it plugs into the next
slot, works out which game is sitting opposite and patches that game's start-up
in RAM to take over its interrupt. It is the only commercial MSX cartridge
whose entire job is to read and modify another cartridge.

| | |
|---|---|
| binary explained | **100%** — 16,384 of 16,384 bytes |
| traced code | 10,522 bytes (64.2%) |
| identified data | 5,862 bytes (35.8%) |
| routines | 663, **none below 10% commented** |
| comment density | **22.1%** |
| games it recognises | 28 |
| tests | 44 |

## How it gets in

It copies the neighbouring cartridge's first 256 start-up bytes into RAM and
looks there for `9B FD` — the operand of `ld (0xFD9B),hl`, the instruction a
Konami game uses to install its interrupt routine. It swaps it for five bytes
so the game's hook is saved and control passes to the Game Master, then runs
the patched copy.

Checked over the 42 cartridge ROMs in the collection: **all 40 Konami ones
carry that instruction**.

## Reproducing it

The cartridge is not distributed. Put your own copy in the root as
`gamemaster.rom` (sha256 `3160911ae025…`) and:

    make comprueba   # checks it is the same dump
    make             # traces, generates, reassembles and compares
    make imagenes    # draws the screens from the ROM
    make vram        # checks them against openMSX's VRAM

`make verify` reassembles the listing and compares it with the original byte
for byte.

## The pictures

Not one picture here is a capture. They are built by running in Python the same
steps the Z80 runs, and checked byte for byte against the emulator's VRAM: of
the 16,384 bytes, the only one that differs is the blinking cursor.

## Credits

The hidden Konami mark in the last 22 bytes — the catalogue number and the
title in katakana — was discovered by **Manuel Pazos**
([@ManuelPazosMSX](https://twitter.com/ManuelPazosMSX)).

See [LEGAL-NOTICE.md](LEGAL-NOTICE.md) and [LICENSE](LICENSE).
