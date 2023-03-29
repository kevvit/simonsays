.data
sequence:  .byte 0,0,0,0
count:     .word 4
promptw:   .string "\nYou Win! Would you like to continue? (0 - No, 1 - Yes):  "
promptl:   .string "\nYou Lost. Would you like to restart? (0 - No, 1 - Yes):  "
thanks:    .string "Thanks for playing"
difficulty:.string "Current sequence length: "
.globl main
.text
main:
# Memory Enhancement - Increase pattern size
# Sequences are instead stored in a stack, and is read/written to using the stack pointer sp.
# Each time the game restarts (after a win), a new random integer is added to on top of the
# stack. During each round, the length of the sequence is displayed. The process goes like
# this:

# - If the game just started, generate [count] random ints and store them in the stack
# - If the game was continued, generate one random int and store it in the stack
# - Read from the bottom of the stack and display each led accordingly
# - Poll from dpad as normal, as many times as the length of the sequence
# - If the user wins the round, restart the game adding another sequence
# - If the user loses, restart with [count] random ints as the sequence length

# Code Enchancement - Speed up the game
# The game starts with each LED displaying with a 500ms delay. After each win and restart
# of the game, this delay is decreased by 50ms, with a minimum delay of 50ms. Each loss
# resets the delay to 500ms.

    # TODO: Before we deal with the LEDs, we need to generate a random
    # sequence of numbers that we will use to indicate the button/LED
    # to light up. For example, we can have 0 for UP, 1 for DOWN, 2 for
    # LEFT, and 3 for RIGHT. Store the sequence in memory. We provided 
    # a declaration above that you can use if you want.
    # HINT: Use the rand function provided to generate each number

   lw t6 count # initial sequence length
   li s4 500 # initial delay length
   li s1 1 # mode, 1 if new game
   RESTART:
   li t3 0
   
   # display current sequence length
   li a7 4
   la a0 difficulty
   ecall
   li a7 1
   mv a0 t6
   ecall
   
   RANDOMIZER:
        li a0 4
        call rand # generate random number from {0 (UP), 1 (DOWN), 2 (LEFT), 3 (RIGHT)}
        
        addi sp sp -1
        sb a0 0(sp) # add the number to the stack, which holds the sequence
         
        addi t3 t3 1
        beq s1 zero DONE # second round or more, so only add one random element
        beq t6 t3 DONE
        j RANDOMIZER
    DONE:
   
    # TODO: Now read the sequence and replay it on the LEDs. You will
    # need to use the delay function to ensure that the LEDs light up 
    # slowly. In general, for each number in the sequence you should:
    # 1. Figure out the corresponding LED location and colour
    # 2. Light up the appropriate LED (with the colour)
    # 2. Wait for a short delay (e.g. 500 ms)
    # 3. Turn off the LED (i.e. set it to black)
    # 4. Wait for a short delay (e.g. 1000 ms) before repeating

    add sp sp t6 # reset stack pointer
    li t3 0 # loop counter
    
    # s1 is the mode for lighting the circles:
    # 0 is to display dpad input, 1 is for displaying initial sequence
    li s1 1
    
    while: 
        beq t3 t6 finish # end loop if displayed all the colours in sequence
        lb s0 0(sp) # load top byte of stack
        
        beq s0 zero ifgreen # light green
        li t4 2
        beq s0 t4 ifblue # light blue
        li t4 3
        beq s0 t4 ifyellow # light yellow
        li t4 1
        beq s0 t4 ifred # light red
        j finish
        
        # set up the correct coords for each led
        ifgreen:
            li t4 0
            li t5 0
            li a0 0x00ff00
            j continue
        ifblue:
            li t4 0
            li t5 1
            li a0 0x424ef5
            j continue
        ifyellow:
            li t4 1
            li t5 0
            li a0 0xffff00
            j continue
        ifred:
            li t4 1
            li t5 1
            li a0 0xff0000
        continue:
            # set to proper colour
            mv a1 t4
            mv a2 t5
            call setLED
            
            # delay
            mv t0 s4
            mv a0 t0
            call delay
            
            # set black
            mv a1 t4
            mv a2 t5
            li a0 0x000000
            call setLED
            
            # delay
            li t0 500
            mv a0 t0
            call delay
            
            beq s1 zero nextInput
            addi t3 t3 1
            addi sp sp -1
            j while
        finish:
    
    
    # TODO: Read through the sequence again and check for user input
    # using pollDpad. For each number in the sequence, check the d-pad
    # input and compare it against the sequence. If the input does not
    # match, display some indication of error on the LEDs and exit. 
    # Otherwise, keep checking the rest of the sequence and display 
    # some indication of success once you reach the end.
    
    add sp sp t6 # reset stack pointer to beginning
    # s1 is the mode for lighting the circles:
    # 0 is to display dpad input, 1 is for displaying initial sequence
    li s1 0 
    li s2 0 # loop counter
    
    # keep receiving dpad inputs and compare them to the stored sequence
    userloop:
        beq s2 t6 winGame # if user correctly inputted all the colours, win game
        lb s0 0(sp)
        
        call pollDpad # get user input from d-pad
        bne a0 s0 loseGame # if the input is not the same as the current colour, lose game
        
        # light up the corresponding LEDS since the user was correct
        beq s0 zero ifgreen
        li s3 2
        beq s0 s3 ifblue
        li s3 3
        beq s0 s3 ifyellow
        li s3 1
        beq s0 s3 ifred
        
        nextInput:
        addi s2 s2 1
        addi sp sp -1
        j userloop
        

    # TODO: Ask if the user wishes to play again and either loop back to
    # start a new round or terminate, based on their input.
    winGame:
        # Prompt winning msg and ask if user wants to restart
        li a7 4
        la a0 promptw
        ecall
        
        # Retrieve user input
        li a7 4
        call readInt
        mv t0 a0
        
        beq t0 zero exit # if user inputs 0, exit the game
        # don't reset stack pointer here, we want to add onto the old sequence
        li s1 0 # indicates a continued game
        addi t6 t6 1 # increase size of sequence length
        li t0 50
        beq t0 s4 RESTART # if delay is already at minimum (50ms) just restart
        addi s4 s4 -50 # decrease delay between LEDS by 50ms
        j RESTART
    loseGame:
        li s1 3 # flash red this many times
        li s2 0 # loop counter for flashRed
        # flash the last inputted incorrect led red a few times
        beq a0 zero loseGreen
        li s3 2
        beq a0 s3 loseBlue
        li s3 3
        beq a0 s3 loseYellow
        li s3 1
        beq a0 s3 loseRed
        end:
         li a7 4
         la a0 promptl
         ecall 
         call readInt # get response from user
         
         mv t0 a0
         beq t0 zero exit # if 0, exit the game
         
         # reset registers and restart
         add sp sp t6
         lw t6 count
         li s4 500
         li a7 4
         j RESTART
    loseGreen:
            li t4 0
            li t5 0
            j flashRed
    loseBlue:
            li t4 0
            li t5 1
            j flashRed
    loseYellow:
            li t4 1
            li t5 0
            j flashRed
    loseRed:
            li t4 1
            li t5 1
    flashRed:
            beq s1 s2 end
            # set red
            li a0 0xff0000
            mv a1 t4
            mv a2 t5
            call setLED
            
            # delay
            li t0 100
            mv a0 t0
            call delay
            
            # set black
            mv a1 t4
            mv a2 t5
            li a0 0x000000
            call setLED
            
            # delay
            li t0 100
            mv a0 t0
            call delay
            
            addi s2 s2 1
            j flashRed
    
exit:
    add sp sp t6
    li a7 4
    la a0 thanks
    ecall
    li a7, 10
    ecall
    
# provided by previous labs
readInt:
    addi sp, sp, -12
    li a0, 0
    mv a1, sp
    li a2, 12
    li a7, 63
    ecall
    li a1, 1
    add a2, sp, a0
    addi a2, a2, -2
    mv a0, zero
parse:
    blt a2, sp, parseEnd
    lb a7, 0(a2)
    addi a7, a7, -48
    li a3, 9
    bltu a3, a7, error
    mul a7, a7, a1
    add a0, a0, a7
    li a3, 10
    mul a1, a1, a3
    addi a2, a2, -1
    j parse
parseEnd:
    addi sp, sp, 12
    ret

error:
    li a7, 93
    li a0, 1
    ecall
    
# --- HELPER FUNCTIONS ---
# Feel free to use (or modify) them however you see fit

# Takes in the number of milliseconds to wait (in a0) before returning
delay:
    mv t0, a0
    li a7, 30
    ecall
    mv t1, a0
delayLoop:
    ecall
    sub t2, a0, t1
    bgez t2, delayIfEnd
    addi t2, t2, -1
delayIfEnd:
    bltu t2, t0, delayLoop
    jr ra

# Takes in a number in a0, and returns a (sort of) random number from 0 to
# this number (exclusive)
rand:
    mv t0, a0
    li a7, 30
    ecall
    remu a0, a0, t0
    jr ra
    
# Takes in an RGB color in a0, an x-coordinate in a1, and a y-coordinate
# in a2. Then it sets the led at (x, y) to the given color.
setLED:
    li t1, LED_MATRIX_0_WIDTH
    mul t0, a2, t1
    add t0, t0, a1
    li t1, 4
    mul t0, t0, t1
    li t1, LED_MATRIX_0_BASE
    add t0, t1, t0
    sw a0, (0)t0
    jr ra
    
# Polls the d-pad input until a button is pressed, then returns a number
# representing the button that was pressed in a0.
# The possible return values are:
# 0: UP
# 1: DOWN
# 2: LEFT
# 3: RIGHT
pollDpad:
    mv a0, zero
    li t1, 4
pollLoop:
    bge a0, t1, pollLoopEnd
    li t2, D_PAD_0_BASE
    slli t3, a0, 2
    add t2, t2, t3
    lw t3, (0)t2
    bnez t3, pollRelease
    addi a0, a0, 1
    j pollLoop
pollLoopEnd:
    j pollDpad
pollRelease:
    lw t3, (0)t2
    bnez t3, pollRelease
pollExit:
    jr ra
