.PORT int_statusPORT,         0xE0 ; Sprzetowo ustawiane na 1 sprzetowo, ale nigdy nie usuwany wiec trzeba to wylaczyc po obsludze inta
.PORT int_maskPORT,          0xE1  ; odpowiada za to czy int wykona sie dla jakiegos peryferium
.PORT uart0_int_mask, 0x62
.PORT uart0_rx,            0x60
.PORT uart0_tx,            0x60
.PORT uart0_statusPORT,      0x61
.PORT uart0_int_maskPORT,  0x62
.CONST hashChar, 35
.CONST CrChar, 13
.CONST LfChar, 10
.CONST eChar, 69

.CONST boardWidth, 16
.CONST boardHeight, 16


.REG s9, uart0Status
.REG s2, uart0NotEmpty
.REG s3, uart0InterruptMASK

LOAD uart0NotEmpty, 0b00010000
LOAD uart0InterruptMASK, 0b00000100

OUT uart0NotEmpty, uart0_int_maskPORT
OUT uart0InterruptMASK, int_maskPORT

EINT

LOAD s0, 0
LOAD s1, 0

; ------------------start-------------------------
drawBoard:
	COMP s0, boardWidth
	JUMP Z, main


drawLine:
	LOAD sF, hashChar
checkUart:
	IN uart0Status, uart0_statusPORT
	TEST uart0Status, 0b00000100
	JUMP NZ, checkUart
	OUT sF, uart0_tx
	LOAD uart0Status, 0b00000000
	ADD s0, 1
	COMP s0, boardWidth
	JUMP C, drawBoard

LOAD s0, 0
ADD s1, 1

goToNextLine:
	IN uart0Status, uart0_statusPORT
	TEST uart0Status, 0b00000100
	JUMP NZ, goToNextLine
	LOAD sF, CrChar
	OUT sF, uart0_tx
checkUart2:
	IN uart0Status, uart0_statusPORT
	TEST uart0Status, 0b00000100
	JUMP NZ, checkUart2
	LOAD uart0Status, 0b00000000
	LOAD sF, LfChar
	OUT sF, uart0_tx
	LOAD uart0Status, 0b00000000

COMP s1, boardHeight
JUMP C, drawBoard




; ------------------end-------------------------

main:
JUMP main

.CONST opoznij_1u_const, 240

delay_1u:
LOAD sA, opoznij_1u_const

wait_1u:
SUB sA, 1
JUMP NZ, wait_1u
RET
delay_40u:
LOAD sB, 380

wait_40u:
CALL  delay_1u
SUB sB, 1
JUMP NZ, wait_40u
RET

delay_1m:
LOAD sC, 250

wait_1m:
CALL delay_40u
SUB sC, 1
JUMP NZ, wait_1m
RET


