# Written by Bowman Edebohls and Brody Bredice

.text
.eqv SWITCHES_ADDR,      0x11000000   # address for SWITCHES input
.eqv LEDS_ADDR,          0x11000020   # address for LED output
.eqv SEVENSEG_ADDR,      0x11000040   # address for 7-seg output
.eqv SWITCH_DELAY_COUNT, 125000000    # delay count A (longer, for input)
.eqv OUTPUT_DELAY_COUNT, 62500000     # delay count B (shorter, for output)

main:
    la   t0, input              # t0 points to input array
    li   t1, 10                 # t1 = number of inputs to read
    li   t2, SWITCHES_ADDR      # t2 = switches MMIO address
    li   a3, SEVENSEG_ADDR      # a3 = 7-seg MMIO address

read_loop:
    jal  pause_switch           # pause and wait (for input)
    sw   t1, 0(a3)              # display counter on 7-seg (which value we’re inputting)
    lw   t3, 0(t2)              # load word from switches
    andi t3, t3, 0xFF           # mask to lowest 8 bits
    sb   t3, 0(t0)              # store byte into input array
    addi t0, t0, 1              # next input slot
    addi t1, t1, -1             # decrement counter
    bne  t1, x0, read_loop      # loop until all 10 read

    la   t0, input              # reset pointer to input
    la   t4, quot               # pointer to quotient array
    la   t5, rem                # pointer to remainder array
    li   t1, 10                 # counter = 10 elements
    li   t6, 3                  # divisor = 3

div_each:
    lbu  t3, 0(t0)              # load next input byte
    li   a2, 0                  # reset quotient counter

div_loop:
    bltu t3, t6, div_done       # stop when value < 3
    addi t3, t3, -3             # subtract 3
    addi a2, a2, 1              # increment quotient
    j    div_loop

div_done:
    sb   a2, 0(t4)              # store quotient
    sb   t3, 0(t5)              # store remainder
    addi t0, t0, 1              # next input
    addi t4, t4, 1              # next quotient slot
    addi t5, t5, 1              # next remainder slot
    addi t1, t1, -1             # decrement counter
    bne  t1, x0, div_each       # repeat for all 10 values

    la   a3, quot               # base of quotient array
    li   a4, 10                 # length = 10
    jal  sort                   # sort quotients

    la   a3, rem                # base of remainder array
    li   a4, 10
    jal  sort                   # sort remainders

    la   t4, quot               # pointer to quotients
    li   t1, 10                 # counter = 10
    li   a3, SEVENSEG_ADDR      # 7-seg MMIO address
    jal  pause_output

out_quots:
    lbu  t3, 0(t4)              # load next quotient
    sw   t3, 0(a3)              # output to 7-segment
    addi t4, t4, 1              # next quotient
    addi t1, t1, -1             # decrement counter
    jal  pause_output           # pause to show output
    bne  t1, x0, out_quots      # repeat 10 times

    la   t5, rem                # pointer to remainders
    li   t1, 10
    li   a3, LEDS_ADDR          # LED MMIO address

out_rems:
    lbu  t3, 0(t5)              # load next remainder
    sw   t3, 0(a3)              # output to LEDs
    jal  pause_output           # pause to show output
    addi t5, t5, 1
    addi t1, t1, -1
    bne  t1, x0, out_rems

end:
    li   t1, 57005              # sentinel value
    li   a3, SEVENSEG_ADDR      # 7-seg addr
    sw   t1, 0(a3)              # show output on 7-seg
    j    end

# --------------------------------------------------
# sort(a3 = base addr, a4 = length)
# Bubble sort of byte array in-place
# Returns a0 = base, a1 = length
# --------------------------------------------------
sort:
    addi t6, a4, -1             # t6 = N - 1
    beq  t6, x0, sort_done      # skip if N <= 1
    li   t0, 0                  # outer index i = 0

outer:
    li   t1, 0                  # inner index j = 0
    sub  t2, t6, t0             # t2 = N - 1 - i

inner:
    add  t3, a3, t1             # t3 = &a[j]
    lbu  t4, 0(t3)              # a[j]
    lbu  t5, 1(t3)              # a[j + 1]
    bltu t5, t4, do_swap        # if next < current, swap
    j    no_swap

do_swap:
    sb   t5, 0(t3)              # store smaller value
    sb   t4, 1(t3)              # store larger value

no_swap:
    addi t1, t1, 1
    bne  t1, t2, inner          # continue inner loop
    addi t0, t0, 1
    bne  t0, t6, outer          # continue outer loop

sort_done:
    mv   a0, a3                 # return base address
    mv   a1, a4                 # return length
    ret

# --------------------------------------------------
# pause_switch: long delay (for input)
# --------------------------------------------------
pause_switch:
    # each non-load instr ~2 ticks
    # 50,000,000 ticks = 1 sec at 50 MHz
    li   t6, SWITCH_DELAY_COUNT # higher count

ps_loop:
    addi t6, t6, -1             # countdown
    bnez t6, ps_loop            # loop until zero
    ret

# --------------------------------------------------
# pause_output: shorter delay (for output display)
# --------------------------------------------------
pause_output:
    li   t6, OUTPUT_DELAY_COUNT

po_loop:
    addi t6, t6, -1
    bnez t6, po_loop
    ret

.data
input:  .space 10               # input array (10 bytes)
quot:   .space 10               # quotients array
rem:    .space 10               # remainders array
