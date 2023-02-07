#-------------------------------
# Lab_Snake_Game Lab
#
# Author: Eric Kim
# Date: Nov 7, 2022
#
# This program initializes four global variables to be used by function: random. 
#-------------------------------

.data
iTrapData:	.space	256	# allocate space for the interrupt trap data

.align  2        
XiVar:  	.word   17 	# starting seed of the LCG 
aVar:   	.word   10	# constant multiplier of the LCG 
cVar:   	.word   13  # constant increment of the LCG 
mVar:   	.word   9 	# the modulus of the LCG should be kept as 9

.text 
main:
	# Setup the uscratch control status register
	la	    t0, iTrapData		# t0 <- Addr[iTrapData]
	csrw	t0, 0x040		# CSR #64 (uscratch) <- Addr[iTrapData]
	jal 	ra, snakeGame	
	beqz 	zero, main_done


main_done:
	li      a7, 10      # ecall 10 exits the program with code 0
	ecall
