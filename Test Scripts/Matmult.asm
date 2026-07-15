
.data
THE_STACK: .space 1024 # seems like enough
STACK_TOP: # empty, bc we just want the address on the end of the stack

ARR_SIZE: .word 3

# Gotta update the above value when you change the size of the arrays

#### 3x3
#ARR_A: .word 1, 0, 0, 0, 1, 0, 0, 0, 1 # identity matrix
ARR_A: .word 1, 2, 3, 4, 5, 6, 7, 8, 9 # not an identity matrix
ARR_B: .word 1, 2, 3, 4, 5, 6, 7, 8, 9 # not an identity matrix
ARR_OUTPUT: .word 0, 0, 0, 0, 0, 0, 0, 0, 0


.text

main:	
	la sp, STACK_TOP
	# Load row and column sizes
	la s0, ARR_SIZE # pointer to ARR_SIZE
	
	# set param size of array
	lw a0, 0(s0) # value of ARR_SIZE

	# set param locations of arrays
	la a1, ARR_OUTPUT 
	la a2, ARR_A
	la a3, ARR_B

	call multiply_matrices
	j end
	
multiply_matrices:
# preserve data in the stack
addi sp, sp, -32

# idk if i need this
sw ra, 28(sp)

sw s0, 24(sp)
sw s1, 20(sp)
sw s2, 16(sp)
sw s3, 12(sp)
sw s4, 8(sp)
sw s5, 4(sp)
sw s6, 0(sp)



# put locations into safe reggies
mv s0, a0 # s0 holds value of size of array
mv s1, a1 # s1 holds address of arr out
mv s2, a2 # s2 holds address of arr a
mv s3, a3 # s3 holds address of arr b

# Prep for loop, load counters
li s4, 0 # Counter for A rows
li s5, 0 # Counter for B cols
li s6, 0 # Counter for B rows
# unused: li t3, 0 # Counter for A cols
# unused: li t4, 0 # Adder for counter 
# unused: li t5, 0 # Adder for counter s5

# for (int i = 0; i < R1; i++) {
row_loop:
#

# for (int j = 0; j < C2; j++) {
col_loop:
#

# set t5 to location of ARR_A plus counter amount
# test removed? : add t5, s5, s3 


# result[i] [j] = 0;
li t6, 0

# for (int k = 0; k < R2; k++) {
sum_add_loop:
#


# result[i] [j] += m1[i] [k] * m2[k] [j];

# find ARR_A[i][k]
# col size * i + k = address of ARR_A[i][k]
mv a0, s4 # row counter
mv a1, s0 # size of row
call mult # call mult, output in a2
# a2 = col size * i
mv a3, a2 # we just hold onto it in a3 for now
add a3, a3, s6 # + k
slli a3, a3, 2 # *4, because words are 4 bytes
add a3, a3, s2 # + addr of array
lw a3, 0(a3)

# find ARR_B[k][j]
# col size * k + j = address of ARR_A[k][j]
mv a0, s0 # size of col
mv a1, s6 # col counter
call mult # call mult, output in a2
# a2 = col size * k
add a2, a2, s5 # + j
slli a2, a2, 2 # *4, because words are 4 bytes
add a2, a2, s3 # + addr of array
lw a2, 0(a2) # value at point = value at ( loc + start of array )




# ARR_A[i][k] * ARR_B[k][j]
mv a0, a3 
mv a1, a2
call mult

# add to sun
add t6, t6, a2

# put the result in result array
# find OUT_ARR[rows][cols] via col size * j + k 
mv a0, s4 # should be row counter
mv a1, s0 # should be size of row
call mult # call mult, output in a2
add a2, a2, s5 # + k
slli a2, a2, 2 # *4, because words are 4 bytes
add a2, a2, s1 # + addr of array
sw t6, 0(a2) # put t6 in the place described by the address that is a2

# } sum_add_loop
addi s6, s6, 1	
bne s6, s0, sum_add_loop # keep looping if B rows counter != size of A
li s6, 0 # reset it otherwise

# } col_loop
addi s5, s5, 1
bne s5, s0, col_loop # keep looping if B cols counter != size of A
li s5, 0 # reset it otherwise

# } row_loop
addi s4, s4, 1 # tick up A rows counter
bne s4, s0, row_loop # Keep looping if A rows counter != size of A
# dont rly care abt resetting it otherwise

# put data back from stack
lw s6, 0(sp)
lw s5, 4(sp)
lw s4, 8(sp)
lw s3, 12(sp)
lw s2, 16(sp)
lw s1, 20(sp)
lw s0, 24(sp)
lw ra, 28(sp)
addi sp, sp, 32
ret


# INT * INT MULTIPLICATION FUNCTION
# Multiply a by b
# Params: a is value in a0, b is value in a1, output/sum in a2
mult:
	li a2, 0 
	beqz a0, end_mult # no need to mult by zero
	
	loop_mult: #
	add a2, a2, a1 
	addi a0, a0, -1 # tick down conter
	bnez a0, loop_mult # 

end_mult:
	ret # all done


# death
end:
	j end #test5


