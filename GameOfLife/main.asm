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
; Register containing the current amount of neighbors of a given cell
.REG s6, neighborCounter
; Register containing the current temporary column ID for neighbor counting
.REG s7, tempColumnIdx
; Register containing the current value fetched from RAM from the address: tempColumnIdx
.REG s8, tempColumnIdxValue

; ASCII consts:
.CONST deadCell, 88  ; ASCII '_'
.CONST aliveCell, 95 ; ASCII 'X'
.CONST CR_char, 13
.CONST LF_char, 10
; ------------------------------------------------
; ---------------FILLING RAM----------------------
; ------------------------------------------------

LOAD columnIdx, 0
LOAD ramPage, 0
OUT ramPage, ramPagePORT
LOAD s0, aliveCell

FillFirstPageOfRam:
    STORE s0, columnIdx
    ADD columnIdx, 1
    COMP columnIdx, 0 ; in fact we compare against 256 which overflows to 0
    JUMP NZ, FillFirstPageOfRam

LOAD columnIdx, 0
LOAD ramPage, 1
OUT ramPage, ramPagePORT ; switching to the second page of RAM

FillSecondPageOfRam:
    STORE s0, columnIdx
    ADD columnIdx, 1
    COMP columnIdx, 0 ; in fact we compare against 256 which overflows to 0
    JUMP NZ, FillSecondPageOfRam

LOAD ramPage, 0
OUT ramPage, ramPagePORT ; switching to the first page of RAM

; initialize the initial cells
LOAD s0, deadCell
STORE s0, 116
STORE s0, 117
STORE s0, 118
STORE s0, 119
STORE s0, 120
LOAD s0, aliveCell
STORE s0, 121
LOAD s0, deadCell

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
MainIterationLoop:
    FETCH s0, columnIdx
    CALL WriteToUart
    CALL CountNeighbors
    ADD columnIdx, 1
    ADD isAtTheEOL, 1
    COMP isAtTheEOL, 16
    CALL Z, MoveToNextLine
    COMP rowIdx, 16
    CALL Z, Main
    JUMP MainIterationLoop

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
    JUMP Main

; board iterators initialization
; LOAD rowIdx, 0
; LOAD columnIdx, 0
; LOAD isAtTheEOL, 0
; LOAD s0, 0


;count neighbors of all cells in the first RAM page
;and save the result in the second RAM page
CountNeighbors:
    LOAD neighborCounter, 0
    LOAD tempColumnIdx, 0
    LOAD tempColumnIdxValue, 0 ; tempColumnIdx value

CheckCorners:
    ; Left Top Corner
    COMP columnIdx, 0
    JUMP Z, LeftTopCorner

    ; Left Bottom Corner
    COMP columnIdx, 240
    JUMP Z, LeftBottomCorner

    ; Right Top Corner
    COMP columnIdx, 15
    JUMP Z, RightTopCorner

    ; Right Bottom Corner
    COMP columnIdx, 255
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
    LOAD tempColumnIdx, columnIdx
    ;move from the middle to the left
    LOAD tempColumnIdx, 15
    CALL checkIfTempColumnIdxIsAlive
    ;move up
    LOAD tempColumnIdx, 255
    CALL checkIfTempColumnIdxIsAlive
    ;move right
    LOAD tempColumnIdx, 240
    CALL checkIfTempColumnIdxIsAlive
    ;move right
    LOAD tempColumnIdx, 241
    CALL checkIfTempColumnIdxIsAlive
    ;move down
    LOAD tempColumnIdx, 1
    CALL checkIfTempColumnIdxIsAlive
    ;move down
    LOAD tempColumnIdx, 17
    CALL checkIfTempColumnIdxIsAlive
    ;move left
    LOAD tempColumnIdx, 16
    CALL checkIfTempColumnIdxIsAlive
    ;move left
    LOAD tempColumnIdx, 31
    CALL checkIfTempColumnIdxIsAlive
    JUMP EvaluateCellsLife

LeftBottomCorner:
    LOAD tempColumnIdx, columnIdx
    ;move from the middle to the left
    LOAD tempColumnIdx, 255
    CALL checkIfTempColumnIdxIsAlive
    ;move up
    LOAD tempColumnIdx, 239
    CALL checkIfTempColumnIdxIsAlive
    ;move right
    LOAD tempColumnIdx, 224
    CALL checkIfTempColumnIdxIsAlive
    ;move right
    LOAD tempColumnIdx, 225
    CALL checkIfTempColumnIdxIsAlive
    ;move down
    LOAD tempColumnIdx, 241
    CALL checkIfTempColumnIdxIsAlive
    ;move down
    LOAD tempColumnIdx, 1
    CALL checkIfTempColumnIdxIsAlive
    ;move left
    LOAD tempColumnIdx, 0
    CALL checkIfTempColumnIdxIsAlive
    ;move left
    LOAD tempColumnIdx, 15
    CALL checkIfTempColumnIdxIsAlive
    JUMP EvaluateCellsLife

RightTopCorner:
    LOAD tempColumnIdx, columnIdx
    ;move from the middle to the left
    LOAD tempColumnIdx, 14
    CALL checkIfTempColumnIdxIsAlive
    ;move up
    LOAD tempColumnIdx, 254
    CALL checkIfTempColumnIdxIsAlive
    ;move right
    LOAD tempColumnIdx, 255
    CALL checkIfTempColumnIdxIsAlive
    ;move right
    LOAD tempColumnIdx, 240
    CALL checkIfTempColumnIdxIsAlive
    ;move down
    LOAD tempColumnIdx, 0
    CALL checkIfTempColumnIdxIsAlive
    ;move down
    LOAD tempColumnIdx, 16
    CALL checkIfTempColumnIdxIsAlive
    ;move left
    LOAD tempColumnIdx, 31
    CALL checkIfTempColumnIdxIsAlive
    ;move left
    LOAD tempColumnIdx, 30
    CALL checkIfTempColumnIdxIsAlive
    JUMP EvaluateCellsLife

RightBottomCorner:
    LOAD tempColumnIdx, columnIdx
    ;move from the middle to the left
    LOAD tempColumnIdx, 254
    CALL checkIfTempColumnIdxIsAlive
    ;move up
    LOAD tempColumnIdx, 238
    CALL checkIfTempColumnIdxIsAlive
    ;move right
    LOAD tempColumnIdx, 239
    CALL checkIfTempColumnIdxIsAlive
    ;move right
    LOAD tempColumnIdx, 224
    CALL checkIfTempColumnIdxIsAlive
    ;move down
    LOAD tempColumnIdx, 240
    CALL checkIfTempColumnIdxIsAlive
    ;move down
    LOAD tempColumnIdx, 0
    CALL checkIfTempColumnIdxIsAlive
    ;move left
    LOAD tempColumnIdx, 15
    CALL checkIfTempColumnIdxIsAlive
    ;move left
    LOAD tempColumnIdx, 14
    CALL checkIfTempColumnIdxIsAlive
    JUMP EvaluateCellsLife


;works for top and bottom edges and the middle of the board
RegularPositionCount:
    LOAD tempColumnIdx, columnIdx
    ;move from the middle to the left
    SUB tempColumnIdx, 1
    CALL checkIfTempColumnIdxIsAlive
    ;move up
    SUB tempColumnIdx, 16
    CALL checkIfTempColumnIdxIsAlive
    ;move right
    ADD tempColumnIdx, 1
    CALL checkIfTempColumnIdxIsAlive
    ;move right
    ADD tempColumnIdx, 1
    CALL checkIfTempColumnIdxIsAlive
    ;move down
    ADD tempColumnIdx, 16
    CALL checkIfTempColumnIdxIsAlive
    ;move down
    ADD tempColumnIdx, 16
    CALL checkIfTempColumnIdxIsAlive
    ;move left
    SUB tempColumnIdx, 1
    CALL checkIfTempColumnIdxIsAlive
    ;move left
    SUB tempColumnIdx, 1
    CALL checkIfTempColumnIdxIsAlive
    JUMP EvaluateCellsLife

LeftEdgePositionCount:
    LOAD tempColumnIdx, columnIdx
    ;move from the middle to the left
    ADD tempColumnIdx, 15
    CALL checkIfTempColumnIdxIsAlive
    ;move up
    SUB tempColumnIdx, 16
    CALL checkIfTempColumnIdxIsAlive
    ;move right
    SUB tempColumnIdx, 15
    CALL checkIfTempColumnIdxIsAlive
    ;move right
    ADD tempColumnIdx, 1
    CALL checkIfTempColumnIdxIsAlive
    ;move down
    ADD tempColumnIdx, 16
    CALL checkIfTempColumnIdxIsAlive
    ;move down
    ADD tempColumnIdx, 16
    CALL checkIfTempColumnIdxIsAlive
    ;move left
    SUB tempColumnIdx, 1
    CALL checkIfTempColumnIdxIsAlive
    ;move left
    ADD tempColumnIdx, 15
    CALL checkIfTempColumnIdxIsAlive
    JUMP EvaluateCellsLife

RightEdgePositionCount:
    LOAD tempColumnIdx, columnIdx
    ;move from the middle to the left
    SUB tempColumnIdx, 1
    CALL checkIfTempColumnIdxIsAlive
    ;move up
    SUB tempColumnIdx, 16
    CALL checkIfTempColumnIdxIsAlive
    ;move right
    ADD tempColumnIdx, 1
    CALL checkIfTempColumnIdxIsAlive
    ;move right
    SUB tempColumnIdx, 15
    CALL checkIfTempColumnIdxIsAlive
    ;move down
    ADD tempColumnIdx, 16
    CALL checkIfTempColumnIdxIsAlive
    ;move down
    ADD tempColumnIdx, 16
    CALL checkIfTempColumnIdxIsAlive
    ;move left
    ADD tempColumnIdx, 15
    CALL checkIfTempColumnIdxIsAlive
    ;move left
    SUB tempColumnIdx, 1
    CALL checkIfTempColumnIdxIsAlive
    JUMP EvaluateCellsLife

checkIfTempColumnIdxIsAlive:
    FETCH tempColumnIdxValue, tempColumnIdx
    COMP tempColumnIdxValue, aliveCell
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

        JUMP CellSurvives

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
RET
;TBA

KillCell:
    ;switch to the second RAM page
    LOAD ramPage, 1
    OUT ramPage, ramPagePORT
    LOAD sA, deadCell
    STORE sA, columnIdx
    ;switch back to the first RAM page
    LOAD ramPage, 0
    OUT ramPage, ramPagePORT
    RET

GiveBirthToCell:
    ;switch to the second RAM page
    LOAD ramPage, 1
    OUT ramPage, ramPagePORT
    LOAD sA, aliveCell
    STORE sA, columnIdx
    ;switch back to the first RAM page
    LOAD ramPage, 0
    OUT ramPage, ramPagePORT
    RET

ADD columnIdx, 1
ADD isAtTheEOL, 1

; ------------------------------------------------
; ---------------RAM INITIALIZATION---------------
; ------------------------------------------------

.DSEG 0
    .DS 256 ; Initialize 1 Page of RAM
.DSEG 1
    .DS 256 ; Initialize 2 Page of RAM
.CSEG
