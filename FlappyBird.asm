; FlappyBird.asm - a Flappy Bird style game for the console
; Uses the Irvine32 library.

INCLUDE Irvine32.inc

;------------------------- game constants -------------------------
FIELD_W     = 60            ; playfield width in columns
FIELD_H     = 20            ; playfield height in rows
FIELD_TOP   = 2             ; screen row of the first playfield row
BIRD_X      = 12            ; column the bird stays in
BIRD_CHAR   = '@'
PIPE_CHAR   = '#'
PIPE_W      = 3             ; pipe thickness in columns
GAP_H       = 6             ; height of the opening in each pipe
NUM_PIPES   = 3
PIPE_SPACING = 25           ; columns between pipes
SCALE_SHIFT = 2             ; bird Y is stored in 1/4 row units (shift by 2)
START_Y     = (FIELD_H / 2) * 4
GRAVITY     = 1             ; added to velocity every frame
FLAP_VEL    = -5            ; velocity after a flap
MAX_FALL    = 4             ; fastest falling speed
FRAME_MS    = 50            ; delay between frames
KEY_ESC     = 27
KEY_SPACE   = 32

.data
birdY       SDWORD ?        ; bird height (1/4 rows, 0 = top)
birdVel     SDWORD ?        ; bird speed (1/4 rows per frame, negative = up)
quitFlag    DWORD 0
alive       DWORD ?         ; 1 while the bird is still flying
score       DWORD ?
bestScore   DWORD 0
pipeX       SDWORD NUM_PIPES DUP(?)     ; left column of each pipe
gapTop      SDWORD NUM_PIPES DUP(?)     ; first open row of each pipe

rowBuf      BYTE '|', FIELD_W DUP(' '), '|', 0
borderLine  BYTE '+', FIELD_W DUP('-'), '+', 0
scoreMsg    BYTE "Score: ", 0
bestMsg     BYTE "   Best: ", 0
titleMsg    BYTE "F L A P P Y   B I R D", 0
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
    call UpdateBird
    call UpdatePipes
    call CheckCollision
    call DrawFrame
    cmp  alive, 0
    je   GameOver
    mov  eax, FRAME_MS
    call Delay
    jmp  GameLoop

GameOver:
    call ShowGameOver       ; sets quitFlag when the player picks ESC
    cmp  quitFlag, 1
    jne  NewGame

Quit:
    call Clrscr
    exit
main ENDP

;------------------------------------------------------------------
ResetGame PROC USES eax ebx esi
; Puts the bird back in the middle and lines the pipes up
; off the right side of the screen.
; Receives: nothing   Returns: nothing
;------------------------------------------------------------------
    mov  birdY, START_Y
    mov  birdVel, 0
    mov  score, 0
    mov  alive, 1

    mov  esi, 0
    mov  ebx, FIELD_W       ; first pipe starts at the right edge
PipeLoop:
    mov  pipeX[esi], ebx
    call RandomGap
    mov  gapTop[esi], eax
    add  ebx, PIPE_SPACING
    add  esi, TYPE pipeX
    cmp  esi, SIZEOF pipeX
    jl   PipeLoop
    ret
ResetGame ENDP

;------------------------------------------------------------------
RandomGap PROC
; Returns: EAX = random gap top row, 1 .. FIELD_H - GAP_H - 1
;------------------------------------------------------------------
    mov  eax, FIELD_H - GAP_H - 1
    call RandomRange        ; 0 .. FIELD_H - GAP_H - 2
    inc  eax
    ret
RandomGap ENDP

;------------------------------------------------------------------
UpdatePipes PROC USES eax esi
; Moves every pipe one column left and scores each pipe the bird
; gets past. A pipe that leaves the screen jumps back behind the
; last pipe with a new random gap.
; Receives: nothing   Returns: nothing
;------------------------------------------------------------------
    mov  esi, 0
PipeLoop:
    dec  pipeX[esi]
    cmp  pipeX[esi], BIRD_X - PIPE_W    ; right edge just passed the bird?
    jne  CheckEdge
    inc  score
CheckEdge:
    cmp  pipeX[esi], -PIPE_W        ; completely off the left edge?
    jg   NextPipe
    add  pipeX[esi], NUM_PIPES * PIPE_SPACING
    call RandomGap
    mov  gapTop[esi], eax
NextPipe:
    add  esi, TYPE pipeX
    cmp  esi, SIZEOF pipeX
    jl   PipeLoop
    ret
UpdatePipes ENDP

;------------------------------------------------------------------
HandleInput PROC USES eax ebx edx
; Reads one key without waiting. SPACE/W flaps, ESC quits.
; Receives: nothing   Returns: nothing
;------------------------------------------------------------------
    call ReadKey            ; ZF = 1 when no key is waiting
    jz   Done
    .IF al == KEY_SPACE
        mov  birdVel, FLAP_VEL
    .ELSEIF al == 'w'
        mov  birdVel, FLAP_VEL
    .ELSEIF al == 'W'
        mov  birdVel, FLAP_VEL
    .ELSEIF al == KEY_ESC
        mov  quitFlag, 1
    .ENDIF
Done:
    ret
HandleInput ENDP

;------------------------------------------------------------------
UpdateBird PROC USES eax
; Applies gravity, moves the bird, and stops it at the ceiling.
; Receives: nothing   Returns: nothing
;------------------------------------------------------------------
    mov  eax, birdVel
    add  eax, GRAVITY
    cmp  eax, MAX_FALL
    jle  SpeedOk
    mov  eax, MAX_FALL
SpeedOk:
    mov  birdVel, eax
    add  birdY, eax
    cmp  birdY, 0           ; above the top? hold it at the ceiling
    jge  Done
    mov  birdY, 0
    mov  birdVel, 0
Done:
    ret
UpdateBird ENDP

;------------------------------------------------------------------
CheckCollision PROC USES eax ebx esi
; Sets alive = 0 if the bird hit the ground or a pipe.
; Receives: nothing   Returns: nothing
;------------------------------------------------------------------
    call GetBirdRow
    cmp  eax, FIELD_H
    jge  Dead               ; hit the ground
    mov  ebx, eax           ; ebx = bird row

    mov  esi, 0
PipeLoop:
    mov  eax, pipeX[esi]
    cmp  eax, BIRD_X
    jg   NextPipe           ; pipe is still to the right of the bird
    add  eax, PIPE_W
    cmp  eax, BIRD_X
    jle  NextPipe           ; pipe is already to the left of the bird
    mov  eax, gapTop[esi]
    cmp  ebx, eax
    jl   Dead               ; above the gap
    add  eax, GAP_H
    cmp  ebx, eax
    jge  Dead               ; below the gap
NextPipe:
    add  esi, TYPE pipeX
    cmp  esi, SIZEOF pipeX
    jl   PipeLoop
    ret
Dead:
    mov  alive, 0
    ret
CheckCollision ENDP

;------------------------------------------------------------------
GetBirdRow PROC
; Returns: EAX = playfield row of the bird (birdY / 4)
;------------------------------------------------------------------
    mov  eax, birdY
    sar  eax, SCALE_SHIFT
    ret
GetBirdRow ENDP

;------------------------------------------------------------------
DrawFrame PROC USES eax ebx ecx edx esi edi
; Draws the borders, every playfield row, and the bird.
; Receives: nothing   Returns: nothing
;------------------------------------------------------------------
    mov  dh, 0              ; score line
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

    mov  dh, FIELD_TOP - 1  ; top border
    mov  dl, 0
    call Gotoxy
    mov  edx, OFFSET borderLine
    call WriteString

    mov  ecx, 0             ; ecx = current row
RowLoop:
    ; blank the inside of the row
    mov  edi, OFFSET rowBuf + 1
    push ecx
    mov  ecx, FIELD_W
    mov  al, ' '
    cld
    rep  stosb
    pop  ecx

    ; draw the solid part of every pipe that crosses this row
    mov  esi, 0
PipeLoop:
    mov  eax, gapTop[esi]
    cmp  ecx, eax
    jl   Solid              ; row is above the gap
    add  eax, GAP_H
    cmp  ecx, eax
    jl   NextPipe           ; row is inside the gap
Solid:
    mov  ebx, pipeX[esi]
    inc  ebx                ; ebx = index in rowBuf (+1 for left border)
    mov  edx, 0             ; edx = columns drawn so far
ColLoop:
    cmp  ebx, 1
    jl   NextCol            ; off the left side
    cmp  ebx, FIELD_W
    jg   NextCol            ; off the right side
    mov  rowBuf[ebx], PIPE_CHAR
NextCol:
    inc  ebx
    inc  edx
    cmp  edx, PIPE_W
    jl   ColLoop
NextPipe:
    add  esi, TYPE pipeX
    cmp  esi, SIZEOF pipeX
    jl   PipeLoop

    mov  dh, cl
    add  dh, FIELD_TOP
    mov  dl, 0
    call Gotoxy
    mov  edx, OFFSET rowBuf
    call WriteString

    inc  ecx
    cmp  ecx, FIELD_H
    jl   RowLoop

    mov  dh, FIELD_TOP + FIELD_H    ; bottom border
    mov  dl, 0
    call Gotoxy
    mov  edx, OFFSET borderLine
    call WriteString

    mov  dh, FIELD_TOP + FIELD_H + 1
    mov  dl, 0
    call Gotoxy
    mov  edx, OFFSET helpMsg
    call WriteString

    ; bird
    call GetBirdRow
    .IF eax < FIELD_H
        mov  dh, al
        add  dh, FIELD_TOP
        mov  dl, BIRD_X + 1     ; +1 skips the left border
        call Gotoxy
        mov  al, BIRD_CHAR
        call WriteChar
    .ENDIF

    mov  dh, FIELD_TOP + FIELD_H + 2    ; park the cursor below the game
    mov  dl, 0
    call Gotoxy
    ret
DrawFrame ENDP

;------------------------------------------------------------------
WaitKey PROC USES ebx edx
; Waits until a key is pressed.
; Returns: AL = ASCII code of the key
;------------------------------------------------------------------
Wait1:
    mov  eax, 10
    call Delay
    call ReadKey            ; ZF = 1 when no key is waiting
    jz   Wait1
    ret
WaitKey ENDP

;------------------------------------------------------------------
ShowTitle PROC USES eax edx
; Shows the title screen and waits for SPACE (play) or ESC (quit).
; Returns: quitFlag = 1 if the player chose ESC
;------------------------------------------------------------------
    call Clrscr
    mov  dh, FIELD_TOP + 7
    mov  dl, 20
    call Gotoxy
    mov  edx, OFFSET titleMsg
    call WriteString
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

;------------------------------------------------------------------
ShowGameOver PROC USES eax edx
; Updates the best score, shows the game over message, and waits
; for R (play again) or ESC (quit).
; Returns: quitFlag = 1 if the player chose ESC
;------------------------------------------------------------------
    mov  eax, score
    .IF eax > bestScore
        mov  bestScore, eax
    .ENDIF

    mov  dh, FIELD_TOP + 7
    mov  dl, 22
    call Gotoxy
    mov  edx, OFFSET overMsg
    call WriteString
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

    mov  eax, 600           ; short pause so a held SPACE does not skip this
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
