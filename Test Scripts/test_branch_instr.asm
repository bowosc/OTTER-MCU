
nop
nop
nop
beq x0, x0, next
add t1, t1, t1 # born to be flushed
add t1, t1, t1
add t1, t1, t1

next:
	li t1, 1
	li t1, 2
	li t1, 3

	jal next2
	
	add t2, t2, t2 # born to be flushed
	add t2, t2, t2 # but then not flushed the second time
	add t2, t2, t2
	
	j end
end:
li t1, 9 # pointless. 
j end
add t1, t1, t1 # born to be flushed
add t1, t1, t1
add t1, t1, t1
jalr x0, x1, 0
next2:
	li t1, 1
	li t1, 2
	li t1, 3
	ret
add t1, t1, t1 # born to be flushed
add t1, t1, t1
add t1, t1, t1




