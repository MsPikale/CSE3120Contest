; SinkingSubmarine.asm - console game (Irvine32)
INCLUDE Irvine32.inc

FIELD_W     = 60
FIELD_H     = 20
FIELD_TOP   = 2
SUB_X       = 12
SUB_HALF    = 1
ROCK_CHAR   = '%'
ROCK_W      = 3
GAP_H       = 6
NUM_ROCKS   = 3
ROCK_SPACING = 25
SCALE_SHIFT = 2             ; subY is in 1/4 rows
START_Y     = (FIELD_H / 2) * 4
GRAVITY     = 1
FLAP_VEL    = -5
MAX_FALL    = 4
FRAME_MS    = 50
KEY_ESC     = 27
KEY_SPACE   = 32

.data
subY        SDWORD ?
subVel      SDWORD ?
quitFlag    DWORD 0
alive       DWORD ?
score       DWORD ?
bestScore   DWORD 0
rockX       SDWORD NUM_ROCKS DUP(?)
gapTop      SDWORD NUM_ROCKS DUP(?)

rowBuf      BYTE '|', FIELD_W DUP(' '), '|', 0
borderLine  BYTE '+', FIELD_W DUP('-'), '+', 0
subSprite   BYTE "<O>", 0
scoreMsg    BYTE "Score: ", 0
bestMsg     BYTE "   Best: ", 0
titleMsg    BYTE "S I N K I N G   S U B M A R I N E", 0
startMsg    BYTE "Press SPACE to start, ESC to quit", 0
overMsg     BYTE "G A M E   O V E R", 0
againMsg    BYTE "R = play again     ESC = quit", 0
helpMsg     BYTE "SPACE / W = flap     ESC = quit", 0

.code
main PROC
    call Randomize
    call ShowTitle
    cmp  quitFlag, 1
    je   Quit

NewGame:
    call Clrscr
    call ResetGame

GameLoop:
    call HandleInput
    cmp  quitFlag, 1
    je   Quit
    call UpdateSub
    call UpdateRocks
    call CheckCollision
    call DrawFrame
    cmp  alive, 0
    je   GameOver
    mov  eax, FRAME_MS
    call Delay
    jmp  GameLoop

GameOver:
    call ShowGameOver
    cmp  quitFlag, 1
    jne  NewGame

Quit:
    call Clrscr
    exit
main ENDP

ResetGame PROC USES eax ebx esi
    mov  subY, START_Y
    mov  subVel, 0
    mov  score, 0
    mov  alive, 1

    mov  esi, 0
    mov  ebx, FIELD_W
RockLoop:
    mov  rockX[esi], ebx
    call RandomGap
    mov  gapTop[esi], eax
    add  ebx, ROCK_SPACING
    add  esi, TYPE rockX
    cmp  esi, SIZEOF rockX
    jl   RockLoop
    ret
ResetGame ENDP

RandomGap PROC
    mov  eax, FIELD_H - GAP_H - 1
    call RandomRange
    inc  eax
    ret
RandomGap ENDP

UpdateRocks PROC USES eax esi
    mov  esi, 0
RockLoop:
    dec  rockX[esi]
    cmp  rockX[esi], SUB_X - SUB_HALF - ROCK_W
    jne  CheckEdge
    inc  score
CheckEdge:
    cmp  rockX[esi], -ROCK_W
    jg   NextRock
    add  rockX[esi], NUM_ROCKS * ROCK_SPACING
    call RandomGap
    mov  gapTop[esi], eax
NextRock:
    add  esi, TYPE rockX
    cmp  esi, SIZEOF rockX
    jl   RockLoop
    ret
UpdateRocks ENDP

HandleInput PROC USES eax ebx edx
    call ReadKey            ; ZF = 1 when no key
    jz   Done
    .IF al == KEY_SPACE
        mov  subVel, FLAP_VEL
    .ELSEIF al == 'w'
        mov  subVel, FLAP_VEL
    .ELSEIF al == 'W'
        mov  subVel, FLAP_VEL
    .ELSEIF al == KEY_ESC
        mov  quitFlag, 1
    .ENDIF
Done:
    ret
HandleInput ENDP

UpdateSub PROC USES eax
    mov  eax, subVel
    add  eax, GRAVITY
    cmp  eax, MAX_FALL
    jle  SpeedOk
    mov  eax, MAX_FALL
SpeedOk:
    mov  subVel, eax
    add  subY, eax
    cmp  subY, 0
    jge  Done
    mov  subY, 0
    mov  subVel, 0
Done:
    ret
UpdateSub ENDP

CheckCollision PROC USES eax ebx esi
    call GetSubRow
    cmp  eax, FIELD_H
    jge  Dead
    mov  ebx, eax

    mov  esi, 0
RockLoop:
    mov  eax, rockX[esi]
    cmp  eax, SUB_X + SUB_HALF
    jg   NextRock
    add  eax, ROCK_W
    cmp  eax, SUB_X - SUB_HALF
    jle  NextRock
    mov  eax, gapTop[esi]
    cmp  ebx, eax
    jl   Dead
    add  eax, GAP_H
    cmp  ebx, eax
    jge  Dead
NextRock:
    add  esi, TYPE rockX
    cmp  esi, SIZEOF rockX
    jl   RockLoop
    ret
Dead:
    mov  alive, 0
    ret
CheckCollision ENDP

GetSubRow PROC
    mov  eax, subY
    sar  eax, SCALE_SHIFT
    ret
GetSubRow ENDP

DrawFrame PROC USES eax ebx ecx edx esi edi
    mov  eax, white + (black * 16)
    call SetTextColor
    mov  dh, 0
    mov  dl, 0
    call Gotoxy
    mov  edx, OFFSET scoreMsg
    call WriteString
    mov  eax, score
    call WriteDec
    mov  edx, OFFSET bestMsg
    call WriteString
    mov  eax, bestScore
    call WriteDec

    mov  dh, FIELD_TOP - 1
    mov  dl, 0
    call Gotoxy
    mov  edx, OFFSET borderLine
    call WriteString

    mov  eax, lightGreen + (black * 16)
    call SetTextColor
    mov  ecx, 0
RowLoop:
    mov  edi, OFFSET rowBuf + 1
    push ecx
    mov  ecx, FIELD_W
    mov  al, ' '
    cld
    rep  stosb
    pop  ecx

    mov  esi, 0
RockLoop:
    mov  eax, gapTop[esi]
    cmp  ecx, eax
    jl   Solid
    add  eax, GAP_H
    cmp  ecx, eax
    jl   NextRock
Solid:
    mov  ebx, rockX[esi]
    inc  ebx
    mov  edx, 0
ColLoop:
    cmp  ebx, 1
    jl   NextCol
    cmp  ebx, FIELD_W
    jg   NextCol
    mov  rowBuf[ebx], ROCK_CHAR
NextCol:
    inc  ebx
    inc  edx
    cmp  edx, ROCK_W
    jl   ColLoop
NextRock:
    add  esi, TYPE rockX
    cmp  esi, SIZEOF rockX
    jl   RockLoop

    mov  dh, cl
    add  dh, FIELD_TOP
    mov  dl, 0
    call Gotoxy
    mov  edx, OFFSET rowBuf
    call WriteString

    inc  ecx
    cmp  ecx, FIELD_H
    jl   RowLoop
    mov  eax, white + (black * 16)
    call SetTextColor

    mov  dh, FIELD_TOP + FIELD_H
    mov  dl, 0
    call Gotoxy
    mov  edx, OFFSET borderLine
    call WriteString

    mov  dh, FIELD_TOP + FIELD_H + 1
    mov  dl, 0
    call Gotoxy
    mov  edx, OFFSET helpMsg
    call WriteString

    call GetSubRow
    .IF eax < FIELD_H
        mov  dh, al
        add  dh, FIELD_TOP
        mov  dl, SUB_X
        call Gotoxy
        mov  eax, yellow + (black * 16)
        call SetTextColor
        mov  edx, OFFSET subSprite
        call WriteString
        mov  eax, white + (black * 16)
        call SetTextColor
    .ENDIF

    mov  dh, FIELD_TOP + FIELD_H + 2
    mov  dl, 0
    call Gotoxy
    ret
DrawFrame ENDP

WaitKey PROC USES ebx edx
Wait1:
    mov  eax, 10
    call Delay
    call ReadKey
    jz   Wait1
    ret
WaitKey ENDP

ShowTitle PROC USES eax edx
    call Clrscr
    mov  dh, FIELD_TOP + 7
    mov  dl, 14
    call Gotoxy
    mov  edx, OFFSET titleMsg
    mov  eax, yellow + (black * 16)
    call SetTextColor
    call WriteString
    mov  eax, white + (black * 16)
    call SetTextColor
    mov  dh, FIELD_TOP + 10
    mov  dl, 14
    call Gotoxy
    mov  edx, OFFSET startMsg
    call WriteString
    mov  dh, FIELD_TOP + 12
    mov  dl, 15
    call Gotoxy
    mov  edx, OFFSET helpMsg
    call WriteString

KeyLoop:
    call WaitKey
    .IF al == KEY_SPACE
        ret
    .ELSEIF al == KEY_ESC
        mov  quitFlag, 1
        ret
    .ENDIF
    jmp  KeyLoop
ShowTitle ENDP

ShowGameOver PROC USES eax edx
    mov  eax, score
    .IF eax > bestScore
        mov  bestScore, eax
    .ENDIF

    mov  dh, FIELD_TOP + 7
    mov  dl, 22
    call Gotoxy
    mov  edx, OFFSET overMsg
    mov  eax, yellow + (black * 16)
    call SetTextColor
    call WriteString
    mov  eax, white + (black * 16)
    call SetTextColor
    mov  dh, FIELD_TOP + 9
    mov  dl, 22
    call Gotoxy
    mov  edx, OFFSET scoreMsg
    call WriteString
    mov  eax, score
    call WriteDec
    mov  edx, OFFSET bestMsg
    call WriteString
    mov  eax, bestScore
    call WriteDec
    mov  dh, FIELD_TOP + 11
    mov  dl, 16
    call Gotoxy
    mov  edx, OFFSET againMsg
    call WriteString

    mov  eax, 600           ; ignore a held SPACE
    call Delay

KeyLoop:
    call WaitKey
    .IF al == 'r'
        ret
    .ELSEIF al == 'R'
        ret
    .ELSEIF al == KEY_ESC
        mov  quitFlag, 1
        ret
    .ENDIF
    jmp  KeyLoop
ShowGameOver ENDP

END main
