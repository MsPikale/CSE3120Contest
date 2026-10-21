INCLUDE Irvine32.inc

SUB_X        = 10
SUB_W        = 3
FLOOR_Y      = 21
GAP_H        = 7
WALL_SPACING = 26
WALL_START   = 78
FLAP_VEL     = -3
TICK_MS      = 80

.data
subShape   BYTE "<=>",0
subY       BYTE 10
alive      BYTE 1

.code
main PROC
    call Clrscr
gameLoop:
    mov eax, TICK_MS
    call Delay
    call UpdateSub
    cmp alive, 1
    je gameLoop
    exit
main ENDP

UpdateSub PROC
    mov dl, SUB_X
    mov dh, subY
    call Gotoxy
    mov edx, OFFSET subShape
    call WriteString
    ret
UpdateSub ENDP
END main
