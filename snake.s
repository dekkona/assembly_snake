#-------------------------------
# Lab_Snake_Game Lab
#
# Author: 	Eric Kim
# Date: 	Nov 7 2022
#
#-------------------------------

.include "common.s"

.data
.align 2

DISPLAY_CONTROL:    .word 0xFFFF0008
DISPLAY_DATA:       .word 0xFFFF000C
INTERRUPT_ERROR:	.asciz "Error: Unhandled interrupt with exception code: "
INSTRUCTION_ERROR:	.asciz "\n   Originating from the instruction at address: "
DISPLAY_WELCOME:	.asciz "Please enter 1, 2, or 3 to choose the level and start the game"
DISPLAY_POINTS:		.asciz "points"
DISPLAY_SECONDS:	.asciz "seconds"

Brick:      .asciz "#"
Body:	.asciz "*"
Head:	.asciz "@"
Space:	.asciz " "
Apple:  .asciz "a"
aRow:	.word	3	#Row for apple
aCol:	.word	6	#Col for apple
Row:	.word	5	#Row for snake head
Col:	.word	9	#Col for snake head
Dir:	.word	0	#0=right(a), 1=left(d), 2=down(s), 3=up(w)  
NeckR:	.word	5	
NeckC: 	.word   8
TorsoR:	.word 	5	#Rows and Cols for parts of snake body
TorsoC:	.word	7	
TailR:	.word	5
TailC:	.word	6
changes: .word	0	#1 if a second has passed, 0 otherwirse
over:	.word	0	#0 if game is not over, 1 if game is over
started: .word	0	#0 if game has not started yet, 1 if game has started
bonus:	.word	0	#how many bonus seconds per apple
waiting: .word	0	#waiting for valid user input in start menu
pdig1:	 .word	0	#points digits for display
pdig2:	 .word	0
pdig3:	 .word	0
sdig1:	.word	0	#seconds digits for display
sdig2:	.word	0
sdig3:	.word	0

.text



snakeGame:
	addi sp, sp, -12
	sw ra, 0(sp)		#save values in stack
	sw s0, 4(sp)
	sw s1, 8(sp) 
	la t0, handler
 	csrrw zero, 5, t0 # set utvec (5) to the handlers address
 	csrrsi zero, 0, 1 # set interrupt enable bit in ustatus (0)
 	li t0, 0x0110
 	csrrs zero, 4, t0 # set interrupt enable bits in uie (0)
	
	li t0, 0xFFFF0000 #enable keyboard
	li t1, 2
	sw t1, (t0)
startMenu: #welcome screen
	lw t0, started
	bne t0, zero, startGame # keep looping startMenu until started does not equal zero
	lw t0, waiting
	bne t0, zero, startMenu
	la a0, DISPLAY_WELCOME 
	add a1, zero, zero
	add a2, zero, zero
	jal printStr
	la t0, waiting
	addi t1, zero, 1
	sw t1, (t0)
	
	jal startMenu
startGame:
	# clear welcome text
	li a0, 40
	add a1, zero, zero
	addi a2, zero, 21
	la a3, Space
	lbu a3, (a3)
	jal printMultipleSameChars 
	# print walls
	jal printAllWalls 
	# print snake body at initial position
	li a0, 3
	lw a1, Row
	lw a2, Col
	addi a2, a2, -3
	la a3, Body 
	lbu a3, (a3)
	jal printMultipleSameChars 
	# print snake head at initial position
	la a0, Head 
	lbu a0, (a0)
	lw a1, Row
	lw a2, Col
	jal printChar 
	# print apple at initial position
	la a0, Apple
	lbu a0, (a0)
	lw a1, aRow
	lw a2, aCol
	jal printChar 

	la a0, DISPLAY_POINTS
	add a1, zero, zero
	li a2, 28
	jal printStr
	
	la a0, DISPLAY_SECONDS
	addi a1, zero, 1
	li a2, 28
	jal printStr 
	# print points display
	la t0, pdig1
	li a0, 0x30
	sw a0, (t0)
	add a1, zero, zero
	li a2, 26
	jal printChar
	la t0, pdig2
	li a0, 0x30
	sw a0, (t0)
	add a1, zero, zero
	li a2, 25
	jal printChar
	la t0, pdig3
	li a0, 0x30
	sw a0, (t0)
	add a1, zero, zero
	li a2, 24
	jal printChar
	# print seconds display
	lw a0, sdig1
	addi a1, zero, 1
	li a2, 26
	jal printChar
	lw a0, sdig2
	addi a1, zero, 1
	li a2, 25
	jal printChar
	lw a0, sdig3
	addi a1, zero, 1
	li a2, 24
	jal printChar
	# set timecmp, in this case timecmp = 1000ms (1s) + current ms passed
	li t0, 0xFFFF0020 #timecmp 
	lw t1, 0xFFFF0018
	li t4, 1000
	add t4, t1, t4
	sw t4, (t0)
	
loop:
	# keep looping game until gameOver does not equal zero
	lw t0, over
	bne t0, zero, gameOver #check if gameOver
	lw t0, changes
	bne t0, zero, update
	
	jal loop
update:
	# goto update from loop everytime a second has passed
	jal drawSnake # update snake pos
	la t0, Apple # draw apple
	lbu a0, (t0)
	lw a1, aRow
	lw a2, aCol
	jal printChar
	
	#update display points
	lw a0, pdig1
	add a1, zero, zero
	li a2, 26
	jal printChar
	lw a0, pdig2
	add a1, zero, zero
	li a2, 25
	jal printChar
	lw a0, pdig3
	add a1, zero, zero
	li a2, 24
	jal printChar
	
	#update display seconds
	lw a0, sdig1
	addi a1, zero, 1
	li a2, 26
	jal printChar
	lw a0, sdig2
	addi a1, zero, 1
	li a2, 25
	jal printChar
	lw a0, sdig3
	addi a1, zero, 1
	li a2, 24
	jal printChar
	# set changes back to 0 to stay back in loop until changes does not equal zero again
	la t0, changes
	add t1, zero, zero
	sw t1, (t0)

	jal loop
gameOver:
	# end of snakeGame
	lw ra, 0(sp)		#recover values from stack
	lw s0, 4(sp)
	lw s1, 8(sp)
	addi sp, sp, 12
	jalr zero, ra, 0 
	
drawSnake:
	addi sp, sp, -12
	sw ra, 0(sp)		#save values in stack
	sw s0, 4(sp)
	sw s1, 8(sp) 

	lw t0, Dir
	
	li t1, 1
	li t2, 2
	li, t3, 3
	add s2, zero, zero # col
	add s3, zero, zero # row
	beq t0, t1, left
	beq t0, t2, up
	beq t0, t3, down
	addi s2, zero, 1 #right
	jal move
left:
	addi s2, zero, -1
	jal move
up:
	addi s3, zero, 1
	jal move
down:
	addi s3, zero, -1
move:
	#remove trailspace
	la a0, Space
	lbu a0, (a0)
	lw a1, TailR
	lw a2, TailC
	jal printChar
	la a0, Space
	lbu a0, (a0)
	lw a1, TorsoR
	lw a2, TorsoC
	jal printChar
	la a0, Space
	lbu a0, (a0)
	lw a1, NeckR
	lw a2, NeckC
	jal printChar
	#update neck, torso, and tail positions
	lw t0, TorsoR
	la t1, TailR
	sw t0, (t1)
	lw t0, TorsoC
	la t1, TailC
	sw t0, (t1)
	
	lw t0, NeckR
	la t1, TorsoR
	sw t0, (t1)
	lw t0, NeckC
	la t1, TorsoC
	sw t0, (t1)
	
	lw t0, Row
	la t1, NeckR
	sw t0, (t1)
	lw t0, Col
	la t1, NeckC
	sw t0, (t1)
	
	#new body
	la a0, Body 
	lbu a0, (a0)
	lw a1, NeckR
	lw a2, NeckC
	jal printChar
	la a0, Body 
	lbu a0, (a0)
	lw a1, TorsoR
	lw a2, TorsoC
	jal printChar
	la a0, Body 
	lbu a0, (a0)
	lw a1, TailR
	lw a2, TailC
	jal printChar
	
	#new head
	la a0, Head 
	lbu a0, (a0)
	lw a1, Row
	add a1, a1, s3
	la t0, Row
	sw a1, (t0) #update Row
	lw a2, Col
	add a2, a2, s2 
	la t0, Col
	sw a2, (t0) #update Col
	jal printChar
	#check if the head of the snake hit a wall
	jal checkHitting
	beq a0, zero, hitChecked 
	la t0, over
	addi t1, zero, 1
	sw t1, (t0)
hitChecked:
	jal checkEatingApple
	beq a0, zero, eatChecked #check if eat apple
	
	#new apple location
	jal random
	bne a0, zero, validRow
	addi a0, a0, 5
	
	# check if valid (aka random does not give us 0 because the apple will be in a wall)
validRow:
	la t0, aRow
	sw a0, (t0)
	jal random
	bne a0, zero, validCol
	addi a0, a0, 5
validCol:
	la t0, aCol
	addi t1, zero, 2
	mul a0, a0, t1
	sw a0, (t0)
	
eatChecked: 
	lw ra, 0(sp)		#recover values from stack
	lw s0, 4(sp)
	lw s1, 8(sp)
	addi sp, sp, 12
	jalr zero, ra, 0 # end of drawSanke

checkHitting: # input: None	output: a0 - 1 if hit, 0 if no hit
	addi sp, sp, -12
	sw ra, 0(sp)		#save values in stack
	sw s0, 4(sp)
	sw s1, 8(sp) 
	#if 0<Row<=9 and 0<Col<=20 then no hit, otherwise hit
	lw t0, Row
	li t1, 10
	addi t2, zero, 1
	blt t0, t2, hit
	bge t0, t1, hit 
	lw t0, Col
	li t1, 20
	addi t2, zero, 1
	blt t0, t2, hit
	bge t0, t1, hit 
	jal noHit
hit:
	addi a0, zero, 1
	jal hitExit
noHit:
	add a0, zero, zero
hitExit:
	lw ra, 0(sp)		#recover values from stack
	lw s0, 4(sp)
	lw s1, 8(sp)
	addi sp, sp, 12
	jalr zero, ra, 0 # end of checkHitting
	
checkEatingApple: # input: None	output: a0 - 1 if hit, 0 if no hit
	addi sp, sp, -12
	sw ra, 0(sp)		#save values in stack
	sw s0, 4(sp)
	sw s1, 8(sp) 
	
	lw t0, Row
	lw t1, aRow
	beq t0, t1, yesEat
	jal noEat
yesEat:
	lw t0, Col
	lw t1, aCol
	bne t0, t1, noEat
	
	#add a point to total points
	li t0, 0x39 # ascii for 9
	lw t1, pdig1
	beq t1, t0, pCheck1 # if digit 1 of points = 9 goto pCheck1
	addi t2, t1, 1
	la t3, pdig1
	sw t2, (t3)
	jal pUpdated
pCheck1:
	la t1, pdig1 
	li t3, 0x30 #ascii for 0
	sw t3, (t1) #set digit 1 of points to 0
	lw t2, pdig2
	beq t2, t0, pCheck2 # if digit 2 of points = 9 goto pCheck3
	addi t2, t2, 1
	la t0, pdig2
	sw t2, (t0) 
	jal pUpdated
pCheck2:
	la t2, pdig2 
	sw t3, (t2) #set digit 2 of points to 0
	lw t0, pdig3
	addi t0, t0, 1
	la t1, pdig3
	sw t0, (t1) # set digit 3 of points assume points cannot exceed 999
pUpdated:
	#add bonus time to seconds
	lw t0, bonus
   	lw t1, sdig1
   	li t2, 0x3a # 1 ascii above 9 
   	add t3, t1, t0
   	bge t3, t2, bCheck1 # for if the bonus changes more than 1 digits
   	la t1, sdig1
   	sw t3, (t1)
   	jal bUpdated
bCheck1:
	div t0, t3, t2 # digit 2 to be added
	rem t1, t3, t2 # digit 1 to be added to ascii 0
	lw t4, sdig2
	add t4, t4, t0
	li t5, 0x30 # ascii 0
	add t1, t5, t1
	la t0, sdig1
	sw t1, (t0)
	bge t4, t2, bCheck2 # for if the bonus changes more than 2 digits
	la t0, sdig2
	sw t4, (t0)
	jal bUpdated
bCheck2:
	div t0, t4, t2 # digit 3 to be added
	rem t1, t4, t2 # digit 2 to be added to ascii 0
	lw t4, sdig3
	add t4, t4, t0
	la t0, sdig3 # set digit 3 and digit 2, assume seconds cannot exceed 999
	sw t4, (t0)
	add t1, t5, t1
	la t0, sdig2
	sw t1, (t0)
bUpdated:
	addi a0, zero, 1 
	jal appleExit
noEat:
	add a0, zero, zero
appleExit:
	lw ra, 0(sp)		#recover values from stack
	lw s0, 4(sp)
	lw s1, 8(sp)
	addi sp, sp, 12
	jalr zero, ra, 0
	
random: # input: None	output: a0 - random number
	lw t0, XiVar # Load global vars	
	lw t1, aVar
	lw t2, cVar
	lw t3, mVar
	mul t0, t0, t1 
	add t0, t0, t2
	rem a0, t0, t3 # Xi = (a*Xi-1+c) mod m 
	la t1, XiVar 
	sw a0, (t1) # Xi-1 = Xi
	
	jalr zero, ra, 0

handler:
	la a0, iTrapData
  	csrrw a0, 64, a0 # Swap the uscratch register with a0
   	sw t1, 0(a0) # Save all the used registers into memory stored at the ksp
   	sw t2, 4(a0)
   	sw t3, 8(a0)
   	sw t4, 12(a0)
   	sw t0, 16(a0)
   
   	li t1, 0 # Load 0 into t1
   	csrrw t1, 66, t1 # swap t1 with ucause, making ucause 0
   	
   	li t3, 0x80000008
   	bne t3, t1, ifTimer
   	
   	li t0, 0xFFFF0004 # ascii val of last key pressed
	lw t0, (t0)
	
	lw t1, started
	bne t1, zero, gameStarted # if user is past start menu goto gameStarted
	li t1, 0x31 # 1 (easy)
	li t2, 0x32 # 2 (medium)
	li t3, 0x33 # 3 (hard)
	
	beq t0, t1, easy
	beq t0, t2, medium
	beq t0, t3, hard
	jal keyChecked
easy:
	la t0, bonus
	addi t1, zero, 8
	sw t1, (t0)
	
	#update display seconds
	la t0, sdig1
	li t1, 0x30 #ascii for 0
	sw t1, (t0)
	la t0, sdig2
	li t1, 0x32 #ascii for 2
	sw t1, (t0)
	la t0, sdig3
	li t1, 0x31 #ascii for 1
	sw t1, (t0)
	
	la t0, started
	addi t1, zero, 1
	sw t1, (t0) # start game
	jal keyChecked
medium:	
	la t0, bonus
	addi t1, zero, 5
	sw t1, (t0)
	
	#update display seconds
	la t0, sdig1
	li t1, 0x30 #ascii for 0
	sw t1, (t0)
	la t0, sdig2
	li t1, 0x33 #ascii for 3
	sw t1, (t0)
	la t0, sdig3
	li t1, 0x30 #ascii for 0
	sw t1, (t0)
	
	la t0, started
	addi t1, zero, 1
	sw t1, (t0) # start game
	jal keyChecked
hard:	
	la t0, bonus
	addi t1, zero, 3
	sw t1, (t0)
	
	#update display seconds
	la t0, sdig1
	li t1, 0x35 #ascii for 5
	sw t1, (t0)
	la t0, sdig2
	li t1, 0x31 #ascii for 1
	sw t1, (t0)
	la t0, sdig3
	li t1, 0x30 #ascii for 0
	sw t1, (t0)
	
	la t0, started
	addi t1, zero, 1
	sw t1, (t0) # start game
	jal keyChecked
			
gameStarted:
	li t1, 0x77 # w
	li t2, 0x61 # a
	li t3, 0x73 # s
	li t4, 0x64 # d
	
	beq t0, t1, w
	beq t0, t2, a
	beq t0, t3, s
	beq t0, t4, d
	jal keyChecked
w:
	la t0, Dir
	addi t1, zero, 3 # up
	sw t1, (t0)
	jal keyChecked
a:
	la t0, Dir
	addi t1, zero, 1 # left
	sw t1, (t0)
	jal keyChecked
s:
	la t0, Dir
	addi t1, zero, 2 # down
	sw t1, (t0)
	jal keyChecked
d:
	la t0, Dir
	add t1, zero, zero # right
	sw t1, (t0)
keyChecked:   	
	li t0, 0xFFFF0000
	li t1, 2
	sw t1, (t0)	
	
   	jal ifTimerExit
ifTimer:
   	li t3, 0x80000004 # This is the code regarding user timer interrupts.
   	bne t3, t1, handlerTerminate # If the status isn't for a user timer interrupt, go to the handler terminate code
   	
   	#update seconds
   	lw t3, sdig3
   	lw t2, sdig2
   	lw t1, sdig1
   	li t0, 0x30 # ascii 0
   	beq t1, t0, sCheck1
   	addi t1, t1, -1
   	la t4, sdig1
   	sw t1, (t4)
   	jal sUpdated
sCheck1:
	beq t2, t0, sCheck2
	addi t2, t2, -1
	la t4, sdig2
	sw, t2, (t4)
	li t5, 0x39 # ascii 9
	la t4, sdig1
	sw t5, (t4)
	jal sUpdated
sCheck2:
	beq t3, t0, sCheck3
   	addi t3, t3, -1
   	la t4, sdig3
   	sw t3, (t4)
   	li t5, 0x39 # ascii 9
	la t4, sdig2
	sw t5, (t4)
	la t4, sdig1
	sw t5, (t4)
	jal sUpdated
sCheck3:
	la t4, sdig1 # seconds to 000
	sw t0, (t4)
	la t4, sdig2
	sw t0, (t4)
	la t4, sdig3
	sw t0, (t4)
	
	la t4, over # game over
	addi t5, zero, 1
	sw t5, (t4)
sUpdated:
   	li t0, 0xFFFF0020 
   	lw t4, 0xFFFF0020
	addi t4, t4, 1000 #update timecmp
	sw t4, (t0)
	
	la t0, changes #update changes
	addi t1, zero, 1
	sw t1, (t0)
ifTimerExit:	
	lw t1, 0(a0) # load back all the old registers
   	lw t2, 4(a0)
   	lw t3, 8(a0)
   	lw t4, 12(a0)
   	lw t0, 16(a0)
   
   	csrrw a0, 64, a0 # swap t0 and the uscratch register to restore t0's value
   	
   	uret
   	
handlerTerminate:
	# Print error msg before terminating
	li     a7, 4
	la     a0, INTERRUPT_ERROR
	ecall
	li     a7, 34
	csrrci a0, 66, 0
	ecall
	li     a7, 4
	la     a0, INSTRUCTION_ERROR
	ecall
	li     a7, 34
	csrrci a0, 65, 0
	ecall
handlerQuit:
	li     a7, 10
	ecall	# End of program

#---------------------------------------------------------------------------------------------
# printAllWalls
#
# Subroutine description: This subroutine prints all the walls within which the snake moves
# 
#   Args:
#  		None
#
# Register Usage
#      s0: the current row
#      s1: the end row
#
# Return Values:
#	None
#---------------------------------------------------------------------------------------------
printAllWalls:
	# Stack
	addi   sp, sp, -12
	sw     ra, 0(sp)
	sw     s0, 4(sp)
	sw     s1, 8(sp)
	# print the top wall
	li     a0, 21
	li     a1, 0
	li     a2, 0
	la     a3, Brick
	lbu    a3, 0(a3)
	jal    ra, printMultipleSameChars

	li     s0, 1	# s0 <- startRow
	li     s1, 10	# s1 <- endRow
printAllWallsLoop:
	bge    s0, s1, printAllWallsLoopEnd
	# print the first brick
	la     a0, Brick	# a0 <- address(Brick)
	lbu    a0, 0(a0)	# a0 <- '#'
	mv     a1, s0		# a1 <- row
	li     a2, 0		# a2 <- col
	jal    ra, printChar
	# print the second brick
	la     a0, Brick
	lbu    a0, 0(a0)
	mv     a1, s0
	li     a2, 20
	jal    ra, printChar
	
	addi   s0, s0, 1
	jal    zero, printAllWallsLoop

printAllWallsLoopEnd:
	# print the bottom wall
	li     a0, 21
	li     a1, 10
	li     a2, 0
	la     a3, Brick
	lbu    a3, 0(a3)
	jal    ra, printMultipleSameChars

	# Unstack
	lw     ra, 0(sp)
	lw     s0, 4(sp)
	lw     s1, 8(sp)
	addi   sp, sp, 12
	jalr   zero, ra, 0


#---------------------------------------------------------------------------------------------
# printMultipleSameChars
# 
# Subroutine description: This subroutine prints white spaces in the Keyboard and Display MMIO Simulator terminal at the
# given row and column.
# 
#   Args:
#   a0: length of the chars
# 	a1: row - The row to print on.
# 	a2: col - The column to start printing on.
#   a3: char to print
#
# Register Usage
#      s0: the remaining number of cahrs
#      s1: the current row
#      s2: the current column
#      s3: the char to be printed
#
# Return Values:
#	None
#---------------------------------------------------------------------------------------------
printMultipleSameChars:
	# Stack
	addi   sp, sp, -20
	sw     ra, 0(sp)
	sw     s0, 4(sp)
	sw     s1, 8(sp)
	sw     s2, 12(sp)
	sw     s3, 16(sp)

	mv     s0, a0
	mv     s1, a1
	mv     s2, a2
	mv     s3, a3

# the loop for printing the chars
printMultipleSameCharsLoop:
	beq    s0, zero, printMultipleSameCharsLoopEnd   # branch if there's no remaining white space to print
	# Print character
	mv     a0, s3	# a0 <- char
	mv     a1, s1	# a1 <- row
	mv     a2, s2	# a2 <- col
	jal    ra, printChar
		
	addi   s0, s0, -1	# s0--
	addi   s2, s2, 1	# col++
	jal    zero, printMultipleSameCharsLoop

# All the printing chars work is done
printMultipleSameCharsLoopEnd:	
	# Unstack
	lw     ra, 0(sp)
	lw     s0, 4(sp)
	lw     s1, 8(sp)
	lw     s2, 12(sp)
	lw     s3, 16(sp)
	addi   sp, sp, 20
	jalr   zero, ra, 0


#------------------------------------------------------------------------------
# printStr
#
# Subroutine description: Prints a string in the Keyboard and Display MMIO Simulator terminal at the
# given row and column.
#
# Args:
# 	a0: strAddr - The address of the null-terminated string to be printed.
# 	a1: row - The row to print on.
# 	a2: col - The column to start printing on.
#
# Register Usage
#      s0: The address of the string to be printed.
#      s1: The current row
#      s2: The current column
#      t0: The current character
#      t1: '\n'
#
# Return Values:
#	None
#
# References: This peice of code is adjusted from displayDemo.s(Zachary Selk, Jul 18, 2019)
#------------------------------------------------------------------------------
printStr:
	# Stack
	addi   sp, sp, -16
	sw     ra, 0(sp)
	sw     s0, 4(sp)
	sw     s1, 8(sp)
	sw     s2, 12(sp)

	mv     s0, a0
	mv     s1, a1
	mv     s2, a2

# the loop for printing string
printStrLoop:
	# Check for null-character
	lb     t0, 0(s0)
	# Loop while(str[i] != '\0')
	beq    t0, zero, printStrLoopEnd

	# Print Char
	mv     a0, t0
	mv     a1, s1
	mv     a2, s2
	jal    ra, printChar

	addi   s0, s0, 1	# i++
	addi   s2, s2, 1	# col++
	jal    zero, printStrLoop

printStrLoopEnd:
	# Unstack
	lw     ra, 0(sp)
	lw     s0, 4(sp)
	lw     s1, 8(sp)
	lw     s2, 12(sp)
	addi   sp, sp, 16
	jalr   zero, ra, 0



#------------------------------------------------------------------------------
# printChar
#
# Subroutine description: Prints a single character to the Keyboard and Display MMIO Simulator terminal
# at the given row and column.
#
# Args:
# 	a0: char - The character to print
#	a1: row - The row to print the given character
#	a2: col - The column to print the given character
#
# Register Usage
#      s0: The character to be printed.
#      s1: the current row
#      s2: the current column
#      t0: Bell ascii 7
#      t1: DISPLAY_DATA
#
# Return Values:
#	None
#
# References: This peice of code is adjusted from displayDemo.s(Zachary Selk, Jul 18, 2019)
#------------------------------------------------------------------------------
printChar:
	# Stack
	addi   sp, sp, -16
	sw     ra, 0(sp)
	sw     s0, 4(sp)
	sw     s1, 8(sp)
	sw     s2, 12(sp)
	# save parameters
	mv     s0, a0
	mv     s1, a1
	mv     s2, a2

	jal    ra, waitForDisplayReady

	# Load bell and position into a register
	addi   t0, zero, 7	# Bell ascii
	slli   s1, s1, 8	# Shift row into position
	slli   s2, s2, 20	# Shift col into position
	or     t0, t0, s1
	or     t0, t0, s2	# Combine ascii, row, & col
	
	# Move cursor
	lw     t1, DISPLAY_DATA
	sw     t0, 0(t1)
	jal    waitForDisplayReady	# Wait for display before printing
	
	# Print char
	lw     t0, DISPLAY_DATA
	sw     s0, 0(t0)
	
	# Unstack
	lw     ra, 0(sp)
	lw     s0, 4(sp)
	lw     s1, 8(sp)
	lw     s2, 12(sp)
	addi   sp, sp, 16
	jalr   zero, ra, 0



#------------------------------------------------------------------------------
# waitForDisplayReady
#
# Subroutine description: A method that will check if the Keyboard and Display MMIO Simulator terminal
# can be writen to, busy-waiting until it can.
#
# Args:
# 	None
#
# Register Usage
#      t0: used for DISPLAY_CONTROL
#
# Return Values:
#	None
#
# References: This peice of code is adjusted from displayDemo.s(Zachary Selk, Jul 18, 2019)
#------------------------------------------------------------------------------
waitForDisplayReady:
	# Loop while display ready bit is zero
	lw     t0, DISPLAY_CONTROL
	lw     t0, 0(t0)
	andi   t0, t0, 1
	beq    t0, zero, waitForDisplayReady
	jalr   zero, ra, 0
