#Sophia Schuur
#Mips program to handle interrupts between output and keyboard
 
  
    .data 
 expBuffer: .space 60
 expBufferLen: .word 0
 
 .kdata
 v0: .word 10
 a0: .word 11
 
 .text
 .globl main
 main:
 
 .eqv    TCR 0xffff0008      
 .eqv    TDR 0xffff000c
    	
 mfc0 $a0, $12			
 ori $a0, 0xff11			
 mtc0 $a0, $12			

 lui $t0, 0xFFFF			
 ori $a0, $0, 2				
 sw $a0, 0($t0)

 loop:
 j loop
 #infinite loop 
 
 #################### begin kernal code
 .ktext 0x80000180
 
 move $k1, $at
 .set at

 sw $v0, v0
 sw $a0, a0
 
 mfc0 $k0, $13
 #check cause reg
 
 srl $a0, $k0, 2
 andi $a0, $a0, 0x1f
 bne $a0, $zero, ExitProgram
 #check cause interrupt
 
 la $k0, myHandCode
 jalr $k0
 
 ExitProgram:
 	
 ori $k0, 0x11
 mtc0 $k0, $12
 	
 lw $v0, v0
 lw $a0, a0
 
 mtc0 $0, $13
 mfc0 $k0, $12
 andi $k0, 0xfffd
 	
 eret
 
 ########################## Begin myHandCode
 .text
 myHandCode:
 
 #grab from the stack
 addi $sp, $sp, -8
 sw $v0, 0($sp)
 sw $ra, 4($sp)
 
 lui $v0, 0xFFFF
 lw $v0, 4($v0)
 #Grab the key pressed
 
 jal Store
 #Store key to buffer array
 
 #Detect equal sign. If pressed key is an equal sign (Ascii value 61), then add!
 beq $v0, 61, IfEqualSign 
 j NotEqualSign
 IfEqualSign:
 jal Evaluate
 
 #If not, keep on going
 NotEqualSign:
 lw $v0, 0($sp)
 lw $ra, 4($sp)
 addi $sp, $sp, 8
 
 jr $ra
 
 ####################### Store the key pressed to the array buffer
 Store:
 #grab the stack
 addi $sp, $sp, -12
 sw $t0, 0($sp)
 sw $t1, 4($sp)
 
 la $t0, expBuffer
 lw $t1, expBufferLen
 #load in these variables
 
 mul $t1, $t1, 4
 add $t1, $t0, $t1
 sw $v0, 0($t1)
 #Get real value of key at array[t1] and save in v0
 
 sub $t1, $t1, $t0
 div $t1, $t1, 4
 
 addi $t1, $t1, 1
 sw $t1, expBufferLen
 #Add one to the buffer length and save
 
 #Restore the stack
 lw $t0, 0($sp)
 lw $t1, 4($sp)
 addi $sp, $sp, 12
 jr $ra
 
 ########################## Add the digits
 Evaluate:
 #Save to the stack
 addi $sp, $sp, -16
 sw $t0, 0($sp)
 sw $t1, 4($sp)
 sw $a0, 8($sp)
 sw $ra, 12($sp)
 
 #Load variables
 la $t0, expBuffer
 lw $t1, 8($t0)
 lw $t0, 0($t0)
 

 andi $t0, $t0, 0x0F
 andi $t1, $t1, 0x0F
 #Convert ascii digits to integers 
 
 add $a0, $t0, $t1
 #Add em up
 
 jal ConvertAndStore
 
 #Restore to stack
 lw $t0, 0($sp)
 lw $t1, 4($sp)
 lw $a0, 8($sp)
 lw $ra, 12($sp)
 addi $sp, $sp, 16
 jr $ra
 
 ##################### Convert back to ascii and store to array buffer
 ConvertAndStore:
 addi $sp, $sp, -16
 sw $t0, 0($sp)
 sw $t1, 4($sp)
 sw $t2, 8($sp)
 sw $ra, 12($sp)
 #Save from Stack
 
 bge $a0, 10, DoubleDigit
 #if its a double digit, go to the doubleDigit branch
 j NotDouble
 DoubleDigit:
 li $a1, 1
 sub $a0, $a0, 10
 #get the second digit of the key to display to the screen. all we need to do is subtract 10 to get it
 
 la $t0, expBuffer
 lw $t1, expBufferLen
 #just load in these values 
 
 addi $t2, $t1, 1
 
 addi $a1, $a1, 48
 addi $a0, $a0, 48
 #convert key back to ascii
 
 mul $t1, $t1, 4
 add $t1, $t0, $t1
 #get real value of item at array[t1]
 mul $t2, $t2, 4
 add $t2, $t0, $t2
 #get real value of item at array[t2]
 
 sw $a1, 0($t1)
 sw $a0, 0($t2)
 #save variables
 
 lw $t1, expBufferLen
 addi $t1, $t1, 2
 sw $t1, expBufferLen
 #save and add two to the buffer length (because of double digit)
 
 j ExitDouble
 NotDouble:
 #if not a double, no need to parse 
 
 la $t0, expBuffer
 lw $t1, expBufferLen
 #just load in these values
 
 mul $t1, $t1, 4
 add $t1, $t0, $t1
#get real value of item at array[t1]
 
 addi $a0, $a0, 48
 #convert key to ascii
 
 sw $a0, 0($t1)
 #save variable
 
 lw $t1, expBufferLen
 addi $t1, $t1, 1
 sw $t1, expBufferLen
 #save and add one to the buffer length 
 
 ExitDouble:
 
 jal Display
 
 lw $t0, 0($sp)
 lw $t1, 4($sp)
 lw $t2, 8($sp)
 lw $ra, 12($sp)
 addi $sp, $sp, 16
 #restore the stack
 jr $ra

 ###################### write to the display
 Display:
 addi $sp, $sp, -4
 sw $t1, 0($sp)
 #grab from the stack

 li $t3, 0
 lw $t2, expBufferLen
 li $t4, 0
 la $t5, expBuffer
 lui $t6, 0xFFFF
 #display - thanks to stack overflow

 DisplayWait:
 #since we want to poll and not use interrupt we must wait for the display to loop all the way through
 lw $t0, TCR
 andi $t0, $t0, 1
 beq $t0, $zero, DisplayWait
 
 mul $t4, $t3, 4
 add $t4, $t5, $t4
 
 lw $a0, 0($t4)
 sw $a0, TDR
 
 addi $t3, $t3, 1
 bge $t3, $t2, DisplayExit

 j DisplayWait
 #display - thanks to stack overflow
 
 DisplayExit:
 lw $t1, 0($sp)
 addi $sp, $sp, 4
 #save to the stack and stop displaying
 
 jr $ra
