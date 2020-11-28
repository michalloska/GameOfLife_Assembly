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
LOAD s0, 88 ; 88 is an ASCII repr. of 'X'
STORE s0, 116
STORE s0, 117
STORE s0, 118
STORE s0, 119
STORE s0, 120
LOAD s0, 79 ; 79 is an ASCII repr. of 'O'
STORE s0, 121
LOAD s0, 88

STORE s0, 122
STORE s0, 123
STORE s0, 124


; board iterators initialization
LOAD row, 1
LOAD column, 0
LOAD isAtTheEOL, 0

; Called for visual alignment in the simulator!
CALL CarriageReturn
CALL LineFeed

; s0 hold value 0
LOAD s0, 0
; initialize board with initial values
displayBoard:
    FETCH s0, column
    CALL writeToUart
    ADD column, 1
    ADD isAtTheEOL, 1
    COMP isAtTheEOL, 16
    CALL Z, moveToNextLine
    COMP row, 16
    CALL Z, main
    JUMP displayBoard

; OUT ramPage, ramPagePORT

moveToNextLine:
    CALL CarriageReturn
    CALL LineFeed
    LOAD isAtTheEOL, 0
    ADD row, 1
    RET

CarriageReturn:
    ; check if uart_tx full
    IN uart0Status, uart0_statusPORT
    TEST uart0Status, 0b00000100
    JUMP NZ, CarriageReturn
    ; end
    LOAD sF, CrChar ; 13 in ASCII is the Carriage Return
    OUT sF, uart0_tx
    RET

LineFeed:
    ; check if uart_tx full
    IN uart0Status, uart0_statusPORT
    TEST uart0Status, 0b00000100
    JUMP NZ, LineFeed
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

.DSEG 0
    .DS 256 ; Initialize 1 Page of RAM
.DSEG 1
    .DS 256 ; Initialize 2 Page of RAM
.CSEG