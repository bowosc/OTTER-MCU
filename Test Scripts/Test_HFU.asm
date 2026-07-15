li s0, 3
add s1, s0, s0
nop
nop
add s2, s1, s1
add s3, s2, s1
nop
nop
add s1, s0, s0
add s2, s1, s1
add s3, s2, s2
add s3, s2, s2
nop
nop
li s0, 1
li s1, 1
li s2, 2
beq s0, s2, branch1 # should not branch
beq s0, s1, branch1 # should yes branch
addi s0, s0, 512

branch1:
addi s1, s1, 16
addi s1, s1, 16
addi s1, s1, 16
nop
nop
nop
addi s0, s0, 15
addi s0, s0, 16
lw s1 0(s0)
lw s1 0(s1)
nop
nop
nop
