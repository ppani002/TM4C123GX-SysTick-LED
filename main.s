	;Include constants I define to main
	INCLUDE my_Constants.s
	;Include variables I define to main
	;INCLUDE my_Variables.s
	IMPORT PB5_MASK

	AREA |.text|, CODE, READONLY
	THUMB
	EXPORT __main
	ENTRY
	
	;This  subroutine initializes GPIO
GPIO_Init	PROC
	
	;Push LR onto stack first
	PUSH {LR}
	
	
	;power pin PB5 to light up external LED
	;select APB. GPIOHBCTL
	LDR r0, =SYS_CONTROL
	LDR r1,[r0, #GPIOHBCTL]
	ORR r1, r1, #(1<<1) ;Enable port B AHB instead. "Note that GPIO can only be accessed through the AHB aperture
	;BFC r1,#0,#6 ;use APB when 0
	;AND r1, r1, 0x0000.0000 ;use APB when 0
	STR r1,[r0, #GPIOHBCTL] 
	
	;Enable clock. RCGCGPIO
	LDR r0, =SYS_CONTROL 
	LDR r1,[r0,#RCGCGPIO]
	ORR r1, r1, #(1<<1) ;enable port B clock(bit 5)
	STR r1,[r0,#RCGCGPIO]
	
	;set to output. GPIODIR
	LDR r0, =AHB_PORTB
	LDR r1,[r0,#GPIODIR]
	ORR r1, r1, #(1<<5);pin5
	STR r1,[r0,#GPIODIR]
	
	;set mode to GPIO (nor alternate function). GPIOAFSEL
	LDR r0, =AHB_PORTB
	LDR r1,[r0,#GPIOAFSEL]
	BFC r1,#0,#8 ;clears fields. 0 = GPIO
	;AND r1, r1, 0x0000.0000 ;0 = GPIO
	STR r1,[r0,#GPIOAFSEL]
	
	;to drive strength to 2mA. GPIODR2R
	LDR r0, =AHB_PORTB
	LDR r1,[r0,#GPIODR2R]
	ORR r1, r1, #(1<<5);pin5
	STR r1,[r0,#GPIODR2R]
	
	;set to pull up. GPIOPUR
	LDR r0, =AHB_PORTB
	LDR r1,[r0,#GPIOPUR]
	ORR r1, r1, #(1<<5) ;pin5
	STR r1,[r0,#GPIOPUR]

	;enable digital output. GPIODEN
	LDR r0, =AHB_PORTB
	LDR r1,[r0,#GPIODEN]
	ORR r1,r1, #(1<<5);pin 1 = digital output enable
	STR r1,[r0,#GPIODEN]
	
	;write "high" to data register for port F pin 1 to turn on red LED. GPIODATA
	LDR r0, =AHB_PORTB
	LDR r1,[r0,#GPIODATAPB5]
	LDR r2, =PB5_MASK	;get RAM address of PB5 mask (pointer)
	LDR r3,[r2]	;get the value of PB5 mask
	ORR r3, r3, #0xF0
	STR r3,[r2]
	
	ORR r1, r1, r3	;Set PB5 to 'high'
	STR r1,[r0,#GPIODATAPB5]
	;LDR r1,[r0,#GPIODATAPB5]

	
	;Pop LR and return to __main
	POP {LR}
	BX LR
	
	ENDP
	
	
	;This subroutine initialies SysTick
SysTick_Init	PROC
	
	;Push LR onto stack first
	PUSH {LR}
	
	;Clear ENABLE bit. STCTRL
	LDR r0, =SYS_PERIPH
	LDR r1, [r0,#STCTRL]
	AND r1, r1, #0	;Clear bit 0
	STR r1, [r0, #STCTRL]
	
	;Set reload value. STRELOAD
	LDR r0, =SYS_PERIPH
	LDR r1, [r0,#STRELOAD]
	ORR r1, r1, #(1<<5);23) ;Set interrupt period here
	STR r1, [r0,#STRELOAD]
	
	;Clear timer and interrupt flag. STCURRENT
	LDR r0, =SYS_PERIPH
	LDR r1, [r0,#STCURRENT]
	ORR r1, r1, #1 ;Write any value to reset
	STR r1, [r0,#STCURRENT]
	LDR r1, [r0,#STCURRENT]
	
	;Set CLK_SRC bit to use the system clock (PIOSC). STCTRL
	LDR r0, =SYS_PERIPH
	LDR r1, [r0,#STCTRL]
	ORR r1, r1, #(1<<2) ;bit 2
	STR r1, [r0,#STCTRL]
	
	;Set INTEN bit to enable interrupts. STCTRL
	LDR r0, =SYS_PERIPH
	LDR r1, [r0,#STCTRL]
	ORR r1, r1, #(1<<1) ;bit 1
	STR r1, [r0,#STCTRL]
	
	;Set ENABLE bit to turn SysTick on again. STCTRL
	
	
	;Set TICK priority field. SYSPRI3
	LDR r0, =SYS_PERIPH
	LDR r1, [r0,#SYSPRI3]
	ORR r1, r1, #(1<<29) ;priority 1. TICK begins at bit 29
	STR r1, [r0,#SYSPRI3]
	
	;Set ENABLE bit to turn SysTick on again. STCTRL
	LDR r0, =SYS_PERIPH
	LDR r1, [r0,#STCTRL]
	ORR r1, r1, #1 ;bit 0
	STR r1, [r0,#STCTRL]
	
	
	;Pop LR and return to __main
	POP {LR}
	BX LR
	
	ENDP
		
		
	
__main
	
	;call GPIO_Init subroutine and return
	BL GPIO_Init
	
	;call SysTick_Init subroutine and return
	BL SysTick_Init
	
stop 
	;Trash data to see if program is actually returning to main
	MOV r1, #0
	ADD r1, r1, #1
	B stop	;While(1)
	
	END