.include "consts.s"
.org 0x20
/*********************************************************/
/**********************INTERRUP***************************/
/*********************************************************/

/* Exception Handler */
	rdctl et, ipending
	beq et, r0, OTHER_EXCEPTIONS

HARDWARE_EXCEPTION:						# Standardized code

	subi ea, ea, 4

	andi r13, et, 0b10					
	bne r13, r0, HANDLE_BUTTON
	andi r13, et, 0b1 					# interval timer is interrupt level 0
	beq r13, r0, END_HANDLER

	movia r14, TIMER_BASEADRESS
	sthio r0, 0(r14) 						# clear Time Out ( clear the interrupt )

/********************** LED FLASH **********************/
	movia r16, REDLED_BASEADDRESS
	beq	r15, r0, OFF
	addi r14, r0, 2
	bge r15, r14, DISPLAY

	ON:
		stwio r7, 0(r16)
		add r15, r0, r0
 		br END_HANDLER

	OFF:
		stwio r0, 0(r16)
		addi r15, r0, 1
		br END_HANDLER

/********************* DISPLAY ROTATE *****************/
	DISPLAY:
		movia r16, MSG_DISPLAY1
		movia r14, DISPLAY_BASE_ADDRESS1
		ldw r17, 0(r16)					# Load the array value on r17
		stwio r17, 0(r14)				# Set Display value

		movia r16, MSG_DISPLAY2
		movia r14, DISPLAY_BASE_ADDRESS2
		ldw r18, 0(r16)					# Load the array value on r18
		stwio r18, 0(r14)				# Set Display value

		addi r19, r0, 2
		beq r15, r19, SHIFTR
		addi r19, r0, 4
		beq r15, r19, SHIFTL
		br END_HANDLER
	SHIFTL:

		/*Swift first character of messages*/
		#Message 2
		srli r19, r17, 24
		slli r20, r18, 8
		or r20, r20, r19
		stw r20, 0(r16)

		#Message 1
		movia r16, MSG_DISPLAY1
		srli r19, r18, 24
		slli r20, r17, 8
		or r20, r20, r19
		stw r20, 0(r16)

		br END_HANDLER

	SHIFTR:

		/*Swift first character of messages*/
		#Message 2
		andi r19, r17, 0xFF
		slli r19, r19, 24
		srli r20, r18, 8
		or r20, r20, r19
		stw r20, 0(r16)

		#Message 1
		movia r16, MSG_DISPLAY1
		andi r19, r18, 0xFF
		slli r19, r19, 24
		srli r20, r17, 8
		or r20, r20, r19
		stw r20, 0(r16)

		br END_HANDLER

/**************** HANDLE PUSHBUTTON PRESS ***************/
	HANDLE_BUTTON:
		movia r12, PUSHBUTTON_BASE_ADDRESS
		ldwio r13, 12(r12)					# Word to buttons flags
		andi r13, r13, 0x06

		movi r14, 0x2
		beq r13, r14, INVERT_ROTATION
		movi r14, 0x4
		beq r13, r14, PAUSE_ROTATION
		br CLEAR_BTN

	INVERT_ROTATION:
		addi r19, r0, 2
		bne r15, r19, INVERT_R

		INVERT_L:
			addi r15, r0, 4
			br CLEAR_BTN

		INVERT_R:
			addi r15, r0, 2
			br CLEAR_BTN

	PAUSE_ROTATION:
			addi r19, r0, 3
			beq r15, r19, RESUME_ROTATION
			addi r19, r0, 5
			beq r15, r19, RESUME_ROTATION

			addi r15, r15, 1
			br CLEAR_BTN

			RESUME_ROTATION:
				subi r15, r15, 1
				br CLEAR_BTN

	CLEAR_BTN:
		stwio r0, 12(r12)							# Set interruption to button
		br END_HANDLER

OTHER_EXCEPTIONS:
END_HANDLER:
	eret

.global SET_INTERRUPTION
SET_INTERRUPTION:

/*********************************************************/
/**********************PROLOGUE***************************/
/*********************************************************/

# Adjust the stack pointer
	addi sp, sp, -8									# make a 8-byte frame

# Store registers to the frame
	stw ra, 4(sp)										# store the return address
	stw fp, 0(sp) 									# store the frame pointer

# Set the new frame pointer
	addi fp, sp, 0

/**********************SET INTERRUPTION*******************/
	movia r9,  MASK_CPU_INTERRUP
	movia r12, TIMER_BASEADRESS
	movia r13, TIME_COUNTERH
	movia r17, TIME_COUNTERL
	movia r14, MASK_START

	addi r16, r0, 2
	bne r15, r16, SKIP_DISPLAY_TIMER
	movia r13, TIME_COUNTERH_ROTATE
	movia r17, TIME_COUNTERL_ROTATE

	SKIP_DISPLAY_TIMER:

	######****** Start interval timer, enable its interrupts ******######
	sthio r17, 8(r12)  							# Set to low value
	sthio r13, 12(r12)  						# Set to high Value
	sthio r14, 4(r12)								# Set, START, CONT, E ITO = 1

	movia r12, PUSHBUTTON_BASE_ADDRESS
	movi r14, 0x06								# Mask to set button
	stwio r14, 8(r12)							# Set interruption to button

	######******enable Nios II processor interrupts******######
	wrctl ienable, r9 		  				# Set IRQ bit 0
	movi r9, 0x1
	wrctl status, r9 		  				# turn on Nios II interrupt processing ( SET PIE = 1 )

/********************************************************/
/*********************EPILOGUE***************************/
/********************************************************/

# Restore ra, fp, sp, and registers
	mov sp, fp
	ldw ra, 4(sp)
	ldw fp, 0(sp)
	addi sp, sp, 0
ret															# Return from subroutine

MSG_DISPLAY1:
.byte 0b00010000, 0b00111111, 0b00000000, 0b00000000

MSG_DISPLAY2:
.byte 0b01111101, 0b00000110, 0b00111111, 0b01011011
