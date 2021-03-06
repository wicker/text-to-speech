@ Author: Jenner Hanni - Winter 2013 - ECE372
@ Project #1 - Button-driven Talker
@
@ ============================================================================ @
@ INITIALIZING PHASE            					       @
@ ============================================================================ @

.text
.global _start
_start:

@------------------@
@ Define addresses @
@------------------@

.EQU GPCR2,  0x40E0002C
.EQU GPDR2,  0x40E00014
.EQU GRER0,  0x40E00030
.EQU GRER2,  0x40E00038
.EQU GRER3,  0x40E00130
.EQU GEDR0,  0x40E00048
.EQU GEDR2,  0x40E00050
.EQU GEDR3,  0x40E00148
.EQU GAFR2L, 0x40E00064

.EQU CAFRL,  0x000C0000   @ Value to clear or set bits 19 and 20

.EQU BIT0,   0x00000001   @ Value to clear or set bit 0
.EQU BIT4,   0x00000010   @ Value to clear or set bit 4
.EQU BIT5,   0x00000020   @ Value to clear or set bit 5
.EQU BIT6,   0x00000040   @ Value to clear or set bit 6
.EQU BIT7,   0x00000080   @ Value to clear or set bit 7
.EQU BIT9,   0x00000200   @ Value to clear or set bit 9
.EQU BIT10,  0x00000400   @ Value to clear or set bit 10
.EQU BIT14,  0x00004000   @ Value to clear or set bit 14
.EQU BIT20,  0x00100000   @ Value to clear or set bit 20

.EQU ICIP,   0x40D00000  @ Interrupt Controller IRQ Pending Register
.EQU ICMR,   0x40D00004  @ Interrupt Controller Mask Register
.EQU ICPR,   0x40D00010  @ Interrupt Controller Pending Register
.EQU ICCR,   0x40D00014  @ Interrupt Controller Control Register
.EQU ICLR,   0x40D00008  @ Interrupt Controller Level Register

@--------------------------------@
@ Define UART Register Addresses @
@--------------------------------@

.EQU RHR,     0x10800000  @ Receive Holding Register
.EQU THR,     0x10800000  @ Transmit Holding Register
.EQU DLSB,    0x10800000  @ Divisor LSB 
.EQU DMSB,    0x10800002  @ Divisor MSB
.EQU IER,     0x10800002  @ Interrupt Enable Register
.EQU ISR,     0x10800004  @ Interrupt Status Register
.EQU FCR,     0x10800004  @ FIFO Control Register
.EQU LCR,     0x10800006  @ Line Control Register
.EQU MCR,     0x10800008  @ Modem Control Register
.EQU LSR,     0x1080000A  @ Line Status Register
.EQU MSR,     0x1080000C  @ Modem Status Register
.EQU SPR,     0x1080000E  @ Scratch Pad Register

@-------------------------------------------@
@ Set GPIO 73 back to Alternate Function 00 @
@-------------------------------------------@

LDR R0, =GAFR2L @ Load pointer to GAFR2_L register
LDR R1, [R0]    @ Read GAFR2_L to get current value
BIC R1, #CAFRL  @ Clear bits 19 and 20 to make GPIO 73 not an alternate function
STR R1, [R0]    @ Write word back to the GAFR2_L

@-------------------------------------------------------@
@ Initialize GPIO 73 as an input and rising edge detect @
@-------------------------------------------------------@

LDR R0, =GPCR2	@ Point to GPCR2 register
LDR R1, [R0]    @ Read current value of GPCR2 register
ORR R1, #BIT9	@ Word to clear bit 9, sign off when output
STR R1, [R0]	@ Write to GPCR2

LDR R0, =GPDR2	@ Point to GPDR2 register
LDR R1, [R0]	@ Read GPDR2 to get current value
BIC R1, #BIT9   @ Clear bit 9 to make GPIO 73 an input
STR R1, [R0]	@ Write word back to the GPDR2

LDR R0, =GRER2	@ Point to GRER2 register
LDR R1, [R0]	@ Read current value of GRER2 register
ORR R1, #BIT9   @ Load mask to set bit 9
STR R1, [R0]	@ Write word back to GRER2 register

@----------------------------------------------------------@
@ Initialize GPIO 10 as a rising edge detect for COM2 UART @
@----------------------------------------------------------@

LDR R0, =GRER0	@ Point to GRER0 register
LDR R1, [R0]	@ Read GRER0 register
ORR R1, #BIT10	@ Set bit 10 to enable GPIO10 for rising edge detect
STR R1, [R0]	@ Write back to GRER0

@-----------------@
@ Initialize UART @
@-----------------@

@@ Set DLAB bit in line control register to access baud rate divisor
LDR R0, =LCR	@ Point to UART line control register
MOV R1, #0x83	@ Value for divisor enable = 1, 8 bits, no parity, 1 stop bit
STRB R1, [R0]	@ Write byte back to LCR

@@ Load divisor value to give 38.4Kb/sec
LDR R0, =DLSB	@ Pointer to divisor low register (DLSB)
MOV R1, #0x18	@ #0x18 divisor for 38.4Kb/sec
STRB R1, [R0]	@ Write byte back to DLSB

LDR R0, =DMSB 	@ Pointer to divisor high register (DMSB)
MOV R1, #0x00	@ Value for the divisor high register (DMSB)
STRB R1, [R0]	@ Write byte back to DMSB

@@ Toggle DLAB bit back to 0 to give access to Tx and Rx registers
LDR R0, =LCR	@ Point to COM2 UART line control register
MOV R1, #0x03	@ Value for divisor enable = 0, 8 bits, no parity, 1 stop bit
STRB R1, [R0]	@ Write byte back to LCR

@@ Clear FIFO and turn off FIFO mode
LDR R0, =FCR	@ Pointer to FIFO Control Register (FCR)
MOV R1, #0x00	@ Value to disable FIFO and clear FIFO
STRB R1, [R0]	@ Write word back to FCR

@-----------------------------------------------------------------@
@ Hook IRQ procedure address and install our IRQ_DIRECTOR address @
@-----------------------------------------------------------------@

MOV R0, #0x18	@ Load IRQ interrupt vector address 0x18
LDR R1, [R0]	@ Read instruction from interrupt vector table at 0x18
LDR R2, =0xFF   @ Construct mask (FFF or FF)?
AND R1, R1, R2	@ Mask all but offset part of instruction
ADD R1,R1,#0x20	@ Build absolute address of IRQ procedure in literal pool
LDR R2, [R1]	@ Read BTLDR IRQ address from literal pool
STR R2, BTLDR_IRQ_ADDRESS	@ Save BTLDR IRQ address for use in IRQ_DIRECTOR
LDR R3, =IRQ_DIRECTOR		@ Load absolute address of our interrupt director
STR R3, [R1]	@ Store this address literal pool

@---------------------------------------------------------------@
@ Initialize interrupt controller for button and UART on IP<10> @
@---------------------------------------------------------------@

LDR R0, =ICMR	@ Load pointer to address of ICMR register
LDR R1, [R0]	@ Read current value of ICMR
ORR R1, #BIT10	@ Set bit 10 to unmask IM10
STR R0, [R1] 	@ Write word back to ICMR register

@------------------------------------------------------------------------@
@ Make sure IRQ interrupt on processor enabled by clearing bit 7 in CPSR @
@------------------------------------------------------------------------@

MRS R3, CPSR	@ Copy CPSR to R3
BIC R3, #BIT7	@ Clear bit 7 (IRQ Enable bit)
MSR CPSR_c, R3	@ Write new counter value back in memory
		@ _c means modify the lower eight bits only

@ ============================================================================ @
@ RUNTIME PHASE								       @
@ ============================================================================ @

@----------------------------------------@
@ Wait in the main loop for an interrupt @
@----------------------------------------@

LOOP: 	NOP
	B LOOP

@-----------------------------------------------------------------------------@
@ IRQ_DIRECTOR - An interrupt has been detected! Test it to determine source. @
@-----------------------------------------------------------------------------@

IRQ_DIRECTOR:
	STMFD SP!, {R0-R5, LR}	@ Save registers on stack
	LDR R0, =ICIP	@ Point at IRQ Pending Register (ICIP)
	LDR R1, [R0]	@ Read ICIP
	TST R1, #BIT10	@ Check if GPIO 119:2 IRQ interrupt on IP<10> asserted
	BEQ PASSON	@ No, must be other IRQ, pass on to system program

	LDR R0, =GEDR2	@ Load GEDR2 register address to check if GPIO73 asserted
	LDR R1, [R0]	@ Read GEDR2 register value
	TST R1, #BIT9	@ Check if bit 9 in GEDR2 = 1
	BNE BTN_SVC	@ Yes, must be button press, go service the button
			@ No, must be other GPIO 119:2 IRQ, pass on: 

	LDR R0, =GEDR0	@ Load address of GEDR0 register
	LDR R1, [R0]	@ Read GEDR0 register address to check if GPIO10 
	TST R1, #BIT10	@ Check for UART interrupt on bit 10
	BNE TLKR_SVC	@ Yes, go send character


@-----------------------------------------------------------@
@ PASSON - The interrupt is not from our button or the UART @
@-----------------------------------------------------------@

PASSON: 
	LDMFD SP!, {R0-R5,LR}		@ Restore the registers
	@LDR PC, =BTLDR_IRQ_ADDRESS	@ Go to bootloader IRQ service procedure
	SUBS PC, LR, #4			@ Return to wait loop

@-------------------------------------------------------------@
@ BTN_SVC - The interrupt came from our button on GPIO pin 73 @
@-------------------------------------------------------------@

BTN_SVC:
	LDR R0, =GEDR2		@ Point to GEDR2 
	LDR R1, [R0]		@ Read the current value from GEDR2
	ORR R1, #BIT9		@ Set bit 9 to clear the interrupt from pin 73
	STR R1, [R0]		@ Write to GEDR2

        @@ Enable Tx interrupt and enable modem status change interrupt
	LDR R0, =IER	        @ Pointer to interrupt enable register (IER)
	MOV R1, #0x0A	        @ Bit 3 = modem status int, bit 1 = Tx enable
	STRB R1, [R0]	        @ Write to IER

	LDMFD SP!, {R0-R5,LR}	@ Restore registers, including return address
	SUBS PC, LR, #4		@ Return from interrupt to wait loop

@---------------------------------------------------------------------------------@
@ TLKR_SVC - The interrupt came from the CTS# low or THR empty or other interrupt @
@---------------------------------------------------------------------------------@

TLKR_SVC:
	LDR R0, =GEDR0	@ Point to GEDR0
	LDR R1, [R0]	@ Read the current value from GEDR0
	ORR R1, #BIT10	@ Set bit 10 to clear the interrupt from UART
	STR R1, [R0]	@ Write to GEDR0

	LDR R0, =MSR	@ Point to MSR
	LDRB R1, [R0]	@ Read MSR, resets MSR change interrupt bits
	TST R1, #BIT4	@ Check if the CTS# is currently asserted (MSR bit 4)
	BEQ NOCTS	@ If not, go check for THR status

	LDR R0, =LSR	@ Point to LSR
	LDRB R1, [R0]	@ Read LSR
        TST R1, #BIT5	@ Check if THR-ready is asserted
	BNE SEND	@ If yes, both are asserted, send character
	B GOBCK		@ If no, exit and wait for THR-ready

@--------------------------------------------------@
@ NOCTS - The interrupt did not come from CTS# low @
@--------------------------------------------------@

NOCTS:
	LDR R0, =LSR	@ Point to LSR
	LDRB R1, [R0]	@ Read LSR (does not clear interrupt)
	TST R1, #0x20	@ Check if THR-ready is asserted
	BEQ GOBCK	@ Neither CTS# or THR are asserted, must be other source
			@ Else no CTS# but THR asserted, disable interrupt on THR
			@ to prevent spinning while waiting for CTS#

	LDR R0, =IER	@ Load IER
	MOV R1, #0x08	@ Disable bit 1 = Tx interrupt enable (Mask THR)
	STRB R1, [R0]	@ Write to IER
	B GOBCK		@ Exit to wait for CTS# interrupt
		
@----------------------------------------------------------------@
@ SEND - unmask THR, send the character, test if more characters @
@----------------------------------------------------------------@

SEND:
	LDR R0, =IER	@ Load pointer to IER
	MOV R1, #0x0A	@ Bit 3 = modem status interrupt, bit 1 = Tx int enable
	STRB R1, [R0]	@ Write to IER

	LDR R0, =CHAR_PTR	@ Load address of char pointer
	LDR R1, [R0]		@ Load address of desired char in text string
	LDR R2, =CHAR_COUNT	@ Load address of count store location
	LDRB R3, [R2]		@ Get current char count value
	LDRB R4, [R1], #1	@ Load char from string, increment char pointer
	STRB R1, [R0]		@ Put incremented char address into CHAR_PTR for next time

	LDR R5, =THR		@ Point at UART THR
	STRB R4, [R5]		@ Write char to THR, which clears interrupt source for now
	SUBS R3, R3, #1		@ Decrement char counter by 1
	STRB R3, [R2]		@ Store char value counter back in memory
	CMP R3, #0x00		@ Test char counter value
	BNE GOBCK		@ If greater than zero, go get more characters

	LDR R3, =MESSAGE	@ If not, reload the message. Get address of start string.
	STR R3, [R0]		@ Store the string starting address in CHAR_PTR
	MOV R3, #MESSAGE_LEN	@ Load the original number of characters in string again
	STR R3, [R2]		@ Write that length to CHAR_COUNT

	LDR R0, =IER	        @ Pointer to interrupt enable register (IER)
	MOV R1, #0x00	        @ Bit 3 = modem status int, bit 1 = Tx enable
	STRB R1, [R0]	        @ Write to IER

@------------------------------------@
@ GOBCK - Restore from the interrupt @
@------------------------------------@

GOBCK:
	LDMFD SP!, {R0-R5,LR}	@ Restore original registers, including return address
	SUBS PC, LR, #4		@ Return from interrupt (to wait loop)

@--------------------@
@ Build literal pool @
@--------------------@

BTLDR_IRQ_ADDRESS: .word 0

@ ============================================================================== @
@ Define the data section                                                        @
@ ============================================================================== @

.data

.align 4

MESSAGE: 
	.byte 0x0D	@ So the RC8660 will begin to speak
	.ascii "Hello"
	.byte 0x0D	@ So the RC8660 will begin to speak

.align 4

CHAR_COUNT: 
	.word 7

.align 4

.EQU MESSAGE_LEN, 7


.align 4

CHAR_PTR:
	.word MESSAGE

.end




