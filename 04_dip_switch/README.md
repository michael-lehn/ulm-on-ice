## Purpose

When button one is pressed the bits of the dip switch are stored in a 8 bit
register. The hex display shows the value of the 8 bit register.

### Visualization of the design

![test](https://github.com/michael-lehn/icebreaker-examples/blob/main/04_dip_switch/test.svg)

### Demo (Link to YouTube)

[<img src="https://github.com/michael-lehn/icebreaker-examples/blob/main/04_dip_switch/demo.png" width="200">](https://youtu.be/VXf1pYegonU)

### Pictures

- `pic1.png`: the board with the display (PMOD 1A), the DIP switch (PMOD 1B)
  and the buttons (PMOD 2) after power-up; the display shows `00`.
- `pic2.png` to `pic6.png` were taken with the Mini-ALU of `05_mini_alu`, not
  with this step: the display shows one of its registers (selected with BTN2
  and BTN3), not the setting of the DIP switch. For example, in `pic5.png` the
  switches are set to `00011101` (load 7 into `%1`) and the display shows
  `07`; in `pic6.png` they are set to `01000101` (add 1·2^4 to `%1`) and the
  display shows `17`.
