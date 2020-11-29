;-------------------------------------------------------
; PicoBlaze Conway's Game Of Life on UART (TX) Interface
; © Michal Loska 29.11.2020
;-------------------------------------------------------

; port used to select currently active RAM page (x/8)
.PORT ramPagePORT, 0xF0
; currently selected RAM page
.REG s3, ramPage
; current row of the RAM page
.REG s4, rowIdx
; current RAM address
.REG s5, cellIdx
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
; Register containing the current amount of neighbors of a given cell
.REG s6, neighborCounter
; Register containing the current temporary column ID for neighbor counting
.REG s7, tempcellIdx
; Register containing the current value fetched from RAM from the address: tempcellIdx
.REG s8, tempcellIdxValue
; Register containing the number of the current simulation iteration
.REG sE, simulationIterator
.CONST amountOfSimulationIterations, 30

; ASCII consts:
.CONST aliveCell, 88  ; ASCII 'X'
.CONST deadCell, 95 ; ASCII '_'
.CONST CR_char, 13
.CONST LF_char, 10

; ------------------------------------------------
; ---------------FILLING RAM----------------------
; ------------------------------------------------

LOAD cellIdx, 0
LOAD ramPage, 0
OUT ramPage, ramPagePORT
LOAD s0, deadCell

FillFirstPageOfRam:
    STORE s0, cellIdx
    ADD cellIdx, 1
    COMP cellIdx, 0 ; in fact we compare against 256 which overflows to 0
    JUMP NZ, FillFirstPageOfRam

LOAD cellIdx, 0
LOAD ramPage, 1
OUT ramPage, ramPagePORT ; switching to the second page of RAM

FillSecondPageOfRam:
    STORE s0, cellIdx
    ADD cellIdx, 1
    COMP cellIdx, 0 ; in fact we compare against 256 which overflows to 0
    JUMP NZ, FillSecondPageOfRam

LOAD ramPage, 0
OUT ramPage, ramPagePORT ; switching to the first page of RAM

; Set the initial alive cells (in RAM memory blocks)
LOAD s0, aliveCell
STORE s0, 0
STORE s0, 16
STORE s0, 32

STORE s0, 223
STORE s0, 239
STORE s0, 255

STORE s0, 116
STORE s0, 117
STORE s0, 118
STORE s0, 119
STORE s0, 120
LOAD s0, deadCell
STORE s0, 121
LOAD s0, aliveCell

STORE s0, 122
STORE s0, 123
STORE s0, 124

; ------------------------------------------------
; ---------------MAIN LOOP------------------------
; ------------------------------------------------

ExecuteNextIteration:

; board iterators initialization
LOAD rowIdx, 0
LOAD cellIdx, 0
LOAD isAtTheEOL, 0

; Called for visual alignment in the simulator!
CALL CarriageReturn
CALL LineFeed

; s0 hold value 0
LOAD s0, 0
; initialize board with initial values
MainIterationLoop:
    FETCH s0, cellIdx
    CALL WriteToUart
    CALL CountNeighbors ; countNeighborsAndGenerate2ndIteration
    ADD cellIdx, 1
    ADD isAtTheEOL, 1
    COMP isAtTheEOL, 16
    CALL Z, MoveToNextLine
    COMP rowIdx, 16
    JUMP Z, Main
    JUMP MainIterationLoop

; ------------------------------------------------
; ---------------DISPLAYING RAM(UART)-------------
; ------------------------------------------------

MoveToNextLine:
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

WriteToUart:
    ; check if uart_tx full
    IN uart0Status, uart0_statusPORT
    TEST uart0Status, uart0_txFull
    JUMP NZ, WriteToUart
    ; end
    OUT s0, uart0_tx
    LOAD uart0Status, 0b00000000
    RET

Main:
    CALL Wait_07s
    LOAD cellIdx, 0

    ADD simulationIterator, 1
    COMP simulationIterator, amountOfSimulationIterations
    JUMP NZ, rewriteSecondRamPageToTheFirstPage
    JUMP END

; code execution ends here
END:
    JUMP END

rewriteSecondRamPageToTheFirstPage:
    ; switch to page 2
    LOAD ramPage, 1
    OUT ramPage, ramPagePORT

    FETCH s0, cellIdx

    ; switch to page 1
    LOAD ramPage, 0
    OUT ramPage, ramPagePORT

    STORE s0, cellIdx

    ADD cellIdx, 1
    COMP cellIdx, 0 ; should be 256 but was changed to 0 due to stack overflow
    JUMP NZ, rewriteSecondRamPageToTheFirstPage
    JUMP ExecuteNextIteration

; ------------------------------------------------
; ---------------NEIGHBOR COUNTING LOGIC----------
; ------------------------------------------------

;count neighbors of all cells in the first RAM page
;and save the result in the second RAM page
CountNeighbors:
    LOAD neighborCounter, 0
    LOAD tempcellIdx, 0
    LOAD tempcellIdxValue, 0 ; tempcellIdx value

CheckCorners:
    ; Left Top Corner
    COMP cellIdx, 0
    JUMP Z, LeftTopCorner

    ; Left Bottom Corner
    COMP cellIdx, 240
    JUMP Z, LeftBottomCorner

    ; Right Top Corner
    COMP cellIdx, 15
    JUMP Z, RightTopCorner

    ; Right Bottom Corner
    COMP cellIdx, 255
    JUMP Z, RightBottomCorner

CheckSides:
    ; Left EDGE
    COMP isAtTheEOL, 0
    JUMP Z, LeftEdgePositionCount

    ; Right EDGE
    COMP isAtTheEOL, 15
    JUMP Z, RightEdgePositionCount

    ; TOP/BOTTOM/MIDDLE of the board
    JUMP RegularPositionCount

LeftTopCorner:
    LOAD tempcellIdx, cellIdx
    ;move from the middle to the left
    LOAD tempcellIdx, 15
    CALL checkIfTempcellIdxIsAlive
    ;move up
    LOAD tempcellIdx, 255
    CALL checkIfTempcellIdxIsAlive
    ;move right
    LOAD tempcellIdx, 240
    CALL checkIfTempcellIdxIsAlive
    ;move right
    LOAD tempcellIdx, 241
    CALL checkIfTempcellIdxIsAlive
    ;move down
    LOAD tempcellIdx, 1
    CALL checkIfTempcellIdxIsAlive
    ;move down
    LOAD tempcellIdx, 17
    CALL checkIfTempcellIdxIsAlive
    ;move left
    LOAD tempcellIdx, 16
    CALL checkIfTempcellIdxIsAlive
    ;move left
    LOAD tempcellIdx, 31
    CALL checkIfTempcellIdxIsAlive
    JUMP EvaluateCellsLife

LeftBottomCorner:
    LOAD tempcellIdx, cellIdx
    ;move from the middle to the left
    LOAD tempcellIdx, 255
    CALL checkIfTempcellIdxIsAlive
    ;move up
    LOAD tempcellIdx, 239
    CALL checkIfTempcellIdxIsAlive
    ;move right
    LOAD tempcellIdx, 224
    CALL checkIfTempcellIdxIsAlive
    ;move right
    LOAD tempcellIdx, 225
    CALL checkIfTempcellIdxIsAlive
    ;move down
    LOAD tempcellIdx, 241
    CALL checkIfTempcellIdxIsAlive
    ;move down
    LOAD tempcellIdx, 1
    CALL checkIfTempcellIdxIsAlive
    ;move left
    LOAD tempcellIdx, 0
    CALL checkIfTempcellIdxIsAlive
    ;move left
    LOAD tempcellIdx, 15
    CALL checkIfTempcellIdxIsAlive
    JUMP EvaluateCellsLife

RightTopCorner:
    LOAD tempcellIdx, cellIdx
    ;move from the middle to the left
    LOAD tempcellIdx, 14
    CALL checkIfTempcellIdxIsAlive
    ;move up
    LOAD tempcellIdx, 254
    CALL checkIfTempcellIdxIsAlive
    ;move right
    LOAD tempcellIdx, 255
    CALL checkIfTempcellIdxIsAlive
    ;move right
    LOAD tempcellIdx, 240
    CALL checkIfTempcellIdxIsAlive
    ;move down
    LOAD tempcellIdx, 0
    CALL checkIfTempcellIdxIsAlive
    ;move down
    LOAD tempcellIdx, 16
    CALL checkIfTempcellIdxIsAlive
    ;move left
    LOAD tempcellIdx, 31
    CALL checkIfTempcellIdxIsAlive
    ;move left
    LOAD tempcellIdx, 30
    CALL checkIfTempcellIdxIsAlive
    JUMP EvaluateCellsLife

RightBottomCorner:
    LOAD tempcellIdx, cellIdx
    ;move from the middle to the left
    LOAD tempcellIdx, 254
    CALL checkIfTempcellIdxIsAlive
    ;move up
    LOAD tempcellIdx, 238
    CALL checkIfTempcellIdxIsAlive
    ;move right
    LOAD tempcellIdx, 239
    CALL checkIfTempcellIdxIsAlive
    ;move right
    LOAD tempcellIdx, 224
    CALL checkIfTempcellIdxIsAlive
    ;move down
    LOAD tempcellIdx, 240
    CALL checkIfTempcellIdxIsAlive
    ;move down
    LOAD tempcellIdx, 0
    CALL checkIfTempcellIdxIsAlive
    ;move left
    LOAD tempcellIdx, 15
    CALL checkIfTempcellIdxIsAlive
    ;move left
    LOAD tempcellIdx, 14
    CALL checkIfTempcellIdxIsAlive
    JUMP EvaluateCellsLife


;works for top and bottom edges and the middle of the board
RegularPositionCount:
    LOAD tempcellIdx, cellIdx
    ;move from the middle to the left
    SUB tempcellIdx, 1
    CALL checkIfTempcellIdxIsAlive
    ;move up
    SUB tempcellIdx, 16
    CALL checkIfTempcellIdxIsAlive
    ;move right
    ADD tempcellIdx, 1
    CALL checkIfTempcellIdxIsAlive
    ;move right
    ADD tempcellIdx, 1
    CALL checkIfTempcellIdxIsAlive
    ;move down
    ADD tempcellIdx, 16
    CALL checkIfTempcellIdxIsAlive
    ;move down
    ADD tempcellIdx, 16
    CALL checkIfTempcellIdxIsAlive
    ;move left
    SUB tempcellIdx, 1
    CALL checkIfTempcellIdxIsAlive
    ;move left
    SUB tempcellIdx, 1
    CALL checkIfTempcellIdxIsAlive
    JUMP EvaluateCellsLife

LeftEdgePositionCount:
    LOAD tempcellIdx, cellIdx
    ;move from the middle to the left
    ADD tempcellIdx, 15
    CALL checkIfTempcellIdxIsAlive
    ;move up
    SUB tempcellIdx, 16
    CALL checkIfTempcellIdxIsAlive
    ;move right
    SUB tempcellIdx, 15
    CALL checkIfTempcellIdxIsAlive
    ;move right
    ADD tempcellIdx, 1
    CALL checkIfTempcellIdxIsAlive
    ;move down
    ADD tempcellIdx, 16
    CALL checkIfTempcellIdxIsAlive
    ;move down
    ADD tempcellIdx, 16
    CALL checkIfTempcellIdxIsAlive
    ;move left
    SUB tempcellIdx, 1
    CALL checkIfTempcellIdxIsAlive
    ;move left
    ADD tempcellIdx, 15
    CALL checkIfTempcellIdxIsAlive
    JUMP EvaluateCellsLife

RightEdgePositionCount:
    LOAD tempcellIdx, cellIdx
    ;move from the middle to the left
    SUB tempcellIdx, 1
    CALL checkIfTempcellIdxIsAlive
    ;move up
    SUB tempcellIdx, 16
    CALL checkIfTempcellIdxIsAlive
    ;move right
    ADD tempcellIdx, 1
    CALL checkIfTempcellIdxIsAlive
    ;move right
    SUB tempcellIdx, 15
    CALL checkIfTempcellIdxIsAlive
    ;move down
    ADD tempcellIdx, 16
    CALL checkIfTempcellIdxIsAlive
    ;move down
    ADD tempcellIdx, 16
    CALL checkIfTempcellIdxIsAlive
    ;move left
    ADD tempcellIdx, 15
    CALL checkIfTempcellIdxIsAlive
    ;move left
    SUB tempcellIdx, 1
    CALL checkIfTempcellIdxIsAlive
    JUMP EvaluateCellsLife

checkIfTempcellIdxIsAlive:
    FETCH tempcellIdxValue, tempcellIdx
    COMP tempcellIdxValue, aliveCell
    JUMP NZ, goBack
    incrementAliveCounter:
        ADD neighborCounter, 1
    goBack:
        RET

EvaluateCellsLife:
    COMP s0, aliveCell
    JUMP Z, CurrentCellIsAlive
    CurrentCellIsDead:
        COMP neighborCounter, 3
        CALL Z, GiveBirthToCell
        RET

    CurrentCellIsAlive:
        COMP neighborCounter, 0
        JUMP Z, KillCell
        COMP neighborCounter, 1
        JUMP Z, KillCell
        ; 4 or more neighbors (4 >=)
        COMP neighborCounter, 4
        JUMP NC, KillCell

        JUMP CellSurvives

CellSurvives:
    ;switch to the second RAM page
    LOAD ramPage, 1
    OUT ramPage, ramPagePORT
    LOAD sA, aliveCell
    STORE sA, cellIdx
    ;switch back to the first RAM page
    LOAD ramPage, 0
    OUT ramPage, ramPagePORT
    RET

KillCell:
    ;switch to the second RAM page
    LOAD ramPage, 1
    OUT ramPage, ramPagePORT
    LOAD sA, deadCell
    STORE sA, cellIdx
    ;switch back to the first RAM page
    LOAD ramPage, 0
    OUT ramPage, ramPagePORT
    RET

GiveBirthToCell:
    ;switch to the second RAM page
    LOAD ramPage, 1
    OUT ramPage, ramPagePORT
    LOAD sA, aliveCell
    STORE sA, cellIdx
    ;switch back to the first RAM page
    LOAD ramPage, 0
    OUT ramPage, ramPagePORT
    RET

; ------------------------------------------------
; ---------------DELAY FUNCTIONS------------------
; ------------------------------------------------
For1:
    load s0, 255
    wait1:
       sub s0, 1
       jump nz, wait1
    RET

For2:
    load s2, 255
    wait2:
        call For1
        sub s2, 1
        jump nz, wait2
    RET

For3:
    load sD, 255
    wait3:
       call For2
       sub sD, 1
       jump nz, wait3
    RET

Wait_07s:
    call For3
RET

; ------------------------------------------------
; ---------------RAM INITIALIZATION---------------
; ------------------------------------------------

.DSEG 0
    .DS 256 ; Initialize 1 Page of RAM
.DSEG 1
    .DS 256 ; Initialize 2 Page of RAM
.CSEG
