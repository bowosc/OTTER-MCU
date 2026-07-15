.data
THE_SPACE: .space 1024 # space
SPACE_SIZE: .word 3
.text

main:	

	la s0, SPACE_SIZE # pointer to ARR_SIZE
	
	lw a0, 0(s0) # value of ARR_SIZE

	# set param locations of arrays
	la a1, THE_SPACE


	call funky_function
	j end
	
funky_function:
	li t1, 1
	li t1, 2
	li t1, 3
	li t1, 4
	li t1, 5
	li t1, 6

	ret # all done

li t1, 9
li t1, 9
li t1, 9
li t1, 9
li t1, 9
li t1, 9
# death
end:
	j end##

