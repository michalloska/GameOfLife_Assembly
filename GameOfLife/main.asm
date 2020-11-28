; port used to select currently active RAM page (x/8)
.PORT ramPagePORT, 0xF0
; currently selected RAM page
.REG s3, ramPage
; current row of the RAM page
.REG s4, row
; current RAM address
.REG s5, column
; indicates whether the carrot is at the EOL
.REG s1, isAtTheEOL
; UART transmission port used to output data to the protocol
.PORT uart0_tx, 0x60
; UART port returning current status of the UART protocol (FULL/NOT FULL)
.PORT uart0_statusPORT, 0x61
; Register containing current status of the UART protocol (FULL/NOT FULL)
.REG s9, uart0Status

.CONST CrChar, 13
.CONST LfChar, 10


; initialize the initial cells
LOAD s0, 1
STORE s0, 116
STORE s0, 117
STORE s0, 118
STORE s0, 119
STORE s0, 120

STORE s0, 122
STORE s0, 123
STORE s0, 124


; board iterators initialization
LOAD row, 1
LOAD column, 0
LOAD isAtTheEOL, 0

; s0 hold value 0
LOAD s0, 0
; initialize board with initial values
writeCell:
    FETCH s0, column
    CALL writeToUart
    ADD column, 1
    ADD isAtTheEOL, 1
    COMP isAtTheEOL, 16
    CALL Z, moveToNextLine
    COMP row, 15
    CALL Z, main
    JUMP writeCell

; OUT ramPage, ramPagePORT

moveToNextLine:
    CALL moveCarrotToNextLine
    CALL checkUart2
    LOAD isAtTheEOL, 0
    ADD row, 1
    RET

moveCarrotToNextLine:
    ; check if uart_tx full
    IN uart0Status, uart0_statusPORT
    TEST uart0Status, 0b00000100
    JUMP NZ, moveCarrotToNextLine
    ; end
    LOAD sF, CrChar ; 13 in ASCII is the Carriage Return
    OUT sF, uart0_tx
		RET

checkUart2:
    ; check if uart_tx full
    IN uart0Status, uart0_statusPORT
    TEST uart0Status, 0b00000100
    JUMP NZ, checkUart2
    ; end
    LOAD sF, LfChar ; 10 in ASCII is the Line Feed
    LOAD uart0Status, 0b00000000
    OUT sF, uart0_tx
    LOAD uart0Status, 0b00000000
    RET

writeToUart:
    ; check if uart_tx full
    IN uart0Status, uart0_statusPORT
    TEST uart0Status, 0b00000100
    JUMP NZ, writeToUart
    ; end
    OUT s0, uart0_tx
    LOAD uart0Status, 0b00000000
    RET

main:
JUMP main





; ------------------------------------------------
; ---------------DELAY FUNCTIONS------------------
; ------------------------------------------------


; ------------------------------------------------
; ---------------RAM INITIALIZATION---------------
; ------------------------------------------------

; FIRST RAM PAGE:
.DSEG 0
initialBoardPattern:
; 1 row ------------
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
; 2 row ------------
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
; 3 row ------------
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
; 4 row ------------
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
; 5 row ------------
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
; 6 row ------------
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
; 7 row ------------
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ONE
    .DS 1 ; ONE
    .DS 1 ; ONE
    .DS 1 ; ONE
    .DS 1 ; ONE
    .DS 1 ; ZERO
    .DS 1 ; ONE
    .DS 1 ; ONE
    .DS 1 ; ONE
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
; 8 row ------------
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
; 9 row ------------
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
;1 0 row ------------
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
;1 1 row ------------
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
;1 2 row ------------
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
;1 3 row ------------
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
;1 4 row ------------
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
;1 5 row ------------
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
;1 6 row ------------
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
; SECOND RAM PAGE:
.DSEG 1
; 1 row ------------
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
; 2 row ------------
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
; 3 row ------------
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
; 4 row ------------
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
; 5 row ------------
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
; 6 row ------------
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
; 7 row ------------
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ONE
    .DS 1 ; ONE
    .DS 1 ; ONE
    .DS 1 ; ONE
    .DS 1 ; ONE
    .DS 1 ; ZERO
    .DS 1 ; ONE
    .DS 1 ; ONE
    .DS 1 ; ONE
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
; 8 row ------------
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
; 9 row ------------
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
;1 0 row ------------
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
;1 1 row ------------
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
;1 2 row ------------
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
;1 3 row ------------
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
;1 4 row ------------
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
;1 5 row ------------
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
;1 6 row ------------
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
    .DS 1 ; ZERO
.CSEG
RET