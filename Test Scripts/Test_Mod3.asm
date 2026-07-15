.text
# li  t2, 0x6000    # Data Memory address 0x6000
# This is equivalent to: li t0, 0x11000020 # LEDS address (according to Wrapper)
lui t0, 69632
nop
nop
addi t0, t0, 32
# This is: li t1, 0xFFFF # should light up all 16 LEDs
lui t1, 16
nop
nop
addi t1, t1, -1
nop
nop
addi x7, zero, 7
addi  x8, zero, 40
addi x10, zero, 10
nop
nop
or x11, x7, x10
nop
nop
sw x11, 0(x8)
sw t1, 0(t0)
