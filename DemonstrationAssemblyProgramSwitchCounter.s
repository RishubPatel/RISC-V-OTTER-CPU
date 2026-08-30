#-----------------------------------------------------------------------------------------
#This program does the following (see flowchart for more detail):
#-moves the lit LED one to the right each time you press the button (wraps around at end)
#-increases a count each time you press the button if the switch below the LED
# is on (it goes up to 99 then back to 0)
#-displays that count
#-----------------------------------------------------------------------------------------
.data
sseg: .byte 0x03,0x9F,0x25,0x0D,0x99,0x49,0x41,0x1F,0x01,0x09 #LUT for 7-segs

.text
NUMBERS:
init:      li    s0, 0x11008004   #buttons address (switches is 4 less)
           li    s1, 0x1100C004   #segs address (anodes address is 4 more; LEDs address is 4 less)
           li    s2, 0x1100D000   #timer counter CSR port address (count port address is 4 more)
           
           li    s3, 7            #anode value for rightmost on only
           li    s4, 11           #anode value for second rightmost on only
           li    s6, 0xF          #value to turn all anodes off
           la    s5, sseg         #LUT address
           li    a5, 9            #load 9 into a5 for incr_cnt
           
           mv    a0, x0           #clear ones digit 
           mv    a1, x0           #clear tens digit
           li    s7, 0            #toggle flag: 0 for ones; 1 for tens
          
           li    t1, 249999       #load multiplexing delay length
           sw    t1, 4(s2)        #init TC count
           li    t1, 1            #init TC CSR
           sw    t1, 0(s2)        #no prescale, turn on TC

           la    t1, ISR          #load ISR address into t1
           csrrw x0, mtvec, t1    #store address in mtvec
           li    a2, 0x8000       #init switches/LEDs count
           sw    a2, -4(s1)       #init LEDs to leftmost on only

unmask:    li    t6, 0x8          #set bit 3 in t6
           csrrs x0, mstatus, t6  #enable interrupts: set MIE

#---------------------------------------------------------------------------------------------------
#- Main code loop: polls button, updates LEDs, updates the count as needed
#---------------------------------------------------------------------------------------------------

poll:      lhu  t2, 0(s0)         #wait for button press
           andi t2, t2, 1         #mask button
           beqz t2, poll          #keep waiting for button press if not pressed
           
           li    t3, 2000         #load debounce delay counter
dBounce:   lhu   t4, 0(s0)        #load buttons data
           andi  t4, t4, 1        #mask button value
           beqz  t4, poll         #if bounce (button value != 1), return to polling
           addi  t3, t3, -1       #decrement debounce delay counter
           bnez  t3, dBounce      #keep debouncing if not done        

	       lhu  a3, -4(s0)        #load switch data
           and  a3, a3, a2        #mask current switch value
           
incr_cnt:  beqz a3, done          #if current switch value is 0, don't increment

onez:      beq  a0, a5, tenz      #handle carry if needed
           addi a0, a0, 1         #else simply increment ones
           j done    
           
tenz:      mv   a0, x0            #clear ones
           beq  a1, a5, clr       #if count at 99, clear it
           addi a1, a1, 1         #otherwise simply increment tens
           j done

clr:       mv   a1, x0            #clear tens 

done:      srli a2, a2, 1         #shift over LEDs/switch count by one
           bnez a2, next          #if not wrapping around, proceed
           li   a2, 0x8000        #if wrapping around, set LEDs/switch count to leftmost on only
next:      sh   a2, -4(s1)        #output LED data

poll2:     lhu  t2, 0(s0)         #wait for button release
           andi t2, t2, 1         #mask button
           bnez t2, poll2         #keep waiting for button release if not released yet
           
           li    t3, 2000         #load debounce delay counter
dBounce2:  lhu   t4, 0(s0)        #load buttons data
           andi  t4, t4, 1        #mask button value
           bnez  t4, poll2        #if bounce (button value != 0), return to polling
           addi  t3, t3, -1       #decrement debounce delay counter
           bnez  t3, dBounce2     #keep debouncing if not done        

           j    poll              #return to polling for button press

#------------------------------------------------------------------------------------------
#- The ISR: handles multiplexing (interrupts come from TC) --> MODIFIES a7, t0, t5, t6, s7
#------------------------------------------------------------------------------------------
ISR:

multiplex: sb   s6, 4(s1)         #turn off all anodes
           bnez s7, tens          #if previously output ones digit, do tens this time

ones:      mv   a7, a0            #load ones digit into a7
           mv   t0, s3            #load t0 with value to turn rightmost digit on (anode)
           j    display

tens:      beqz a1, done2         #if tens digit is 0, keep displaying ones digit
	   	   mv   a7, a1            #load tens digit into a7
	       mv   t0, s4            #load t0 with value to turn second rightmost digit on (anode)

display:   add  t5, s5, a7        #get segs value address
           lb   t6, 0(t5)         #load segs value
           sb   t6, 0(s1)         #output segs value
           sb   t0, 4(s1)         #output anode value
           
done2:     xori s7, s7, 1         #toggle the toggle flag
           mret
