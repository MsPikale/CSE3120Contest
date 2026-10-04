; FlappyBird.asm - a Flappy Bird style game for the console
; Uses the Irvine32 library.

INCLUDE Irvine32.inc

;------------------------- game constants -------------------------
FIELD_W     = 60            ; playfield width in columns
FIELD_H     = 20            ; playfield height in rows
FIELD_TOP   = 2             ; screen row of the first playfield row
BIRD_X      = 12            ; column the bird stays in
BIRD_CHAR   = '@'
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

rowBuf      BYTE '|', FIELD_W DUP(' '), '|', 0
borderLine  BYTE '+', FIELD_W DUP('-'), '+', 0
helpMsg     BYTE "SPACE / W = flap     ESC = quit", 0

.code
main PROC
    call Randomize
    call Clrscr
    call ResetGame

GameLoop:
    call HandleInput
    cmp  quitFlag, 1
    je   Quit
    call UpdateBird
    call DrawFrame
    mov  eax, FRAME_MS
    call Delay
    jmp  GameLoop

Quit:
    call Clrscr
    exit
main ENDP

;------------------------------------------------------------------
ResetGame PROC
; Puts the bird back in the middle of the screen.
; Receives: nothing   Returns: nothing
;------------------------------------------------------------------
    mov  birdY, START_Y
    mov  birdVel, 0
    ret
ResetGame ENDP

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
GetBirdRow PROC
; Returns: EAX = playfield row of the bird (birdY / 4)
;------------------------------------------------------------------
    mov  eax, birdY
    sar  eax, SCALE_SHIFT
    ret
GetBirdRow ENDP

;------------------------------------------------------------------
DrawFrame PROC USES eax ecx edx edi
; Draws the borders, every playfield row, and the bird.
; Receives: nothing   Returns: nothing
;------------------------------------------------------------------
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

END main
