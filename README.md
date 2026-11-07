# Pupose

Provide an additional target for the compiler class project in 
[HPC0](https://www.mathematik.uni-ulm.de/numerik/hpc/ss22/hpc0/index.html)
next semester.

## What is ULM on ICE?

It is a simple implementation of the ULM (Ulm Lecture Machine) on a
[iCEBreaker FPGA](https://1bitsquared.com/products/icebreaker).

## Tutorial

The directory `tutorial/` contains lecture notes that introduce everything
step by step: what an FPGA is, SystemVerilog as a textual representation of
circuits, the tools (`sv2v`, `yosys`, `nextpnr`, `icestorm`, Verilator), and
then one chapter per step directory up to the ULM. Read it as
[PDF](tutorial/ulm-on-ice-tutorial.pdf); to rebuild it from the LaTeX sources,
run `make` in `tutorial/` (LuaLaTeX).

## Current state

It's a working prototype, and it's is doing what it was designed for. When I
started the project it was my first encounter with `Verilog` and
`SystemVerilog` and the first time I had an FPGA in my hands. This means that
there is lots of potential for improvement. And if time permits I will do so.

If you are also a newbie you might be interested in places where you find some
information on getting started:
- [Project F](https://projectf.io)
- [Verilator introduction](https://itsembedded.com/dhd/verilator_1/)
- [SystemVerilog tutorial](https://www.chipverify.com/systemverilog/systemverilog-tutorial)
- ... I will extend and comment this list ...

## Demo (Link to YouTube)

[<img src="https://github.com/michael-lehn/icebreaker-examples/blob/main/09_ulm_on_ice/demo_hello.png" width="200">](https://youtu.be/j96EJUkOHoc)

[<img src="https://github.com/michael-lehn/icebreaker-examples/blob/main/09_ulm_on_ice/demo.png" width="200">](https://www.youtube.com/playlist?list=PL7bpgGDa-GJAgZmCLt6cgYch0mlWRdWok)

## Install

Tested on macOS with Homebrew.

Required:
- `sv2v`, `yosys`, `nextpnr-ice40` and `icestorm` (`icepack`, `iceprog`)
  for `make synth` and `make prog`
- `verilator` and a C++ compiler (`xcode-select --install`) for `make sim`
- GNU `make`

```sh
brew install sv2v yosys nextpnr-ice40 icestorm verilator make
```

Optional:
- Waveform viewers for `make surfer` and `make waves`: `surfer`
  (`brew install surfer`) and `gtkwave`. GTKWave is no longer in Homebrew;
  build it from [source](https://github.com/gtkwave/gtkwave) with meson (its
  README lists the Homebrew dependencies).
- Netlist pictures for `make svg` and `make png`:
  `brew install netlistsvg librsvg`
- `make report` and `make floorplan` only need `python3` in addition.
  `make floorplan` writes an HTML page and opens it.
- `make gui-pnr` needs nextpnr with its Qt GUI, which Homebrew's
  `nextpnr-ice40` does not have. Build it from
  [source](https://github.com/YosysHQ/nextpnr) after `brew install qt`, with
  `cmake -DARCH=ice40 -DBUILD_GUI=ON
  -DICESTORM_INSTALL_PREFIX=$(brew --prefix icestorm)
  -DICEBOX_DATADIR=$(brew --prefix icestorm)/share/icestorm/chipdb`.
  `ICEBOX_DATADIR` matters because Homebrew's icestorm keeps the chip data
  there. Install it somewhere before Homebrew in your `PATH`
  (e.g. `~/.local/bin`).
- A serial terminal for steps `06` and later. `06_io_mirror/kermit-serial` is
  a C-Kermit script (`brew install c-kermit`); adjust the device name in
  `set line` to your board.
- Language servers for editing: `verible` and `svlangserver` (e.g. via
  Neovim's Mason).
- For the tutorial PDF: a TeX distribution with `lualatex`
  (`brew install texlive` or MacTeX).


