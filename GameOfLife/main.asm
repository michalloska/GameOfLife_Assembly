; port used to select currently active RAM page (x/8)
.PORT ramPagePORT, 0xF0
; currently selected RAM page
.REG s3, ramPage
; current row of the RAM page
.REG s4, rowIdx
; current RAM address
.REG s5, columnIdx
; indicates whether the carrot is at the EOL
.REG s1, isAtTheEOL
; UART transmission port used to output data to the protocol
.PORT uart0_tx, 0x60
; UART port returning current status of the UART protocol (FULL/NOT FULL)
.PORT uart0_statusPORT, 0x61
; Register containing current status of the UART protocol (FULL/NOT FULL)
.REG s9, uart0Status
; value corresponding to the mask of uart0_statusPORT when TX queue is full
.CONST uart0_txFull, 0b00000100

; ASCII consts:
.CONST uderscoreChar, 88
.CONST xChar, 95
.CONST CR_char, 13
.CONST LF_char, 10
; ------------------------------------------------
; ---------------FILLING RAM----------------------
; ------------------------------------------------

LOAD columnIdx, 0
LOAD ramPage, 0
OUT ramPage, ramPagePORT
LOAD s0, xChar

fillFirstPageOfRam:
    STORE s0, columnIdx
    ADD columnIdx, 1
    COMP columnIdx, 0 ; in fact we compare against 256 which overflows to 0
    JUMP NZ, fillFirstPageOfRam

LOAD columnIdx, 0
LOAD ramPage, 1
OUT ramPage, ramPagePORT ; switching to the second page of RAM

fillSecondPageOfRam:
    STORE s0, columnIdx
    ADD columnIdx, 1
    COMP columnIdx, 0 ; in fact we compare against 256 which overflows to 0
    JUMP NZ, fillSecondPageOfRam

LOAD ramPage, 0
OUT ramPage, ramPagePORT ; switching to the first page of RAM

; initialize the initial cells
LOAD s0, uderscoreChar
STORE s0, 116
STORE s0, 117
STORE s0, 118
STORE s0, 119
STORE s0, 120
LOAD s0, xChar
STORE s0, 121
LOAD s0, uderscoreChar

STORE s0, 122
STORE s0, 123
STORE s0, 124

; ------------------------------------------------
; ---------------DISPLAYING RAM-------------------
; ------------------------------------------------

; board iterators initialization
LOAD rowIdx, 0
LOAD columnIdx, 0
LOAD isAtTheEOL, 0

; Called for visual alignment in the simulator!
CALL CarriageReturn
CALL LineFeed

; s0 hold value 0
LOAD s0, 0
; initialize board with initial values
displayBoard:
    FETCH s0, columnIdx
    CALL writeToUart
    ADD columnIdx, 1
    ADD isAtTheEOL, 1
    COMP isAtTheEOL, 16
    CALL Z, moveToNextLine
    COMP rowIdx, 17
    CALL Z, main
    JUMP displayBoard

moveToNextLine:
    CALL CarriageReturn
    CALL LineFeed
    LOAD isAtTheEOL, 0
    ADD rowIdx, 1
    RET

CarriageReturn:
    ; check if uart_tx full
    IN uart0Status, uart0_statusPORT
    TEST uart0Status, uart0_txFull
    JUMP NZ, CarriageReturn
    ; end
    LOAD sF, CR_char ; 13 in ASCII is the Carriage Return
    OUT sF, uart0_tx
    RET

LineFeed:
    ; check if uart_tx full
    IN uart0Status, uart0_statusPORT
    TEST uart0Status, uart0_txFull
    JUMP NZ, LineFeed
    ; end
    LOAD sF, LF_char ; 10 in ASCII is the Line Feed
    LOAD uart0Status, 0b00000000
    OUT sF, uart0_tx
    LOAD uart0Status, 0b00000000
    RET

writeToUart:
    ; check if uart_tx full
    IN uart0Status, uart0_statusPORT
    TEST uart0Status, uart0_txFull
    JUMP NZ, writeToUart
    ; end
    OUT s0, uart0_tx
    LOAD uart0Status, 0b00000000
    RET

main:
JUMP main


; ------------------------------------------------
; ---------------RAM INITIALIZATION---------------
; ------------------------------------------------

.DSEG 0
    .DS 256 ; Initialize 1 Page of RAM
.DSEG 1
    .DS 256 ; Initialize 2 Page of RAM
.CSEG
