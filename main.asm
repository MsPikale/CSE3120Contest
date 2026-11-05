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
blankStr   BYTE "   ",0
scoreMsg   BYTE "Score: ",0
subY       BYTE 10
vel        SBYTE 0
wallX      BYTE 26, 52, 78
gapY       BYTE 7, 4, 10
score      DWORD 0
alive      BYTE 1

.code
main PROC
    call Randomize
newGame:
    call Clrscr
    call DrawFloor
    call InitGame
gameLoop:
    mov eax, TICK_MS
    call Delay
    call CheckInput
    call UpdateWalls
    call UpdateSub
    call CheckHit
    call ShowScore
    cmp alive, 1
    je gameLoop
    exit
main ENDP

InitGame PROC USES esi
    mov subY, 10
    mov vel, 0
    mov score, 0
    mov alive, 1
    mov esi, 0
    mov al, WALL_SPACING
setWall:
    mov wallX[esi], al
    add al, WALL_SPACING
    inc esi
    cmp esi, LENGTHOF wallX
    jb setWall
    ret
InitGame ENDP

DrawFloor PROC
    mov dl, 0
    mov dh, FLOOR_Y
    call Gotoxy
    mov al, '='
    mov ecx, 79
floorLoop:
    call WriteChar
    loop floorLoop
    ret
DrawFloor ENDP

DrawColumn PROC
    mov dh, 1
rowLoop:
    cmp dh, bl
    jb solid
    mov ah, bl
    add ah, GAP_H
    cmp dh, ah
    jb skipRow
solid:
    call Gotoxy
    call WriteChar
skipRow:
    inc dh
    cmp dh, FLOOR_Y
    jb rowLoop
    ret
DrawColumn ENDP

UpdateWalls PROC USES esi ebx
    mov esi, 0
nextWall:
    mov dl, wallX[esi]
    mov bl, gapY[esi]
    mov al, ' '
    call DrawColumn
    dec wallX[esi]
    jnz drawIt
    mov wallX[esi], WALL_START
    mov eax, FLOOR_Y - GAP_H - 1
    call RandomRange
    inc al
    mov gapY[esi], al
    mov bl, al
drawIt:
    cmp wallX[esi], SUB_X - 1
    jne noPoint
    inc score
noPoint:
    mov dl, wallX[esi]
    mov al, '#'
    call DrawColumn
    inc esi
    cmp esi, LENGTHOF wallX
    jb nextWall
    ret
UpdateWalls ENDP

CheckHit PROC USES esi
    cmp subY, FLOOR_Y
    jae dead
    mov esi, 0
hitLoop:
    mov al, wallX[esi]
    cmp al, SUB_X
    jb nextHit
    cmp al, SUB_X + SUB_W
    jae nextHit
    mov al, subY
    cmp al, gapY[esi]
    jb dead
    mov ah, gapY[esi]
    add ah, GAP_H
    cmp al, ah
    jae dead
nextHit:
    inc esi
    cmp esi, LENGTHOF wallX
    jb hitLoop
    ret
dead:
    mov alive, 0
    ret
CheckHit ENDP

CheckInput PROC
readMore:
    call ReadKey
    jz noKey
    cmp al, ' '
    jne readMore
    mov vel, FLAP_VEL
    jmp readMore
noKey:
    ret
CheckInput ENDP

UpdateSub PROC
    mov dl, SUB_X
    mov dh, subY
    call Gotoxy
    mov edx, OFFSET blankStr
    call WriteString
    inc vel
    cmp vel, 1
    jle velOk
    mov vel, 1
velOk:
    mov al, subY
    add al, vel
    cmp al, 1
    jge notTop
    mov al, 1
notTop:
    mov subY, al
    mov dl, SUB_X
    mov dh, subY
    call Gotoxy
    mov edx, OFFSET subShape
    call WriteString
    ret
UpdateSub ENDP

ShowScore PROC
    mov dl, 0
    mov dh, 0
    call Gotoxy
    mov edx, OFFSET scoreMsg
    call WriteString
    mov eax, score
    call WriteDec
    ret
ShowScore ENDP
END main
